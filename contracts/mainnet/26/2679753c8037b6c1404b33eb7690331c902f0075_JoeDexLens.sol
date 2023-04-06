// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

/// @title Joe V1 Factory Interface
/// @notice Interface to interact with Joe V1 Factory
interface IJoeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setMigrator(address) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

/// @title Joe V1 Pair Interface
/// @notice Interface to interact with Joe V1 Pairs
interface IJoePair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

import {ILBPair} from "./ILBPair.sol";
import {IPendingOwnable} from "./IPendingOwnable.sol";

/**
 * @title Liquidity Book Factory Interface
 * @author Trader Joe
 * @notice Required interface of LBFactory contract
 */
interface ILBFactory is IPendingOwnable {
    error LBFactory__IdenticalAddresses(IERC20 token);
    error LBFactory__QuoteAssetNotWhitelisted(IERC20 quoteAsset);
    error LBFactory__QuoteAssetAlreadyWhitelisted(IERC20 quoteAsset);
    error LBFactory__AddressZero();
    error LBFactory__LBPairAlreadyExists(IERC20 tokenX, IERC20 tokenY, uint256 _binStep);
    error LBFactory__LBPairDoesNotExist(IERC20 tokenX, IERC20 tokenY, uint256 binStep);
    error LBFactory__LBPairNotCreated(IERC20 tokenX, IERC20 tokenY, uint256 binStep);
    error LBFactory__FlashLoanFeeAboveMax(uint256 fees, uint256 maxFees);
    error LBFactory__BinStepTooLow(uint256 binStep);
    error LBFactory__FunctionIsLockedForUsers(address user, uint256 binStep);
    error LBFactory__LBPairIgnoredIsAlreadyInTheSameState();
    error LBFactory__BinStepHasNoPreset(uint256 binStep);
    error LBFactory__PresetOpenStateIsAlreadyInTheSameState();
    error LBFactory__SameFeeRecipient(address feeRecipient);
    error LBFactory__SameFlashLoanFee(uint256 flashLoanFee);
    error LBFactory__LBPairSafetyCheckFailed(address LBPairImplementation);
    error LBFactory__SameImplementation(address LBPairImplementation);
    error LBFactory__ImplementationNotSet();

    /**
     * @dev Structure to store the LBPair information, such as:
     * binStep: The bin step of the LBPair
     * LBPair: The address of the LBPair
     * createdByOwner: Whether the pair was created by the owner of the factory
     * ignoredForRouting: Whether the pair is ignored for routing or not. An ignored pair will not be explored during routes finding
     */
    struct LBPairInformation {
        uint16 binStep;
        ILBPair LBPair;
        bool createdByOwner;
        bool ignoredForRouting;
    }

    event LBPairCreated(
        IERC20 indexed tokenX, IERC20 indexed tokenY, uint256 indexed binStep, ILBPair LBPair, uint256 pid
    );

    event FeeRecipientSet(address oldRecipient, address newRecipient);

    event FlashLoanFeeSet(uint256 oldFlashLoanFee, uint256 newFlashLoanFee);

    event LBPairImplementationSet(address oldLBPairImplementation, address LBPairImplementation);

    event LBPairIgnoredStateChanged(ILBPair indexed LBPair, bool ignored);

    event PresetSet(
        uint256 indexed binStep,
        uint256 baseFactor,
        uint256 filterPeriod,
        uint256 decayPeriod,
        uint256 reductionFactor,
        uint256 variableFeeControl,
        uint256 protocolShare,
        uint256 maxVolatilityAccumulator
    );

    event PresetOpenStateChanged(uint256 indexed binStep, bool indexed isOpen);

    event PresetRemoved(uint256 indexed binStep);

    event QuoteAssetAdded(IERC20 indexed quoteAsset);

    event QuoteAssetRemoved(IERC20 indexed quoteAsset);

    function getMinBinStep() external pure returns (uint256);

    function getFeeRecipient() external view returns (address);

    function getMaxFlashLoanFee() external pure returns (uint256);

    function getFlashLoanFee() external view returns (uint256);

    function getLBPairImplementation() external view returns (address);

    function getNumberOfLBPairs() external view returns (uint256);

    function getLBPairAtIndex(uint256 id) external returns (ILBPair);

    function getNumberOfQuoteAssets() external view returns (uint256);

    function getQuoteAssetAtIndex(uint256 index) external view returns (IERC20);

    function isQuoteAsset(IERC20 token) external view returns (bool);

    function getLBPairInformation(IERC20 tokenX, IERC20 tokenY, uint256 binStep)
        external
        view
        returns (LBPairInformation memory);

    function getPreset(uint256 binStep)
        external
        view
        returns (
            uint256 baseFactor,
            uint256 filterPeriod,
            uint256 decayPeriod,
            uint256 reductionFactor,
            uint256 variableFeeControl,
            uint256 protocolShare,
            uint256 maxAccumulator,
            bool isOpen
        );

    function getAllBinSteps() external view returns (uint256[] memory presetsBinStep);

    function getAllLBPairs(IERC20 tokenX, IERC20 tokenY)
        external
        view
        returns (LBPairInformation[] memory LBPairsBinStep);

    function setLBPairImplementation(address lbPairImplementation) external;

    function createLBPair(IERC20 tokenX, IERC20 tokenY, uint24 activeId, uint16 binStep)
        external
        returns (ILBPair pair);

    function setLBPairIgnored(IERC20 tokenX, IERC20 tokenY, uint16 binStep, bool ignored) external;

    function setPreset(
        uint16 binStep,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator,
        bool isOpen
    ) external;

    function setPresetOpenState(uint16 binStep, bool isOpen) external;

    function removePreset(uint16 binStep) external;

    function setFeesParametersOnPair(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator
    ) external;

    function setFeeRecipient(address feeRecipient) external;

    function setFlashLoanFee(uint256 flashLoanFee) external;

    function addQuoteAsset(IERC20 quoteAsset) external;

    function removeQuoteAsset(IERC20 quoteAsset) external;

    function forceDecay(ILBPair lbPair) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

/// @title Liquidity Book Flashloan Callback Interface
/// @author Trader Joe
/// @notice Required interface to interact with LB flash loans
interface ILBFlashLoanCallback {
    function LBFlashLoanCallback(
        address sender,
        IERC20 tokenX,
        IERC20 tokenY,
        bytes32 amounts,
        bytes32 totalFees,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

import {ILBLegacyPair} from "./ILBLegacyPair.sol";
import {IPendingOwnable} from "./IPendingOwnable.sol";

/// @title Liquidity Book Factory Interface
/// @author Trader Joe
/// @notice Required interface of LBFactory contract
interface ILBLegacyFactory is IPendingOwnable {
    /// @dev Structure to store the LBPair information, such as:
    /// - binStep: The bin step of the LBPair
    /// - LBPair: The address of the LBPair
    /// - createdByOwner: Whether the pair was created by the owner of the factory
    /// - ignoredForRouting: Whether the pair is ignored for routing or not. An ignored pair will not be explored during routes finding
    struct LBPairInformation {
        uint16 binStep;
        ILBLegacyPair LBPair;
        bool createdByOwner;
        bool ignoredForRouting;
    }

    event LBPairCreated(
        IERC20 indexed tokenX, IERC20 indexed tokenY, uint256 indexed binStep, ILBLegacyPair LBPair, uint256 pid
    );

    event FeeRecipientSet(address oldRecipient, address newRecipient);

    event FlashLoanFeeSet(uint256 oldFlashLoanFee, uint256 newFlashLoanFee);

    event FeeParametersSet(
        address indexed sender,
        ILBLegacyPair indexed LBPair,
        uint256 binStep,
        uint256 baseFactor,
        uint256 filterPeriod,
        uint256 decayPeriod,
        uint256 reductionFactor,
        uint256 variableFeeControl,
        uint256 protocolShare,
        uint256 maxVolatilityAccumulator
    );

    event FactoryLockedStatusUpdated(bool unlocked);

    event LBPairImplementationSet(address oldLBPairImplementation, address LBPairImplementation);

    event LBPairIgnoredStateChanged(ILBLegacyPair indexed LBPair, bool ignored);

    event PresetSet(
        uint256 indexed binStep,
        uint256 baseFactor,
        uint256 filterPeriod,
        uint256 decayPeriod,
        uint256 reductionFactor,
        uint256 variableFeeControl,
        uint256 protocolShare,
        uint256 maxVolatilityAccumulator,
        uint256 sampleLifetime
    );

    event PresetRemoved(uint256 indexed binStep);

    event QuoteAssetAdded(IERC20 indexed quoteAsset);

    event QuoteAssetRemoved(IERC20 indexed quoteAsset);

    function MAX_FEE() external pure returns (uint256);

    function MIN_BIN_STEP() external pure returns (uint256);

    function MAX_BIN_STEP() external pure returns (uint256);

    function MAX_PROTOCOL_SHARE() external pure returns (uint256);

    function LBPairImplementation() external view returns (address);

    function getNumberOfQuoteAssets() external view returns (uint256);

    function getQuoteAsset(uint256 index) external view returns (IERC20);

    function isQuoteAsset(IERC20 token) external view returns (bool);

    function feeRecipient() external view returns (address);

    function flashLoanFee() external view returns (uint256);

    function creationUnlocked() external view returns (bool);

    function allLBPairs(uint256 id) external returns (ILBLegacyPair);

    function getNumberOfLBPairs() external view returns (uint256);

    function getLBPairInformation(IERC20 tokenX, IERC20 tokenY, uint256 binStep)
        external
        view
        returns (LBPairInformation memory);

    function getPreset(uint16 binStep)
        external
        view
        returns (
            uint256 baseFactor,
            uint256 filterPeriod,
            uint256 decayPeriod,
            uint256 reductionFactor,
            uint256 variableFeeControl,
            uint256 protocolShare,
            uint256 maxAccumulator,
            uint256 sampleLifetime
        );

    function getAllBinSteps() external view returns (uint256[] memory presetsBinStep);

    function getAllLBPairs(IERC20 tokenX, IERC20 tokenY)
        external
        view
        returns (LBPairInformation[] memory LBPairsBinStep);

    function setLBPairImplementation(address LBPairImplementation) external;

    function createLBPair(IERC20 tokenX, IERC20 tokenY, uint24 activeId, uint16 binStep)
        external
        returns (ILBLegacyPair pair);

    function setLBPairIgnored(IERC20 tokenX, IERC20 tokenY, uint256 binStep, bool ignored) external;

    function setPreset(
        uint16 binStep,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator,
        uint16 sampleLifetime
    ) external;

    function removePreset(uint16 binStep) external;

    function setFeesParametersOnPair(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator
    ) external;

    function setFeeRecipient(address feeRecipient) external;

    function setFlashLoanFee(uint256 flashLoanFee) external;

    function setFactoryLockedState(bool locked) external;

    function addQuoteAsset(IERC20 quoteAsset) external;

    function removeQuoteAsset(IERC20 quoteAsset) external;

    function forceDecay(ILBLegacyPair LBPair) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

import {ILBLegacyToken} from "./ILBLegacyToken.sol";

/// @title Liquidity Book Pair V2 Interface
/// @author Trader Joe
/// @notice Required interface of LBPair contract
interface ILBLegacyPair is ILBLegacyToken {
    /// @dev Structure to store the protocol fees:
    /// - binStep: The bin step
    /// - baseFactor: The base factor
    /// - filterPeriod: The filter period, where the fees stays constant
    /// - decayPeriod: The decay period, where the fees are halved
    /// - reductionFactor: The reduction factor, used to calculate the reduction of the accumulator
    /// - variableFeeControl: The variable fee control, used to control the variable fee, can be 0 to disable them
    /// - protocolShare: The share of fees sent to protocol
    /// - maxVolatilityAccumulated: The max value of volatility accumulated
    /// - volatilityAccumulated: The value of volatility accumulated
    /// - volatilityReference: The value of volatility reference
    /// - indexRef: The index reference
    /// - time: The last time the accumulator was called
    struct FeeParameters {
        // 144 lowest bits in slot
        uint16 binStep;
        uint16 baseFactor;
        uint16 filterPeriod;
        uint16 decayPeriod;
        uint16 reductionFactor;
        uint24 variableFeeControl;
        uint16 protocolShare;
        uint24 maxVolatilityAccumulated;
        // 112 highest bits in slot
        uint24 volatilityAccumulated;
        uint24 volatilityReference;
        uint24 indexRef;
        uint40 time;
    }

    /// @dev Structure used during swaps to distributes the fees:
    /// - total: The total amount of fees
    /// - protocol: The amount of fees reserved for protocol
    struct FeesDistribution {
        uint128 total;
        uint128 protocol;
    }

    /// @dev Structure to store the reserves of bins:
    /// - reserveX: The current reserve of tokenX of the bin
    /// - reserveY: The current reserve of tokenY of the bin
    struct Bin {
        uint112 reserveX;
        uint112 reserveY;
        uint256 accTokenXPerShare;
        uint256 accTokenYPerShare;
    }

    /// @dev Structure to store the information of the pair such as:
    /// slot0:
    /// - activeId: The current id used for swaps, this is also linked with the price
    /// - reserveX: The sum of amounts of tokenX across all bins
    /// slot1:
    /// - reserveY: The sum of amounts of tokenY across all bins
    /// - oracleSampleLifetime: The lifetime of an oracle sample
    /// - oracleSize: The current size of the oracle, can be increase by users
    /// - oracleActiveSize: The current active size of the oracle, composed only from non empty data sample
    /// - oracleLastTimestamp: The current last timestamp at which a sample was added to the circular buffer
    /// - oracleId: The current id of the oracle
    /// slot2:
    /// - feesX: The current amount of fees to distribute in tokenX (total, protocol)
    /// slot3:
    /// - feesY: The current amount of fees to distribute in tokenY (total, protocol)
    struct PairInformation {
        uint24 activeId;
        uint136 reserveX;
        uint136 reserveY;
        uint16 oracleSampleLifetime;
        uint16 oracleSize;
        uint16 oracleActiveSize;
        uint40 oracleLastTimestamp;
        uint16 oracleId;
        FeesDistribution feesX;
        FeesDistribution feesY;
    }

    /// @dev Structure to store the debts of users
    /// - debtX: The tokenX's debt
    /// - debtY: The tokenY's debt
    struct Debts {
        uint256 debtX;
        uint256 debtY;
    }

    /// @dev Structure to store fees:
    /// - tokenX: The amount of fees of token X
    /// - tokenY: The amount of fees of token Y
    struct Fees {
        uint128 tokenX;
        uint128 tokenY;
    }

    /// @dev Structure to minting informations:
    /// - amountXIn: The amount of token X sent
    /// - amountYIn: The amount of token Y sent
    /// - amountXAddedToPair: The amount of token X that have been actually added to the pair
    /// - amountYAddedToPair: The amount of token Y that have been actually added to the pair
    /// - activeFeeX: Fees X currently generated
    /// - activeFeeY: Fees Y currently generated
    /// - totalDistributionX: Total distribution of token X. Should be 1e18 (100%) or 0 (0%)
    /// - totalDistributionY: Total distribution of token Y. Should be 1e18 (100%) or 0 (0%)
    /// - id: Id of the current working bin when looping on the distribution array
    /// - amountX: The amount of token X deposited in the current bin
    /// - amountY: The amount of token Y deposited in the current bin
    /// - distributionX: Distribution of token X for the current working bin
    /// - distributionY: Distribution of token Y for the current working bin
    struct MintInfo {
        uint256 amountXIn;
        uint256 amountYIn;
        uint256 amountXAddedToPair;
        uint256 amountYAddedToPair;
        uint256 activeFeeX;
        uint256 activeFeeY;
        uint256 totalDistributionX;
        uint256 totalDistributionY;
        uint256 id;
        uint256 amountX;
        uint256 amountY;
        uint256 distributionX;
        uint256 distributionY;
    }

    event Swap(
        address indexed sender,
        address indexed recipient,
        uint256 indexed id,
        bool swapForY,
        uint256 amountIn,
        uint256 amountOut,
        uint256 volatilityAccumulated,
        uint256 fees
    );

    event FlashLoan(address indexed sender, address indexed receiver, IERC20 token, uint256 amount, uint256 fee);

    event CompositionFee(
        address indexed sender, address indexed recipient, uint256 indexed id, uint256 feesX, uint256 feesY
    );

    event DepositedToBin(
        address indexed sender, address indexed recipient, uint256 indexed id, uint256 amountX, uint256 amountY
    );

    event WithdrawnFromBin(
        address indexed sender, address indexed recipient, uint256 indexed id, uint256 amountX, uint256 amountY
    );

    event FeesCollected(address indexed sender, address indexed recipient, uint256 amountX, uint256 amountY);

    event ProtocolFeesCollected(address indexed sender, address indexed recipient, uint256 amountX, uint256 amountY);

    event OracleSizeIncreased(uint256 previousSize, uint256 newSize);

    function tokenX() external view returns (IERC20);

    function tokenY() external view returns (IERC20);

    function factory() external view returns (address);

    function getReservesAndId() external view returns (uint256 reserveX, uint256 reserveY, uint256 activeId);

    function getGlobalFees()
        external
        view
        returns (uint128 feesXTotal, uint128 feesYTotal, uint128 feesXProtocol, uint128 feesYProtocol);

    function getOracleParameters()
        external
        view
        returns (
            uint256 oracleSampleLifetime,
            uint256 oracleSize,
            uint256 oracleActiveSize,
            uint256 oracleLastTimestamp,
            uint256 oracleId,
            uint256 min,
            uint256 max
        );

    function getOracleSampleFrom(uint256 timeDelta)
        external
        view
        returns (uint256 cumulativeId, uint256 cumulativeAccumulator, uint256 cumulativeBinCrossed);

    function feeParameters() external view returns (FeeParameters memory);

    function findFirstNonEmptyBinId(uint24 id_, bool sentTokenY) external view returns (uint24 id);

    function getBin(uint24 id) external view returns (uint256 reserveX, uint256 reserveY);

    function pendingFees(address account, uint256[] memory ids)
        external
        view
        returns (uint256 amountX, uint256 amountY);

    function swap(bool sentTokenY, address to) external returns (uint256 amountXOut, uint256 amountYOut);

    function flashLoan(address receiver, IERC20 token, uint256 amount, bytes calldata data) external;

    function mint(
        uint256[] calldata ids,
        uint256[] calldata distributionX,
        uint256[] calldata distributionY,
        address to
    ) external returns (uint256 amountXAddedToPair, uint256 amountYAddedToPair, uint256[] memory liquidityMinted);

    function burn(uint256[] calldata ids, uint256[] calldata amounts, address to)
        external
        returns (uint256 amountX, uint256 amountY);

    function increaseOracleLength(uint16 newSize) external;

    function collectFees(address account, uint256[] calldata ids) external returns (uint256 amountX, uint256 amountY);

    function collectProtocolFees() external returns (uint128 amountX, uint128 amountY);

    function setFeesParameters(bytes32 packedFeeParameters) external;

    function forceDecay() external;

    function initialize(
        IERC20 tokenX,
        IERC20 tokenY,
        uint24 activeId,
        uint16 sampleLifetime,
        bytes32 packedFeeParameters
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "openzeppelin/utils/introspection/IERC165.sol";

/// @title Liquidity Book V2 Token Interface
/// @author Trader Joe
/// @notice Required interface of LBToken contract
interface ILBLegacyToken is IERC165 {
    event TransferSingle(address indexed sender, address indexed from, address indexed to, uint256 id, uint256 amount);

    event TransferBatch(
        address indexed sender, address indexed from, address indexed to, uint256[] ids, uint256[] amounts
    );

    event ApprovalForAll(address indexed account, address indexed sender, bool approved);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory batchBalances);

    function totalSupply(uint256 id) external view returns (uint256);

    function isApprovedForAll(address owner, address spender) external view returns (bool);

    function setApprovalForAll(address sender, bool approved) external;

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount) external;

    function safeBatchTransferFrom(address from, address to, uint256[] calldata id, uint256[] calldata amount)
        external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

import {ILBFactory} from "./ILBFactory.sol";
import {ILBFlashLoanCallback} from "./ILBFlashLoanCallback.sol";
import {ILBToken} from "./ILBToken.sol";

interface ILBPair is ILBToken {
    error LBPair__ZeroBorrowAmount();
    error LBPair__AddressZero();
    error LBPair__AlreadyInitialized();
    error LBPair__EmptyMarketConfigs();
    error LBPair__FlashLoanCallbackFailed();
    error LBPair__FlashLoanInsufficientAmount();
    error LBPair__InsufficientAmountIn();
    error LBPair__InsufficientAmountOut();
    error LBPair__InvalidInput();
    error LBPair__InvalidStaticFeeParameters();
    error LBPair__OnlyFactory();
    error LBPair__OnlyProtocolFeeRecipient();
    error LBPair__OutOfLiquidity();
    error LBPair__TokenNotSupported();
    error LBPair__ZeroAmount(uint24 id);
    error LBPair__ZeroAmountsOut(uint24 id);
    error LBPair__ZeroShares(uint24 id);
    error LBPair__MaxTotalFeeExceeded();

    event DepositedToBins(address indexed sender, address indexed to, uint256[] ids, bytes32[] amounts);

    event WithdrawnFromBins(address indexed sender, address indexed to, uint256[] ids, bytes32[] amounts);

    event CompositionFees(address indexed sender, uint24 id, bytes32 totalFees, bytes32 protocolFees);

    event CollectedProtocolFees(address indexed feeRecipient, bytes32 protocolFees);

    event Swap(
        address indexed sender,
        address indexed to,
        uint24 id,
        bytes32 amountsIn,
        bytes32 amountsOut,
        uint24 volatilityAccumulator,
        bytes32 totalFees,
        bytes32 protocolFees
    );

    event StaticFeeParametersSet(
        address indexed sender,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator
    );

    event FlashLoan(
        address indexed sender,
        ILBFlashLoanCallback indexed receiver,
        uint24 activeId,
        bytes32 amounts,
        bytes32 totalFees,
        bytes32 protocolFees
    );

    event OracleLengthIncreased(address indexed sender, uint16 oracleLength);

    event ForcedDecay(address indexed sender, uint24 idReference, uint24 volatilityReference);

    function initialize(
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator,
        uint24 activeId
    ) external;

    function getFactory() external view returns (ILBFactory factory);

    function getTokenX() external view returns (IERC20 tokenX);

    function getTokenY() external view returns (IERC20 tokenY);

    function getBinStep() external view returns (uint16 binStep);

    function getReserves() external view returns (uint128 reserveX, uint128 reserveY);

    function getActiveId() external view returns (uint24 activeId);

    function getBin(uint24 id) external view returns (uint128 binReserveX, uint128 binReserveY);

    function getNextNonEmptyBin(bool swapForY, uint24 id) external view returns (uint24 nextId);

    function getProtocolFees() external view returns (uint128 protocolFeeX, uint128 protocolFeeY);

    function getStaticFeeParameters()
        external
        view
        returns (
            uint16 baseFactor,
            uint16 filterPeriod,
            uint16 decayPeriod,
            uint16 reductionFactor,
            uint24 variableFeeControl,
            uint16 protocolShare,
            uint24 maxVolatilityAccumulator
        );

    function getVariableFeeParameters()
        external
        view
        returns (uint24 volatilityAccumulator, uint24 volatilityReference, uint24 idReference, uint40 timeOfLastUpdate);

    function getOracleParameters()
        external
        view
        returns (uint8 sampleLifetime, uint16 size, uint16 activeSize, uint40 lastUpdated, uint40 firstTimestamp);

    function getOracleSampleAt(uint40 lookupTimestamp)
        external
        view
        returns (uint64 cumulativeId, uint64 cumulativeVolatility, uint64 cumulativeBinCrossed);

    function getPriceFromId(uint24 id) external view returns (uint256 price);

    function getIdFromPrice(uint256 price) external view returns (uint24 id);

    function getSwapIn(uint128 amountOut, bool swapForY)
        external
        view
        returns (uint128 amountIn, uint128 amountOutLeft, uint128 fee);

    function getSwapOut(uint128 amountIn, bool swapForY)
        external
        view
        returns (uint128 amountInLeft, uint128 amountOut, uint128 fee);

    function swap(bool swapForY, address to) external returns (bytes32 amountsOut);

    function flashLoan(ILBFlashLoanCallback receiver, bytes32 amounts, bytes calldata data) external;

    function mint(address to, bytes32[] calldata liquidityConfigs, address refundTo)
        external
        returns (bytes32 amountsReceived, bytes32 amountsLeft, uint256[] memory liquidityMinted);

    function burn(address from, address to, uint256[] calldata ids, uint256[] calldata amountsToBurn)
        external
        returns (bytes32[] memory amounts);

    function collectProtocolFees() external returns (bytes32 collectedProtocolFees);

    function increaseOracleLength(uint16 newLength) external;

    function setStaticFeeParameters(
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator
    ) external;

    function forceDecay() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @title Liquidity Book Token Interface
 * @author Trader Joe
 * @notice Interface to interact with the LBToken.
 */
interface ILBToken {
    error LBToken__AddressThisOrZero();
    error LBToken__InvalidLength();
    error LBToken__SelfApproval(address owner);
    error LBToken__SpenderNotApproved(address from, address spender);
    error LBToken__TransferExceedsBalance(address from, uint256 id, uint256 amount);
    error LBToken__BurnExceedsBalance(address from, uint256 id, uint256 amount);

    event TransferBatch(
        address indexed sender, address indexed from, address indexed to, uint256[] ids, uint256[] amounts
    );

    event ApprovalForAll(address indexed account, address indexed sender, bool approved);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply(uint256 id) external view returns (uint256);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function isApprovedForAll(address owner, address spender) external view returns (bool);

    function approveForAll(address spender, bool approved) external;

    function batchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @title Liquidity Book Pending Ownable Interface
 * @author Trader Joe
 * @notice Required interface of Pending Ownable contract used for LBFactory
 */
interface IPendingOwnable {
    error PendingOwnable__AddressZero();
    error PendingOwnable__NoPendingOwner();
    error PendingOwnable__NotOwner();
    error PendingOwnable__NotPendingOwner();
    error PendingOwnable__PendingOwnerAlreadySet();

    event PendingOwnerSet(address indexed pendingOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function setPendingOwner(address pendingOwner) external;

    function revokePendingOwner() external;

    function becomeOwner() external;

    function renounceOwnership() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @title Liquidity Book Constants Library
 * @author Trader Joe
 * @notice Set of constants for Liquidity Book contracts
 */
library Constants {
    uint8 internal constant SCALE_OFFSET = 128;
    uint256 internal constant SCALE = 1 << SCALE_OFFSET;

    uint256 internal constant PRECISION = 1e18;
    uint256 internal constant SQUARED_PRECISION = PRECISION * PRECISION;

    uint256 internal constant MAX_FEE = 0.1e18; // 10%
    uint256 internal constant MAX_PROTOCOL_SHARE = 2_500; // 25% of the fee

    uint256 internal constant BASIS_POINT_MAX = 10_000;

    /// @dev The expected return after a successful flash loan
    bytes32 internal constant CALLBACK_SUCCESS = keccak256("LBPair.onFlashLoan");
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

/**
 * @title Liquidity Book Joe Library Helper Library
 * @author Trader Joe
 * @notice Helper contract used for Joe V1 related calculations
 */
library JoeLibrary {
    error JoeLibrary__AddressZero();
    error JoeLibrary__IdenticalAddresses();
    error JoeLibrary__InsufficientAmount();
    error JoeLibrary__InsufficientLiquidity();

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        if (tokenA == tokenB) revert JoeLibrary__IdenticalAddresses();
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        if (token0 == address(0)) revert JoeLibrary__AddressZero();
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) internal pure returns (uint256 amountB) {
        if (amountA == 0) revert JoeLibrary__InsufficientAmount();
        if (reserveA == 0 || reserveB == 0) revert JoeLibrary__InsufficientLiquidity();
        amountB = (amountA * reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        internal
        pure
        returns (uint256 amountOut)
    {
        if (amountIn == 0) revert JoeLibrary__InsufficientAmount();
        if (reserveIn == 0 || reserveOut == 0) revert JoeLibrary__InsufficientLiquidity();
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut)
        internal
        pure
        returns (uint256 amountIn)
    {
        if (amountOut == 0) revert JoeLibrary__InsufficientAmount();
        if (reserveIn == 0 || reserveOut == 0) revert JoeLibrary__InsufficientLiquidity();
        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 997;
        amountIn = numerator / denominator + 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {Uint128x128Math} from "./math/Uint128x128Math.sol";
import {Uint256x256Math} from "./math/Uint256x256Math.sol";
import {SafeCast} from "./math/SafeCast.sol";
import {Constants} from "./Constants.sol";

/**
 * @title Liquidity Book Price Helper Library
 * @author Trader Joe
 * @notice This library contains functions to calculate prices
 */
library PriceHelper {
    using Uint128x128Math for uint256;
    using Uint256x256Math for uint256;
    using SafeCast for uint256;

    int256 private constant REAL_ID_SHIFT = 1 << 23;

    /**
     * @dev Calculates the price from the id and the bin step
     * @param id The id
     * @param binStep The bin step
     * @return price The price as a 128.128-binary fixed-point number
     */
    function getPriceFromId(uint24 id, uint16 binStep) internal pure returns (uint256 price) {
        uint256 base = getBase(binStep);
        int256 exponent = getExponent(id);

        price = base.pow(exponent);
    }

    /**
     * @dev Calculates the id from the price and the bin step
     * @param price The price as a 128.128-binary fixed-point number
     * @param binStep The bin step
     * @return id The id
     */
    function getIdFromPrice(uint256 price, uint16 binStep) internal pure returns (uint24 id) {
        uint256 base = getBase(binStep);
        int256 realId = price.log2() / base.log2();

        unchecked {
            id = uint256(REAL_ID_SHIFT + realId).safe24();
        }
    }

    /**
     * @dev Calculates the base from the bin step, which is `1 + binStep / BASIS_POINT_MAX`
     * @param binStep The bin step
     * @return base The base
     */
    function getBase(uint16 binStep) internal pure returns (uint256) {
        unchecked {
            return Constants.SCALE + (uint256(binStep) << Constants.SCALE_OFFSET) / Constants.BASIS_POINT_MAX;
        }
    }

    /**
     * @dev Calculates the exponent from the id, which is `id - REAL_ID_SHIFT`
     * @param id The id
     * @return exponent The exponent
     */
    function getExponent(uint24 id) internal pure returns (int256) {
        unchecked {
            return int256(uint256(id)) - REAL_ID_SHIFT;
        }
    }

    /**
     * @dev Converts a price with 18 decimals to a 128.128-binary fixed-point number
     * @param price The price with 18 decimals
     * @return price128x128 The 128.128-binary fixed-point number
     */
    function convertDecimalPriceTo128x128(uint256 price) internal pure returns (uint256) {
        return price.shiftDivRoundDown(Constants.SCALE_OFFSET, Constants.PRECISION);
    }

    /**
     * @dev Converts a 128.128-binary fixed-point number to a price with 18 decimals
     * @param price128x128 The 128.128-binary fixed-point number
     * @return price The price with 18 decimals
     */
    function convert128x128PriceToDecimal(uint256 price128x128) internal pure returns (uint256) {
        return price128x128.mulShiftRoundDown(Constants.PRECISION, Constants.SCALE_OFFSET);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @title Liquidity Book Bit Math Library
 * @author Trader Joe
 * @notice Helper contract used for bit calculations
 */
library BitMath {
    /**
     * @dev Returns the index of the closest bit on the right of x that is non null
     * @param x The value as a uint256
     * @param bit The index of the bit to start searching at
     * @return id The index of the closest non null bit on the right of x.
     * If there is no closest bit, it returns max(uint256)
     */
    function closestBitRight(uint256 x, uint8 bit) internal pure returns (uint256 id) {
        unchecked {
            uint256 shift = 255 - bit;
            x <<= shift;

            // can't overflow as it's non-zero and we shifted it by `_shift`
            return (x == 0) ? type(uint256).max : mostSignificantBit(x) - shift;
        }
    }

    /**
     * @dev Returns the index of the closest bit on the left of x that is non null
     * @param x The value as a uint256
     * @param bit The index of the bit to start searching at
     * @return id The index of the closest non null bit on the left of x.
     * If there is no closest bit, it returns max(uint256)
     */
    function closestBitLeft(uint256 x, uint8 bit) internal pure returns (uint256 id) {
        unchecked {
            x >>= bit;

            return (x == 0) ? type(uint256).max : leastSignificantBit(x) + bit;
        }
    }

    /**
     * @dev Returns the index of the most significant bit of x
     * This function returns 0 if x is 0
     * @param x The value as a uint256
     * @return msb The index of the most significant bit of x
     */
    function mostSignificantBit(uint256 x) internal pure returns (uint8 msb) {
        assembly {
            if gt(x, 0xffffffffffffffffffffffffffffffff) {
                x := shr(128, x)
                msb := 128
            }
            if gt(x, 0xffffffffffffffff) {
                x := shr(64, x)
                msb := add(msb, 64)
            }
            if gt(x, 0xffffffff) {
                x := shr(32, x)
                msb := add(msb, 32)
            }
            if gt(x, 0xffff) {
                x := shr(16, x)
                msb := add(msb, 16)
            }
            if gt(x, 0xff) {
                x := shr(8, x)
                msb := add(msb, 8)
            }
            if gt(x, 0xf) {
                x := shr(4, x)
                msb := add(msb, 4)
            }
            if gt(x, 0x3) {
                x := shr(2, x)
                msb := add(msb, 2)
            }
            if gt(x, 0x1) { msb := add(msb, 1) }
        }
    }

    /**
     * @dev Returns the index of the least significant bit of x
     * This function returns 255 if x is 0
     * @param x The value as a uint256
     * @return lsb The index of the least significant bit of x
     */
    function leastSignificantBit(uint256 x) internal pure returns (uint8 lsb) {
        assembly {
            let sx := shl(128, x)
            if iszero(iszero(sx)) {
                lsb := 128
                x := sx
            }
            sx := shl(64, x)
            if iszero(iszero(sx)) {
                x := sx
                lsb := add(lsb, 64)
            }
            sx := shl(32, x)
            if iszero(iszero(sx)) {
                x := sx
                lsb := add(lsb, 32)
            }
            sx := shl(16, x)
            if iszero(iszero(sx)) {
                x := sx
                lsb := add(lsb, 16)
            }
            sx := shl(8, x)
            if iszero(iszero(sx)) {
                x := sx
                lsb := add(lsb, 8)
            }
            sx := shl(4, x)
            if iszero(iszero(sx)) {
                x := sx
                lsb := add(lsb, 4)
            }
            sx := shl(2, x)
            if iszero(iszero(sx)) {
                x := sx
                lsb := add(lsb, 2)
            }
            if iszero(iszero(shl(1, x))) { lsb := add(lsb, 1) }

            lsb := sub(255, lsb)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @title Liquidity Book Safe Cast Library
 * @author Trader Joe
 * @notice This library contains functions to safely cast uint256 to different uint types.
 */
library SafeCast {
    error SafeCast__Exceeds248Bits();
    error SafeCast__Exceeds240Bits();
    error SafeCast__Exceeds232Bits();
    error SafeCast__Exceeds224Bits();
    error SafeCast__Exceeds216Bits();
    error SafeCast__Exceeds208Bits();
    error SafeCast__Exceeds200Bits();
    error SafeCast__Exceeds192Bits();
    error SafeCast__Exceeds184Bits();
    error SafeCast__Exceeds176Bits();
    error SafeCast__Exceeds168Bits();
    error SafeCast__Exceeds160Bits();
    error SafeCast__Exceeds152Bits();
    error SafeCast__Exceeds144Bits();
    error SafeCast__Exceeds136Bits();
    error SafeCast__Exceeds128Bits();
    error SafeCast__Exceeds120Bits();
    error SafeCast__Exceeds112Bits();
    error SafeCast__Exceeds104Bits();
    error SafeCast__Exceeds96Bits();
    error SafeCast__Exceeds88Bits();
    error SafeCast__Exceeds80Bits();
    error SafeCast__Exceeds72Bits();
    error SafeCast__Exceeds64Bits();
    error SafeCast__Exceeds56Bits();
    error SafeCast__Exceeds48Bits();
    error SafeCast__Exceeds40Bits();
    error SafeCast__Exceeds32Bits();
    error SafeCast__Exceeds24Bits();
    error SafeCast__Exceeds16Bits();
    error SafeCast__Exceeds8Bits();

    /**
     * @dev Returns x on uint248 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint248
     */
    function safe248(uint256 x) internal pure returns (uint248 y) {
        if ((y = uint248(x)) != x) revert SafeCast__Exceeds248Bits();
    }

    /**
     * @dev Returns x on uint240 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint240
     */
    function safe240(uint256 x) internal pure returns (uint240 y) {
        if ((y = uint240(x)) != x) revert SafeCast__Exceeds240Bits();
    }

    /**
     * @dev Returns x on uint232 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint232
     */
    function safe232(uint256 x) internal pure returns (uint232 y) {
        if ((y = uint232(x)) != x) revert SafeCast__Exceeds232Bits();
    }

    /**
     * @dev Returns x on uint224 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint224
     */
    function safe224(uint256 x) internal pure returns (uint224 y) {
        if ((y = uint224(x)) != x) revert SafeCast__Exceeds224Bits();
    }

    /**
     * @dev Returns x on uint216 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint216
     */
    function safe216(uint256 x) internal pure returns (uint216 y) {
        if ((y = uint216(x)) != x) revert SafeCast__Exceeds216Bits();
    }

    /**
     * @dev Returns x on uint208 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint208
     */
    function safe208(uint256 x) internal pure returns (uint208 y) {
        if ((y = uint208(x)) != x) revert SafeCast__Exceeds208Bits();
    }

    /**
     * @dev Returns x on uint200 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint200
     */
    function safe200(uint256 x) internal pure returns (uint200 y) {
        if ((y = uint200(x)) != x) revert SafeCast__Exceeds200Bits();
    }

    /**
     * @dev Returns x on uint192 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint192
     */
    function safe192(uint256 x) internal pure returns (uint192 y) {
        if ((y = uint192(x)) != x) revert SafeCast__Exceeds192Bits();
    }

    /**
     * @dev Returns x on uint184 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint184
     */
    function safe184(uint256 x) internal pure returns (uint184 y) {
        if ((y = uint184(x)) != x) revert SafeCast__Exceeds184Bits();
    }

    /**
     * @dev Returns x on uint176 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint176
     */
    function safe176(uint256 x) internal pure returns (uint176 y) {
        if ((y = uint176(x)) != x) revert SafeCast__Exceeds176Bits();
    }

    /**
     * @dev Returns x on uint168 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint168
     */
    function safe168(uint256 x) internal pure returns (uint168 y) {
        if ((y = uint168(x)) != x) revert SafeCast__Exceeds168Bits();
    }

    /**
     * @dev Returns x on uint160 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint160
     */
    function safe160(uint256 x) internal pure returns (uint160 y) {
        if ((y = uint160(x)) != x) revert SafeCast__Exceeds160Bits();
    }

    /**
     * @dev Returns x on uint152 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint152
     */
    function safe152(uint256 x) internal pure returns (uint152 y) {
        if ((y = uint152(x)) != x) revert SafeCast__Exceeds152Bits();
    }

    /**
     * @dev Returns x on uint144 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint144
     */
    function safe144(uint256 x) internal pure returns (uint144 y) {
        if ((y = uint144(x)) != x) revert SafeCast__Exceeds144Bits();
    }

    /**
     * @dev Returns x on uint136 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint136
     */
    function safe136(uint256 x) internal pure returns (uint136 y) {
        if ((y = uint136(x)) != x) revert SafeCast__Exceeds136Bits();
    }

    /**
     * @dev Returns x on uint128 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint128
     */
    function safe128(uint256 x) internal pure returns (uint128 y) {
        if ((y = uint128(x)) != x) revert SafeCast__Exceeds128Bits();
    }

    /**
     * @dev Returns x on uint120 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint120
     */
    function safe120(uint256 x) internal pure returns (uint120 y) {
        if ((y = uint120(x)) != x) revert SafeCast__Exceeds120Bits();
    }

    /**
     * @dev Returns x on uint112 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint112
     */
    function safe112(uint256 x) internal pure returns (uint112 y) {
        if ((y = uint112(x)) != x) revert SafeCast__Exceeds112Bits();
    }

    /**
     * @dev Returns x on uint104 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint104
     */
    function safe104(uint256 x) internal pure returns (uint104 y) {
        if ((y = uint104(x)) != x) revert SafeCast__Exceeds104Bits();
    }

    /**
     * @dev Returns x on uint96 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint96
     */
    function safe96(uint256 x) internal pure returns (uint96 y) {
        if ((y = uint96(x)) != x) revert SafeCast__Exceeds96Bits();
    }

    /**
     * @dev Returns x on uint88 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint88
     */
    function safe88(uint256 x) internal pure returns (uint88 y) {
        if ((y = uint88(x)) != x) revert SafeCast__Exceeds88Bits();
    }

    /**
     * @dev Returns x on uint80 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint80
     */
    function safe80(uint256 x) internal pure returns (uint80 y) {
        if ((y = uint80(x)) != x) revert SafeCast__Exceeds80Bits();
    }

    /**
     * @dev Returns x on uint72 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint72
     */
    function safe72(uint256 x) internal pure returns (uint72 y) {
        if ((y = uint72(x)) != x) revert SafeCast__Exceeds72Bits();
    }

    /**
     * @dev Returns x on uint64 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint64
     */
    function safe64(uint256 x) internal pure returns (uint64 y) {
        if ((y = uint64(x)) != x) revert SafeCast__Exceeds64Bits();
    }

    /**
     * @dev Returns x on uint56 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint56
     */
    function safe56(uint256 x) internal pure returns (uint56 y) {
        if ((y = uint56(x)) != x) revert SafeCast__Exceeds56Bits();
    }

    /**
     * @dev Returns x on uint48 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint48
     */
    function safe48(uint256 x) internal pure returns (uint48 y) {
        if ((y = uint48(x)) != x) revert SafeCast__Exceeds48Bits();
    }

    /**
     * @dev Returns x on uint40 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint40
     */
    function safe40(uint256 x) internal pure returns (uint40 y) {
        if ((y = uint40(x)) != x) revert SafeCast__Exceeds40Bits();
    }

    /**
     * @dev Returns x on uint32 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint32
     */
    function safe32(uint256 x) internal pure returns (uint32 y) {
        if ((y = uint32(x)) != x) revert SafeCast__Exceeds32Bits();
    }

    /**
     * @dev Returns x on uint24 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint24
     */
    function safe24(uint256 x) internal pure returns (uint24 y) {
        if ((y = uint24(x)) != x) revert SafeCast__Exceeds24Bits();
    }

    /**
     * @dev Returns x on uint16 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint16
     */
    function safe16(uint256 x) internal pure returns (uint16 y) {
        if ((y = uint16(x)) != x) revert SafeCast__Exceeds16Bits();
    }

    /**
     * @dev Returns x on uint8 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint8
     */
    function safe8(uint256 x) internal pure returns (uint8 y) {
        if ((y = uint8(x)) != x) revert SafeCast__Exceeds8Bits();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {Constants} from "../Constants.sol";
import {BitMath} from "./BitMath.sol";

/**
 * @title Liquidity Book Uint128x128 Math Library
 * @author Trader Joe
 * @notice Helper contract used for power and log calculations
 */
library Uint128x128Math {
    using BitMath for uint256;

    error Uint128x128Math__LogUnderflow();
    error Uint128x128Math__PowUnderflow(uint256 x, int256 y);

    uint256 constant LOG_SCALE_OFFSET = 127;
    uint256 constant LOG_SCALE = 1 << LOG_SCALE_OFFSET;
    uint256 constant LOG_SCALE_SQUARED = LOG_SCALE * LOG_SCALE;

    /**
     * @notice Calculates the binary logarithm of x.
     * @dev Based on the iterative approximation algorithm.
     * https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
     * Requirements:
     * - x must be greater than zero.
     * Caveats:
     * - The results are not perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation
     * Also because x is converted to an unsigned 129.127-binary fixed-point number during the operation to optimize the multiplication
     * @param x The unsigned 128.128-binary fixed-point number for which to calculate the binary logarithm.
     * @return result The binary logarithm as a signed 128.128-binary fixed-point number.
     */
    function log2(uint256 x) internal pure returns (int256 result) {
        // Convert x to a unsigned 129.127-binary fixed-point number to optimize the multiplication.
        // If we use an offset of 128 bits, y would need 129 bits and y**2 would would overflow and we would have to
        // use mulDiv, by reducing x to 129.127-binary fixed-point number we assert that y will use 128 bits, and we
        // can use the regular multiplication

        if (x == 1) return -128;
        if (x == 0) revert Uint128x128Math__LogUnderflow();

        x >>= 1;

        unchecked {
            // This works because log2(x) = -log2(1/x).
            int256 sign;
            if (x >= LOG_SCALE) {
                sign = 1;
            } else {
                sign = -1;
                // Do the fixed-point inversion inline to save gas
                x = LOG_SCALE_SQUARED / x;
            }

            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = (x >> LOG_SCALE_OFFSET).mostSignificantBit();

            // The integer part of the logarithm as a signed 129.127-binary fixed-point number. The operation can't overflow
            // because n is maximum 255, LOG_SCALE_OFFSET is 127 bits and sign is either 1 or -1.
            result = int256(n) << LOG_SCALE_OFFSET;

            // This is y = x * 2^(-n).
            uint256 y = x >> n;

            // If y = 1, the fractional part is zero.
            if (y != LOG_SCALE) {
                // Calculate the fractional part via the iterative approximation.
                // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
                for (int256 delta = int256(1 << (LOG_SCALE_OFFSET - 1)); delta > 0; delta >>= 1) {
                    y = (y * y) >> LOG_SCALE_OFFSET;

                    // Is y^2 > 2 and so in the range [2,4)?
                    if (y >= 1 << (LOG_SCALE_OFFSET + 1)) {
                        // Add the 2^(-m) factor to the logarithm.
                        result += delta;

                        // Corresponds to z/2 on Wikipedia.
                        y >>= 1;
                    }
                }
            }
            // Convert x back to unsigned 128.128-binary fixed-point number
            result = (result * sign) << 1;
        }
    }

    /**
     * @notice Returns the value of x^y. It calculates `1 / x^abs(y)` if x is bigger than 2^128.
     * At the end of the operations, we invert the result if needed.
     * @param x The unsigned 128.128-binary fixed-point number for which to calculate the power
     * @param y A relative number without any decimals, needs to be between ]2^21; 2^21[
     */
    function pow(uint256 x, int256 y) internal pure returns (uint256 result) {
        bool invert;
        uint256 absY;

        if (y == 0) return Constants.SCALE;

        assembly {
            absY := y
            if slt(absY, 0) {
                absY := sub(0, absY)
                invert := iszero(invert)
            }
        }

        if (absY < 0x100000) {
            result = Constants.SCALE;
            assembly {
                let squared := x
                if gt(x, 0xffffffffffffffffffffffffffffffff) {
                    squared := div(not(0), squared)
                    invert := iszero(invert)
                }

                if and(absY, 0x1) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x2) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x4) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x8) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x10) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x20) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x40) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x80) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x100) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x200) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x400) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x800) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x1000) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x2000) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x4000) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x8000) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x10000) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x20000) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x40000) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x80000) { result := shr(128, mul(result, squared)) }
            }
        }

        // revert if y is too big or if x^y underflowed
        if (result == 0) revert Uint128x128Math__PowUnderflow(x, y);

        return invert ? type(uint256).max / result : result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @title Liquidity Book Uint256x256 Math Library
 * @author Trader Joe
 * @notice Helper contract used for full precision calculations
 */
library Uint256x256Math {
    error Uint256x256Math__MulShiftOverflow();
    error Uint256x256Math__MulDivOverflow();

    /**
     * @notice Calculates floor(x*y/denominator) with full precision
     * The result will be rounded down
     * @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
     * Requirements:
     * - The denominator cannot be zero
     * - The result must fit within uint256
     * Caveats:
     * - This function does not work with fixed-point numbers
     * @param x The multiplicand as an uint256
     * @param y The multiplier as an uint256
     * @param denominator The divisor as an uint256
     * @return result The result as an uint256
     */
    function mulDivRoundDown(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        (uint256 prod0, uint256 prod1) = _getMulProds(x, y);

        return _getEndOfDivRoundDown(x, y, denominator, prod0, prod1);
    }

    /**
     * @notice Calculates ceil(x*y/denominator) with full precision
     * The result will be rounded up
     * @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
     * Requirements:
     * - The denominator cannot be zero
     * - The result must fit within uint256
     * Caveats:
     * - This function does not work with fixed-point numbers
     * @param x The multiplicand as an uint256
     * @param y The multiplier as an uint256
     * @param denominator The divisor as an uint256
     * @return result The result as an uint256
     */
    function mulDivRoundUp(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        result = mulDivRoundDown(x, y, denominator);
        if (mulmod(x, y, denominator) != 0) result += 1;
    }

    /**
     * @notice Calculates floor(x * y / 2**offset) with full precision
     * The result will be rounded down
     * @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
     * Requirements:
     * - The offset needs to be strictly lower than 256
     * - The result must fit within uint256
     * Caveats:
     * - This function does not work with fixed-point numbers
     * @param x The multiplicand as an uint256
     * @param y The multiplier as an uint256
     * @param offset The offset as an uint256, can't be greater than 256
     * @return result The result as an uint256
     */
    function mulShiftRoundDown(uint256 x, uint256 y, uint8 offset) internal pure returns (uint256 result) {
        (uint256 prod0, uint256 prod1) = _getMulProds(x, y);

        if (prod0 != 0) result = prod0 >> offset;
        if (prod1 != 0) {
            // Make sure the result is less than 2^256.
            if (prod1 >= 1 << offset) revert Uint256x256Math__MulShiftOverflow();

            unchecked {
                result += prod1 << (256 - offset);
            }
        }
    }

    /**
     * @notice Calculates floor(x * y / 2**offset) with full precision
     * The result will be rounded down
     * @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
     * Requirements:
     * - The offset needs to be strictly lower than 256
     * - The result must fit within uint256
     * Caveats:
     * - This function does not work with fixed-point numbers
     * @param x The multiplicand as an uint256
     * @param y The multiplier as an uint256
     * @param offset The offset as an uint256, can't be greater than 256
     * @return result The result as an uint256
     */
    function mulShiftRoundUp(uint256 x, uint256 y, uint8 offset) internal pure returns (uint256 result) {
        result = mulShiftRoundDown(x, y, offset);
        if (mulmod(x, y, 1 << offset) != 0) result += 1;
    }

    /**
     * @notice Calculates floor(x << offset / y) with full precision
     * The result will be rounded down
     * @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
     * Requirements:
     * - The offset needs to be strictly lower than 256
     * - The result must fit within uint256
     * Caveats:
     * - This function does not work with fixed-point numbers
     * @param x The multiplicand as an uint256
     * @param offset The number of bit to shift x as an uint256
     * @param denominator The divisor as an uint256
     * @return result The result as an uint256
     */
    function shiftDivRoundDown(uint256 x, uint8 offset, uint256 denominator) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;

        prod0 = x << offset; // Least significant 256 bits of the product
        unchecked {
            prod1 = x >> (256 - offset); // Most significant 256 bits of the product
        }

        return _getEndOfDivRoundDown(x, 1 << offset, denominator, prod0, prod1);
    }

    /**
     * @notice Calculates ceil(x << offset / y) with full precision
     * The result will be rounded up
     * @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
     * Requirements:
     * - The offset needs to be strictly lower than 256
     * - The result must fit within uint256
     * Caveats:
     * - This function does not work with fixed-point numbers
     * @param x The multiplicand as an uint256
     * @param offset The number of bit to shift x as an uint256
     * @param denominator The divisor as an uint256
     * @return result The result as an uint256
     */
    function shiftDivRoundUp(uint256 x, uint8 offset, uint256 denominator) internal pure returns (uint256 result) {
        result = shiftDivRoundDown(x, offset, denominator);
        if (mulmod(x, 1 << offset, denominator) != 0) result += 1;
    }

    /**
     * @notice Helper function to return the result of `x * y` as 2 uint256
     * @param x The multiplicand as an uint256
     * @param y The multiplier as an uint256
     * @return prod0 The least significant 256 bits of the product
     * @return prod1 The most significant 256 bits of the product
     */
    function _getMulProds(uint256 x, uint256 y) private pure returns (uint256 prod0, uint256 prod1) {
        // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
        // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2^256 + prod0.
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }
    }

    /**
     * @notice Helper function to return the result of `x * y / denominator` with full precision
     * @param x The multiplicand as an uint256
     * @param y The multiplier as an uint256
     * @param denominator The divisor as an uint256
     * @param prod0 The least significant 256 bits of the product
     * @param prod1 The most significant 256 bits of the product
     * @return result The result as an uint256
     */
    function _getEndOfDivRoundDown(uint256 x, uint256 y, uint256 denominator, uint256 prod0, uint256 prod1)
        private
        pure
        returns (uint256 result)
    {
        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            unchecked {
                result = prod0 / denominator;
            }
        } else {
            // Make sure the result is less than 2^256. Also prevents denominator == 0
            if (prod1 >= denominator) revert Uint256x256Math__MulDivOverflow();

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1
            // See https://cs.stackexchange.com/q/138556/92363
            unchecked {
                // Does not overflow because the denominator cannot be zero at this stage in the function
                uint256 lpotdod = denominator & (~denominator + 1);
                assembly {
                    // Divide denominator by lpotdod.
                    denominator := div(denominator, lpotdod)

                    // Divide [prod1 prod0] by lpotdod.
                    prod0 := div(prod0, lpotdod)

                    // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one
                    lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
                }

                // Shift in bits from prod1 into prod0
                prod0 |= prod1 * lpotdod;

                // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
                // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
                // four bits. That is, denominator * inv = 1 mod 2^4
                uint256 inverse = (3 * denominator) ^ 2;

                // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
                // in modular arithmetic, doubling the correct bits in each step
                inverse *= 2 - denominator * inverse; // inverse mod 2^8
                inverse *= 2 - denominator * inverse; // inverse mod 2^16
                inverse *= 2 - denominator * inverse; // inverse mod 2^32
                inverse *= 2 - denominator * inverse; // inverse mod 2^64
                inverse *= 2 - denominator * inverse; // inverse mod 2^128
                inverse *= 2 - denominator * inverse; // inverse mod 2^256

                // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
                // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
                // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
                // is no longer required.
                result = prod0 * inverse;
            }
        }
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ISafeOwnable.sol";

interface ISafeAccessControlEnumerable is ISafeOwnable {
    error SafeAccessControlEnumerable__OnlyRole(address account, bytes32 role);
    error SafeAccessControlEnumerable__OnlyOwnerOrRole(address account, bytes32 role);
    error SafeAccessControlEnumerable__RoleAlreadyGranted(address account, bytes32 role);
    error SafeAccessControlEnumerable__AccountAlreadyHasRole(address account, bytes32 role);
    error SafeAccessControlEnumerable__AccountDoesNotHaveRole(address account, bytes32 role);

    event RoleGranted(address indexed sender, bytes32 indexed role, address indexed account);
    event RoleRevoked(address indexed sender, bytes32 indexed role, address indexed account);
    event RoleAdminSet(address indexed sender, bytes32 indexed role, bytes32 indexed adminRole);

    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleMemberCount(bytes32 role) external view returns (uint256);

    function getRoleMemberAt(bytes32 role, uint256 index) external view returns (address);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface ISafeOwnable {
    error SafeOwnable__OnlyOwner();
    error SafeOwnable__OnlyPendingOwner();

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PendingOwnerSet(address indexed owner, address indexed pendingOwner);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function setPendingOwner(address newPendingOwner) external;

    function becomeOwner() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "../structs/EnumerableMap.sol";
import "./ISafeAccessControlEnumerable.sol";
import "./SafeOwnable.sol";

/**
 * @title Safe Access Control Enumerable
 * @author 0x0Louis
 * @notice This contract is used to manage a set of addresses that have been granted a specific role.
 * Only the owner can be granted the DEFAULT_ADMIN_ROLE.
 */
abstract contract SafeAccessControlEnumerable is SafeOwnable, ISafeAccessControlEnumerable {
    using EnumerableMap for EnumerableMap.AddressSet;

    struct EnumerableRoleData {
        EnumerableMap.AddressSet members;
        bytes32 adminRole;
    }

    bytes32 public constant override DEFAULT_ADMIN_ROLE = 0x00;

    mapping(bytes32 => EnumerableRoleData) private _roles;

    /**
     * @dev Modifier that checks if the caller has the role `role`.
     */
    modifier onlyRole(bytes32 role) {
        if (!hasRole(role, msg.sender)) revert SafeAccessControlEnumerable__OnlyRole(msg.sender, role);
        _;
    }

    /**
     * @dev Modifier that checks if the caller has the role `role` or the role `DEFAULT_ADMIN_ROLE`.
     */
    modifier onlyOwnerOrRole(bytes32 role) {
        if (owner() != msg.sender && !hasRole(role, msg.sender)) {
            revert SafeAccessControlEnumerable__OnlyOwnerOrRole(msg.sender, role);
        }
        _;
    }

    /**
     * @notice Checks if an account has a role.
     * @param role The role to check.
     * @param account The account to check.
     * @return True if the account has the role, false otherwise.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @notice Returns the number of accounts that have the role.
     * @param role The role to check.
     * @return The number of accounts that have the role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @notice Returns the account at the given index in the role.
     * @param role The role to check.
     * @param index The index to check.
     * @return The account at the given index in the role.
     */
    function getRoleMemberAt(bytes32 role, uint256 index) public view override returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @notice Returns the admin role of the given role.
     * @param role The role to check.
     * @return The admin role of the given role.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @notice Grants `role` to `account`.
     * @param role The role to grant.
     * @param account The account to grant the role to.
     */
    function grantRole(bytes32 role, address account) public override onlyOwnerOrRole((getRoleAdmin(role))) {
        if (!_grantRole(role, account)) revert SafeAccessControlEnumerable__AccountAlreadyHasRole(account, role);
    }

    /**
     * @notice Revokes `role` from `account`.
     * @param role The role to revoke.
     * @param account The account to revoke the role from.
     */
    function revokeRole(bytes32 role, address account) public override onlyOwnerOrRole((getRoleAdmin(role))) {
        if (!_revokeRole(role, account)) revert SafeAccessControlEnumerable__AccountDoesNotHaveRole(account, role);
    }

    /**
     * @notice Revokes `role` from the calling account.
     * @param role The role to revoke.
     */
    function renounceRole(bytes32 role) public override {
        if (!_revokeRole(role, msg.sender)) {
            revert SafeAccessControlEnumerable__AccountDoesNotHaveRole(msg.sender, role);
        }
    }

    function _transferOwnership(address newOwner) internal override {
        address previousOwner = owner();
        super._transferOwnership(newOwner);

        _revokeRole(DEFAULT_ADMIN_ROLE, previousOwner);
        _grantRole(DEFAULT_ADMIN_ROLE, newOwner);
    }

    /**
     * @notice Grants `role` to `account`.
     * @param role The role to grant.
     * @param account The account to grant the role to.
     * @return True if the role was granted to the account, that is if the account did not already have the role,
     * false otherwise.
     */
    function _grantRole(bytes32 role, address account) internal returns (bool) {
        if (role == DEFAULT_ADMIN_ROLE && owner() != account || !_roles[role].members.add(account)) return false;

        emit RoleGranted(msg.sender, role, account);
        return true;
    }

    /**
     * @notice Revokes `role` from `account`.
     * @param role The role to revoke.
     * @param account The account to revoke the role from.
     * @return True if the role was revoked from the account, that is if the account had the role,
     * false otherwise.
     */
    function _revokeRole(bytes32 role, address account) internal returns (bool) {
        if (role == DEFAULT_ADMIN_ROLE && owner() != account || !_roles[role].members.remove(account)) return false;

        emit RoleRevoked(msg.sender, role, account);
        return true;
    }

    /**
     * @notice Sets `role` as the admin role of `adminRole`.
     * @param role The role to set as the admin role.
     * @param adminRole The role to set as the admin role of `role`.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
        _roles[role].adminRole = adminRole;

        emit RoleAdminSet(msg.sender, role, adminRole);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ISafeOwnable.sol";

/**
 * @title Safe Ownable
 * @author 0x0Louis
 * @notice This contract is used to manage the ownership of a contract in a two-step process.
 */
abstract contract SafeOwnable is ISafeOwnable {
    address private _owner;
    address private _pendingOwner;

    /**
     * @dev Modifier that checks if the caller is the owner.
     */
    modifier onlyOwner() {
        if (msg.sender != owner()) revert SafeOwnable__OnlyOwner();
        _;
    }

    /**
     * @dev Modifier that checks if the caller is the pending owner.
     */
    modifier onlyPendingOwner() {
        if (msg.sender != pendingOwner()) revert SafeOwnable__OnlyPendingOwner();
        _;
    }

    /**
     * @notice Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    /**
     * @notice Returns the address of the current owner.
     */
    function owner() public view virtual override returns (address) {
        return _owner;
    }

    /**
     * @notice Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual override returns (address) {
        return _pendingOwner;
    }

    /**
     * @notice Sets the pending owner to a new address.
     * @param newOwner The address to transfer ownership to.
     */
    function setPendingOwner(address newOwner) public virtual override onlyOwner {
        _setPendingOwner(newOwner);
    }

    /**
     * @notice Accepts ownership of the contract.
     * @dev Can only be called by the pending owner.
     */
    function becomeOwner() public virtual override onlyPendingOwner {
        address newOwner = _pendingOwner;

        _setPendingOwner(address(0));
        _transferOwnership(newOwner);
    }

    /**
     * Private Functions
     */

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev Sets the pending owner to a new address.
     * @param newPendingOwner The address to transfer ownership to.
     */
    function _setPendingOwner(address newPendingOwner) internal virtual {
        _pendingOwner = newPendingOwner;
        emit PendingOwnerSet(msg.sender, newPendingOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Enumerable Map
 * @author 0x0Louis
 * @notice Implements a simple enumerable map that maps keys to values.
 * @dev This library is very close to the EnumerableMap library from OpenZeppelin.
 * The main difference is that this library use only one storage slot to store the
 * keys and values while the OpenZeppelin library uses two storage slots.
 *
 * Enumerable maps have the folowing properties:
 *
 * - Elements are added, removed, updated, checked for existence and returned in constant time (O(1)).
 * - Elements are enumerated in linear time (O(n)). Enumeration is not guaranteed to be in any particular order.
 *
 * Usage:
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.AddressToUint96Map;
 *
 *    // Declare a map state variable
 *     EnumerableMap.AddressToUint96Map private _map;
 * ```
 *
 * Currently, only address keys to uint96 values are supported.
 *
 * The library also provides enumerable sets. Using the same implementation as the enumerable maps,
 * but the values and the keys are the same.
 */
library EnumerableMap {
    struct EnumerableMapping {
        bytes32[] _entries;
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @notice Returns the value at the given index.
     * @param self The enumerable mapping to query.
     * @param index The index.
     * @return value The value at the given index.
     */
    function _at(EnumerableMapping storage self, uint256 index) private view returns (bytes32 value) {
        value = self._entries[index];
    }

    /**
     * @notice Returns the value associated with the given key.
     * @dev Returns 0 if the key is not in the enumerable mapping. Use `contains` to check for existence.
     * @param self The enumerable mapping to query.
     * @param key The key.
     * @return value The value associated with the given key.
     */
    function _get(EnumerableMapping storage self, bytes32 key) private view returns (bytes32 value) {
        uint256 index = self._indexes[key];
        if (index == 0) return bytes12(0);

        value = _at(self, index - 1);
    }

    /**
     * @notice Returns true if the enumerable mapping contains the given key.
     * @param self The enumerable mapping to query.
     * @param key The key.
     * @return True if the given key is in the enumerable mapping.
     */
    function _contains(EnumerableMapping storage self, bytes32 key) private view returns (bool) {
        return self._indexes[key] != 0;
    }

    /**
     * @notice Returns the number of elements in the enumerable mapping.
     * @param self The enumerable mapping to query.
     * @return The number of elements in the enumerable mapping.
     */
    function _length(EnumerableMapping storage self) private view returns (uint256) {
        return self._entries.length;
    }

    /**
     * @notice Adds the given key and value to the enumerable mapping.
     * @param self The enumerable mapping to update.
     * @param offset The offset to add to the key.
     * @param key The key to add.
     * @param value The value associated with the key.
     * @return True if the key was added to the enumerable mapping, that is if it was not already in the enumerable mapping.
     */
    function _add(
        EnumerableMapping storage self,
        uint8 offset,
        bytes32 key,
        bytes32 value
    ) private returns (bool) {
        if (!_contains(self, key)) {
            self._entries.push(_encode(offset, key, value));
            self._indexes[key] = self._entries.length;
            return true;
        }

        return false;
    }

    /**
     * @notice Removes a key from the enumerable mapping.
     * @param self The enumerable mapping to update.
     * @param offset The offset to use when removing the key.
     * @param key The key to remove.
     * @return True if the key was removed from the enumerable mapping, that is if it was present in the enumerable mapping.
     */
    function _remove(
        EnumerableMapping storage self,
        uint8 offset,
        bytes32 key
    ) private returns (bool) {
        uint256 keyIndex = self._indexes[key];

        if (keyIndex != 0) {
            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = self._entries.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastentry = self._entries[lastIndex];
                bytes32 lastKey = _decodeKey(offset, lastentry);

                self._entries[toDeleteIndex] = lastentry;
                self._indexes[lastKey] = keyIndex;
            }

            self._entries.pop();
            delete self._indexes[key];

            return true;
        }

        return false;
    }

    /**
     * @notice Updates the value associated with the given key in the enumerable mapping.
     * @param self The enumerable mapping to update.
     * @param offset The offset to use when setting the key.
     * @param key The key to set.
     * @param value The value to set.
     * @return True if the value was updated, that is if the key was already in the enumerable mapping.
     */
    function _update(
        EnumerableMapping storage self,
        uint8 offset,
        bytes32 key,
        bytes32 value
    ) private returns (bool) {
        uint256 keyIndex = self._indexes[key];

        if (keyIndex != 0) {
            self._entries[keyIndex - 1] = _encode(offset, key, value);

            return true;
        }

        return false;
    }

    /**
     * @notice Encodes a key and a value into a bytes32.
     * @dev The key is encoded at the beginning of the bytes32 using the given offset.
     * The value is encoded at the end of the bytes32.
     * There is no overflow check, so the key and value must be small enough to fit both in the bytes32.
     * @param offset The offset to use when encoding the key.
     * @param key The key to encode.
     * @param value The value to encode.
     * @return encoded The encoded bytes32.
     */
    function _encode(
        uint8 offset,
        bytes32 key,
        bytes32 value
    ) private pure returns (bytes32 encoded) {
        encoded = (key << offset) | value;
    }

    /**
     * @notice Decodes a bytes32 into an addres key
     * @param offset The offset to use when decoding the key.
     * @param entry The bytes32 to decode.
     * @return key The key.
     */
    function _decodeKey(uint8 offset, bytes32 entry) private pure returns (bytes32 key) {
        key = entry >> offset;
    }

    /**
     * @notice Decodes a bytes32 into a bytes32 value.
     * @param mask The mask to use when decoding the value.
     * @param entry The bytes32 to decode.
     * @return value The decoded value.
     */
    function _decodeValue(uint256 mask, bytes32 entry) private pure returns (bytes32 value) {
        value = entry & bytes32(mask);
    }

    /** Address to Uint96 Map */

    /**
     * @dev Structure to represent a map of address keys to uint96 values.
     * The first 20 bytes of the key are used to store the address, and the last 12 bytes are used to store the uint96 value.
     */
    struct AddressToUint96Map {
        EnumerableMapping _inner;
    }

    uint256 private constant _ADDRESS_TO_UINT96_MAP_MASK = type(uint96).max;
    uint8 private constant _ADDRESS_TO_UINT96_MAP_OFFSET = 96;

    /**
     * @notice Returns the address key and the uint96 value at the given index.
     * @param self The address to uint96 map to query.
     * @param index The index.
     * @return key The key at the given index.
     * @return value The value at the given index.
     */
    function at(AddressToUint96Map storage self, uint256 index) internal view returns (address key, uint96 value) {
        bytes32 entry = _at(self._inner, index);

        key = address(uint160(uint256(_decodeKey(_ADDRESS_TO_UINT96_MAP_OFFSET, entry))));
        value = uint96(uint256(_decodeValue(_ADDRESS_TO_UINT96_MAP_MASK, entry)));
    }

    /**
     * @notice Returns the uint96 value associated with the given key.
     * @dev Returns 0 if the key is not in the map. Use `contains` to check for existence.
     * @param self The address to uint96 map to query.
     * @param key The address key.
     * @return value The uint96 value associated with the given key.
     */
    function get(AddressToUint96Map storage self, address key) internal view returns (uint96 value) {
        bytes32 entry = _get(self._inner, bytes32(uint256(uint160(key))));

        value = uint96(uint256(_decodeValue(_ADDRESS_TO_UINT96_MAP_MASK, entry)));
    }

    /**
     * @notice Returns the number of elements in the map.
     * @param self The address to uint96 map to query.
     * @return The number of elements in the map.
     */
    function length(AddressToUint96Map storage self) internal view returns (uint256) {
        return _length(self._inner);
    }

    /**
     * @notice Returns true if the map contains the given key.
     * @param self The address to uint96 map to query.
     * @param key The address key.
     * @return True if the map contains the given key.
     */
    function contains(AddressToUint96Map storage self, address key) internal view returns (bool) {
        return _contains(self._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @notice Adds a key-value pair to the map.
     * @param self The address to uint96 map to update.
     * @param key The address key.
     * @param value The uint96 value.
     * @return True if the key-value pair was added, that is if the key was not already in the map.
     */
    function add(
        AddressToUint96Map storage self,
        address key,
        uint96 value
    ) internal returns (bool) {
        return
            _add(self._inner, _ADDRESS_TO_UINT96_MAP_OFFSET, bytes32(uint256(uint160(key))), bytes32(uint256(value)));
    }

    /**
     * @notice Removes a key-value pair from the map.
     * @param self The address to uint96 map to update.
     * @param key The address key.
     * @return True if the key-value pair was removed, that is if the key was in the map.
     */
    function remove(AddressToUint96Map storage self, address key) internal returns (bool) {
        return _remove(self._inner, _ADDRESS_TO_UINT96_MAP_OFFSET, bytes32(uint256(uint160(key))));
    }

    /**
     * @notice Updates a key-value pair in the map.
     * @param self The address to uint96 map to update.
     * @param key The address key.
     * @param value The uint96 value.
     * @return True if the value was updated, that is if the key was already in the map.
     */
    function update(
        AddressToUint96Map storage self,
        address key,
        uint96 value
    ) internal returns (bool) {
        return
            _update(
                self._inner,
                _ADDRESS_TO_UINT96_MAP_OFFSET,
                bytes32(uint256(uint160(key))),
                bytes32(uint256(value))
            );
    }

    /** Bytes32 Set */

    /**
     * @dev Structure to represent a set of bytes32 values.
     */
    struct Bytes32Set {
        EnumerableMapping _inner;
    }

    uint8 private constant _BYTES32_SET_OFFSET = 0;

    // uint256 private constant _BYTES32_SET_MASK = type(uint256).max; // unused

    /**
     * @notice Returns the bytes32 value at the given index.
     * @param self The bytes32 set to query.
     * @param index The index.
     * @return value The value at the given index.
     */
    function at(Bytes32Set storage self, uint256 index) internal view returns (bytes32 value) {
        value = _at(self._inner, index);
    }

    /**
     * @notice Returns the number of elements in the set.
     * @param self The bytes32 set to query.
     * @return The number of elements in the set.
     */
    function length(Bytes32Set storage self) internal view returns (uint256) {
        return _length(self._inner);
    }

    /**
     * @notice Returns true if the set contains the given value.
     * @param self The bytes32 set to query.
     * @param value The bytes32 value.
     * @return True if the set contains the given value.
     */
    function contains(Bytes32Set storage self, bytes32 value) internal view returns (bool) {
        return _contains(self._inner, value);
    }

    /**
     * @notice Adds a value to the set.
     * @param self The bytes32 set to update.
     * @param value The bytes32 value.
     * @return True if the value was added, that is if the value was not already in the set.
     */
    function add(Bytes32Set storage self, bytes32 value) internal returns (bool) {
        return _add(self._inner, _BYTES32_SET_OFFSET, value, bytes32(0));
    }

    /**
     * @notice Removes a value from the set.
     * @param self The bytes32 set to update.
     * @param value The bytes32 value.
     * @return True if the value was removed, that is if the value was in the set.
     */
    function remove(Bytes32Set storage self, bytes32 value) internal returns (bool) {
        return _remove(self._inner, _BYTES32_SET_OFFSET, value);
    }

    /** Uint Set */

    /**
     * @dev Structure to represent a set of uint256 values.
     */
    struct UintSet {
        EnumerableMapping _inner;
    }

    uint8 private constant _UINT_SET_OFFSET = 0;

    // uint256 private constant _UINT_SET_MASK = type(uint256).max; // unused

    /**
     * @notice Returns the uint256 value at the given index.
     * @param self The uint256 set to query.
     * @param index The index.
     * @return value The value at the given index.
     */
    function at(UintSet storage self, uint256 index) internal view returns (uint256 value) {
        value = uint256(_at(self._inner, index));
    }

    /**
     * @notice Returns the number of elements in the set.
     * @param self The uint256 set to query.
     * @return The number of elements in the set.
     */
    function length(UintSet storage self) internal view returns (uint256) {
        return _length(self._inner);
    }

    /**
     * @notice Returns true if the set contains the given value.
     * @param self The uint256 set to query.
     * @param value The uint256 value.
     * @return True if the set contains the given value.
     */
    function contains(UintSet storage self, uint256 value) internal view returns (bool) {
        return _contains(self._inner, bytes32(value));
    }

    /**
     * @notice Adds a value to the set.
     * @param self The uint256 set to update.
     * @param value The uint256 value.
     * @return True if the value was added, that is if the value was not already in the set.
     */
    function add(UintSet storage self, uint256 value) internal returns (bool) {
        return _add(self._inner, _UINT_SET_OFFSET, bytes32(value), bytes32(0));
    }

    /**
     * @notice Removes a value from the set.
     * @param self The uint256 set to update.
     * @param value The uint256 value.
     * @return True if the value was removed, that is if the value was in the set.
     */
    function remove(UintSet storage self, uint256 value) internal returns (bool) {
        return _remove(self._inner, _UINT_SET_OFFSET, bytes32(value));
    }

    /** Address Set */

    /**
     * @dev Structure to represent a set of address values.
     */
    struct AddressSet {
        EnumerableMapping _inner;
    }

    // uint256 private constant _ADDRESS_SET_MASK = type(uint160).max; // unused
    uint8 private constant _ADDRESS_SET_OFFSET = 0;

    /**
     * @notice Returns the address value at the given index.
     * @param self The address set to query.
     * @param index The index.
     * @return value The value at the given index.
     */
    function at(AddressSet storage self, uint256 index) internal view returns (address value) {
        value = address(uint160(uint256(_at(self._inner, index))));
    }

    /**
     * @notice Returns the number of elements in the set.
     * @param self The address set to query.
     * @return The number of elements in the set.
     */
    function length(AddressSet storage self) internal view returns (uint256) {
        return _length(self._inner);
    }

    /**
     * @notice Returns true if the set contains the given value.
     * @param self The address set to query.
     * @param value The address value.
     * @return True if the set contains the given value.
     */
    function contains(AddressSet storage self, address value) internal view returns (bool) {
        return _contains(self._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @notice Adds a value to the set.
     * @param self The address set to update.
     * @param value The address value.
     * @return True if the value was added, that is if the value was not already in the set.
     */
    function add(AddressSet storage self, address value) internal returns (bool) {
        return _add(self._inner, _ADDRESS_SET_OFFSET, bytes32(uint256(uint160(value))), bytes32(0));
    }

    /**
     * @notice Removes a value from the set.
     * @param self The address set to update.
     * @param value The address value.
     * @return True if the value was removed, that is if the value was in the set.
     */
    function remove(AddressSet storage self, address value) internal returns (bool) {
        return _remove(self._inner, _ADDRESS_SET_OFFSET, bytes32(uint256(uint160(value))));
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {Constants} from "joe-v2/libraries/Constants.sol";
import {PriceHelper} from "joe-v2/libraries/PriceHelper.sol";
import {JoeLibrary} from "joe-v2/libraries/JoeLibrary.sol";
import {IJoeFactory} from "joe-v2/interfaces/IJoeFactory.sol";
import {IJoePair} from "joe-v2/interfaces/IJoePair.sol";
import {ILBFactory} from "joe-v2/interfaces/ILBFactory.sol";
import {ILBLegacyFactory} from "joe-v2/interfaces/ILBLegacyFactory.sol";
import {ILBLegacyPair} from "joe-v2/interfaces/ILBLegacyPair.sol";
import {ILBPair} from "joe-v2/interfaces/ILBPair.sol";
import {Uint256x256Math} from "joe-v2/libraries/math/Uint256x256Math.sol";
import {IERC20Metadata, IERC20} from "openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import {
    ISafeAccessControlEnumerable, SafeAccessControlEnumerable
} from "solrary/access/SafeAccessControlEnumerable.sol";

import {AggregatorV3Interface} from "./interfaces/AggregatorV3Interface.sol";
import {IJoeDexLens} from "./interfaces/IJoeDexLens.sol";

/**
 * @title Joe Dex Lens
 * @author Trader Joe
 * @notice This contract allows to price tokens in either Native or USD.
 * It uses a set of data feeds to get the price of a token. The data feeds can be added or removed by the owner and
 * the data feed manager. They can also set the weight of each data feed.
 * When no data feed is provided, the contract will iterate over TOKEN/WNative
 * pools on v2.1, v2 and v1 to find a weighted average price.
 */
contract JoeDexLens is SafeAccessControlEnumerable, IJoeDexLens {
    using Uint256x256Math for uint256;
    using PriceHelper for uint24;

    bytes32 public constant DATA_FEED_MANAGER_ROLE = keccak256("DATA_FEED_MANAGER_ROLE");

    uint256 private constant _BIN_WIDTH = 5;
    uint256 private constant _TWO_BASIS_POINT = 20_000;

    ILBFactory private immutable _FACTORY_V2_1;
    ILBLegacyFactory private immutable _LEGACY_FACTORY_V2;
    IJoeFactory private immutable _FACTORY_V1;

    address private immutable _WNATIVE;
    uint256 private immutable _WNATIVE_DECIMALS;
    uint256 private immutable _WNATIVE_PRECISION;

    /**
     * @dev Mapping from a token to an enumerable set of data feeds used to get the price of the token
     */
    mapping(address => DataFeedSet) private _whitelistedDataFeeds;

    /**
     * Modifiers *
     */

    /**
     * @notice Verify that the two lengths match
     * @dev Revert if length are not equal
     * @param lengthA The length of the first list
     * @param lengthB The length of the second list
     */
    modifier verifyLengths(uint256 lengthA, uint256 lengthB) {
        if (lengthA != lengthB) revert JoeDexLens__LengthsMismatch();
        _;
    }

    /**
     * @notice Verify a data feed
     * @dev Revert if :
     * - The dataFeed's collateral and the token are the same address
     * - The dataFeed's collateral is not one of the two tokens of the pair (if the dfType is V1 or V2)
     * - The token is not one of the two tokens of the pair (if the dfType is V1 or V2)
     * @param token The address of the token
     * @param dataFeed The data feeds information
     */
    modifier verifyDataFeed(address token, DataFeed calldata dataFeed) {
        address collateralAddress = dataFeed.collateralAddress;
        if (collateralAddress == token) revert JoeDexLens__SameTokens();

        DataFeedType dfType = dataFeed.dfType;

        if (dfType != DataFeedType.CHAINLINK) {
            if (dfType == DataFeedType.V2_1 && address(_FACTORY_V2_1) == address(0)) {
                revert JoeDexLens__V2_1ContractNotSet();
            } else if (dfType == DataFeedType.V2 && address(_LEGACY_FACTORY_V2) == address(0)) {
                revert JoeDexLens__V2ContractNotSet();
            } else if (dfType == DataFeedType.V1 && address(_FACTORY_V1) == address(0)) {
                revert JoeDexLens__V1ContractNotSet();
            }

            (address tokenA, address tokenB) = _getPairedTokens(dataFeed.dfAddress, dfType);

            if (tokenA != collateralAddress && tokenB != collateralAddress) {
                revert JoeDexLens__CollateralNotInPair(dataFeed.dfAddress, collateralAddress);
            }

            if (tokenA != token && tokenB != token) revert JoeDexLens__TokenNotInPair(dataFeed.dfAddress, token);
        }
        _;
    }

    /**
     * @notice Verify the weight for a data feed
     * @dev Revert if the weight is equal to 0
     * @param weight The weight of a data feed
     */
    modifier verifyWeight(uint88 weight) {
        if (weight == 0) revert JoeDexLens__NullWeight();
        _;
    }

    /**
     * @notice Constructor of the contract
     * @dev Revert if :
     * - All addresses are zero
     * - wnative is zero
     * @param lbFactory The address of the v2.1 factory
     * @param lbLegacyFactory The address of the v2 factory
     * @param joeFactory The address of the v1 factory
     * @param wnative The address of the wnative token
     */
    constructor(ILBFactory lbFactory, ILBLegacyFactory lbLegacyFactory, IJoeFactory joeFactory, address wnative) {
        // revert if all addresses are zero or if wnative is zero
        if (
            address(lbFactory) == address(0) && address(lbLegacyFactory) == address(0)
                && address(joeFactory) == address(0) || wnative == address(0)
        ) {
            revert JoeDexLens__ZeroAddress();
        }

        _FACTORY_V1 = joeFactory;
        _LEGACY_FACTORY_V2 = lbLegacyFactory;
        _FACTORY_V2_1 = lbFactory;

        _WNATIVE = wnative;

        _WNATIVE_DECIMALS = IERC20Metadata(wnative).decimals();
        _WNATIVE_PRECISION = 10 ** _WNATIVE_DECIMALS;
    }

    /**
     * @notice Initialize the contract
     * @dev Transfer the ownership to the sender and set the native data feed
     * @param aggregator The address of the aggregator
     */
    function initialize(address aggregator) external {
        if (_getDataFeedsLength(_WNATIVE) != 0) revert JoeDexLens__AlreadyInitialized();
        _whitelistedDataFeeds[_WNATIVE].dataFeeds.push();

        _transferOwnership(msg.sender);
        _setNativeDataFeed(aggregator);
    }

    /**
     * @notice Returns the address of the wrapped native token
     * @return wNative The address of the wrapped native token
     */
    function getWNative() external view override returns (address wNative) {
        return _WNATIVE;
    }

    /**
     * @notice Returns the address of the factory v1
     * @return factoryV1 The address of the factory v1
     */
    function getFactoryV1() external view override returns (IJoeFactory factoryV1) {
        return _FACTORY_V1;
    }

    /**
     * @notice Returns the address of the factory v2
     * @return legacyFactoryV2 The address of the factory v2
     */
    function getLegacyFactoryV2() external view override returns (ILBLegacyFactory legacyFactoryV2) {
        return _LEGACY_FACTORY_V2;
    }

    /**
     * @notice Returns the address of the factory v2.1
     * @return factoryV2 The address of the factory v2.1
     */
    function getFactoryV2_1() external view override returns (ILBFactory factoryV2) {
        return _FACTORY_V2_1;
    }

    /**
     * @notice Returns the list of data feeds used to calculate the price of the token
     * @param token The address of the token
     * @return dataFeeds The array of data feeds used to price `token`
     */
    function getDataFeeds(address token) external view override returns (DataFeed[] memory dataFeeds) {
        return _whitelistedDataFeeds[token].dataFeeds;
    }

    /**
     * @notice Returns the price of token in USD, scaled with wnative's decimals
     * @param token The address of the token
     * @return price The price of the token in USD, with wnative's decimals
     */
    function getTokenPriceUSD(address token) external view override returns (uint256 price) {
        return _getTokenWeightedAverageNativePrice(token) * _getNativePrice() / _WNATIVE_PRECISION;
    }

    /**
     * @notice Returns the price of token in Native, scaled with wnative's decimals
     * @param token The address of the token
     * @return price The price of the token in Native, with wnative's decimals
     */
    function getTokenPriceNative(address token) external view override returns (uint256 price) {
        return _getTokenWeightedAverageNativePrice(token);
    }

    /**
     * @notice Returns the prices of each token in USD, scaled with wnative's decimals
     * @param tokens The list of address of the tokens
     * @return prices The prices of each token in USD, with wnative's decimals
     */
    function getTokensPricesUSD(address[] calldata tokens) external view override returns (uint256[] memory prices) {
        return _getTokenWeightedAverageNativePrices(tokens);
    }

    /**
     * @notice Returns the prices of each token in Native, scaled with wnative's decimals
     * @param tokens The list of address of the tokens
     * @return prices The prices of each token in Native, with wnative's decimals
     */
    function getTokensPricesNative(address[] calldata tokens)
        external
        view
        override
        returns (uint256[] memory prices)
    {
        return _getTokenWeightedAverageNativePrices(tokens);
    }

    /**
     * Owner Functions *
     */

    /**
     * @notice Set the chainlink datafeed for the native token
     * @dev Can only be called by the owner
     * @param aggregator The address of the chainlink aggregator
     */
    function setNativeDataFeed(address aggregator) external override onlyOwnerOrRole(DATA_FEED_MANAGER_ROLE) {
        _setNativeDataFeed(aggregator);
    }

    /**
     * @notice Add a data feed for a specific token
     * @dev Can only be called by the owner
     * @param token The address of the token
     * @param dataFeed The data feeds information
     */
    function addDataFeed(address token, DataFeed calldata dataFeed)
        external
        override
        onlyOwnerOrRole(DATA_FEED_MANAGER_ROLE)
    {
        if (token == _WNATIVE) revert JoeDexLens__NativeToken();

        _addDataFeed(token, dataFeed);
    }

    /**
     * @notice Set the Native weight for a specific data feed of a token
     * @dev Can only be called by the owner
     * @param token The address of the token
     * @param dfAddress The data feed address
     * @param newWeight The new weight of the data feed
     */
    function setDataFeedWeight(address token, address dfAddress, uint88 newWeight)
        external
        override
        onlyOwnerOrRole(DATA_FEED_MANAGER_ROLE)
    {
        _setDataFeedWeight(token, dfAddress, newWeight);
    }

    /**
     * @notice Remove a data feed of a token
     * @dev Can only be called by the owner
     * @param token The address of the token
     * @param dfAddress The data feed address
     */
    function removeDataFeed(address token, address dfAddress)
        external
        override
        onlyOwnerOrRole(DATA_FEED_MANAGER_ROLE)
    {
        if (token == _WNATIVE) revert JoeDexLens__NativeToken();

        _removeDataFeed(token, dfAddress);
    }

    /**
     * @notice Batch add data feed for each (token, data feed)
     * @dev Can only be called by the owner
     * @param tokens The addresses of the tokens
     * @param dataFeeds The list of Native data feeds informations
     */
    function addDataFeeds(address[] calldata tokens, DataFeed[] calldata dataFeeds)
        external
        override
        onlyOwnerOrRole(DATA_FEED_MANAGER_ROLE)
    {
        _addDataFeeds(tokens, dataFeeds);
    }

    /**
     * @notice Batch set the Native weight for each (token, data feed)
     * @dev Can only be called by the owner
     * @param tokens The list of addresses of the tokens
     * @param dfAddresses The list of Native data feed addresses
     * @param newWeights The list of new weights of the data feeds
     */
    function setDataFeedsWeights(
        address[] calldata tokens,
        address[] calldata dfAddresses,
        uint88[] calldata newWeights
    ) external override onlyOwnerOrRole(DATA_FEED_MANAGER_ROLE) {
        _setDataFeedsWeights(tokens, dfAddresses, newWeights);
    }

    /**
     * @notice Batch remove a list of data feeds for each (token, data feed)
     * @dev Can only be called by the owner
     * @param tokens The list of addresses of the tokens
     * @param dfAddresses The list of data feed addresses
     */
    function removeDataFeeds(address[] calldata tokens, address[] calldata dfAddresses)
        external
        override
        onlyOwnerOrRole(DATA_FEED_MANAGER_ROLE)
    {
        _removeDataFeeds(tokens, dfAddresses);
    }

    /**
     * Private Functions *
     */

    /**
     * @notice Returns the data feed length for a specific token
     * @param token The address of the token
     * @return length The number of data feeds
     */
    function _getDataFeedsLength(address token) private view returns (uint256 length) {
        return _whitelistedDataFeeds[token].dataFeeds.length;
    }

    /**
     * @notice Returns the data feed at index `index` for a specific token
     * @param token The address of the token
     * @param index The index
     * @return dataFeed the data feed at index `index`
     */
    function _getDataFeedAt(address token, uint256 index) private view returns (DataFeed memory dataFeed) {
        return _whitelistedDataFeeds[token].dataFeeds[index];
    }

    /**
     * @notice Returns if a token's set contains the data feed address
     * @param token The address of the token
     * @param dfAddress The data feed address
     * @return Whether the set contains the data feed address (true) or not (false)
     */
    function _dataFeedContains(address token, address dfAddress) private view returns (bool) {
        return _whitelistedDataFeeds[token].indexes[dfAddress] != 0;
    }

    /**
     * @notice Add a data feed to a set, return true if it was added, false if not
     * @param token The address of the token
     * @param dataFeed The data feeds information
     * @return Whether the data feed was added (true) to the set or not (false)
     */
    function _addToSet(address token, DataFeed calldata dataFeed) private returns (bool) {
        if (!_dataFeedContains(token, dataFeed.dfAddress)) {
            DataFeedSet storage set = _whitelistedDataFeeds[token];

            set.dataFeeds.push(dataFeed);
            set.indexes[dataFeed.dfAddress] = set.dataFeeds.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice Remove a data feed from a set, returns true if it was removed, false if not
     * @param token The address of the token
     * @param dfAddress The data feed address
     * @return Whether the data feed was removed (true) from the set or not (false)
     */
    function _removeFromSet(address token, address dfAddress) private returns (bool) {
        DataFeedSet storage set = _whitelistedDataFeeds[token];
        uint256 dataFeedIndex = set.indexes[dfAddress];

        if (dataFeedIndex != 0) {
            uint256 toDeleteIndex = dataFeedIndex - 1;
            uint256 lastIndex = set.dataFeeds.length - 1;

            if (toDeleteIndex != lastIndex) {
                DataFeed memory lastDataFeed = set.dataFeeds[lastIndex];

                set.dataFeeds[toDeleteIndex] = lastDataFeed;
                set.indexes[lastDataFeed.dfAddress] = dataFeedIndex;
            }

            set.dataFeeds.pop();
            delete set.indexes[dfAddress];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice Add a data feed to a set, revert if it couldn't add it
     * @param token The address of the token
     * @param dataFeed The data feeds information
     */
    function _addDataFeed(address token, DataFeed calldata dataFeed)
        private
        verifyDataFeed(token, dataFeed)
        verifyWeight(dataFeed.dfWeight)
    {
        if (!_addToSet(token, dataFeed)) {
            revert JoeDexLens__DataFeedAlreadyAdded(token, dataFeed.dfAddress);
        }

        (uint256 price,) = _getDataFeedPrice(dataFeed, token);
        if (price == 0) revert JoeDexLens__InvalidDataFeed();

        emit DataFeedAdded(token, dataFeed);
    }

    /**
     * @notice Batch add data feed for each (token, data feed)
     * @param tokens The addresses of the tokens
     * @param dataFeeds The list of USD data feeds informations
     */
    function _addDataFeeds(address[] calldata tokens, DataFeed[] calldata dataFeeds)
        private
        verifyLengths(tokens.length, dataFeeds.length)
    {
        for (uint256 i; i < tokens.length;) {
            _addDataFeed(tokens[i], dataFeeds[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Set the weight for a specific data feed of a token
     * @param token The address of the token
     * @param dfAddress The data feed address
     * @param newWeight The new weight of the data feed
     */
    function _setDataFeedWeight(address token, address dfAddress, uint88 newWeight) private verifyWeight(newWeight) {
        DataFeedSet storage set = _whitelistedDataFeeds[token];

        uint256 index = set.indexes[dfAddress];
        if (index == 0) revert JoeDexLens__DataFeedNotInSet(token, dfAddress);

        set.dataFeeds[index - 1].dfWeight = newWeight;

        emit DataFeedsWeightSet(token, dfAddress, newWeight);
    }

    /**
     * @notice Batch set the weight for each (token, data feed)
     * @param tokens The list of addresses of the tokens
     * @param dfAddresses The list of data feed addresses
     * @param newWeights The list of new weights of the data feeds
     */
    function _setDataFeedsWeights(
        address[] calldata tokens,
        address[] calldata dfAddresses,
        uint88[] calldata newWeights
    ) private verifyLengths(tokens.length, dfAddresses.length) verifyLengths(tokens.length, newWeights.length) {
        for (uint256 i; i < tokens.length;) {
            _setDataFeedWeight(tokens[i], dfAddresses[i], newWeights[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Remove a data feed from a set, revert if it couldn't remove it
     * @dev Revert if the token's price is 0 after removing the data feed to prevent the other tokens
     * that use this token as a data feed to have a price of 0
     * @param token The address of the token
     * @param dfAddress The data feed address
     */
    function _removeDataFeed(address token, address dfAddress) private {
        if (!_removeFromSet(token, dfAddress)) {
            revert JoeDexLens__DataFeedNotInSet(token, dfAddress);
        }

        if (_getTokenWeightedAverageNativePrice(token) == 0) revert JoeDexLens__InvalidDataFeed();

        emit DataFeedRemoved(token, dfAddress);
    }

    /**
     * @notice Batch remove a list of data feeds for each (token, data feed)
     * @param tokens The list of addresses of the tokens
     * @param dfAddresses The list of USD data feed addresses
     */
    function _removeDataFeeds(address[] calldata tokens, address[] calldata dfAddresses)
        private
        verifyLengths(tokens.length, dfAddresses.length)
    {
        for (uint256 i; i < tokens.length;) {
            _removeDataFeed(tokens[i], dfAddresses[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Set the native token's data feed
     * @param aggregator The address of the chainlink aggregator
     */
    function _setNativeDataFeed(address aggregator) private {
        if (_getDataFeedAt(_WNATIVE, 0).dfAddress == aggregator) revert JoeDexLens__SameDataFeed();

        DataFeed memory dataFeed = DataFeed(_WNATIVE, aggregator, 1, DataFeedType.CHAINLINK);
        _whitelistedDataFeeds[_WNATIVE].dataFeeds[0] = dataFeed;

        if (_getPriceFromChainlink(aggregator) == 0) revert JoeDexLens__InvalidChainLinkPrice();

        emit NativeDataFeedSet(aggregator);
    }

    /**
     * @notice Return the price of the native token
     * @dev The native token had to have a chainlink data feed set
     * @return price The price of the native token, with the native token's decimals
     */
    function _getNativePrice() private view returns (uint256 price) {
        return _getPriceFromChainlink(_getDataFeedAt(_WNATIVE, 0).dfAddress);
    }

    /**
     * @notice Return the weighted average native price of a token using its data feeds
     * @dev If no data feed was provided, will use `_getNativePriceAnyToken` to try to find a valid price
     * @param token The address of the token
     * @return price The weighted average price of the token, with the wnative's decimals
     */
    function _getTokenWeightedAverageNativePrice(address token) private view returns (uint256 price) {
        if (token == _WNATIVE) return _WNATIVE_PRECISION;

        uint256 length = _getDataFeedsLength(token);
        if (length == 0) return _getNativePriceAnyToken(token);

        uint256 totalWeights;

        for (uint256 i; i < length;) {
            DataFeed memory dataFeed = _getDataFeedAt(token, i);

            (uint256 dfPrice, uint256 dfWeight) = _getDataFeedPrice(dataFeed, token);

            if (dfPrice != 0) {
                price += dfPrice * dfWeight;
                unchecked {
                    totalWeights += dfWeight;
                }
            }

            unchecked {
                ++i;
            }
        }

        price = totalWeights == 0 ? 0 : price / totalWeights;
    }

    /**
     * @notice Return the price of a token using a specific datafeed, with wnative's decimals
     */
    function _getDataFeedPrice(DataFeed memory dataFeed, address token)
        private
        view
        returns (uint256 dfPrice, uint256 dfWeight)
    {
        DataFeedType dfType = dataFeed.dfType;

        if (dfType == DataFeedType.V1) {
            (,, dfPrice,) = _getPriceFromV1(dataFeed.dfAddress, token);
        } else if (dfType == DataFeedType.V2 || dfType == DataFeedType.V2_1) {
            (,, dfPrice,) = _getPriceFromLb(dataFeed.dfAddress, dfType, token);
        } else if (dfType == DataFeedType.CHAINLINK) {
            dfPrice = _getPriceFromChainlink(dataFeed.dfAddress);
        } else {
            revert JoeDexLens__UnknownDataFeedType();
        }

        if (dfPrice != 0) {
            if (dataFeed.collateralAddress != _WNATIVE) {
                uint256 collateralPrice = _getTokenWeightedAverageNativePrice(dataFeed.collateralAddress);
                dfPrice = dfPrice * collateralPrice / _WNATIVE_PRECISION;
            }

            dfWeight = dataFeed.dfWeight;
        }
    }

    /**
     * @notice Batch function to return the weighted average price of each tokens using its data feeds
     * @dev If no data feed was provided, will use `_getNativePriceAnyToken` to try to find a valid price
     * @param tokens The list of addresses of the tokens
     * @return prices The list of weighted average price of each token, with the wnative's decimals
     */
    function _getTokenWeightedAverageNativePrices(address[] calldata tokens)
        private
        view
        returns (uint256[] memory prices)
    {
        prices = new uint256[](tokens.length);
        for (uint256 i; i < tokens.length;) {
            prices[i] = _getTokenWeightedAverageNativePrice(tokens[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Return the price tracked by the aggreagator using chainlink's data feed, with wnative's decimals
     * @param dfAddress The address of the data feed
     * @return price The price tracked by the aggregator, with wnative's decimals
     */
    function _getPriceFromChainlink(address dfAddress) private view returns (uint256 price) {
        AggregatorV3Interface aggregator = AggregatorV3Interface(dfAddress);

        (, int256 sPrice,,,) = aggregator.latestRoundData();
        if (sPrice <= 0) revert JoeDexLens__InvalidChainLinkPrice();

        price = uint256(sPrice);

        uint256 aggregatorDecimals = aggregator.decimals();

        // Return the price with wnative's decimals
        if (aggregatorDecimals < _WNATIVE_DECIMALS) price *= 10 ** (_WNATIVE_DECIMALS - aggregatorDecimals);
        else if (aggregatorDecimals > _WNATIVE_DECIMALS) price /= 10 ** (aggregatorDecimals - _WNATIVE_DECIMALS);
    }

    /**
     * @notice Return the price of the token denominated in the second token of the V1 pair, with wnative's decimals
     * @dev The `token` token needs to be on of the two paired token of the given pair
     * @param pairAddress The address of the pair
     * @param token The address of the token
     * @return reserve0 The reserve of the first token of the pair
     * @return reserve1 The reserve of the second token of the pair
     * @return price The price of the token denominated in the second token of the pair, with wnative's decimals
     * @return isTokenX True if the token is the first token of the pair, false otherwise
     */
    function _getPriceFromV1(address pairAddress, address token)
        private
        view
        returns (uint256 reserve0, uint256 reserve1, uint256 price, bool isTokenX)
    {
        IJoePair pair = IJoePair(pairAddress);

        address token0 = pair.token0();
        address token1 = pair.token1();

        uint256 decimals0 = IERC20Metadata(token0).decimals();
        uint256 decimals1 = IERC20Metadata(token1).decimals();

        (reserve0, reserve1,) = pair.getReserves();
        isTokenX = token == token0;

        // Return the price with wnative's decimals
        if (isTokenX) {
            price =
                reserve0 == 0 ? 0 : (reserve1 * 10 ** (decimals0 + _WNATIVE_DECIMALS)) / (reserve0 * 10 ** decimals1);
        } else {
            price =
                reserve1 == 0 ? 0 : (reserve0 * 10 ** (decimals1 + _WNATIVE_DECIMALS)) / (reserve1 * 10 ** decimals0);
        }
    }

    /**
     * @notice Return the price of the token denominated in the second token of the LB pair, with wnative's decimals
     * @dev The `token` token needs to be on of the two paired token of the given pair
     * @param pair The address of the pair
     * @param dfType The type of the data feed
     * @param token The address of the token
     * @return activeId The active id of the pair
     * @return binStep The bin step of the pair
     * @return price The price of the token, with wnative's decimals
     * @return isTokenX True if the token is the first token of the pair, false otherwise
     */
    function _getPriceFromLb(address pair, DataFeedType dfType, address token)
        private
        view
        returns (uint24 activeId, uint16 binStep, uint256 price, bool isTokenX)
    {
        (address tokenX, address tokenY) = _getPairedTokens(pair, dfType);
        (activeId, binStep) = _getActiveIdAndBinStep(pair, dfType);

        uint256 priceScaled = activeId.getPriceFromId(binStep);

        uint256 decimalsX = IERC20Metadata(tokenX).decimals();
        uint256 decimalsY = IERC20Metadata(tokenY).decimals();

        uint256 precision;

        isTokenX = token == tokenX;

        (priceScaled, precision) = isTokenX
            ? (priceScaled, 10 ** (_WNATIVE_DECIMALS + decimalsX - decimalsY))
            : (type(uint256).max / priceScaled, 10 ** (_WNATIVE_DECIMALS + decimalsY - decimalsX));

        price = priceScaled.mulShiftRoundDown(precision, Constants.SCALE_OFFSET);
    }

    /**
     * @notice Return the addresses of the two tokens of a pair
     * @dev Work with both V1 or V2 pairs
     * @param pair The address of the pair
     * @param dfType The type of the pair, V1, V2 or V2.1
     * @return tokenA The address of the first token of the pair
     * @return tokenB The address of the second token of the pair
     */
    function _getPairedTokens(address pair, DataFeedType dfType)
        private
        view
        returns (address tokenA, address tokenB)
    {
        if (dfType == DataFeedType.V2_1) {
            tokenA = address(ILBPair(pair).getTokenX());
            tokenB = address(ILBPair(pair).getTokenY());
        } else if (dfType == DataFeedType.V2) {
            tokenA = address(ILBLegacyPair(pair).tokenX());
            tokenB = address(ILBLegacyPair(pair).tokenY());
        } else if (dfType == DataFeedType.V1) {
            tokenA = IJoePair(pair).token0();
            tokenB = IJoePair(pair).token1();
        } else {
            revert JoeDexLens__UnknownDataFeedType();
        }
    }

    /**
     * @notice Return the active id and the bin step of a pair
     * @dev Work with both V1 or V2 pairs
     * @param pair The address of the pair
     * @param dfType The type of the pair, V1, V2 or V2.1
     * @return activeId The active id of the pair
     * @return binStep The bin step of the pair
     */
    function _getActiveIdAndBinStep(address pair, DataFeedType dfType)
        private
        view
        returns (uint24 activeId, uint16 binStep)
    {
        if (dfType == DataFeedType.V2) {
            (,, uint256 aId) = ILBLegacyPair(pair).getReservesAndId();
            activeId = uint24(aId);

            binStep = uint16(ILBLegacyPair(pair).feeParameters().binStep);
        } else if (dfType == DataFeedType.V2_1) {
            activeId = ILBPair(pair).getActiveId();
            binStep = ILBPair(pair).getBinStep();
        } else {
            revert JoeDexLens__UnknownDataFeedType();
        }
    }

    /**
     * @notice Tries to find the price of the token on v2.1, v2 and v1 pairs.
     * V2.1 and v2 pairs are checked to have enough liquidity in them, to avoid pricing using stale pools
     * @dev Will return 0 if the token is not paired with wnative on any of the different versions
     * @param token The address of the token
     * @return price The weighted average, based on pair's liquidity, of the token with the collateral's decimals
     */
    function _getNativePriceAnyToken(address token) private view returns (uint256 price) {
        // First check the token price on v2.1
        (uint256 weightedPriceV2_1, uint256 totalWeightV2_1) = _v2_1FallbackNativePrice(token);

        // Then on v2
        (uint256 weightedPriceV2, uint256 totalWeightV2) = _v2FallbackNativePrice(token);

        // Then on v1
        (uint256 weightedPriceV1, uint256 totalWeightV1) = _v1FallbackNativePrice(token);

        uint256 totalWeight = totalWeightV2_1 + totalWeightV2 + totalWeightV1;
        return totalWeight == 0 ? 0 : (weightedPriceV2_1 + weightedPriceV2 + weightedPriceV1) / totalWeight;
    }

    /**
     * @notice Loops through all the wnative/token v2.1 pairs and returns the price of the token if a valid one was found
     * @param token The address of the token
     * @return weightedPrice The weighted price, based on the paired wnative's liquidity,
     * of the token with the collateral's decimals
     * @return totalWeight The total weight of the pairs
     */
    function _v2_1FallbackNativePrice(address token)
        private
        view
        returns (uint256 weightedPrice, uint256 totalWeight)
    {
        if (address(_FACTORY_V2_1) == address(0)) return (0, 0);

        ILBFactory.LBPairInformation[] memory lbPairsAvailable =
            _FACTORY_V2_1.getAllLBPairs(IERC20(_WNATIVE), IERC20(token));

        if (lbPairsAvailable.length != 0) {
            for (uint256 i = 0; i < lbPairsAvailable.length; i++) {
                address lbPair = address(lbPairsAvailable[i].LBPair);

                (uint24 activeId, uint16 binStep, uint256 price, bool isTokenX) =
                    _getPriceFromLb(lbPair, DataFeedType.V2_1, token);

                uint256 scaledReserves = _getLbBinReserves(lbPair, activeId, binStep, isTokenX);

                weightedPrice += price * scaledReserves;
                totalWeight += scaledReserves;
            }
        }
    }

    /**
     * @notice Loops through all the wnative/token v2 pairs and returns the price of the token if a valid one was found
     * @param token The address of the token
     * @return weightedPrice The weighted price, based on the paired wnative's liquidity,
     * of the token with the collateral's decimals
     * @return totalWeight The total weight of the pairs
     */
    function _v2FallbackNativePrice(address token) private view returns (uint256 weightedPrice, uint256 totalWeight) {
        if (address(_LEGACY_FACTORY_V2) == address(0)) return (0, 0);

        ILBLegacyFactory.LBPairInformation[] memory lbPairsAvailable =
            _LEGACY_FACTORY_V2.getAllLBPairs(IERC20(_WNATIVE), IERC20(token));

        if (lbPairsAvailable.length != 0) {
            for (uint256 i = 0; i < lbPairsAvailable.length; i++) {
                address lbPair = address(lbPairsAvailable[i].LBPair);

                (uint24 activeId, uint16 binStep, uint256 price, bool isTokenX) =
                    _getPriceFromLb(lbPair, DataFeedType.V2, token);

                uint256 scaledReserves = _getLbBinReserves(lbPair, activeId, binStep, isTokenX);

                weightedPrice += price * scaledReserves;
                totalWeight += scaledReserves;
            }
        }
    }

    /**
     * @notice Fetchs the wnative/token v1 pair and returns the price of the token if a valid one was found
     * @param token The address of the token
     * @return weightedPrice The weighted price, based on the paired wnative's liquidity,
     * of the token with the collateral's decimals
     * @return totalWeight The total weight of the pairs
     */
    function _v1FallbackNativePrice(address token) private view returns (uint256 weightedPrice, uint256 totalWeight) {
        if (address(_FACTORY_V1) == address(0)) return (0, 0);

        address pair = _FACTORY_V1.getPair(token, _WNATIVE);

        if (pair != address(0)) {
            (uint256 reserve0, uint256 reserve1, uint256 price, bool isTokenX) = _getPriceFromV1(pair, token);

            totalWeight = (isTokenX ? reserve1 : reserve0) * _BIN_WIDTH;
            weightedPrice = price * totalWeight;
        }
    }

    /**
     * @notice Get the scaled reserves of the bins that are close to the active bin, based on the bin step
     * and the wnative's reserves.
     * @dev Multiply the reserves by `20_000 / binStep` to get the scaled reserves and compare them to the
     * reserves of the V1 pair. This is an approximation of the price impact of the different versions.
     * @param lbPair The address of the liquidity book pair
     * @param activeId The active bin id
     * @param binStep The bin step
     * @param isTokenX Whether the token is token X or not
     * @return scaledReserves The scaled reserves of the pair, based on the bin step and the other token's reserves
     */
    function _getLbBinReserves(address lbPair, uint24 activeId, uint16 binStep, bool isTokenX)
        private
        view
        returns (uint256 scaledReserves)
    {
        if (isTokenX) {
            (uint256 start, uint256 end) = (activeId - _BIN_WIDTH + 1, activeId + 1);

            for (uint256 i = start; i < end;) {
                (, uint256 y) = ILBPair(lbPair).getBin(uint24(i));
                scaledReserves += y * _TWO_BASIS_POINT / binStep;

                unchecked {
                    ++i;
                }
            }
        } else {
            (uint256 start, uint256 end) = (activeId, activeId + _BIN_WIDTH);

            for (uint256 i = start; i < end;) {
                (uint256 x,) = ILBPair(lbPair).getBin(uint24(i));
                scaledReserves += x * _TWO_BASIS_POINT / binStep;

                unchecked {
                    ++i;
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {IJoeFactory} from "joe-v2/interfaces/IJoeFactory.sol";
import {ILBFactory} from "joe-v2/interfaces/ILBFactory.sol";
import {ILBLegacyFactory} from "joe-v2/interfaces/ILBLegacyFactory.sol";
import {ISafeAccessControlEnumerable} from "solrary/access/ISafeAccessControlEnumerable.sol";

import {AggregatorV3Interface} from "../interfaces/AggregatorV3Interface.sol";

/// @title Interface of the Joe Dex Lens contract
/// @author Trader Joe
/// @notice The interface needed to interract with the Joe Dex Lens contract
interface IJoeDexLens is ISafeAccessControlEnumerable {
    error JoeDexLens__UnknownDataFeedType();
    error JoeDexLens__CollateralNotInPair(address pair, address collateral);
    error JoeDexLens__TokenNotInPair(address pair, address token);
    error JoeDexLens__SameTokens();
    error JoeDexLens__NativeToken();
    error JoeDexLens__DataFeedAlreadyAdded(address token, address dataFeed);
    error JoeDexLens__DataFeedNotInSet(address token, address dataFeed);
    error JoeDexLens__LengthsMismatch();
    error JoeDexLens__NullWeight();
    error JoeDexLens__InvalidChainLinkPrice();
    error JoeDexLens__V1ContractNotSet();
    error JoeDexLens__V2ContractNotSet();
    error JoeDexLens__V2_1ContractNotSet();
    error JoeDexLens__AlreadyInitialized();
    error JoeDexLens__InvalidDataFeed();
    error JoeDexLens__ZeroAddress();
    error JoeDexLens__SameDataFeed();

    /// @notice Enumerators of the different data feed types
    enum DataFeedType {
        V1,
        V2,
        V2_1,
        CHAINLINK
    }

    /// @notice Structure for data feeds, contains the data feed's address and its type.
    /// For V1/V2, the`dfAddress` should be the address of the pair
    /// For chainlink, the `dfAddress` should be the address of the aggregator
    struct DataFeed {
        address collateralAddress;
        address dfAddress;
        uint88 dfWeight;
        DataFeedType dfType;
    }

    /// @notice Structure for a set of data feeds
    /// `datafeeds` is the list of all the data feeds
    /// `indexes` is a mapping linking the address of a data feed to its index in the `datafeeds` list.
    struct DataFeedSet {
        DataFeed[] dataFeeds;
        mapping(address => uint256) indexes;
    }

    event NativeDataFeedSet(address dfAddress);

    event DataFeedAdded(address token, DataFeed dataFeed);

    event DataFeedsWeightSet(address token, address dfAddress, uint256 weight);

    event DataFeedRemoved(address token, address dfAddress);

    function getWNative() external view returns (address wNative);

    function getFactoryV1() external view returns (IJoeFactory factoryV1);

    function getLegacyFactoryV2() external view returns (ILBLegacyFactory legacyFactoryV2);

    function getFactoryV2_1() external view returns (ILBFactory factoryV2);

    function getDataFeeds(address token) external view returns (DataFeed[] memory dataFeeds);

    function getTokenPriceUSD(address token) external view returns (uint256 price);

    function getTokenPriceNative(address token) external view returns (uint256 price);

    function getTokensPricesUSD(address[] calldata tokens) external view returns (uint256[] memory prices);

    function getTokensPricesNative(address[] calldata tokens) external view returns (uint256[] memory prices);

    function addDataFeed(address token, DataFeed calldata dataFeed) external;

    function setDataFeedWeight(address token, address dfAddress, uint88 newWeight) external;

    function removeDataFeed(address token, address dfAddress) external;

    function addDataFeeds(address[] calldata tokens, DataFeed[] calldata dataFeeds) external;

    function setDataFeedsWeights(
        address[] calldata _tokens,
        address[] calldata _dfAddresses,
        uint88[] calldata _newWeights
    ) external;

    function removeDataFeeds(address[] calldata tokens, address[] calldata dfAddresses) external;

    function setNativeDataFeed(address aggregator) external;
}