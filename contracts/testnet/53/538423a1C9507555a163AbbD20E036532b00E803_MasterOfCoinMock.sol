// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IMasterOfCoin.sol";
import "../interfaces/ITestERC20.sol";

contract MasterOfCoinMock is IMasterOfCoin {
    ITestERC20 public immutable magic;
    uint256 public previousWithdrawStamp;
    bool public staticAmount;

    constructor(address magic_) {
        magic = ITestERC20(magic_);
        previousWithdrawStamp = block.timestamp;
        staticAmount = true;
    }

    function requestRewards() external override returns (uint256 rewardsPaid) {
        if (staticAmount) {
            magic.mint(500 ether, msg.sender);
            return 500 ether;
        }
        uint256 secondsPassed = block.timestamp - previousWithdrawStamp;
        uint256 rewards = secondsPassed * 11574074e8;
        previousWithdrawStamp = block.timestamp;
        magic.mint(rewards, msg.sender);
        return rewards;
    }

    function getPendingRewards(address) external view override returns (uint256 pendingRewards) {
        if (staticAmount) {
            return 500 ether;
        }
        uint256 secondsPassed = block.timestamp - previousWithdrawStamp;
        uint256 rewards = secondsPassed * 11574074e8;
        return rewards;
    }

    function setWithdrawStamp() external override {
        previousWithdrawStamp = block.timestamp;
    }

    function setStaticAmount(bool set) external override {
        staticAmount = set;
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
pragma solidity >0.8.0;

interface IMasterOfCoin {
    function requestRewards() external returns (uint256 rewardsPaid);

    function getPendingRewards(address _stream) external view returns (uint256 pendingRewards);

    function setWithdrawStamp() external;

    function setStaticAmount(bool set) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITestERC20 is IERC20 {
    function mint(uint256 amount, address receiver) external;
}