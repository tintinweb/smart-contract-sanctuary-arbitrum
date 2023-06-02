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
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Vesting {
    IERC20 public immutable token;
    uint256 public constant vestingPeriod = 180 days;
    mapping(address => uint256) public allocation;
    mapping(address => uint256) public claimed;
    uint256 public start;
    bool public started;

    constructor() {
        token = IERC20(0x3A33473d7990a605a88ac72A78aD4EFC40a54ADB);
        allocation[0x8c807CDdB6fAADF96956353f70ea60D63fAb69D5] = 72766666666666666666666;
        allocation[0xa77fEaE6752429a7ef263B40479Df84971F7d230] = 72766666666666666666666;
        allocation[0xE46DBa60D38AAEc41CdF19f2c0779E48cf51D939] = 72766666666666666666666;
    }

    function begin() external {
        require(!started, "Started");
        started = true;
        start = block.timestamp;
    }

    function claim() external {
        require(started, "!Started");
        uint256 _claimable = pending(msg.sender);
        require(_claimable > 0, "Nothing to claim");
        claimed[msg.sender] += _claimable;
        token.transfer(msg.sender, _claimable);
    }

    function pending(address _user) public view returns (uint256) {
        if (!started) return 0;
        if (block.timestamp - start > vestingPeriod)
            return allocation[_user] - claimed[_user];
        return (allocation[_user] * (block.timestamp - start)) / vestingPeriod - claimed[_user];
    }
}