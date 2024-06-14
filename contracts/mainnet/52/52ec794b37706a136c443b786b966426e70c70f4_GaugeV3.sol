// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;
pragma abicoder v1;

// INTERFACES
import {IGaugeV3, QuotaRateParams, UserVotes} from "../interfaces/IGaugeV3.sol";
import {IGearStakingV3} from "../interfaces/IGearStakingV3.sol";
import {IPoolQuotaKeeperV3} from "../interfaces/IPoolQuotaKeeperV3.sol";
import {IPoolV3} from "../interfaces/IPoolV3.sol";

// TRAITS
import {ACLNonReentrantTrait} from "../traits/ACLNonReentrantTrait.sol";

// EXCEPTIONS
import {
    CallerNotVoterException,
    IncorrectParameterException,
    TokenNotAllowedException,
    InsufficientVotesException
} from "../interfaces/IExceptions.sol";

/// @title Gauge V3
/// @notice In Gearbox V3, quota rates are determined by GEAR holders that vote to move the rate within a given range.
///         While there are notable mechanic differences, the overall idea of token holders controlling strategy yield
///         is similar to the Curve's gauge system, and thus the contract carries the same name.
///         For each token, there are two parameters: minimum rate determined by the risk committee, and maximum rate
///         determined by the Gearbox DAO. GEAR holders then vote either for CA side, which moves the rate towards min,
///         or for LP side, which moves it towards max.
///         Rates are only updated once per epoch (1 week), to avoid manipulation and make strategies more predictable.
contract GaugeV3 is IGaugeV3, ACLNonReentrantTrait {
    /// @notice Contract version
    uint256 public constant override version = 3_00;

    /// @notice Address of the pool this gauge is connected to
    address public immutable override pool;

    /// @notice Mapping from token address to its rate parameters
    mapping(address => QuotaRateParams) public override quotaRateParams;

    /// @notice Mapping from (user, token) to vote amounts submitted by `user` for each side
    mapping(address => mapping(address => UserVotes)) public override userTokenVotes;

    /// @notice GEAR staking and voting contract
    address public immutable override voter;

    /// @notice Epoch when the rates were last updated
    uint16 public override epochLastUpdate;

    /// @notice Whether gauge is frozen and rates cannot be updated
    bool public override epochFrozen;

    /// @notice Constructor
    /// @param _pool Address of the lending pool
    /// @param _gearStaking Address of the GEAR staking contract
    constructor(address _pool, address _gearStaking)
        ACLNonReentrantTrait(IPoolV3(_pool).addressProvider())
        nonZeroAddress(_gearStaking) // U:[GA-01]
    {
        pool = _pool; // U:[GA-01]
        voter = _gearStaking; // U:[GA-01]
        epochLastUpdate = IGearStakingV3(_gearStaking).getCurrentEpoch(); // U:[GA-01]
        epochFrozen = true; // U:[GA-01]
        emit SetFrozenEpoch(true); // U:[GA-01]
    }

    /// @dev Ensures that function caller is voter
    modifier onlyVoter() {
        _revertIfCallerNotVoter(); // U:[GA-02]
        _;
    }

    /// @notice Updates the epoch and, unless frozen, rates in the quota keeper
    function updateEpoch() external override {
        _checkAndUpdateEpoch(); // U:[GA-14]
    }

    /// @dev Implementation of `updateEpoch`
    function _checkAndUpdateEpoch() internal {
        uint16 epochNow = IGearStakingV3(voter).getCurrentEpoch(); // U:[GA-14]

        if (epochNow > epochLastUpdate) {
            epochLastUpdate = epochNow; // U:[GA-14]

            if (!epochFrozen) {
                // The quota keeper should call back to retrieve quota rates for needed tokens
                _poolQuotaKeeper().updateRates(); // U:[GA-14]
            }

            emit UpdateEpoch(epochNow); // U:[GA-14]
        }
    }

    /// @notice Computes rates for an array of tokens based on the current votes
    /// @dev Actual rates can be different since they are only updated once per epoch
    /// @param tokens Array of tokens to computes rates for
    /// @return rates Array of rates, in the same order as passed tokens
    function getRates(address[] calldata tokens) external view override returns (uint16[] memory rates) {
        uint256 len = tokens.length; // U:[GA-15]
        rates = new uint16[](len); // U:[GA-15]

        unchecked {
            for (uint256 i; i < len; ++i) {
                address token = tokens[i]; // U:[GA-15]

                if (!isTokenAdded(token)) revert TokenNotAllowedException(); // U:[GA-15]

                QuotaRateParams memory qrp = quotaRateParams[token]; // U:[GA-15]

                uint96 votesLpSide = qrp.totalVotesLpSide; // U:[GA-15]
                uint96 votesCaSide = qrp.totalVotesCaSide; // U:[GA-15]
                uint256 totalVotes = votesLpSide + votesCaSide; // U:[GA-15]

                rates[i] = totalVotes == 0
                    ? qrp.minRate
                    : uint16((uint256(qrp.minRate) * votesCaSide + uint256(qrp.maxRate) * votesLpSide) / totalVotes); // U:[GA-15]
            }
        }
    }

    /// @notice Submits user's votes for the provided token and side and updates the epoch if necessary
    /// @param user The user that submitted votes
    /// @param votes Amount of votes to add
    /// @param extraData Gauge specific parameters (encoded into `extraData` to adhere to the voting contract interface)
    ///        * token - address of the token to vote for
    ///        * lpSide - whether the side to add votes for is the LP side
    function vote(address user, uint96 votes, bytes calldata extraData)
        external
        override
        onlyVoter // U:[GA-02]
    {
        (address token, bool lpSide) = abi.decode(extraData, (address, bool)); // U:[GA-10,11,12]
        _vote({user: user, token: token, votes: votes, lpSide: lpSide}); // U:[GA-10,11,12]
    }

    /// @dev Implementation of `vote`
    /// @param user User to add votes to
    /// @param votes Amount of votes to add
    /// @param token Token to add votes for
    /// @param lpSide Side to add votes for: `true` for LP side, `false` for CA side
    function _vote(address user, uint96 votes, address token, bool lpSide) internal {
        if (!isTokenAdded(token)) revert TokenNotAllowedException(); // U:[GA-10]

        _checkAndUpdateEpoch(); // U:[GA-11]

        QuotaRateParams storage qp = quotaRateParams[token]; // U:[GA-12]
        UserVotes storage uv = userTokenVotes[user][token];

        if (lpSide) {
            qp.totalVotesLpSide += votes; // U:[GA-12]
            uv.votesLpSide += votes; // U:[GA-12]
        } else {
            qp.totalVotesCaSide += votes; // U:[GA-12]
            uv.votesCaSide += votes; // U:[GA-12]
        }

        emit Vote({user: user, token: token, votes: votes, lpSide: lpSide}); // U:[GA-12]
    }

    /// @notice Removes user's existing votes for the provided token and side and updates the epoch if necessary
    /// @param user The user that submitted votes
    /// @param votes Amount of votes to remove
    /// @param extraData Gauge specific parameters (encoded into `extraData` to adhere to the voting contract interface)
    ///        * token - address of the token to unvote for
    ///        * lpSide - whether the side to remove votes for is the LP side
    function unvote(address user, uint96 votes, bytes calldata extraData)
        external
        override
        onlyVoter // U:[GA-02]
    {
        (address token, bool lpSide) = abi.decode(extraData, (address, bool)); // U:[GA-10,11,13]
        _unvote({user: user, token: token, votes: votes, lpSide: lpSide}); // U:[GA-10,11,13]
    }

    /// @dev Implementation of `unvote`
    /// @param user User to remove votes from
    /// @param votes Amount of votes to remove
    /// @param token Token to remove votes from
    /// @param lpSide Side to remove votes from: `true` for LP side, `false` for CA side
    function _unvote(address user, uint96 votes, address token, bool lpSide) internal {
        if (!isTokenAdded(token)) revert TokenNotAllowedException(); // U:[GA-10]

        _checkAndUpdateEpoch(); // U:[GA-11]

        QuotaRateParams storage qp = quotaRateParams[token]; // U:[GA-13]
        UserVotes storage uv = userTokenVotes[user][token]; // U:[GA-13]

        if (lpSide) {
            if (uv.votesLpSide < votes) revert InsufficientVotesException();
            unchecked {
                qp.totalVotesLpSide -= votes; // U:[GA-13]
                uv.votesLpSide -= votes; // U:[GA-13]
            }
        } else {
            if (uv.votesCaSide < votes) revert InsufficientVotesException();
            unchecked {
                qp.totalVotesCaSide -= votes; // U:[GA-13]
                uv.votesCaSide -= votes; // U:[GA-13]
            }
        }

        emit Unvote({user: user, token: token, votes: votes, lpSide: lpSide}); // U:[GA-13]
    }

    // ------------- //
    // CONFIGURATION //
    // ------------- //

    /// @notice Sets the frozen epoch status
    /// @param status The new status
    /// @dev The epoch can be frozen to prevent rate updates during gauge/staking contracts migration
    function setFrozenEpoch(bool status) external override configuratorOnly {
        if (status != epochFrozen) {
            epochFrozen = status;

            emit SetFrozenEpoch(status);
        }
    }

    /// @notice Adds a new quoted token to the gauge and sets the initial rate params
    ///         If token is not added to the quota keeper, adds it there as well
    /// @param token Address of the token to add
    /// @param minRate The minimal interest rate paid on token's quotas
    /// @param maxRate The maximal interest rate paid on token's quotas
    function addQuotaToken(address token, uint16 minRate, uint16 maxRate)
        external
        override
        nonZeroAddress(token) // U:[GA-04]
        configuratorOnly // U:[GA-03]
    {
        if (isTokenAdded(token) || token == IPoolV3(pool).underlyingToken()) {
            revert TokenNotAllowedException(); // U:[GA-04]
        }
        _checkParams({minRate: minRate, maxRate: maxRate}); // U:[GA-04]

        quotaRateParams[token] =
            QuotaRateParams({minRate: minRate, maxRate: maxRate, totalVotesLpSide: 0, totalVotesCaSide: 0}); // U:[GA-05]

        IPoolQuotaKeeperV3 quotaKeeper = _poolQuotaKeeper();
        if (!quotaKeeper.isQuotedToken(token)) {
            quotaKeeper.addQuotaToken({token: token}); // U:[GA-05]
        }

        emit AddQuotaToken({token: token, minRate: minRate, maxRate: maxRate}); // U:[GA-05]
    }

    /// @dev Changes the min rate for a quoted token
    /// @param minRate The minimal interest rate paid on token's quotas
    function changeQuotaMinRate(address token, uint16 minRate)
        external
        override
        nonZeroAddress(token) // U: [GA-04]
        controllerOnly // U: [GA-03]
    {
        _changeQuotaTokenRateParams(token, minRate, quotaRateParams[token].maxRate);
    }

    /// @dev Changes the max rate for a quoted token
    /// @param maxRate The maximal interest rate paid on token's quotas
    function changeQuotaMaxRate(address token, uint16 maxRate)
        external
        override
        nonZeroAddress(token) // U: [GA-04]
        controllerOnly // U: [GA-03]
    {
        _changeQuotaTokenRateParams(token, quotaRateParams[token].minRate, maxRate);
    }

    /// @dev Implementation of `changeQuotaTokenRateParams`
    function _changeQuotaTokenRateParams(address token, uint16 minRate, uint16 maxRate) internal {
        if (!isTokenAdded(token)) revert TokenNotAllowedException(); // U:[GA-06A, GA-06B]

        _checkParams(minRate, maxRate); // U:[GA-04]

        QuotaRateParams storage qrp = quotaRateParams[token]; // U:[GA-06A, GA-06B]
        if (minRate == qrp.minRate && maxRate == qrp.maxRate) return;
        qrp.minRate = minRate; // U:[GA-06A, GA-06B]
        qrp.maxRate = maxRate; // U:[GA-06A, GA-06B]

        emit SetQuotaTokenParams({token: token, minRate: minRate, maxRate: maxRate}); // U:[GA-06A, GA-06B]
    }

    /// @dev Checks that given min and max rate are correct (`0 < minRate <= maxRate`)
    function _checkParams(uint16 minRate, uint16 maxRate) internal pure {
        if (minRate == 0 || minRate > maxRate) {
            revert IncorrectParameterException(); // U:[GA-04]
        }
    }

    /// @notice Whether token is added to the gauge as quoted
    function isTokenAdded(address token) public view override returns (bool) {
        return quotaRateParams[token].maxRate != 0; // U:[GA-08]
    }

    /// @dev Returns quota keeper connected to the pool
    function _poolQuotaKeeper() internal view returns (IPoolQuotaKeeperV3) {
        return IPoolQuotaKeeperV3(IPoolV3(pool).poolQuotaKeeper());
    }

    /// @dev Reverts if `msg.sender` is not voter
    function _revertIfCallerNotVoter() internal view {
        if (msg.sender != voter) {
            revert CallerNotVoterException(); // U:[GA-02]
        }
    }
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IVersion} from "@gearbox-protocol/core-v2/contracts/interfaces/IVersion.sol";

import {IVotingContractV3} from "./IVotingContractV3.sol";

struct QuotaRateParams {
    uint16 minRate;
    uint16 maxRate;
    uint96 totalVotesLpSide;
    uint96 totalVotesCaSide;
}

struct UserVotes {
    uint96 votesLpSide;
    uint96 votesCaSide;
}

interface IGaugeV3Events {
    /// @notice Emitted when epoch is updated
    event UpdateEpoch(uint16 epochNow);

    /// @notice Emitted when a user submits a vote
    event Vote(address indexed user, address indexed token, uint96 votes, bool lpSide);

    /// @notice Emitted when a user removes a vote
    event Unvote(address indexed user, address indexed token, uint96 votes, bool lpSide);

    /// @notice Emitted when a new quota token is added in the PoolQuotaKeeper
    event AddQuotaToken(address indexed token, uint16 minRate, uint16 maxRate);

    /// @notice Emitted when quota interest rate parameters are changed
    event SetQuotaTokenParams(address indexed token, uint16 minRate, uint16 maxRate);

    /// @notice Emitted when the frozen epoch status changes
    event SetFrozenEpoch(bool status);
}

/// @title Gauge V3 interface
interface IGaugeV3 is IGaugeV3Events, IVotingContractV3, IVersion {
    function pool() external view returns (address);

    function voter() external view returns (address);

    function updateEpoch() external;

    function epochLastUpdate() external view returns (uint16);

    function getRates(address[] calldata tokens) external view returns (uint16[] memory rates);

    function userTokenVotes(address user, address token)
        external
        view
        returns (uint96 votesLpSide, uint96 votesCaSide);

    function quotaRateParams(address token)
        external
        view
        returns (uint16 minRate, uint16 maxRate, uint96 totalVotesLpSide, uint96 totalVotesCaSide);

    // ------------- //
    // CONFIGURATION //
    // ------------- //

    function epochFrozen() external view returns (bool);

    function setFrozenEpoch(bool status) external;

    function isTokenAdded(address token) external view returns (bool);

    function addQuotaToken(address token, uint16 minRate, uint16 maxRate) external;

    function changeQuotaMinRate(address token, uint16 minRate) external;

    function changeQuotaMaxRate(address token, uint16 maxRate) external;
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IVersion} from "@gearbox-protocol/core-v2/contracts/interfaces/IVersion.sol";

uint256 constant EPOCH_LENGTH = 7 days;

uint256 constant EPOCHS_TO_WITHDRAW = 4;

/// @notice Voting contract status
///         * NOT_ALLOWED - cannot vote or unvote
///         * ALLOWED - can both vote and unvote
///         * UNVOTE_ONLY - can only unvote
enum VotingContractStatus {
    NOT_ALLOWED,
    ALLOWED,
    UNVOTE_ONLY
}

struct UserVoteLockData {
    uint96 totalStaked;
    uint96 available;
}

struct WithdrawalData {
    uint96[EPOCHS_TO_WITHDRAW] withdrawalsPerEpoch;
    uint16 epochLastUpdate;
}

/// @notice Multi vote
/// @param votingContract Contract to submit a vote to
/// @param voteAmount Amount of staked GEAR to vote with
/// @param isIncrease Whether to add or remove votes
/// @param extraData Data to pass to the voting contract
struct MultiVote {
    address votingContract;
    uint96 voteAmount;
    bool isIncrease;
    bytes extraData;
}

interface IGearStakingV3Events {
    /// @notice Emitted when the user deposits GEAR into staked GEAR
    event DepositGear(address indexed user, uint256 amount);

    /// @notice Emitted Emits when the user migrates GEAR into a successor contract
    event MigrateGear(address indexed user, address indexed successor, uint256 amount);

    /// @notice Emitted Emits when the user starts a withdrawal from staked GEAR
    event ScheduleGearWithdrawal(address indexed user, uint256 amount);

    /// @notice Emitted Emits when the user claims a mature withdrawal from staked GEAR
    event ClaimGearWithdrawal(address indexed user, address to, uint256 amount);

    /// @notice Emitted Emits when the configurator adds or removes a voting contract
    event SetVotingContractStatus(address indexed votingContract, VotingContractStatus status);

    /// @notice Emitted Emits when the new successor contract is set
    event SetSuccessor(address indexed successor);

    /// @notice Emitted Emits when the new migrator contract is set
    event SetMigrator(address indexed migrator);
}

/// @title Gear staking V3 interface
interface IGearStakingV3 is IGearStakingV3Events, IVersion {
    function gear() external view returns (address);

    function firstEpochTimestamp() external view returns (uint256);

    function getCurrentEpoch() external view returns (uint16);

    function balanceOf(address user) external view returns (uint256);

    function availableBalance(address user) external view returns (uint256);

    function getWithdrawableAmounts(address user)
        external
        view
        returns (uint256 withdrawableNow, uint256[EPOCHS_TO_WITHDRAW] memory withdrawableInEpochs);

    function deposit(uint96 amount, MultiVote[] calldata votes) external;

    function depositWithPermit(
        uint96 amount,
        MultiVote[] calldata votes,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function multivote(MultiVote[] calldata votes) external;

    function withdraw(uint96 amount, address to, MultiVote[] calldata votes) external;

    function claimWithdrawals(address to) external;

    function migrate(uint96 amount, MultiVote[] calldata votesBefore, MultiVote[] calldata votesAfter) external;

    function depositOnMigration(uint96 amount, address onBehalfOf, MultiVote[] calldata votes) external;

    // ------------- //
    // CONFIGURATION //
    // ------------- //

    function allowedVotingContract(address) external view returns (VotingContractStatus);

    function setVotingContractStatus(address votingContract, VotingContractStatus status) external;

    function successor() external view returns (address);

    function setSuccessor(address newSuccessor) external;

    function migrator() external view returns (address);

    function setMigrator(address newMigrator) external;
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IVersion} from "@gearbox-protocol/core-v2/contracts/interfaces/IVersion.sol";

struct TokenQuotaParams {
    uint16 rate;
    uint192 cumulativeIndexLU;
    uint16 quotaIncreaseFee;
    uint96 totalQuoted;
    uint96 limit;
}

struct AccountQuota {
    uint96 quota;
    uint192 cumulativeIndexLU;
}

interface IPoolQuotaKeeperV3Events {
    /// @notice Emitted when account's quota for a token is updated
    event UpdateQuota(address indexed creditAccount, address indexed token, int96 quotaChange);

    /// @notice Emitted when token's quota rate is updated
    event UpdateTokenQuotaRate(address indexed token, uint16 rate);

    /// @notice Emitted when the gauge is updated
    event SetGauge(address indexed newGauge);

    /// @notice Emitted when a new credit manager is allowed
    event AddCreditManager(address indexed creditManager);

    /// @notice Emitted when a new token is added as quoted
    event AddQuotaToken(address indexed token);

    /// @notice Emitted when a new total quota limit is set for a token
    event SetTokenLimit(address indexed token, uint96 limit);

    /// @notice Emitted when a new one-time quota increase fee is set for a token
    event SetQuotaIncreaseFee(address indexed token, uint16 fee);
}

/// @title Pool quota keeper V3 interface
interface IPoolQuotaKeeperV3 is IPoolQuotaKeeperV3Events, IVersion {
    function pool() external view returns (address);

    function underlying() external view returns (address);

    // ----------------- //
    // QUOTAS MANAGEMENT //
    // ----------------- //

    function updateQuota(address creditAccount, address token, int96 requestedChange, uint96 minQuota, uint96 maxQuota)
        external
        returns (uint128 caQuotaInterestChange, uint128 fees, bool enableToken, bool disableToken);

    function removeQuotas(address creditAccount, address[] calldata tokens, bool setLimitsToZero) external;

    function accrueQuotaInterest(address creditAccount, address[] calldata tokens) external;

    function getQuotaRate(address) external view returns (uint16);

    function cumulativeIndex(address token) external view returns (uint192);

    function isQuotedToken(address token) external view returns (bool);

    function getQuota(address creditAccount, address token)
        external
        view
        returns (uint96 quota, uint192 cumulativeIndexLU);

    function getTokenQuotaParams(address token)
        external
        view
        returns (
            uint16 rate,
            uint192 cumulativeIndexLU,
            uint16 quotaIncreaseFee,
            uint96 totalQuoted,
            uint96 limit,
            bool isActive
        );

    function getQuotaAndOutstandingInterest(address creditAccount, address token)
        external
        view
        returns (uint96 quoted, uint128 outstandingInterest);

    function poolQuotaRevenue() external view returns (uint256);

    function lastQuotaRateUpdate() external view returns (uint40);

    // ------------- //
    // CONFIGURATION //
    // ------------- //

    function gauge() external view returns (address);

    function setGauge(address _gauge) external;

    function creditManagers() external view returns (address[] memory);

    function addCreditManager(address _creditManager) external;

    function quotedTokens() external view returns (address[] memory);

    function addQuotaToken(address token) external;

    function updateRates() external;

    function setTokenLimit(address token, uint96 limit) external;

    function setTokenQuotaIncreaseFee(address token, uint16 fee) external;
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;
pragma abicoder v1;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IVersion} from "@gearbox-protocol/core-v2/contracts/interfaces/IVersion.sol";

interface IPoolV3Events {
    /// @notice Emitted when depositing liquidity with referral code
    event Refer(address indexed onBehalfOf, uint256 indexed referralCode, uint256 amount);

    /// @notice Emitted when credit account borrows funds from the pool
    event Borrow(address indexed creditManager, address indexed creditAccount, uint256 amount);

    /// @notice Emitted when credit account's debt is repaid to the pool
    event Repay(address indexed creditManager, uint256 borrowedAmount, uint256 profit, uint256 loss);

    /// @notice Emitted when incurred loss can't be fully covered by burning treasury's shares
    event IncurUncoveredLoss(address indexed creditManager, uint256 loss);

    /// @notice Emitted when new interest rate model contract is set
    event SetInterestRateModel(address indexed newInterestRateModel);

    /// @notice Emitted when new pool quota keeper contract is set
    event SetPoolQuotaKeeper(address indexed newPoolQuotaKeeper);

    /// @notice Emitted when new total debt limit is set
    event SetTotalDebtLimit(uint256 limit);

    /// @notice Emitted when new credit manager is connected to the pool
    event AddCreditManager(address indexed creditManager);

    /// @notice Emitted when new debt limit is set for a credit manager
    event SetCreditManagerDebtLimit(address indexed creditManager, uint256 newLimit);

    /// @notice Emitted when new withdrawal fee is set
    event SetWithdrawFee(uint256 fee);
}

/// @title Pool V3 interface
interface IPoolV3 is IVersion, IPoolV3Events, IERC4626, IERC20Permit {
    function addressProvider() external view returns (address);

    function underlyingToken() external view returns (address);

    function treasury() external view returns (address);

    function withdrawFee() external view returns (uint16);

    function creditManagers() external view returns (address[] memory);

    function availableLiquidity() external view returns (uint256);

    function expectedLiquidity() external view returns (uint256);

    function expectedLiquidityLU() external view returns (uint256);

    // ---------------- //
    // ERC-4626 LENDING //
    // ---------------- //

    function depositWithReferral(uint256 assets, address receiver, uint256 referralCode)
        external
        returns (uint256 shares);

    function mintWithReferral(uint256 shares, address receiver, uint256 referralCode)
        external
        returns (uint256 assets);

    // --------- //
    // BORROWING //
    // --------- //

    function totalBorrowed() external view returns (uint256);

    function totalDebtLimit() external view returns (uint256);

    function creditManagerBorrowed(address creditManager) external view returns (uint256);

    function creditManagerDebtLimit(address creditManager) external view returns (uint256);

    function creditManagerBorrowable(address creditManager) external view returns (uint256 borrowable);

    function lendCreditAccount(uint256 borrowedAmount, address creditAccount) external;

    function repayCreditAccount(uint256 repaidAmount, uint256 profit, uint256 loss) external;

    // ------------- //
    // INTEREST RATE //
    // ------------- //

    function interestRateModel() external view returns (address);

    function baseInterestRate() external view returns (uint256);

    function supplyRate() external view returns (uint256);

    function baseInterestIndex() external view returns (uint256);

    function baseInterestIndexLU() external view returns (uint256);

    function lastBaseInterestUpdate() external view returns (uint40);

    // ------ //
    // QUOTAS //
    // ------ //

    function poolQuotaKeeper() external view returns (address);

    function quotaRevenue() external view returns (uint256);

    function lastQuotaRevenueUpdate() external view returns (uint40);

    function updateQuotaRevenue(int256 quotaRevenueDelta) external;

    function setQuotaRevenue(uint256 newQuotaRevenue) external;

    // ------------- //
    // CONFIGURATION //
    // ------------- //

    function setInterestRateModel(address newInterestRateModel) external;

    function setPoolQuotaKeeper(address newPoolQuotaKeeper) external;

    function setTotalDebtLimit(uint256 newLimit) external;

    function setCreditManagerDebtLimit(address creditManager, uint256 newLimit) external;

    function setWithdrawFee(uint256 newWithdrawFee) external;
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

import {IACL} from "@gearbox-protocol/core-v2/contracts/interfaces/IACL.sol";
import {
    CallerNotControllerException,
    CallerNotPausableAdminException,
    CallerNotUnpausableAdminException
} from "../interfaces/IExceptions.sol";

import {ACLTrait} from "./ACLTrait.sol";
import {ReentrancyGuardTrait} from "./ReentrancyGuardTrait.sol";

/// @title ACL non-reentrant trait
/// @notice Extended version of `ACLTrait` that implements pausable functionality,
///         reentrancy protection and external controller role
abstract contract ACLNonReentrantTrait is ACLTrait, Pausable, ReentrancyGuardTrait {
    /// @notice Emitted when new external controller is set
    event NewController(address indexed newController);

    /// @notice External controller address
    address public controller;

    /// @dev Ensures that function caller is external controller or configurator
    modifier controllerOnly() {
        _ensureCallerIsControllerOrConfigurator();
        _;
    }

    /// @dev Reverts if the caller is not controller or configurator
    /// @dev Used to cut contract size on modifiers
    function _ensureCallerIsControllerOrConfigurator() internal view {
        if (msg.sender != controller && !_isConfigurator({account: msg.sender})) {
            revert CallerNotControllerException();
        }
    }

    /// @dev Ensures that function caller has pausable admin role
    modifier pausableAdminsOnly() {
        _ensureCallerIsPausableAdmin();
        _;
    }

    /// @dev Reverts if the caller is not pausable admin
    /// @dev Used to cut contract size on modifiers
    function _ensureCallerIsPausableAdmin() internal view {
        if (!_isPausableAdmin({account: msg.sender})) {
            revert CallerNotPausableAdminException();
        }
    }

    /// @dev Ensures that function caller has unpausable admin role
    modifier unpausableAdminsOnly() {
        _ensureCallerIsUnpausableAdmin();
        _;
    }

    /// @dev Reverts if the caller is not unpausable admin
    /// @dev Used to cut contract size on modifiers
    function _ensureCallerIsUnpausableAdmin() internal view {
        if (!_isUnpausableAdmin({account: msg.sender})) {
            revert CallerNotUnpausableAdminException();
        }
    }

    /// @notice Constructor
    /// @param addressProvider Address provider contract address
    constructor(address addressProvider) ACLTrait(addressProvider) {
        controller = IACL(acl).owner();
    }

    /// @notice Pauses contract, can only be called by an account with pausable admin role
    function pause() external virtual pausableAdminsOnly {
        _pause();
    }

    /// @notice Unpauses contract, can only be called by an account with unpausable admin role
    function unpause() external virtual unpausableAdminsOnly {
        _unpause();
    }

    /// @notice Sets new external controller, can only be called by configurator
    function setController(address newController) external configuratorOnly {
        if (controller == newController) return;
        controller = newController;
        emit NewController(newController);
    }

    /// @dev Checks whether given account has pausable admin role
    function _isPausableAdmin(address account) internal view returns (bool) {
        return IACL(acl).isPausableAdmin(account);
    }

    /// @dev Checks whether given account has unpausable admin role
    function _isUnpausableAdmin(address account) internal view returns (bool) {
        return IACL(acl).isUnpausableAdmin(account);
    }
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

// ------- //
// GENERAL //
// ------- //

/// @notice Thrown on attempting to set an important address to zero address
error ZeroAddressException();

/// @notice Thrown when attempting to pass a zero amount to a funding-related operation
error AmountCantBeZeroException();

/// @notice Thrown on incorrect input parameter
error IncorrectParameterException();

/// @notice Thrown when balance is insufficient to perform an operation
error InsufficientBalanceException();

/// @notice Thrown if parameter is out of range
error ValueOutOfRangeException();

/// @notice Thrown when trying to send ETH to a contract that is not allowed to receive ETH directly
error ReceiveIsNotAllowedException();

/// @notice Thrown on attempting to set an EOA as an important contract in the system
error AddressIsNotContractException(address);

/// @notice Thrown on attempting to receive a token that is not a collateral token or was forbidden
error TokenNotAllowedException();

/// @notice Thrown on attempting to add a token that is already in a collateral list
error TokenAlreadyAddedException();

/// @notice Thrown when attempting to use quota-related logic for a token that is not quoted in quota keeper
error TokenIsNotQuotedException();

/// @notice Thrown on attempting to interact with an address that is not a valid target contract
error TargetContractNotAllowedException();

/// @notice Thrown if function is not implemented
error NotImplementedException();

// ------------------ //
// CONTRACTS REGISTER //
// ------------------ //

/// @notice Thrown when an address is expected to be a registered credit manager, but is not
error RegisteredCreditManagerOnlyException();

/// @notice Thrown when an address is expected to be a registered pool, but is not
error RegisteredPoolOnlyException();

// ---------------- //
// ADDRESS PROVIDER //
// ---------------- //

/// @notice Reverts if address key isn't found in address provider
error AddressNotFoundException();

// ----------------- //
// POOL, PQK, GAUGES //
// ----------------- //

/// @notice Thrown by pool-adjacent contracts when a credit manager being connected has a wrong pool address
error IncompatibleCreditManagerException();

/// @notice Thrown when attempting to set an incompatible successor staking contract
error IncompatibleSuccessorException();

/// @notice Thrown when attempting to vote in a non-approved contract
error VotingContractNotAllowedException();

/// @notice Thrown when attempting to unvote more votes than there are
error InsufficientVotesException();

/// @notice Thrown when attempting to borrow more than the second point on a two-point curve
error BorrowingMoreThanU2ForbiddenException();

/// @notice Thrown when a credit manager attempts to borrow more than its limit in the current block, or in general
error CreditManagerCantBorrowException();

/// @notice Thrown when attempting to connect a quota keeper to an incompatible pool
error IncompatiblePoolQuotaKeeperException();

/// @notice Thrown when the quota is outside of min/max bounds
error QuotaIsOutOfBoundsException();

// -------------- //
// CREDIT MANAGER //
// -------------- //

/// @notice Thrown on failing a full collateral check after multicall
error NotEnoughCollateralException();

/// @notice Thrown if an attempt to approve a collateral token to adapter's target contract fails
error AllowanceFailedException();

/// @notice Thrown on attempting to perform an action for a credit account that does not exist
error CreditAccountDoesNotExistException();

/// @notice Thrown on configurator attempting to add more than 255 collateral tokens
error TooManyTokensException();

/// @notice Thrown if more than the maximum number of tokens were enabled on a credit account
error TooManyEnabledTokensException();

/// @notice Thrown when attempting to execute a protocol interaction without active credit account set
error ActiveCreditAccountNotSetException();

/// @notice Thrown when trying to update credit account's debt more than once in the same block
error DebtUpdatedTwiceInOneBlockException();

/// @notice Thrown when trying to repay all debt while having active quotas
error DebtToZeroWithActiveQuotasException();

/// @notice Thrown when a zero-debt account attempts to update quota
error UpdateQuotaOnZeroDebtAccountException();

/// @notice Thrown when attempting to close an account with non-zero debt
error CloseAccountWithNonZeroDebtException();

/// @notice Thrown when value of funds remaining on the account after liquidation is insufficient
error InsufficientRemainingFundsException();

/// @notice Thrown when Credit Facade tries to write over a non-zero active Credit Account
error ActiveCreditAccountOverridenException();

// ------------------- //
// CREDIT CONFIGURATOR //
// ------------------- //

/// @notice Thrown on attempting to use a non-ERC20 contract or an EOA as a token
error IncorrectTokenContractException();

/// @notice Thrown if the newly set LT if zero or greater than the underlying's LT
error IncorrectLiquidationThresholdException();

/// @notice Thrown if borrowing limits are incorrect: minLimit > maxLimit or maxLimit > blockLimit
error IncorrectLimitsException();

/// @notice Thrown if the new expiration date is less than the current expiration date or current timestamp
error IncorrectExpirationDateException();

/// @notice Thrown if a contract returns a wrong credit manager or reverts when trying to retrieve it
error IncompatibleContractException();

/// @notice Thrown if attempting to forbid an adapter that is not registered in the credit manager
error AdapterIsNotRegisteredException();

// ------------- //
// CREDIT FACADE //
// ------------- //

/// @notice Thrown when attempting to perform an action that is forbidden in whitelisted mode
error ForbiddenInWhitelistedModeException();

/// @notice Thrown if credit facade is not expirable, and attempted aciton requires expirability
error NotAllowedWhenNotExpirableException();

/// @notice Thrown if a selector that doesn't match any allowed function is passed to the credit facade in a multicall
error UnknownMethodException();

/// @notice Thrown when trying to close an account with enabled tokens
error CloseAccountWithEnabledTokensException();

/// @notice Thrown if a liquidator tries to liquidate an account with a health factor above 1
error CreditAccountNotLiquidatableException();

/// @notice Thrown if too much new debt was taken within a single block
error BorrowedBlockLimitException();

/// @notice Thrown if the new debt principal for a credit account falls outside of borrowing limits
error BorrowAmountOutOfLimitsException();

/// @notice Thrown if a user attempts to open an account via an expired credit facade
error NotAllowedAfterExpirationException();

/// @notice Thrown if expected balances are attempted to be set twice without performing a slippage check
error ExpectedBalancesAlreadySetException();

/// @notice Thrown if attempting to perform a slippage check when excepted balances are not set
error ExpectedBalancesNotSetException();

/// @notice Thrown if balance of at least one token is less than expected during a slippage check
error BalanceLessThanExpectedException();

/// @notice Thrown when trying to perform an action that is forbidden when credit account has enabled forbidden tokens
error ForbiddenTokensException();

/// @notice Thrown when new forbidden tokens are enabled during the multicall
error ForbiddenTokenEnabledException();

/// @notice Thrown when enabled forbidden token balance is increased during the multicall
error ForbiddenTokenBalanceIncreasedException();

/// @notice Thrown when the remaining token balance is increased during the liquidation
error RemainingTokenBalanceIncreasedException();

/// @notice Thrown if `botMulticall` is called by an address that is not approved by account owner or is forbidden
error NotApprovedBotException();

/// @notice Thrown when attempting to perform a multicall action with no permission for it
error NoPermissionException(uint256 permission);

/// @notice Thrown when attempting to give a bot unexpected permissions
error UnexpectedPermissionsException();

/// @notice Thrown when a custom HF parameter lower than 10000 is passed into the full collateral check
error CustomHealthFactorTooLowException();

/// @notice Thrown when submitted collateral hint is not a valid token mask
error InvalidCollateralHintException();

// ------ //
// ACCESS //
// ------ //

/// @notice Thrown on attempting to call an access restricted function not as credit account owner
error CallerNotCreditAccountOwnerException();

/// @notice Thrown on attempting to call an access restricted function not as configurator
error CallerNotConfiguratorException();

/// @notice Thrown on attempting to call an access-restructed function not as account factory
error CallerNotAccountFactoryException();

/// @notice Thrown on attempting to call an access restricted function not as credit manager
error CallerNotCreditManagerException();

/// @notice Thrown on attempting to call an access restricted function not as credit facade
error CallerNotCreditFacadeException();

/// @notice Thrown on attempting to call an access restricted function not as controller or configurator
error CallerNotControllerException();

/// @notice Thrown on attempting to pause a contract without pausable admin rights
error CallerNotPausableAdminException();

/// @notice Thrown on attempting to unpause a contract without unpausable admin rights
error CallerNotUnpausableAdminException();

/// @notice Thrown on attempting to call an access restricted function not as gauge
error CallerNotGaugeException();

/// @notice Thrown on attempting to call an access restricted function not as quota keeper
error CallerNotPoolQuotaKeeperException();

/// @notice Thrown on attempting to call an access restricted function not as voter
error CallerNotVoterException();

/// @notice Thrown on attempting to call an access restricted function not as allowed adapter
error CallerNotAdapterException();

/// @notice Thrown on attempting to call an access restricted function not as migrator
error CallerNotMigratorException();

/// @notice Thrown when an address that is not the designated executor attempts to execute a transaction
error CallerNotExecutorException();

/// @notice Thrown on attempting to call an access restricted function not as veto admin
error CallerNotVetoAdminException();

// ------------------- //
// CONTROLLER TIMELOCK //
// ------------------- //

/// @notice Thrown when the new parameter values do not satisfy required conditions
error ParameterChecksFailedException();

/// @notice Thrown when attempting to execute a non-queued transaction
error TxNotQueuedException();

/// @notice Thrown when attempting to execute a transaction that is either immature or stale
error TxExecutedOutsideTimeWindowException();

/// @notice Thrown when execution of a transaction fails
error TxExecutionRevertedException();

/// @notice Thrown when the value of a parameter on execution is different from the value on queue
error ParameterChangedAfterQueuedTxException();

// -------- //
// BOT LIST //
// -------- //

/// @notice Thrown when attempting to set non-zero permissions for a forbidden or special bot
error InvalidBotException();

// --------------- //
// ACCOUNT FACTORY //
// --------------- //

/// @notice Thrown when trying to deploy second master credit account for a credit manager
error MasterCreditAccountAlreadyDeployedException();

/// @notice Thrown when trying to rescue funds from a credit account that is currently in use
error CreditAccountIsInUseException();

// ------------ //
// PRICE ORACLE //
// ------------ //

/// @notice Thrown on attempting to set a token price feed to an address that is not a correct price feed
error IncorrectPriceFeedException();

/// @notice Thrown on attempting to interact with a price feed for a token not added to the price oracle
error PriceFeedDoesNotExistException();

/// @notice Thrown when price feed returns incorrect price for a token
error IncorrectPriceException();

/// @notice Thrown when token's price feed becomes stale
error StalePriceException();

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

/// @title Version interface
/// @notice Defines contract version
interface IVersion {
    /// @notice Contract version
    function version() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

interface IVotingContractV3 {
    function vote(address user, uint96 votes, bytes calldata extraData) external;
    function unvote(address user, uint96 votes, bytes calldata extraData) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";
import "../token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
 */
interface IERC4626 is IERC20, IERC20Metadata {
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;
import { IVersion } from "./IVersion.sol";

interface IACLExceptions {
    /// @dev Thrown when attempting to delete an address from a set that is not a pausable admin
    error AddressNotPausableAdminException(address addr);

    /// @dev Thrown when attempting to delete an address from a set that is not a unpausable admin
    error AddressNotUnpausableAdminException(address addr);
}

interface IACLEvents {
    /// @dev Emits when a new admin is added that can pause contracts
    event PausableAdminAdded(address indexed newAdmin);

    /// @dev Emits when a Pausable admin is removed
    event PausableAdminRemoved(address indexed admin);

    /// @dev Emits when a new admin is added that can unpause contracts
    event UnpausableAdminAdded(address indexed newAdmin);

    /// @dev Emits when an Unpausable admin is removed
    event UnpausableAdminRemoved(address indexed admin);
}

/// @title ACL interface
interface IACL is IACLEvents, IACLExceptions, IVersion {
    /// @dev Returns true if the address is a pausable admin and false if not
    /// @param addr Address to check
    function isPausableAdmin(address addr) external view returns (bool);

    /// @dev Returns true if the address is unpausable admin and false if not
    /// @param addr Address to check
    function isUnpausableAdmin(address addr) external view returns (bool);

    /// @dev Returns true if an address has configurator rights
    /// @param account Address to check
    function isConfigurator(address account) external view returns (bool);

    /// @dev Returns address of configurator
    function owner() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IACL} from "@gearbox-protocol/core-v2/contracts/interfaces/IACL.sol";

import {AP_ACL, IAddressProviderV3, NO_VERSION_CONTROL} from "../interfaces/IAddressProviderV3.sol";
import {CallerNotConfiguratorException} from "../interfaces/IExceptions.sol";

import {SanityCheckTrait} from "./SanityCheckTrait.sol";

/// @title ACL trait
/// @notice Utility class for ACL (access-control list) consumers
abstract contract ACLTrait is SanityCheckTrait {
    /// @notice ACL contract address
    address public immutable acl;

    /// @notice Constructor
    /// @param addressProvider Address provider contract address
    constructor(address addressProvider) nonZeroAddress(addressProvider) {
        acl = IAddressProviderV3(addressProvider).getAddressOrRevert(AP_ACL, NO_VERSION_CONTROL);
    }

    /// @dev Ensures that function caller has configurator role
    modifier configuratorOnly() {
        _ensureCallerIsConfigurator();
        _;
    }

    /// @dev Reverts if the caller is not the configurator
    /// @dev Used to cut contract size on modifiers
    function _ensureCallerIsConfigurator() internal view {
        if (!_isConfigurator({account: msg.sender})) {
            revert CallerNotConfiguratorException();
        }
    }

    /// @dev Checks whether given account has configurator role
    function _isConfigurator(address account) internal view returns (bool) {
        return IACL(acl).isConfigurator(account);
    }
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

uint8 constant NOT_ENTERED = 1;
uint8 constant ENTERED = 2;

/// @title Reentrancy guard trait
/// @notice Same as OpenZeppelin's `ReentrancyGuard` but only uses 1 byte of storage instead of 32
abstract contract ReentrancyGuardTrait {
    uint8 internal _reentrancyStatus = NOT_ENTERED;

    /// @dev Prevents a contract from calling itself, directly or indirectly.
    /// Calling a `nonReentrant` function from another `nonReentrant`
    /// function is not supported. It is possible to prevent this from happening
    /// by making the `nonReentrant` function external, and making it call a
    /// `private` function that does the actual work.
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        _ensureNotEntered();

        // Any calls to nonReentrant after this point will fail
        _reentrancyStatus = ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _reentrancyStatus = NOT_ENTERED;
    }

    /// @dev Reverts if the contract is currently entered
    /// @dev Used to cut contract size on modifiers
    function _ensureNotEntered() internal view {
        require(_reentrancyStatus != ENTERED, "ReentrancyGuard: reentrant call");
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IVersion} from "@gearbox-protocol/core-v2/contracts/interfaces/IVersion.sol";

uint256 constant NO_VERSION_CONTROL = 0;

bytes32 constant AP_CONTRACTS_REGISTER = "CONTRACTS_REGISTER";
bytes32 constant AP_ACL = "ACL";
bytes32 constant AP_PRICE_ORACLE = "PRICE_ORACLE";
bytes32 constant AP_ACCOUNT_FACTORY = "ACCOUNT_FACTORY";
bytes32 constant AP_DATA_COMPRESSOR = "DATA_COMPRESSOR";
bytes32 constant AP_TREASURY = "TREASURY";
bytes32 constant AP_GEAR_TOKEN = "GEAR_TOKEN";
bytes32 constant AP_WETH_TOKEN = "WETH_TOKEN";
bytes32 constant AP_WETH_GATEWAY = "WETH_GATEWAY";
bytes32 constant AP_ROUTER = "ROUTER";
bytes32 constant AP_BOT_LIST = "BOT_LIST";
bytes32 constant AP_GEAR_STAKING = "GEAR_STAKING";
bytes32 constant AP_ZAPPER_REGISTER = "ZAPPER_REGISTER";

interface IAddressProviderV3Events {
    /// @notice Emitted when an address is set for a contract key
    event SetAddress(bytes32 indexed key, address indexed value, uint256 indexed version);
}

/// @title Address provider V3 interface
interface IAddressProviderV3 is IAddressProviderV3Events, IVersion {
    function addresses(bytes32 key, uint256 _version) external view returns (address);

    function getAddressOrRevert(bytes32 key, uint256 _version) external view returns (address result);

    function setAddress(bytes32 key, address value, bool saveVersion) external;
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {ZeroAddressException} from "../interfaces/IExceptions.sol";

/// @title Sanity check trait
abstract contract SanityCheckTrait {
    /// @dev Ensures that passed address is non-zero
    modifier nonZeroAddress(address addr) {
        _revertIfZeroAddress(addr);
        _;
    }

    /// @dev Reverts if address is zero
    function _revertIfZeroAddress(address addr) private pure {
        if (addr == address(0)) revert ZeroAddressException();
    }
}