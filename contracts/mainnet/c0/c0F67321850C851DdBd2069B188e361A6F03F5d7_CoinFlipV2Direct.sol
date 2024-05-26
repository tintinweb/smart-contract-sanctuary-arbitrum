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
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CoinFlipV2Direct is Ownable, ReentrancyGuard {
    IERC20 public token;
    address public authorizedCaller;

    // Max amount of tokens that can be betted
    uint256 public maxBetAmount = 10000 * 10 ** 18;

    // Total token deposited
    uint256 public tokenBank;
    uint256 public feeAmount;

    // Event for a flip
    event Flip(address indexed user, uint256 amount, uint256 choose);
    // Event for a check
    event Check(address indexed user, uint256 result);
    // Event for claim
    event Claim(address indexed user, uint256 amount);
    // Event for deposit
    event Deposit(address indexed user, uint256 amount);
    // Event for claim from bank
    event ClaimFromBank(address indexed user, uint256 amount);

    // Structure to keep track of plays
    struct Position {
        address owner;
        // Play time
        uint256 timestamp;
        // Amount of betted tokens
        uint256 amount;
        // The choose of the user (heads / tails) 0 for heads, 1 for tails
        uint256 choose;
        // If the position is checked by the API and can be claimed
        bool checked;
    }

    // Address -> Position
    mapping(address => Position) public positions;

    constructor(address _token, address _authorized) {
        token = IERC20(_token);
        authorizedCaller = _authorized;
        feeAmount = 5; // Percent fee on flip
    }

    // Set a new authorized caller
    function setAuthorizedCaller(address _authorized) public onlyOwner {
        authorizedCaller = _authorized;
    }

    // Set max bet amount
    function setMaxBetAmount(uint256 _amount) public onlyOwner {
        maxBetAmount = _amount;
    }

    // Only authorized or owner modifier
    modifier onlyAuthorized() {
        require(
            msg.sender == authorizedCaller || msg.sender == owner(),
            "Not authorized"
        );
        _;
    }

    // Flip coin!
    function flip(uint256 _amount, uint256 _choose) public {
        require(_choose == 0 || _choose == 1, "Invalid choose");
        // Require that the amount is less than the max bet amount
        require(_amount <= maxBetAmount, "Amount too high");
        // Require that the contract holds at least double the amount of the bet
        require(
            token.balanceOf(address(this)) >= _amount * 2,
            "Insufficient funds in bank"
        );

        // Make sure the user does not have an unchecked position already
        require(
            positions[msg.sender].timestamp == 0 ||
                positions[msg.sender].checked,
            "User has an open flip"
        );

        // Transfer tokens from the user to the contract
        require(
            token.transferFrom(msg.sender, address(this), _amount),
            "Transfer failed"
        );

        // Increase the bank
        tokenBank += _amount;

        positions[msg.sender] = Position(
            msg.sender,
            block.timestamp,
            _amount,
            _choose,
            false
        );

        emit Flip(msg.sender, _amount, _choose);
    }

    // Checks a position
    function checkPosition(
        address _user,
        uint256 _result
    ) public onlyAuthorized nonReentrant {
        Position storage position = positions[_user];
        require(position.timestamp != 0, "Position not found");
        require(!position.checked, "Position already checked");

        if (_result == position.choose) {
            uint256 prize = position.amount * 2;
            // Remove the fee
            uint256 fee = (prize * feeAmount) / 100;

            uint256 total = prize - fee;

            // Modify the bank
            tokenBank -= total;

            // Send the tokens to the user
            require(token.transfer(_user, total), "Transfer failed");
        }

        position.checked = true;

        emit Check(_user, _result);
    }

    // Claim the fees
    function claimFromBank(uint256 amount) public onlyOwner {
        // Check that we dont claim more than the bank amount (user funds safu)
        require(amount <= tokenBank, "Amount too high");
        tokenBank -= amount;

        require(token.transfer(owner(), amount), "Transfer failed");

        emit ClaimFromBank(owner(), amount);
    }

    // Deposit in the BANK
    function depositInBank(uint256 _amount) public {
        require(
            token.transferFrom(msg.sender, address(this), _amount),
            "Transfer failed"
        );
        tokenBank += _amount;

        emit Deposit(msg.sender, _amount);
    }
}