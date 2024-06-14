// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.25;

/// @notice Thrown if the supplied address is a zero address where it is not allowed
error ZeroAddressNotAllowed();

/// @notice Thrown if the supplied value is 0 where it is not allowed
error ZeroValueNotAllowed();

/// @notice Checks if the provided address is nonzero, reverts otherwise
/// @param address_ Address to check
/// @custom:error ZeroAddressNotAllowed is thrown if the provided address is a zero address
function ensureNonzeroAddress(address address_) pure {
    if (address_ == address(0)) {
        revert ZeroAddressNotAllowed();
    }
}

/// @notice Checks if the provided value is nonzero, reverts otherwise
/// @param value_ Value to check
/// @custom:error ZeroValueNotAllowed is thrown if the provided value is 0
function ensureNonzeroValue(uint256 value_) pure {
    if (value_ == 0) {
        revert ZeroValueNotAllowed();
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.25;
import { ensureNonzeroAddress } from "@venusprotocol/solidity-utilities/contracts/validators.sol";

/**
 * @title TimelockV8
 * @author Venus
 * @notice The Timelock contract using solidity V8.
 * This contract also differs from the original timelock because it has a virtual function to get minimum delays
 * and allow test deployments to override the value.
 */
contract TimelockV8 {
    /// @notice Required period to execute a proposal transaction
    uint256 private constant DEFAULT_GRACE_PERIOD = 14 days;

    /// @notice Minimum amount of time a proposal transaction must be queued
    uint256 private constant DEFAULT_MINIMUM_DELAY = 2 days;

    /// @notice Maximum amount of time a proposal transaction must be queued
    uint256 private constant DEFAULT_MAXIMUM_DELAY = 30 days;

    /// @notice Timelock admin authorized to queue and execute transactions
    address public admin;

    /// @notice Account proposed as the next admin
    address public pendingAdmin;

    /// @notice Period for a proposal transaction to be queued
    uint256 public delay;

    /// @notice Mapping of queued transactions
    mapping(bytes32 => bool) public queuedTransactions;

    /// @notice Event emitted when a new admin is accepted
    event NewAdmin(address indexed oldAdmin, address indexed newAdmin);

    /// @notice Event emitted when a new admin is proposed
    event NewPendingAdmin(address indexed newPendingAdmin);

    /// @notice Event emitted when a new delay is proposed
    event NewDelay(uint256 indexed oldDelay, uint256 indexed newDelay);

    /// @notice Event emitted when a proposal transaction has been cancelled
    event CancelTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );

    /// @notice Event emitted when a proposal transaction has been executed
    event ExecuteTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );

    /// @notice Event emitted when a proposal transaction has been queued
    event QueueTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );

    constructor(address admin_, uint256 delay_) {
        require(delay_ >= MINIMUM_DELAY(), "Timelock::constructor: Delay must exceed minimum delay.");
        require(delay_ <= MAXIMUM_DELAY(), "Timelock::setDelay: Delay must not exceed maximum delay.");
        ensureNonzeroAddress(admin_);

        admin = admin_;
        delay = delay_;
    }

    fallback() external payable {}

    /**
     * @notice Setter for the transaction queue delay
     * @param delay_ The new delay period for the transaction queue
     * @custom:access Sender must be Timelock itself
     * @custom:event Emit NewDelay with old and new delay
     */
    function setDelay(uint256 delay_) public {
        require(msg.sender == address(this), "Timelock::setDelay: Call must come from Timelock.");
        require(delay_ >= MINIMUM_DELAY(), "Timelock::setDelay: Delay must exceed minimum delay.");
        require(delay_ <= MAXIMUM_DELAY(), "Timelock::setDelay: Delay must not exceed maximum delay.");
        emit NewDelay(delay, delay_);
        delay = delay_;
    }

    /**
     * @notice Return grace period
     * @return The duration of the grace period, specified as a uint256 value.
     */
    function GRACE_PERIOD() public view virtual returns (uint256) {
        return DEFAULT_GRACE_PERIOD;
    }

    /**
     * @notice Return required minimum delay
     * @return Minimum delay
     */
    function MINIMUM_DELAY() public view virtual returns (uint256) {
        return DEFAULT_MINIMUM_DELAY;
    }

    /**
     * @notice Return required maximum delay
     * @return Maximum delay
     */
    function MAXIMUM_DELAY() public view virtual returns (uint256) {
        return DEFAULT_MAXIMUM_DELAY;
    }

    /**
     * @notice Method for accepting a proposed admin
     * @custom:access Sender must be pending admin
     * @custom:event Emit NewAdmin with old and new admin
     */
    function acceptAdmin() public {
        require(msg.sender == pendingAdmin, "Timelock::acceptAdmin: Call must come from pendingAdmin.");
        emit NewAdmin(admin, msg.sender);
        admin = msg.sender;
        pendingAdmin = address(0);
    }

    /**
     * @notice Method to propose a new admin authorized to call timelock functions. This should be the Governor Contract
     * @param pendingAdmin_ Address of the proposed admin
     * @custom:access Sender must be Timelock contract itself or admin
     * @custom:event Emit NewPendingAdmin with new pending admin
     */
    function setPendingAdmin(address pendingAdmin_) public {
        require(
            msg.sender == address(this) || msg.sender == admin,
            "Timelock::setPendingAdmin: Call must come from Timelock."
        );
        ensureNonzeroAddress(pendingAdmin_);
        pendingAdmin = pendingAdmin_;

        emit NewPendingAdmin(pendingAdmin);
    }

    /**
     * @notice Called for each action when queuing a proposal
     * @param target Address of the contract with the method to be called
     * @param value Native token amount sent with the transaction
     * @param signature Signature of the function to be called
     * @param data Arguments to be passed to the function when called
     * @param eta Timestamp after which the transaction can be executed
     * @return Hash of the queued transaction
     * @custom:access Sender must be admin
     * @custom:event Emit QueueTransaction
     */
    function queueTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) public returns (bytes32) {
        require(msg.sender == admin, "Timelock::queueTransaction: Call must come from admin.");
        require(
            eta >= getBlockTimestamp() + delay,
            "Timelock::queueTransaction: Estimated execution block must satisfy delay."
        );

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        require(!queuedTransactions[txHash], "Timelock::queueTransaction: transaction already queued.");
        queuedTransactions[txHash] = true;

        emit QueueTransaction(txHash, target, value, signature, data, eta);
        return txHash;
    }

    /**
     * @notice Called to cancel a queued transaction
     * @param target Address of the contract with the method to be called
     * @param value Native token amount sent with the transaction
     * @param signature Signature of the function to be called
     * @param data Arguments to be passed to the function when called
     * @param eta Timestamp after which the transaction can be executed
     * @custom:access Sender must be admin
     * @custom:event Emit CancelTransaction
     */
    function cancelTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) public {
        require(msg.sender == admin, "Timelock::cancelTransaction: Call must come from admin.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        require(queuedTransactions[txHash], "Timelock::cancelTransaction: transaction is not queued yet.");
        delete (queuedTransactions[txHash]);

        emit CancelTransaction(txHash, target, value, signature, data, eta);
    }

    /**
     * @notice Called to execute a queued transaction
     * @param target Address of the contract with the method to be called
     * @param value Native token amount sent with the transaction
     * @param signature Signature of the function to be called
     * @param data Arguments to be passed to the function when called
     * @param eta Timestamp after which the transaction can be executed
     * @return Result of function call
     * @custom:access Sender must be admin
     * @custom:event Emit ExecuteTransaction
     */
    function executeTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) public returns (bytes memory) {
        require(msg.sender == admin, "Timelock::executeTransaction: Call must come from admin.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        require(queuedTransactions[txHash], "Timelock::executeTransaction: Transaction hasn't been queued.");
        require(getBlockTimestamp() >= eta, "Timelock::executeTransaction: Transaction hasn't surpassed time lock.");
        require(getBlockTimestamp() <= eta + GRACE_PERIOD(), "Timelock::executeTransaction: Transaction is stale.");

        delete (queuedTransactions[txHash]);

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{ value: value }(callData);
        require(success, "Timelock::executeTransaction: Transaction execution reverted.");

        emit ExecuteTransaction(txHash, target, value, signature, data, eta);

        return returnData;
    }

    /**
     * @notice Returns the current block timestamp
     * @return The current block timestamp
     */
    function getBlockTimestamp() internal view returns (uint256) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp;
    }
}