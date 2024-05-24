// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { AutomationCompatibleInterface } from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libraries/SearchUtils.sol";
import "./LotteryShares.sol";
import "./DrawConsumer.sol";
import "./LotteryAgent.sol";
import "./LotteryTicket.sol";

/// @title Handles logic for a toto-like game system.
/// @dev Uses Chainlink's Logic-based Upkeep System to automate ticket processing and prize allocation.
contract FairLottery is AutomationCompatibleInterface {

    struct Result {
        // draw id
        uint256 drawId;
        // timing before tickets for this draw expire
        uint256 expiryTimestamp;
        // total prize pool for this draw
        uint256 totalDrawPool;
        // number of winners per tier
        uint256[7] prizeWinners;
        // total prizes allocated per winner per tier
        uint256[7] prizeTierAllocations;
        // last checked ticket for winnings after a draw
        uint256 lastIndexChecked;
        // last checked expired ticket to sweep
        uint256 lastIndexSweeped;
        // is the prize finalized for this draw
        bool isPrizeDetermined;
    }

    /// @dev Last Draw ID.
    uint256 private lastDrawId;

    /// @dev Number of tickets to process per batch.
    uint256 private ticketBatchCount = 75;

    /// @dev Mapping of draw ID to results.
    mapping (uint256 => Result) public results;

    /// @dev Duration before tickets expire after a draw.
    uint256 public claimDuration = 7 days;
    
    /// @dev % Allocated for Burn, Ops, Jackpot.
    uint256 public constant PRE_DISTRIBUTION_PERC = 5; 
    /// @dev % Allocated for different prize tiers (1, 2, 3, 4, 5, 6, 7)
    uint256[] public PRIZE_TIER_PERCENTAGES = [30, 20, 15, 12, 10, 8, 5];
    
    /// @dev Interface for ERC20 token
    IERC20 paymentToken;
    /// @dev Interface for DrawConsumer
    DrawConsumer drawConsumer;
    /// @dev Interface for LotteryAgent
    LotteryAgent agentManager;
    /// @dev Interface for LotteryTicket
    LotteryTicket ticketManager;
    /// @dev Interface for LotteryShares
    LotteryShares sharesManager;

    /// @dev Amount of tokens reserved for claims/rewards.
    uint256 public reservedForRewards;

    /// @dev Amount of tokens reserved for the next draw.
    mapping (uint256 => uint256) public drawIdToPoolReserves;
    uint256 public totalPoolReserves;

    /// @dev Mapping of recipient address to claimable token amounts.
    mapping (address => uint256) public claimableFees;

    /// @dev Multi-sig Address to receive Ops fees.
    address public opsFeeAddress;

    /// @dev Multi-sig Address to receive Jackpot Tokens.
    address public jackpotPoolAddress;
    
    event PrizeTierAllocation(uint256 drawId, uint256[7] initialTierAllocations, uint256[7] finalTierAllocations);
    event PrizeAllocated(uint256 drawId, uint256 totalUnitsForRedistribution, uint256 totalRolloverAmount);
    event WinningTicketFound(uint256 ticketId, uint256 ticketSize, uint256 matches, bool isAdditionalMatch, uint256[7] winningTiers);
    event PrizeClaimed(address indexed owner, uint256 ticketId, uint256[7] winningTiers, uint256 prizeAmount);
    event DrawCommitted(address admin, uint256 drawId, uint256 requestId, uint256 preDistributionAllocation, uint256 currentDrawPool);
    event AddressesUpdated(address oldOpsFeeAddress, address newOpsFeeAddress);
    event ExpiryDurationUpdated(uint256 oldExpiry, uint256 newExpiry);
    event TicketBatchCountUpdated(uint256 oldBatchCount, uint256 newBatchCount);
    event JackpotActivated(address admin, uint256 jackpotAmount);
    event ExpiredTicketsSwept(uint256 drawId);

    constructor(
        address _opsFeeAddress,
        address _jackpotPoolAddress,
        address paymentTokenAddress,
        address drawConsumerAddress,
        address lotteryAgentAddress,
        address lotteryTicketAddress,
        address lotterySharesAddress
    ) 
    {
        opsFeeAddress = _opsFeeAddress;
        jackpotPoolAddress = _jackpotPoolAddress;

        // Warning: This token cannot be USDT as the expected boolean return value will be absent.
        paymentToken = IERC20(paymentTokenAddress); 
        drawConsumer = DrawConsumer(drawConsumerAddress);
        agentManager = LotteryAgent(lotteryAgentAddress);
        ticketManager = LotteryTicket(lotteryTicketAddress);
        sharesManager = LotteryShares(lotterySharesAddress);
    }

    /// @notice Returns the distribution for the next draw based on the current balances.
    function GetCurrentPrizePool() public view returns (
        uint256 totalPool,
        uint256 preDistributionAllocation,
        uint256 currentDrawPool
    ) {
        // Lock in prize pool based on current balances.
        totalPool = paymentToken.balanceOf(address(this)) - reservedForRewards - totalPoolReserves;
        
        preDistributionAllocation = totalPool * PRE_DISTRIBUTION_PERC / 100; // 5% each for burn, ops, and jackpot reserve.

        uint256 postDistributionAllocation = totalPool - (preDistributionAllocation * 3); // Get 85%
        currentDrawPool = postDistributionAllocation / 2; // 50% of remaining 85%
    }

    /// @dev Initiated by the DrawConsumer to lock the prize pool and prevent further ticket purchases.
    function CloseDraw(uint256 drawId, uint256 requestId) external {
        require(msg.sender == address(drawConsumer), "Invalid sender");
        require(ticketManager.drawIdToTicketCount(drawId) > 0, "No Tickets");

        lastDrawId = drawId;

        // Lock in prize pool based on current balances.
        (
            , 
            uint256 preDistributionAllocation,
            uint256 currentDrawPool
        ) = GetCurrentPrizePool();

        require(paymentToken.transfer(0x000000000000000000000000000000000000dEaD, preDistributionAllocation), "Transfer Failed"); // 5% Burnt
        require(paymentToken.transfer(opsFeeAddress, preDistributionAllocation), "Transfer Failed"); // 5% to Ops Address
        require(paymentToken.transfer(jackpotPoolAddress, preDistributionAllocation), "Transfer Failed"); // 5% for Jackpot Pool.

        // Affix the pool size and so new tickets count towards next draw.
        results[drawId].drawId = drawId;
        results[drawId].totalDrawPool = currentDrawPool;

        reservedForRewards += currentDrawPool;

        // Release any prize pool reserves (jackpot/future ticket sales) for the next draw.
        totalPoolReserves -= drawIdToPoolReserves[drawId + 1];
        drawIdToPoolReserves[drawId + 1] = 0;
        
        emit DrawCommitted(msg.sender, drawId, requestId, preDistributionAllocation, currentDrawPool);
    }

    // Checks tickets in a draw for winnings. 
    // All tickets need to be checked before prizes can be allocated.
    function checkTicketsForWinnings(
        uint256 drawId,
        uint256 startingIndex,
        uint256 finalIndex,
        uint256[6] memory winningNumbers,
        uint256 additionalNumber
        ) internal 
    {
        uint256 _drawId = drawId;
        for (uint256 index = startingIndex; index < finalIndex; index += 1) {
            uint256 ticketId = ticketManager.drawIdToTicketIds(_drawId, index);
            (
                ,
                uint256[12] memory numbers,
                uint256 ticketSize,
                ,,
            ) = ticketManager.GetTicket(ticketId);

            uint256[] memory ticketNumbers = new uint256[](ticketSize);
            for (uint256 i = 0; i < ticketSize; i += 1) {
                ticketNumbers[i] = numbers[i];
            }

            // Find number of matches
            uint256 matches = 0;
            for (uint256 i = 0; i < winningNumbers.length; i += 1) {
                if (SearchUtils.searchArray(ticketNumbers, winningNumbers[i])) {
                    matches += 1;
                }
            }

            bool isAdditionalMatch = SearchUtils.searchArray(ticketNumbers, additionalNumber);

            uint256[7] memory winningTiers = sharesManager.getWinningTiers(ticketSize, matches, isAdditionalMatch);
            ticketManager.AllocateWinningShares(ticketId, winningTiers);

            if (matches >= 3) {
                emit WinningTicketFound(ticketId, ticketSize, matches, isAdditionalMatch, winningTiers);
            }

            for (uint256 k = 0; k < 7; k += 1) {
                results[_drawId].prizeWinners[k] += winningTiers[k]; // First Prize
            }
        }
    }

    /// @dev Processes all tickets to count total number of winning shares per tier for re-distribution.
    function processWinnerPrizes() internal {
        require(!results[lastDrawId].isPrizeDetermined, "Already initialized");
        
        (, uint256[6] memory winningNumbers, uint256 additionalNumber) = drawConsumer.GetDraw(lastDrawId);
        require(additionalNumber > 0, "Not drawn yet");

        uint256 checksToPerform = ticketManager.drawIdToTicketCount(lastDrawId) - results[lastDrawId].lastIndexChecked;
        if (checksToPerform > ticketBatchCount) {
            checksToPerform = ticketBatchCount;
        }

        // Find out how many winners for each category we have.
        // We need to do this first in order to determine how the reward pools are split.
        checkTicketsForWinnings(lastDrawId, results[lastDrawId].lastIndexChecked, results[lastDrawId].lastIndexChecked + checksToPerform, winningNumbers, additionalNumber);
        results[lastDrawId].lastIndexChecked += checksToPerform;
    }

    /// @dev Calculates and allocates how much rewards will be distribtued per tier.
    function allocateDrawPrizes() internal {
        require(!results[lastDrawId].isPrizeDetermined, "Already allocated");

        // We have checked through all tickets for winning ones and can now allocate the prizes.
        uint256 totalDrawPool = results[lastDrawId].totalDrawPool;
        uint256[7] memory initialTierAllocations;
        uint256[7] memory finalTierAllocations;

        uint256 totalRolloverAmount;
        uint256 totalUnitsForRedistribution;

        // First Prize - Receives rollover from 2-7th, but doesn't give rollover.
        uint256 firstPrize = totalDrawPool * PRIZE_TIER_PERCENTAGES[0] / 100; // 30% of the prize pool
        initialTierAllocations[0] = firstPrize;
        finalTierAllocations[0] = firstPrize;

        if (results[lastDrawId].prizeWinners[0] > 0) {
            // Add weight in case of rollover distribution.
            totalUnitsForRedistribution += PRIZE_TIER_PERCENTAGES[0];

            // Track how much prizes each winner gets for each tier (without rollover).
            results[lastDrawId].prizeTierAllocations[0] = firstPrize / results[lastDrawId].prizeWinners[0];
        } else {
            reservedForRewards -= firstPrize; // Return first prize back to the pool.
            finalTierAllocations[0] = 0;
        }

        // Second Prize onwards
        for (uint256 i = 1; i < PRIZE_TIER_PERCENTAGES.length; i += 1) {
            uint256 initialTierPrize = totalDrawPool * PRIZE_TIER_PERCENTAGES[i] / 100; // The initial % allocated to this tier.
            uint256 prizeTier = i; // Check through 2-7th.
            initialTierAllocations[prizeTier] = initialTierPrize;

            if (results[lastDrawId].prizeWinners[prizeTier] > 0) {
                // Add weight in case of rollover distribution.
                totalUnitsForRedistribution += PRIZE_TIER_PERCENTAGES[i];

                // Track how much prizes each winner gets for each tier (without rollover).
                results[lastDrawId].prizeTierAllocations[prizeTier] = initialTierPrize / results[lastDrawId].prizeWinners[prizeTier];
            } else {
                totalRolloverAmount += initialTierPrize;
            }
        }

        // Re-distribute rewards to every tier with winners.
        if (totalUnitsForRedistribution > 0) {
            for (uint256 i = 0; i < PRIZE_TIER_PERCENTAGES.length; i += 1) {
                uint256 prizeTier = i;
                uint256 rewardThisTier = totalRolloverAmount * PRIZE_TIER_PERCENTAGES[i] / totalUnitsForRedistribution;

                if (results[lastDrawId].prizeWinners[prizeTier] > 0) {
                    // Calculate and add how much extra each winner in this tier gets from any rollover.
                    uint256 extraRewardsPerWinner = rewardThisTier / results[lastDrawId].prizeWinners[prizeTier];
                    results[lastDrawId].prizeTierAllocations[prizeTier] += extraRewardsPerWinner;

                    finalTierAllocations[prizeTier] = results[lastDrawId].prizeTierAllocations[prizeTier] * results[lastDrawId].prizeWinners[prizeTier];
                }
            }
        } else {
            // No winners at all from 2-7, un-reserve prize pool.
            reservedForRewards -= totalDrawPool - firstPrize; // Remaining 70% of the prize pool.

            finalTierAllocations[1] = 0;
            finalTierAllocations[2] = 0;
            finalTierAllocations[3] = 0;
            finalTierAllocations[4] = 0;
            finalTierAllocations[5] = 0;
            finalTierAllocations[6] = 0;
        }

        results[lastDrawId].isPrizeDetermined = true;
        emit PrizeAllocated(lastDrawId, totalUnitsForRedistribution, totalRolloverAmount);
        emit PrizeTierAllocation(lastDrawId, initialTierAllocations, finalTierAllocations);
    }

    /// @dev Handles allocation of the prizes. All tickets must be processed before this.
    function finalizeWinnerPrizes() internal {
        // When all tickets processed, allocate draw prizes and set expiry.
        require(results[lastDrawId].lastIndexChecked >= ticketManager.drawIdToTicketCount(lastDrawId), "Not ready");

        allocateDrawPrizes();
        results[lastDrawId].expiryTimestamp = block.timestamp + claimDuration;
    }

    /// @dev Allows activating of jackpot for next draw (skip 1).
    function ActivateJackpot(uint256 jackpotAmount) external {
        require(paymentToken.transferFrom(msg.sender, address(this), jackpotAmount), "Transfer Failed");

        // Add jackpot amount into the subsequent draw.
        drawIdToPoolReserves[drawConsumer.GetNextDrawId() + 1] += jackpotAmount;
        totalPoolReserves += jackpotAmount;

        emit JackpotActivated(msg.sender, jackpotAmount);
    }

    /// @dev Allows anyone to unlock allocations from expired winning tickets.
    function SweepExpiredTickets(uint256[] memory _drawIds, uint256 batchCount) external {
        for (uint256 i = 0; i < _drawIds.length; i += 1) {
            Result storage result = results[_drawIds[i]];
            require(result.totalDrawPool > 0, "Invalid draw");
            require(result.expiryTimestamp < block.timestamp, "Not expired yet");

            uint256 startingIndex = result.lastIndexSweeped;
            uint256 lastIndex = ticketManager.drawIdToTicketCount(_drawIds[i]);
            if (result.lastIndexSweeped + batchCount < lastIndex) {
                lastIndex = result.lastIndexSweeped + batchCount;
            }

            for (uint256 j = startingIndex; j < lastIndex; j += 1) {
                uint256 ticketId = ticketManager.drawIdToTicketIds(_drawIds[i], j);
                (
                    ,
                    ,
                    ,
                    ,
                    bool isWinningsClaimed,
                    uint256[7] memory prizeTiers
                ) = ticketManager.GetTicket(ticketId);
            
                uint256 totalPrizeAmount;
                if (!isWinningsClaimed) {
                    for (uint256 k = 0; k < 7; k += 1) {
                        totalPrizeAmount += result.prizeTierAllocations[k] * prizeTiers[k];
                    }
                }

                reservedForRewards -= totalPrizeAmount;
            }

            result.lastIndexSweeped = lastIndex;
            emit ExpiredTicketsSwept(_drawIds[i]);
        }
    }

    /// @notice Purchase multiple tickets for future draws (`drawId`) under agent (`agentCode`)
    /// @dev (`numbers`) must start with the purchased numbers in ascending order and be unique.
    /// There must be trailing zeroes for leftover slots.
    /// @dev (`agentCode`) can be left empty or "" if there is no agent.
    function BuyTickets(uint256 drawId, uint256[12][] memory numbers, string memory agentCode) external {
        // Can only buy for subsequent draws.
        require(drawId >= drawConsumer.GetNextDrawId(), "Expired Draw");

        // Try entrusting this user to specified agent.
        // Code registration handled within.
        agentManager.EntrustAgent(msg.sender, agentCode);
        
        uint256 totalFees = ticketManager.BuyTickets(
            msg.sender,
            drawId,
            numbers
        );

        // Track how much of the fees are going into the prize pool.
        uint256 allocationToPrizePool = totalFees;

        // Get agent tiers and allocate fees.
        (
            address[3] memory userAgents,
            uint256[3] memory agentFees
        ) = agentManager.GetAgentFees(totalFees, msg.sender);

        for (uint256 i = 0; i < userAgents.length; i += 1)  {
            if (userAgents[i] != address(0)) {
                claimableFees[userAgents[i]] += agentFees[i];
                reservedForRewards += agentFees[i];
                allocationToPrizePool -= agentFees[i];
            }
        }

        require(paymentToken.transferFrom(msg.sender, address(this), totalFees), "Transfer Failed");

        // If this ticket is for future draws, don't add it to the current prize pool.
        if (drawId > drawConsumer.GetNextDrawId()) {
             drawIdToPoolReserves[drawId] += allocationToPrizePool;
             totalPoolReserves += allocationToPrizePool;
        }
    }

    /// @notice Returns winnings information for (`ticketIds`) specified.
    /// @dev Returns default values if prizes not determined yet.
    function GetTicketWinnings(uint256[] memory ticketIds) 
        public view 
        returns (
            bool[] memory isWinners,
            uint256[7][] memory prizeTiers,
            uint256[] memory prizeAmounts
        )
    {
        isWinners = new bool[](ticketIds.length);
        prizeTiers = new uint256[7][](ticketIds.length);
        prizeAmounts = new uint256[](ticketIds.length);

        for (uint256 i = 0; i < ticketIds.length; i += 1) {
            uint256 ticketId = ticketIds[i];
            (
                uint256 drawId,
                ,
                ,
                ,
                ,
                uint256[7] memory _prizeTiers
            ) = ticketManager.GetTicket(ticketId);

            if (!results[drawId].isPrizeDetermined) {
                // Prizes not determined yet
                continue;
            }

            uint256 totalPrizeAmount;
            for (uint256 k = 0; k < 7; k += 1) {
                totalPrizeAmount += results[drawId].prizeTierAllocations[k] * _prizeTiers[k];
            }

            isWinners[i] = totalPrizeAmount > 0;
            prizeAmounts[i] = totalPrizeAmount;
            prizeTiers[i] = _prizeTiers;
        }
    }

    /// @notice Allow users to claim prizes for winning tickets.
    function ClaimPrize(uint256 ticketId) external {
        // Check for winnings.
        uint256[] memory ticketIds = new uint256[](1);
        ticketIds[0] = ticketId;
        (bool[] memory isWinners, uint256[7][] memory prizeTiers, uint256[] memory prizeAmounts) = GetTicketWinnings(ticketIds);
        require(isWinners[0], "No winnings");

        // Mark as claimed and validate ownership/status/expiry.
        (
            uint256 drawId,
            ,
            ,
            address owner,
            bool isWinningsClaimed
            ,
        ) = ticketManager.GetTicket(ticketId);
        require(owner == msg.sender && !isWinningsClaimed, "Invalid Ticket");
        ticketManager.MarkAsClaimed(ticketId);

        require(results[drawId].expiryTimestamp > block.timestamp, "Ticket expired");    

        uint256 claimablePrize = prizeAmounts[0];

        // Get agent tiers and allocate fees.
        (
            address[3] memory userAgents,
            uint256[3] memory agentFees
        ) = agentManager.GetAgentFees(claimablePrize, msg.sender);

        for (uint256 i = 0; i < userAgents.length; i += 1)  {
            if (userAgents[i] != address(0)) {
                claimableFees[userAgents[i]] += agentFees[i];
                claimablePrize -= agentFees[i];
            }
        }

        // Transfer winnings to owner.
        require(paymentToken.transfer(msg.sender, claimablePrize), "Transfer Failed");
        reservedForRewards -= claimablePrize;
    
        emit PrizeClaimed(msg.sender, ticketId, prizeTiers[0], claimablePrize);
    }

    /// @notice Allow users to claim agent fees.
    function ClaimFees() external {
        uint256 fees = claimableFees[msg.sender];
        claimableFees[msg.sender] = 0;

        require(fees > 0, "No Fees");
        
        // Transfer winnings to owner.
        require(paymentToken.transfer(msg.sender, fees), "Transfer Failed");
        reservedForRewards -= fees;
    }
    
    /// @dev Returns results based on draw IDs
    function GetResults(uint256[] memory ids) 
        external view 
        returns (
            uint256[] memory resultIds,
            uint256[] memory expiryTimestamps,
            uint256[] memory totalDrawPools,
            uint256[7][] memory prizeWinners,
            uint256[7][] memory prizeTierAllocations,
            uint256[] memory lastIndexesChecked,
            bool[] memory arePrizesDetermined
        ) 
    {
        resultIds = new uint256[](ids.length);
        expiryTimestamps = new uint256[](ids.length);
        totalDrawPools = new uint256[](ids.length);
        prizeWinners = new uint256[7][](ids.length);
        prizeTierAllocations = new uint256[7][](ids.length);
        lastIndexesChecked = new uint256[](ids.length);
        arePrizesDetermined = new bool[](ids.length);

        for (uint256 i = 0; i < ids.length; i += 1) {
            uint256 drawId = ids[i];

            resultIds[i] = drawId;
            expiryTimestamps[i] = results[drawId].expiryTimestamp;
            totalDrawPools[i] = results[drawId].totalDrawPool;
            prizeWinners[i] = results[drawId].prizeWinners;
            prizeTierAllocations[i] = results[drawId].prizeTierAllocations;
            lastIndexesChecked[i] = results[drawId].lastIndexChecked;
            arePrizesDetermined[i] = results[drawId].isPrizeDetermined;
        }
    }

    
    /// @dev Used by Chainlink Automation to check if performUpkeep needs to be called.
    /// @dev Checks if prizes are ready for the latest draw.
    function checkUpkeep( bytes calldata /* checkData */) external view override
    returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        if (results[lastDrawId].isPrizeDetermined) {
            upkeepNeeded = false;
        } else {
            (,, uint256 additionalNumber) = drawConsumer.GetDraw(lastDrawId);
            upkeepNeeded = additionalNumber > 0;
        }
    }

    /// @dev Used by Chainlink Automation to run custom logic if checkUpkeep returns true.
    /// @dev Processes and allocates the prizes to winners for the lateest draw.
    function performUpkeep(bytes calldata /* performData */) external override {
        if (results[lastDrawId].lastIndexChecked >= ticketManager.drawIdToTicketCount(lastDrawId)) {
            finalizeWinnerPrizes();
        } else {
            processWinnerPrizes();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title Contains Binary Search utility functions for uint256.
/// @dev Assumes that the input array is sorted in ascending order.
library SearchUtils {
    /// @dev Returns if (`target`) exists in (`sortedArr`).
    /// (`sortedArr`) must be sorted in ascending order to guarantee accurate results.
    function searchArray(uint256[] memory sortedArr, uint256 target) internal pure returns (bool) {
        uint256 low = 0;
        uint256 high = sortedArr.length - 1;

        while (low <= high) {
            uint256 mid = low + (high - low) / 2;
            if (sortedArr[mid] == target) {
                return true;
            }
            if (sortedArr[mid] < target) {
                low = mid + 1;
            }
            else {
                if (mid == 0) {
                    return false;
                }

                high = mid - 1;
            }
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title Handles Access Control for a single Owner/multiple Admins.
/// @dev Facilitates ACL via onlyOwner modifiers.
contract Ownable {
    /// @notice Address with Owner privileges.
    address public ownerAddress;
    address public potentialOwner;

    event OwnershipTransferred(address oldOwner, address newOwner);
    event OwnerNominated(address potentialOwner);
    
    /// @dev Throws if the sender is not the owner.
    function _onlyOwner() private view {
        require(msg.sender == ownerAddress, "Not Owner");
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /// @dev Transfers ownership to (`newOwner`).
    function TransferOwnership(address pendingOwner) external onlyOwner {
        require(pendingOwner != address(0), "Invalid owner");
        potentialOwner = pendingOwner;
        emit OwnerNominated(potentialOwner);
    }

    /// @dev Allows nominated owner to accept ownership.
    function AcceptOwnership() external {
        require(msg.sender == potentialOwner, 'Not nominated');
        emit OwnershipTransferred(ownerAddress, potentialOwner);
        ownerAddress = potentialOwner;
        potentialOwner = address(0); 
    }

    /// @dev Revoke ownership.
    /// Transfer to zero address to renounce ownership to disable `onlyOwner` functionality.
    function RevokeOwnership() external onlyOwner {
        emit OwnershipTransferred(ownerAddress, address(0));
        ownerAddress = address(0);
        potentialOwner = address(0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./libraries/Ownable.sol";

/// @title Handles Ticket-related functions in the FairLottery system.
/// @notice Facilitates purchasing and processing of tickets.
contract LotteryTicket is Ownable {

    address private oracleAddress;

    // Modifier to restrict who can call a given function
    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Caller is not the oracle");
        _;
    }

    struct Ticket {
        // id of draw to check against.
        uint256 drawId;
        // selected numbers. LOWEST_DIGIT <= x <= HIGHEST_DIGIT
        uint256[12] numbers;
        // purchased numbers. MIN_TICKET_SIZE <= x <= MAX_TICKET_SIZE
        uint256 ticketSize;
        // owner of this ticket
        address owner;
        // is winnings claimed?
        bool isWinningsClaimed;
        // winning shares per tier
        uint256[7] winningTiers;
    }

    /// @dev Total tickets bought across all draws.
    uint256 public totalTickets;

    /// @dev Mapping of owner address to (drawId > list of bought ticket IDs).
    mapping (address => mapping(uint256 => uint256[])) private ownedTicketsPerDraw; 
    /// @dev Mapping of owner address to (drawId > total tickets bought).
    mapping (address => mapping(uint256 => uint256)) public ownedTicketPerDrawCount;

    /// @dev Mapping of owner address to list of bought ticket IDs.
    mapping (address => uint256[]) private ownedTickets;
    /// @dev Mapping of owner address to total tickets bought.
    mapping (address => uint256) public ownedTicketCount;

    /// @dev Mapping of drawId to list of bought ticket IDs.
    mapping (uint256 => uint256[]) public drawIdToTicketIds;
    /// @dev Mapping of drawId to total tickets bought.
    mapping (uint256 => uint256) public drawIdToTicketCount;

    /// @dev Mapping of ticketId to ticket info.
    mapping (uint256 => Ticket) private tickets;
        
    /// @dev Lowest purchaseable number.
    uint256 public constant LOWEST_DIGIT = 1;
    /// @dev Highest purchaseable number.
    uint256 public constant HIGHEST_DIGIT = 49;

    /// @dev Minimum count for numbers purchased in a ticket.
    uint256 public constant MIN_TICKET_SIZE = 6;
    /// @dev Maximum count for numbers purchased in a ticket.
    uint256 public constant MAX_TICKET_SIZE = 12;

    /// @dev Multiplied cost based on ticket size. (6, 7, 8, 9, 10, 11, 12)
    uint256[] public TICKET_PRICE_MULTIPLIER = [1, 7, 28, 84, 210, 462, 924];
    
    /// @dev Ticket price in USDT. (2 USD)
    uint256 public baseTicketPrice = 2 * 1e18;

    /// @dev Oracle Response
    uint256 public oracleResponse = 1e18;

    /// @dev Address of the lottery system.
    address public fairLotteryAddress;
    
    event TicketPurchased(address indexed owner, uint256 ticketId, uint256 drawId, uint256[12] numbers);
    event AddressesChanged(address oldLotteryAddress, address newLotteryAddress);
    event TicketWinningsClaimed(uint256 ticketId);
    event TicketTierAllocated(uint256 ticketId, uint256[7] winningTiers);
    event RequestFulfilled(uint256 data);

    // Ownership will be renounced after addresses updated.
    constructor () 
    {
        ownerAddress = msg.sender;
        oracleAddress = 0x48d9e170cd3400b3B53BE264D62258B2d25B90Ce;
    }

    /// @dev Allows only the Owner to update addresses references.
    function UpdateAddresses(address _fairLotteryAddress) external onlyOwner {
        emit AddressesChanged(fairLotteryAddress, _fairLotteryAddress);
        fairLotteryAddress = _fairLotteryAddress;
    }

    /// @dev Purchases single/mutliple tickets for draw (`drawId`) for (`user`).
    /// @dev (`numbers`) must start with the purchased numbers in ascending order and be unique.
    /// There must be trailing zeroes for leftover slots.
    /// @dev Returns the total token cost of the ticket.
    function BuyTickets(address user, uint256 drawId, uint256[12][] memory numbers) 
    external returns (uint256 totalFees) {
        require(msg.sender == fairLotteryAddress, "Invalid sender");
        
        // Valid ticket numbers must be in ascending order without duplicates.
        for (uint256 i = 0; i < numbers.length; i += 1) {
            uint256[12] memory ticketNumbers = numbers[i];
            require(ticketNumbers.length == MAX_TICKET_SIZE, "Invalid ticket numbers");

            uint256 ticketSize;
            uint256 latestNumber;
            for (uint256 j = 0; j < ticketNumbers.length; j += 1) {
                if (ticketNumbers[j] > 0) {
                    ticketSize += 1;

                    // This also prevents duplicate since it must be ascending.
                    require(ticketNumbers[j] > latestNumber, "Non-ascending ticket numbers");
                    require(ticketNumbers[j] >= LOWEST_DIGIT && ticketNumbers[j] <= HIGHEST_DIGIT, "Number out of range");
                    latestNumber = ticketNumbers[j];
                } else {
                    break;
                }
            }

            require(ticketSize >= MIN_TICKET_SIZE, "Too little numbers on ticket");
 
            // Collect payment for this ticket.
            uint256 paymentCost = GetPaymentCost(ticketSize);
            
            totalFees += paymentCost;

            // Assign the ticket.
            uint256 ticketId = totalTickets + i + 1;
            tickets[ticketId].drawId = drawId;
            tickets[ticketId].numbers = ticketNumbers;
            tickets[ticketId].ticketSize = ticketSize;
            tickets[ticketId].owner = user;

            drawIdToTicketIds[drawId].push(ticketId);

            ownedTicketsPerDraw[user][drawId].push(ticketId);
            ownedTicketPerDrawCount[user][drawId] += 1;

            ownedTickets[user].push(ticketId);
            ownedTicketCount[user] += 1;

            emit TicketPurchased(user, ticketId, drawId, ticketNumbers);
        }

        drawIdToTicketCount[drawId] += numbers.length;
        totalTickets += numbers.length;

        return (totalFees);
    }

    /// @dev Returns tokens needed to purchase the ticket based on (`ticketSize`).
    function GetPaymentCost(uint256 ticketSize) public view returns (uint256 tokensNeeded) {
        require(ticketSize >= MIN_TICKET_SIZE && ticketSize <= MAX_TICKET_SIZE, "Invalid ticket size");
        uint256 combinationMultiplier = TICKET_PRICE_MULTIPLIER[ticketSize - MIN_TICKET_SIZE];

        uint256 tokensNeededPerLine = GetTokensNeededForTicket();
        tokensNeeded = tokensNeededPerLine * combinationMultiplier;
    }

    function GetTokensNeededForTicket() public view
    returns (uint256 tokensNeeded) {
        // For local tests, fixed at 2 * 1e18 for tokens needed.
        // tokensNeeded = baseTicketPrice;

        // For testnet/mainnet, use oracle based on mainnet pricing.
        // Oracle Response is the USD value of the token asset in WEI.
        tokensNeeded = baseTicketPrice * 1e18 / oracleResponse;
    }

    /// @dev Marks a ticket as claimed by the lottery system.
    function MarkAsClaimed(uint256 ticketId) external {
        require(msg.sender == fairLotteryAddress, "Invalid sender");

        tickets[ticketId].isWinningsClaimed = true;
        
        emit TicketWinningsClaimed(ticketId);
    }

    /// @dev Allocates a ticket's winning shares by the lottery system.
    function AllocateWinningShares(uint256 ticketId, uint256[7] memory winningTiers) external {
        require(msg.sender == fairLotteryAddress, "Invalid sender");

        tickets[ticketId].winningTiers = winningTiers;

        emit TicketTierAllocated(ticketId, winningTiers);
    }

    // Receive the result from the ChainLink oracle (See https://docs.linkwellnodes.io/services/direct-request-jobs/testnets/Arbitrum-Sepolia-Testnet-Jobs)
    function fulfill(uint256 _data) external onlyOracle {
        emit RequestFulfilled(_data);
        oracleResponse = _data;
    }

    /// @dev Returns the number of tickets bought for (`drawId`).
    function GetTicketsForDraw(uint256 drawId) 
    external view returns (uint256 numTickets) {
        numTickets = drawIdToTicketIds[drawId].length;
    }

    /// @notice Returns the ticket info for (`ticketId`)
    function GetTicket(uint256 ticketId) 
    external view returns (
        uint256 drawId,
        uint256[12] memory numbers,
        uint256 ticketSize,
        address owner,
        bool isWinningsClaimed,
        uint256[7] memory prizeTiers
    ) {
        drawId = tickets[ticketId].drawId;
        numbers = tickets[ticketId].numbers;
        ticketSize = tickets[ticketId].ticketSize;
        owner = tickets[ticketId].owner;
        isWinningsClaimed = tickets[ticketId].isWinningsClaimed;
        prizeTiers = tickets[ticketId].winningTiers;
    }

    /// @notice Returns multiple ticket info for (`ticketIds`)
    function GetTickets(uint256[] memory ticketIds) 
        external view 
        returns (
            uint256[] memory ids,
            uint256[] memory drawIds,
            uint256[12][] memory numbers,
            uint256[] memory ticketSizes,
            address[] memory owners,
            bool[] memory areWinningsClaimed,
            uint256[7][] memory prizeTiers
    ) {
        ids = new uint256[](ticketIds.length);
        drawIds = new uint256[](ticketIds.length);
        numbers = new uint256[12][](ticketIds.length);
        ticketSizes = new uint256[](ticketIds.length);
        owners = new address[](ticketIds.length);
        areWinningsClaimed = new bool[](ticketIds.length);
        prizeTiers = new uint256[7][](ticketIds.length);

        for (uint256 i = 0; i < ticketIds.length; i += 1) {
            uint256 ticketId = ticketIds[i];

            ids[i] = ticketId;
            drawIds[i] = tickets[ticketId].drawId;
            numbers[i] = tickets[ticketId].numbers;
            ticketSizes[i] = tickets[ticketId].ticketSize;
            owners[i] = tickets[ticketId].owner;
            areWinningsClaimed[i] = tickets[ticketId].isWinningsClaimed;
            prizeTiers[i] = tickets[ticketId].winningTiers;
        }
    }

    /// @notice Returns the latest (`count`) ticket IDs for (`owner`) filtered by (`drawId`).
    function GetLatestTicketIds(address owner, uint256 drawId, uint256 count) 
        external view 
        returns (
            uint256[] memory ids
    ) {
        require(count <= ownedTicketPerDrawCount[owner][drawId], "Not enough tickets bought");
        
        ids = new uint256[](count);

        uint256 index = 0;
        for (uint256 i = ownedTicketPerDrawCount[owner][drawId] - count; i < ownedTicketPerDrawCount[owner][drawId]; i += 1) {
            uint256 ticketId = ownedTicketsPerDraw[owner][drawId][i];

            ids[index] = ticketId;
            index += 1;
        }
    }

    /// @notice Returns the latest (`count`) ticket IDs for (`owner`).
    function GetLatestTicketIds(address owner, uint256 count) 
        external view 
        returns (
            uint256[] memory ids
    ) {
        require(count <= ownedTicketCount[owner], "Not enough tickets bought");
        
        ids = new uint256[](count);

        uint256 index = 0;
        for (uint256 i = ownedTicketCount[owner] - count; i < ownedTicketCount[owner]; i += 1) {
            uint256 ticketId = ownedTickets[owner][i];

            ids[index] = ticketId;
            index += 1;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./libraries/Ownable.sol";


/// @title Handles Winning Shares for the Lottery System.
contract LotteryShares is Ownable {
    /// @dev Winning shares per ticket size and matching numbers.
    uint256[7][8][7] public WINNING_SHARES;

    event WinningSharesUpdated(uint256[7][8][7] winningShares);

    // Ownership will be renounced after addresses updated.
    constructor() 
    {
        ownerAddress = msg.sender;
    }

    /// @dev Allows owner to update winning shares per ticket size.
    function SetupWinningShares(uint256 ticketSize, uint256[7][8] memory winningShare)
    external onlyOwner {
        WINNING_SHARES[ticketSize - 6] = winningShare;
        emit WinningSharesUpdated(WINNING_SHARES);
    }

    /// @dev Returns the number of winning shares based on ticket size and number of matches.
    function getWinningTiers(uint256 ticketSize, uint256 winningMatches, bool isAdditionalMatch)
    external view returns (uint256[7] memory winningTiers) {
        uint256 ticketIndex = ticketSize - 6; // 6 -> index 0, 12 -> index 6

        if (winningMatches >= 3) {
            uint256 rewardIndex = (winningMatches - 3) * 2;
            winningTiers = WINNING_SHARES[ticketIndex][rewardIndex + (isAdditionalMatch ? 1 : 0)];
        }
    }

    function GetWinningShares() 
    external view returns (uint256[7][8][7] memory winningShares) {
        return WINNING_SHARES;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./libraries/Ownable.sol";

/// @title Handles Agent-related functions in the FairLottery system.
/// @notice Facilitates registering and calculation of agents and fees.
/// @dev Uses Linear Congruential Generator (LCG) to generate sequential codes that look randomized.
/// https://en.wikipedia.org/wiki/Linear_congruential_generator
/// Using the parameters from Numerical Recipes, maximum up to 2 ** 32 = 4,294,967,296.
/// This cycle period is mathetically proven to be larger than (36 ** 6), preventing conflicts.
contract LotteryAgent is Ownable {
    /// @dev Mapping of agent codes to agent address.
    mapping (string => address) public agents;
    /// @dev Mapping of agent address to agent codes.
    mapping (address => string) public agentCodes;
    
    /// @dev Returns if address has an agent code assigned.
    mapping (address => bool) public isCodeAssigned;

    /// @dev Mapping of user address to his agent address.
    mapping (address => address) public agentMapping;

    /// @dev % Fees per agent tier. (direct, 2nd, 3rd)
    uint256[3] public AGENT_FEES_PERC = [5, 3, 2];
    
    /// @dev Total number of agents registered.
    uint256 public totalAgents;

    /// @dev Address of the lottery system.
    address public fairLotteryAddress;

    /// @dev Seed (X0) for the LCG.
    uint256 private seed = 1;
    /// @dev Multiplier (a) for the LCG.
    uint256 private constant multiplier = 1664525;
    /// @dev Increment (c) for the LCG.
    uint256 private constant increment = 1013904223;
    /// @dev Modulo (m) for the LCG.
    uint256 private constant modulo = 2 ** 32;

    /// @dev Length of the agent code. Maximum possible combinations = 36 ** 6 = 2,176,782,336.
    uint256 public constant STRING_LENGTH = 6;

    /// @dev Simple mapping for base36 conversion (0-9, A-Z)
    string private constant BASE36_CHARS = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";

    event AddressesChanged(address oldLotteryAddress, address newLotteryAddress);

    event CodeRegistered(address user, string code);
    event AgentEntrusted(address user, address agent);

    // Ownership will be renounced after addresses updated.
    constructor() 
    {
        ownerAddress = msg.sender;
    }

    /// @dev Allows only the Owner to update addresses references.
    function UpdateAddresses(address _fairLotteryAddress) external onlyOwner {
        emit AddressesChanged(fairLotteryAddress, _fairLotteryAddress);
        fairLotteryAddress = _fairLotteryAddress;

    }

    /// @dev Registers and returns the agent code for (`user`).
    /// @dev To prevent overlaps, users after the 4,294,967,296th signup will not receive codes.
    function registerAgentCode(address user) internal returns (string memory code){
        require (msg.sender == fairLotteryAddress, "Invalid sender");
        require (bytes(agentCodes[user]).length == 0, "Code Exists");

        // We've already assigned all unique codes, mark this as assigned without a code.
        if (totalAgents >= modulo) {
            isCodeAssigned[user] = true;
            return ""; 
        }

        // Maximum value of seed here would be multiplier * (2 ** 32 - 1) + increment
        // Which is 7.149...e15, lower than uint256 limits. (2 ** 256 - 1).
        seed = (multiplier * seed + increment) % modulo;

        // Convert the generated number to an 8-character base36 string
        code = toBase36String(seed);

        // Store the unique code
        agentCodes[user] = code;
        agents[code] = user;
        isCodeAssigned[user] = true;

        totalAgents += 1;
        emit CodeRegistered(user, code);
    }

    /// @dev Entrusts an agent with (`agentCode`) for (`user`).
    /// Agents cannot be removed or updated.
    function EntrustAgent(address user, string memory agentCode) external {
        require (msg.sender == fairLotteryAddress, "Invalid Perms");

        // Register this user a code if he doesn't have one.
        if (!isCodeAssigned[user]) {
            registerAgentCode(user);
        }

        if (bytes(agentCode).length == 0 || agentMapping[user] != address(0) || agents[agentCode] == address(0)) {
            // No/invalid code or already entrusted, return.
            return;
        }

        require (agents[agentCode] != user, "No Self Referral");

        // Mark this user's direct agent.
        agentMapping[user] = agents[agentCode];
        emit AgentEntrusted(user, agentMapping[user]);
    }

    /// @dev Returns the agents up to 3 levels for (`user`).
    function GetUserAgents(address user) public view returns (address[3] memory userAgents) {
        if (agentMapping[user] != address(0)) {
            userAgents[0] = agentMapping[user];
        } else {
            return userAgents;
        }

        for (uint256 i = 1; i < userAgents.length; i += 1) {
            address nextAgent = agentMapping[userAgents[i - 1]];
            if (nextAgent != address(0) && !containsAddress(userAgents, nextAgent) && nextAgent != user) {
                userAgents[i] = nextAgent;
            }
        }
    }

    /// @dev Returns the agents fees up to 3 levels for (`user`) based on (`amount`).
    function GetAgentFees(uint256 amount, address user) external view 
    returns (address[3] memory userAgents, uint256[3] memory agentFees) {
        userAgents = GetUserAgents(user);

        for (uint256 i = 0; i < userAgents.length; i += 1) {
            if (userAgents[i] != address(0)) {
                agentFees[i] = amount * AGENT_FEES_PERC[i] / 100;
            }
        }
    }

    /// @dev Converts a number to a string based on BASE36_CHARS.
    function toBase36String(uint256 number) internal pure returns (string memory) {
        bytes memory buffer = new bytes(STRING_LENGTH); // Fixed length for the code
        for (uint256 i = 0; i < STRING_LENGTH; i += 1) {
            buffer[STRING_LENGTH - 1 - i] = bytes(BASE36_CHARS)[number % 36];
            number /= 36;
        }
        return string(buffer);
    }

    /// @dev Helper function to check if an address exists in array.
    function containsAddress(address[3] memory _array, address agent) internal pure returns (bool) {
        for (uint256 i = 0; i < _array.length; i++) {
            if (_array[i] == agent) {
                return true;
            }
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AutomationCompatibleInterface } from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "./libraries/Ownable.sol";
import "./FairLottery.sol";
import "./LotteryTicket.sol";

/// @title Handles drawing of Chainlink VRF numbers for the lottery system.
/// @dev Uses Chainlink's Logic-based Upkeep System to automate draws.
contract DrawConsumer is VRFConsumerBaseV2, Ownable, AutomationCompatibleInterface {

    /// @dev Numbers available at beginning of draw.
    uint256 public constant AVAILABLE_NUMBERS = 49;
    /// @dev Lowest purchaseable number.
    uint256 public constant LOWEST_DIGIT = 1;
    /// @dev Highest purchaseable number.
    uint256 public constant HIGHEST_DIGIT = 49;

    /*
     * @dev Keyhash used for Chainlink VRF.
     * Arbitrum Sepolia: 0x027f94ff1465b3525f9fc03e9ff7d6d2c0953482246dd6ae07570c45d6631414;
     */
    bytes32 keyHash;

    /// @dev Interface for VRFCoordinatorV2.
    VRFCoordinatorV2Interface COORDINATOR;
    /// @dev Callback gas limit.
    uint32 callbackGasLimit = 2500000;
    /// @dev Request confirmations.
    uint16 requestConfirmations = 10;
    /// @dev Words to request.
    uint32 numWords = 7;

    /*
     * @dev Consumer Subscription ID.
     * Arbitrum Sepolia: 275;
     */
    uint64 public subscriptionId;

    struct Draw {
        // chainlink VRF request id
        uint256 requestId;
        // winning numbers
        uint256[6] winningNumbers;
        // additional number
        uint256 additionalNumber;
    }

    /// @dev Total draws.
    uint256 public totalDraws = 0;

    /// @dev Interface for FairLottery.
    FairLottery lotterySystem;
    /// @dev Interface for LotteryTicket.
    LotteryTicket ticketManager;

    /// @dev Timing of first draw.
    uint256 public firstDrawTimestamp;
    /// @dev Timing of the next draw.
    uint256 public nextDrawTimestamp;
    /// @dev Interval between draws.
    uint256 public drawInterval;

    /// @dev Mapping of draw ID to request ID.
    mapping (uint256 => uint256) private requestIds;
    /// @dev Mapping of draw ID to random words. (for re-verifiability)
    mapping (uint256 => uint256[]) private drawIdsToRandomWords;

    /// @dev Mapping of request ID to draw ID.
    mapping (uint256 => uint256) private drawIds;
    /// @dev Mapping of requst ID to draw info.
    mapping (uint256 => Draw) private draws;

    event DrawRequested(uint256 drawId, uint256 requestId);
    event DrawFulfilled(uint256 drawId, uint256 requestId, uint256[] randomWords, uint256[6] drawNumbers, uint256 additionalNumbers);
    event AddressesChanged(address oldLotteryAddress, address oldTicketAddress, address newLotteryAddress, address newTicketAddress);
    event SubscriptionIdChanged(uint256 oldSubscriptionId, uint256 newSubscriptionId);
    event DrawIntervalChanged(uint256 oldDrawInterval, uint256 newDrawInterval);

    // Ownership will be renounced after addresses updated.
    constructor (
        bytes32 _keyHash,
        address _vrfCoordinator,
        uint64 _subscriptionId,
        uint256 _drawInterval,
        uint256 _firstDrawTimestamp
    ) 
        VRFConsumerBaseV2(_vrfCoordinator) 
    {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        keyHash = _keyHash;
        subscriptionId = _subscriptionId;

        drawInterval = _drawInterval;
        firstDrawTimestamp = _firstDrawTimestamp;
        nextDrawTimestamp = firstDrawTimestamp;

        ownerAddress = msg.sender;
    }

    /// @dev Allows owner to update references.
    function UpdateAddresses(address _fairLotteryAddress, address _ticketManagerAddress) external onlyOwner {
        emit AddressesChanged(address(lotterySystem), address(ticketManager), _fairLotteryAddress, _ticketManagerAddress);
        lotterySystem = FairLottery(_fairLotteryAddress);
        ticketManager = LotteryTicket(_ticketManagerAddress);
    }

    /// @dev Initiates the request to draw random numbers using Chainlink VRF
    /// @dev Returns used request ID.
    function requestDraw() internal returns (uint256 requestId) {   
        uint256 drawId = GetNextDrawId();

        require (block.timestamp >= nextDrawTimestamp, "Not time yet");
        nextDrawTimestamp = nextDrawTimestamp + drawInterval;

        if (ticketManager.drawIdToTicketCount(drawId) < 1) {
            // Just return after having incremented the draw timestamp.
            return 0;
        }

        uint256[] memory ids = new uint256[](1);
        ids[0] = totalDraws;
        (,,,,,, bool[] memory arePrizesDetermined) = lotterySystem.GetResults(ids);
        require(ticketManager.drawIdToTicketCount(totalDraws) < 1 || arePrizesDetermined[0], "Prev draw not finalized");

        require(requestIds[drawId] == 0, "Already drawn");

        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        drawIds[requestId] = drawId;
        requestIds[drawId] = requestId;

        lotterySystem.CloseDraw(drawId, requestId);

        totalDraws += 1;
        emit DrawRequested(drawId, requestId);
        return requestId;
    }

    /// @dev Draws the winning numbers and additional number.
    /// @dev Callback function used by VRF Coordinator
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        (uint256[6] memory winningNumbers, uint256 additionalNumber) = FindWinningNumbers(randomWords);

        // Record and emit event.
        uint256 drawId = drawIds[requestId];
        draws[drawId] = Draw(requestId, winningNumbers, additionalNumber);
        
        drawIdsToRandomWords[drawId] = randomWords;

        emit DrawFulfilled(drawId, requestId, randomWords, winningNumbers, additionalNumber);
    }

    /// @notice Returns a total of 7 unique numbers between LOWEST_DIGIT and HIGHEST_DIGIT based on (`randomWords`).
    /// 6 winning numbers and 1 additional numbers.
    function FindWinningNumbers(uint256[] memory randomWords) public pure
    returns (uint256[6] memory winningNumbers, uint256 additionalNumber) {
        // Initialize an array for the range of possible numbers
        uint256[] memory availableNumbers = new uint256[](AVAILABLE_NUMBERS);
        for (uint256 i = 0; i < AVAILABLE_NUMBERS; i += 1) {
            availableNumbers[i] = i + 1; // Populate it with 1 through AVAILABLE_NUMBERS
        }

        uint256 availableCount = AVAILABLE_NUMBERS;

        for (uint256 draw = 0; draw < 7; draw += 1) {
            uint256 selectedIndex = randomWords[draw] % availableCount;
            uint256 selectedNumber = availableNumbers[selectedIndex];

            if (draw < winningNumbers.length) {
                winningNumbers[draw] = selectedNumber;
            } else {
                additionalNumber = selectedNumber;
            }

            // Move the last number in the array to the selected index (to remove the selected number)
            availableNumbers[selectedIndex] = availableNumbers[availableCount - 1];
            availableCount -= 1; // Reduce the count of available numbers
        }

        // Ensure numbers are drawn within limits.
        for (uint256 i = 0; i < winningNumbers.length; i += 1) {
            require(winningNumbers[i] >= LOWEST_DIGIT && winningNumbers[i] <= HIGHEST_DIGIT , "Winning number not drawn");
        }
        require(additionalNumber >= LOWEST_DIGIT && additionalNumber <= HIGHEST_DIGIT, "Additional number not drawn");

        // Ensure no duplicates.
        for (uint256 i = 0; i < winningNumbers.length; i += 1) {
            for (uint256 j = i + 1; j < winningNumbers.length; j += 1) {
                require(winningNumbers[i] != winningNumbers[j], "Duplicate in winning numbers.");
            }
        }
        for (uint256 i = 0; i < winningNumbers.length; i += 1) {
            require(winningNumbers[i] != additionalNumber, "Duplicate in winning additional number.");
        }
    }

    /// @notice Returns the draw ID of the next draw.
    function GetNextDrawId() public view returns (uint256 nextDrawId) {
        nextDrawId = totalDraws + 1;
    }

    /// @notice Returns the draw result for (`_drawId`).
    function GetDraw(uint256 _drawId) external view 
    returns (uint256 id, uint256[6] memory winningNumbers, uint256 additionalNumber) {
        id = _drawId;
        winningNumbers = draws[_drawId].winningNumbers;
        additionalNumber = draws[_drawId].additionalNumber;
    }

    /// @notice Returns the draw results for (`_drawIds`).
    function GetDraws(uint256[] memory _drawIds) external view 
    returns (uint256[] memory ids, uint256[6][] memory winningNumbers, uint256[] memory additionalNumbers) {
        ids = new uint256[](_drawIds.length);
        winningNumbers = new uint256[6][](_drawIds.length);
        additionalNumbers = new uint256[](_drawIds.length);

        for (uint256 i = 0; i < _drawIds.length; i += 1) {
            uint256 drawId = _drawIds[i];

            ids[i] = drawId;
            winningNumbers[i] = draws[drawId].winningNumbers;
            additionalNumbers[i] = draws[drawId].additionalNumber;
        }
    }

    /// @notice Returns results for the latest (`count`) draws.
    function GetLatestDraws(uint256 count) external view 
    returns (uint256[] memory ids, uint256[6][] memory winningNumbers, uint256[] memory additionalNumbers) {
        require(count <= totalDraws, "Not enough draws elapsed");

        ids = new uint256[](count);
        winningNumbers = new uint256[6][](count);
        additionalNumbers = new uint256[](count);

        uint256 index = 0;
        // 0 is skipped, so offset with +1.
        for (uint256 i = totalDraws - count + 1; i <= totalDraws; i += 1) {
            ids[index] = i;
            winningNumbers[index] = draws[i].winningNumbers;
            additionalNumbers[index] = draws[i].additionalNumber;

            index += 1;
        }
    }

    /// @notice Returns the randomWords used for (`drawId`).
    function GetRandomWords(uint256 drawId) external view
    returns (uint256[] memory randomWords) {
        return drawIdsToRandomWords[drawId];
    }

    /// @dev Used by Chainlink Automation to check if performUpkeep needs to be called.
    /// @dev Checks if the draw should occur if draw timing has passed and
    /// @dev there are no tickets purchased / all tickets purchased have been processed.
    function checkUpkeep( bytes calldata /* checkData */ )
    external view returns (bool upkeepNeeded, bytes memory /* performData */) {
        uint256[] memory ids = new uint256[](1);
        ids[0] = totalDraws;

        (,,,,,, bool[] memory arePrizesDetermined) = lotterySystem.GetResults(ids);

        upkeepNeeded = 
            block.timestamp >= nextDrawTimestamp && // Next draw eligible.
            (ticketManager.drawIdToTicketCount(totalDraws) < 1 || arePrizesDetermined[0]); // Previous draw processed.
    }

    /// @dev Used by Chainlink Automation to run custom logic if checkUpkeep returns true.
    /// @dev Initate the request to draw.
    function performUpkeep(bytes calldata /* performData */) external override {
        requestDraw();       
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
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
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
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

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