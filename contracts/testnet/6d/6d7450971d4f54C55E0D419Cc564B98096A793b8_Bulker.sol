////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
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
}

contract BankMath {
    error InvalidUInt64();
    error InvalidUInt104();
    error InvalidUInt128();
    error InvalidInt104();
    error InvalidInt256();
    error NegativeNumber();

    function safe64(uint256 n) internal pure returns (uint64) {
        // if (n > type(uint64).max) revert InvalidUInt64();
        if (n > type(uint64).max) revert("InvalidUInt64");
        return uint64(n);
    }

    function safe104(uint256 n) internal pure returns (uint104) {
        // if (n > type(uint104).max) revert InvalidUInt104();
        if (n > type(uint104).max) revert("InvalidUInt104");
        return uint104(n);
    }

    function safe128(uint256 n) internal pure returns (uint128) {
        // if (n > type(uint128).max) revert InvalidUInt128();
        if (n > type(uint128).max) revert("InvalidUInt128");
        return uint128(n);
    }

    function signed104(uint104 n) internal pure returns (int104) {
        // if (n > uint104(type(int104).max)) revert InvalidInt104();
        if (n > uint104(type(int104).max)) revert("InvalidInt104");
        return int104(n);
    }

    function signed256(uint256 n) internal pure returns (int256) {
        // if (n > uint256(type(int256).max)) revert InvalidInt256();
        if (n > uint256(type(int256).max)) revert("InvalidInt256");
        return int256(n);
    }

    function unsigned104(int104 n) internal pure returns (uint104) {
        // if (n < 0) revert NegativeNumber();
        if (n < 0) revert("NegativeNumber");
        return uint104(n);
    }

    function unsigned256(int256 n) internal pure returns (uint256) {
        // if (n < 0) revert NegativeNumber();
        if (n < 0) revert("NegativeNumber");
        return uint256(n);
    }

    function toUInt8(bool x) internal pure returns (uint8) {
        return x ? 1 : 0;
    }

    function toBool(uint8 x) internal pure returns (bool) {
        return x != 0;
    }
}

contract BankStorage {
    // 512 bits total = 2 slots
    struct TotalsBasic {
        // 1st slot
        uint64 baseSupplyIndex;
        uint64 baseBorrowIndex;
        uint64 trackingSupplyIndex;
        uint64 trackingBorrowIndex;
        // 2nd slot
        uint104 totalSupplyBase;
        uint104 totalBorrowBase;
        uint40 lastAccrualTime;
        uint8 pauseFlags;
    }

    struct TotalsCollateral {
        uint128 totalSupplyAsset;
        uint128 _reserved;
        uint128 investment;
    }

    struct UserBasic {
        int104 principal;
        uint64 baseTrackingIndex;
        uint64 baseTrackingAccrued;
        uint16 assetsIn;
        uint8 _reserved;
    }

    struct UserCollateral {
        uint128 balance;
        uint128 _reserved;
    }

    struct LiquidatorPoints {
        uint32 numAbsorbs;
        uint64 numAbsorbed;
        uint128 approxSpend;
        uint32 _reserved;
    }

    /// @dev Aggregate variables tracked for the entire market
    uint64 internal baseSupplyIndex;
    uint64 internal baseBorrowIndex;
    uint64 internal trackingSupplyIndex;
    uint64 internal trackingBorrowIndex;
    uint104 internal totalSupplyBase;
    uint104 internal totalBorrowBase;
    uint40 internal lastAccrualTime;
    uint8 internal pauseFlags;

    /// @notice Aggregate variables tracked for each collateral asset
    mapping(address => TotalsCollateral) public totalsCollateral;

    /// @notice Mapping of users to accounts which may be permitted to manage the user account
    mapping(address => mapping(address => bool)) public isAllowed;

    /// @notice The next expected nonce for an address, for validating authorizations via signature
    mapping(address => uint256) public userNonce;

    /// @notice Mapping of users to base principal and other basic data
    mapping(address => UserBasic) public userBasic;

    /// @notice Mapping of users to collateral data per collateral asset
    mapping(address => mapping(address => UserCollateral))
        public userCollateral;

    /// @notice Mapping of magic liquidator points
    mapping(address => LiquidatorPoints) public liquidatorPoints;
}

contract BankConfiguration {
    struct ExtConfiguration {
        bytes32 name32;
        bytes32 symbol32;
    }

    struct Configuration {
        address governor;
        address pauseGuardian;
        address baseToken;
        address baseTokenPriceFeed;
        address extensionDelegate;
        uint64 supplyKink;
        uint64 supplyPerYearInterestRateSlopeLow;
        uint64 supplyPerYearInterestRateSlopeHigh;
        uint64 supplyPerYearInterestRateBase;
        uint64 borrowKink;
        uint64 borrowPerYearInterestRateSlopeLow;
        uint64 borrowPerYearInterestRateSlopeHigh;
        uint64 borrowPerYearInterestRateBase;
        uint64 storeFrontPriceFactor;
        uint64 trackingIndexScale;
        uint64 baseTrackingSupplySpeed;
        uint64 baseTrackingBorrowSpeed;
        uint104 baseMinForRewards;
        uint104 baseBorrowMin;
        uint104 targetReserves;
        AssetConfig[] assetConfigs;
    }

    struct AssetConfig {
        address asset;
        address priceFeed;
        uint8 decimals;
        uint64 borrowCollateralFactor;
        uint64 liquidateCollateralFactor;
        uint64 liquidationFactor;
        uint128 supplyCap;
    }
}

abstract contract BankCore is BankConfiguration, BankStorage, BankMath {
    struct AssetInfo {
        uint8 offset;
        address asset;
        address priceFeed;
        uint64 scale;
        uint64 borrowCollateralFactor;
        uint64 liquidateCollateralFactor;
        uint64 liquidationFactor;
        uint128 supplyCap;
    }

    /** Internal constants **/

    /// @dev The max number of assets this contract is hardcoded to support
    ///  Do not change this variable without updating all the fields throughout the contract,
    //    including the size of UserBasic.assetsIn and corresponding integer conversions.
    uint8 internal constant MAX_ASSETS = 15;

    /// @dev The max number of decimals base token can have
    ///  Note this cannot just be increased arbitrarily.
    uint8 internal constant MAX_BASE_DECIMALS = 18;

    /// @dev The max value for a collateral factor (1)
    uint64 internal constant MAX_COLLATERAL_FACTOR = FACTOR_SCALE;

    /// @dev Offsets for specific actions in the pause flag bit array
    uint8 internal constant PAUSE_SUPPLY_OFFSET = 0;
    uint8 internal constant PAUSE_TRANSFER_OFFSET = 1;
    uint8 internal constant PAUSE_WITHDRAW_OFFSET = 2;
    uint8 internal constant PAUSE_ABSORB_OFFSET = 3;
    uint8 internal constant PAUSE_BUY_OFFSET = 4;

    /// @dev The decimals required for a price feed
    uint8 internal constant PRICE_FEED_DECIMALS = 8;

    /// @dev 365 days * 24 hours * 60 minutes * 60 seconds
    uint64 internal constant SECONDS_PER_YEAR = 31_536_000;

    /// @dev The scale for base tracking accrual
    uint64 internal constant BASE_ACCRUAL_SCALE = 1e6;

    /// @dev The scale for base index (depends on time/rate scales, not base token)
    uint64 internal constant BASE_INDEX_SCALE = 1e15;

    /// @dev The scale for prices (in USD)
    uint64 internal constant PRICE_SCALE = uint64(10 ** PRICE_FEED_DECIMALS);

    /// @dev The scale for factors
    uint64 internal constant FACTOR_SCALE = 1e18;

    /**
     * @notice Determine if the manager has permission to act on behalf of the owner
     * @param owner The owner account
     * @param manager The manager account
     * @return Whether or not the manager has permission
     */
    function hasPermission(
        address owner,
        address manager
    ) public view returns (bool) {
        return owner == manager || isAllowed[owner][manager];
    }

    /**
     * @dev The positive present supply balance if positive or the negative borrow balance if negative
     */
    function presentValue(
        int104 principalValue_
    ) internal view returns (int256) {
        if (principalValue_ >= 0) {
            return
                signed256(
                    presentValueSupply(
                        baseSupplyIndex,
                        uint104(principalValue_)
                    )
                );
        } else {
            return
                -signed256(
                    presentValueBorrow(
                        baseBorrowIndex,
                        uint104(-principalValue_)
                    )
                );
        }
    }

    /**
     * @dev The principal amount projected forward by the supply index
     */
    function presentValueSupply(
        uint64 baseSupplyIndex_,
        uint104 principalValue_
    ) internal pure returns (uint256) {
        return (uint256(principalValue_) * baseSupplyIndex_) / BASE_INDEX_SCALE;
    }

    /**
     * @dev The principal amount projected forward by the borrow index
     */
    function presentValueBorrow(
        uint64 baseBorrowIndex_,
        uint104 principalValue_
    ) internal pure returns (uint256) {
        return (uint256(principalValue_) * baseBorrowIndex_) / BASE_INDEX_SCALE;
    }

    /**
     * @dev The positive principal if positive or the negative principal if negative
     */
    function principalValue(
        int256 presentValue_
    ) internal view returns (int104) {
        if (presentValue_ >= 0) {
            return
                signed104(
                    principalValueSupply(
                        baseSupplyIndex,
                        uint256(presentValue_)
                    )
                );
        } else {
            return
                -signed104(
                    principalValueBorrow(
                        baseBorrowIndex,
                        uint256(-presentValue_)
                    )
                );
        }
    }

    /**
     * @dev The present value projected backward by the supply index (rounded down)
     *  Note: This will overflow (revert) at 2^104/1e18=~20 trillion principal for assets with 18 decimals.
     */
    function principalValueSupply(
        uint64 baseSupplyIndex_,
        uint256 presentValue_
    ) internal pure returns (uint104) {
        return safe104((presentValue_ * BASE_INDEX_SCALE) / baseSupplyIndex_);
    }

    /**
     * @dev The present value projected backward by the borrow index (rounded up)
     *  Note: This will overflow (revert) at 2^104/1e18=~20 trillion principal for assets with 18 decimals.
     */
    function principalValueBorrow(
        uint64 baseBorrowIndex_,
        uint256 presentValue_
    ) internal pure returns (uint104) {
        return
            safe104(
                (presentValue_ * BASE_INDEX_SCALE + baseBorrowIndex_ - 1) /
                    baseBorrowIndex_
            );
    }
}

abstract contract BankExtInterface is BankCore {
    error BadAmount();
    error BadNonce();
    error BadSignatory();
    error InvalidValueS();
    error InvalidValueV();
    error SignatureExpired();

    function allow(address manager, bool isAllowed) external virtual;

    function allowBySig(
        address owner,
        address manager,
        bool isAllowed,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual;

    function collateralBalanceOf(
        address account,
        address asset
    ) external view virtual returns (uint128);

    function baseTrackingAccrued(
        address account
    ) external view virtual returns (uint64);

    function baseAccrualScale() external view virtual returns (uint64);

    function baseIndexScale() external view virtual returns (uint64);

    function factorScale() external view virtual returns (uint64);

    function priceScale() external view virtual returns (uint64);

    function maxAssets() external view virtual returns (uint8);

    function totalsBasic() external view virtual returns (TotalsBasic memory);

    function version() external view virtual returns (string memory);

    /**
     * ===== ERC20 interfaces =====
     * Does not include the following functions/events, which are defined in `BankMainInterface` instead:
     * - function decimals() virtual external view returns (uint8)
     * - function totalSupply() virtual external view returns (uint256)
     * - function transfer(address dst, uint amount) virtual external returns (bool)
     * - function transferFrom(address src, address dst, uint amount) virtual external returns (bool)
     * - function balanceOf(address owner) virtual external view returns (uint256)
     * - event Transfer(address indexed from, address indexed to, uint256 amount)
     */
    function name() external view virtual returns (string memory);

    function symbol() external view virtual returns (string memory);

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(
        address spender,
        uint256 amount
    ) external virtual returns (bool);

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return The number of tokens allowed to be spent (-1 means infinite)
     */
    function allowance(
        address owner,
        address spender
    ) external view virtual returns (uint256);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );
}

abstract contract BankMainInterface is BankCore {
    error Absurd();
    error AlreadyInitialized();
    error BadAsset();
    error BadDecimals();
    error BadDiscount();
    error BadMinimum();
    error BadPrice();
    error BorrowTooSmall();
    error BorrowCFTooLarge();
    error InsufficientReserves();
    error LiquidateCFTooLarge();
    error NoSelfTransfer();
    error NotCollateralized();
    error NotForSale();
    error NotLiquidatable();
    error Paused();
    error SupplyCapExceeded();
    error TimestampTooLarge();
    error TooManyAssets();
    error TooMuchSlippage();
    error TransferInFailed();
    error TransferOutFailed();
    error Unauthorized();
    event Supply(address indexed from, address indexed dst, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Withdraw(address indexed src, address indexed to, uint256 amount);

    event SupplyCollateral(
        address indexed from,
        address indexed dst,
        address indexed asset,
        uint256 amount
    );
    event TransferCollateral(
        address indexed from,
        address indexed to,
        address indexed asset,
        uint256 amount
    );
    event WithdrawCollateral(
        address indexed src,
        address indexed to,
        address indexed asset,
        uint256 amount
    );

    /// @notice Event emitted when a borrow position is absorbed by the protocol
    event AbsorbDebt(
        address indexed absorber,
        address indexed borrower,
        uint256 basePaidOut,
        uint256 usdValue
    );

    /// @notice Event emitted when a user's collateral is absorbed by the protocol
    event AbsorbCollateral(
        address indexed absorber,
        address indexed borrower,
        address indexed asset,
        uint256 collateralAbsorbed,
        uint256 usdValue
    );

    /// @notice Event emitted when a collateral asset is purchased from the protocol
    event BuyCollateral(
        address indexed buyer,
        address indexed asset,
        uint256 baseAmount,
        uint256 collateralAmount
    );

    /// @notice Event emitted when an action is paused/unpaused
    event PauseAction(
        bool supplyPaused,
        bool transferPaused,
        bool withdrawPaused,
        bool absorbPaused,
        bool buyPaused
    );

    /// @notice Event emitted when reserves are withdrawn by the governor
    event WithdrawReserves(address indexed to, uint256 amount);
    /// @notice Event emmited when governor withdrawn investment collateral
    event WithdrawInvestment(
        address indexed asset,
        uint256 amount,
        address governor
    );
    /// @notice Event emmited when governor payback investment
    event PaybackInvestment(
        address indexed asset,
        uint256 amount,
        address operator
    );

    function supply(address asset, uint256 amount) external virtual;

    function supplyTo(
        address dst,
        address asset,
        uint256 amount
    ) external virtual;

    function supplyFrom(
        address from,
        address dst,
        address asset,
        uint256 amount
    ) external virtual;

    function transfer(
        address dst,
        uint256 amount
    ) external virtual returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external virtual returns (bool);

    function transferAsset(
        address dst,
        address asset,
        uint256 amount
    ) external virtual;

    function transferAssetFrom(
        address src,
        address dst,
        address asset,
        uint256 amount
    ) external virtual;

    function withdraw(address asset, uint256 amount) external virtual;

    function withdrawTo(
        address to,
        address asset,
        uint256 amount
    ) external virtual;

    function withdrawFrom(
        address src,
        address to,
        address asset,
        uint256 amount
    ) external virtual;

    function approveThis(
        address manager,
        address asset,
        uint256 amount
    ) external virtual;

    function withdrawReserves(address to, uint256 amount) external virtual;

    function absorb(
        address absorber,
        address[] calldata accounts
    ) external virtual;

    function buyCollateral(
        address asset,
        uint256 minAmount,
        uint256 baseAmount,
        address recipient
    ) external virtual;

    function quoteCollateral(
        address asset,
        uint256 baseAmount
    ) public view virtual returns (uint256);

    function getAssetInfo(
        uint8 i
    ) public view virtual returns (AssetInfo memory);

    function getAssetInfoByAddress(
        address asset
    ) public view virtual returns (AssetInfo memory);

    function getCollateralReserves(
        address asset
    ) public view virtual returns (uint256);

    function getReserves() public view virtual returns (int256);

    function getPrice(address priceFeed) public view virtual returns (uint256);

    function isBorrowCollateralized(
        address account
    ) public view virtual returns (bool);

    function isLiquidatable(address account) public view virtual returns (bool);

    function totalSupply() external view virtual returns (uint256);

    function totalBorrow() external view virtual returns (uint256);

    function balanceOf(address owner) public view virtual returns (uint256);

    function borrowBalanceOf(
        address account
    ) public view virtual returns (uint256);

    function pause(
        bool supplyPaused,
        bool transferPaused,
        bool withdrawPaused,
        bool absorbPaused,
        bool buyPaused
    ) external virtual;

    function isSupplyPaused() public view virtual returns (bool);

    function isTransferPaused() public view virtual returns (bool);

    function isWithdrawPaused() public view virtual returns (bool);

    function isAbsorbPaused() public view virtual returns (bool);

    function isBuyPaused() public view virtual returns (bool);

    function accrueAccount(address account) external virtual;

    function getSupplyRate(
        uint256 utilization
    ) public view virtual returns (uint64);

    function getBorrowRate(
        uint256 utilization
    ) public view virtual returns (uint64);

    function getUtilization() public view virtual returns (uint256);

    function governor() external view virtual returns (address);

    function pauseGuardian() external view virtual returns (address);

    function baseToken() external view virtual returns (address);

    function baseTokenPriceFeed() external view virtual returns (address);

    function extensionDelegate() external view virtual returns (address);

    /// @dev uint64
    function supplyKink() external view virtual returns (uint256);

    /// @dev uint64
    function supplyPerSecondInterestRateSlopeLow()
        external
        view
        virtual
        returns (uint256);

    /// @dev uint64
    function supplyPerSecondInterestRateSlopeHigh()
        external
        view
        virtual
        returns (uint256);

    /// @dev uint64
    function supplyPerSecondInterestRateBase()
        external
        view
        virtual
        returns (uint256);

    /// @dev uint64
    function borrowKink() external view virtual returns (uint256);

    /// @dev uint64
    function borrowPerSecondInterestRateSlopeLow()
        external
        view
        virtual
        returns (uint256);

    /// @dev uint64
    function borrowPerSecondInterestRateSlopeHigh()
        external
        view
        virtual
        returns (uint256);

    /// @dev uint64
    function borrowPerSecondInterestRateBase()
        external
        view
        virtual
        returns (uint256);

    /// @dev uint64
    function storeFrontPriceFactor() external view virtual returns (uint256);

    /// @dev uint64
    function baseScale() external view virtual returns (uint256);

    /// @dev uint64
    function trackingIndexScale() external view virtual returns (uint256);

    /// @dev uint64
    function baseTrackingSupplySpeed() external view virtual returns (uint256);

    /// @dev uint64
    function baseTrackingBorrowSpeed() external view virtual returns (uint256);

    /// @dev uint104
    function baseMinForRewards() external view virtual returns (uint256);

    /// @dev uint104
    function baseBorrowMin() external view virtual returns (uint256);

    /// @dev uint104
    function targetReserves() external view virtual returns (uint256);

    function numAssets() external view virtual returns (uint8);

    function decimals() external view virtual returns (uint8);

    function initializeStorage() external virtual;
}

interface IWETH {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function balanceOf(address) external view returns (uint);

    function allowance(address, address) external view returns (uint);

    receive() external payable;

    function deposit() external payable;

    function withdraw(uint wad) external;

    function totalSupply() external view returns (uint);

    function approve(address guy, uint wad) external returns (bool);

    function transfer(address dst, uint wad) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint wad
    ) external returns (bool);
}

interface ERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 amount) external returns (bool);

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return The number of tokens allowed to be spent (-1 means infinite)
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );
}

abstract contract BankInterface is BankMainInterface, BankExtInterface {}

interface IClaimable {
    function claim(address comet, address src, bool shouldAccrue) external;

    function claimTo(
        address comet,
        address src,
        address to,
        bool shouldAccrue
    ) external;

    function harvest(address comet, address src) external;
}

contract Bulker {
    /** General configuration constants **/
    address public immutable admin;
    address payable public immutable weth;

    /** Actions **/
    uint256 public constant ACTION_SUPPLY_ASSET = 1;
    uint256 public constant ACTION_SUPPLY_ETH = 2;
    uint256 public constant ACTION_TRANSFER_ASSET = 3;
    uint256 public constant ACTION_WITHDRAW_ASSET = 4;
    uint256 public constant ACTION_WITHDRAW_ETH = 5;
    uint256 public constant ACTION_CLAIM_REWARD = 6;
    uint256 public constant ACTION_HARVEST_REWARD = 7;

    constructor(address admin_, address payable weth_) {
        admin = admin_;
        weth = weth_;
    }

    /**
     * @notice Fallback for receiving Weth. Needed for ACTION_WITHDRAW_ETH.
     */
    receive() external payable {}

    /**
     * @notice A public function to sweep accidental ERC-20 transfers to this contract. Tokens are sent to admin (Timelock)
     * @param recipient The address that will receive the swept funds
     * @param asset The address of the ERC-20 token to sweep
     */
    function sweepToken(address recipient, ERC20 asset) external {
        // if (msg.sender != admin) revert Unauthorized();
        if (msg.sender != admin) revert("Unauthorized");

        uint256 balance = asset.balanceOf(address(this));
        asset.transfer(recipient, balance);
    }

    /**
     * @notice A public function to sweep accidental Weth transfers to this contract. Tokens are sent to admin (Timelock)
     * @param recipient The address that will receive the swept funds
     */
    function sweepWeth(address recipient) external {
        // if (msg.sender != admin) revert Unauthorized();
        if (msg.sender != admin) revert("Unauthorized");

        uint256 balance = address(this).balance;
        (bool success, ) = recipient.call{value: balance}("");
        if (!success) revert("FailedToSendWeth");
    }

    /**
     * @notice Executes a list of actions in order
     * @param actions The list of actions to execute in order
     * @param data The list of calldata to use for each action
     */
    function invoke(
        uint256[] calldata actions,
        bytes[] calldata data
    ) external payable {
        // if (actions.length != data.length) revert InvalidArgument();
        if (actions.length != data.length) revert("InvalidArgument");

        uint256 unusedWeth = msg.value;
        for (uint256 i = 0; i < actions.length; ) {
            uint256 action = actions[i];
            if (action == ACTION_SUPPLY_ASSET) {
                (address comet, address to, address asset, uint256 amount) = abi
                    .decode(data[i], (address, address, address, uint256));
                supplyTo(comet, to, asset, amount);
            } else if (action == ACTION_SUPPLY_ETH) {
                (address comet, address to, uint256 amount) = abi.decode(
                    data[i],
                    (address, address, uint256)
                );
                unusedWeth -= amount;
                supplyEthTo(comet, to, amount);
            } else if (action == ACTION_TRANSFER_ASSET) {
                (address comet, address to, address asset, uint256 amount) = abi
                    .decode(data[i], (address, address, address, uint256));
                transferTo(comet, to, asset, amount);
            } else if (action == ACTION_WITHDRAW_ASSET) {
                (address comet, address to, address asset, uint256 amount) = abi
                    .decode(data[i], (address, address, address, uint256));
                withdrawTo(comet, to, asset, amount);
            } else if (action == ACTION_WITHDRAW_ETH) {
                (address comet, address to, uint256 amount) = abi.decode(
                    data[i],
                    (address, address, uint256)
                );
                withdrawEthTo(comet, to, amount);
            } else if (action == ACTION_CLAIM_REWARD) {
                (
                    address comet,
                    address rewards,
                    address src,
                    bool shouldAccrue
                ) = abi.decode(data[i], (address, address, address, bool));
                claimReward(comet, rewards, src, shouldAccrue);
            } else if (action == ACTION_HARVEST_REWARD) {
                (address comet, address rewards, address src) = abi.decode(
                    data[i],
                    (address, address, address)
                );
                harvestReward(comet, rewards, src);
            }
            unchecked {
                i++;
            }
        }

        // Refund unused Weth back to msg.sender
        if (unusedWeth > 0) {
            (bool success, ) = msg.sender.call{value: unusedWeth}("");
            if (!success) revert("FailedToSendWeth");
        }
    }

    /**
     * @notice Supplies an asset to a user in Bank
     */
    function supplyTo(
        address comet,
        address to,
        address asset,
        uint256 amount
    ) internal {
        BankInterface(comet).supplyFrom(msg.sender, to, asset, amount);
    }

    /**
     * @notice Wraps Weth and supplies WETH to a user in Bank
     */
    function supplyEthTo(address comet, address to, uint256 amount) internal {
        IWETH(weth).deposit{value: amount}();
        IWETH(weth).approve(comet, amount);
        BankInterface(comet).supplyFrom(address(this), to, weth, amount);
    }

    /**
     * @notice Transfers an asset to a user in Bank
     */
    function transferTo(
        address comet,
        address to,
        address asset,
        uint256 amount
    ) internal {
        BankInterface(comet).transferAssetFrom(msg.sender, to, asset, amount);
    }

    /**
     * @notice Withdraws an asset to a user in Bank
     */
    function withdrawTo(
        address comet,
        address to,
        address asset,
        uint256 amount
    ) internal {
        BankInterface(comet).withdrawFrom(msg.sender, to, asset, amount);
    }

    /**
     * @notice Withdraws WETH from Bank to a user after unwrapping it to VS
     */
    function withdrawEthTo(address comet, address to, uint256 amount) internal {
        BankInterface(comet).withdrawFrom(
            msg.sender,
            address(this),
            weth,
            amount
        );
        IWETH(weth).withdraw(amount);
        (bool success, ) = to.call{value: amount}("");
        if (!success) revert("FailedToSendWeth");
    }

    /**
     * @notice Claim reward for a user
     */
    function claimReward(
        address comet,
        address rewards,
        address src,
        bool shouldAccrue
    ) internal {
        IClaimable(rewards).claim(comet, src, shouldAccrue);
    }

    /**
     * @notice Claim reward for a user
     */
    function harvestReward(
        address comet,
        address rewards,
        address src
    ) internal {
        IClaimable(rewards).harvest(comet, src);
    }
}