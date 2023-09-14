// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

contract DCA {
    address public constant PARASWAP = 0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57;

    // @dev Token to sell
    address public immutable source;
    // @dev Token to buy
    address public immutable target;
    // @dev The amount of `source` tokens to sell
    uint256 public amountToSell;
    // @dev The receiver of the tokens
    address public receiver;

    // @dev The last time a swap was done
    uint256 private lastSwap;
    // @dev The amount of time between swaps
    uint256 private interval;

    mapping(address => bool) private owners;

    modifier onlyOwner() {
        require(owners[msg.sender], "Sender is not an owner");
        _;
    }

    modifier afterInterval() {
        require(_canSwap(), "Trying to swap too soon");
        _;
    }

    constructor(
        address _owner,
        address _receiver,
        address _source,
        address _target,
        uint256 _interval,
        uint256 _amountToSell
    ) {
        require(_interval >= 1 hours, "Interval too small");
        require(_amountToSell > 0, "Amount to sell cannot be 0");

        owners[_owner] = true;

        receiver = _receiver;
        source = _source;
        target = _target;
        interval = _interval;
        amountToSell = _amountToSell;

        IERC20(_source).approve(0x216B4B4Ba9F3e719726886d34a177484278Bfcae, type(uint256).max);
    }

    function canSwap() public view returns (bool) {
        return _canSwap();
    }

    function recoverToken(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }

    function addOwner(address newOwner) external onlyOwner {
        owners[newOwner] = true;
    }

    function removeOwner(address ownerToRemove) external onlyOwner {
        owners[ownerToRemove] = false;
    }

    function setReceiver(address newReceiver) external onlyOwner {
        receiver = newReceiver;
    }

    function setInterval(uint256 newInterval) external onlyOwner {
        interval = newInterval;
    }

    function setAmountToSell(uint256 newAmountToSell) external onlyOwner {
        amountToSell = newAmountToSell;
    }

    function swap(bytes calldata data) external afterInterval onlyOwner {
        address receiverCache = receiver;

        uint256 initialSourceBalance = IERC20(source).balanceOf(address(this));
        uint256 initialTargetBalance = IERC20(target).balanceOf(receiverCache);

        (bool success,) = PARASWAP.call{value: 0}(data);

        require(success, "Failed to swap");
        require(
            initialSourceBalance - amountToSell == IERC20(source).balanceOf(address(this)), "Source amount mismatch"
        );
        require(initialTargetBalance < IERC20(target).balanceOf(receiverCache), "Target amount mismatch");

        lastSwap = block.timestamp;
    }

    function _canSwap() internal view returns (bool) {
        return block.timestamp >= lastSwap + interval;
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