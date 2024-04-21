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

contract CoinFlip is Ownable {
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

    // Mapping of the balances of players (WETH tokens locked in the contract)
    mapping(address => uint256) public balances;

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
        feeAmount = 1; // Percent fee on flip
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

        // Add the fee
        uint256 fee = (_amount * feeAmount) / 100;
        uint256 total = _amount + fee;

        // Check if the user has enough balance in the contract, if not transfer the tokens
        uint256 difference = total - balances[msg.sender];

        if (difference > 0) {
            require(
                token.transferFrom(msg.sender, address(this), difference),
                "Transfer failed"
            );
        }

        // Increase token Bank by the amount
        tokenBank += total;

        // Reduce the balance of the user
        if (balances[msg.sender] > total) {
            balances[msg.sender] -= total;
        } else {
            balances[msg.sender] = 0;
        }

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
    ) public onlyAuthorized {
        Position storage position = positions[_user];
        require(position.timestamp != 0, "Position not found");
        require(!position.checked, "Position already checked");

        if (_result == position.choose) {
            uint256 prize = position.amount * 2;
            // User won
            balances[_user] += prize;

            // Modify the bank
            tokenBank -= prize;
        }

        position.checked = true;

        emit Check(_user, _result);
    }

    // Claim the winnings
    function claim() public {
        Position storage position = positions[msg.sender];
        require(position.timestamp != 0, "Position not found");
        require(position.checked, "Position not checked yet");

        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance to claim");

        balances[msg.sender] = 0;
        require(token.transfer(msg.sender, amount), "Transfer failed");

        emit Claim(msg.sender, amount);
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