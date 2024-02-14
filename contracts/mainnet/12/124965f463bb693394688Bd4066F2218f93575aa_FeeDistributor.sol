// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;

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
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
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
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {IMemefiManagement} from "../management/IMemefiManagement.sol";
import {MemefiSwapable} from "./MemefiSwapable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract FeeDistributor is MemefiSwapable, ReentrancyGuard {
    event RewardAdded(uint256 reward, uint256 rewardIndex);
    event RewardWithdraw(
        address indexed user,
        uint256 reward,
        uint256 rewardIndexOfUser
    );
    event Burn(address indexed user, uint256 amount, bool isSwapped);

    uint256 private constant MULTIPLIER = 1e18;

    constructor(address _memefiManagement) MemefiSwapable(_memefiManagement) {}

    uint256 public rewardIndex;
    mapping(address => uint256) public rewardIndexOf;
    mapping(address => uint256) public earned;
    mapping(address => uint256) public balance;
    uint256 public depositedSupply;

    function swapToMemefi(uint256 _ethToMemefiRate) external override {
        require(msg.sender == address(memefiManagement), "Only management");
        _swapToMemefi(_ethToMemefiRate);
        uint256 depositedInMemefi = _calculateMemefiFromEth(depositedSupply);
        memefiToken.burn(depositedInMemefi);
    }

    function addReward(uint256 reward) external payable {
        if (isSwapped) {
            require(msg.value != 0, "FeeDistributor: ETH not allowed");
            memefiToken.transferFrom(msg.sender, address(this), reward);
            memefiToken.burn(reward);
            reward = _calculateEthFromMemefi(reward);
        } else {
            require(
                msg.value == reward,
                "FeeDistributor: Wrong amount of ETH sent"
            );
        }
        if (depositedSupply != 0) {
            rewardIndex += (reward * MULTIPLIER) / depositedSupply;
        }
        emit RewardAdded(reward, rewardIndex);
    }

    function _calculateRewards(address account) private view returns (uint256) {
        return
            (balance[account] * (rewardIndex - rewardIndexOf[account])) /
            MULTIPLIER;
    }

    function _updateRewards(address account) private {
        earned[account] += _calculateRewards(account);
        rewardIndexOf[account] = rewardIndex;
    }

    function burn(uint256 amount) external payable {
        require(amount > 0, "FeeDistributor: Amount must be greater than 0");
        uint256 ethAmount;
        if (isSwapped) {
            require(msg.value == 0, "FeeDistributor: ETH not allowed");
            memefiToken.burnFrom(msg.sender, amount);
            ethAmount = _calculateEthFromMemefi(amount);
        } else {
            require(
                msg.value == amount,
                "FeeDistributor: Wrong amount of ETH sent"
            );
            ethAmount = amount;
        }
        depositedSupply += ethAmount;
        balance[msg.sender] += ethAmount;
        _updateRewards(msg.sender);
        emit Burn(msg.sender, amount, isSwapped);
    }

    function withdrawReward() external returns (uint256) {
        return _withdrawReward(msg.sender);
    }

    function _withdrawReward(
        address rewardReceiver
    ) internal nonReentrant returns (uint256) {
        _updateRewards(rewardReceiver);

        uint256 reward = earned[rewardReceiver];

        if (reward > 0) {
            earned[rewardReceiver] = 0;
            if (isSwapped) {
                uint256 currentBalance = memefiToken.balanceOf(address(this));
                uint256 calculated = _calculateMemefiFromEth(reward);
                // Precision loss is possible here
                reward = currentBalance < calculated
                    ? currentBalance
                    : calculated;
                memefiToken.transfer(rewardReceiver, reward);
            } else {
                (bool success, ) = rewardReceiver.call{value: reward}("");
                require(success, "Unable to send funds");
            }

            emit RewardWithdraw(
                rewardReceiver,
                reward,
                rewardIndexOf[rewardReceiver]
            );
        }

        return reward;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {IERC20Burnable} from "../tokens/IERC20Burnable.sol";
import {IMemefiManagement} from "../management/IMemefiManagement.sol";

abstract contract MemefiSwapable {
    event TokenSwap(bool swapped);

    bool public isSwapped;
    uint256 public ethToMemefiRate; // 1 full eth = n memefi
    IERC20Burnable public memefiToken;
    IMemefiManagement public memefiManagement;

    constructor(address _memefiManagement) {
        memefiManagement = IMemefiManagement(_memefiManagement);
        memefiToken = IERC20Burnable(memefiManagement.memefiToken());
    }

    function swapToMemefi(uint256 _ethToMemefiRate) virtual external {
        _swapToMemefi(_ethToMemefiRate);
    }

    function _swapToMemefi(uint256 _ethToMemefiRate) internal {
        require(msg.sender == address(memefiManagement), "Only management");
        require(!isSwapped, "Already swapped");
        isSwapped = true;
        ethToMemefiRate = _ethToMemefiRate;
        uint256 ethBalance = address(this).balance;
        (bool success, ) = memefiManagement.treasury().call{value: ethBalance}(
            ""
        );
        require(success, "Unable to send funds");
        uint256 memefiAmount = _calculateMemefiFromEth(ethBalance);
        memefiToken.transferFrom(msg.sender, address(this), memefiAmount);
        emit TokenSwap(true);
    }

    function _calculateMemefiFromEth(
        uint256 ethAmount
    ) internal view returns (uint256) {
        return (ethAmount * ethToMemefiRate) / 1 ether;
    }

    function _calculateEthFromMemefi(
        uint256 memefiAmount
    ) internal view returns (uint256) {
        return (memefiAmount * 1 ether) / ethToMemefiRate;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IMemefiManagement {
    function treasury() external returns (address);

    function signer() external returns (address);

    function rewardDistributor() external returns (address);

    function mainAdmin() external returns (address);

    function hasRole(
        uint256 role,
        address walletAddress
    ) external view returns (bool);

    function uniqueRoleAddress(
        uint256 uniqueRole
    ) external view returns (address);

    function memefiToken() external returns (address);

    function storageSlot(uint256 _slot) external view returns (string memory);

    function feesDistributor() external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IERC20Burnable {
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 value) external;
}