// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "contracts/utils/structs/EnumerableSet.sol";
import "contracts/utils/Strings.sol";

import "contracts/common/ViciInitializable.sol";
import "contracts/wallet/Wallet.sol";

/**
 * @title Multi-Signature Wallet with Timelock and Survivorship
 * @notice Allows multiple parties to agree on transactions before execution.
 * @notice Enforces a delay before allowing a transaction to execute.
 * @author Original: Stefan George - <[email protected]>
 * @author Josh Davis - <[email protected]>
 * changelog:
 * - update to 0.8
 * - use Address set for owners
 * - add support for sending/holding/receiving tokens
 * - add function to veto transactions
 * - replace boolean executed flag with a status enum
 * - add support for upgrades
 * - add support for timelock
 * - add rights of survivorship
 *
 * Based heavily on the contract at https://polygonscan.com/address/0x355b8e02e7f5301e6fac9b7cac1d6d9c86c0343f
 *
 * This contract has
 * - A set of owners - addresses allowed to submit and confirm transactions
 * - A minimum number of owner for a quorum - the number of confirmations a
 *   transaction must have before it can be executed.
 * - A timelock period - the amount of time that must pass after a transaction
 *   has received the required number of confirmations before it can be
 *   executed.
 * - A live account timer - the amount of time after which, if an owner has
 *   not interacted with this contract (see #ping), that owner's vote is no
 *   longer required for a quorum. That is to say, inactive owners auto-
 *   confirm transactions.
 *
 * Any owner may veto a transaction. A vetoed transaction cannot be confirmed
 * or executed.
 *
 * A multi-sig wallet has a set of owners and a number of required signatures.
 * Any owner can submit a transaction, and the other owners can then confirm
 * the transaction.
 *
 * When a transaction reached the required number of confirmations, a countdown
 * timer begins. The transaction cannot be executed until the required amount
 * of time has passed. If enough owners revoke their confirmation so that the
 * transation no longer has the required number of confirmations, the timer is
 * reset, and will start over if the required number of confirmations is
 * reached again.
 *
 * If the timelock period is 0, then the timelock period feature is turned off.
 * Transactions will executed immediately once they reach the required number
 * of confirmations. If the timelock period is nonzero, transactions must be
 * executed manually by calling the `executeTransaction()` function.
 *
 * If the live account timer is 0, then the survivorship feature is turned off,
 * and owners are never considered to be inactive.
 *
 * IMPORTANT: If the number of required confirmations change, and the change
 * causes pending transactions to reach or fall below the new value, the
 * countdown timers are NOT automatically set or cleared. You can manually
 * set or reset the timer for a transaction by calling `resetConfirmationTimer()`.
 */

enum TransactionStatus {
    // 0: Every status, use for querying. No tx should ever have this status.
    EVERY_STATUS,
    // 1: Unconfirmed, Tx submitted but not confirmed
    UNCONFIRMED,
    // 2: Confirmed, but not yet executed
    CONFIRMED,
    // 3: Executed
    EXECUTED,
    // 4: Vetoed, cannot be executed
    VETOED,
    // 5: Reverted, may be tried again
    REVERTED
}

contract MultiSigWalletWithSurvivorship is ViciInitializable, Wallet {
    using EnumerableSet for EnumerableSet.AddressSet;
    using ViciAddressUtils for address;

    /**
     * @notice Emitted when an owner votes to confirm a transaction.
     */
    event Confirmation(address indexed sender, uint256 indexed transactionId);

    /**
     * @notice Emitted when an owner revokes their vote to confirm a transaction.
     */
    event Revocation(address indexed sender, uint256 indexed transactionId);

    /**
     * @notice Emitted when an owner submits a new transaction.
     */
    event Submission(uint256 indexed transactionId);

    /**
     * @notice Emitted when a confirmed transaction has been performed.
     */
    event Execution(uint256 indexed transactionId);

    /**
     * @notice Emitted when a confirmed transaction failed to execute.
     */
    event ExecutionFailure(uint256 indexed transactionId, bytes reason);

    /**
     * @notice Emitted when a transaction has been vetoed.
     */
    event Vetoed(address indexed sender, uint256 indexed transactionId);

    /**
     * @notice Emitted when a new owner is added.
     */
    event OwnerAddition(address indexed owner);

    /**
     * @notice Emitted when an owner is removed.
     */
    event OwnerRemoval(address indexed owner);

    /**
     * @notice Emitted when the required number of signatures changes.
     */
    event RequirementChange(uint256 previous, uint256 required);

    /**
     * @notice Emitted when the timelock period is changed.
     */
    event TimelockChange(uint256 previous, uint256 timelock);

    /**
     * @notice Emitted with the live account checkin time period has changed.
     */
    event LiveAccountCheckinChange(
        uint256 previous,
        uint256 liveAccountCheckin
    );

    /**
     * @notice Emitted when the countdown timer for a transaction has been set.
     */
    event ConfirmationTimeSet(uint256 transactionId, uint256 confirmationTime);

    /**
     * @notice Emitted when the countdown timer for a transaction has been cleared.
     */
    event ConfirmationTimeUnset(uint256 transactionId);

    struct Transaction {
        /**
         * What the tx does. Be succinct! You only have 32 characters.
         */
        bytes32 description;
        /**
         * The address of the contract to call.
         */
        address destination;
        /**
         * The amount of crypto to send.
         */
        uint256 value;
        /**
         * Set to true when this transaction is successfully executed.
         */
        TransactionStatus status;
        /**
         * The ABI-encoded function call.
         */
        bytes data;
    }

    uint256 internal constant MAX_OWNER_COUNT = 50;

    /**
     * @dev All submitted transactions by id. Transaction ids are sequential
     *     starting at 1.
     */
    mapping(uint256 => Transaction) public transactions;

    /**
     * @dev For each transaction id, whether an owner has approved it.
     */
    mapping(uint256 => mapping(address => bool)) public confirmations;

    /**
     * @dev address to whether or not they are an owner
     */
    mapping(address => bool) public isOwner;

    /**
     * @dev address to the last blockchain timestamp at which they interacted
     *     with this contract.
     */
    mapping(address => uint256) public lastCheckin;

    /**
     * @dev The set of owners
     */
    EnumerableSet.AddressSet owners;

    /**
     * @dev The number of required confirmations
     */
    uint256 public required;

    /**
     * @dev The total number of submitted transactions
     */
    uint256 public transactionCount;

    /**
     * @dev The number of seconds to wait after confirmation before any
     *     transaction can be executed.
     */
    uint256 public lockPeriod;

    /**
     * @dev The amount of time, after which, an onwer may be considered
     *     inactive.
     */
    uint256 public liveAccountCheckin;

    /**
     * @dev Tracks when a transaction received the required number of
     *     confirmations.
     * @dev Key is transactionId, value is block.timestamp
     */
    mapping(uint256 => uint256) public confirmationTimes;

    modifier onlyWallet() {
        require(msg.sender == address(this), "Must be wallet");
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        enforceNotOwner(owner);
        _;
    }

    modifier ownerExists(address owner) {
        enforceOwner(owner);
        _;
    }

    modifier onlyOwner() {
        enforceOwner(msg.sender);
        _checkin(msg.sender);
        _;
    }

    modifier transactionExists(uint256 transactionId) {
        require(
            transactions[transactionId].destination != address(0),
            string.concat("Invalid TX: ", Strings.toString(transactionId))
        );
        _;
    }

    modifier confirmed(uint256 transactionId, address owner) {
        require(
            confirmations[transactionId][owner],
            string.concat(
                "TX ",
                Strings.toString(transactionId),
                " not confirmed by ",
                Strings.toHexString(owner)
            )
        );
        _;
    }

    modifier notConfirmed(uint256 transactionId, address owner) {
        require(
            !confirmations[transactionId][owner],
            string.concat(
                "TX ",
                Strings.toString(transactionId),
                " already confirmed by ",
                Strings.toHexString(owner)
            )
        );
        _;
    }

    modifier notExecuted(uint256 transactionId) {
        require(
            transactions[transactionId].status != TransactionStatus.EXECUTED,
            string.concat(
                "Already executed TX: ",
                Strings.toString(transactionId)
            )
        );
        _;
    }

    modifier notVetoed(uint256 transactionId) {
        require(
            transactions[transactionId].status != TransactionStatus.VETOED,
            string.concat("Vetoed TX: ", Strings.toString(transactionId))
        );
        _;
    }

    modifier notNull(address _address) {
        enforceValidOwnerAddress(_address);
        _;
    }

    modifier validRequirement(uint256 ownerCount, uint256 _required) {
        enforceValidRequirement(ownerCount, _required);
        _;
    }

    function enforceNotOwner(address owner) internal view virtual {
        require(
            !isOwner[owner],
            string.concat("Already owner: ", Strings.toHexString(owner))
        );
    }

    function enforceOwner(address owner) internal view virtual {
        require(
            isOwner[owner],
            string.concat("Not owner: ", Strings.toHexString(owner))
        );
    }

    function enforceValidOwnerAddress(address _address) internal view virtual {
        require(_address != address(0), "Null owner address");
    }

    function enforceValidRequirement(
        uint256 ownerCount,
        uint256 _required
    ) internal view virtual {
        require(ownerCount <= MAX_OWNER_COUNT, "Too many owners");
        require(_required <= ownerCount, "Not enough owners");
        require(_required != 0, "Required can't be zero");
    }

    /**
     * @param _owners The initial list of owners.
     * @param _required The initial required number of confirmations.
     * @param _lockPeriod The number of seconds to wait after confirmation
     *     before a transaction can be executed.
     * @param _liveAccountCheckin The amount of time, after which, an onwer may
     *     be considered inactive.
     *
     * Requirements:
     * - `_owners` MUST NOT contain any duplicates.
     * - `_owners` MUST NOT contain the null address.
     * - `_required` MUST be greater than 0.
     * - The length of `_owners` MUST NOT be less than `_required`.
     * - The length of `_owners` MUST NOT be greater than `MAX_OWNER_COUNT`.
     * - `_lockPeriod` MAY be 0, in which case transactions will execute
     *     immediately upon receiving the required number of confirmations.
     * - `_liveAccountCheckin` MAY be 0, in which case owners are never
     *    considered to be inactive.
     */
    function initialize(
        address[] calldata _owners,
        uint256 _required,
        uint256 _lockPeriod,
        uint256 _liveAccountCheckin
    ) public virtual initializer {
        __MultiSigWalletWithSurvivorship_init(
            _owners,
            _required,
            _lockPeriod,
            _liveAccountCheckin
        );
    }

    function __MultiSigWalletWithSurvivorship_init(
        address[] calldata _owners,
        uint256 _required,
        uint256 _lockPeriod,
        uint256 _liveAccountCheckin
    ) internal onlyInitializing {
        __MultiSigWalletWithSurvivorship_init_unchained(
            _owners,
            _required,
            _lockPeriod,
            _liveAccountCheckin
        );
    }

    function __MultiSigWalletWithSurvivorship_init_unchained(
        address[] calldata _owners,
        uint256 _required,
        uint256 _lockPeriod,
        uint256 _liveAccountCheckin
    ) internal onlyInitializing validRequirement(_owners.length, _required) {
        for (uint256 i = 0; i < _owners.length; i++) {
            enforceValidOwnerAddress(_owners[i]);
            enforceNotOwner(_owners[i]);
            isOwner[_owners[i]] = true;
            owners.add(_owners[i]);
        }
        required = _required;
        lockPeriod = _lockPeriod;
        liveAccountCheckin = _liveAccountCheckin;
    }

    /**
     * @notice Changes the lock period.
     * @notice emits TimeLockChange
     * @param _newLockPeriod the new lock period, in seconds.
     *
     * Requirements:
     * - Transaction MUST be sent by the wallet.
     * - `_newLockPeriod` MUST be different from the current value.
     * - `_newLockPeriod` MAY be 0, in which case transactions will execute
     *     immediately upon receiving the required number of confirmations.
     */
    function changeLockPeriod(
        uint256 _newLockPeriod
    ) public virtual onlyWallet {
        require(lockPeriod != _newLockPeriod);

        uint256 previous = lockPeriod;
        lockPeriod = _newLockPeriod;
        emit TimelockChange(previous, lockPeriod);
    }

    /**
     * @notice Changes the live account period.
     * @notice emits LiveAccountCheckinChange
     * @param _liveAccountCheckin the new live account checkin period, in seconds.
     *
     * Requirements:
     * - _liveAccountCheckin MUST be sent by the wallet.
     * - `_newLockPeriod` MUST be different from the current value.
     * - `_liveAccountCheckin` MAY be 0, in which case owners are never
     *    considered to be inactive.
     */
    function changeLiveAccountCheckinPeriod(
        uint256 _liveAccountCheckin
    ) public virtual onlyWallet {
        require(liveAccountCheckin != _liveAccountCheckin);

        uint256 previous = liveAccountCheckin;
        liveAccountCheckin = _liveAccountCheckin;
        emit LiveAccountCheckinChange(previous, liveAccountCheckin);
    }

    /**
     * @notice Adds a new owner
     * @notice emits OwnerAddition
     * @param owner the owner address
     *
     * Requirements:
     * - Transaction MUST be sent by the wallet.
     * - `owner` MUST NOT already be an owner.
     * - `owner` MUST NOT be the null address.
     * - The current number of owners MUST be less than `MAX_OWNER_COUNT`.
     */
    function addOwner(
        address owner
    )
        public
        virtual
        onlyWallet
        ownerDoesNotExist(owner)
        notNull(owner)
        validRequirement(owners.length() + 1, required)
    {
        _addOwner(owner);
        emit OwnerAddition(owner);
    }

    function _addOwner(address owner) internal virtual {
        isOwner[owner] = true;
        owners.add(owner);
        lastCheckin[owner] = block.timestamp;
    }

    /**
     * @notice Removes an owner.
     * @notice emits OwnerRemoval
     * @notice If the current number of owners is reduced to below the number
     * of required signatures, `required` will be reduced to match.
     * @param owner the owner to be removed
     *
     * Requirements:
     * - Transaction MUST be sent by the wallet.
     * - `owner` MUST be an existing owner
     * - The current number of owners MUST be greater than 1 (i.e. you can't
     *   remove all the owners).
     */
    function removeOwner(
        address owner
    ) public virtual onlyWallet ownerExists(owner) {
        _removeOwner(owner);

        if (required > owners.length()) changeRequirement(owners.length());
        emit OwnerRemoval(owner);
    }

    function _removeOwner(address owner) internal virtual {
        isOwner[owner] = false;
        owners.remove(owner);
    }

    /**
     * @notice Replaces an owner with a new owner.
     * @notice emits OwnerRemoval and OwnerAddition
     * @param owner Address of owner to be replaced.
     * @param newOwner Address of new owner.
     *
     * Requirements:
     * - Transaction MUST be sent by the wallet.
     * - `owner` MUST be an existing owner
     * - `newOwner` MUST NOT already be an owner.
     * - `newOwner` MUST NOT be the null address.
     */
    function replaceOwner(
        address owner,
        address newOwner
    )
        public
        virtual
        onlyWallet
        ownerExists(owner)
        notNull(newOwner)
        ownerDoesNotExist(newOwner)
    {
        _removeOwner(owner);
        _addOwner(newOwner);

        emit OwnerRemoval(owner);
        emit OwnerAddition(newOwner);
    }

    /**
     * @notice Changes the number of required confirmations.
     * @notice emits RequirementChange
     * @param _required Number of required confirmations.
     *
     * Requirements:
     * - Transaction MUST be sent by the wallet.
     * - `_required` MUST be greater than 0.
     * - `_required` MUST NOT be greater than the number of owners.
     * - `_required` MUST be different from the current value.
     */
    function changeRequirement(
        uint256 _required
    ) public virtual onlyWallet validRequirement(owners.length(), _required) {
        require(required != _required);
        uint256 previous = required;
        required = _required;

        emit RequirementChange(previous, _required);
    }

    /**
     * @notice Allows an owner to submit and confirm a transaction.
     * @notice Also resets the caller's last active time to the current
     *     timestamp.
     * @dev The new transaction id will be equal to the new transaction count.
     * @param description The transaction description.
     * @param destination Transaction target address.
     * @param value Transaction ether value.
     * @param data Transaction data payload.
     * @return transactionId transaction ID.
     *
     * Requirements:
     * - Caller MUST be an owner.
     */
    function submitTransaction(
        bytes32 description,
        address destination,
        uint256 value,
        bytes calldata data
    ) public virtual notNull(destination) returns (uint256 transactionId) {
        transactionId = _addTransaction(description, destination, value, data);
        confirmTransaction(transactionId);
    }

    /**
     * @notice Allows an owner to confirm a transaction.
     * @notice emits Confirmation
     * @notice Also resets the caller's last active time to the current
     *     timestamp.
     * @param transactionId Transaction ID.
     *
     * Requirements:
     * - Caller MUST be an owner.
     * - `transactionId` MUST exist.
     * - Caller MUST NOT have already confirmed the transaction.
     */
    function confirmTransaction(
        uint256 transactionId
    )
        public
        virtual
        onlyOwner
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
        returns (uint256 gasUsed)
    {
        uint256 startGas = gasleft();
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        _confirmationHook(transactionId);
        executeTransaction(transactionId);
        gasUsed = startGas - gasleft();
    }

    /**
     * @notice Allows an owner to revoke a confirmation for a transaction.
     * @notice emits Revocation
     * @param transactionId Transaction ID.
     * @notice Also resets the caller's last active time to the current
     *     timestamp.
     *
     * Requirements:
     * - Caller MUST be an owner.
     * - `transactionId` MUST exist.
     * - Caller MUST have previously confirmed the transaction.
     * - The transaction MUST NOT have already been successfully executed.
     * - The transaction MUST NOT have been vetoed.
     */
    function revokeConfirmation(
        uint256 transactionId
    )
        public
        virtual
        onlyOwner
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
        notVetoed(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
        _revocationHook(transactionId);
    }

    /**
     * @notice Allows an owner to veto a transaction.
     * @notice emits Vetoed
     * @param transactionId Transaction ID.
     * @notice Also resets the caller's last active time to the current
     *     timestamp.
     *
     * Requirements:
     * - Caller MUST be an owner.
     * - `transactionId` MUST exist.
     * - The transaction MUST NOT have already been successfully executed.
     * - The transaction MUST NOT have been vetoed.
     */
    function vetoTransaction(
        uint256 transactionId
    )
        public
        virtual
        onlyOwner
        transactionExists(transactionId)
        notExecuted(transactionId)
        notVetoed(transactionId)
    {
        transactions[transactionId].status = TransactionStatus.VETOED;
        emit Vetoed(msg.sender, transactionId);
    }

    /**
     * @notice Allows an owner to execute a confirmed transaction.
     * @notice performs no-op if transaction is not confirmed.
     * @notice emits Execution if the transaction was successfully executed.
     * @notice emits ExecutionFailure if the transaction was attempted and did
     *     not succeed.
     * @notice Also resets the caller's last active time to the current
     *     timestamp, success or fail.
     * @param transactionId Transaction ID.
     *
     * Requirements:
     * - Caller MUST be an owner.
     * - `transactionId` MUST exist.
     * - `transactionId` MUST exist.
     * - The transaction MUST NOT have already been successfully executed.
     * - The transaction MUST NOT have been vetoed.
     */
    function executeTransaction(
        uint256 transactionId
    )
        public
        virtual
        onlyOwner
        transactionExists(transactionId)
        notExecuted(transactionId)
        notVetoed(transactionId)
        returns (uint256 gasUsed)
    {
        uint256 startGas = gasleft();
        if (isConfirmed(transactionId)) {
            if (lockPeriod == 0) {
                _executeTransaction(transactionId);
            } else if (confirmationTimes[transactionId] == 0) {
                _setConfirmed(transactionId);
            } else if (
                block.timestamp >= confirmationTimes[transactionId] + lockPeriod
            ) {
                _executeTransaction(transactionId);
            } else {
                revert("Too early");
            }
        } else if (confirmationTimes[transactionId] > 0) {
            // Catch cases where a confirmed transaction became unconfirmed
            // due to an increase in the required number of confirmations.
            _setUnconfirmed(transactionId);
        }
        gasUsed = startGas - gasleft();
    }

    /**
     * @notice Returns the confirmation status of a transaction.
     * @notice Returns `false` if the transaction is vetoed.
     * @param transactionId Transaction ID.
     * @return Confirmation status.
     */
    function isConfirmed(
        uint256 transactionId
    ) public view virtual returns (bool) {
        if (transactions[transactionId].status == TransactionStatus.VETOED) {
            return false;
        }

        uint256 count = 0;
        uint256 inactiveCutoff = 0;
        if (liveAccountCheckin > 0 && liveAccountCheckin < block.timestamp) {
            inactiveCutoff = block.timestamp - liveAccountCheckin;
        }
        for (uint256 i = 0; i < owners.length(); i++) {
            address eachOwner = owners.at(i);
            if (confirmations[transactionId][eachOwner]) {
                count += 1;
            } else if (lastCheckin[eachOwner] < inactiveCutoff) {
                count += 1;
            }
            if (count == required) return true;
        }
        return false;
    }

    /**
     * @notice Returns number of confirmations of a transaction.
     * @param transactionId Transaction ID.
     * @return count number of confirmations.
     */
    function getConfirmationCount(
        uint256 transactionId
    ) public view virtual returns (uint256 count, uint256 inactives) {
        uint256 inactiveCutoff = 0;
        if (liveAccountCheckin > 0 && liveAccountCheckin < block.timestamp) {
            inactiveCutoff = block.timestamp - liveAccountCheckin;
        }

        for (uint256 i = 0; i < owners.length(); i++) {
            address eachOwner = owners.at(i);
            if (confirmations[transactionId][eachOwner]) {
                count += 1;
            } else if (lastCheckin[eachOwner] < inactiveCutoff) {
                inactives += 1;
            }
        }
    }

    /**
     * @notice Returns total number of transactions after filters are applied.
     * @dev use with `getTransactionIds` to page through transactions.
     * @dev Pass TransactionStatus.EVERY_STATUS (0) to count all transactions.
     * @param status Only count transactions with the supplied status.
     * @return count Total number of transactions after filters are applied.
     */
    function getTransactionCount(
        TransactionStatus status
    ) public view virtual returns (uint256 count) {
        for (uint256 i = 1; i <= transactionCount; i++)
            if (
                status == TransactionStatus.EVERY_STATUS ||
                transactions[i].status == status
            ) count += 1;
    }

    /**
     * @notice Returns list of transaction IDs in defined range.
     * @dev use with `getTransactionCount` to page through transactions.
     * @dev Pass TransactionStatus.EVERY_STATUS (0) to return all transactions
     *     in range.
     * @param from Index start position of transaction array (inclusive).
     * @param to Index end position of transaction array (exclusive).
     * @param status Only return transactions with the supplied status.
     * @return _transactionIds array of transaction IDs.
     *
     * Requirements:
     * `to` MUST NOT be less than `from`.
     * `to` - `from` MUST NOT be greater than the number of transactions that
     *     meet the filter criteria.
     */
    function getTransactionIds(
        uint256 from,
        uint256 to,
        TransactionStatus status
    ) public view virtual returns (uint256[] memory _transactionIds) {
        uint256[] memory transactionIdsTemp = new uint256[](transactionCount);
        uint256 count = 0;
        uint256 i;
        uint256 maxResults = to - from;
        for (i = 1; i <= transactionCount && count <= to; i++)
            if (
                status == TransactionStatus.EVERY_STATUS ||
                    transactions[i].status == status
            ) {
                transactionIdsTemp[count] = i;
                count += 1;
            }

        _transactionIds = new uint256[](maxResults);
        for (i = from; i < maxResults+from; i++)
            _transactionIds[i - from] = transactionIdsTemp[i];
    }

    /**
     * @notice Returns list of owners.
     * @return List of owner addresses.
     */
    function getOwners() public view virtual returns (address[] memory) {
        return owners.values();
    }

    /**
     * @notice Returns the number of owners.
     * @dev Use with getOwnerAtIndex() to enumerate.
     */
    function getOwnerCount() public view virtual returns (uint256) {
        return owners.length();
    }

    /**
     * @notice Returns the number of owners.
     * @dev Use with getOwnerCount() to enumerate.
     */
    function getOwnerAtIndex(
        uint256 index
    ) public view virtual returns (address) {
        return owners.at(index);
    }

    /**
     * @notice Returns array with owner addresses, which confirmed transaction.
     * @param transactionId Transaction ID.
     * @return _confirmations array of owner addresses.
     */
    function getConfirmations(
        uint256 transactionId
    ) public view virtual returns (address[] memory _confirmations) {
        address[] memory confirmationsTemp = new address[](owners.length());
        uint256 count = 0;
        uint256 i;
        for (i = 0; i < owners.length(); i++)
            if (confirmations[transactionId][owners.at(i)]) {
                confirmationsTemp[count] = owners.at(i);
                count += 1;
            }
        _confirmations = new address[](count);
        for (i = 0; i < count; i++) _confirmations[i] = confirmationsTemp[i];
    }

    /**
     * @notice Withdraws native crypto.
     * @param toAddress the address to receive the crypto
     * @param amount the amount to withdraw
     *
     * Requirements:
     * - Transaction MUST be sent by the wallet.
     * - `toAddress` MUST NOT be the null address.
     * - `amount` MUST NOT exceed the wallet balance.
     */
    function withdraw(
        address payable toAddress,
        uint256 amount
    ) public virtual onlyWallet {
        _withdraw(toAddress, amount);
    }

    /**
     * @notice Withdraws ERC20 crypto.
     * @param toAddress the address to receive the crypto
     * @param amount the amount to withdraw
     * @param tokenContract the ERC20 contract.
     *
     * Requirements:
     * - Transaction MUST be sent by the wallet.
     * - `toAddress` MUST NOT be the null address.
     * - `amount` MUST NOT exceed the wallet balance.
     */
    function withdrawERC20(
        address payable toAddress,
        uint256 amount,
        IERC20 tokenContract
    ) public virtual onlyWallet {
        _withdrawERC20(toAddress, amount, tokenContract);
    }

    /**
     * @notice Withdraws an ERC721 token.
     * @param toAddress the address to receive the token
     * @param tokenId the token id
     * @param tokenContract the ERC721 contract.
     *
     * Requirements:
     * - Transaction MUST be sent by the wallet.
     * - `toAddress` MUST NOT be the null address.
     * - `amount` MUST NOT exceed the wallet balance.
     */
    function withdrawERC721(
        address payable toAddress,
        uint256 tokenId,
        IERC721 tokenContract
    ) public virtual onlyWallet {
        _withdrawERC721(toAddress, tokenId, tokenContract);
    }

    /**
     * @notice Withdraws ERC777 crypto.
     * @param toAddress the address to receive the crypto
     * @param amount the amount to withdraw
     * @param tokenContract the ERC777 contract.
     *
     * Requirements:
     * - Transaction MUST be sent by the wallet.
     * - `toAddress` MUST NOT be the null address.
     * - `amount` MUST NOT exceed the wallet balance.
     */
    function withdrawERC777(
        address payable toAddress,
        uint256 amount,
        IERC777 tokenContract
    ) public virtual onlyWallet {
        _withdrawERC777(toAddress, amount, tokenContract);
    }

    /**
     * @notice Withdraws ERC1155 tokens.
     * @param toAddress the address to receive the tokens
     * @param tokenId the token id
     * @param amount the amount to withdraw
     * @param tokenContract the ERC1155 contract.
     *
     * Requirements:
     * - Transaction MUST be sent by the wallet.
     * - `toAddress` MUST NOT be the null address.
     * - `amount` MUST NOT exceed the wallet balance.
     */
    function withdrawERC1155(
        address payable toAddress,
        uint256 tokenId,
        uint256 amount,
        IERC1155 tokenContract
    ) public virtual onlyWallet {
        _withdrawERC1155(toAddress, tokenId, amount, tokenContract);
    }

    /**
     * @dev Adds a new transaction to the transaction mapping
     * @param description The transaction description.
     * @param destination Transaction target address.
     * @param value Transaction ether value.
     * @param data Transaction data payload.
     * @return transactionId transaction ID.
     */
    function _addTransaction(
        bytes32 description,
        address destination,
        uint256 value,
        bytes calldata data
    ) internal virtual returns (uint256 transactionId) {
        transactionId = transactionCount + 1;
        transactions[transactionId] = Transaction({
            description: description,
            destination: destination,
            value: value,
            status: TransactionStatus.UNCONFIRMED,
            data: data
        });
        transactionCount += 1;
        emit Submission(transactionId);
    }

    function _executeTransaction(uint256 transactionId) internal virtual {
        Transaction storage txn = transactions[transactionId];
        (bool executed, bytes memory result) = txn.destination.call{
            value: txn.value
        }(txn.data);

        if (executed) {
            txn.status = TransactionStatus.EXECUTED;
            emit Execution(transactionId);
        } else {
            transactions[transactionId].status = TransactionStatus.REVERTED;
            emit ExecutionFailure(transactionId, result);
        }
    }

    /**
     * @notice Sets or clears confimation timers for a pending transaction
     *     that may have become confirmed or unconfirmed due to a change to the
     *     required number of confirmations.
     * @notice This should be called for pending transactions after changing
     *     the required number of confirmations.
     * @notice Also resets the caller's last active time to the current
     *     timestamp.
     * @param transactionId Transaction ID.
     *
     * Requirements:
     * - Caller MUST be an owner.
     * - `transactionId` MUST exist.
     * - The transaction MUST NOT have already been successfully executed.
     * - The transaction MUST NOT have been vetoed.
     */
    function resetConfirmationTimer(
        uint256 transactionId
    )
        public
        virtual
        onlyOwner
        transactionExists(transactionId)
        notExecuted(transactionId)
        notVetoed(transactionId)
    {
        if (isConfirmed(transactionId)) {
            if (confirmationTimes[transactionId] == 0) {
                _setConfirmed(transactionId);
            }
        } else {
            if (confirmationTimes[transactionId] > 0) {
                _setUnconfirmed(transactionId);
            }
        }
    }

    /**
     * @notice Call this function periodically to maintain active status.
     * @notice Resets the caller's last active time to the current timestamp.
     *
     * Requirements
     * - Caller MUST be an owner.
     */
    function ping() public virtual onlyOwner {}

    /**
     * @notice Call this function on behalf of another owner to maintain their
     *     active status.
     * @notice Also resets the caller's last active time to the current
     *     timestamp.
     *
     * Requirements
     * - Caller MUST be an owner.
     * - `owner` MUST be an owner.
     */
    function pingFor(address owner) public virtual onlyOwner {
        enforceOwner(owner);
        _checkin(owner);
    }

    function _checkin(address owner) internal virtual {
        lastCheckin[owner] = block.timestamp;
    }

    function _setConfirmed(uint256 transactionId) internal virtual {
        confirmationTimes[transactionId] = block.timestamp;
        transactions[transactionId].status = TransactionStatus.CONFIRMED;
        emit ConfirmationTimeSet(
            transactionId,
            confirmationTimes[transactionId]
        );
    }

    function _setUnconfirmed(uint256 transactionId) internal virtual {
        confirmationTimes[transactionId] = 0;
        transactions[transactionId].status = TransactionStatus.UNCONFIRMED;
        emit ConfirmationTimeUnset(transactionId);
    }

    function _confirmationHook(uint256 transactionId) internal virtual {}

    /**
     * @dev Clears the countdown timer for a transaction if started and we
     *     do not have the required number of confirmations.
     * @dev emits ConfirmationTimeUnset if the countdown timer was cleared.
     */
    function _revocationHook(uint256 transactionId) internal virtual {
        if (confirmationTimes[transactionId] == 0) return;

        if (!isConfirmed(transactionId)) {
            _setUnconfirmed(transactionId);
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[40] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.20;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position is the index of the value in the `values` array plus 1.
        // Position 0 is used to mean a value is not in the set.
        mapping(bytes32 value => uint256) _positions;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._positions[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We cache the value's position to prevent multiple reads from the same storage slot
        uint256 position = set._positions[value];

        if (position != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 valueIndex = position - 1;
            uint256 lastIndex = set._values.length - 1;

            if (valueIndex != lastIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the lastValue to the index where the value to delete is
                set._values[valueIndex] = lastValue;
                // Update the tracked position of the lastValue (that was just moved)
                set._positions[lastValue] = position;
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the tracked position for the deleted slot
            delete set._positions[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._positions[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Strings.sol)

pragma solidity ^0.8.20;

import {Math} from "contracts/utils/math/Math.sol";
import {SignedMath} from "contracts/utils/math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant HEX_DIGITS = "0123456789abcdef";
    uint8 private constant ADDRESS_LENGTH = 20;

    /**
     * @dev The `value` string doesn't fit in the specified `length`.
     */
    error StringsInsufficientHexLength(uint256 value, uint256 length);

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), HEX_DIGITS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toStringSigned(int256 value) internal pure returns (string memory) {
        return string.concat(value < 0 ? "-" : "", toString(SignedMath.abs(value)));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        uint256 localValue = value;
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = HEX_DIGITS[localValue & 0xf];
            localValue >>= 4;
        }
        if (localValue != 0) {
            revert StringsInsufficientHexLength(value, length);
        }
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal
     * representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return bytes(a).length == bytes(b).length && keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/Math.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
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
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.24;

import "contracts/lib/ViciAddressUtils.sol";

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
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
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
 *
 * @dev This contract is a direct copy of OpenZeppelin's InitializableUpgradeable,
 * moved here, renamed, and modified to use our AddressUtils library so we
 * don't have to deal with incompatibilities between OZ'` contracts and
 * contracts-upgradeable `
 */
abstract contract ViciInitializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) ||
                (!ViciAddressUtils.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
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
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(
            !_initializing && _initialized < version,
            "Initializable: contract is already initialized"
        );
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
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
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.24;

/**
 * @dev Collection of functions related to the address type
 *
 * @dev This contract is a direct copy of OpenZeppelin's AddressUpgradeable, 
 * moved here and renamed so we don't have to deal with incompatibilities 
 * between OZ'` contracts and contracts-upgradeable `
 */
library ViciAddressUtils {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "contracts/token/ERC20/IERC20.sol";
import "contracts/token/ERC721/IERC721.sol";
import "contracts/token/ERC721/IERC721Receiver.sol";
import "contracts/interfaces/IERC777.sol";
import "contracts/interfaces/IERC777Recipient.sol";
import "contracts/token/ERC1155/IERC1155.sol";
import "contracts/token/ERC1155/IERC1155Receiver.sol";
import "contracts/utils/introspection/ERC165.sol";

/**
 * @title Wallet
 * @notice (c) 2023 ViciNFT https://vicinft.com/
 * @author Josh Davis <[email protected]>
 *
 * @dev This is an abstract contract with basic wallet functionality. It can
 *     send and receive native crypto, ERC20 tokens, ERC721 tokens, ERC777 
 *     tokens, and ERC1155 tokens.
 * @dev The withdraw events are always emitted when crypto or tokens are
 *     withdrawn.
 * @dev The deposit events are less reliable, and normally only work when the
 *     safe transfer functions are used.
 * @dev There is no DepositERC20 event defined, because the ERC20 standard 
 *     doesn't include a safe transfer function.
 * @dev The withdraw functions are all marked as internal. Subclasses should
 *     add public withdraw functions that delegate to these, preferably with 
 *     some kind of control over who is allowed to call them.
 */
abstract contract Wallet is
    IERC721Receiver,
    IERC777Recipient,
    IERC1155Receiver,
    ERC165
{
    /**
     * @dev May be emitted when native crypto is deposited.
     * @param sender the source of the crypto
     * @param value the amount deposited
     */
    event Deposit(address indexed sender, uint256 value);

    /**
     * @dev May be emitted when an NFT is deposited.
     * @param sender the source of the NFT
     * @param tokenContract the NFT contract
     * @param tokenId the id of the deposited token
     */
    event DepositERC721(
        address indexed sender,
        address indexed tokenContract,
        uint256 tokenId
    );

    /**
     * @dev May be emitted when ERC777 tokens are deposited.
     * @param sender the source of the ERC777 tokens
     * @param tokenContract the ERC777 contract
     * @param amount the amount deposited
     */
    event DepositERC777(
        address indexed sender,
        address indexed tokenContract,
        uint256 amount
    );

    /**
     * @dev May be emitted when semi-fungible tokens are deposited.
     * @param sender the source of the semi-fungible tokens
     * @param tokenContract the semi-fungible token contract
     * @param tokenId the id of the semi-fungible tokens
     * @param amount the number of tokens deposited
     */
    event DepositERC1155(
        address indexed sender,
        address indexed tokenContract,
        uint256 tokenId,
        uint256 amount
    );

    /**
     * @dev Emitted when native crypto is withdrawn.
     * @param recipient the destination of the crypto
     * @param value the amount withdrawn
     */
    event Withdraw(address indexed recipient, uint256 value);

    /**
     * @dev Emitted when ERC20 tokens are withdrawn.
     * @param recipient the destination of the ERC20 tokens
     * @param tokenContract the ERC20 contract
     * @param amount the amount withdrawn
     */
    event WithdrawERC20(
        address indexed recipient,
        address indexed tokenContract,
        uint256 amount
    );

    /**
     * @dev Emitted when an NFT is withdrawn.
     * @param recipient the destination of the NFT
     * @param tokenContract the NFT contract
     * @param tokenId the id of the withdrawn token
     */
    event WithdrawERC721(
        address indexed recipient,
        address indexed tokenContract,
        uint256 tokenId
    );

    /**
     * @dev Emitted when ERC777 tokens are withdrawn.
     * @param recipient the destination of the ERC777 tokens
     * @param tokenContract the ERC777 contract
     * @param amount the amount withdrawn
     */
    event WithdrawERC777(
        address indexed recipient,
        address indexed tokenContract,
        uint256 amount
    );

    /**
     * @dev Emitted when semi-fungible tokens are withdrawn.
     * @param recipient the destination of the semi-fungible tokens
     * @param tokenContract the semi-fungible token contract
     * @param tokenId the id of the semi-fungible tokens
     * @param amount the number of tokens withdrawn
     */
    event WithdrawERC1155(
        address indexed recipient,
        address indexed tokenContract,
        uint256 tokenId,
        uint256 amount
    );

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(IERC777Recipient).interfaceId ||
            interfaceId == type(IERC1155Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    receive() external payable {
        if (msg.value > 0) emit Deposit(msg.sender, msg.value);
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external override returns (bytes4) {
        emit DepositERC721(from, msg.sender, tokenId);
        return IERC721Receiver.onERC721Received.selector;
    }

    /**
     * @dev See {IERC777Recipient-tokensReceived}.
     */
    function tokensReceived(
        address,
        address from,
        address,
        uint256 amount,
        bytes calldata,
        bytes calldata
    ) external override {
        emit DepositERC777(from, msg.sender, amount);
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155Received}.
     */
    function onERC1155Received(
        address,
        address from,
        uint256 tokenId,
        uint256 value,
        bytes calldata
    ) external override returns (bytes4) {
        emit DepositERC1155(from, msg.sender, tokenId, value);
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155BatchReceived}.
     */
    function onERC1155BatchReceived(
        address,
        address from,
        uint256[] calldata tokenIds,
        uint256[] calldata values,
        bytes calldata
    ) external override returns (bytes4) {
        for (uint256 i = 0; i < values.length; i++) {
            emit DepositERC1155(from, msg.sender, tokenIds[i], values[i]);
        }
        return
            bytes4(
                keccak256(
                    "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
                )
            );
    }

    /**
     * @dev Withdraw native crypto.
     * @notice Emits Withdraw
     * @param toAddress Where to send the crypto
     * @param amount The amount to send
     */
    function _withdraw(address payable toAddress, uint256 amount)
        internal
        virtual
    {
        require(toAddress != address(0), "ETH: transfer to the zero address");
        toAddress.transfer(amount);
        emit Withdraw(toAddress, amount);
    }

    /**
     * @dev Withdraw ERC20 tokens.
     * @notice Emits WithdrawERC20
     * @param toAddress Where to send the ERC20 tokens
     * @param tokenContract The ERC20 token contract
     * @param amount The amount withdrawn
     */
    function _withdrawERC20(
        address payable toAddress,
        uint256 amount,
        IERC20 tokenContract
    ) internal virtual {
        require(toAddress != address(0), "ERC20: transfer to the zero address");
        tokenContract.transfer(toAddress, amount);
        emit WithdrawERC20(toAddress, address(tokenContract), amount);
    }

    /**
     * @dev Withdraw an NFT.
     * @notice Emits WithdrawERC721
     * @param toAddress Where to send the NFT
     * @param tokenContract The NFT contract
     * @param tokenId The id of the NFT
     */
    function _withdrawERC721(
        address payable toAddress,
        uint256 tokenId,
        IERC721 tokenContract
    ) internal virtual {
        require(toAddress != address(0), "ERC721: transfer to the zero address");
        tokenContract.safeTransferFrom(address(this), toAddress, tokenId);
        emit WithdrawERC721(toAddress, address(tokenContract), tokenId);
    }

    /**
     * @dev Withdraw ERC777 tokens.
     * @notice Emits WithdrawERC777
     * @param toAddress Where to send the ERC777 tokens
     * @param tokenContract The ERC777 token contract
     * @param amount The amount withdrawn
     */
    function _withdrawERC777(
        address payable toAddress,
        uint256 amount,
        IERC777 tokenContract
    ) internal virtual {
        require(toAddress != address(0), "ERC777: transfer to the zero address");
        tokenContract.operatorSend(address(this), toAddress, amount, "", "");
        emit WithdrawERC777(toAddress, address(tokenContract), amount);
    }

    /**
     * @dev Withdraw semi-fungible tokens.
     * @notice Emits WithdrawERC1155
     * @param toAddress Where to send the semi-fungible tokens
     * @param tokenContract The semi-fungible token contract
     * @param tokenId The id of the semi-fungible tokens
     * @param amount The number of tokens withdrawn
     */
    function _withdrawERC1155(
        address payable toAddress,
        uint256 tokenId,
        uint256 amount,
        IERC1155 tokenContract
    ) internal virtual {
        require(toAddress != address(0), "ERC1155: transfer to the zero address");
        tokenContract.safeTransferFrom(
            address(this),
            toAddress,
            tokenId,
            amount,
            ""
        );
        emit WithdrawERC1155(
            toAddress,
            address(tokenContract),
            tokenId,
            amount
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.20;

import {IERC165} from "contracts/utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or
     *   {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
     * - The `operator` cannot be the address zero.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.20;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be
     * reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC777.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC777Token standard as defined in the EIP.
 *
 * This contract uses the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 registry standard] to let
 * token holders and recipients react to token movements by using setting implementers
 * for the associated interfaces in said registry. See {IERC1820Registry} and
 * {IERC1820Implementer}.
 */
interface IERC777 {
    /**
     * @dev Emitted when `amount` tokens are created by `operator` and assigned to `to`.
     *
     * Note that some additional user `data` and `operatorData` can be logged in the event.
     */
    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    /**
     * @dev Emitted when `operator` destroys `amount` tokens from `account`.
     *
     * Note that some additional user `data` and `operatorData` can be logged in the event.
     */
    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    /**
     * @dev Emitted when `operator` is made operator for `tokenHolder`.
     */
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    /**
     * @dev Emitted when `operator` is revoked its operator status for `tokenHolder`.
     */
    event RevokedOperator(address indexed operator, address indexed tokenHolder);

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the smallest part of the token that is not divisible. This
     * means all token operations (creation, movement and destruction) must have
     * amounts that are a multiple of this number.
     *
     * For most token contracts, this value will equal 1.
     */
    function granularity() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by an account (`owner`).
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * If send or receive hooks are registered for the caller and `recipient`,
     * the corresponding functions will be called with `data` and empty
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function send(address recipient, uint256 amount, bytes calldata data) external;

    /**
     * @dev Destroys `amount` tokens from the caller's account, reducing the
     * total supply.
     *
     * If a send hook is registered for the caller, the corresponding function
     * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata data) external;

    /**
     * @dev Returns true if an account is an operator of `tokenHolder`.
     * Operators can send and burn tokens on behalf of their owners. All
     * accounts are their own operator.
     *
     * See {operatorSend} and {operatorBurn}.
     */
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    /**
     * @dev Make an account an operator of the caller.
     *
     * See {isOperatorFor}.
     *
     * Emits an {AuthorizedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function authorizeOperator(address operator) external;

    /**
     * @dev Revoke an account's operator status for the caller.
     *
     * See {isOperatorFor} and {defaultOperators}.
     *
     * Emits a {RevokedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function revokeOperator(address operator) external;

    /**
     * @dev Returns the list of default operators. These accounts are operators
     * for all token holders, even if {authorizeOperator} was never called on
     * them.
     *
     * This list is immutable, but individual holders may revoke these via
     * {revokeOperator}, in which case {isOperatorFor} will return false.
     */
    function defaultOperators() external view returns (address[] memory);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * If send or receive hooks are registered for `sender` and `recipient`,
     * the corresponding functions will be called with `data` and
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * The caller must be an operator of `account`.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `data` and `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * - the caller must be an operator for `account`.
     */
    function operatorBurn(address account, uint256 amount, bytes calldata data, bytes calldata operatorData) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC777Recipient.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC777TokensRecipient standard as defined in the EIP.
 *
 * Accounts can be notified of {IERC777} tokens being sent to them by having a
 * contract implement this interface (contract holders can be their own
 * implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {IERC1820Implementer}.
 */
interface IERC777Recipient {
    /**
     * @dev Called by an {IERC777} token contract whenever tokens are being
     * moved or created into a registered account (`to`). The type of operation
     * is conveyed by `from` being the zero address or not.
     *
     * This call occurs _after_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the post-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.20;

import {IERC165} from "contracts/utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` amount of tokens of type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the value of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers a `value` amount of tokens of type `id` from `from` to `to`.
     *
     * WARNING: This function can potentially allow a reentrancy attack when transferring tokens
     * to an untrusted contract, when invoking {onERC1155Received} on the receiver.
     * Ensure to follow the checks-effects-interactions pattern and consider employing
     * reentrancy guards when interacting with untrusted contracts.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `value` amount.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     *
     * WARNING: This function can potentially allow a reentrancy attack when transferring tokens
     * to an untrusted contract, when invoking {onERC1155BatchReceived} on the receiver.
     * Ensure to follow the checks-effects-interactions pattern and consider employing
     * reentrancy guards when interacting with untrusted contracts.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `values` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.20;

import {IERC165} from "contracts/utils/introspection/IERC165.sol";

/**
 * @dev Interface that must be implemented by smart contracts in order to receive
 * ERC-1155 token transfers.
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/ERC165.sol)

pragma solidity ^0.8.20;

import {IERC165} from "contracts/utils/introspection/IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}