// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Errors} from "src/libraries/Errors.sol";
import {ISubscriptions} from "src/interfaces/ISubscriptions.sol";
import {IOperator} from "src/storage/interfaces/IOperator.sol";
import {IFutureManagers} from "src/storage/interfaces/IFutureManagers.sol";
import {IQ} from "src/q/interfaces/IQ.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Subscriptions is ISubscriptions {
    address public operator;
    uint96 public subscriptionLimit;

    event Subscribe(
        address indexed managerAddress,
        address indexed subscriberAddress,
        address indexed subscriberAccountAddress,
        uint96 maxLimit
    );
    event SubscribeToFutureManager(
        bytes32 indexed futureManager,
        address indexed subscriberAddress,
        address indexed subscriberAccountAddress,
        uint96 maxLimit
    );
    event Unsubscribe(
        address indexed managerAddress, address indexed subscriberAddress, address indexed subscriberAccountAddress
    );
    event UnsubscribeToFutureManager(
        bytes32 indexed futureManager, address indexed subscriberAddress, address indexed subscriberAccountAddress
    );
    event UpdateSubscriptionLimit(uint96 newSubscriptionLimit);

    constructor(address _operator, uint96 _subscriptionLimit) {
        operator = _operator;
        subscriptionLimit = _subscriptionLimit; // type(uint96).max / subscriptionLimit - For eg. 79228162514264337593543950335 / 10_000e6 - 7.922816251426434e18 subscribers
    }

    function claimFutureManager(bytes32 futureManager, address manager) external {
        address vault = IOperator(operator).getAddress("VAULT");
        if (msg.sender != vault) revert Errors.NoAccess();
        address futureManagers = IOperator(operator).getAddress("FUTUREMANAGERS");
        address[] memory subs = IFutureManagers(futureManagers).getAllSubscribers(futureManager);
        uint256 i;
        for (; i < subs.length;) {
            uint96 amount = IFutureManagers(futureManagers).getSubscriptionAmount(futureManager, subs[i]);
            IOperator(operator).setSubscribe(manager, subs[i], amount);
            IFutureManagers(futureManagers).deleteSubscriber(futureManager, subs[i]);
            unchecked {
                ++i;
            }
        }
        IFutureManagers(futureManagers).deleteFutureManager(futureManager, manager);
    }

    function updateSubscriptionLimit(uint96 newSubscriptionLimit) external {
        address owner = IOperator(operator).getAddress("OWNER");
        if (msg.sender != owner) revert Errors.NotOwner();
        if (newSubscriptionLimit < 1e6) revert Errors.ZeroAmount();
        subscriptionLimit = newSubscriptionLimit;
        emit UpdateSubscriptionLimit(newSubscriptionLimit);
    }

    function subscribe(address manager, uint96 maxLimit) external {
        address subscriberAccountAddress = IOperator(operator).getTraderAccount(msg.sender);
        _checkbalance(subscriberAccountAddress, maxLimit);
        _subscribe(manager, subscriberAccountAddress, maxLimit);
    }

    function subscribeToFutureManager(bytes32 futureManager, uint96 maxLimit) external {
        address subscriberAccountAddress = IOperator(operator).getTraderAccount(msg.sender);
        _checkbalance(subscriberAccountAddress, maxLimit);
        _subscribeToFutureManager(futureManager, subscriberAccountAddress, maxLimit);
    }

    function subscribe(address[] calldata managers, uint96[] calldata maxLimit) external {
        if (managers.length != maxLimit.length) revert Errors.InputMismatch();
        address subscriberAccountAddress = IOperator(operator).getTraderAccount(msg.sender);
        uint256 i;
        uint96 amount;
        uint96 highestAmount;
        for (; i < managers.length;) {
            amount = maxLimit[i];
            highestAmount = amount > highestAmount ? amount : highestAmount;
            _subscribe(managers[i], subscriberAccountAddress, amount);
            unchecked {
                ++i;
            }
        }
        _checkbalance(subscriberAccountAddress, highestAmount);
    }

    function unsubscribe(address manager) external {
        address subscriberAccountAddress = IOperator(operator).getTraderAccount(msg.sender);
        _unsubscribe(manager, subscriberAccountAddress);
    }

    function unsubscribeToFutureManager(bytes32 futureManager) external {
        address subscriberAccountAddress = IOperator(operator).getTraderAccount(msg.sender);
        _unsubscribeToFutureManager(futureManager, subscriberAccountAddress);
    }

    function updateSubscription(address manager, uint96 maxLimit) external {
        address subscriberAccountAddress = IOperator(operator).getTraderAccount(msg.sender);
        uint96 subscriptionAmount = IOperator(operator).getSubscriptionAmount(manager, subscriberAccountAddress);
        _unsubscribe(manager, subscriberAccountAddress);
        if (maxLimit > subscriptionAmount) _checkbalance(subscriberAccountAddress, maxLimit);
        _subscribe(manager, subscriberAccountAddress, maxLimit);
    }

    function unsubscribe(address[] calldata managers) external {
        address subscriberAccountAddress = IOperator(operator).getTraderAccount(msg.sender);
        uint256 i;
        for (; i < managers.length;) {
            _unsubscribe(managers[i], subscriberAccountAddress);
            unchecked {
                ++i;
            }
        }
    }

    function getAllSubscribers(address manager) external view returns (address[] memory) {
        return IOperator(operator).getAllSubscribers(manager);
    }

    function getIsSubscriber(address manager, address subscriber) external view returns (bool) {
        return IOperator(operator).getIsSubscriber(manager, subscriber);
    }

    function getSubscriptionAmount(address manager, address subscriber) external view returns (uint96) {
        return IOperator(operator).getSubscriptionAmount(manager, subscriber);
    }

    function getTotalSubscribedAmountPerManager(address manager) external view returns (uint96) {
        return IOperator(operator).getTotalSubscribedAmountPerManager(manager);
    }

    function _subscribe(address manager, address subscriberAccountAddress, uint96 maxLimit) internal {
        if (manager == address(0)) revert Errors.ZeroAddress();
        if (maxLimit < 1e6) revert Errors.ZeroAmount();
        if (maxLimit > subscriptionLimit) revert Errors.MoreThanLimit();

        IOperator(operator).setSubscribe(manager, subscriberAccountAddress, maxLimit);
        emit Subscribe(manager, msg.sender, subscriberAccountAddress, maxLimit);
    }

    function _subscribeToFutureManager(bytes32 futureManager, address subscriberAccountAddress, uint96 maxLimit) internal {
        if (futureManager == bytes32(0)) revert Errors.ZeroAddress();
        if (maxLimit < 1e6) revert Errors.ZeroAmount();
        if (maxLimit > subscriptionLimit) revert Errors.MoreThanLimit();

        address futureManagersContract = IOperator(operator).getAddress("FUTUREMANAGERS");
        IFutureManagers(futureManagersContract).setSubscribeToFutureManager(futureManager, subscriberAccountAddress, maxLimit);
        emit SubscribeToFutureManager(futureManager, msg.sender, subscriberAccountAddress, maxLimit);
    }

    function _unsubscribe(address manager, address subscriberAccountAddress) internal {
        if (manager == address(0)) revert Errors.ZeroAddress();

        IOperator(operator).setUnsubscribe(manager, subscriberAccountAddress);
        emit Unsubscribe(manager, msg.sender, subscriberAccountAddress);
    }

    function _unsubscribeToFutureManager(bytes32 futureManager, address subscriberAccountAddress) internal {
        if (futureManager == bytes32(0)) revert Errors.ZeroAddress();

        address futureManagersContract = IOperator(operator).getAddress("FUTUREMANAGERS");
        IFutureManagers(futureManagersContract).setUnsubscribeToFutureManager(futureManager, subscriberAccountAddress);
        emit UnsubscribeToFutureManager(futureManager, msg.sender, subscriberAccountAddress);
    }

    function _checkbalance(address traderAccount, uint96 amount) internal view {
        address token = IOperator(operator).getAddress("DEFAULTSTABLECOIN");
        uint256 balance = IERC20(token).balanceOf(traderAccount);
        if (traderAccount == address(0)) revert Errors.AccountNotExists();
        if (balance < amount) revert Errors.BalanceLessThanAmount();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

library Errors {
    // Zero Errors
    error ZeroAmount();
    error ZeroAddress();
    error ZeroTotalRaised();
    error ZeroClaimableAmount();

    // Modifier Errors
    error NotOwner();
    error NotAdmin();
    error CallerNotVault();
    error CallerNotTrade();
    error CallerNotVaultOwner();
    error CallerNotGenerate();
    error NoAccess();
    error NotPlugin();

    // State Errors
    error BelowMinFundraisingPeriod();
    error AboveMaxFundraisingPeriod();
    error BelowMinLeverage();
    error AboveMaxLeverage();
    error BelowMinEndTime();
    error TradeTokenNotApplicable();

    // STV errors
    error StvDoesNotExist();
    error AlreadyOpened();
    error MoreThanTotalRaised();
    error MoreThanTotalReceived();
    error StvNotOpen();
    error StvNotClose();
    error ClaimNotApplicable();
    error StvStatusMismatch();

    // General Errors
    error BalanceLessThanAmount();
    error FundraisingPeriodEnded();
    error TotalRaisedMoreThanCapacity();
    error StillFundraising();
    error CommandMisMatch();
    error TradeCommandMisMatch();
    error NotInitialised();
    error Initialised();
    error LengthMismatch();
    error TransferFailed();
    error DelegateCallFailed();
    error CallFailed(bytes);
    error AccountAlreadyExists();
    error SwapFailed();
    error ExchangeDataMismatch();
    error AccountNotExists();
    error InputMismatch();
    error AboveMaxDistributeIndex();
    error BelowMinStvDepositAmount();

    // Protocol specific errors
    error GmxFeesMisMatch();
    error UpdateOrderRequestMisMatch();
    error CancelOrderRequestMisMatch();
    error WrongRewardClaimToken();

    // Subscriptions
    error NotASubscriber();
    error AlreadySubscribed();
    error MoreThanLimit();
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface ISubscriptions {
    function claimFutureManager(bytes32 futureManager, address manager) external;
    function getAllSubscribers(address managerAddress) external view returns (address[] memory);
    function getIsSubscriber(address manager, address subscriber) external view returns (bool);
    function getSubscriptionAmount(address manager, address subscriber) external view returns (uint96);
    function getTotalSubscribedAmountPerManager(address manager) external view returns (uint96);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IOperator {
    function getMaxDistributeIndex() external view returns (uint256);
    function getAddress(string calldata adapter) external view returns (address);
    function getAddresses(string[] calldata adapters) external view returns (address[] memory);
    function getTraderAccount(address trader) external view returns (address);
    function getPlugin(address plugin) external view returns (bool);
    function getPlugins(address[] calldata plugins) external view returns (bool[] memory);
    function setAddress(string calldata adapter, address addr) external;
    function setAddresses(string[] calldata adapters, address[] calldata addresses) external;
    function setPlugin(address plugin, bool isPlugin) external;
    function setPlugins(address[] calldata plugins, bool[] calldata isPlugin) external;
    function setTraderAccount(address trader, address account) external;
    function getAllSubscribers(address manager) external view returns (address[] memory);
    function getIsSubscriber(address manager, address subscriber) external view returns (bool);
    function getSubscriptionAmount(address manager, address subscriber) external view returns (uint96);
    function getTotalSubscribedAmountPerManager(address manager) external view returns (uint96);
    function setSubscribe(address manager, address subscriber, uint96 maxLimit) external;
    function setUnsubscribe(address manager, address subscriber) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IFutureManagers {
    function getAllSubscribers(bytes32 futureManager) external view returns (address[] memory);
    function getIsSubscriber(bytes32 futureManager, address subscriber) external view returns (bool);
    function getSubscriptionAmount(bytes32 futureManager, address subscriber) external view returns (uint96);
    function getTotalSubscribedAmountPerManager(bytes32 futureManager) external view returns (uint96);
    function claimFutureManager(bytes32 futureManager, address manager) external;
    function setSubscribeToFutureManager(bytes32 futureManager, address subscriber, uint96 maxLimit) external;
    function setUnsubscribeToFutureManager(bytes32 futureManager, address subscriber) external;
    function deleteSubscriber(bytes32 futureManager, address subscriber) external;
    function deleteFutureManager(bytes32 futureManager, address manager) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IQ {
    function owner() external view returns (address);
    function admin() external view returns (address);
    function perpTrade() external view returns (address);
    function whitelistedPlugins(address) external view returns (bool);
    function defaultStableCoin() external view returns (address);
    function traderAccount(address) external view returns (address);
    function createAccount(address) external returns (address);
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

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}