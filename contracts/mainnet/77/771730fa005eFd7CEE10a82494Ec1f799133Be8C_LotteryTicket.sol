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