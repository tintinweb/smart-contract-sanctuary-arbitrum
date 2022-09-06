/**
 *Submitted for verification at Arbiscan on 2022-09-05
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

// File: PriceProviderInterface.sol

interface ICustomPriceProvider {
    struct RoundData {
        uint256 roundId;
        uint256 price;
        uint256 startedAt;
        uint256 updatedAt;
        uint256 answeredInRound;
    }
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

    function changeLock(
        uint256 id,
        uint256 tokenXAmount,
        uint256 premium
    ) external;
}

interface IBufferOptions {
    event Create(
        uint256 indexed id,
        address indexed account,
        uint256 settlementFee,
        uint256 totalFee,
        string metadata
    );

    event Exercise(uint256 indexed id, uint256 profit);
    event Expire(uint256 indexed id, uint256 premium);
    event PayReferralFee(address indexed referrer, uint256 amount);
    event PayAdminFee(address indexed owner, uint256 amount);
    event AutoExerciseStatusChange(address indexed account, bool status);

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

    event UpdateOptionCreationWindow(
        uint256 startHour,
        uint256 startMinute,
        uint256 endHour,
        uint256 endMinute
    );
    event TransferUnits(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId,
        uint256 targetTokenId,
        uint256 transferUnits
    );

    event Split(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 newTokenId,
        uint256 splitUnits
    );

    event Merge(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 indexed targetTokenId,
        uint256 mergeUnits
    );

    event ApprovalUnits(
        address indexed approval,
        uint256 indexed tokenId,
        uint256 allowance
    );
    struct OptionDetails {
        uint256 period;
        uint256 amount;
        uint256 strike;
        bool isYes;
        bool isAbove;
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

    struct ApproveUnits {
        address[] approvals;
        mapping(address => uint256) allowances;
    }
}

interface INFTReceiver {
    function onNFTReceived(
        address operator,
        address from,
        uint256 tokenId,
        uint256 units,
        bytes calldata data
    ) external returns (bytes4);
}

interface IOptionsConfig {
    enum PermittedTradingType {
        All,
        OnlyPut,
        OnlyCall,
        None
    }
    event UpdateImpliedVolatility(uint256 value);
    event UpdateSettlementFeePercentage(uint256 value);
    event UpdateSettlementFeeRecipient(address account);
    event UpdateStakingFeePercentage(uint256 value);
    event UpdateReferralRewardPercentage(uint256 value);
    event UpdateOptionCollaterizationRatio(uint256 value);
    event UpdateNFTSaleRoyaltyPercentage(uint256 value);
    event UpdateTradingPermission(PermittedTradingType permissionType);
    event UpdateStrike(uint256 value);
    event UpdateUnits(uint256 value);
    event UpdateOptionSizePerBlockLimitPercent(uint256 value);
}

interface IOptionWindowCreator {
    struct OptionCreationWindow {
        uint256 startHour;
        uint256 startMinute;
        uint256 endHour;
        uint256 endMinute;
    }
    event UpdateOptionCreationWindow(
        uint256 startHour,
        uint256 startMinute,
        uint256 endHour,
        uint256 endMinute
    );
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function getTimestamp(uint256 _roundId)
        external
        view
        returns (uint256 timestamp);

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

interface IPriceProvider {
    function getUsdPrice() external view returns (uint256 _price);

    function getRoundData(uint256 _roundId)
        external
        view
        returns (
            uint80 roundId,
            uint256 price,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function decimals() external view returns (uint8);
}

interface INFTCore {
    function burnOption(uint256 optionId_) external;

    function unitsInToken(uint256 optionId_) external view returns (uint256);

    function slotOf(uint256 optionId_) external view returns (uint256);

    function transferUnitsFrom(
        address from_,
        address to_,
        uint256 optionId_,
        uint256 targetOptionId_,
        uint256 transferUnits_,
        address sender
    ) external;

    function checkOnNFTReceived(
        address from_,
        address to_,
        uint256 tokenId_,
        uint256 units_,
        bytes memory _data,
        address sender
    ) external returns (bool);

    function isApprovedOrOwner(address account, uint256 optionId_)
        external
        returns (bool);
}

interface ISlidingWindowOracle {
    function consult(address tvlOracle)
        external
        view
        returns (uint256 amountOut);

    function getTimeWeightedAverageTVL(address tvlOracle, uint256 roundId)
        external
        view
        returns (uint256 roundTimestamp, uint256 KPI);
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

// File: CustomPriceProvider.sol

contract CustomPriceProvider is Ownable, ICustomPriceProvider {
    mapping(uint256 => RoundData) public roundData;
    uint256 public latestRoundId;
    uint256 public latestTimestamp;

    string public symbol;

    // Should return USD price
    function getUsdPrice() external view returns (uint256 latestPrice) {
        (, latestPrice, , , ) = latestRoundData();
    }

    // Should return timestamp of corresponding round
    function getRoundData(uint256 _roundID)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        RoundData storage _roundData = roundData[_roundID];

        return (
            _roundData.roundId,
            _roundData.price,
            _roundData.startedAt,
            _roundData.updatedAt,
            _roundData.answeredInRound
        );
    }

    function latestRoundData()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        RoundData storage _roundData = roundData[latestRoundId];

        return (
            _roundData.roundId,
            _roundData.price,
            _roundData.startedAt,
            _roundData.updatedAt,
            _roundData.answeredInRound
        );
    }

    function decimals() external view returns (uint8) {
        return 8;
    }

    function setSymbol(string memory _symbol) external onlyOwner {
        symbol = _symbol;
    }

    function update(uint256 price)
        external
        onlyOwner
        returns (uint256 roundId)
    {
        roundId = latestRoundId + 1;
        latestTimestamp = block.timestamp;

        RoundData memory _roundData = RoundData(
            roundId,
            price,
            latestTimestamp,
            latestTimestamp,
            roundId
        );
        roundData[roundId] = _roundData;
        latestRoundId = roundId;
    }
}