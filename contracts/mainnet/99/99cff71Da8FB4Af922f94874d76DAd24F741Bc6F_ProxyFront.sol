// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "../interface/ICoreBase.sol";
import "../interface/ILP.sol";
import "../interface/IProxyFront.sol";
import "../interface/IWNative.sol";
import "../libraries/SafeCast.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";

/**
 * @title  ProxyFront is a proxy contract designed to facilitate interaction with a Liquidity Pool contract.
 * @notice The contract provides functions for making bets and withdrawing payouts in batches.
 */
contract ProxyFront is IProxyFront {
    using SafeCast for *;

    receive() external payable {}

    /**
     * @notice An alternative version {ILP-withdrawLiquidity} that allows for deposit liquidity to the Liquidity Pool
     *         in the native currency of the network.
     * @notice To deposit the native currency, you need to send the deposit amount in {msg.value}.
     * @param  lp The address of the LP contract to use for withdrawal liquidity.
     */
    function addLiquidityNative(address lp) external payable {
        ILP lp_ = ILP(lp);
        address token = lp_.token();
        IWNative(token).deposit{value: msg.value}();

        TransferHelper.safeApprove(token, lp, msg.value);
        uint48 depositId = lp_.addLiquidity((msg.value).toUint128());
        lp_.transferFrom(address(this), msg.sender, depositId);
    }

    /**
     * @notice The batch version of {ILP-bet} with additional feature to pay for bet in the native currency of the
     *         network.
     * @notice To pay bets in the native currency, you need to send the total amount of bids in {msg.value}.
     * @param  lp The address of the LP contract to use for making bets.
     * @param  data An array of input data structures for making bets using the `bet` function of the specified LP.
     */
    function bet(address lp, BetData[] calldata data) external payable {
        uint256 totalAmount;
        for (uint256 i = 0; i < data.length; ++i) {
            totalAmount += data[i].amount;
        }

        ILP lp_ = ILP(lp);
        address token = lp_.token();
        if (msg.value > 0) {
            if (msg.value != totalAmount) revert IncorrectValue();
            IWNative(token).deposit{value: msg.value}();
        } else {
            TransferHelper.safeTransferFrom(
                token,
                msg.sender,
                address(this),
                totalAmount
            );
        }

        TransferHelper.safeApprove(token, lp, totalAmount);
        for (uint256 i = 0; i < data.length; ++i) {
            lp_.betFor(
                msg.sender,
                data[i].core,
                data[i].amount,
                data[i].expiresAt,
                data[i].extraData
            );
        }
    }

    /**
     * @notice An alternative version {ILP-withdrawLiquidity} that allows for withdrawal of liquidity in the
     *         native currency of the network.
     * @param  lp The address of the LP contract to use for withdrawal liquidity.
     * @param  depositId The ID of the liquidity deposit.
     * @param  percent The % of the liquidity to withdraw, where `FixedMath.ONE` represents 100% of the deposit.
     */
    function withdrawLiquidityNative(
        address lp,
        uint48 depositId,
        uint40 percent
    ) external payable {
        ILP lp_ = ILP(lp);
        lp_.transferFrom(msg.sender, address(this), depositId);

        uint256 withdrawnAmount = lp_.withdrawLiquidity(depositId, percent);
        _withdrawNative(lp_.token(), msg.sender, withdrawnAmount);

        if (lp_.isDepositExists(depositId))
            lp_.transferFrom(address(this), msg.sender, depositId);
    }

    /**
     * @notice The batch version of {ILP-withdrawPayout} with additional feature to withdraw payout in the native
     *         currency of the network.
     * @param  data An array of input data structures for withdrawing payouts using the `withdrawPayout` function.
     */
    function withdrawPayouts(WithdrawPayoutData[] calldata data) external {
        for (uint256 i = 0; i < data.length; ++i) {
            ICoreBase core = ICoreBase(data[i].core);
            ILP lp = core.lp();
            uint256 payout = lp.withdrawPayout(data[i].core, data[i].tokenId);
            if (data[i].isNative && payout > 0) {
                address account = core.azuroBet().ownerOf(data[i].tokenId);
                address token = lp.token();
                //slither-disable-next-line arbitrary-send-erc20
                TransferHelper.safeTransferFrom(
                    token,
                    account,
                    address(this),
                    payout
                );
                _withdrawNative(token, account, payout);
            }
        }
    }

    /**
     * @notice Unwraps the specified amount of wrapped native currency of the network represented as token and sends it
     *         to `to` address.
     */
    function _withdrawNative(
        address token,
        address to,
        uint256 amount
    ) internal {
        IWNative(token).withdraw(amount);
        TransferHelper.safeTransferETH(to, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "./IOwnable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

interface IAzuroBet is IOwnable, IERC721EnumerableUpgradeable {
    function initialize(address core) external;

    function burn(uint256 id) external;

    function mint(address account) external returns (uint256);

    error OnlyCore();
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

interface IBet {
    struct BetData {
        address affiliate; // address indicated as an affiliate when placing bet
        uint64 minOdds;
        bytes data; // core-specific customized bet data
    }

    error BetNotExists();
    error SmallOdds();

    /**
     * @notice Register new bet.
     * @param  bettor wallet for emitting bet token
     * @param  amount amount of tokens to bet
     * @param  betData customized bet data
     */
    function putBet(
        address bettor,
        uint128 amount,
        BetData calldata betData
    ) external returns (uint256 tokenId);

    function resolvePayout(address caller, uint256 tokenId)
        external
        returns (address account, uint128 payout);

    function viewPayout(uint256 tokenId) external view returns (uint128 payout);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

interface ICondition {
    enum ConditionState {
        CREATED,
        RESOLVED,
        CANCELED,
        PAUSED
    }

    struct Condition {
        uint256 gameId;
        uint128[] payouts;
        uint128[] virtualFunds;
        uint128 totalNetBets;
        uint128 reinforcement;
        uint128 fund;
        uint64 margin;
        uint64 endsAt;
        uint48 lastDepositId;
        uint8 winningOutcomesCount;
        ConditionState state;
        address oracle;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "./IBet.sol";
import "./ICondition.sol";
import "./ILP.sol";
import "./IOwnable.sol";
import "./IAzuroBet.sol";

interface ICoreBase is ICondition, IOwnable, IBet {
    struct Bet {
        uint256 conditionId;
        uint128 amount;
        uint128 payout;
        uint64 outcome;
        bool isPaid;
    }

    struct CoreBetData {
        uint256 conditionId; // The match or game ID
        uint64 outcomeId; // ID of predicted outcome
    }

    struct ConditionData {
        uint256 id; // The match or condition ID according to oracle's internal numbering
        uint256 gameId; // The game ID the condition belongs
        uint256[] odds; // Start odds for [team 1, ..., team N]
        uint64[] outcomes; // Unique outcomes for the condition [outcome 1, ..., outcome N]
        uint128 reinforcement; // Maximum amount of liquidity intended to condition reinforcement
        uint64 margin; // Bookmaker commission rate
        uint8 winningOutcomesCount; // The number of winning outcomes for the condition
        bytes[] data; // The additional data
    }

    event ConditionCreated(
        uint256 indexed gameId,
        uint256 indexed conditionId,
        bytes[] data
    );
    event ConditionResolved(
        uint256 indexed conditionId,
        uint8 state,
        uint64[] winningOutcomes,
        int128 lpProfit
    );
    event ConditionStopped(uint256 indexed conditionId, bool flag);

    event ReinforcementChanged(
        uint256 indexed conditionId,
        uint128 newReinforcement
    );
    event MarginChanged(uint256 indexed conditionId, uint64 newMargin);
    event OddsChanged(uint256 indexed conditionId, uint256[] newOdds);

    error OnlyLp();

    error AlreadyPaid();
    error DuplicateOutcomes(uint64 outcome);
    error IncorrectConditionId();
    error IncorrectMargin();
    error IncorrectReinforcement();
    error NothingChanged();
    error IncorrectTimestamp();
    error IncorrectWinningOutcomesCount();
    error IncorrectOutcomesCount();
    error NoPendingReward();
    error OnlyBetOwner();
    error OnlyOracle(address);
    error OutcomesAndOddsCountDiffer();
    error StartOutOfRange(uint256 pendingRewardsCount);
    error WrongOutcome();
    error ZeroOdds();

    error CantChangeFlag();
    error ConditionAlreadyCreated();
    error ConditionAlreadyResolved();
    error ConditionNotExists();
    error ConditionNotRunning();
    error GameAlreadyStarted();
    error InsufficientFund();
    error InsufficientVirtualFund();
    error ResolveTooEarly(uint64 waitTime);

    function lp() external view returns (ILP);

    function azuroBet() external view returns (IAzuroBet);

    function initialize(address azuroBet, address lp) external;

    function calcOdds(
        uint256 conditionId,
        uint128 amount,
        uint64 outcome
    ) external view returns (uint64 odds);

    /**
     * @notice Change the current condition `conditionId` margin.
     */
    function changeMargin(uint256 conditionId, uint64 newMargin) external;

    /**
     * @notice Change the current condition `conditionId` odds.
     */
    function changeOdds(uint256 conditionId, uint256[] calldata newOdds)
        external;

    /**
     * @notice Change the current condition `conditionId` reinforcement.
     */
    function changeReinforcement(uint256 conditionId, uint128 newReinforcement)
        external;

    function getCondition(uint256 conditionId)
        external
        view
        returns (Condition memory);

    /**
     * @notice Indicate the condition `conditionId` as canceled.
     * @notice The condition creator can always cancel it regardless of granted access tokens.
     */
    function cancelCondition(uint256 conditionId) external;

    /**
     * @notice Indicate the status of condition `conditionId` bet lock.
     * @param  conditionId the match or condition ID
     * @param  flag if stop receiving bets for the condition or not
     */
    function stopCondition(uint256 conditionId, bool flag) external;

    function createCondition(ConditionData calldata conditionData) external;

    function getOutcomeIndex(uint256 conditionId, uint64 outcome)
        external
        view
        returns (uint256);

    function isOutcomeWinning(uint256 conditionId, uint64 outcome)
        external
        view
        returns (bool);

    function isConditionCanceled(uint256 conditionId)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "./IBet.sol";
import "./IOwnable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

interface ILP is IOwnable, IERC721EnumerableUpgradeable {
    enum FeeType {
        DAO,
        DATA_PROVIDER
    }

    enum CoreState {
        UNKNOWN,
        ACTIVE,
        INACTIVE
    }

    struct Condition {
        address core;
        uint256 conditionId;
    }

    struct CoreData {
        CoreState state;
        uint64 reinforcementAbility;
        uint128 minBet;
        uint128 lockedLiquidity;
    }

    struct Game {
        uint128 lockedLiquidity;
        uint64 startsAt;
        bool canceled;
    }

    struct Reward {
        int128 amount;
        uint64 claimedAt;
    }

    event CoreSettingsUpdated(
        address indexed core,
        CoreState state,
        uint64 reinforcementAbility,
        uint128 minBet
    );

    event BettorWin(
        address indexed core,
        address indexed bettor,
        uint256 tokenId,
        uint256 amount
    );
    event ClaimTimeoutChanged(uint64 newClaimTimeout);
    event DataProviderChanged(address newDataProvider);
    event FeeChanged(FeeType feeType, uint64 fee);
    event GameCanceled(uint256 indexed gameId);
    event GameShifted(uint256 indexed gameId, uint64 newStart);
    event LiquidityAdded(
        address indexed account,
        uint48 indexed depositId,
        uint256 amount
    );
    event LiquidityDonated(
        address indexed account,
        uint48 indexed depositId,
        uint256 amount
    );
    event LiquidityManagerChanged(address newLiquidityManager);
    event LiquidityRemoved(
        address indexed account,
        uint48 indexed depositId,
        uint256 amount
    );
    event MinBetChanged(address core, uint128 newMinBet);
    event MinDepoChanged(uint128 newMinDepo);
    event NewGame(uint256 indexed gameId, bytes32 ipfsHash, uint64 startsAt);
    event ReinforcementAbilityChanged(uint128 newReinforcementAbility);
    event WithdrawTimeoutChanged(uint64 newWithdrawTimeout);

    error OnlyFactory();

    error SmallDepo();
    error SmallDonation();

    error BetExpired();
    error CoreNotActive();
    error ClaimTimeout(uint64 waitTime);
    error DepositDoesNotExist();
    error GameAlreadyCanceled();
    error GameAlreadyCreated();
    error GameCanceled_();
    error GameNotExists();
    error IncorrectCoreState();
    error IncorrectFee();
    error IncorrectGameId();
    error IncorrectMinBet();
    error IncorrectMinDepo();
    error IncorrectReinforcementAbility();
    error IncorrectTimestamp();
    error LiquidityNotOwned();
    error LiquidityIsLocked();
    error NoLiquidity();
    error NotEnoughLiquidity();
    error SmallBet();
    error UnknownCore();
    error WithdrawalTimeout(uint64 waitTime);

    function initialize(
        address access,
        address dataProvider,
        address token,
        uint128 minDepo,
        uint64 daoFee,
        uint64 dataProviderFee
    ) external;

    function addCore(address core) external;

    function addLiquidity(uint128 amount) external returns (uint48);

    function withdrawLiquidity(uint48 depositId, uint40 percent)
        external
        returns (uint128);

    function viewPayout(address core, uint256 tokenId)
        external
        view
        returns (uint128 payout);

    function betFor(
        address bettor,
        address core,
        uint128 amount,
        uint64 expiresAt,
        IBet.BetData calldata betData
    ) external returns (uint256 tokenId);

    /**
     * @notice Make new bet.
     * @notice Emits bet token to `msg.sender`.
     * @param  core address of the Core the bet is intended
     * @param  amount amount of tokens to bet
     * @param  expiresAt the time before which bet should be made
     * @param  betData customized bet data
     */
    function bet(
        address core,
        uint128 amount,
        uint64 expiresAt,
        IBet.BetData calldata betData
    ) external returns (uint256 tokenId);

    function changeDataProvider(address newDataProvider) external;

    function claimReward() external returns (uint128);

    function getReserve() external view returns (uint128);

    function addReserve(
        uint256 gameId,
        uint128 lockedReserve,
        uint128 profitReserve,
        uint48 depositId
    ) external;

    function addCondition(uint256 gameId) external view returns (uint64);

    function withdrawPayout(address core, uint256 tokenId)
        external
        returns (uint128);

    function changeLockedLiquidity(uint256 gameId, int128 deltaReserve)
        external;

    /**
     * @notice Indicate the game `gameId` as canceled.
     * @param  gameId the game ID
     */
    function cancelGame(uint256 gameId) external;

    /**
     * @notice Create new game.
     * @param  gameId the match or condition ID according to oracle's internal numbering
     * @param  ipfsHash hash of detailed info about the game stored in the IPFS
     * @param  startsAt timestamp when the game starts
     */
    function createGame(
        uint256 gameId,
        bytes32 ipfsHash,
        uint64 startsAt
    ) external;

    /**
     * @notice Set `startsAt` as new game `gameId` start time.
     * @param  gameId the game ID
     * @param  startsAt new timestamp when the game starts
     */
    function shiftGame(uint256 gameId, uint64 startsAt) external;

    function getGameInfo(uint256 gameId)
        external
        view
        returns (uint64 startsAt, bool canceled);

    function getLockedLiquidityLimit(address core)
        external
        view
        returns (uint128);

    function isGameCanceled(uint256 gameId)
        external
        view
        returns (bool canceled);

    function checkAccess(
        address account,
        address target,
        bytes4 selector
    ) external;

    function checkCore(address core) external view;

    function getLastDepositId() external view returns (uint48 depositId);

    function isDepositExists(uint256 depositId) external view returns (bool);

    function token() external view returns (address);

    function fees(uint256) external view returns (uint64);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

interface IOwnable {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function owner() external view returns (address);

    function checkOwner(address account) external view;

    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "./IBet.sol";

interface IProxyFront {
    struct BetData {
        address core;
        uint128 amount;
        uint64 expiresAt;
        IBet.BetData extraData;
    }

    struct WithdrawPayoutData {
        address core;
        uint256 tokenId;
        bool isNative;
    }

    error IncorrectValue();

    function bet(address lp, BetData[] calldata data) external payable;

    function withdrawPayouts(WithdrawPayoutData[] calldata data) external;
}

// SPDX-License-Identifier: GPL-3.0
/**
 * @dev interface for canonical wrapped native contract based on WETH9.sol
 */
pragma solidity ^0.8.9;

interface IWNative {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

library SafeCast {
    enum Type {
        BYTES32,
        INT128,
        UINT64,
        UINT128
    }
    error SafeCastError(Type to);

    function toBytes32(string calldata value) internal pure returns (bytes32) {
        bytes memory value_ = bytes(value);
        if (value_.length > 32) revert SafeCastError(Type.BYTES32);
        return bytes32(value_);
    }

    function toInt128(uint128 value) internal pure returns (int128) {
        if (value > uint128(type(int128).max))
            revert SafeCastError(Type.INT128);
        return int128(value);
    }

    function toUint64(uint256 value) internal pure returns (uint64) {
        if (value > type(uint64).max) revert SafeCastError(Type.UINT64);
        return uint64(value);
    }

    function toUint128(uint256 value) internal pure returns (uint128) {
        if (value > type(uint128).max) revert SafeCastError(Type.UINT128);
        return uint128(value);
    }
}