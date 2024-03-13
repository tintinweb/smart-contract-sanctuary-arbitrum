/**
 *Submitted for verification at Arbiscan.io on 2024-03-08
*/

// Sources flattened with hardhat v2.20.1 https://hardhat.org

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

// Original license: SPDX_License_Identifier: MIT
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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// Original license: SPDX_License_Identifier: MIT
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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
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


// File @openzeppelin/contracts-upgradeable/access/[email protected]

// Original license: SPDX_License_Identifier: MIT
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    /// @custom:storage-location erc7201:openzeppelin.storage.Ownable
    struct OwnableStorage {
        address _owner;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Ownable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant OwnableStorageLocation = 0x9016d09d72d40fdae2fd8ceac6b6234c7706214fd39c1cd1e609a0528c199300;

    function _getOwnableStorage() private pure returns (OwnableStorage storage $) {
        assembly {
            $.slot := OwnableStorageLocation
        }
    }

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
    function __Ownable_init(address initialOwner) internal onlyInitializing {
        __Ownable_init_unchained(initialOwner);
    }

    function __Ownable_init_unchained(address initialOwner) internal onlyInitializing {
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
        OwnableStorage storage $ = _getOwnableStorage();
        return $._owner;
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
        OwnableStorage storage $ = _getOwnableStorage();
        address oldOwner = $._owner;
        $._owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

// Original license: SPDX_License_Identifier: MIT
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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
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


// File contracts/interfaces/AggregatorInterface.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.20;

interface AggregatorInterface {
    function decimals() external view returns (uint8);

    function latestAnswer() external view returns (int256);
}


// File contracts/Presale.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.20;




contract Presale is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    // PresaleBalance = PresaleBuyAmount + PresaleBonus + ReferralBonus
    struct BalanceInfo {
        // total token were purchased
        uint256 total;
        // presale bonus
        uint256 bonus;
        // presale referral
        uint256 referral;
        // amount of unclaimed token
        uint256 claimable;
        // the last claim timestamp
        uint256 lastClaimTime;
        // mapping to NFTs own by address
        mapping(uint8 => uint256) ownNFTs;
    }

    // 500 / BASE_UNIT -> 5%
    uint256 private constant BASE_UNIT = 10_000;

    // $0.125 per token
    uint256 private constant PRESALE_TOKEN_PRICE = 125e15;

    // all presale amount will be vested
    // once the vesting period will be started, buyers can claim 10% their amount
    // remain 90% can be claimed after 90 days with 10% per 10 days
    uint256 private constant VESTING_CLAIM_PERIOD = 90 days;
    uint256 private constant VESTING_CLAIM_DURATION = 10 days;

    // referrer bonus
    // C refer B, B refer A, D refer C
    // D is level 1 of A, D earn 1% from A buy amount
    // C is level 2 of A, C earn 3% from A buy amount
    // B is level 3 of A, D earn 5% from A buy amount
    uint256 private constant REFERRER_BONUS_LEVEL_1 = 100; // 1%
    uint256 private constant REFERRER_BONUS_LEVEL_2 = 300; // 3%
    uint256 private constant REFERRER_BONUS_LEVEL_3 = 500; // 5%

    // => presale bonus base, first come, first serve
    // early earn more
    // the maximum bonus percentage is 15% in first 4 hours
    // this amount will be reduce 0.04% every 4 hours later
    // and in a period of 375 epochs ~ 2 months
    uint256 private constant BONUS_AMOUNT_MAX = 1500; // 15%
    uint256 private constant BONUS_EPOCH_PERIOD = 4 hours;
    uint256 private constant BONUS_EPOCH_REDUCTION = 4; // reduce 0.04 % every epoch

    // => presale bonus high roller
    // there are some fixed BONUS for high roller NFTs buy
    // buy high roller amount will receive both base and high-roller presale bonus
    uint256 private constant BONUS_HIGH_ROLLER_TARGET_J = 8000e18; // 8k token buy ~ $1000
    uint256 private constant BONUS_HIGH_ROLLER_AMOUNT_J = 1000; // 10% bonus
    uint256 private constant BONUS_HIGH_ROLLER_TARGET_Q = 24000e18; // 24k token buy ~ $3000
    uint256 private constant BONUS_HIGH_ROLLER_AMOUNT_Q = 1200; // 12% bonus
    uint256 private constant BONUS_HIGH_ROLLER_TARGET_K = 40000e18; // 40k token buy ~ $5000
    uint256 private constant BONUS_HIGH_ROLLER_AMOUNT_K = 1500; // 15% bonus
    uint256 private constant BONUS_HIGH_ROLLER_TARGET_JOKER = 80000e18; // 80k token buy ~ $10000
    uint256 private constant BONUS_HIGH_ROLLER_AMOUNT_JOKER = 2000; // 20% bonus

    // will be the PLAYBIT token
    address public token;

    // treasury address holds fund
    address public treasury;

    // total amount were raised in PLAYBIT token
    uint256 public totalRaised;
    // total amount were bonus in PLAYBIT token
    uint256 public totalBonus;
    // total amount were raised in US Dollar
    uint256 public totalRaisedUsd;

    // if startTime is zero, the presale is pending or ended, and can not buy
    uint256 public startPresaleTime;

    // time when all vesting are started
    // once this value is set, buyers can start their vesting period
    // admin should set this value 24h after presale end
    uint256 public startVestingTime;

    // mapping token with a ChainLink price feed
    mapping(address => bool) public stablecoins;
    mapping(address => address) public tokenPriceFeeds;

    // token balance info of every address
    mapping(address => BalanceInfo) public balances;

    // referrer map tree
    // A => B, B is the referrer address of A
    // B earn bonus when A buy token
    mapping(address => address) public referrers;

    // revert when the startPresaleTime was not set
    error InvalidTime();

    // revert when the pay token was not supported
    // or the token price feed address was not found
    error InvalidPayToken();

    event PresaleBuy(
        address indexed buyer,
        address indexed buyToken,
        uint256 amountToken,
        uint256 amountBuyToken,
        uint256 amountUsd
    );
    event PresaleBonus(address indexed buyer, uint256 buyAmount, uint256 bonusAmount);
    event ReferralBonus(
        address indexed buyer,
        address indexed referrer,
        uint256 buyAmount,
        uint8 bonusLevel,
        uint256 bonusAmount
    );
    event NftBonus(address indexed buyer, uint8 indexed nft);

    function initialize(address _treasury) external initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();

        treasury = _treasury;
    }

    modifier validTime() {
        if (startPresaleTime == 0 || block.timestamp < startPresaleTime) {
            revert InvalidTime();
        }

        _;
    }

    receive() external payable {}

    // always return value with 1e18 decimals
    function getTokenPrice(address _token) public view returns (uint256) {
        if (stablecoins[_token]) {
            return 1e18;
        }

        if (tokenPriceFeeds[_token] == address(0)) {
            return 0;
        }

        uint8 numberOfDecimals = AggregatorInterface(tokenPriceFeeds[_token]).decimals();
        int256 answer = AggregatorInterface(tokenPriceFeeds[_token]).latestAnswer();

        // convert to 18 decimals
        return (uint256(answer) * 1e18) / (10 ** numberOfDecimals);
    }

    function getTokenAmountWad(address _token, uint256 _amount) internal view returns (uint256) {
        if (_token == address(0)) {
            return _amount;
        }

        // convert token amount to 1e18
        uint8 tokenDecimals = IERC20Metadata(_token).decimals();
        return (_amount * 1e18) / (10 ** (tokenDecimals));
    }

    function getBonusPercentage() public view returns (uint256) {
        uint256 timeElapsed = block.timestamp > startPresaleTime && startPresaleTime > 0
            ? block.timestamp - startPresaleTime
            : 0;
        uint256 numberOfEpochPassed = timeElapsed / BONUS_EPOCH_PERIOD;
        uint256 reductionAmount = BONUS_EPOCH_REDUCTION * numberOfEpochPassed;
        return BONUS_AMOUNT_MAX > reductionAmount ? BONUS_AMOUNT_MAX - reductionAmount : 0;
    }

    // _buyAmount in PLAYBIT
    function getBonusAmount(uint256 _buyAmount) public view returns (uint256) {
        uint256 bonusPercentage = getBonusPercentage();
        uint256 bonusAmount = (_buyAmount * bonusPercentage) / BASE_UNIT;

        if (_buyAmount >= BONUS_HIGH_ROLLER_TARGET_JOKER) {
            bonusAmount += (_buyAmount * BONUS_HIGH_ROLLER_AMOUNT_JOKER) / BASE_UNIT;
        } else if (_buyAmount >= BONUS_HIGH_ROLLER_TARGET_K) {
            bonusAmount += (_buyAmount * BONUS_HIGH_ROLLER_AMOUNT_K) / BASE_UNIT;
        } else if (_buyAmount >= BONUS_HIGH_ROLLER_TARGET_Q) {
            bonusAmount += (_buyAmount * BONUS_HIGH_ROLLER_AMOUNT_Q) / BASE_UNIT;
        } else if (_buyAmount >= BONUS_HIGH_ROLLER_TARGET_J) {
            bonusAmount += (_buyAmount * BONUS_HIGH_ROLLER_AMOUNT_J) / BASE_UNIT;
        }

        return bonusAmount;
    }

    function getAmountOut(
        address _payToken,
        uint256 _payAmount
    ) public view returns (uint256 _amount, uint256 _bonus) {
        uint256 tokenPrice = getTokenPrice(_payToken);

        // convert token amount to 1e18
        uint256 amountWad = getTokenAmountWad(_payToken, _payAmount);

        // 1e18 * 1e18 / 1e18 = 1e18
        _amount = (amountWad * tokenPrice) / PRESALE_TOKEN_PRICE;

        _bonus = getBonusAmount(_amount);
    }

    function getBalances(
        address _buyer
    ) public view returns (uint256 _bought, uint256 _bonus, uint256 _referral) {
        _bonus = balances[_buyer].bonus;
        _referral = balances[_buyer].referral;
        _bought = balances[_buyer].total - balances[_buyer].bonus - balances[_buyer].referral;
    }

    function getNFTs(
        address _buyer
    ) public view returns (uint256 _nftJ, uint256 _nftQ, uint256 _nftK, uint256 _nftJoker) {
        _nftJ = balances[_buyer].ownNFTs[0];
        _nftQ = balances[_buyer].ownNFTs[1];
        _nftK = balances[_buyer].ownNFTs[2];
        _nftJoker = balances[_buyer].ownNFTs[3];
    }

    function getReferrers(
        address _buyer
    ) public view returns (address _level1, address _level2, address _level3) {
        _level3 = referrers[_buyer];
        _level2 = referrers[_level3];
        _level1 = referrers[_level2];
    }

    // support purchase token with input ERC20 tokens
    function buy(
        address _token,
        uint256 _amountTokenRaw,
        address _referrer
    ) external payable nonReentrant validTime {
        uint256 tokenPrice = getTokenPrice(_token);
        if (tokenPrice == 0) {
            revert InvalidPayToken();
        }

        (uint256 amountOut, uint256 amountBonus) = getAmountOut(_token, _amountTokenRaw);
        if (amountOut > 0) {
            uint256 amountUsd = (tokenPrice * getTokenAmountWad(_token, _amountTokenRaw)) / 1e18;

            // keep track total raised
            totalRaised = totalRaised + amountOut;
            totalBonus = totalBonus + amountBonus;
            totalRaisedUsd = totalRaisedUsd + amountUsd;

            // update referrer when buyer actually buy token
            if (_referrer != msg.sender) {
                referrers[msg.sender] = _referrer;
            }

            // => handle buy amount
            if (_token != address(0)) {
                // transfer token into this contract
                IERC20(_token).transferFrom(msg.sender, treasury, _amountTokenRaw);
            } else {
                // transfer function does not work with Gnosis Safe as treasury address
                (bool success, ) = treasury.call{value: _amountTokenRaw}("");
                if (!success) {
                    // if the treasury failed to receive fund
                    // send fund to the dev address
                    payable(owner()).transfer(_amountTokenRaw);
                }
            }

            balances[msg.sender].total = balances[msg.sender].total + amountOut;
            balances[msg.sender].claimable = balances[msg.sender].claimable + amountOut;

            emit PresaleBuy(msg.sender, _token, amountOut, _amountTokenRaw, amountUsd);

            // => handle presale bonus
            balances[msg.sender].total = balances[msg.sender].total + amountBonus;
            balances[msg.sender].claimable = balances[msg.sender].claimable + amountBonus;
            balances[msg.sender].bonus = balances[msg.sender].bonus + amountBonus;

            emit PresaleBonus(msg.sender, amountOut, amountBonus);

            // => handle NFT bonus
            if (amountOut >= BONUS_HIGH_ROLLER_TARGET_JOKER) {
                balances[msg.sender].ownNFTs[3] += 1;
                emit NftBonus(msg.sender, 3);
            } else if (amountOut >= BONUS_HIGH_ROLLER_TARGET_K) {
                balances[msg.sender].ownNFTs[2] += 1;
                emit NftBonus(msg.sender, 2);
            } else if (amountOut >= BONUS_HIGH_ROLLER_TARGET_Q) {
                balances[msg.sender].ownNFTs[1] += 1;
                emit NftBonus(msg.sender, 1);
            } else if (amountOut >= BONUS_HIGH_ROLLER_TARGET_J) {
                balances[msg.sender].ownNFTs[0] += 1;
                emit NftBonus(msg.sender, 0);
            }

            // => handle referrers bonus
            (address _level1, address _level2, address _level3) = getReferrers(msg.sender);
            if (_level1 != address(0)) {
                (uint256 boughtAmount, , ) = getBalances(_level1);
                uint256 amountToGetBonusReferral = boughtAmount > amountOut
                    ? amountOut
                    : boughtAmount;

                if (amountToGetBonusReferral > 0) {
                    uint256 amountLevel1 = (amountToGetBonusReferral * REFERRER_BONUS_LEVEL_1) /
                        BASE_UNIT;
                    balances[_level1].total = balances[_level1].total + amountLevel1;
                    balances[_level1].referral = balances[_level1].referral + amountLevel1;
                    balances[_level1].claimable = balances[_level1].claimable + amountLevel1;
                    emit ReferralBonus(msg.sender, _level1, amountOut, 1, amountLevel1);
                }
            }
            if (_level2 != address(0)) {
                (uint256 boughtAmount, , ) = getBalances(_level2);
                uint256 amountToGetBonusReferral = boughtAmount > amountOut
                    ? amountOut
                    : boughtAmount;

                if (amountToGetBonusReferral > 0) {
                    uint256 amountLevel2 = (amountToGetBonusReferral * REFERRER_BONUS_LEVEL_2) /
                        BASE_UNIT;
                    balances[_level2].total = balances[_level2].total + amountLevel2;
                    balances[_level2].referral = balances[_level2].referral + amountLevel2;
                    balances[_level2].claimable = balances[_level2].claimable + amountLevel2;
                    emit ReferralBonus(msg.sender, _level2, amountOut, 2, amountLevel2);
                }
            }
            if (_level3 != address(0)) {
                (uint256 boughtAmount, , ) = getBalances(_level3);
                uint256 amountToGetBonusReferral = boughtAmount > amountOut
                    ? amountOut
                    : boughtAmount;

                if (amountToGetBonusReferral > 0) {
                    uint256 amountLevel3 = (amountToGetBonusReferral * REFERRER_BONUS_LEVEL_3) /
                        BASE_UNIT;
                    balances[_level3].total = balances[_level3].total + amountLevel3;
                    balances[_level3].referral = balances[_level3].referral + amountLevel3;
                    balances[_level3].claimable = balances[_level3].claimable + amountLevel3;
                    emit ReferralBonus(msg.sender, _level3, amountOut, 3, amountLevel3);
                }
            }
        }
    }

    function setPresaleConfigs(
        address _token,
        uint256 _startPresaleTime,
        uint256 _startVestingTime
    ) external onlyOwner {
        token = _token;

        startPresaleTime = _startPresaleTime;
        startVestingTime = _startVestingTime;
    }

    function setTokenPriceFeed(address _token, address _chainlinkFeed) external onlyOwner {
        tokenPriceFeeds[_token] = _chainlinkFeed;
    }

    function setTokenStablecoin(address _token, bool _isStablecoin) external onlyOwner {
        stablecoins[_token] = _isStablecoin;
    }
}