// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function decimals() external view returns (uint8);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity ^0.8.11;

interface IRewardTracker {
    function depositBalances(address _account, address _depositToken) external view returns (uint256);

    function stakedAmounts(address _account) external view returns (uint256);

    function updateRewards() external;

    function stake(address _depositToken, uint256 _amount) external;

    function stakeForAccount(
        address _fundingAccount,
        address _account,
        address _depositToken,
        uint256 _amount
    ) external;

    function unstake(address _depositToken, uint256 _amount) external;

    function unstakeForAccount(address _account, address _depositToken, uint256 _amount, address _receiver) external;

    function tokensPerInterval(address _rewardToken) external view returns (uint256);

    function claim(address _receiver) external returns (uint256[] memory);

    function claimForAccount(address _account, address _receiver) external returns (uint256[] memory);

    function claimable(address _account, address _token) external view returns (uint256);

    function claimables(address _account) external view returns (uint256[] memory);

    function averageStakedAmounts(address _account) external view returns (uint256);

    function cumulativeRewards(address _rewardToken, address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract Governable {
    address public gov;

    constructor() {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "Governable: forbidden");
        _;
    }

    function setGov(address _gov) external onlyGov {
        require(_gov != address(0), "Governable: invalid address");
        gov = _gov;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {IERC20} from "./interfaces/IERC20.sol";
import {IRewardTracker} from "./interfaces/IRewardTracker.sol";
import {Governable} from "./libraries/Governable.sol";

interface VaultAPI is IERC20 {
    function deposit(uint256 amount, address recipient) external returns (uint256);

    function withdraw(uint256 maxShares, address recipient, uint256 maxLoss) external returns (uint256);
}

contract nUSDCRouter is ReentrancyGuard, Governable {
    address public vault;
    address public want;
    address public stakedNeutraUsdcTracker;

    event StakeNeutraUsdc(address fundingAccount, address account, uint256 amount);
    event UnstakeNeutraUsdc(address fundingAccount, address account, uint256 amount, uint256 maxLoss);

    constructor (
        address _vault,
        address _want,
        address _stakedNeutraUsdcTracker
    ) {
        vault = _vault;
        want = _want;
        stakedNeutraUsdcTracker = _stakedNeutraUsdcTracker;

        IERC20(_want).approve(_vault, type(uint256).max);
        VaultAPI(_vault).approve(_stakedNeutraUsdcTracker, type(uint256).max);
    }

    function depositAndStakeNeutraUsdc(address _recipient, uint256 _amount) external returns (uint256) {
        require(_amount > 0, "invalid _amount");

        IERC20(want).transferFrom(msg.sender, address(this), _amount);
        uint256 share = VaultAPI(vault).deposit(_amount, address(this));
        IRewardTracker(stakedNeutraUsdcTracker).stakeForAccount(address(this), _recipient, vault, share);

        emit StakeNeutraUsdc(msg.sender, _recipient, _amount);

        return share;
    }

    function unstakeAndRedeemNeutraUsdc(
        address _recipient,
        uint256 _amount,
        uint256 _maxLoss
    ) external returns (uint256) {
        require(_amount > 0, "invalid _amount");

        IRewardTracker(stakedNeutraUsdcTracker).unstakeForAccount(msg.sender, vault, _amount, address(this));
        uint256 amountOut = VaultAPI(vault).withdraw(_amount, _recipient, _maxLoss);

        emit UnstakeNeutraUsdc(msg.sender, _recipient, _amount, _maxLoss);

        return amountOut;
    }

    // to help users who accidentally send their tokens to this contract
    function withdrawToken(address _token, address _account, uint256 _amount) external onlyGov {
        IERC20(_token).transfer(_account, _amount);
    }

    function claim() external nonReentrant {
        IRewardTracker(stakedNeutraUsdcTracker).claimForAccount(msg.sender, msg.sender);
    }
}