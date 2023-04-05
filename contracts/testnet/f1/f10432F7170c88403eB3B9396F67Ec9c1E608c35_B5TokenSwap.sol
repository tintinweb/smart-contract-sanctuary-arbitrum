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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract B5TokenSwap is Ownable {
    address public token1;
    address public token2;

    uint public token1Reserve;
    uint public token2Reserve;

    mapping(address => mapping(address => uint256)) public balances;

    uint256 public lastBuyOrderId;
    uint256 public lastSellOrderId;
    struct SwapOrder {
        uint256 ordId;
        uint256 amount; // Amount of the token being sent
        uint256 price; // Amount of the token being sent
        uint256 timestamp; // Time when the swap order was created
        bool isBuy; // Is buy or sell
    }
    mapping(uint256 => SwapOrder) public buyOrdersHistory;
    mapping(uint256 => SwapOrder) public sellOrdersHistory;
    mapping(address => SwapOrder[]) public userBuyOrders;
    mapping(address => SwapOrder[]) public userSellOrders;

    event Deposit(address indexed from, address indexed token, uint256 amount);
    event Withdraw(address indexed to, address indexed token, uint256 amount);
    event TokensPurchased(address indexed buyer, uint256 amount);
    event TokensSold(address indexed seller, uint256 amount);

    constructor(address _token1, address _token2) {
        token1 = _token1;
        token2 = _token2;
    }

    function depositTokens(address tokenAddress, uint amount) external {
        require(amount > 0, "Amount must be greater than zero.");
        require(
            IERC20(tokenAddress).transferFrom(
                msg.sender,
                address(this),
                amount
            ),
            "Transfer failed."
        );
        balances[msg.sender][tokenAddress] += amount;
        emit Deposit(msg.sender, tokenAddress, amount);
    }

    function withdrawTokens(address tokenAddress, uint amount) external {
        require(amount > 0, "Amount must be greater than zero.");
        require(
            balances[msg.sender][tokenAddress] >= amount,
            "Insufficient balance."
        );
        require(
            IERC20(tokenAddress).transfer(msg.sender, amount),
            "Transfer failed."
        );
        balances[msg.sender][tokenAddress] -= amount;
        emit Withdraw(msg.sender, tokenAddress, amount);
    }

    function buyTokens(uint256 amount) external {
        require(amount > 0, "Amounts must be greater than zero.");

        uint256 token2Amount = calculateToken2Amount(amount);
        require(token2Amount <= token2Reserve, "Not enough tokens available");

        token1Reserve += amount;
        token2Reserve -= token2Amount;
        balances[msg.sender][token1] -= amount;
        balances[msg.sender][token2] += token2Amount;
        IERC20(token2).transfer(msg.sender, token2Amount);

        SwapOrder memory _order = SwapOrder({
            ordId: lastBuyOrderId,
            isBuy: true,
            amount: amount,
            price: calculateToken2Amount(1e18),
            timestamp: block.timestamp
        });

        buyOrdersHistory[lastBuyOrderId] = _order;
        userBuyOrders[msg.sender].push(_order);
        lastBuyOrderId++;
        emit TokensPurchased(msg.sender, amount);
    }

    function sellTokens(uint256 amount) public {
        require(amount > 0, "Amounts must be greater than zero.");

        uint256 token1Amount = calculateToken1Amount(amount);
        require(token1Amount <= token1Reserve, "Not enough tokens available");

        token1Reserve -= token1Amount;
        token2Reserve += amount;
        balances[msg.sender][token1] += token1Amount;
        balances[msg.sender][token2] -= amount;

        IERC20(token1).transfer(msg.sender, token1Amount);

        SwapOrder memory _order = SwapOrder({
            ordId: lastSellOrderId,
            isBuy: false,
            amount: amount,
            price: calculateToken2Amount(1e18),
            timestamp: block.timestamp
        });
        sellOrdersHistory[lastSellOrderId] = _order;
        userSellOrders[msg.sender].push(_order);
        lastSellOrderId++;
        emit TokensSold(msg.sender, amount);
    }

    function addLiquidity(
        uint256 token1Amount,
        uint256 token2Amount
    ) public onlyOwner {
        if (token1Reserve != 0) {
            token2Amount = calculateToken2Amount(token1Amount);
        }

        IERC20(token1).transferFrom(msg.sender, address(this), token1Amount);
        IERC20(token2).transferFrom(msg.sender, address(this), token2Amount);

        token1Reserve += token1Amount;
        token2Reserve += token2Amount;
    }

    function calculateToken1Amount(
        uint256 token2Amount
    ) public view returns (uint256) {
        return (token2Amount * token1Reserve) / token2Reserve;
    }

    function calculateToken2Amount(
        uint256 token1Amount
    ) public view returns (uint256) {
        return (token1Amount * token2Reserve) / token1Reserve;
    }

    function getUsersOrderCount(
        address _user
    ) public view returns (uint256 buyOrders, uint256 sellOrders) {
        return (userBuyOrders[_user].length, userSellOrders[_user].length);
    }
}