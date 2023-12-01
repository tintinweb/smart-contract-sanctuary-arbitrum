// SPDX-License-Identifier: MIT

pragma solidity 0.8.22;

import {IERC20} from "open-zeppelin/contracts/token/ERC20/IERC20.sol";
import {IGlpManager} from "./interfaces/IGlpManager.sol";

contract MugenRedemption {
    address public constant MUGEN = 0xFc77b86F3ADe71793E1EEc1E7944DB074922856e;
    address public constant GLP_MANAGER = 0xB95DB5B167D75e6d04227CfFFA61069348d271F5;
    address public constant FS_GLP = 0x1aDDD80E6039594eE970E5872D247bf0414C8903;
    address public constant OWNER = 0x6Cb6D9Fb673CfbF31b3A432F6316fE3196efd4aA;
    address public constant USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    uint256 public exchangeRate;
    bool public opened;
    bool public paused;
    uint256 public immutable close;
    mapping(address => uint256) public redeemed;

    modifier isPaused() {
        if (paused) revert Paused();
        _;
    }

    constructor() {
        close = block.timestamp + (86400 * 90); // 90 days
    }

    function exchangeGlp(uint256 amount) external {
        if (msg.sender != OWNER) revert OnlyOwner();
        IGlpManager(GLP_MANAGER).unstakeAndRedeemGlp(
            USDC, IERC20(FS_GLP).balanceOf(address(this)), amount, address(this)
        );
    }

    ///@notice redeem all of the users Mugen balance at the set exchange rate for USDC;
    function redeem() external isPaused {
        if (!opened) revert NotOpen();
        address sender = msg.sender;
        uint256 amount = IERC20(MUGEN).balanceOf(sender);
        IERC20(MUGEN).transferFrom(sender, address(this), amount);
        uint256 shares = (amount * exchangeRate) / 1e18;
        IERC20(USDC).transfer(sender, shares);
        redeemed[sender] = shares; // Store proportions for airdrop of unclaimed funds post 90 days;
        emit Redeemed(sender, shares, amount);
    }

    function openRedemption() external {
        if (opened) revert AlreadyOpened();
        if (msg.sender != OWNER) revert OnlyOwner();
        uint256 share = IERC20(USDC).balanceOf(address(this)) * 75 / 1_000;
        IERC20(USDC).transfer(OWNER, share);
        exchangeRate = IERC20(USDC).balanceOf(address(this)) * 1e18 / IERC20(MUGEN).totalSupply();
        opened = true;
        emit Opened(msg.sender, exchangeRate);
    }

    function collectRemainder(address _to) external {
        if (block.timestamp < close) revert StillOpen();
        if (msg.sender != OWNER) revert OnlyOwner();
        uint256 _balance = IERC20(USDC).balanceOf(address(this));
        IERC20(USDC).transfer(_to, _balance);
        emit Collect(msg.sender, _to, _balance);
    }

    function emergencyWithdraw(address to, bytes calldata data) external {
        if (msg.sender != OWNER) revert OnlyOwner();
        (bool success,) = address(to).call(data);
        if (!success) revert CallFailed();
    }

    function pause() external {
        if (msg.sender != OWNER) revert OnlyOwner();
        paused = true;
    }

    function unpause() external {
        if (msg.sender != OWNER) revert OnlyOwner();
        paused = false;
    }

    event Collect(address indexed caller, address indexed receiver, uint256 amount);
    event Redeemed(address indexed caller, uint256 shares, uint256 amount);
    event Opened(address indexed caller, uint256 rate);

    error AlreadyOpened();
    error OnlyOwner();
    error NotOpen();
    error StillOpen();
    error Paused();
    error CallFailed();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.22;

interface IGlpManager {
    function depositBalances(address _account, address _depositToken) external view returns (uint256);
    function stakedAmounts(address _account) external view returns (uint256);
    function updateRewards() external;
    function stake(address _depositToken, uint256 _amount) external;
    function stakeForAccount(address _fundingAccount, address _account, address _depositToken, uint256 _amount)
        external;
    function unstake(address _depositToken, uint256 _amount) external;
    function unstakeForAccount(address _account, address _depositToken, uint256 _amount, address _receiver) external;
    function tokensPerInterval() external view returns (uint256);
    function claim(address _receiver) external returns (uint256);
    function claimForAccount(address _account, address _receiver) external returns (uint256);
    function claimable(address _account) external view returns (uint256);
    function averageStakedAmounts(address _account) external view returns (uint256);
    function cumulativeRewards(address _account) external view returns (uint256);
    function unstakeAndRedeemGlp(address, uint256, uint256, address) external returns (uint256);
    function glp() external view returns (address);
}