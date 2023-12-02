// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

//import "forge-std/console.sol";

interface IBankRoll {
    function getOwner() external view returns (address);
}

contract Lottery is AutomationCompatibleInterface, ReentrancyGuard {
    using SafeERC20 for IERC20;
    address immutable weth;

    bytes32 immutable keyHash;
    uint64 immutable subId;
    uint16 constant minimumRequestConfirmations = 50;
    uint32 constant callBackGasLimit = 2_500_000;
    address immutable chainLinkVRF;

    uint256[12] MONTH_DURATION = [
        31,
        28,
        31,
        30,
        31,
        30,
        31,
        31,
        30,
        31,
        30,
        31
    ];
    uint256 public constant TICKET_COST = 0.001 ether;

    uint256 constant REBATE_SHARE = 5_000_000;
    uint256 constant BANKROLL_SHARE = 5_000_000;
    uint256 constant NEXT_LOTTERY_SHARE = 5_000_000;
    uint256 constant CHARITY_SHARE = 5_000_000;
    uint256 constant DIVISOR = 100_000_000;

    uint64 constant K = 1000;

    address immutable bankRoll;

    enum LotteryStatus {
        OPEN,
        PENDING_VRF,
        STOPPED,
        ERROR,
        CANCELED
    }

    struct Ticket {
        address player;
        uint64 startIndex;
        uint64 endIndex;
    }

    struct PlayerStats {
        uint128 ticketSum;
        uint64 numTicketsRebate;
        uint64 numTicketsBought;
        uint256 lastRoundPlayed;
    }

    struct LotteryGame {
        uint256 winnerPool;
        uint256 rebatePool;
        uint256 bankrollPool;
        uint256 nextLotteryPool;
        uint256 charityPool;
        Ticket[] tickets;
        uint64 totalTicketsBought;
        uint64 closeTime;
        uint64 blockNumberRequest;
        uint256 requestId;
    }

    bool public stopLottery;
    uint256 public charityFunds;

    uint256 public currentGameId;
    uint256 public currentMonth;
    uint256 public currentYear;
    LotteryStatus public currentLotteryStatus;

    mapping(uint256 => LotteryGame) public games;
    mapping(address => PlayerStats) public playerStats;

    error OnlyCoordinatorCanFulfill(address have, address want);
    error InvalidLotteryState(LotteryStatus have, LotteryStatus want);
    error InvalidTime(uint256 finishTime, uint256 currentTime);

    event TicketPurchased(
        uint256 roundId,
        address indexed player,
        uint64 amount,
        uint64 totalTicketsPurchased,
        uint256 rebateAmount
    );
    event VRFRequested(uint256 requestId);
    event LotteryResult(
        uint256 roundId,
        uint256 winningTicketId,
        address indexed winner,
        uint256 prize,
        uint256 nextLottery,
        uint256 charity
    );
    event DonationPerformed(address indexed to, uint256 amount);
    event RebateClaimed(
        uint256 roundId,
        address indexed player,
        uint256 amount
    );

    constructor(
        address _weth,
        bytes32 _keyHash,
        uint64 _subId,
        address _vrf,
        uint64 initialCloseTime,
        address _bankroll,
        uint256 _currentMonth,
        uint256 _currentYear
    ) {
        weth = _weth;
        keyHash = _keyHash;
        subId = _subId;
        chainLinkVRF = _vrf;
        bankRoll = _bankroll;

        currentGameId = 1;
        currentLotteryStatus = LotteryStatus.OPEN;
        games[currentGameId].closeTime = initialCloseTime;

        currentMonth = _currentMonth;
        currentYear = _currentYear;
    }

    function getState(
        address player
    )
        external
        view
        returns (
            uint256 _currentRoundId,
            LotteryGame memory _currentLottery,
            LotteryStatus _currentStatus,
            uint256 _currentMonth,
            uint256 _currentYear,
            PlayerStats memory _playerStatus,
            uint256 _playerRebateAvailable
        )
    {
        _currentRoundId = currentGameId;
        _currentLottery = games[currentGameId];
        _currentStatus = currentLotteryStatus;
        _currentMonth = currentMonth;
        _currentYear = currentYear;
        _playerStatus = playerStats[player];
        _playerRebateAvailable = _claimPrize(player);
    }

    function getGame(uint256 id) external view returns (LotteryGame memory) {
        return games[id];
    }

    function getPlayerStats(
        address player
    ) external view returns (PlayerStats memory) {
        return playerStats[player];
    }

    // Player Functions
    function purchaseTickets(uint64 amount) external payable nonReentrant {
        LotteryGame storage game = games[currentGameId];
        if (currentLotteryStatus != LotteryStatus.OPEN) {
            revert InvalidLotteryState(
                currentLotteryStatus,
                LotteryStatus.OPEN
            );
        }
        if (game.closeTime < block.timestamp) {
            revert InvalidTime(game.closeTime, block.timestamp);
        }
        PlayerStats memory stats = playerStats[msg.sender];

        uint256 totalCost = amount * TICKET_COST;
        uint256 amountToClaim = _claimPrize(msg.sender);
        if (amountToClaim != 0) {
            emit RebateClaimed(
                stats.lastRoundPlayed,
                msg.sender,
                amountToClaim
            );
            delete (stats);
        }
        if (
            stats.lastRoundPlayed != currentGameId && stats.lastRoundPlayed != 0
        ) {
            delete (stats);
        }
        if (msg.value + amountToClaim > totalCost) {
            _transferETH(msg.sender, msg.value + amountToClaim - totalCost);
        } else if (msg.value + amountToClaim < totalCost) {
            revert();
        }
        uint64 ticketsBefore = game.totalTicketsBought;
        uint64 ticketsAfter = ticketsBefore + amount;
        game.totalTicketsBought += amount;

        uint256 bankrollPool = (totalCost * BANKROLL_SHARE) / DIVISOR;
        uint256 rebatePool = (totalCost * REBATE_SHARE) / DIVISOR;
        uint256 nextLotteryPool = (totalCost * NEXT_LOTTERY_SHARE) / DIVISOR;
        uint256 charityPool = (totalCost * CHARITY_SHARE) / DIVISOR;
        game.bankrollPool += bankrollPool;
        game.rebatePool += rebatePool;
        game.nextLotteryPool += nextLotteryPool;
        game.charityPool += charityPool;
        game.winnerPool +=
            totalCost -
            bankrollPool -
            rebatePool -
            nextLotteryPool -
            charityPool;

        game.tickets.push(
            Ticket(msg.sender, ticketsBefore, ticketsBefore + amount - 1)
        );
        stats.numTicketsBought += amount;
        stats.lastRoundPlayed = currentGameId;
        if (ticketsBefore < K) {
            if (ticketsAfter > K) {
                uint64 inc = K - ticketsBefore;

                stats.numTicketsRebate += inc;
                stats.ticketSum += (inc * (inc + (2 * ticketsBefore) - 1)) / 2;
            } else {
                stats.numTicketsRebate += amount;
                stats.ticketSum +=
                    (amount * (amount + (2 * ticketsBefore) - 1)) /
                    2;
            }
        }
        playerStats[msg.sender] = stats;
        emit TicketPurchased(
            currentGameId,
            msg.sender,
            amount,
            ticketsAfter,
            amountToClaim
        );
    }

    function claimRebate() external nonReentrant {
        uint256 amountToClaim = _claimPrize(msg.sender);
        if (amountToClaim != 0) {
            delete (playerStats[msg.sender]);
            _transferETH(msg.sender, amountToClaim);
            emit RebateClaimed(
                playerStats[msg.sender].lastRoundPlayed,
                msg.sender,
                amountToClaim
            );
        }
    }

    function _claimPrize(address player) public view returns (uint256) {
        PlayerStats memory stats = playerStats[player];
        if (
            stats.lastRoundPlayed == 0 ||
            stats.lastRoundPlayed == currentGameId ||
            stats.numTicketsRebate == 0
        ) {
            return 0;
        }

        uint256 totalRebate = games[stats.lastRoundPlayed].rebatePool;
        uint256 totalTicketsBought = games[stats.lastRoundPlayed]
            .totalTicketsBought;
        if (totalTicketsBought > K) {
            totalTicketsBought = K;
        }
        if (totalTicketsBought == 1) {
            return totalRebate;
        }
        uint256 u = stats.numTicketsRebate;

        uint256 sum = stats.ticketSum;

        uint256 b = (2 * totalRebate) / (totalTicketsBought);
        uint256 m = (b * K) / (totalTicketsBought - 1);
        if (((m * sum) / (K)) + 1 > b * u) {
            return 0;
        }

        uint256 reward = b * u - ((m * sum) / (K)) - 1;

        return reward;
    }

    // Onwer Functions
    function closeLottery() external {
        if (msg.sender != IBankRoll(bankRoll).getOwner()) {
            revert();
        }
        stopLottery = true;
    }

    function donate(address to, uint256 amount) external nonReentrant {
        if (msg.sender != IBankRoll(bankRoll).getOwner()) {
            revert();
        }
        if (charityFunds < amount) {
            revert();
        }
        charityFunds -= amount;
        _transferETH(to, amount);
        emit DonationPerformed(to, amount);
    }

    // Emergency functions
    function errorLottery() external {
        if (
            currentLotteryStatus == LotteryStatus.STOPPED ||
            currentLotteryStatus == LotteryStatus.ERROR
        ) {
            revert InvalidLotteryState(
                currentLotteryStatus,
                LotteryStatus.PENDING_VRF
            );
        }
        if (block.timestamp < games[currentGameId].closeTime + (2 weeks)) {
            revert InvalidTime(
                games[currentGameId].closeTime + (2 weeks),
                block.timestamp
            );
        }
        currentLotteryStatus = LotteryStatus.ERROR;
    }

    function cancelLottery() external {
        if (msg.sender != IBankRoll(bankRoll).getOwner()) {
            revert();
        }
        currentLotteryStatus = LotteryStatus.CANCELED;
    }

    function rescueTicket(uint256 ticketIndex) external nonReentrant {
        if (
            !(currentLotteryStatus == LotteryStatus.ERROR ||
                currentLotteryStatus == LotteryStatus.CANCELED)
        ) {
            revert InvalidLotteryState(
                currentLotteryStatus,
                LotteryStatus.ERROR
            );
        }

        Ticket memory t = games[currentGameId].tickets[ticketIndex];
        delete (games[currentGameId].tickets[ticketIndex]);
        uint256 totalValue = (1 + t.endIndex - t.startIndex) * TICKET_COST;
        _transferETH(t.player, totalValue);
    }

    function rescueETH(address to, uint256 amount) external nonReentrant {
        if (msg.sender != IBankRoll(bankRoll).getOwner()) {
            revert();
        }
        if (block.timestamp < games[currentGameId].closeTime + (5 weeks)) {
            revert();
        }
        _transferETH(to, amount);
    }

    // Chainlink Functions
    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded =
            (games[currentGameId].closeTime < block.timestamp &&
                currentLotteryStatus == LotteryStatus.OPEN) ||
            (currentLotteryStatus == LotteryStatus.PENDING_VRF &&
                block.number > games[currentGameId].blockNumberRequest + 1000);
    }

    function performUpkeep(bytes calldata performData) external override {
        if (
            (games[currentGameId].closeTime < block.timestamp &&
                currentLotteryStatus == LotteryStatus.OPEN) ||
            (currentLotteryStatus == LotteryStatus.PENDING_VRF &&
                block.number > games[currentGameId].blockNumberRequest + 1000)
        ) {
            LotteryGame storage game = games[currentGameId];

            if (game.tickets.length == 0) {
                if (stopLottery) {
                    currentLotteryStatus = LotteryStatus.STOPPED;
                    return;
                }
                currentLotteryStatus = LotteryStatus.OPEN;
                emit LotteryResult(
                    currentGameId,
                    0,
                    address(0),
                    0,
                    game.nextLotteryPool,
                    0
                );

                LotteryGame storage nextLottery = games[currentGameId + 1];
                _setupNextLotteryStartTime(nextLottery, game.closeTime);
                nextLottery.winnerPool = game.nextLotteryPool;

                currentGameId++;

                return;
            } else {
                currentLotteryStatus = LotteryStatus.PENDING_VRF;
                uint256 id = VRFCoordinatorV2Interface(chainLinkVRF)
                    .requestRandomWords(
                        keyHash,
                        subId,
                        minimumRequestConfirmations,
                        callBackGasLimit,
                        1
                    );
                game.blockNumberRequest = uint64(block.number);
                game.requestId = id;
                emit VRFRequested(id);
            }
        }
    }

    /**
     * @dev function called by Chainlink VRF with random numbers
     * @param requestId id provided when the request was made
     * @param randomWords array of random numbers
     */
    function rawFulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) external {
        if (msg.sender != chainLinkVRF) {
            revert OnlyCoordinatorCanFulfill(msg.sender, chainLinkVRF);
        }
        fulfillRandomWords(requestId, randomWords);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal {
        if (requestId != games[currentGameId].requestId) {
            revert();
        }
        if (currentLotteryStatus != LotteryStatus.PENDING_VRF) {
            revert();
        }
        LotteryGame storage game = games[currentGameId];

        uint256 max = game.tickets.length - 1;
        uint256 min = 0;
        uint256 guess;

        uint256 winningTicket = (randomWords[0] % game.totalTicketsBought);
        address winner;

        while (min <= max) {
            guess = (min + max) / 2;

            if (
                winningTicket >= game.tickets[guess].startIndex &&
                winningTicket <= game.tickets[guess].endIndex
            ) {
                winner = game.tickets[guess].player;
                break;
            }

            if (game.tickets[guess].startIndex > winningTicket) {
                max = guess - 1;
            } else {
                min = guess + 1;
            }
        }

        if (winner == address(0)) {
            currentLotteryStatus = LotteryStatus.ERROR;
            return;
        }

        if (stopLottery) {
            currentLotteryStatus = LotteryStatus.STOPPED;

            _transferETH(winner, game.winnerPool + game.nextLotteryPool);
            _transferETH(bankRoll, game.bankrollPool);

            emit LotteryResult(
                currentGameId,
                winningTicket,
                winner,
                game.winnerPool + game.nextLotteryPool,
                0,
                game.charityPool
            );
            charityFunds += game.charityPool;
            currentGameId++;
        } else {
            currentLotteryStatus = LotteryStatus.OPEN;

            _transferETH(winner, game.winnerPool);
            _transferETH(bankRoll, game.bankrollPool);

            emit LotteryResult(
                currentGameId,
                winningTicket,
                winner,
                game.winnerPool,
                game.nextLotteryPool,
                game.charityPool
            );
            LotteryGame storage nextLottery = games[currentGameId + 1];

            _setupNextLotteryStartTime(nextLottery, game.closeTime);

            nextLottery.winnerPool = game.nextLotteryPool;
            charityFunds += game.charityPool;
            currentGameId++;
        }
    }

    function _setupNextLotteryStartTime(
        LotteryGame storage nextLottery,
        uint64 currentLotteryCloseTime
    ) internal {
        if (currentMonth == 11) {
            currentMonth = 0;
            currentYear += 1;
            nextLottery.closeTime =
                currentLotteryCloseTime +
                (uint64(MONTH_DURATION[currentMonth]) * 1 days);
        } else {
            currentMonth += 1;
            if (currentMonth == 1) {
                if (
                    currentYear % 4 == 0 &&
                    (currentYear % 100 != 0 || currentYear % 400 == 0)
                ) {
                    nextLottery.closeTime = currentLotteryCloseTime + (29 days);
                } else {
                    nextLottery.closeTime = currentLotteryCloseTime + (28 days);
                }
            } else {
                nextLottery.closeTime =
                    currentLotteryCloseTime +
                    (uint64(MONTH_DURATION[currentMonth]) * 1 days);
            }
        }
    }

    function _transferETH(address to, uint256 amount) internal {
        (bool success, ) = payable(to).call{value: amount, gas: 3000}("");
        if (!success) {
            (bool _success, ) = weth.call{value: amount}(
                abi.encodeWithSignature("deposit()")
            );
            if (!_success) {
                revert();
            }
            IERC20(weth).safeTransfer(to, amount);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig() external view returns (uint16, uint32, bytes32[] memory);

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(
    uint64 subId
  ) external view returns (uint96 balance, uint64 reqCount, address owner, address[] memory consumers);

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}