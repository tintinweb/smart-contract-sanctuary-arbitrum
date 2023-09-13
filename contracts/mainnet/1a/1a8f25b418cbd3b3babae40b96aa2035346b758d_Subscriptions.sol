// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Errors} from "src/libraries/Errors.sol";
import {ISubscriptions} from "src/interfaces/ISubscriptions.sol";
import {IOperator} from "src/storage/interfaces/IOperator.sol";
import {IQ} from "src/q/interfaces/IQ.sol";

contract Subscriptions is ISubscriptions {
    address public operator;
    uint96 public subscriptionLimit;

    event Subscribe(address indexed managerAddress, address indexed subscriberAddress, uint96 maxLimit);
    event Unsubscribe(address indexed managerAddress, address indexed subscriberAddress);

    constructor(address _operator, uint96 _subscriptionLimit) {
        operator = _operator;
        subscriptionLimit = _subscriptionLimit; // type(uint96).max / subscriptionLimit - For eg. 79228162514264337593543950335 / 10_000e6 - 7.922816251426434e18 subscribers
    }

    function subscribe(address manager, uint96 maxLimit) external {
        _subscribe(manager, maxLimit);
    }

    function subscribe(address[] calldata managers, uint96[] calldata maxLimit) external {
        if (managers.length != maxLimit.length) revert Errors.InputMismatch();
        uint256 i;
        for (; i < managers.length;) {
            _subscribe(managers[i], maxLimit[i]);
            unchecked {
                ++i;
            }
        }
    }

    function unsubscribe(address manager) external {
        _unsubscribe(manager);
    }

    function unsubscribe(address[] calldata managers) external {
        uint256 i;
        for (; i < managers.length;) {
            _unsubscribe(managers[i]);
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

    function _subscribe(address manager, uint96 maxLimit) internal {
        if (manager == address(0)) revert Errors.ZeroAddress();
        if (maxLimit < 1e6) revert Errors.ZeroAmount();
        if (maxLimit > subscriptionLimit) revert Errors.MoreThanLimit();

        address traderAccount = IOperator(operator).getTraderAccount(msg.sender);
        address q = IOperator(operator).getAddress("Q");
        if (traderAccount == address(0)) traderAccount = IQ(q).createAccount(msg.sender);

        IOperator(operator).setSubscribe(manager, msg.sender, maxLimit);
        emit Subscribe(manager, msg.sender, maxLimit);
    }

    function _unsubscribe(address manager) internal {
        if (manager == address(0)) revert Errors.ZeroAddress();

        IOperator(operator).setUnsubscribe(manager, msg.sender);
        emit Unsubscribe(manager, msg.sender);
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

    // Subscriptions
    error NotASubscriber();
    error AlreadySubscribed();
    error MoreThanLimit();
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface ISubscriptions {
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

interface IQ {
    function owner() external view returns (address);
    function admin() external view returns (address);
    function perpTrade() external view returns (address);
    function whitelistedPlugins(address) external view returns (bool);
    function defaultStableCoin() external view returns (address);
    function traderAccount(address) external view returns (address);
    function createAccount(address) external returns (address);
}