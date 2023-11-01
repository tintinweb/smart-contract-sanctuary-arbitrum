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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract lock {
    IERC20 public token;

    struct UserInfo {
        uint startTime;
        uint endTime;
        uint amount;
        uint claimed;
        uint lastTime;
        uint rate;
    }

    mapping(address => UserInfo) public userInfo;
    constructor(address token_){
        token = IERC20(token_);
    }
    uint256 constant times = 2 * 365 days;
    //    uint times = 120;
    event Stake(address indexed player, uint indexed amount);
    event Claim(address indexed player, uint indexed amount);

    function stake(uint amount) external {
        UserInfo storage info = userInfo[msg.sender];
        require(info.amount == 0, 'staked');
        token.transferFrom(msg.sender, address(this), amount);
        info.startTime = block.timestamp;

        info.endTime = block.timestamp + times;
        info.lastTime = block.timestamp;
        info.amount = amount;
        info.rate = amount / times;
        emit Stake(msg.sender, amount);
    }

    function calculateReward(address addr) public view returns (uint){
        UserInfo storage info = userInfo[addr];
        if (info.amount == 0) return 0;
        uint out = (block.timestamp - info.lastTime) * info.rate;
        if (out + info.claimed >= info.amount || block.timestamp >= info.endTime) {
            out = info.amount - info.claimed;
        }
        return out;
    }

    function claim() external {
        UserInfo storage info = userInfo[msg.sender];
        require(info.amount != 0, 'NOT STAKE');
        uint rew = calculateReward(msg.sender);
        require(rew > 0, 'no reward');
        token.transfer(msg.sender, rew);
        info.claimed += rew;
        info.lastTime = block.timestamp;
        if (info.claimed >= info.amount || block.timestamp >= info.endTime) {
            delete userInfo[msg.sender];
        }
        emit Claim(msg.sender, rew);
    }
}