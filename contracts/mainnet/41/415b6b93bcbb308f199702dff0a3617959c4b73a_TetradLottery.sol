/**
 *Submitted for verification at Arbiscan.io on 2024-06-20
*/

// File: IRandomNumberGenerator.sol


pragma solidity ^0.8.20;

interface IRandomNumberGenerator {
    function generate(uint256 _id) external returns (uint256 requestId);
}
// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @chainlink/[email protected]/src/v0.8/ccip/libraries/Client.sol


pragma solidity ^0.8.0;

// End consumer library.
library Client {
  /// @dev RMN depends on this struct, if changing, please notify the RMN maintainers.
  struct EVMTokenAmount {
    address token; // token address on the local chain.
    uint256 amount; // Amount of tokens.
  }

  struct Any2EVMMessage {
    bytes32 messageId; // MessageId corresponding to ccipSend on source.
    uint64 sourceChainSelector; // Source chain selector.
    bytes sender; // abi.decode(sender) if coming from an EVM chain.
    bytes data; // payload sent in original message.
    EVMTokenAmount[] destTokenAmounts; // Tokens and their amounts in their destination chain representation.
  }

  // If extraArgs is empty bytes, the default is 200k gas limit.
  struct EVM2AnyMessage {
    bytes receiver; // abi.encode(receiver address) for dest EVM chains
    bytes data; // Data payload
    EVMTokenAmount[] tokenAmounts; // Token transfers
    address feeToken; // Address of feeToken. address(0) means you will send msg.value.
    bytes extraArgs; // Populate this with _argsToBytes(EVMExtraArgsV1)
  }

  // bytes4(keccak256("CCIP EVMExtraArgsV1"));
  bytes4 public constant EVM_EXTRA_ARGS_V1_TAG = 0x97a657c9;
  struct EVMExtraArgsV1 {
    uint256 gasLimit;
  }

  function _argsToBytes(EVMExtraArgsV1 memory extraArgs) internal pure returns (bytes memory bts) {
    return abi.encodeWithSelector(EVM_EXTRA_ARGS_V1_TAG, extraArgs);
  }
}

// File: @chainlink/[email protected]/src/v0.8/ccip/interfaces/IAny2EVMMessageReceiver.sol


pragma solidity ^0.8.0;


/// @notice Application contracts that intend to receive messages from
/// the router should implement this interface.
interface IAny2EVMMessageReceiver {
  /// @notice Called by the Router to deliver a message.
  /// If this reverts, any token transfers also revert. The message
  /// will move to a FAILED state and become available for manual execution.
  /// @param message CCIP Message
  /// @dev Note ensure you check the msg.sender is the OffRampRouter
  function ccipReceive(Client.Any2EVMMessage calldata message) external;
}

// File: @chainlink/[email protected]/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
// File: @chainlink/[email protected]/src/v0.8/ccip/applications/CCIPReceiver.sol


pragma solidity ^0.8.0;




/// @title CCIPReceiver - Base contract for CCIP applications that can receive messages.
abstract contract CCIPReceiver is IAny2EVMMessageReceiver, IERC165 {
  address internal immutable i_ccipRouter;

  constructor(address router) {
    if (router == address(0)) revert InvalidRouter(address(0));
    i_ccipRouter = router;
  }

  /// @notice IERC165 supports an interfaceId
  /// @param interfaceId The interfaceId to check
  /// @return true if the interfaceId is supported
  /// @dev Should indicate whether the contract implements IAny2EVMMessageReceiver
  /// e.g. return interfaceId == type(IAny2EVMMessageReceiver).interfaceId || interfaceId == type(IERC165).interfaceId
  /// This allows CCIP to check if ccipReceive is available before calling it.
  /// If this returns false or reverts, only tokens are transferred to the receiver.
  /// If this returns true, tokens are transferred and ccipReceive is called atomically.
  /// Additionally, if the receiver address does not have code associated with
  /// it at the time of execution (EXTCODESIZE returns 0), only tokens will be transferred.
  function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
    return interfaceId == type(IAny2EVMMessageReceiver).interfaceId || interfaceId == type(IERC165).interfaceId;
  }

  /// @inheritdoc IAny2EVMMessageReceiver
  function ccipReceive(Client.Any2EVMMessage calldata message) external virtual override onlyRouter {
    _ccipReceive(message);
  }

  /// @notice Override this function in your implementation.
  /// @param message Any2EVMMessage
  function _ccipReceive(Client.Any2EVMMessage memory message) internal virtual;

  /////////////////////////////////////////////////////////////////////
  // Plumbing
  /////////////////////////////////////////////////////////////////////

  /// @notice Return the current router
  /// @return CCIP router address
  function getRouter() public view returns (address) {
    return address(i_ccipRouter);
  }

  error InvalidRouter(address router);

  /// @dev only calls from the set router are accepted.
  modifier onlyRouter() {
    if (msg.sender != address(i_ccipRouter)) revert InvalidRouter(msg.sender);
    _;
  }
}

// File: @chainlink/[email protected]/src/v0.8/ccip/interfaces/IRouterClient.sol


pragma solidity ^0.8.0;


interface IRouterClient {
  error UnsupportedDestinationChain(uint64 destChainSelector);
  error InsufficientFeeTokenAmount();
  error InvalidMsgValue();

  /// @notice Checks if the given chain ID is supported for sending/receiving.
  /// @param chainSelector The chain to check.
  /// @return supported is true if it is supported, false if not.
  function isChainSupported(uint64 chainSelector) external view returns (bool supported);

  /// @notice Gets a list of all supported tokens which can be sent or received
  /// to/from a given chain id.
  /// @param chainSelector The chainSelector.
  /// @return tokens The addresses of all tokens that are supported.
  function getSupportedTokens(uint64 chainSelector) external view returns (address[] memory tokens);

  /// @param destinationChainSelector The destination chainSelector
  /// @param message The cross-chain CCIP message including data and/or tokens
  /// @return fee returns execution fee for the message
  /// delivery to destination chain, denominated in the feeToken specified in the message.
  /// @dev Reverts with appropriate reason upon invalid message.
  function getFee(
    uint64 destinationChainSelector,
    Client.EVM2AnyMessage memory message
  ) external view returns (uint256 fee);

  /// @notice Request a message to be sent to the destination chain
  /// @param destinationChainSelector The destination chain ID
  /// @param message The cross-chain CCIP message including data and/or tokens
  /// @return messageId The message ID
  /// @dev Note if msg.value is larger than the required fee (from getFee) we accept
  /// the overpayment with no refund.
  /// @dev Reverts with appropriate reason upon invalid message.
  function ccipSend(
    uint64 destinationChainSelector,
    Client.EVM2AnyMessage calldata message
  ) external payable returns (bytes32);
}

// File: IWETH.sol


// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.8.0. SEE SOURCE BELOW. !!
pragma solidity ^0.8.0;

interface IWETH {
    function approve(address guy, uint256 wad) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);

    function withdraw(uint256 wad) external;

    function balanceOf(address) external view returns (uint256);

    function transfer(address dst, uint256 wad) external returns (bool);

    function deposit() external payable;

    function allowance(address, address) external view returns (uint256);

    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);
}

// File: lottery.sol


pragma solidity ^0.8.20;







contract TetradLottery is CCIPReceiver, Ownable {
    struct Lottery {
        uint256[6] rewardsPerBracket;
        uint256[6] countWinnersPerBracket;
        uint256 firstTicketId;
        uint256 lastTicketId;
        uint256 amountCollected;
        uint256 totalAmountCollected;
        uint32 finalNumber;
    }

    struct Ticket {
        uint32 number;
        address owner;
    }

    struct CCIPData {
        address user;
        uint256 call;
        uint32[] tickets;
        uint256[] ticketIds;
        uint256 id;
        uint32[] brackets;
    }

    mapping(uint256 => Lottery) lotteries;
    mapping(address => uint256[]) roundsJoined;
    mapping(uint256 => Ticket) public tickets;
    mapping(uint256 => uint256) rewardsBreakdown; // 0: 1 matching number // 5: 6 matching numbers

    uint256 public price = 500000000000000;
    uint256 currentTicketId;
    uint256 lastLotteryPurchased;
    address public treasury;
    uint256 public treasuryFees = 1;

    mapping(uint256 => mapping(uint32 => uint256))
        private _numberTicketsPerLotteryId;
    mapping(address => mapping(uint256 => uint256[]))
        private _userTicketIdsPerLotteryId;
    mapping(uint32 => uint32) private bracketCalculator;

    IRandomNumberGenerator internal randomNumberGenerator;

    error NotRandomNumberGenerator();
    error InvalidTickets();
    error InsufficientPayment();
    error LotteryNotDrawn();
    error LotteryDrawn();
    error TransferFailed();
    error FutureLottery();
    error PreviousLotteryNotDrawn();
    error SourceChainNotAllowlisted(uint64 sourceChainSelector);
    error SenderNotAllowlisted(address sender);

    modifier onlyRandomNumberGenerator() {
        if (msg.sender != address(randomNumberGenerator))
            revert NotRandomNumberGenerator();
        _;
    }

    event LotteryNumberDrawn(
        uint256 indexed lotteryId,
        uint256 finalNumber,
        uint256 countWinningTickets
    );
    event TicketsPurchase(
        address indexed buyer,
        uint256 indexed lotteryId,
        uint256 numberTickets
    );
    event TicketsClaim(
        address indexed claimer,
        uint256 amount,
        uint256 indexed lotteryId,
        uint256 numberTickets
    );

    IWETH public WETH;

    constructor(
        address _randomNumberGenerator,
        address _router,
        address _WETH,
        address _treasury
    ) Ownable(msg.sender) CCIPReceiver(_router) {
        treasury = _treasury;
        randomNumberGenerator = IRandomNumberGenerator(_randomNumberGenerator);

        bracketCalculator[0] = 1;
        bracketCalculator[1] = 11;
        bracketCalculator[2] = 111;
        bracketCalculator[3] = 1111;
        bracketCalculator[4] = 11111;
        bracketCalculator[5] = 111111;

        rewardsBreakdown[0] = 1500;
        rewardsBreakdown[1] = 1750;
        rewardsBreakdown[2] = 2000;
        rewardsBreakdown[3] = 2250;
        rewardsBreakdown[4] = 1000;
        rewardsBreakdown[5] = 1500;

        WETH = IWETH(_WETH);
        lotteries[(block.timestamp / 24 hours) - 1].finalNumber = 1; //so the real first round can be called
    }

    function buyTicketsWithEther(uint32[] memory _numbers, address _user)
        external
        payable
    {
        uint256 payment = _numbers.length * price;

        WETH.deposit{value: payment}();

        buyTickets(_numbers, _user, payment);
    }

    function buyTicketsWithWETH(uint32[] memory _numbers, address _user)
        external
    {
        uint256 payment = _numbers.length * price;
        bool sent = WETH.transferFrom(_user, address(this), payment);
        if (!sent) revert("Insufficient payment");

        buyTickets(_numbers, _user, payment);
    }

    function buyTickets(
        uint32[] memory _numbers,
        address _user,
        uint256 _payment
    ) internal {
        if (_numbers.length == 0) revert InvalidTickets();
        uint256 id = block.timestamp / 24 hours;

        if (lotteries[id].amountCollected == 0) {
            lotteries[id].firstTicketId = currentTicketId;
            if (
                lotteries[id - 1].amountCollected != 0 &&
                lotteries[id - 1].lastTicketId == 0
            ) {
                lotteries[id - 1].lastTicketId = currentTicketId - 1;
            }
        }

        for (uint256 i = 0; i < _numbers.length; i++) {
            uint32 thisTicketNumber = _numbers[i];

            if (thisTicketNumber < 1000000 || thisTicketNumber > 1999999)
                revert InvalidTickets();

            _numberTicketsPerLotteryId[id][1 + (thisTicketNumber % 10)]++;
            _numberTicketsPerLotteryId[id][11 + (thisTicketNumber % 100)]++;
            _numberTicketsPerLotteryId[id][111 + (thisTicketNumber % 1000)]++;
            _numberTicketsPerLotteryId[id][1111 + (thisTicketNumber % 10000)]++;
            _numberTicketsPerLotteryId[id][
                11111 + (thisTicketNumber % 100000)
            ]++;
            _numberTicketsPerLotteryId[id][
                111111 + (thisTicketNumber % 1000000)
            ]++;

            _userTicketIdsPerLotteryId[_user][id].push(currentTicketId);

            tickets[currentTicketId] = Ticket({
                number: thisTicketNumber,
                owner: _user
            });

            currentTicketId++;
        }

        if (
            roundsJoined[_user].length == 0 ||
            roundsJoined[_user][roundsJoined[_user].length - 1] != id
        ) {
            roundsJoined[_user].push(id);
        }

        lotteries[id].amountCollected += (_payment);
        lotteries[id].totalAmountCollected += (_payment);

        emit TicketsPurchase(_user, id, _numbers.length);
    }

    function claimTickets(
        uint256 _id,
        uint256[] calldata _ticketIds,
        uint32[] calldata _brackets
    ) external {
        if (_ticketIds.length != _brackets.length) revert InvalidTickets();
        if (_ticketIds.length == 0) revert InvalidTickets();
        if (lotteries[_id].finalNumber == 0) revert LotteryNotDrawn();

        uint256 rewardToTransfer;

        for (uint256 i = 0; i < _ticketIds.length; i++) {
            require(_brackets[i] < 6, "Bracket out of range");

            uint256 thisTicketId = _ticketIds[i];

            require(
                lotteries[_id].lastTicketId >= thisTicketId,
                "TicketId too high"
            );
            require(
                lotteries[_id].firstTicketId <= thisTicketId,
                "TicketId too low"
            );
            require(msg.sender == tickets[thisTicketId].owner, "Not the owner");

            // Update the lottery ticket owner to 0x address
            tickets[thisTicketId].owner = address(0);

            uint256 rewardForTicketId = calculateRewardsForTicketId(
                _id,
                thisTicketId,
                _brackets[i]
            );

            // Check user is claiming the correct bracket
            require(rewardForTicketId != 0, "No prize for this bracket");

            if (_brackets[i] != 5) {
                require(
                    calculateRewardsForTicketId(
                        _id,
                        thisTicketId,
                        _brackets[i] + 1
                    ) == 0,
                    "Bracket must be higher"
                );
            }
            rewardToTransfer += rewardForTicketId;
        }
        bool sent = WETH.transfer(msg.sender, (rewardToTransfer * (10000 - treasuryFees)) / 10000);
        bool _sent = WETH.transfer(treasury, (rewardToTransfer * treasuryFees) / 10000);
        if (!sent || !_sent) revert TransferFailed();

        emit TicketsClaim(msg.sender, (rewardToTransfer * (10000 - treasuryFees)) / 10000, _id, _ticketIds.length);
    }

    function _ccipReceive(Client.Any2EVMMessage memory any2EvmMessage)
        internal
        override
    {
        CCIPData memory data = abi.decode(any2EvmMessage.data, (CCIPData));
        if (data.call == 0) {
            require(
                any2EvmMessage.destTokenAmounts[0].token == address(WETH),
                "Not WETH"
            );

            uint256 payment = data.tickets.length * price;
            if (payment > any2EvmMessage.destTokenAmounts[0].amount)
                revert InsufficientPayment();

            buyTickets(data.tickets, data.user, payment);
        } else {
            if (data.call == 1) {
                claimTicketsCrossChain(
                    data.id,
                    data.ticketIds,
                    data.brackets,
                    data.user,
                    any2EvmMessage.sourceChainSelector
                );
            }
        }
    }

    function claimTicketsCrossChain(
        uint256 _id,
        uint256[] memory _ticketIds,
        uint32[] memory _brackets,
        address _user,
        uint64 _sourceChain
    ) internal {
        if (_ticketIds.length != _brackets.length) revert InvalidTickets();
        if (_ticketIds.length == 0) revert InvalidTickets();
        if (lotteries[_id].finalNumber == 0) revert LotteryNotDrawn();

        uint256 rewardToTransfer;

        for (uint256 i = 0; i < _ticketIds.length; i++) {
            require(_brackets[i] < 6, "Bracket out of range");

            uint256 thisTicketId = _ticketIds[i];

            require(
                lotteries[_id].lastTicketId >= thisTicketId,
                "TicketId too high"
            );
            require(
                lotteries[_id].firstTicketId <= thisTicketId,
                "TicketId too low"
            );
            require(_user == tickets[thisTicketId].owner, "Not the owner");

            // Update the lottery ticket owner to 0x address
            tickets[thisTicketId].owner = address(0);

            uint256 rewardForTicketId = calculateRewardsForTicketId(
                _id,
                thisTicketId,
                _brackets[i]
            );

            // Check user is claiming the correct bracket
            require(rewardForTicketId != 0, "No prize for this bracket");

            if (_brackets[i] != 5) {
                require(
                    calculateRewardsForTicketId(
                        _id,
                        thisTicketId,
                        _brackets[i] + 1
                    ) == 0,
                    "Bracket must be higher"
                );
            }
            rewardToTransfer += rewardForTicketId;
        }

        bool sent = WETH.transfer(treasury, (rewardToTransfer * treasuryFees) / 10000);
        if (!sent) revert TransferFailed();
        transferFundsCrossChain((rewardToTransfer * (10000 - treasuryFees)) / 10000, _user, _sourceChain);

        emit TicketsClaim(_user, (rewardToTransfer * (10000 - treasuryFees)) / 10000, _id, _ticketIds.length);
    }

    function transferFundsCrossChain(
        uint256 _amount,
        address _address,
        uint64 _to
    ) internal {
        IRouterClient router = IRouterClient(this.getRouter());

        uint256 fees = router.getFee(
            _to,
            createEVM2AnyMessage(_amount, _address)
        );

        if (_amount <= fees) revert("Insufficent rewards");
        _amount -= fees;

        WETH.approve(address(router), _amount);

        WETH.withdraw(fees);

        router.ccipSend{value: fees}(
            _to,
            createEVM2AnyMessage(_amount, _address)
        );
    }

    function createEVM2AnyMessage(uint256 amount, address receiver)
        internal
        view
        returns (Client.EVM2AnyMessage memory)
    {
        Client.EVMTokenAmount[]
            memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({
            token: address(WETH),
            amount: amount
        });

        return
            Client.EVM2AnyMessage({
                receiver: abi.encode(receiver),
                data: "",
                tokenAmounts: tokenAmounts,
                extraArgs: Client._argsToBytes(
                    Client.EVMExtraArgsV1({gasLimit: 0})
                ),
                feeToken: address(0)
            });
    }

    function calculateRewardsForTicketId(
        uint256 _id,
        uint256 _ticketId,
        uint32 _bracket
    ) internal view returns (uint256) {
        uint32 winningTicketNumber = lotteries[_id].finalNumber;
        uint32 userNumber = tickets[_ticketId].number;

        uint32 transformedWinningNumber = bracketCalculator[_bracket] +
            (winningTicketNumber % (uint32(10)**(_bracket + 1)));

        uint32 transformedUserNumber = bracketCalculator[_bracket] +
            (userNumber % (uint32(10)**(_bracket + 1)));

        if (transformedWinningNumber == transformedUserNumber) {
            return lotteries[_id].rewardsPerBracket[_bracket];
        } else {
            return 0;
        }
    }

    function drawLottery(uint256 _id) external {
        if ((block.timestamp / 24 hours) <= _id) revert FutureLottery();
        if (lotteries[_id].finalNumber != 0) revert LotteryDrawn();
        if (lotteries[_id - 1].finalNumber == 0)
            revert PreviousLotteryNotDrawn();

        lotteries[_id].lastTicketId = currentTicketId - 1;
        randomNumberGenerator.generate(_id);
    }

    function makeLotteryClaimable(uint256 _id, uint256 _result)
        external
        onlyRandomNumberGenerator
    {
        uint32 finalNumber = uint32(1000000 + (_result % 1000000));

        uint256 numberAddressesInPreviousBracket;

        for (uint32 i = 0; i < 6; i++) {
            uint32 j = 5 - i;
            uint32 transformedWinningNumber = bracketCalculator[j] +
                (finalNumber % (uint32(10)**(j + 1)));

            lotteries[_id].countWinnersPerBracket[j] =
                _numberTicketsPerLotteryId[_id][transformedWinningNumber] -
                numberAddressesInPreviousBracket;

            // A. If number of users for this _bracket number is superior to 0
            if (
                (_numberTicketsPerLotteryId[_id][transformedWinningNumber] -
                    numberAddressesInPreviousBracket) != 0
            ) {
                // B. If rewards at this bracket are > 0, calculate, else, report the numberAddresses from previous bracket
                if (rewardsBreakdown[j] != 0) {
                    lotteries[_id].rewardsPerBracket[j] +=
                        ((rewardsBreakdown[j] *
                            lotteries[_id].amountCollected) /
                            (_numberTicketsPerLotteryId[_id][
                                transformedWinningNumber
                            ] - numberAddressesInPreviousBracket)) /
                        10000;

                    numberAddressesInPreviousBracket = _numberTicketsPerLotteryId[
                        _id
                    ][transformedWinningNumber];
                }
            } else {
                lotteries[_id + 1].totalAmountCollected +=
                    (rewardsBreakdown[j] * lotteries[_id].amountCollected) /
                    10000;
                lotteries[_id + 1].rewardsPerBracket[j] +=
                    (rewardsBreakdown[j] * lotteries[_id].amountCollected) /
                    10000 +
                    lotteries[_id].rewardsPerBracket[j];
            }
        }

        lotteries[_id].finalNumber = finalNumber;

        emit LotteryNumberDrawn(
            _id,
            finalNumber,
            numberAddressesInPreviousBracket
        );
    }

    function viewUserInfoForLotteryId(
        address _user,
        uint256 _lotteryId,
        uint256 _cursor,
        uint256 _size
    )
        external
        view
        returns (
            uint256[] memory,
            uint32[] memory,
            bool[] memory,
            uint256
        )
    {
        uint256 length = _size;
        uint256 numberTicketsBoughtAtLotteryId = _userTicketIdsPerLotteryId[_user][_lotteryId].length;

        if (length > (numberTicketsBoughtAtLotteryId - _cursor)) {
            length = numberTicketsBoughtAtLotteryId - _cursor;
        }

        uint256[] memory lotteryTicketIds = new uint256[](length);
        uint32[] memory ticketNumbers = new uint32[](length);
        bool[] memory ticketStatuses = new bool[](length);

        for (uint256 i = 0; i < length; i++) {
            lotteryTicketIds[i] = _userTicketIdsPerLotteryId[_user][_lotteryId][i + _cursor];
            ticketNumbers[i] = tickets[lotteryTicketIds[i]].number;

            // True = ticket claimed
            if (tickets[lotteryTicketIds[i]].owner == address(0)) {
                ticketStatuses[i] = true;
            } else {
                // ticket not claimed (includes the ones that cannot be claimed)
                ticketStatuses[i] = false;
            }
        }

        return (lotteryTicketIds, ticketNumbers, ticketStatuses, _cursor + length);
    }

    function viewCurrentLotteryId() external view returns (uint256) {
        return (block.timestamp / 24 hours);
    }

    function changeRandomNumberGenerator(address _newRandomNumberGenerator)
        external
        onlyOwner
    {
        randomNumberGenerator = IRandomNumberGenerator(
            _newRandomNumberGenerator
        );
    }

    function changeRewardsBreakdown(uint256 _index, uint256 _distribution)
        external
        onlyOwner
    {
        rewardsBreakdown[_index] = _distribution;
    }

    function viewLottery(uint256 _lotteryId)
        external
        view
        returns (Lottery memory)
    {
        return lotteries[_lotteryId];
    }

    function viewRoundsJoined(address _user)
        external
        view
        returns (uint256[] memory)
    {
        return (roundsJoined[_user]);
    }

    function setTreasury(address _treasury) onlyOwner() external {
        treasury = _treasury;
    }
    function setTreasuryFees(uint256 _fees) onlyOwner() external {
        treasuryFees = _fees;
    }
    function setPrice(uint256 _price) onlyOwner() external {
        price = _price;
    }
}