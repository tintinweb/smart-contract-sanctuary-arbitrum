// SPDX-License-Identifier: None
// Raffl Protocol (last updated v1.0.0) (Raffl.sol)
pragma solidity ^0.8.25;

import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import { TokenLib } from "./libraries/TokenLib.sol";
import { Errors } from "./libraries/RafflErrors.sol";

import { EntriesManager } from "./abstracts/EntriesManager.sol";

import { IRaffl } from "./interfaces/IRaffl.sol";
import { IFeeManager } from "./interfaces/IFeeManager.sol";

/*
                                                                       
  _____            ______ ______ _      
 |  __ \     /\   |  ____|  ____| |     
 | |__) |   /  \  | |__  | |__  | |     
 |  _  /   / /\ \ |  __| |  __| | |     
 | | \ \  / ____ \| |    | |    | |____ 
 |_|  \_\/_/    \_\_|    |_|    |______|                               
                                                                       
 */

/// @title Raffl
/// @author JA <@ubinatus>
/// @notice Raffl is a decentralized platform built on the Ethereum blockchain, allowing users to create and participate
/// in raffles/lotteries with complete transparency, security, and fairness.
contract Raffl is ReentrancyGuardUpgradeable, EntriesManager, IRaffl {
    /**
     *
     * STATE
     *
     */
    /// @dev Address of the RafflFactory
    address public factory;
    /// @dev User address that created the Raffl
    address public creator;
    /// @dev Prizes contained in the Raffl
    Prize[] public prizes;
    /// @dev Block timestamp for when the draw should be made and until entries are accepted
    uint256 public deadline;
    /// @dev Minimum number of entries required to execute the draw
    uint256 public minEntries;
    /// @dev Price of the entry to participate in the Raffl
    uint256 public entryPrice;
    /// @dev Address of the ERC20 entry token (if applicable)
    address public entryToken;
    /// @dev Array of token gates required for all participants to purchase entries.
    TokenGate[] public tokenGates;
    /// @dev Maps a user address to whether refund was made.
    mapping(address => bool) public userRefund;
    /// @dev Extra recipient to share the pooled funds.
    ExtraRecipient public extraRecipient;
    /// @dev Total pooled funds from entries acquisition
    uint256 public pool;
    /// @dev Whether the raffle is settled or not
    bool public settled;
    /// @dev Whether the prizes were refunded when criteria did not meet.
    bool public prizesRefunded;
    /// @dev Status of the Raffl game
    GameStatus public gameStatus;
    /// @dev Maximum number of entries a single address can hold.
    uint64 internal constant MAX_ENTRIES_PER_USER = 2 ** 64 - 1; // type(uint64).max
    /// @dev Maximum total of entries.
    uint256 internal constant MAX_TOTAL_ENTRIES = 2 ** 256 - 1; // type(uint256).max
    /// @dev Percentages and fees are calculated using 18 decimals where 1 ether is 100%.
    uint256 internal constant ONE = 1 ether;
    /// @notice The manager that deployed this contract which controls the values for `fee` and `feeCollector`.
    IFeeManager public manager;

    /**
     *
     * MODIFIERS
     *
     */
    modifier onlyFactory() {
        if (msg.sender != factory) revert Errors.OnlyFactoryAllowed();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     *
     * INITIALIZER
     *
     */
    //// @inheritdoc IRaffl
    function initialize(
        address _entryToken,
        uint256 _entryPrice,
        uint256 _minEntries,
        uint256 _deadline,
        address _creator,
        Prize[] calldata _prizes,
        TokenGate[] calldata _tokenGatesArray,
        ExtraRecipient calldata _extraRecipient
    )
        external
        override
        initializer
    {
        __ReentrancyGuard_init();

        entryToken = _entryToken;
        entryPrice = _entryPrice;
        minEntries = _minEntries;
        deadline = _deadline;
        creator = _creator;
        factory = msg.sender;
        manager = IFeeManager(msg.sender);

        uint256 i = 0;
        for (i; i < _prizes.length;) {
            prizes.push(_prizes[i]);

            unchecked {
                ++i;
            }
        }

        for (i = 0; i < _tokenGatesArray.length;) {
            tokenGates.push(_tokenGatesArray[i]);

            unchecked {
                ++i;
            }
        }

        extraRecipient = _extraRecipient;

        gameStatus = GameStatus.Initialized;

        emit RaffleInitialized();
    }

    /**
     *
     * METHODS
     *
     */

    /// @inheritdoc IRaffl
    function criteriaMet() external view override returns (bool) {
        return totalEntries() >= minEntries;
    }

    /// @inheritdoc IRaffl
    function deadlineExpired() external view override returns (bool) {
        return block.timestamp >= deadline;
    }

    /// @inheritdoc IRaffl
    function upkeepPerformed() external view override returns (bool) {
        return settled;
    }

    /// @notice Returns the current pool fee associated to this `Raffl`.
    function poolFeeData() external view returns (address, uint64) {
        return manager.poolFeeData(creator);
    }

    /// @notice Returns the current prizes associated to this `Raffl`.
    function getPrizes() external view returns (Prize[] memory) {
        return prizes;
    }

    /// @inheritdoc IRaffl
    function buyEntries(uint256 quantity) external payable override nonReentrant {
        if (block.timestamp > deadline) revert Errors.EntriesPurchaseClosed();
        if (totalEntries() >= MAX_TOTAL_ENTRIES) revert Errors.MaxTotalEntriesReached();

        _ensureTokenGating(msg.sender);

        if (entryPrice > 0) {
            _purchaseEntry(quantity);
        } else {
            _purchaseFreeEntry();
        }
    }

    /// @inheritdoc IRaffl
    function refundEntries(address user) external override nonReentrant {
        if (gameStatus != GameStatus.FailedDraw) revert Errors.RefundsOnlyAllowedOnFailedDraw();

        uint256 userEntries = balanceOf(user);
        if (userEntries == 0) revert Errors.UserWithoutEntries();
        if (entryPrice == 0) revert Errors.WithoutRefunds();
        if (userRefund[user]) revert Errors.UserAlreadyRefunded();

        userRefund[user] = true;

        uint256 value = entryPrice * userEntries;
        if (entryToken != address(0)) {
            TokenLib.safeTransfer(entryToken, user, value);
        } else {
            payable(user).transfer(value);
        }
        emit EntriesRefunded(user, userEntries, value);
    }

    /// @inheritdoc IRaffl
    function refundPrizes() external override nonReentrant {
        if (gameStatus != GameStatus.FailedDraw) revert Errors.RefundsOnlyAllowedOnFailedDraw();
        if (creator != msg.sender) revert Errors.OnlyCreatorAllowed();
        if (prizesRefunded) revert Errors.PrizesAlreadyRefunded();

        prizesRefunded = true;
        _transferPrizes(creator);
        emit PrizesRefunded();
    }

    /**
     *
     * HELPERS
     *
     */

    /// @dev Transfers the prizes to the specified user.
    /// @param user The address of the user who will receive the prizes.
    function _transferPrizes(address user) private {
        uint256 i = prizes.length;
        for (i; i != 0;) {
            unchecked {
                --i;
            }
            uint256 val = prizes[i].value;
            address asset = prizes[i].asset;
            if (prizes[i].assetType == AssetType.ERC20) {
                TokenLib.safeTransfer(asset, user, val);
            } else {
                TokenLib.safeTransferFrom(asset, address(this), user, val);
            }
        }
    }

    /// @dev Transfers the pool balance to the creator of the raffle, after deducting any fees.
    function _transferPool() private {
        uint256 balance =
            (entryToken != address(0)) ? TokenLib.balanceOf(entryToken, address(this)) : address(this).balance;

        if (balance > 0) {
            // Get feeData
            (address feeCollector, uint64 poolFeePercentage) = manager.poolFeeData(creator);
            uint256 fee = 0;

            // If fee is present, calculate it once and subtract from balance
            if (poolFeePercentage != 0) {
                fee = (balance * poolFeePercentage) / ONE;
                balance -= fee;
            }

            // Similar for extraRecipient.sharePercentage
            uint256 extraRecipientAmount = 0;
            if (extraRecipient.recipient != address(0) && extraRecipient.sharePercentage > 0) {
                extraRecipientAmount = (balance * extraRecipient.sharePercentage) / ONE;
                balance -= extraRecipientAmount;
            }

            if (entryToken != address(0)) {
                // Avoid checking the balance > 0 before each transfer
                if (fee > 0) {
                    TokenLib.safeTransfer(entryToken, feeCollector, fee);
                }
                if (extraRecipientAmount > 0) {
                    TokenLib.safeTransfer(entryToken, extraRecipient.recipient, extraRecipientAmount);
                }
                if (balance > 0) {
                    TokenLib.safeTransfer(entryToken, creator, balance);
                }
            } else {
                if (fee > 0) {
                    payable(feeCollector).transfer(fee);
                }
                if (extraRecipientAmount > 0) {
                    payable(extraRecipient.recipient).transfer(extraRecipientAmount);
                }
                if (balance > 0) {
                    payable(creator).transfer(balance);
                }
            }
        }
    }

    /// @dev Internal function to handle the purchase of entries with entry price greater than 0.
    /// @param quantity The quantity of entries to purchase.
    function _purchaseEntry(uint256 quantity) private {
        if (quantity == 0) revert Errors.EntryQuantityRequired();
        if (balanceOf(msg.sender) >= MAX_ENTRIES_PER_USER) revert Errors.MaxUserEntriesReached();
        uint256 value = quantity * entryPrice;
        // Check if entryToken is a non-zero address, meaning ERC-20 is used for purchase
        if (entryToken != address(0)) {
            // Transfer the required amount of entryToken from user to contract
            // Assumes that the ERC-20 token follows the ERC-20 standard
            TokenLib.safeTransferFrom(entryToken, msg.sender, address(this), value);
        } else {
            // Check that the correct amount of Ether is sent
            if (msg.value != value) revert Errors.EntriesPurchaseInvalidValue();
        }

        // Increments the pool value
        pool += value;

        // Mints entries for the user
        _mint(msg.sender, quantity);

        // Emits the `EntriesBought` event
        emit EntriesBought(msg.sender, quantity, value);
    }

    /// @dev Internal function to handle the purchase of free entries with entry price equal to 0.
    function _purchaseFreeEntry() private {
        // Allow up to one free entry per user
        if (balanceOf(msg.sender) == 1) revert Errors.MaxUserEntriesReached();

        // Mints a single entry for the user
        _mint(msg.sender, 1);

        // Emits the `EntriesBought` event with zero `value`
        emit EntriesBought(msg.sender, 1, 0);
    }

    /// @notice Ensures that the user has all the requirements from the `tokenGates` array
    /// @param user Address of the user
    function _ensureTokenGating(address user) private view {
        uint256 i = tokenGates.length;
        for (i; i != 0;) {
            unchecked {
                --i;
            }

            address token = tokenGates[i].token;
            uint256 amount = tokenGates[i].amount;

            // Extract the returned balance value
            uint256 balance = TokenLib.balanceOf(token, user);

            // Check if the balance meets the requirement
            if (balance < amount) {
                revert Errors.TokenGateRestriction();
            }
        }
    }

    /**
     *
     * FACTORY METHODS
     *
     */

    /// @inheritdoc IRaffl
    function setSuccessCriteria(uint256 requestId) external override onlyFactory {
        gameStatus = GameStatus.DrawStarted;
        emit DeadlineSuccessCriteria(requestId, totalEntries(), minEntries);
        settled = true;
    }

    /// @inheritdoc IRaffl
    function setFailedCriteria() external override onlyFactory {
        gameStatus = GameStatus.FailedDraw;
        emit DeadlineFailedCriteria(totalEntries(), minEntries);
        settled = true;
    }

    /// @inheritdoc IRaffl
    function disperseRewards(uint256 requestId, uint256 randomNumber) external override onlyFactory nonReentrant {
        uint256 totalEntries_ = totalEntries();
        uint256 winnerEntry = randomNumber % totalEntries_;
        address winnerUser = ownerOf(winnerEntry);

        _transferPrizes(winnerUser);
        _transferPool();

        gameStatus = GameStatus.SuccessDraw;

        emit DrawSuccess(requestId, winnerEntry, winnerUser, totalEntries_);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;
import {Initializable} from "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    /// @custom:storage-location erc7201:openzeppelin.storage.ReentrancyGuard
    struct ReentrancyGuardStorage {
        uint256 _status;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.ReentrancyGuard")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ReentrancyGuardStorageLocation = 0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00;

    function _getReentrancyGuardStorage() private pure returns (ReentrancyGuardStorage storage $) {
        assembly {
            $.slot := ReentrancyGuardStorageLocation
        }
    }

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
        $._status = NOT_ENTERED;
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
        ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if ($._status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        $._status = ENTERED;
    }

    function _nonReentrantAfter() private {
        ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        $._status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
        return $._status == ENTERED;
    }
}

// SPDX-License-Identifier: None
// Raffl Protocol (last updated v1.0.0) (libraries/TokenLib.sol)
pragma solidity ^0.8.25;

import { IERC20Minimal } from "../interfaces/IERC20Minimal.sol";

/// @title TokenLib
/// @dev Library the contains helper methods for retrieving balances and transfering ERC-20 and ERC-721
library TokenLib {
    /// @notice Retrieves the balance of a specified token for a given user
    /// @dev This function calls the `balanceOf` function on the token contract using the provided selector and decodes
    /// the returned data to retrieve the balance
    /// @param token The address of the token contract
    /// @param user The address of the user to query
    /// @return The balance of tokens held by the user
    function balanceOf(address token, address user) internal view returns (uint256) {
        (bool success, bytes memory data) =
            token.staticcall(abi.encodeWithSelector(IERC20Minimal.balanceOf.selector, user));
        // Throws an error with revert message "BF" if the staticcall fails or the returned data is less than 32 bytes
        require(success && data.length >= 32, "BF");
        return abi.decode(data, (uint256));
    }

    /// @notice Safely transfers tokens from the calling contract to a recipient
    /// @dev Calls the `transfer` function on the specified token contract and checks for successful transfer
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The amount of tokens to be transferred
    function safeTransfer(address token, address to, uint256 value) internal {
        // Encode the function signature and arguments for the `transfer` function
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20Minimal.transfer.selector, to, value));
        // Check if the `transfer` function call was successful and no error data was returned
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TF");
    }

    /// @notice Safely transfers tokens from one address to another using the `transferFrom` function
    /// @dev Calls the `transferFrom` function on the specified token contract and checks for successful transfer
    /// @param token The contract address of the token which will be transferred
    /// @param from The source address from which tokens will be transferred
    /// @param to The recipient address to which tokens will be transferred
    /// @param value The amount of tokens to be transferred
    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        // Encode the function signature and arguments for the `transferFrom` function
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20Minimal.transferFrom.selector, from, to, value));
        // Check if the `transferFrom` function call was successful and no error data was returned
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TFF");
    }
}

// SPDX-License-Identifier: None
// Raffl Protocol (last updated v1.0.0) (libraries/RafflErrors.sol)
pragma solidity ^0.8.25;

/// @title Errors Library for Raffl.sol
library Errors {
    /// @notice Thrown if anyone other than the factory tries to interact.
    error OnlyFactoryAllowed();

    /// @notice Thrown if anyone other than the creator tries to interact.
    error OnlyCreatorAllowed();

    /// @notice Thrown if no entry quantity is provided.
    error EntryQuantityRequired();

    /// @notice Thrown if the entries purchase period is closed.
    error EntriesPurchaseClosed();

    /// @notice Thrown if invalid value provided for entries purchase.
    error EntriesPurchaseInvalidValue();

    /// @notice Thrown if refunds are initiated before draw failure.
    error RefundsOnlyAllowedOnFailedDraw();

    /// @notice Thrown if a user without entries tries to claim.
    error UserWithoutEntries();

    /// @notice Thrown if a user was already refunded entries.
    error UserAlreadyRefunded();

    /// @notice Thrown if prizes are already refunded.
    error PrizesAlreadyRefunded();

    /// @notice Thrown if the maximum entries limit per user has been reached.
    error MaxUserEntriesReached();

    /// @notice Thrown if the total maximum entries limit has been reached.
    error MaxTotalEntriesReached();

    /// @notice Thrown if the refund operation is initiated without any refunds.
    error WithoutRefunds();

    /// @notice Thrown if token gate restriction is violated.
    error TokenGateRestriction();
}

// SPDX-License-Identifier: None
// Raffl Protocol (last updated v1.0.0) (abstracts/EntriesManager.sol)
pragma solidity ^0.8.25;

/**
 * @title EntriesManager
 * @notice Manager contract that handles the acquisition of `Raffl` entries.
 * @dev This is an extract of @cygaar_dev and @vectorized.eth [ERC721A](https://erc721a.org) contract in order to manage
 * efficient minting of entries.
 *
 * Assumptions:
 *
 * - An owner cannot mint more than 2**64 - 1 (type(uint64).max).
 * - The maximum entry ID cannot exceed 2**256 - 1 (type(uint256).max).
 */
abstract contract EntriesManager {
    // =============================================================
    //                            CUSTOM ERRORS
    // =============================================================

    /// @notice Cannot query the balance for the zero address.
    error BalanceQueryForZeroAddress();

    /// @notice The entry does not exist.
    error OwnerQueryForNonexistentEntry();

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    /// @dev Mask of an entry in packed address data.
    uint256 private constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    /// @dev The bit position of `numberMinted` in packed address data.
    uint256 private constant _BITPOS_NUMBER_MINTED = 64;

    /// @dev The mask of the lower 160 bits for addresses.
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    // =============================================================
    //                            STORAGE
    // =============================================================

    /// @dev The next entry ID to be minted.
    uint256 private _currentIndex;

    // Mapping from entry ID to ownership details
    // An empty struct value does not necessarily mean the entry is unowned.
    // See {_packedOwnershipOf} implementation for details.
    //
    // Bits Layout:
    // - [0..159]   `addr`
    mapping(uint256 => uint256) private _packedOwnerships;

    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..63]    `balance`
    mapping(address => uint256) private _packedAddressData;

    // =============================================================
    //                   READ OPERATIONS
    // =============================================================

    /// @dev Returns the total amount of entries minted in the contract.
    function totalEntries() public view virtual returns (uint256 result) {
        unchecked {
            result = _currentIndex;
        }
    }

    /// @dev Returns the number of entries in `owner`'s account.
    function balanceOf(address owner) public view virtual returns (uint256) {
        if (owner == address(0)) _revert(BalanceQueryForZeroAddress.selector);
        return _packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * @dev Returns the owner of the `entryId`.
     *
     * Requirements:
     *
     * - `entryId` must exist.
     */
    function ownerOf(uint256 entryId) public view virtual returns (address) {
        return address(uint160(_packedOwnershipOf(entryId)));
    }

    // =============================================================
    //                     PRIVATE HELPERS
    // =============================================================

    /// @dev Returns the packed ownership data of `entryId`.
    function _packedOwnershipOf(uint256 entryId) private view returns (uint256 packed) {
        packed = _packedOwnerships[entryId];

        // If the data at the starting slot does not exist, start the scan.
        if (packed == 0) {
            if (entryId >= _currentIndex) _revert(OwnerQueryForNonexistentEntry.selector);
            // Invariant:
            // There will always be an initialized ownership slot
            // (i.e. `ownership.addr != address(0)`)
            // before an unintialized ownership slot
            // (i.e. `ownership.addr == address(0)`)
            // Hence, `entryId` will not underflow.
            //
            // We can directly compare the packed value.
            // If the address is zero, packed will be zero.
            for (;;) {
                unchecked {
                    packed = _packedOwnerships[--entryId];
                }
                if (packed == 0) continue;

                return packed;
            }
        }
        // Otherwise, the data exists and we can skip the scan.
        return packed;
    }

    /// @dev Packs ownership data into a single uint256.
    function _packOwnershipData(address owner) private pure returns (uint256 result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            result := and(owner, _BITMASK_ADDRESS)
        }
    }

    // =============================================================
    //                        MINT OPERATIONS
    // =============================================================

    /**
     * @dev Mints `quantity` entries and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     */
    function _mint(address to, uint256 quantity) internal virtual {
        uint256 startEntryId = _currentIndex;

        // Overflows are incredibly unrealistic.
        // `balance` and `numberMinted` have a maximum limit of 2**64.
        // `entryId` has a maximum limit of 2**256.
        unchecked {
            // Update `address` to the owner.
            _packedOwnerships[startEntryId] = _packOwnershipData(to);

            // Directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            _currentIndex = startEntryId + quantity;
        }
    }

    /// @dev For more efficient reverts.
    function _revert(bytes4 errorSelector) internal pure {
        assembly {
            mstore(0x00, errorSelector)
            revert(0x00, 0x04)
        }
    }
}

// SPDX-License-Identifier: None
// Raffl Protocol (last updated v1.0.0) (interfaces/IRaffl.sol)
pragma solidity ^0.8.25;

/// @dev Interface that describes the Prize struct, the GameStatus and initialize function so the `RafflFactory` knows
/// how to initialize the `Raffl`.
/// @title IRaffl
interface IRaffl {
    /// @dev Asset type describe the kind of token behind the prize tok describes how the periods between release
    /// tokens.
    enum AssetType {
        ERC20,
        ERC721
    }

    /// @dev `asset` represents the address of the asset considered as a prize
    /// @dev `assetType` defines the type of asset
    /// @dev `value` represents the value of the prize. If asset is an ERC20, it's the amount. If asset is an ERC721,
    /// it's the tokenId.
    struct Prize {
        address asset;
        AssetType assetType;
        uint256 value;
    }

    /// @dev `token` represents the address of the token gating asset
    /// @dev `amount` represents the minimum value of the token gating
    struct TokenGate {
        address token;
        uint256 amount;
    }

    /// @dev `recipient` represents the address of the extra recipient of the pooled funds
    /// @dev `feePercentage` is the percentage of the pooled funds (after fees) that will be shared to the extra
    /// recipient
    struct ExtraRecipient {
        address recipient;
        uint64 sharePercentage;
    }

    /**
     * @dev GameStatus defines the possible states of the game
     * (0) Initialized: Raffle is initialized and ready to receive entries until the deadline
     * (1) FailedDraw: Raffle deadline was hit by the Chailink Upkeep but minimum entries were not met
     * (2) DrawStarted: Raffle deadline was hit by the Chainlink Upkeep and it's waiting for the Chainlink VRF
     *  with the lucky winner
     * (3) SuccessDraw: Raffle received the provably fair and verifiable random lucky winner and distributed rewards.
     */
    enum GameStatus {
        Initialized,
        FailedDraw,
        DrawStarted,
        SuccessDraw
    }

    /// @notice Emit when a new raffle is initialized.
    event RaffleInitialized();

    /// @notice Emit when a user buys entries.
    /// @param user The address of the user who purchased the entries.
    /// @param entriesBought The number of entries bought.
    /// @param value The value of the entries bought.
    event EntriesBought(address indexed user, uint256 entriesBought, uint256 value);

    /// @notice Emit when a user gets refunded for their entries.
    /// @param user The address of the user who got the refund.
    /// @param entriesRefunded The number of entries refunded.
    /// @param value The value of the entries refunded.
    event EntriesRefunded(address indexed user, uint256 entriesRefunded, uint256 value);

    /// @notice Emit when prizes are refunded.
    event PrizesRefunded();

    /// @notice Emit when a draw is successful.
    /// @param requestId The indexed ID of the draw request.
    /// @param winnerEntry The entry that won the draw.
    /// @param user The address of the winner.
    /// @param entries The entries the winner had.
    event DrawSuccess(uint256 indexed requestId, uint256 winnerEntry, address user, uint256 entries);

    /// @notice Emit when the criteria for deadline success is met.
    /// @param requestId The indexed ID of the deadline request.
    /// @param entries The number of entries at the time of the deadline.
    /// @param minEntries The minimum number of entries required for success.
    event DeadlineSuccessCriteria(uint256 indexed requestId, uint256 entries, uint256 minEntries);

    /// @notice Emit when the criteria for deadline failure is met.
    /// @param entries The number of entries at the time of the deadline.
    /// @param minEntries The minimum number of entries required for success.
    event DeadlineFailedCriteria(uint256 entries, uint256 minEntries);

    /// @notice Emit when changes are made to token-gating parameters.
    event TokenGatingChanges();

    /**
     * @notice Initializes the contract by setting up the raffle variables and the
     * `prices` information.
     *
     * @param entryToken        The address of the ERC-20 token as entry. If address zero, entry is the network token
     * @param entryPrice        The value of each entry for the raffle.
     * @param minEntries        The minimum number of entries to consider make the draw.
     * @param deadline          The block timestamp until the raffle will receive entries
     *                          and that will perform the draw if criteria is met.
     * @param creator           The address of the raffle creator
     * @param prizes            The prizes that will be held by this contract.
     * @param tokenGates        The token gating that will be imposed to users.
     * @param extraRecipient    The extra recipient that will share the rewards (optional).
     */
    function initialize(
        address entryToken,
        uint256 entryPrice,
        uint256 minEntries,
        uint256 deadline,
        address creator,
        Prize[] calldata prizes,
        TokenGate[] calldata tokenGates,
        ExtraRecipient calldata extraRecipient
    )
        external;

    /// @notice Checks if the raffle has met the minimum entries
    function criteriaMet() external view returns (bool);

    /// @notice Checks if the deadline has passed
    function deadlineExpired() external view returns (bool);

    /// @notice Checks if raffle already perfomed the upkeep
    function upkeepPerformed() external view returns (bool);

    /// @notice Sets the criteria as settled, sets the `GameStatus` as `DrawStarted` and emits event
    /// `DeadlineSuccessCriteria`
    /// @dev Access control: `factory` is the only allowed to called this method
    function setSuccessCriteria(uint256 requestId) external;

    /// @notice Sets the criteria as settled, sets the `GameStatus` as `FailedDraw` and emits event
    /// `DeadlineFailedCriteria`
    /// @dev Access control: `factory` is the only allowed to called this method
    function setFailedCriteria() external;

    /**
     * @notice Purchase entries for the raffle.
     * @dev Handles the acquisition of entries for three scenarios:
     * i) Entry is paid with network tokens,
     * ii) Entry is paid with ERC-20 tokens,
     * iii) Entry is free (allows up to 1 entry per user)
     * @param quantity The quantity of entries to purchase.
     *
     * Requirements:
     * - If entry is paid with network tokens, the required amount of network tokens.
     * - If entry is paid with ERC-20, the contract must be approved to spend ERC-20 tokens.
     * - If entry is free, no payment is required.
     *
     * Emits `EntriesBought` event
     */
    function buyEntries(uint256 quantity) external payable;

    /// @notice Refund entries for a specific user.
    /// @dev Invokable when the draw was not made because the min entries were not enought
    /// @dev This method is not available if the `entryPrice` was zero
    /// @param user The address of the user whose entries will be refunded.
    function refundEntries(address user) external;

    /// @notice Refund prizes to the creator.
    /// @dev Invokable when the draw was not made because the min entries were not enought
    function refundPrizes() external;

    /// @notice Transfers the `prizes` to the provably fair and verifiable entrant, sets the `GameStatus` as
    /// `SuccessDraw` and emits event `DrawSuccess`
    /// @dev Access control: `factory` is the only allowed to called this method through the Chainlink VRF Coordinator
    function disperseRewards(uint256 requestId, uint256 randomNumber) external;
}

// SPDX-License-Identifier: None
// Raffl Protocol (last updated v1.0.0) (interfaces/IFeeManager.sol)
pragma solidity ^0.8.25;

/// @title IFeeManager
/// @dev Interface that describes the struct and accessor function for the data related to the collection of fees.
interface IFeeManager {
    /// @dev The `FeeData` struct is used to store fee configurations such as the collection address and fee amounts for
    /// various transaction types in the contract.
    struct FeeData {
        /// @notice The address designated to collect fees.
        /// @dev This address is responsible for receiving fees generated from various sources.
        address feeCollector;
        /// @notice The fixed fee amount required to be sent as value with each `createRaffle` operation.
        /// @dev `creationFee` is denominated in the smallest unit of the token. It must be sent as the transaction
        /// value during the execution of the payable `createRaffle` function.
        uint64 creationFee;
        /// @notice The transfer fee expressed in ether, where 0.01 ether corresponds to a 1% fee.
        /// @dev `poolFeePercentage` is not in basis points but in ether units, with each ether unit representing a
        /// percentage that will be collected from the pool on success draws.
        uint64 poolFeePercentage;
    }

    /// @dev Stores global fee data upcoming change and timestamp for that change.
    struct UpcomingFeeData {
        /// @notice The new fee value in wei to be applied at `valueChangeAt`.
        uint64 nextValue;
        /// @notice Timestamp at which a new fee value becomes effective.
        uint64 valueChangeAt;
    }

    /// @dev Stores custom fee data, including its current state, upcoming changes, and the timestamps for those
    /// changes.
    struct CustomFeeData {
        /// @notice Indicates if the custom fee is currently enabled.
        bool isEnabled;
        /// @notice The current fee value in wei.
        uint64 value;
        /// @notice The new fee value in wei to be applied at `valueChangeAt`.
        uint64 nextValue;
        /// @notice Timestamp at which a new fee value becomes effective.
        uint64 valueChangeAt;
        /// @notice Indicates the future state of `isEnabled` after `statusChangeAt`.
        bool nextEnableState;
        /// @notice Timestamp at which the change to `isEnabled` becomes effective.
        uint64 statusChangeAt;
    }

    /// @notice Exposes the creation fee for new `Raffl`s deployments.
    /// @param raffle Address of the `Raffl`.
    /// @dev Enabled custom fees overrides the global creation fee.
    function creationFeeData(address raffle) external view returns (address feeCollector, uint64 creationFeeValue);

    /// @notice Exposes the fee that will be collected from the pool on success draws for `Raffl`s.
    /// @param raffle Address of the `Raffl`.
    /// @dev Enabled custom fees overrides the global transfer fee.
    function poolFeeData(address raffle) external view returns (address feeCollector, uint64 poolFeePercentage);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.20;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Storage of the initializable contract.
     *
     * It's implemented on a custom ERC-7201 namespace to reduce the risk of storage collisions
     * when using with upgradeable contracts.
     *
     * @custom:storage-location erc7201:openzeppelin.storage.Initializable
     */
    struct InitializableStorage {
        /**
         * @dev Indicates that the contract has been initialized.
         */
        uint64 _initialized;
        /**
         * @dev Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant INITIALIZABLE_STORAGE = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    /**
     * @dev The contract is already initialized.
     */
    error InvalidInitialization();

    /**
     * @dev The contract is not initializing.
     */
    error NotInitializing();

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint64 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that in the context of a constructor an `initializer` may be invoked any
     * number of times. This behavior in the constructor can be useful during testing and is not expected to be used in
     * production.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        // Cache values to avoid duplicated sloads
        bool isTopLevelCall = !$._initializing;
        uint64 initialized = $._initialized;

        // Allowed calls:
        // - initialSetup: the contract is not in the initializing state and no previous version was
        //                 initialized
        // - construction: the contract is initialized at version 1 (no reininitialization) and the
        //                 current contract is just being deployed
        bool initialSetup = initialized == 0 && isTopLevelCall;
        bool construction = initialized == 1 && address(this).code.length == 0;

        if (!initialSetup && !construction) {
            revert InvalidInitialization();
        }
        $._initialized = 1;
        if (isTopLevelCall) {
            $._initializing = true;
        }
        _;
        if (isTopLevelCall) {
            $._initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: Setting the version to 2**64 - 1 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint64 version) {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing || $._initialized >= version) {
            revert InvalidInitialization();
        }
        $._initialized = version;
        $._initializing = true;
        _;
        $._initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        _checkInitializing();
        _;
    }

    /**
     * @dev Reverts if the contract is not in an initializing state. See {onlyInitializing}.
     */
    function _checkInitializing() internal view virtual {
        if (!_isInitializing()) {
            revert NotInitializing();
        }
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing) {
            revert InvalidInitialization();
        }
        if ($._initialized != type(uint64).max) {
            $._initialized = type(uint64).max;
            emit Initialized(type(uint64).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint64) {
        return _getInitializableStorage()._initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _getInitializableStorage()._initializing;
    }

    /**
     * @dev Returns a pointer to the storage namespace.
     */
    // solhint-disable-next-line var-name-mixedcase
    function _getInitializableStorage() private pure returns (InitializableStorage storage $) {
        assembly {
            $.slot := INITIALIZABLE_STORAGE
        }
    }
}

// SPDX-License-Identifier: None
// Raffl Protocol (last updated v1.0.0) (interfaces/IERC20Minimal.sol)
pragma solidity ^0.8.25;

/// @title IERC20Minimal
/// @notice Interface for the ERC20 token standard with minimal functionality
interface IERC20Minimal {
    /// @notice Returns the balance of a token for a specific account
    /// @param account The address of the account to query
    /// @return The balance of tokens held by the account
    function balanceOf(address account) external view returns (uint256);

    /// @notice Transfers a specified amount of tokens from the caller's account to a recipient's account
    /// @param recipient The address of the recipient
    /// @param amount The amount of tokens to transfer
    /// @return True if the transfer was successful, False otherwise
    function transfer(address recipient, uint256 amount) external returns (bool);

    /// @notice Transfers a specified amount of tokens from a sender's account to a recipient's account
    /// @param sender The address of the sender
    /// @param recipient The address of the recipient
    /// @param amount The amount of tokens to transfer
    /// @return True if the transfer was successful, False otherwise
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}