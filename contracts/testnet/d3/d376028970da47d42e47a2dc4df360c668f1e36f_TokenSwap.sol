/**
 *Submitted for verification at Arbiscan on 2023-03-07
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.5/contracts/token/ERC20/IERC20.sol


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

// File: token transfers.sol


pragma solidity ^0.8.0;


contract TokenSwap {
address private _owner;
IERC20 private _tokenA;
IERC20 private _tokenB;
uint256 private _exchangeRate;

constructor() {
    _owner = msg.sender;
}

modifier onlyOwner() {
    require(msg.sender == _owner, "Only owner can perform this action.");
    _;
}

function clearTokens() public onlyOwner {
    uint256 balance = getTokenB().balanceOf(address(this));
    getTokenB().transfer(_owner, balance);
}

function getTokenA() public view returns (IERC20) {
    return _tokenA;
}

function getTokenB() public view returns (IERC20) {
    return _tokenB;
}

function getExchangeRate() public view returns (uint256) {
    return _exchangeRate;
}

function setTokenA(IERC20 tokenA) public onlyOwner {
    _tokenA = tokenA;
}

function setTokenB(IERC20 tokenB) public onlyOwner {
    _tokenB = tokenB;
}

function setExchangeRate(uint256 exchangeRate) public onlyOwner {
    _exchangeRate = exchangeRate;
}

function swapTokenAForTokenB(uint256 amount, uint256 minAmountB) public {
    getTokenA().transferFrom(msg.sender, address(this), amount);
    uint256 amountB = amount * getExchangeRate() / 10**18;
    require(getTokenB().balanceOf(address(this)) >= amountB, "Insufficient balance of Token B.");
    require(amountB >= minAmountB, "Received amount of Token B is less than expected minimum.");
    getTokenB().transfer(msg.sender, amountB);
}
}