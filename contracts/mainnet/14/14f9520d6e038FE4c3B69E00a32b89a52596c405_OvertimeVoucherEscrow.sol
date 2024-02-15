// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

// internal
import "../../utils/proxy/solidity-0.8.0/ProxyReentrancyGuard.sol";
import "../../utils/proxy/solidity-0.8.0/ProxyOwned.sol";

import "./OvertimeVoucher.sol";

contract OvertimeVoucherEscrow is Initializable, ProxyOwned, PausableUpgradeable, ProxyReentrancyGuard {
    /* ========== LIBRARIES ========== */
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* ========== STATE VARIABLES ========== */

    /// @return The sUSD contract used for payment
    IERC20Upgradeable public sUSD;

    /// @return OvertimeVoucher used for minting tokens
    OvertimeVoucher public overtimeVoucher;

    /// @return Address whitelisted for claiming voucher in claiming period
    mapping(uint => mapping(address => bool)) public whitelistedAddressesPerPeriod;

    /// @return Address already claimed voucher in claiming period
    mapping(uint => mapping(address => bool)) public addressClaimedVoucherPerPeriod;

    /// @return Amount of sUSD in voucher to be minted/claimed
    uint public voucherAmount;

    /// @return Timestamp until claiming period is open
    mapping(uint => uint) public periodEnd;

    /// @return Current claiming period number
    uint public period;

    /* ========== CONSTRUCTOR ========== */
    function initialize(
        address _owner,
        IERC20Upgradeable _sUSD,
        address _overtimeVoucher,
        address[] calldata _whitelistedAddresses,
        uint _voucherAmount,
        uint _periodEnd
    ) external initializer {
        setOwner(_owner);
        initNonReentrant();
        sUSD = _sUSD;
        overtimeVoucher = OvertimeVoucher(_overtimeVoucher);
        voucherAmount = _voucherAmount;

        period = 1;
        periodEnd[1] = _periodEnd;

        setWhitelistedAddresses(_whitelistedAddresses, true);

        sUSD.approve(_overtimeVoucher, type(uint256).max);
    }

    /// @notice Mints OvertimeVoucher and sends it to the user if given address
    /// is whitelisted and claiming period is not closed yet
    function claimVoucher() external canClaim {
        overtimeVoucher.mint(msg.sender, voucherAmount);
        addressClaimedVoucherPerPeriod[period][msg.sender] = true;

        emit VoucherClaimed(msg.sender, voucherAmount);
    }

    /* ========== SETTERS ========== */

    /// @notice sets address of sUSD contract
    /// @param _address sUSD address
    function setsUSD(address _address) external onlyOwner {
        sUSD = IERC20Upgradeable(_address);
        emit SetsUSD(_address);
    }

    /// @notice sets address of OvertimeVoucher contract
    /// @param _address OvertimeVoucher address
    function setOvertimeVoucher(address _address) external onlyOwner {
        overtimeVoucher = OvertimeVoucher(_address);
        emit SetOvertimeVoucher(_address);
    }

    /// @notice setWhitelistedAddresses enables whitelist addresses of given array
    /// @param _whitelistedAddresses array of whitelisted addresses
    /// @param _flag adding or removing from whitelist (true: add, false: remove)
    function setWhitelistedAddresses(address[] calldata _whitelistedAddresses, bool _flag) public onlyOwner {
        require(_whitelistedAddresses.length > 0, "Whitelisted addresses cannot be empty");
        for (uint i = 0; i < _whitelistedAddresses.length; i++) {
            if (whitelistedAddressesPerPeriod[period][_whitelistedAddresses[i]] != _flag) {
                whitelistedAddressesPerPeriod[period][_whitelistedAddresses[i]] = _flag;
                emit WhitelistChanged(_whitelistedAddresses[i], period, _flag);
            }
        }
    }

    /// @notice sets amount in voucher to be claimed/minted
    /// @param _voucherAmount sUSD amount
    function setVoucherAmount(uint _voucherAmount) external onlyOwner {
        voucherAmount = _voucherAmount;
        emit VoucherAmountChanged(_voucherAmount);
    }

    /// @notice sets timestamp until claiming is open
    /// @param _periodEnd new timestamp
    /// @param _startNextPeriod extend current period if false, start next period if true
    function setPeriodEndTimestamp(uint _periodEnd, bool _startNextPeriod) external onlyOwner {
        require(_periodEnd > periodEnd[period], "Invalid timestamp");
        if (_startNextPeriod) {
            period += 1;
        }

        periodEnd[period] = _periodEnd;

        emit PeriodEndTimestampChanged(_periodEnd);
    }

    /* ========== VIEWS ========== */

    /// @notice checks if address is whitelisted
    /// @param _address address to be checked
    /// @return bool
    function isWhitelistedAddress(address _address) public view returns (bool) {
        return whitelistedAddressesPerPeriod[period][_address];
    }

    /// @notice checks if current claiming period is closed
    /// @return bool
    function claimingPeriodEnded() public view returns (bool) {
        return block.timestamp >= periodEnd[period];
    }

    /// @notice retrieveSUSDAmount retrieves sUSD from this contract
    /// @param amount how much to retrieve
    function retrieveSUSDAmount(uint amount) external onlyOwner {
        sUSD.transfer(msg.sender, amount);
    }

    /* ========== MODIFIERS ========== */

    modifier canClaim() {
        require(!claimingPeriodEnded(), "Claiming period ended");
        require(isWhitelistedAddress(msg.sender), "Invalid address");
        require(!addressClaimedVoucherPerPeriod[period][msg.sender], "Address has already claimed voucher");

        require(sUSD.balanceOf(address(this)) >= voucherAmount, "Not enough sUSD in the contract");
        _;
    }

    /* ========== EVENTS ========== */

    event WhitelistChanged(address _address, uint period, bool _flag);
    event SetsUSD(address _address);
    event SetOvertimeVoucher(address _address);
    event VoucherAmountChanged(uint _amount);
    event PeriodEndTimestampChanged(uint _timestamp);
    event VoucherClaimed(address _address, uint _amount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the `nonReentrant` modifier
 * available, which can be aplied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
contract ProxyReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;
    bool private _initialized;

    function initNonReentrant() public {
        require(!_initialized, "Already initialized");
        _initialized = true;
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Clone of syntetix contract without constructor
contract ProxyOwned {
    address public owner;
    address public nominatedOwner;
    bool private _initialized;
    bool private _transferredAtInit;

    function setOwner(address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        require(!_initialized, "Already initialized, use nominateNewOwner");
        _initialized = true;
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    function transferOwnershipAtInit(address proxyAddress) external onlyOwner {
        require(proxyAddress != address(0), "Invalid address");
        require(!_transferredAtInit, "Already transferred");
        owner = proxyAddress;
        _transferredAtInit = true;
        emit OwnerChanged(owner, proxyAddress);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-4.4.1/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-4.4.1/utils/Counters.sol";
import "@openzeppelin/contracts-4.4.1/access/Ownable.sol";
import "@openzeppelin/contracts-4.4.1/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts-4.4.1/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-4.4.1/token/ERC20/utils/SafeERC20.sol";

import "../../interfaces/ISportsAMM.sol";
import "../../interfaces/IParlayMarketsAMM.sol";
import "../../interfaces/ISportPositionalMarket.sol";
import "../../interfaces/IPosition.sol";

contract OvertimeVoucher is ERC721URIStorage, Ownable {
    /* ========== LIBRARIES ========== */

    using Counters for Counters.Counter;
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    Counters.Counter private _tokenIds;

    string public _name = "Overtime Voucher";
    string public _symbol = "OVER";
    bool public paused = false;
    string public tokenURIFive;
    string public tokenURITen;
    string public tokenURITwenty;
    string public tokenURIFifty;
    string public tokenURIHundred;
    string public tokenURITwoHundred;
    string public tokenURIFiveHundred;
    string public tokenURIThousand;

    ISportsAMM public sportsAMM;
    IParlayMarketsAMM public parlayAMM;

    uint public multiplier;

    IERC20 public sUSD;
    mapping(uint => uint) public amountInVoucher;

    /* ========== CONSTANTS ========== */
    uint private constant ONE = 1;
    uint private constant FIVE = 5;
    uint private constant TEN = 10;
    uint private constant TWENTY = 20;
    uint private constant FIFTY = 50;
    uint private constant HUNDRED = 100;
    uint private constant TWO_HUNDRED = 200;
    uint private constant FIVE_HUNDRED = 500;
    uint private constant THOUSAND = 1000;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _sUSD,
        string memory _tokenURIFive,
        string memory _tokenURITen,
        string memory _tokenURITwenty,
        string memory _tokenURIFifty,
        string memory _tokenURIHundred,
        string memory _tokenURITwoHundred,
        string memory _tokenURIFiveHundred,
        string memory _tokenURIThousand,
        address _sportsamm,
        address _parlayAMM
    ) ERC721(_name, _symbol) {
        sUSD = IERC20(_sUSD);
        tokenURIFive = _tokenURIFive;
        tokenURITen = _tokenURITen;
        tokenURITwenty = _tokenURITwenty;
        tokenURIFifty = _tokenURIFifty;
        tokenURIHundred = _tokenURIHundred;
        tokenURITwoHundred = _tokenURITwoHundred;
        tokenURIFiveHundred = _tokenURIFiveHundred;
        tokenURIThousand = _tokenURIThousand;
        sportsAMM = ISportsAMM(_sportsamm);
        sUSD.approve(_sportsamm, type(uint256).max);
        parlayAMM = IParlayMarketsAMM(_parlayAMM);
        sUSD.approve(_parlayAMM, type(uint256).max);
    }

    /* ========== TRV ========== */

    function mintBatch(address[] calldata recipients, uint amount) external returns (uint[] memory newItemId) {
        require(!paused, "Cant mint while paused");

        require(_checkAmount(amount), "Invalid amount");

        sUSD.safeTransferFrom(msg.sender, address(this), (recipients.length * amount));
        newItemId = new uint[](recipients.length);
        for (uint i = 0; i < recipients.length; i++) {
            _tokenIds.increment();
            newItemId[i] = _tokenIds.current();
            _mint(recipients[i], newItemId[i]);
            _setTokenURI(newItemId[i], _retrieveTokenURI(amount));
            amountInVoucher[newItemId[i]] = amount;
        }
    }

    function mint(address recipient, uint amount) external returns (uint newItemId) {
        require(!paused, "Cant mint while paused");

        require(_checkAmount(amount), "Invalid amount");

        sUSD.safeTransferFrom(msg.sender, address(this), amount);

        _tokenIds.increment();

        newItemId = _tokenIds.current();

        _mint(recipient, newItemId);

        _setTokenURI(newItemId, _retrieveTokenURI(amount));

        amountInVoucher[newItemId] = amount;
    }

    function buyFromAMMWithVoucher(
        address market,
        ISportsAMM.Position position,
        uint amount,
        uint tokenId
    ) external {
        require(!paused, "Cant buy while paused");
        require(ERC721.ownerOf(tokenId) == msg.sender, "You are not the voucher owner!");

        uint quote = sportsAMM.buyFromAmmQuote(market, position, amount);
        require(quote < amountInVoucher[tokenId], "Insufficient amount in voucher");

        sportsAMM.buyFromAMM(market, position, amount, quote, 0);
        amountInVoucher[tokenId] = amountInVoucher[tokenId] - quote;

        (IPosition home, IPosition away, IPosition draw) = ISportPositionalMarket(market).getOptions();
        IPosition target = position == ISportsAMM.Position.Home ? home : position == ISportsAMM.Position.Away ? away : draw;

        IERC20(address(target)).safeTransfer(msg.sender, amount);

        //if less than 1 sUSD, transfer the rest to the owner and burn
        if (amountInVoucher[tokenId] < multiplier) {
            sUSD.safeTransfer(address(msg.sender), amountInVoucher[tokenId]);
            super._burn(tokenId);
        }
        emit BoughtFromAmmWithVoucher(msg.sender, market, position, amount, quote, address(sUSD), address(target));
    }

    function buyFromParlayAMMWithVoucher(
        address[] calldata _sportMarkets,
        uint[] calldata _positions,
        uint _sUSDPaid,
        uint _additionalSlippage,
        uint _expectedPayout,
        uint tokenId
    ) external {
        require(!paused, "Cant buy while paused");
        require(ERC721.ownerOf(tokenId) == msg.sender, "You are not the voucher owner!");

        require(_sUSDPaid <= amountInVoucher[tokenId], "Insufficient amount in voucher");

        parlayAMM.buyFromParlay(_sportMarkets, _positions, _sUSDPaid, _additionalSlippage, _expectedPayout, msg.sender);
        amountInVoucher[tokenId] = amountInVoucher[tokenId] - _sUSDPaid;

        //if less than 1 sUSD, transfer the rest to the owner and burn
        if (amountInVoucher[tokenId] < multiplier) {
            sUSD.safeTransfer(address(msg.sender), amountInVoucher[tokenId]);
            super._burn(tokenId);
        }
        emit BoughtFromParlayWithVoucher(msg.sender, _sportMarkets, _positions, _sUSDPaid, _expectedPayout, address(sUSD));
    }

    /* ========== VIEW ========== */

    /* ========== INTERNALS ========== */

    function _transformConstant(uint value) internal view returns (uint) {
        return value * multiplier;
    }

    function _checkAmount(uint amount) internal view returns (bool) {
        return
            amount == _transformConstant(FIVE) ||
            amount == _transformConstant(TEN) ||
            amount == _transformConstant(TWENTY) ||
            amount == _transformConstant(FIFTY) ||
            amount == _transformConstant(HUNDRED) ||
            amount == _transformConstant(TWO_HUNDRED) ||
            amount == _transformConstant(FIVE_HUNDRED) ||
            amount == _transformConstant(THOUSAND);
    }

    function _retrieveTokenURI(uint amount) internal view returns (string memory) {
        return
            amount == _transformConstant(FIVE) ? tokenURIFive : amount == _transformConstant(TEN)
                ? tokenURITen
                : amount == _transformConstant(TWENTY)
                ? tokenURITwenty
                : amount == _transformConstant(FIFTY)
                ? tokenURIFifty
                : amount == _transformConstant(HUNDRED)
                ? tokenURIHundred
                : amount == _transformConstant(TWO_HUNDRED)
                ? tokenURITwoHundred
                : amount == _transformConstant(FIVE_HUNDRED)
                ? tokenURIFiveHundred
                : tokenURIThousand;
    }

    /* ========== CONTRACT MANAGEMENT ========== */

    /// @notice Retrieve sUSD from the contract
    /// @param account whom to send the sUSD
    /// @param amount how much sUSD to retrieve
    function retrieveSUSDAmount(address payable account, uint amount) external onlyOwner {
        sUSD.safeTransfer(account, amount);
    }

    // function burnToken(uint _tokenId, address _recepient) external onlyOwner {
    //     require(amountInVoucher[_tokenId] > 0, "Amount is zero");
    //     if(_recepient != address(0)) {
    //         sUSD.safeTransfer(_recepient, amountInVoucher[_tokenId]);
    //     }
    //     super._burn(_tokenId);
    // }

    function setTokenUris(
        string memory _tokenURIFive,
        string memory _tokenURITen,
        string memory _tokenURITwenty,
        string memory _tokenURIFifty,
        string memory _tokenURIHundred,
        string memory _tokenURITwoHundred,
        string memory _tokenURIFiveHundred,
        string memory _tokenURIThousand
    ) external onlyOwner {
        tokenURIFive = _tokenURIFive;
        tokenURITen = _tokenURITen;
        tokenURITwenty = _tokenURITwenty;
        tokenURIFifty = _tokenURIFifty;
        tokenURIHundred = _tokenURIHundred;
        tokenURITwoHundred = _tokenURITwoHundred;
        tokenURIFiveHundred = _tokenURIFiveHundred;
        tokenURIThousand = _tokenURIThousand;
    }

    function setPause(bool _state) external onlyOwner {
        paused = _state;
        emit Paused(_state);
    }

    function setParlayAMM(address _parlayAMM) external onlyOwner {
        if (address(_parlayAMM) != address(0)) {
            sUSD.approve(address(sportsAMM), 0);
        }
        parlayAMM = IParlayMarketsAMM(_parlayAMM);
        sUSD.approve(_parlayAMM, type(uint256).max);
        emit NewParlayAMM(_parlayAMM);
    }

    function setSportsAMM(address _sportsAMM) external onlyOwner {
        if (address(_sportsAMM) != address(0)) {
            sUSD.approve(address(sportsAMM), 0);
        }
        sportsAMM = ISportsAMM(_sportsAMM);
        sUSD.approve(_sportsAMM, type(uint256).max);
        emit NewSportsAMM(_sportsAMM);
    }

    function setMultiplier(uint _multiplier) external onlyOwner {
        multiplier = _multiplier;
        emit MultiplierChanged(multiplier);
    }

    /* ========== EVENTS ========== */

    event BoughtFromAmmWithVoucher(
        address buyer,
        address market,
        ISportsAMM.Position position,
        uint amount,
        uint sUSDPaid,
        address susd,
        address asset
    );
    event BoughtFromParlayWithVoucher(
        address buyer,
        address[] _sportMarkets,
        uint[] _positions,
        uint _sUSDPaid,
        uint _expectedPayout,
        address susd
    );
    event NewTokenUri(string _tokenURI);
    event NewSportsAMM(address _sportsAMM);
    event NewParlayAMM(address _parlayAMM);
    event Paused(bool _state);
    event MultiplierChanged(uint multiplier);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        _transferOwnership(_msgSender());
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
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
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
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
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ISportAMMRiskManager.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ISportsAMM {
    /* ========== VIEWS / VARIABLES ========== */

    enum Position {
        Home,
        Away,
        Draw
    }

    struct SellRequirements {
        address user;
        address market;
        Position position;
        uint amount;
        uint expectedPayout;
        uint additionalSlippage;
    }

    function theRundownConsumer() external view returns (address);

    function riskManager() external view returns (ISportAMMRiskManager riskManager);

    function getMarketDefaultOdds(address _market, bool isSell) external view returns (uint[] memory);

    function isMarketInAMMTrading(address _market) external view returns (bool);

    function isMarketForSportOnePositional(uint _tag) external view returns (bool);

    function availableToBuyFromAMM(address market, Position position) external view returns (uint _available);

    function parlayAMM() external view returns (address);

    function minSupportedOdds() external view returns (uint);

    function maxSupportedOdds() external view returns (uint);

    function minSupportedOddsPerSport(uint) external view returns (uint);

    function min_spread() external view returns (uint);

    function max_spread() external view returns (uint);

    function minimalTimeLeftToMaturity() external view returns (uint);

    function getSpentOnGame(address market) external view returns (uint);

    function safeBoxImpact() external view returns (uint);

    function manager() external view returns (address);

    function getLiquidityPool() external view returns (address);

    function sUSD() external view returns (IERC20Upgradeable);

    function buyFromAMM(
        address market,
        Position position,
        uint amount,
        uint expectedPayout,
        uint additionalSlippage
    ) external;

    function buyFromAmmQuote(
        address market,
        Position position,
        uint amount
    ) external view returns (uint);

    function buyFromAmmQuoteForParlayAMM(
        address market,
        Position position,
        uint amount
    ) external view returns (uint);

    function updateParlayVolume(address _account, uint _amount) external;

    function buyPriceImpact(
        address market,
        ISportsAMM.Position position,
        uint amount
    ) external view returns (int impact);

    function obtainOdds(address _market, ISportsAMM.Position _position) external view returns (uint oddsToReturn);

    function buyFromAmmQuoteWithDifferentCollateral(
        address market,
        ISportsAMM.Position position,
        uint amount,
        address collateral
    ) external view returns (uint collateralQuote, uint sUSDToPay);

    function availableToBuyFromAMMWithBaseOdds(
        address market,
        ISportsAMM.Position position,
        uint baseOdds,
        uint balance,
        bool useBalance
    ) external view returns (uint availableAmount);

    function floorBaseOdds(uint baseOdds, address market) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "../SportMarkets/Parlay/ParlayVerifier.sol";

interface IParlayMarketsAMM {
    /* ========== VIEWS / VARIABLES ========== */

    function parlaySize() external view returns (uint);

    function sUSD() external view returns (IERC20Upgradeable);

    function sportsAmm() external view returns (address);

    function parlayPolicy() external view returns (address);

    function parlayAmmFee() external view returns (uint);

    function maxAllowedRiskPerCombination() external view returns (uint);

    function maxSupportedOdds() external view returns (uint);

    function getSgpFeePerCombination(
        uint tag1,
        uint tag2_1,
        uint tag2_2,
        uint position1,
        uint position2
    ) external view returns (uint sgpFee);

    function riskPerCombination(
        address _sportMarkets1,
        uint _position1,
        address _sportMarkets2,
        uint _position2,
        address _sportMarkets3,
        uint _position3,
        address _sportMarkets4,
        uint _position4
    ) external view returns (uint);

    function riskPerGameCombination(
        address _sportMarkets1,
        address _sportMarkets2,
        address _sportMarkets3,
        address _sportMarkets4,
        address _sportMarkets5,
        address _sportMarkets6,
        address _sportMarkets7,
        address _sportMarkets8
    ) external view returns (uint);

    function riskPerPackedGamesCombination(bytes32 gamesPacked) external view returns (uint);

    function isActiveParlay(address _parlayMarket) external view returns (bool isActiveParlayMarket);

    function exerciseParlay(address _parlayMarket) external;

    function triggerResolvedEvent(address _account, bool _userWon) external;

    function resolveParlay() external;

    function buyFromParlay(
        address[] calldata _sportMarkets,
        uint[] calldata _positions,
        uint _sUSDPaid,
        uint _additionalSlippage,
        uint _expectedPayout,
        address _differentRecepient
    ) external;

    function buyQuoteFromParlay(
        address[] calldata _sportMarkets,
        uint[] calldata _positions,
        uint _sUSDPaid
    )
        external
        view
        returns (
            uint sUSDAfterFees,
            uint totalBuyAmount,
            uint totalQuote,
            uint initialQuote,
            uint skewImpact,
            uint[] memory finalQuotes,
            uint[] memory amountsToBuy
        );

    function canCreateParlayMarket(
        address[] calldata _sportMarkets,
        uint[] calldata _positions,
        uint _sUSDToPay
    ) external view returns (bool canBeCreated);

    function numActiveParlayMarkets() external view returns (uint);

    function activeParlayMarkets(uint index, uint pageSize) external view returns (address[] memory);

    function parlayVerifier() external view returns (ParlayVerifier);

    function minUSDAmount() external view returns (uint);

    function maxSupportedAmount() external view returns (uint);

    function safeBoxImpact() external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

import "../interfaces/IPositionalMarketManager.sol";
import "../interfaces/IPosition.sol";
import "../interfaces/IPriceFeed.sol";

interface ISportPositionalMarket {
    /* ========== TYPES ========== */

    enum Phase {
        Trading,
        Maturity,
        Expiry
    }
    enum Side {
        Cancelled,
        Home,
        Away,
        Draw
    }

    /* ========== VIEWS / VARIABLES ========== */

    function getOptions()
        external
        view
        returns (
            IPosition home,
            IPosition away,
            IPosition draw
        );

    function times() external view returns (uint maturity, uint destruction);

    function getGameDetails() external view returns (bytes32 gameId, string memory gameLabel);

    function getGameId() external view returns (bytes32);

    function deposited() external view returns (uint);

    function optionsCount() external view returns (uint);

    function creator() external view returns (address);

    function resolved() external view returns (bool);

    function cancelled() external view returns (bool);

    function paused() external view returns (bool);

    function phase() external view returns (Phase);

    function canResolve() external view returns (bool);

    function result() external view returns (Side);

    function isChild() external view returns (bool);

    function optionsInitialized() external view returns (bool);

    function tags(uint idx) external view returns (uint);

    function getTags() external view returns (uint tag1, uint tag2);

    function getTagsLength() external view returns (uint tagsLength);

    function getParentMarketPositions() external view returns (IPosition position1, IPosition position2);

    function getParentMarketPositionsUint() external view returns (uint position1, uint position2);

    function getStampedOdds()
        external
        view
        returns (
            uint,
            uint,
            uint
        );

    function balancesOf(address account)
        external
        view
        returns (
            uint home,
            uint away,
            uint draw
        );

    function totalSupplies()
        external
        view
        returns (
            uint home,
            uint away,
            uint draw
        );

    function isDoubleChance() external view returns (bool);

    function parentMarket() external view returns (ISportPositionalMarket);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function setPaused(bool _paused) external;

    function updateDates(uint256 _maturity, uint256 _expiry) external;

    function mint(uint value) external;

    function exerciseOptions() external;

    function restoreInvalidOdds(
        uint _homeOdds,
        uint _awayOdds,
        uint _drawOdds
    ) external;

    function initializeOptions() external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

import "./IPositionalMarket.sol";

interface IPosition {
    /* ========== VIEWS / VARIABLES ========== */

    function getBalanceOf(address account) external view returns (uint);

    function getTotalSupply() external view returns (uint);

    function exerciseWithAmount(address claimant, uint amount) external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

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
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

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

pragma solidity ^0.8.0;

interface ISportAMMRiskManager {
    function calculateCapToBeUsed(address _market) external view returns (uint toReturn);

    function isTotalSpendingLessThanTotalRisk(uint _totalSpent, address _market) external view returns (bool _isNotRisky);

    function isMarketForSportOnePositional(uint _tag) external view returns (bool);

    function isMarketForPlayerPropsOnePositional(uint _tag) external view returns (bool);

    function minSupportedOddsPerSport(uint tag) external view returns (uint);

    function minSpreadPerSport(uint tag1, uint tag2) external view returns (uint);

    function maxSpreadPerSport(uint tag) external view returns (uint);

    function getMinSpreadToUse(
        bool useDefaultMinSpread,
        address market,
        uint min_spread,
        uint min_spreadPerAddress
    ) external view returns (uint);

    function getMaxSpreadForMarket(address _market, uint max_spread) external view returns (uint);

    function getMinOddsForMarket(address _market, uint minSupportedOdds) external view returns (uint minOdds);

    function getCapAndMaxSpreadForMarket(address _market, uint max_spread) external view returns (uint, uint);

    function getCapMaxSpreadAndMinOddsForMarket(
        address _market,
        uint max_spread,
        uint minSupportedOdds
    )
        external
        view
        returns (
            uint cap,
            uint maxSpread,
            uint minOddsForMarket
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// interfaces
import "../../interfaces/IParlayMarketsAMM.sol";
import "../../interfaces/ISportsAMM.sol";
// import "../../interfaces/IParlayMarketData.sol";
import "../../interfaces/ISportPositionalMarket.sol";
import "../../interfaces/IParlayPolicy.sol";

contract ParlayVerifier {
    uint private constant ONE = 1e18;
    uint private constant ONE_PERCENT = 1e16;

    uint private constant TAG_F1 = 9445;
    uint private constant TAG_MOTOGP = 9497;
    uint private constant TAG_GOLF = 100121;
    uint private constant TAG_NUMBER_SPREAD = 10001;
    uint private constant TAG_NUMBER_TOTAL = 10002;
    uint private constant DOUBLE_CHANCE_TAG = 10003;
    uint private constant PLAYER_PROPS_TAG = 10010;

    struct InitialQuoteParameters {
        address[] sportMarkets;
        uint[] positions;
        uint totalSUSDToPay;
        uint parlaySize;
        uint defaultONE;
        uint[] sgpFees;
        ISportsAMM sportsAMM;
        address parlayAMM;
    }

    struct VerifyMarket {
        address[] sportMarkets;
        uint[] positions;
        ISportsAMM sportsAMM;
        address parlayAMM;
        uint defaultONE;
    }

    struct CachedMarket {
        bytes32 gameId;
        uint gameCounter;
    }

    struct CheckSGP {
        address[] sportMarkets;
        uint[] positions;
        uint[] tag1;
        uint[] tag2;
        IParlayPolicy parlayPolicy;
        uint defaultONE;
    }

    /// @notice Verifying if given parlay is able to be created given the policies in state
    /// @param params VerifyMarket parameters
    /// @return eligible if the parlay can be created
    /// @return odds the odds for each position
    /// @return sgpFees the fees applied per position in case of SameGameParlay
    function _verifyMarkets(VerifyMarket memory params)
        internal
        view
        returns (
            bool eligible,
            uint[] memory odds,
            uint[] memory sgpFees
        )
    {
        eligible = true;
        uint[] memory tags1;
        uint[] memory tags2;
        IParlayPolicy parlayPolicy = IParlayPolicy(IParlayMarketsAMM(params.parlayAMM).parlayPolicy());
        (tags1, tags2) = _obtainAllTags(params.sportMarkets);
        (odds, sgpFees) = _checkSGPAndGetOdds(
            CheckSGP(params.sportMarkets, params.positions, tags1, tags2, parlayPolicy, params.defaultONE)
        );
    }

    /// @notice Obtain all the tags for each position and calculate unique ones
    /// @param sportMarkets the sport markets for the parlay
    /// @return tag1 all the tags 1 per market
    /// @return tag2 all the tags 2 per market
    function _obtainAllTags(address[] memory sportMarkets) internal view returns (uint[] memory tag1, uint[] memory tag2) {
        tag1 = new uint[](sportMarkets.length);
        tag2 = new uint[](sportMarkets.length);
        address sportMarket;
        for (uint i = 0; i < sportMarkets.length; i++) {
            // 1. Get all tags for a sport market (tag1, tag2)
            sportMarket = sportMarkets[i];
            tag1[i] = ISportPositionalMarket(sportMarket).tags(0);
            tag2[i] = ISportPositionalMarket(sportMarket).getTagsLength() > 1
                ? ISportPositionalMarket(sportMarket).tags(1)
                : 0;
            for (uint j = 0; j < i; j++) {
                if (sportMarkets[i] == sportMarkets[j]) {
                    revert("SameTeamOnParlay");
                }
            }
        }
    }

    /// @notice Check the names, check if any markets are SGPs, obtain odds and apply fees if needed
    /// @param params all the parameters to calculate the fees and odds per position
    /// @return odds all the odds per position
    /// @return sgpFees all the fees per position
    function _checkSGPAndGetOdds(CheckSGP memory params) internal view returns (uint[] memory odds, uint[] memory sgpFees) {
        odds = new uint[](params.sportMarkets.length);
        sgpFees = new uint[](odds.length);
        bool[] memory alreadyInSGP = new bool[](sgpFees.length);
        for (uint i = 0; i < params.sportMarkets.length; i++) {
            for (uint j = 0; j < i; j++) {
                if (params.sportMarkets[j] != params.sportMarkets[i]) {
                    if (!alreadyInSGP[j] && params.tag1[j] == params.tag1[i] && (params.tag2[i] > 0 || params.tag2[j] > 0)) {
                        address parentI = address(ISportPositionalMarket(params.sportMarkets[i]).parentMarket());
                        address parentJ = address(ISportPositionalMarket(params.sportMarkets[j]).parentMarket());
                        if (
                            (params.tag2[j] > 0 && parentJ == params.sportMarkets[i]) ||
                            (params.tag2[i] > 0 && parentI == params.sportMarkets[j]) ||
                            // the following line is for totals + spreads or totals + playerProps
                            (params.tag2[i] > 0 && params.tag2[j] > 0 && parentI == parentJ)
                        ) {
                            uint sgpFee = params.parlayPolicy.getSgpFeePerCombination(
                                IParlayPolicy.SGPData(
                                    params.tag1[i],
                                    params.tag2[i],
                                    params.tag2[j],
                                    params.positions[i],
                                    params.positions[j]
                                )
                            );
                            if (params.tag2[j] == PLAYER_PROPS_TAG && params.tag2[i] == PLAYER_PROPS_TAG) {
                                // check if the markets are elibible props markets
                                if (
                                    !params.parlayPolicy.areEligiblePropsMarkets(
                                        params.sportMarkets[i],
                                        params.sportMarkets[j],
                                        params.tag1[i]
                                    )
                                ) {
                                    revert("InvalidPlayerProps");
                                }
                            } else if (sgpFee == 0) {
                                revert("SameTeamOnParlay");
                            } else {
                                alreadyInSGP[i] = true;
                                alreadyInSGP[j] = true;
                                if (params.tag2[j] > 0) {
                                    (odds[i], odds[j], sgpFees[i], sgpFees[j]) = _getSGPSingleOdds(
                                        params.parlayPolicy.getMarketDefaultOdds(
                                            params.sportMarkets[i],
                                            params.positions[i]
                                        ),
                                        params.parlayPolicy.getMarketDefaultOdds(
                                            params.sportMarkets[j],
                                            params.positions[j]
                                        ),
                                        params.positions[j],
                                        sgpFee,
                                        params.parlayPolicy.getChildMarketTotalLine(params.sportMarkets[j]),
                                        params.defaultONE
                                    );
                                } else {
                                    (odds[j], odds[i], sgpFees[j], sgpFees[i]) = _getSGPSingleOdds(
                                        params.parlayPolicy.getMarketDefaultOdds(
                                            params.sportMarkets[j],
                                            params.positions[j]
                                        ),
                                        params.parlayPolicy.getMarketDefaultOdds(
                                            params.sportMarkets[i],
                                            params.positions[i]
                                        ),
                                        params.positions[i],
                                        sgpFee,
                                        params.parlayPolicy.getChildMarketTotalLine(params.sportMarkets[i]),
                                        params.defaultONE
                                    );
                                }
                            }
                        }
                    }
                } else {
                    revert("SameTeamOnParlay");
                }
            }
            if (odds[i] == 0) {
                odds[i] = params.parlayPolicy.getMarketDefaultOdds(params.sportMarkets[i], params.positions[i]);
            }
        }
    }

    function getSPGOdds(
        uint odds1,
        uint odds2,
        uint position2,
        uint sgpFee,
        uint totalsLine,
        uint defaultONE
    )
        external
        pure
        returns (
            uint resultOdds1,
            uint resultOdds2,
            uint sgpFee1,
            uint sgpFee2
        )
    {
        (resultOdds1, resultOdds2, sgpFee1, sgpFee2) = _getSGPSingleOdds(
            odds1,
            odds2,
            position2,
            sgpFee,
            totalsLine,
            defaultONE
        );
    }

    /// @notice Calculate the sgpFees for the positions of two sport markets, given their odds and default sgpfee
    /// @param odds1 the odd of position 1 (usually the moneyline odd)
    /// @param odds2 the odd of position 2 (usually the totals/spreads odd)
    /// @param sgpFee the default sgp fee
    /// @return resultOdds1 the odd1
    /// @return resultOdds2 the odd2
    /// @return sgpFee1 the fee for position 1 or odd1
    /// @return sgpFee2 the fee for position 2 or odd2
    function _getSGPSingleOdds(
        uint odds1,
        uint odds2,
        uint position2,
        uint sgpFee,
        uint totalsLine,
        uint defaultONE
    )
        internal
        pure
        returns (
            uint resultOdds1,
            uint resultOdds2,
            uint sgpFee1,
            uint sgpFee2
        )
    {
        resultOdds1 = odds1;
        resultOdds2 = odds2;

        odds1 = odds1 * defaultONE;
        odds2 = odds2 * defaultONE;

        if (odds1 > 0 && odds2 > 0) {
            if (totalsLine == 2) {
                sgpFee2 = sgpFee;
            } else if (totalsLine == 250) {
                if (position2 == 0) {
                    if (odds1 < (6 * ONE_PERCENT) && odds2 < (70 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee - (ONE - sgpFee);
                    } else if (odds1 >= (99 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) - 1 * ONE_PERCENT);
                    } else if (odds1 >= (96 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 90 * ONE_PERCENT) / ONE;
                    } else if (odds1 >= (93 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 75 * ONE_PERCENT) / ONE;
                    } else if (odds1 >= (90 * ONE_PERCENT) && odds2 >= (65 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 90 * ONE_PERCENT) / ONE;
                    } else if (odds1 >= (83 * ONE_PERCENT) && odds2 >= (98 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + (5 * ONE_PERCENT);
                    } else if (odds1 >= (83 * ONE_PERCENT) && odds2 >= (52 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 30 * ONE_PERCENT) / ONE;
                    } else if (odds1 >= (80 * ONE_PERCENT) && odds2 >= (74 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 20 * ONE_PERCENT) / ONE;
                    } else if (odds1 >= (80 * ONE_PERCENT) && odds2 >= (70 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 50 * ONE_PERCENT) / ONE;
                    } else if (odds1 >= (80 * ONE_PERCENT) && odds2 >= (60 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 30 * ONE_PERCENT) / ONE;
                    } else if (odds1 >= (80 * ONE_PERCENT) && odds2 >= (50 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 90 * ONE_PERCENT) / ONE;
                    } else if (odds2 >= (60 * ONE_PERCENT) && odds1 <= (10 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee;
                    } else if (odds2 >= (55 * ONE_PERCENT) && odds1 <= (19 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee - ((ONE - sgpFee) * 70 * ONE_PERCENT) / ONE;
                    } else if (odds2 >= (55 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee - ((ONE - sgpFee) * 40 * ONE_PERCENT) / ONE;
                    } else if (odds2 >= (54 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee - ((ONE - sgpFee) * 70 * ONE_PERCENT) / ONE;
                    } else if (odds2 >= (52 * ONE_PERCENT)) {
                        if (odds1 <= (10 * ONE_PERCENT)) {
                            sgpFee2 = sgpFee - ((ONE - sgpFee) * 50 * ONE_PERCENT) / ONE;
                        } else if (odds1 <= (23 * ONE_PERCENT)) {
                            sgpFee2 = sgpFee - ((ONE - sgpFee) * 45 * ONE_PERCENT) / ONE;
                        } else if (odds1 <= (46 * ONE_PERCENT)) {
                            sgpFee2 = sgpFee + (((5 * ONE_PERCENT) * (ONE - odds1)) / ONE);
                        } else {
                            sgpFee2 = sgpFee;
                        }
                    } else if (odds2 >= (51 * ONE_PERCENT) && odds1 <= (20 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee - ((ONE - sgpFee) * 90 * ONE_PERCENT) / ONE;
                    } else if (odds2 >= (51 * ONE_PERCENT) && odds1 <= (25 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee - ((sgpFee * 10 * ONE_PERCENT) / ONE);
                    } else if (odds2 >= (50 * ONE_PERCENT)) {
                        if (odds1 < (10 * ONE_PERCENT)) {
                            sgpFee2 = ONE + odds1;
                        } else if (odds1 <= (21 * ONE_PERCENT)) {
                            sgpFee2 = sgpFee - ((ONE - sgpFee) * 90 * ONE_PERCENT) / ONE;
                        } else if (odds1 <= (23 * ONE_PERCENT)) {
                            sgpFee2 = sgpFee - ((ONE - sgpFee) * 30 * ONE_PERCENT) / ONE;
                        } else if (odds1 <= (56 * ONE_PERCENT)) {
                            sgpFee2 = sgpFee - ((ONE - sgpFee) * 70 * ONE_PERCENT) / ONE;
                        } else {
                            uint oddsDiff = odds2 > odds1 ? odds2 - odds1 : odds1 - odds2;
                            if (oddsDiff > 0) {
                                oddsDiff = (oddsDiff - (5 * ONE_PERCENT) / (90 * ONE_PERCENT));
                                oddsDiff = ((ONE - sgpFee) * oddsDiff) / ONE;
                                sgpFee2 = (sgpFee * (ONE + oddsDiff)) / ONE;
                            } else {
                                sgpFee2 = sgpFee;
                            }
                        }
                    } else if (odds2 >= (49 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee - ((ONE - sgpFee) * 70 * ONE_PERCENT) / ONE;
                    } else if (odds2 >= (48 * ONE_PERCENT) && odds1 <= (20 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee - ((ONE - sgpFee) * 30 * ONE_PERCENT) / ONE;
                    } else if (odds2 >= (48 * ONE_PERCENT) && odds1 <= (40 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee - ((ONE - sgpFee) * 20 * ONE_PERCENT) / ONE;
                    } else if (odds2 >= (48 * ONE_PERCENT) && odds1 <= (50 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee - ((ONE - sgpFee) * 40 * ONE_PERCENT) / ONE;
                    } else if (odds2 >= (48 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee;
                    } else if (odds2 >= (46 * ONE_PERCENT) && odds1 <= (43 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee - ((ONE - sgpFee) * 50 * ONE_PERCENT) / ONE;
                    } else if (odds2 >= (46 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee;
                    } else if (odds2 >= (43 * ONE_PERCENT)) {
                        if (odds1 <= (24 * ONE_PERCENT)) {
                            sgpFee2 = sgpFee - ((ONE - sgpFee) * 30 * ONE_PERCENT) / ONE;
                        } else if (odds2 <= (46 * ONE_PERCENT)) {
                            sgpFee2 = sgpFee > 5 * ONE_PERCENT ? sgpFee - (2 * ONE_PERCENT) : sgpFee;
                        } else {
                            uint oddsDiff = odds2 > odds1 ? odds2 - odds1 : odds1 - odds2;
                            if (oddsDiff > 0) {
                                oddsDiff = (oddsDiff - (5 * ONE_PERCENT) / (90 * ONE_PERCENT));
                                oddsDiff = ((ONE - sgpFee + (ONE - sgpFee) / 2) * oddsDiff) / ONE;

                                sgpFee2 = (sgpFee * (ONE + oddsDiff)) / ONE;
                            } else {
                                sgpFee2 = sgpFee;
                            }
                        }
                    } else if (odds2 >= (39 * ONE_PERCENT) && odds1 >= (43 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee - ((ONE - sgpFee) * 70 * ONE_PERCENT) / ONE;
                    } else if (odds2 >= (35 * ONE_PERCENT)) {
                        if (odds1 <= (46 * ONE_PERCENT)) {
                            sgpFee2 = sgpFee - (((ONE - sgpFee) * (ONE - odds1)) / ONE);
                        } else {
                            sgpFee2 = sgpFee > 5 * ONE_PERCENT ? sgpFee - (2 * ONE_PERCENT) : sgpFee;
                        }
                    } else if (odds2 < (35 * ONE_PERCENT)) {
                        if (odds1 <= (46 * ONE_PERCENT)) {
                            sgpFee2 = sgpFee + ((ONE - sgpFee) * 90 * ONE_PERCENT) / ONE;
                        } else {
                            sgpFee2 = sgpFee > 5 * ONE_PERCENT ? sgpFee - (2 * ONE_PERCENT) : sgpFee;
                        }
                    }
                } else {
                    if (odds2 >= (56 * ONE_PERCENT)) {
                        if (odds2 > (68 * ONE_PERCENT) && odds1 <= (15 * ONE_PERCENT)) {
                            sgpFee2 = sgpFee + ((ONE - sgpFee) * 50 * ONE_PERCENT) / ONE;
                        } else if (odds1 >= 76 * ONE_PERCENT) {
                            sgpFee2 = (ONE + (15 * ONE_PERCENT) + (odds1 * 15 * ONE_PERCENT) / ONE);
                        } else if (odds1 >= 60 * ONE_PERCENT) {
                            sgpFee2 = ONE + (ONE - sgpFee);
                        } else if (odds2 >= (58 * ONE_PERCENT) && odds1 <= (18 * ONE_PERCENT)) {
                            sgpFee2 = sgpFee + ((ONE - sgpFee) * 80 * ONE_PERCENT) / ONE;
                        } else if (odds2 >= (58 * ONE_PERCENT) && odds1 <= (32 * ONE_PERCENT)) {
                            sgpFee2 = sgpFee - ((ONE - sgpFee) * 70 * ONE_PERCENT) / ONE;
                        } else if (odds2 >= (55 * ONE_PERCENT) && odds1 >= (58 * ONE_PERCENT)) {
                            sgpFee2 = sgpFee;
                        } else if (odds2 >= (55 * ONE_PERCENT) && odds1 <= (18 * ONE_PERCENT)) {
                            sgpFee2 = sgpFee;
                        } else if (odds1 <= 35 * ONE_PERCENT && odds1 >= 30 * ONE_PERCENT) {
                            sgpFee2 = sgpFee;
                        } else if (odds1 <= 15 * ONE_PERCENT) {
                            sgpFee2 = sgpFee - ((ONE - sgpFee) * 50 * ONE_PERCENT) / ONE;
                        } else {
                            sgpFee2 = (ONE + (15 * ONE_PERCENT) + (odds1 * 10 * ONE_PERCENT) / ONE);
                        }
                    } else if (odds2 <= (32 * ONE_PERCENT) && odds1 >= (65 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee - (ONE - sgpFee);
                    } else if (odds2 <= (32 * ONE_PERCENT) && odds1 >= (85 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee - ((ONE - sgpFee) * 80 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (35 * ONE_PERCENT) && odds1 <= (125 * 1e15)) {
                        sgpFee2 = sgpFee - ((ONE - sgpFee) * 10 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (35 * ONE_PERCENT) && odds1 > (125 * 1e15) && odds1 <= (13 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee;
                    } else if (odds2 <= (35 * ONE_PERCENT) && odds1 <= (15 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee - ((ONE - sgpFee) * 20 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (35 * ONE_PERCENT) && odds1 <= (24 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 30 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (37 * ONE_PERCENT) && odds1 <= (10 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee - (ONE - sgpFee);
                    } else if (odds2 <= (37 * ONE_PERCENT) && odds1 <= (16 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 60 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (38 * ONE_PERCENT) && odds1 >= (80 * ONE_PERCENT)) {
                        sgpFee2 = ONE + (ONE - sgpFee + 5 * ONE_PERCENT);
                    } else if (odds2 <= (38 * ONE_PERCENT) && odds1 >= (70 * ONE_PERCENT)) {
                        sgpFee2 = ONE + (ONE - sgpFee + 10 * ONE_PERCENT);
                    } else if (odds2 <= (38 * ONE_PERCENT) && odds1 >= (66 * ONE_PERCENT)) {
                        sgpFee2 = ONE + (ONE - sgpFee + 25 * ONE_PERCENT);
                    } else if (odds2 <= (38 * ONE_PERCENT) && odds1 >= (50 * ONE_PERCENT)) {
                        sgpFee2 = ONE + (ONE - sgpFee + 5 * ONE_PERCENT);
                    } else if (odds2 <= (38 * ONE_PERCENT) && odds1 >= (25 * ONE_PERCENT)) {
                        sgpFee2 = ONE + (2 * (ONE - sgpFee));
                    } else if (odds2 <= (38 * ONE_PERCENT) && odds1 >= (23 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee - ((ONE - sgpFee) * 30 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (38 * ONE_PERCENT) && odds1 < (23 * ONE_PERCENT)) {
                        sgpFee2 = ONE + ((ONE - sgpFee) * 40 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (39 * ONE_PERCENT) && odds1 < (20 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee - (sgpFee * 20 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (40 * ONE_PERCENT) && odds1 <= (9 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 80 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (40 * ONE_PERCENT) && odds1 <= (11 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee;
                    } else if (odds2 <= (40 * ONE_PERCENT) && odds1 <= (13 * ONE_PERCENT)) {
                        sgpFee2 = ONE + ((ONE - sgpFee) * 50 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (40 * ONE_PERCENT) && odds1 <= (14 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 80 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (40 * ONE_PERCENT) && odds1 <= (30 * ONE_PERCENT)) {
                        sgpFee2 = ONE + (sgpFee * 30 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (40 * ONE_PERCENT) && odds1 <= (54 * ONE_PERCENT)) {
                        sgpFee2 = ONE + (sgpFee * 20 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (40 * ONE_PERCENT) && odds1 > (54 * ONE_PERCENT)) {
                        sgpFee2 = ONE + (ONE - sgpFee);
                    } else if (odds2 <= (43 * ONE_PERCENT) && odds1 <= (11 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 50 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (43 * ONE_PERCENT) && odds1 <= (12 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 75 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (43 * ONE_PERCENT) && odds1 <= (14 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + (sgpFee * 20 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (43 * ONE_PERCENT) && odds1 <= (15 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee - (sgpFee * 30 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (43 * ONE_PERCENT) && odds1 <= (51 * ONE_PERCENT)) {
                        sgpFee2 = ONE + (ONE - sgpFee);
                    } else if (odds2 <= (44 * ONE_PERCENT) && odds1 >= (55 * ONE_PERCENT)) {
                        sgpFee2 = ONE + (sgpFee * 30 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (44 * ONE_PERCENT) && odds1 <= (55 * ONE_PERCENT)) {
                        sgpFee2 = ONE + (sgpFee * 30 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (45 * ONE_PERCENT) && odds1 >= (70 * ONE_PERCENT)) {
                        sgpFee2 = ONE + (2 * (ONE - sgpFee)) - ((ONE - sgpFee) * 40 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (45 * ONE_PERCENT) && odds1 >= (44 * ONE_PERCENT)) {
                        sgpFee2 = ONE + ((ONE - sgpFee) * 70 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (45 * ONE_PERCENT) && odds1 >= (40 * ONE_PERCENT)) {
                        sgpFee2 = ONE + ((ONE - sgpFee) * 10 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (45 * ONE_PERCENT) && odds1 >= (20 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 80 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (45 * ONE_PERCENT) && odds1 < (20 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 30 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (47 * ONE_PERCENT) && odds1 <= (17 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 70 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (47 * ONE_PERCENT) && odds1 <= (23 * ONE_PERCENT)) {
                        sgpFee2 = ONE + ((ONE - sgpFee) * 8 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (48 * ONE_PERCENT) && odds1 <= (11 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 80 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (48 * ONE_PERCENT) && odds1 <= (24 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + (sgpFee * 20 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (49 * ONE_PERCENT) && odds1 <= (15 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 30 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (49 * ONE_PERCENT) && odds1 <= (25 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 80 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (49 * ONE_PERCENT) && odds1 <= (33 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee;
                    } else if (odds2 <= (50 * ONE_PERCENT) && odds1 <= (10 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 50 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (50 * ONE_PERCENT) && odds1 <= (17 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 35 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (50 * ONE_PERCENT) && odds1 <= (20 * ONE_PERCENT)) {
                        sgpFee2 = ONE + (ONE - sgpFee);
                    } else if (odds2 <= (50 * ONE_PERCENT) && odds1 <= (25 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee - (ONE - sgpFee) - (ONE - sgpFee);
                    } else if (odds2 <= (51 * ONE_PERCENT) && odds1 <= (24 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee;
                    } else if (odds2 <= (52 * ONE_PERCENT) && odds1 <= (10 * ONE_PERCENT)) {
                        sgpFee2 = ONE + ((ONE - sgpFee) * 35 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (52 * ONE_PERCENT) && odds1 <= (15 * ONE_PERCENT)) {
                        sgpFee2 = ONE + ((ONE - sgpFee) * 45 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (52 * ONE_PERCENT) && odds1 <= (24 * ONE_PERCENT)) {
                        sgpFee2 = ONE + ((ONE - sgpFee) * 35 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (52 * ONE_PERCENT) && odds1 > (72 * ONE_PERCENT)) {
                        sgpFee2 = ONE + ((ONE - sgpFee) * 35 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (53 * ONE_PERCENT) && odds1 <= (24 * ONE_PERCENT)) {
                        sgpFee2 = ONE + (sgpFee * 30 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (53 * ONE_PERCENT) && odds1 <= (40 * ONE_PERCENT)) {
                        sgpFee2 = ONE;
                    } else if (odds2 < (54 * ONE_PERCENT) && odds1 >= (74 * ONE_PERCENT)) {
                        sgpFee2 = ONE + (ONE - sgpFee);
                    } else if (odds2 < (54 * ONE_PERCENT) && odds1 >= (58 * ONE_PERCENT)) {
                        sgpFee2 = ONE + (ONE - sgpFee + 10 * ONE_PERCENT);
                    } else if (odds2 < (54 * ONE_PERCENT) && odds1 >= (24 * ONE_PERCENT)) {
                        sgpFee2 = ONE + (ONE - sgpFee);
                    } else if (odds2 < (54 * ONE_PERCENT) && odds1 < (24 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 30 * ONE_PERCENT) / ONE;
                    } else if (odds2 < (56 * ONE_PERCENT) && odds1 >= (82 * ONE_PERCENT)) {
                        sgpFee2 = ONE + ((ONE - sgpFee) * 50 * ONE_PERCENT) / ONE;
                    } else if (odds2 < (56 * ONE_PERCENT) && odds1 >= (40 * ONE_PERCENT)) {
                        sgpFee2 = ONE + (ONE - sgpFee);
                    } else if (odds2 < (56 * ONE_PERCENT) && odds1 >= (10 * ONE_PERCENT)) {
                        sgpFee2 = ONE + (ONE - sgpFee);
                    } else {
                        sgpFee2 = sgpFee;
                    }
                }
            } else {
                sgpFee2 = sgpFee;
            }
            if (sgpFee2 > 0) {
                uint totalQuote = (odds1 * odds2) / ONE;
                uint totalQuoteWSGP = ((totalQuote * ONE * ONE) / sgpFee2) / ONE;
                if (totalQuoteWSGP < (10 * ONE_PERCENT)) {
                    if (odds1 > (10 * ONE_PERCENT)) {
                        sgpFee2 = ((totalQuote * ONE * ONE) / (10 * ONE_PERCENT)) / ONE;
                    } else {
                        sgpFee2 = ((totalQuote * ONE * ONE) / (odds1 - ((odds1 * 10 * ONE_PERCENT) / ONE))) / ONE;
                    }
                } else if (totalQuoteWSGP > odds1 && odds1 < odds2) {
                    sgpFee2 = odds2 + (4 * 1e15);
                } else if (totalQuoteWSGP > odds2 && odds2 <= odds1) {
                    sgpFee2 = odds1 + (4 * 1e15);
                }
            }
        }
    }

    function calculateInitialQuotesForParlay(InitialQuoteParameters memory params)
        external
        view
        returns (
            uint totalQuote,
            uint totalBuyAmount,
            uint skewImpact,
            uint[] memory finalQuotes,
            uint[] memory amountsToBuy
        )
    {
        uint numOfMarkets = params.sportMarkets.length;
        uint inverseSum;
        bool eligible;
        amountsToBuy = new uint[](numOfMarkets);
        (eligible, finalQuotes, params.sgpFees) = _verifyMarkets(
            VerifyMarket(params.sportMarkets, params.positions, params.sportsAMM, params.parlayAMM, params.defaultONE)
        );
        if (eligible && numOfMarkets == params.positions.length && numOfMarkets > 0 && numOfMarkets <= params.parlaySize) {
            for (uint i = 0; i < numOfMarkets; i++) {
                if (params.positions[i] > 2) {
                    totalQuote = 0;
                    break;
                }
                if (finalQuotes.length == 0) {
                    totalQuote = 0;
                    break;
                }
                if (finalQuotes[i] == 0) {
                    totalQuote = 0;
                    break;
                }
                finalQuotes[i] = (params.defaultONE * finalQuotes[i]);
                if (params.sgpFees[i] > 0) {
                    finalQuotes[i] = ((finalQuotes[i] * ONE * ONE) / params.sgpFees[i]) / ONE;
                }
                totalQuote = totalQuote == 0 ? finalQuotes[i] : (totalQuote * finalQuotes[i]) / ONE;
            }
            if (totalQuote != 0) {
                if (totalQuote < IParlayMarketsAMM(params.parlayAMM).maxSupportedOdds()) {
                    totalQuote = IParlayMarketsAMM(params.parlayAMM).maxSupportedOdds();
                }
                totalBuyAmount = (params.totalSUSDToPay * ONE) / totalQuote;
                _calculateRisk(params.sportMarkets, (totalBuyAmount - params.totalSUSDToPay), params.sportsAMM.parlayAMM());
            }

            for (uint i = 0; i < numOfMarkets; i++) {
                //consider if this works well for Arbitrum at 6 decimals
                if (finalQuotes[i] > 0) {
                    amountsToBuy[i] = (ONE * params.totalSUSDToPay) / finalQuotes[i];
                }
            }
        }
    }

    function obtainSportsAMMPosition(uint _position) public pure returns (ISportsAMM.Position) {
        if (_position == 0) {
            return ISportsAMM.Position.Home;
        } else if (_position == 1) {
            return ISportsAMM.Position.Away;
        }
        return ISportsAMM.Position.Draw;
    }

    function _calculateRisk(
        address[] memory _sportMarkets,
        uint _sUSDInRisky,
        address _parlayAMM
    ) internal view returns (bool riskFree) {
        require(_checkRisk(_sportMarkets, _sUSDInRisky, _parlayAMM), "RiskPerComb exceeded");
        riskFree = true;
    }

    function _checkRisk(
        address[] memory _sportMarkets,
        uint _sUSDInRisk,
        address _parlayAMM
    ) internal view returns (bool riskFree) {
        if (_sportMarkets.length > 1 && _sportMarkets.length <= IParlayMarketsAMM(_parlayAMM).parlaySize()) {
            uint riskCombination = IParlayMarketsAMM(_parlayAMM).riskPerPackedGamesCombination(
                _calculateCombinationKey(_sportMarkets)
            );
            riskFree = (riskCombination + _sUSDInRisk) <= IParlayMarketsAMM(_parlayAMM).maxAllowedRiskPerCombination();
        }
    }

    function _calculateCombinationKey(address[] memory _sportMarkets) internal pure returns (bytes32) {
        address[] memory sortedAddresses = new address[](_sportMarkets.length);
        sortedAddresses = _sort(_sportMarkets);
        return keccak256(abi.encodePacked(sortedAddresses));
    }

    function _sort(address[] memory data) internal pure returns (address[] memory) {
        _quickSort(data, int(0), int(data.length - 1));
        return data;
    }

    function _quickSort(
        address[] memory arr,
        int left,
        int right
    ) internal pure {
        int i = left;
        int j = right;
        if (i == j) return;
        address pivot = arr[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint(i)] < pivot) i++;
            while (pivot < arr[uint(j)]) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j) _quickSort(arr, left, j);
        if (i < right) _quickSort(arr, i, right);
    }

    function sort(address[] memory data) external pure returns (address[] memory) {
        _quickSort(data, int(0), int(data.length - 1));
        return data;
    }

    function calculateCombinationKey(address[] memory _sportMarkets) external pure returns (bytes32) {
        return _calculateCombinationKey(_sportMarkets);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IParlayPolicy {
    struct SGPData {
        uint tag1;
        uint tag2_1;
        uint tag2_2;
        uint position1;
        uint position2;
    }

    /* ========== VIEWS / VARIABLES ========== */
    function consumer() external view returns (address);

    function getSgpFeePerCombination(SGPData memory params) external view returns (uint sgpFee);

    function getMarketDefaultOdds(address _sportMarket, uint _position) external view returns (uint odd);

    function areEligiblePropsMarkets(
        address _childMarket1,
        address _childMarket2,
        uint _tag1
    ) external view returns (bool samePlayerDifferentProp);

    function getChildMarketTotalLine(address _sportMarket) external view returns (uint childTotalsLine);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

import "../interfaces/IPositionalMarket.sol";

interface IPositionalMarketManager {
    /* ========== VIEWS / VARIABLES ========== */

    function durations() external view returns (uint expiryDuration, uint maxTimeToMaturity);

    function capitalRequirement() external view returns (uint);

    function marketCreationEnabled() external view returns (bool);

    function onlyAMMMintingAndBurning() external view returns (bool);

    function transformCollateral(uint value) external view returns (uint);

    function reverseTransformCollateral(uint value) external view returns (uint);

    function totalDeposited() external view returns (uint);

    function numActiveMarkets() external view returns (uint);

    function activeMarkets(uint index, uint pageSize) external view returns (address[] memory);

    function numMaturedMarkets() external view returns (uint);

    function maturedMarkets(uint index, uint pageSize) external view returns (address[] memory);

    function isActiveMarket(address candidate) external view returns (bool);

    function isKnownMarket(address candidate) external view returns (bool);

    function getThalesAMM() external view returns (address);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function createMarket(
        bytes32 oracleKey,
        uint strikePrice,
        uint maturity,
        uint initialMint // initial sUSD to mint options for,
    ) external returns (IPositionalMarket);

    function resolveMarket(address market) external;

    function expireMarkets(address[] calldata market) external;

    function transferSusdTo(
        address sender,
        address receiver,
        uint amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

interface IPriceFeed {
    // Structs
    struct RateAndUpdatedTime {
        uint216 rate;
        uint40 time;
    }

    // Mutative functions
    function addAggregator(bytes32 currencyKey, address aggregatorAddress) external;

    function removeAggregator(bytes32 currencyKey) external;

    // Views

    function rateForCurrency(bytes32 currencyKey) external view returns (uint);

    function rateAndUpdatedTime(bytes32 currencyKey) external view returns (uint rate, uint time);

    function getRates() external view returns (uint[] memory);

    function getCurrencies() external view returns (bytes32[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

import "../interfaces/IPositionalMarketManager.sol";
import "../interfaces/IPosition.sol";
import "../interfaces/IPriceFeed.sol";

interface IPositionalMarket {
    /* ========== TYPES ========== */

    enum Phase {
        Trading,
        Maturity,
        Expiry
    }
    enum Side {
        Up,
        Down
    }

    /* ========== VIEWS / VARIABLES ========== */

    function getOptions() external view returns (IPosition up, IPosition down);

    function times() external view returns (uint maturity, uint destructino);

    function getOracleDetails()
        external
        view
        returns (
            bytes32 key,
            uint strikePrice,
            uint finalPrice
        );

    function fees() external view returns (uint poolFee, uint creatorFee);

    function deposited() external view returns (uint);

    function creator() external view returns (address);

    function resolved() external view returns (bool);

    function phase() external view returns (Phase);

    function oraclePrice() external view returns (uint);

    function oraclePriceAndTimestamp() external view returns (uint price, uint updatedAt);

    function canResolve() external view returns (bool);

    function result() external view returns (Side);

    function balancesOf(address account) external view returns (uint up, uint down);

    function totalSupplies() external view returns (uint up, uint down);

    function getMaximumBurnable(address account) external view returns (uint amount);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function mint(uint value) external;

    function exerciseOptions() external returns (uint);

    function burnOptions(uint amount) external;

    function burnOptionsMaximum() external;
}