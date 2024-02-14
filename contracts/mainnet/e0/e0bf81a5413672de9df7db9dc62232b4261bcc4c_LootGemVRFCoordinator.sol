// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import './ReentrancyGuard.sol';
import './Ownable.sol';
import './ILootGemVRFCoordinator.sol';
import {LootGemVRFConsumer} from './LootGemVRFConsumer.sol';

contract LootGemVRFCoordinator is
    ILootGemVRFCoordinator,
    Ownable,
    ReentrancyGuard
{
    uint16 public constant MAX_CONSUMERS = 100;
    error TooManyConsumers();
    error MustBeSubOwner(address owner);
    error InvalidSubscription();
    error InvalidConsumer(uint64 subId, address consumer);
    error PublicUsagePaused();

    uint256 private constant GAS_FOR_CALL_EXACT_CHECK = 5_000;
    uint64 private s_currentSubId;
    bool publicUsage = true;
    struct RequestCommitment {
        uint256 requestId;
        address requester;
        uint64 subId;
        uint32 maxCallbackGasLimit;
        uint256[] randomNumbers;
    }

    struct SubscriptionConfig {
        address owner; // Owner can fund/withdraw/cancel the sub.
        address requestedOwner; // For safely transferring sub ownership.
        // Maintains the list of keys in s_consumers.
        // We do this for 2 reasons:
        // 1. To be able to clean up all keys from s_consumers when canceling a subscription.
        // 2. To be able to return the list of all consumers in getSubscription.
        // Note that we need the s_consumers map to be able to directly check if a
        // consumer is valid without reading all the consumers from storage.
        address[] consumers;
    }

    struct Subscription {
        // There are only 1e9*1e18 = 1e27 juels in existence, so the balance can fit in uint96 (2^96 ~ 7e28)
        uint96 balance; // Common link balance used for all consumer requests.
        uint64 reqCount; // For fee tiers
    }

    mapping(address => mapping(uint64 => uint64)) /* consumer */ /* subId */ /* nonce */
        private s_consumers;

    mapping(uint64 => SubscriptionConfig) /* subId */ /* subscriptionConfig */
        private s_subscriptionConfigs;

    mapping(uint64 => Subscription) /* subId */ /* subscription */
        private s_subscriptions;

    modifier onlySubOwner(uint64 subId) {
        address owner = s_subscriptionConfigs[subId].owner;
        if (owner == address(0)) {
            revert InvalidSubscription();
        }
        if (msg.sender != owner) {
            revert MustBeSubOwner(owner);
        }
        _;
    }

    modifier atPublicUsage() {
        if (!publicUsage) {
            revert PublicUsagePaused();
        }
        _;
    }

    // TODO
    // Change the way of setting owner
    constructor() Ownable(msg.sender) {
        for (uint i = 0; i < 10; ++i) {
            createSubscription();
        }
        publicUsage = false;
    }

    function requestRandomNumbers(
        uint64 subId,
        uint8 amount,
        uint32 maxCallbackGasLimit,
        uint32 maxCallbackGasPrice
    ) external returns (uint) {
        if (s_subscriptionConfigs[subId].owner == address(0)) {
            revert InvalidSubscription();
        }

        uint64 currentNonce = s_consumers[msg.sender][subId];
        if (currentNonce == 0) {
            revert InvalidConsumer(subId, msg.sender);
        }
        uint64 nonce = currentNonce + 1;
        uint requestId = _computeRequestId(
            maxCallbackGasPrice,
            msg.sender,
            subId,
            nonce
        );

        emit RandomNumbersRequest(
            requestId,
            msg.sender,
            subId,
            maxCallbackGasLimit,
            maxCallbackGasPrice,
            amount
        );

        s_consumers[msg.sender][subId] = nonce;
        return requestId;
    }

    function fulfillRequest(
        RequestCommitment memory rc
    ) external onlyOwner nonReentrant {
        uint256 startGas = gasleft();
        LootGemVRFConsumer v;
        bytes memory resp = abi.encodeWithSelector(
            v.rawFulfillRandomNumbers.selector,
            rc.requestId,
            rc.randomNumbers
        );
        bool success = _callWithExactGas(
            rc.maxCallbackGasLimit,
            rc.requester,
            resp
        );
        // Increment the req count for fee tier selection.
        uint64 reqCount = s_subscriptions[rc.subId].reqCount;
        s_subscriptions[rc.subId].reqCount += 1;

        // int96 payment = _calculatePaymentAmount(
        //   startGas,
        //   s_config.gasAfterPaymentCalculation,
        //   getFeeTier(reqCount),
        //   tx.gasprice
        // );
        // if (s_subscriptions[rc.subId].balance < payment) {
        //   revert InsufficientBalance();
        // }
        // s_subscriptions[rc.subId].balance -= payment;
        // s_withdrawableTokens[s_provingKeys[keyHash]] += payment;

        emit RandomNumbersFulfilled(rc.requestId, success);
    }

    function createSubscription() public nonReentrant returns (uint64) {
        s_currentSubId++;
        uint64 currentSubId = s_currentSubId;
        address[] memory consumers = new address[](0);
        s_subscriptions[currentSubId] = Subscription({balance: 0, reqCount: 0});
        s_subscriptionConfigs[currentSubId] = SubscriptionConfig({
            owner: msg.sender,
            requestedOwner: address(0),
            consumers: consumers
        });

        emit SubscriptionCreated(currentSubId, msg.sender);
        return currentSubId;
    }

    function addConsumer(
        uint64 subId,
        address consumer
    ) external onlySubOwner(subId) nonReentrant {
        // Already maxed, cannot add any more consumers.
        if (s_subscriptionConfigs[subId].consumers.length == MAX_CONSUMERS) {
            revert TooManyConsumers();
        }
        if (s_consumers[consumer][subId] != 0) {
            // Idempotence - do nothing if already added.
            // Ensures uniqueness in s_subscriptions[subId].consumers.
            return;
        }
        // Initialize the nonce to 1, indicating the consumer is allocated.
        s_consumers[consumer][subId] = 1;
        s_subscriptionConfigs[subId].consumers.push(consumer);

        emit SubscriptionConsumerAdded(subId, consumer);
    }

    function _callWithExactGas(
        uint256 gasAmount,
        address target,
        bytes memory data
    ) private returns (bool success) {
        assembly {
            let g := gas()
            // Compute g -= GAS_FOR_CALL_EXACT_CHECK and check for underflow
            // The gas actually passed to the callee is min(gasAmount, 63//64*gas available).
            // We want to ensure that we revert if gasAmount >  63//64*gas available
            // as we do not want to provide them with less, however that check itself costs
            // gas.  GAS_FOR_CALL_EXACT_CHECK ensures we have at least enough gas to be able
            // to revert if gasAmount >  63//64*gas available.
            if lt(g, GAS_FOR_CALL_EXACT_CHECK) {
                revert(0, 0)
            }
            g := sub(g, GAS_FOR_CALL_EXACT_CHECK)
            // if g - g//64 <= gasAmount, revert
            // (we subtract g//64 because of EIP-150)
            if iszero(gt(sub(g, div(g, 64)), gasAmount)) {
                revert(0, 0)
            }
            // solidity calls check that a contract actually exists at the destination, so we do the same
            if iszero(extcodesize(target)) {
                revert(0, 0)
            }
            // call and return whether we succeeded. ignore return data
            // call(gas,addr,value,argsOffset,argsLength,retOffset,retLength)
            success := call(
                gasAmount,
                target,
                0,
                add(data, 0x20),
                mload(data),
                0,
                0
            )
        }
        return success;
    }

    function _computeRequestId(
        uint32 maxCallbackGasPrice,
        address sender,
        uint64 subId,
        uint64 nonce
    ) private pure returns (uint256) {
        return
            uint256(
                keccak256(abi.encode(maxCallbackGasPrice, sender, subId, nonce))
            );
    }
}