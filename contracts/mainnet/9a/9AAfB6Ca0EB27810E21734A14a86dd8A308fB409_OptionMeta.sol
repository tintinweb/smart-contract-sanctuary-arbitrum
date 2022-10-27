/**
 *Submitted for verification at Arbiscan on 2022-10-26
*/

// File: Context.sol

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
}

// File: InterfacesBinary.sol

interface IOptionRouter {
    struct QueuedTrade {
        uint256 queueId;
        uint256 userQueueIndex;
        address user;
        uint256 totalFee;
        uint256 period;
        bool isAbove;
        address targetContract;
        uint256 expectedStrike;
        uint256 slippage;
        bool allowPartialFill;
        uint256 queuedTime;
        uint256 cancellationTime;
        bool isQueued;
    }
    struct Trade {
        uint256 queueId;
        uint256 price;
    }

    event OpenTrade(uint256 queueId, address user);
    event CancelTrade(uint256 queueId, address user, string reason);
    event InitiateTrade(uint256 queueId, address user);
}

interface IBufferBinaryOptions {
    event Create(
        uint256 indexed id,
        address indexed account,
        uint256 settlementFee,
        uint256 totalFee
    );

    event Exercise(
        uint256 indexed id,
        uint256 profit,
        uint256 priceAtExpiration
    );
    event Expire(
        uint256 indexed id,
        uint256 premium,
        uint256 priceAtExpiration
    );

    function createFromRouter(
        address user,
        uint256 totalFee,
        uint256 period,
        bool isAbove,
        uint256 strike,
        uint256 amount
    ) external returns (uint256 optionID);

    function checkParams(
        uint256 totalFee,
        bool isAbove,
        bool allowPartialFill
    ) external returns (uint256 amount, uint256 revisedFee);

    function runInitialChecks(
        uint256 slippage,
        uint256 period,
        uint256 totalFee
    ) external view;

    function isStrikeValid(
        uint256 slippage,
        uint256 strike,
        uint256 expectedStrike
    ) external view returns (bool);

    enum State {
        Inactive,
        Active,
        Exercised,
        Expired
    }
    enum OptionType {
        Invalid,
        Put,
        Call
    }
    enum PaymentMethod {
        Usdc,
        TokenX
    }

    struct OptionExpiryData {
        uint256 optionId;
        uint256 priceAtExpiration;
    }

    struct Option {
        State state;
        uint256 strike;
        uint256 amount;
        uint256 lockedAmount;
        uint256 premium;
        uint256 expiration;
        OptionType optionType;
        uint256 totalFee;
        uint256 createdAt;
    }

    struct BinaryOptionType {
        bool isYes;
        bool isAbove;
    }

    struct SlotDetail {
        uint256 strike;
        uint256 expiration;
        OptionType optionType;
        bool isValid;
    }
}

interface IBufferOptionsRead {
    enum State {
        Inactive,
        Active,
        Exercised,
        Expired
    }
    enum OptionType {
        Invalid,
        Put,
        Call
    }

    struct Option {
        State state;
        uint256 strike;
        uint256 amount;
        uint256 lockedAmount;
        uint256 premium;
        uint256 expiration;
        OptionType optionType;
        uint256 totalFee;
        uint256 createdAt;
    }

    struct BinaryOptionType {
        bool isYes;
        bool isAbove;
    }

    function priceProvider() external view returns (address);

    function expiryToRoundID(uint256 timestamp) external view returns (uint256);

    function options(uint256 optionId)
        external
        view
        returns (
            State state,
            uint256 strike,
            uint256 amount,
            uint256 lockedAmount,
            uint256 premium,
            uint256 expiration,
            OptionType optionType,
            uint256 totalFee,
            uint256 createdAt
        );

    function ownerOf(uint256 optionId) external view returns (address owner);

    function nextTokenId() external view returns (uint256 nextToken);

    function binaryOptionType(uint256 optionId)
        external
        view
        returns (bool isYes, bool isAbove);

    function optionPriceAtExpiration(uint256 optionId)
        external
        view
        returns (uint256 priceAtExpiration);

    function config() external view returns (address);

    function userOptionIds(address user, uint256 index)
        external
        view
        returns (uint256 optionId);

    function userOptionCount(address user)
        external
        view
        returns (uint256 count);
}

interface IOptionRouterRead {
    struct QueuedTrade {
        uint256 queueId;
        uint256 userQueueIndex;
        address user;
        uint256 totalFee;
        uint256 period;
        bool isAbove;
        address targetContract;
        uint256 expectedStrike;
        uint256 slippage;
        bool allowPartialFill;
        uint256 queuedTime;
        uint256 cancellationTime;
        bool isQueued;
    }

    function queuedTrades(uint256 queueId)
        external
        view
        returns (QueuedTrade memory);

    function userQueueCount(address user) external view returns (uint256);

    function userQueuedIds(address user, uint256 index)
        external
        view
        returns (uint256);

    function userNextQueueIndexToProcess(address user)
        external
        view
        returns (uint256);

    function nextQueueIdToProcess() external view returns (uint256);

    function nextQueueId() external view returns (uint256);

    function userCancelledQueueCount(address user)
        external
        view
        returns (uint256);

    function userCancelledQueuedIds(address user, uint256 index)
        external
        view
        returns (uint256);
}

interface ILiquidityPool {
    struct LockedLiquidity {
        uint256 amount;
        uint256 premium;
        bool locked;
    }

    event Profit(uint256 indexed id, uint256 amount);
    event Loss(uint256 indexed id, uint256 amount);
    event Provide(address indexed account, uint256 amount, uint256 writeAmount);
    event Withdraw(
        address indexed account,
        uint256 amount,
        uint256 writeAmount
    );

    function unlock(uint256 id) external;

    // function unlockPremium(uint256 amount) external;
    event UpdateRevertTransfersInLockUpPeriod(
        address indexed account,
        bool value
    );
    event InitiateWithdraw(uint256 tokenXAmount, address account);
    event ProcessWithdrawRequest(uint256 tokenXAmount, address account);
    event UpdatePoolState(bool hasPoolEnded);
    event PoolRollOver(uint256 round);
    event UpdateMaxLiquidity(uint256 indexed maxLiquidity);
    event UpdateExpiry(uint256 expiry);
    event UpdateProjectOwner(address account);

    function totalTokenXBalance() external view returns (uint256 amount);

    function availableBalance() external view returns (uint256 balance);

    function unlockWithoutProfit(uint256 id) external;

    function send(
        uint256 id,
        address account,
        uint256 amount
    ) external;

    function lock(
        uint256 id,
        uint256 tokenXAmount,
        uint256 premium
    ) external;
}

interface IOptionsConfig {
    enum PermittedTradingType {
        All,
        OnlyPut,
        OnlyCall,
        None
    }
    // event UpdateImpliedVolatility(uint256 value);
    event UpdateSettlementFeePercentageForUp(uint256 value);
    event UpdateSettlementFeePercentageForDown(uint256 value);
    event UpdateSettlementFeeRecipient(address account);
    event UpdateStakingFeePercentage(
        uint256 treasuryPercentage,
        uint256 blpStakingPercentage,
        uint256 bfrStakingPercentage,
        uint256 insuranceFundPercentage
    );

    event UpdateOptionCollaterizationRatio(uint256 value);
    event UpdateTradingPermission(PermittedTradingType permissionType);
    event UpdateStrike(uint256 value);
    event UpdateUnits(uint256 value);
    event UpdateMaxPeriod(uint256 value);
    event UpdateOptionSizePerTxnLimitPercent(uint256 value);
    event UpdateSettlementFeeDisbursalContract(address value);
    event UpdatePoolUtilizationLimitPercent(uint256 value);

    enum OptionType {
        Invalid,
        Put,
        Call
    }
}

interface ISettlementFeeDisbursal {
    function distributeSettlementFee(uint256 settlementFee)
        external
        returns (uint256 stakingAmount);
}

// File: Ownable.sol

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: OptionMeta.sol

contract OptionMeta is Ownable {
    struct UserOptionInput {
        uint256 lastStoredOptionIndex;
        address contractAddress;
        address userAddress;
        bool isNull;
    }
    struct GenricOptionInput {
        uint256 optionId;
        address contractAddress;
    }
    struct OptionExecutionInput {
        uint256 lastExecutedOptionId;
        address contractAddress;
        bool isNull;
    }

    struct OptionMetaData {
        uint256 optionId;
        IBufferOptionsRead.State state;
        uint256 strike;
        uint256 amount;
        uint256 lockedAmount;
        uint256 premium;
        uint256 expiration;
        IBufferOptionsRead.OptionType optionType;
        bool isYes;
        bool isAbove;
        uint256 totalFee;
        uint256 createdAt;
        uint256 priceAtExpiration;
    }

    function max(uint256 a, uint256 b) public pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) public pure returns (uint256) {
        return a <= b ? a : b;
    }

    function getOptionData(GenricOptionInput memory option)
        public
        view
        returns (OptionMetaData memory optionDetails)
    {
        uint256 optionId = option.optionId;
        IBufferOptionsRead binaryOptionsContract = IBufferOptionsRead(
            option.contractAddress
        );
        (
            IBufferOptionsRead.State state,
            uint256 strike,
            uint256 amount,
            uint256 lockedAmount,
            uint256 premium,
            uint256 expiration,
            IBufferOptionsRead.OptionType optionType,
            uint256 totalFee,
            uint256 createdAt
        ) = binaryOptionsContract.options(optionId);
        (bool isYes, bool isAbove) = binaryOptionsContract.binaryOptionType(
            optionId
        );
        uint256 priceAtExpiration = binaryOptionsContract
            .optionPriceAtExpiration(optionId);
        optionDetails = OptionMetaData(
            optionId,
            state,
            strike,
            amount,
            lockedAmount,
            premium,
            expiration,
            optionType,
            isYes,
            isAbove,
            totalFee,
            createdAt,
            priceAtExpiration
        );
    }

    function getTotalQueueCount(address routerAddress)
        public
        view
        returns (uint256)
    {
        IOptionRouterRead router = IOptionRouterRead(routerAddress);
        uint256 nextQueueIdToProcess = router.nextQueueIdToProcess();
        uint256 nextQueueId = router.nextQueueId();
        return nextQueueId - nextQueueIdToProcess;
    }

    function getUserQueueCount(address user, address routerAddress)
        public
        view
        returns (uint256)
    {
        IOptionRouterRead router = IOptionRouterRead(routerAddress);
        return
            router.userQueueCount(user) -
            router.userNextQueueIndexToProcess(user);
    }

    // Return the queued trades with pagination in earliest first order
    function getQueuedOptions(
        address routerAddress,
        uint256 limit,
        uint256 page
    )
        external
        view
        returns (IOptionRouterRead.QueuedTrade[] memory allOptions)
    {
        IOptionRouterRead router = IOptionRouterRead(routerAddress);
        uint256 nextQueueIdToProcess = router.nextQueueIdToProcess();
        uint256 nextQueueId = router.nextQueueId();

        allOptions = new IOptionRouterRead.QueuedTrade[](
            min(limit, nextQueueId - nextQueueIdToProcess - (page * limit))
        );
        uint256 counter = 0;
        for (
            uint256 queueId = nextQueueIdToProcess + (page * limit);
            queueId <
            min(nextQueueId, nextQueueIdToProcess + ((page + 1) * limit));
            queueId++
        ) {
            IOptionRouterRead.QueuedTrade memory queuedTrade = router
                .queuedTrades(queueId);
            allOptions[counter] = queuedTrade;
            counter++;
        }
    }

    // Return the queued trades for an user in the latest first order
    function getQueuedOptionsForUser(
        address user,
        address routerAddress,
        uint256 limit,
        uint256 page
    )
        external
        view
        returns (IOptionRouterRead.QueuedTrade[] memory allOptions)
    {
        IOptionRouterRead router = IOptionRouterRead(routerAddress);
        uint256 userNextQueueIndexToProcess = router
            .userNextQueueIndexToProcess(user);
        allOptions = new IOptionRouterRead.QueuedTrade[](
            min(
                router.userQueueCount(user) -
                    userNextQueueIndexToProcess -
                    (page * limit),
                limit
            )
        );
        uint256 counter;
        for (
            uint256 index = userNextQueueIndexToProcess + (page * limit);
            index <
            min(
                router.userQueueCount(user),
                userNextQueueIndexToProcess + ((page + 1) * limit)
            );
            index++
        ) {
            uint256 queueId = router.userQueuedIds(user, index);
            IOptionRouterRead.QueuedTrade memory queuedTrade = router
                .queuedTrades(queueId);
            allOptions[counter] = queuedTrade;
            counter++;
        }
    }

    // Return the queued trades for an user in the latest first order
    function getCancelledOptionsForUser(
        address user,
        address routerAddress,
        uint256 limit,
        uint256 page
    )
        external
        view
        returns (IOptionRouterRead.QueuedTrade[] memory allOptions)
    {
        IOptionRouterRead router = IOptionRouterRead(routerAddress);
        allOptions = new IOptionRouterRead.QueuedTrade[](
            min(limit, router.userCancelledQueueCount(user) - (page * limit))
        );
        uint256 counter;
        for (
            uint256 index = page * limit;
            index <
            min(router.userCancelledQueueCount(user), ((page + 1) * limit));
            index++
        ) {
            uint256 queueId = router.userCancelledQueuedIds(user, index);
            IOptionRouterRead.QueuedTrade memory queuedTrade = router
                .queuedTrades(queueId);
            allOptions[counter] = queuedTrade;
            counter++;
        }
    }

    // Return the queued trades for an user in the latest first order
    function getLatestOptionsForUser(UserOptionInput calldata userOptionInput)
        external
        view
        returns (OptionMetaData[] memory allOptions)
    {
        uint256 lastStoredOptionIndex = userOptionInput.lastStoredOptionIndex;
        address optionsContractAddress = userOptionInput.contractAddress;
        IBufferOptionsRead binaryOptionsContract = IBufferOptionsRead(
            optionsContractAddress
        );
        uint256 onChainUserOptions = binaryOptionsContract.userOptionCount(
            userOptionInput.userAddress
        );
        uint256 firstOptionIndexToProcess = (
            userOptionInput.isNull ? 0 : lastStoredOptionIndex + 1
        );

        if (firstOptionIndexToProcess < onChainUserOptions) {
            uint256 counter = 0;
            allOptions = new OptionMetaData[](
                onChainUserOptions - firstOptionIndexToProcess
            );

            for (
                uint256 index = firstOptionIndexToProcess;
                index < onChainUserOptions;
                index++
            ) {
                allOptions[counter] = getOptionData(
                    GenricOptionInput(
                        binaryOptionsContract.userOptionIds(
                            userOptionInput.userAddress,
                            index
                        ),
                        optionsContractAddress
                    )
                );
                counter++;
            }
        }
    }

    function getOptionsForUser(
        address userAddress,
        address targetContract,
        uint256 limit,
        uint256 page
    ) external view returns (OptionMetaData[] memory allOptions) {
        IBufferOptionsRead binaryOptionsContract = IBufferOptionsRead(
            targetContract
        );
        uint256 onChainUserOptions = binaryOptionsContract.userOptionCount(
            userAddress
        );
        allOptions = new OptionMetaData[](
            min(limit, onChainUserOptions - (page * limit))
        );
        uint256 counter = 0;

        for (
            uint256 index = page * limit;
            index < onChainUserOptions;
            index++
        ) {
            allOptions[counter] = getOptionData(
                GenricOptionInput(
                    binaryOptionsContract.userOptionIds(userAddress, index),
                    targetContract
                )
            );
            counter++;
        }
    }

    function getOptionsToExecute(
        address contractAddress,
        uint256 limit,
        uint256 page
    ) public view returns (uint256[] memory executableOptionIds) {
        IBufferOptionsRead binaryOptionsContract = IBufferOptionsRead(
            contractAddress
        );
        uint256 counter;
        executableOptionIds = new uint256[](
            min(limit, binaryOptionsContract.nextTokenId() - (page * limit))
        );

        for (
            uint256 index = (page * limit);
            index <
            min(binaryOptionsContract.nextTokenId(), ((page + 1) * limit));
            index++
        ) {
            OptionMetaData memory optionData = getOptionData(
                GenricOptionInput(index, contractAddress)
            );
            if (
                optionData.expiration < block.timestamp &&
                optionData.state == IBufferOptionsRead.State.Active
            ) {
                executableOptionIds[counter] = index;
                counter++;
            }
        }
    }
}