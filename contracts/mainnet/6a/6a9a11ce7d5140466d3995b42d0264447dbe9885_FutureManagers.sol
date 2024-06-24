// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Errors} from "src/libraries/Errors.sol";
import {IOperator} from "src/storage/interfaces/IOperator.sol";

/// @title FutureManagers
/// @notice Contract to manage all the subscriptions of future managers
contract FutureManagers {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    address public operator;
    /// @notice future manager hash -> subscriber address -> amount per stv
    mapping (bytes32 => mapping (address => uint96)) public futureManagerSubscriberAmount;
    /// @notice future manager hash -> subscribers
    mapping (bytes32 => address[]) public futureManagerSubscribers;
    /// @notice future manager hash -> total subscribed amount
    mapping (bytes32 => uint96) public futureManagerTotalSubscriptionAmount;    
    /// @notice future manager hash -> subscriber address -> unique field in the array
    mapping (bytes32 => mapping(address => bool)) public futureManagerIsUniqueSubscriber;
    /// @notice future manager hash -> manager address
    mapping (bytes32 => address) public futureManagerToManager;

    constructor(address _operator) {
        operator = _operator;
    }

    modifier onlySubscriptions() {
        if (msg.sender != IOperator(operator).getAddress("SUBSCRIPTIONS")) revert Errors.NoAccess();
        _;
    }

    function getAllSubscribers(bytes32 futureManager) external view returns (address[] memory) {
        return futureManagerSubscribers[futureManager];
    }

    function getIsSubscriber(bytes32 futureManager, address subscriber) external view returns (bool) {
        return futureManagerSubscriberAmount[futureManager][subscriber] > 0;
    }

    function getSubscriptionAmount(bytes32 futureManager, address subscriber) external view returns (uint96) {
        return futureManagerSubscriberAmount[futureManager][subscriber];
    }

    function getTotalSubscribedAmountPerManager(bytes32 futureManager) external view returns (uint96) {
        return futureManagerTotalSubscriptionAmount[futureManager];
    }

    function setSubscribeToFutureManager(bytes32 futureManager, address subscriber, uint96 maxLimit) external onlySubscriptions {
        if (futureManagerSubscriberAmount[futureManager][subscriber] > 0) revert Errors.AlreadySubscribed();
        if (futureManagerToManager[futureManager] != address(0)) revert Errors.NoAccess();

        futureManagerSubscriberAmount[futureManager][subscriber] = maxLimit;
        futureManagerTotalSubscriptionAmount[futureManager] += maxLimit;
        if (!futureManagerIsUniqueSubscriber[futureManager][subscriber]) {
            futureManagerSubscribers[futureManager].push(subscriber);
            futureManagerIsUniqueSubscriber[futureManager][subscriber] = true;
        }
    }

    function setUnsubscribeToFutureManager(bytes32 futureManager, address subscriber) external onlySubscriptions {
        if (futureManagerSubscriberAmount[futureManager][subscriber] == 0) revert Errors.NotASubscriber();
        if (futureManagerToManager[futureManager] != address(0)) revert Errors.NoAccess();

        futureManagerTotalSubscriptionAmount[futureManager] -= futureManagerSubscriberAmount[futureManager][subscriber];
        futureManagerSubscriberAmount[futureManager][subscriber] = 0;
    }

    function deleteSubscriber(bytes32 futureManager, address subscriber) external onlySubscriptions {
        futureManagerSubscriberAmount[futureManager][subscriber] = 0;
        futureManagerIsUniqueSubscriber[futureManager][subscriber] = false;
    }

    function deleteFutureManager(bytes32 futureManager, address manager) external onlySubscriptions {
        futureManagerTotalSubscriptionAmount[futureManager] = 0;
        futureManagerToManager[futureManager] = manager;
        delete futureManagerSubscribers[futureManager];
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