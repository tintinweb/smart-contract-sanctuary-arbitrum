/**
 *Submitted for verification at Arbiscan.io on 2024-03-14
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
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
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
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

// File: @openzeppelin/contracts/utils/Pausable.sol


// OpenZeppelin Contracts (last updated v5.0.0) (utils/Pausable.sol)

pragma solidity ^0.8.20;


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
    bool private _paused;

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev The operation failed because the contract is paused.
     */
    error EnforcedPause();

    /**
     * @dev The operation failed because the contract is not paused.
     */
    error ExpectedPause();

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
        if (paused()) {
            revert EnforcedPause();
        }
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if (!paused()) {
            revert ExpectedPause();
        }
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

// File: TokenMigration.sol


pragma solidity ^0.8.20;




interface IERC20 {
    function transfer(address to, uint256 amount) external;

    function burnFrom(address account, uint256 value) external;

    function balanceOf(address account) external returns (uint256);

    function mint(address account, uint256 amount) external;
}

contract StimMigAndBridge is Ownable, Pausable, ReentrancyGuard {
    event MigrationComplete(
        address indexed account,
        uint256 indexed amountIn,
        uint256 indexed amountOut
    );

    event AddBridgeQueue(uint256, address, uint256, uint256);
    event BridgeQueueProcessed(uint256[]);
    event BridgeEvent(uint256, uint256, address, uint256);
    event AddMigrationQueue(
        address indexed account,
        uint256 indexed amount,
        uint256 indexed expectedMint
    );

    struct BridgeItem {
        uint256 id;
        address user;
        uint256 amount;
        uint256 fromChain;
    }

    struct QueueItem {
        uint256 id;
        address user;
        uint256 amount;
        uint256 toMint;
        bool processed;
    }

    struct MigrationItem {
        uint256 id;
        address user;
        uint256 amount;
        uint256 toMint;
        bool processed;
    }

    constructor(address initialOwner, bool _migrationEnabled, bool _bridgeEnabled)
        Ownable(initialOwner)
    {
        migrationEnabled = _migrationEnabled;
        bridgeEnabled = _bridgeEnabled;
    }

    IERC20 public FUZZ = IERC20(0x58E50e24d5160DEf294B6b6410d12C597054B79E);
    IERC20 public HFUZZ = IERC20(0x984b969a8E82F5cE1121CeB03f96fF5bB3f71FEe);
    IERC20 public STIM = IERC20(0x2844B73F319eA341B6616f029f37fe3A3E812328);

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function getMigrationAmount(uint256 amount) public pure returns (uint256) {
        return amount / 20;
    }

    function rescueToken(address _token, uint256 _amount) external onlyOwner {
        if (_amount == 0) {
            IERC20(_token).transfer(
                owner(),
                IERC20(_token).balanceOf(address(this))
            );
        } else {
            IERC20(_token).transfer(owner(), _amount);
        }
    }

    mapping(uint256 => QueueItem) public BridgeQueue;
    mapping(uint256 => MigrationItem) public MigrationQueue;
    uint256 public bridgeCount;
    uint256 public migrationCount;
    uint256 public bridgeProcessingNonce;
    uint256 public migrationProcessingNonce;
    uint256 public fromBridgeFee = 25 ether;
    mapping(address => uint256) public totalMigrated;
    uint256 public totalAmountMigrated;
    bool public migrationEnabled;
    bool public bridgeEnabled;

    function setMigrationStatus() external onlyOwner {
        migrationEnabled = !migrationEnabled;
    }

    function setBridgeStatus() external onlyOwner {
        bridgeEnabled = !bridgeEnabled;
    }

    function setBridgeFee(uint256 _fee) external onlyOwner {
        fromBridgeFee = _fee;
    }

    function itemsToMigrate() public view returns (bool) {
        if (bridgeProcessingNonce == migrationCount) {
            return false;
        } else {
            return true;
        }
    }

    function itemsToBridge() public view returns (bool) {
        if (bridgeProcessingNonce == bridgeCount) {
            return false;
        } else {
            return true;
        }
    }

    function EnterMigrationQueue(uint256 amount)
        public
        whenNotPaused
        nonReentrant
    {
        require(amount >= 20, "req: 20:1");
        require(migrationEnabled, "Mig:NE");
        uint256 toMint = amount / 20;
        FUZZ.burnFrom(msg.sender, amount);
        MigrationItem memory item = MigrationItem(
            migrationCount,
            msg.sender,
            amount,
            toMint,
            false
        );
        MigrationQueue[migrationCount] = item;
        emit AddMigrationQueue(msg.sender, amount, toMint);
    }

    function EnterBridgeQueue(address user, uint256 amount)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        require(bridgeEnabled, "B:NE");
        require(msg.value == fromBridgeFee, "Bridge fee not paid.");
        payable(owner()).transfer(fromBridgeFee);
        HFUZZ.burnFrom(msg.sender, amount);
        uint256 toMint = amount / 20;
        QueueItem memory item = QueueItem(
            bridgeCount,
            user,
            amount,
            toMint,
            false
        );
        BridgeQueue[bridgeCount] = item;
        bridgeCount++;
        emit AddBridgeQueue(item.id, item.user, item.amount, item.toMint);
    }

    function BridgeAndMigrate(BridgeItem[] memory bridgeArray)
        external
        onlyOwner
    {
        for (uint256 i; i < bridgeArray.length; i++) {
            uint256 toMint = bridgeArray[i].amount / 20;
            STIM.transfer(bridgeArray[i].user, toMint);
            emit BridgeEvent(
                bridgeArray[i].id,
                bridgeArray[i].fromChain,
                bridgeArray[i].user,
                bridgeArray[i].amount
            );
        }
    }

    function ProcessMigrationQueue(uint256[] memory itemsToProcess)
        external
        onlyOwner
    {
        for (uint256 i; i < itemsToProcess.length; i++) {
            MigrationItem memory item = MigrationQueue[itemsToProcess[i]];
            if (!item.processed) {
                STIM.transfer(item.user, item.toMint);
                totalMigrated[item.user] += item.amount;
                totalAmountMigrated += item.amount;
            }
            emit MigrationComplete(item.user, item.amount, item.toMint);
        }
    }

    function ProcessBridgeQueue(uint256[] memory itemsToProcess)
        external
        onlyOwner
    {
        for (uint256 i; i < itemsToProcess.length; i++) {
            uint256 x = itemsToProcess[i];
            if (!BridgeQueue[x].processed) {
                BridgeQueue[x].processed = true;
                bridgeProcessingNonce++;
            }
        }
        emit BridgeQueueProcessed(itemsToProcess);
    }

    function RejectMigrationRequest(uint256[] memory itemsToProcess)
        external
        onlyOwner
    {
        for (uint256 i; i < itemsToProcess.length; i++) {
            uint256 x = itemsToProcess[i];
            uint256 fee = MigrationQueue[x].amount / 10;
            uint256 amount = MigrationQueue[x].amount - fee;
            FUZZ.mint(MigrationQueue[x].user, amount);
            MigrationQueue[x].processed = true;
        }
    }

    function RejectBridgeRequest(uint256[] memory itemsToProcess)
        external
        onlyOwner
    {
        for (uint256 i; i < itemsToProcess.length; i++) {
            uint256 x = itemsToProcess[i];
            uint256 fee = BridgeQueue[x].amount / 10;
            uint256 amount = BridgeQueue[x].amount - fee;
            HFUZZ.mint(BridgeQueue[x].user, amount);
            BridgeQueue[x].processed = true;
        }
    }

    function ShowBridgeRequest(uint256 _id)
        public
        view
        returns (QueueItem memory)
    {
        return BridgeQueue[_id];
    }

    function ShowMigrationRequest(uint256 _id)
        public
        view
        returns (MigrationItem memory)
    {
        return MigrationQueue[_id];
    }
}