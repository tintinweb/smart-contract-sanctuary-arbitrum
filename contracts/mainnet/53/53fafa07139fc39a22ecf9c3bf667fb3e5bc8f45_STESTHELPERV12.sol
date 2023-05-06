/**
 *Submitted for verification at Arbiscan on 2023-05-06
*/

// Sources flattened with hardhat v2.14.0 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// 
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

// pragma solidity ^0.8.1;

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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

// 
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

// pragma solidity ^0.8.2;

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
 */
abstract contract Initializable {
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
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
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
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
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
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// 
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

// pragma solidity ^0.8.0;

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/access/[email protected]

// 
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// pragma solidity ^0.8.0;


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
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

// 
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

// pragma solidity ^0.8.0;

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


// File contracts/STESTHELPER.sol

// SPDX-License-Identifier: UNLICENSED

//     ███████╗████████╗ █████╗ ██╗██╗  ██╗    █████╗ ██╗
//     ██╔════╝╚══██╔══╝██╔══██╗██║██║ ██╔╝   ██╔══██╗██║
//     ███████╗   ██║   ███████║██║█████╔╝    ███████║██║
//     ╚════██║   ██║   ██╔══██║██║██╔═██╗    ██╔══██║██║
//     ███████║   ██║   ██║  ██║██║██║  ██╗██╗██║  ██║██║
//     ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝╚═╝

// Helper contract used by STAIK token to calculate BPL and SPR values, as well as incorporating
// the anti-whale mechanism

pragma solidity ^0.8.0;

/// @notice interface to retrieve balances for STAIK and USDC in Ranch contracts
interface ISTAIK {
    function excludeFromMaxTx(address _address) external;
    function excludeAddress(address _address) external;
}

/// @notice interface for on-chain price oracle
interface ISTAIKOracle {
    function getRate(IERC20 srcToken, IERC20 dstToken, IERC20 connector) external view returns (uint256 weightedRate);
}

contract STESTHELPERV12 is Initializable, OwnableUpgradeable {

    /// STAIK Token address 
    address public staikAddress; 
    
    /// STAIKOracle for spot prices
    address public staikOracleAddress;  
    
    address public wethAddress;     // 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1
    address public wbtcAddress;     // 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f
    address public usdcAddress;     // 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8

    /// used to check for USDC de-peg!
    address public usdtAddress;     // 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9

    /// DAO governance multisig
    address public DAO;


    ISTAIK public staik;
    ISTAIKOracle public staikOracle;
    
    IERC20 public STAIK;
    IERC20 public WETH;
    IERC20 public WBTC;
    IERC20 public USDC;
    IERC20 public USDT;


    //////////////////////////////////////////////////////////////////////////////

    /// current total BPL and SPR values
    uint16 public dynamicBPL;
    uint16 public dynamicSPR;

    /// previous BPL and SPR values
    uint16 public dynamicBPLPrevious;
    uint16 public dynamicSPRPrevious;

    /// individual BPL SPR values for combines and STAIK
    uint16 public cBPL;
    uint16 public cSPR;
    uint16 public staikBPL;
    uint16 public staikSPR;

    /// min max values set for BPL and SPR
    uint16 public bplMin; // bps
    uint16 public bplMax; // bps
    uint16 public sprMin; // bps
    uint16 public sprMax; // bps

    /// Combined percentage above base (in bps)
    uint16 public cPercentAbove; // initially set to 2% (200 bps)
    /// Combined percentage below base (in bps)
    uint16 public cPercentBelow; // initially set to 1% (100 bps)

    /// STAIK percentage above base (in bps)
    uint16 public staikPercentAbove; // initially set to 20% (2000 bps)
    /// STAIK percentage below base (in bps)
    uint16 public staikPercentBelow; // initially set to 10% (1000 bps)

    /// target base growth for each "staikBasetimer" time period
    uint16 public staikBaseGrowthPercent; // initially set to 2% (200 bps)
    /// time period for STAIK base growth - set to 1 day by default
    uint256 public staikBaseGrowthWaitPeriod;
    /// time period for STAIK base growth - set to 1 day by default
    uint256 public staikBaseGrowthTimestamp;

    /// Combined WBTC + WETH base value
    uint256 public cBaseValue;
    /// STAIK base value
    uint256 public staikBaseValue;
    
    /// timestamp of when combined base value was set
    uint256 public cBaseTimestamp;
    /// timestamp of when STAIK base value was set
    uint256 public staikBaseTimestamp;

    /// Combined "candidate" base price
    uint256 public cBaseCandidate;
    /// STAIK "candidate" base price
    uint256 public staikBaseCandidate;
    
    /// Combined "candidate" timestamp (epoch)
    uint256 public cBaseCandidateTimestamp;
    /// STAIK "candidate" timestamp (epoch)
    uint256 public staikBaseCandidateTimestamp;

    /// Combined wait period
    uint256 public cBaseCandidateWaitPeriod; // 3 days
    /// STAIK wait period
    uint256 public staikBaseCandidateWaitPeriod; // 3 days

    /// antiwhale backoff timer
    uint256 public antiWhaleBackoff;  // 6 hours

    /// BPL recorded before antiwhale activated
    uint16 public bplPreAntiWhale;
    /// SPR recorded before antiwhale activated 
    uint16 public sprPreAntiWhale;
    
    /// timestamp of when BPL antiwhale was activated
    uint256 public timeAntiWhaleBPLLastInvoked;
    /// rimestamp of when SPR antiwhale was activated
    uint256 public timeAntiWhaleSPRLastInvoked;

    // bool antiwhale activated
    bool public antiWhaleBPL;
    bool public antiWhaleSPR;

    // confirmation of whether BPL/SPR is active
    bool public isBPLActive;
    bool public isSPRActive;

    /// confirmation of whether candidate baser timer has completed
    bool public cBaseCandidateTimerComplete;
    bool public staikBaseCandidateTimerComplete;

    bool public testingFunctions;

    bool public experimentalFunctions;

    uint256 public staikPriceTestValue;

    ///////////////////////////////////////////////////////////////
    
    //// contract functions ////

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializer
    function initialize(
        bool initialIsBPLActive,
        bool initialIsSPRActive,

        address initialStaikOracleAddress,
        address initialWethAddress,
        address initialWbtcAddress,
        address initialUsdcAddress,
        address initialUsdtAddress

        ) initializer public {

        OwnableUpgradeable.__Ownable_init();

        isBPLActive = initialIsBPLActive;
        isSPRActive = initialIsSPRActive;

        staikOracleAddress = initialStaikOracleAddress;
        wethAddress = initialWethAddress;
        wbtcAddress = initialWbtcAddress;
        usdcAddress = initialUsdcAddress;
        usdtAddress = initialUsdtAddress;

        WETH = IERC20(wethAddress);
        WBTC = IERC20(wbtcAddress);
        USDC = IERC20(usdcAddress);
        USDT = IERC20(usdtAddress);
        STAIK = IERC20(staikAddress);

        // staik = ISTAIK(staikAddress);
        // staikOracle = ISTAIKOracle(staikOracleAddress);

        cPercentAbove = 2000;                   // 20%
        cPercentBelow = 1000;                   // 10%
        staikPercentAbove = 500;                // 5%
        staikPercentBelow = 500;                // 5%
                       
        bplMax = 2500;                          // 25%
        sprMax = 2500;                          // 25%

        cBaseCandidateWaitPeriod = 259200;      // 3 days
        staikBaseCandidateWaitPeriod = 259200;  // 3 days

        antiWhaleBackoff = 21600;               // 6 hours
        staikBaseGrowthPercent = 200;           // 2%
        staikBaseGrowthWaitPeriod = 86400;      // 1 day

        cBPL = 0;
        cSPR = 0;
        staikBPL = 0;
        staikSPR = 0;

        experimentalFunctions = false;
        testingFunctions = true;
        // test value
        staikPriceTestValue = 10000;

        // temporarily set owner to DAO
        DAO = msg.sender;
    }

    /// @notice modifier for DAO governance to call functions
    modifier onlyDAO {
        require(msg.sender == DAO, "Only DAO can call this function");
        _;
    }

    /// @notice modifier for DAO governance to call functions
    modifier onlySTAIK {
        require(msg.sender == staikAddress, "Only STAIK Token can call this function");
        _;
    }

    /// @notice transition to DAO governance
    function setDAO(address _multisig) external onlyDAO {
        require(
            _multisig != address(0) &&
            _multisig != staikAddress &&
            _multisig != staikOracleAddress
        );
        DAO = _multisig;
    } 

    /// @notice set the STAIK token deployed address
    function setSTAIKTokenAddress(address _address) external onlyDAO {
        require(
            _address != address(0) &&
            _address != staikOracleAddress
        );
        staikAddress = _address;
        staik = ISTAIK(_address);
        STAIK = IERC20(_address);
    }

    /// @notice set/update the STAIK oracle deployed address
    function setSTAIKOracleAddress(address _address) external onlyDAO {
        require(
            _address != address(0) &&
            _address != staikAddress
        );
        staikOracleAddress = _address;
        staikOracle = ISTAIKOracle(staikOracleAddress);
    }

    /// @notice set tracked token addresses
    function setTrackedTokenAddresses(address _WETH, address _WBTC, address _USDC, address _USDT) external onlyDAO {
        wethAddress = _WETH;
        wbtcAddress = _WBTC;
        usdcAddress = _USDC; 
        usdtAddress = _USDT;
        WETH = IERC20(wethAddress);
        WBTC = IERC20(wbtcAddress);
        USDC = IERC20(usdcAddress);
        USDT = IERC20(usdtAddress);
    }

    /// @notice disable/enable both the BPL and SPR
    function setBPLSPRActive(bool _bpl, bool _spr) external onlyDAO {
        sprActive(_bpl);
        bplActive(_spr);
    }

    /// @notice disable/enable BPL
    function bplActive(bool _bool) internal {
        isBPLActive = _bool;
        if (isBPLActive == true) {
            dynamicBPLPrevious = dynamicBPL;
            dynamicBPL = 0;
        }
        else {
            dynamicBPL = dynamicBPLPrevious;
            dynamicBPLPrevious = 0;
        }
    }

    /// @notice disable/enable SPR
    function sprActive(bool _bool) internal {
        isSPRActive = _bool;
        if (isSPRActive == true) {
            dynamicSPRPrevious = dynamicSPR;
            dynamicSPR = 0;
        }
        else {
            dynamicSPR = dynamicSPRPrevious;
            dynamicSPRPrevious = 0;
        }
    }

    /// @notice set BPL/SPR min/max values (bps)
    function setBPLSPRMinMax(uint16 _bplMin, uint16 _bplMax, uint16 _sprMin, uint16 _sprMax) external onlyDAO {
        require (_bplMin >= 0 && _sprMin >= 0 && _bplMax <= 2500 && _sprMax <= 2500);
        bplMin = _bplMin;
        bplMax = _bplMax;
        sprMin = _sprMin;
        sprMax = _sprMax;
    }

    function experimentalAllowed(bool _choice) external onlyDAO {
        experimentalFunctions = _choice;
    }

    function testingAllowed() external onlyDAO {
        testingFunctions = false;
    }

    /// @notice test function - turns on/off the antiWhale BPL and SPR
    function testingSetAntiWhale(bool _setantiWhaleBPL, bool _setantiWhaleSPR) external onlyDAO {
        require(testingFunctions == true);
        antiWhaleBPL = _setantiWhaleBPL;
        antiWhaleSPR = _setantiWhaleSPR;
    }

    /// @notice test function - sets STAIK Test value
    function testingSetStaikPriceTestValue(uint256 _staikPrice) external onlyDAO {
        require(testingFunctions == true);
        staikPriceTestValue = _staikPrice;
    }

    /// @notice test function to reset all values
    function testingResetAllValues() external onlyDAO {
        require(testingFunctions == true);

        dynamicBPL = 0;
        dynamicSPR = 0;

        dynamicBPLPrevious = 0;
        dynamicSPRPrevious = 0;

        cBPL = 0;
        cSPR = 0;
        staikBPL = 0;
        staikSPR = 0;

        staikBaseGrowthTimestamp = 0;

        cBaseValue = 0;
        staikBaseValue = 0;
    
        cBaseTimestamp = 0;
        staikBaseTimestamp = 0;

        cBaseCandidate = 0;
        staikBaseCandidate = 0;
    
        cBaseCandidateTimestamp = 0;
        staikBaseCandidateTimestamp;

        bplPreAntiWhale = 0;
        sprPreAntiWhale = 0;
    
        timeAntiWhaleBPLLastInvoked = 0;
        timeAntiWhaleSPRLastInvoked = 0;

        antiWhaleBPL = false;
        antiWhaleSPR = false;

        cBaseCandidateTimerComplete = false;
        staikBaseCandidateTimerComplete = false;

        testingFunctions = true;
        experimentalFunctions = false;
    }

    /// @notice sets the AntiWhale backoff period (in seconds)
    function setAntiWhaleBackoff(uint32 _backoff) external onlyDAO {
        antiWhaleBackoff = _backoff;
    }

    /// @notice sets the wait period in seconds before candidate base price becomes new base price
    function setCBaseCandidateWaitPeriod (uint256 _wait) external onlyDAO {
        cBaseCandidateWaitPeriod = _wait;
    }

    /// @notice sets the wait period in seconds before STAIK candidate base price becomes new base price
    function setStaikBaseCandidateWaitPeriod (uint256 _wait) external onlyDAO {
        staikBaseCandidateWaitPeriod = _wait;
    }

    /// @notice sets the baseGrowth wait period
    function setStaikBaseGrowthWaitPeriod(uint16 _wait) external onlyDAO {
        staikBaseGrowthWaitPeriod = _wait;
    }

    /// @notice sets the baseGrowth value percentage for STAIK Value
    function setStaikBaseGrowthPercent(uint16 _percent) external onlyDAO {
        require(_percent <= 10000);
        staikBaseGrowthPercent = _percent;
    }

    /// @notice sets the Percent above and below values to determine upper and lower boundaries    
    function setPercentAboveBelow(
        uint16 _cPercentAbove, 
        uint16 _cPercentBelow, 
        uint16 _staikPercentAbove, 
        uint16 _staikPercentBelow
        ) external onlyDAO {  
        require(_cPercentAbove <= 10000);
        require(_cPercentBelow <= 10000);
        require(_staikPercentAbove <= 10000);
        require(_staikPercentBelow <= 10000);
        cPercentAbove = _cPercentAbove;                   
        cPercentBelow = _cPercentBelow;                   
        staikPercentAbove = _staikPercentAbove;           
        staikPercentBelow = _staikPercentBelow;           
    }


    /** 
    /// setBPLSPR is the core function of the contract that sets BPL/SPR values
    /// and also checks antiWhale. 
    /// This function requires "isBPLActive" and "isSPRActive" to be true
    */
    function setBPLSPR() public returns (uint256 dynamicBpl, uint256 dynamicSpr) {

        /// Firstly confirm that both BPL and SPR are active
        require(isBPLActive && isSPRActive);

        /**
        /// update combined base value and STAIK base value (with timestamps) if required - 
        /// will skip over this function if base values are already set
        */
        // updateBaseValuesIfRequired();
        updateBaseValuesIfRequiredv2();

        /**
        /// checks if STAIK base growth timer has elapsed and therefore the STAIK base value needs updating 
        */
        if (experimentalFunctions == true) {
        updateSTAIKBaseIfRequired();
        }

        /**
        /// update candidate combined base timer completed and STAIK base timer completed if required
        /// will skip over this function if candidate base timer is not yet complete
        */
        // updateBaseCandidateTimersCompletedIfRequired();
        updateBaseCandidateTimersCompletedIfRequiredv2();

        /**
        /// checks if current price is OUTSIDE of range and if so, 
        /// updates combined base candidate and STAIK base candidate (and timestamps) if required
        /// will skip this function if the current price is INSIDE range
        */
        // updateOutsideRangeIfRequired();
        updateOutsideRangeIfRequiredv2();

        /**
        /// checks if current price is INSIDE of range and if so, 
        /// updates combined base candidate and STAIK base candidate (and timestamps) if required
        /// will skip this function if the current price is OUTSIDE range 
        */
        // updateInsideRangeIfRequired();
        updateInsideRangeIfRequiredv2();

        /// now update dynamic BPL/SPR values
        dynamicBPL = limitToMaxValue(cBPL + staikBPL, bplMax);
        dynamicSPR = limitToMaxValue(cSPR + staikSPR, sprMax);

        /// check antiWhale to see if dynamicBPL or dynamicSPR needs to be overriden
        checkAntiWhale();

        // finally, return the latest BPL and SPR values
        return (dynamicBPL, dynamicSPR);
    }


    // /// @notice used by the setBPLSPR() function if needed to update base values
    // function updateBaseValuesIfRequired() public {

    //     if(experimentalFunctions == true) {
    //         uint256 _cPriceCurrent = cPriceInUSD(); // 30606840834207213715400
    //         uint256 _staikPriceCurrent = staikPriceInUSD(); // 0
    //         /// if base value has not been set
    //         if (cBaseValue == 0 && _cPriceCurrent > 0) { // true
    //             cBaseValue = _cPriceCurrent;
    //             cBaseTimestamp = block.timestamp;
    //         }   

    //         /// if base value has not been set or testing is off
    //         if (staikBaseValue == 0 && _staikPriceCurrent > 0) { // false
    //             staikBaseValue = _staikPriceCurrent; 
    //             staikBaseTimestamp = block.timestamp;
    //             // initialize the growth timestamp
    //             staikBaseGrowthTimestamp = block.timestamp;
    //         }

    //         /// if testing is switched on 
    //         if (staikBaseValue == 0 && testingFunctions == true && staikPriceTestValue > 0) { // false
    //             staikBaseValue = staikPriceTestValue; 
    //             staikBaseTimestamp = block.timestamp;
    //             // initialize the growth timestamp
    //             staikBaseGrowthTimestamp = block.timestamp;
    //         }
    //     }
    //     else {
    //         uint256 _cPriceCurrent = cPriceInUSD(); // 
    //         /// if base value has not been set
    //         if (cBaseValue == 0 && _cPriceCurrent > 0) { 
    //             cBaseValue = _cPriceCurrent;
    //             cBaseTimestamp = block.timestamp;
    //         }   
    //     }

    // }

    function updateBaseValuesIfRequiredv2() public {
        if(experimentalFunctions == true) {
            updateBaseValuesCPrice();
            updateBaseValuesStaikPrice();
        }
        else {
            updateBaseValuesCPrice();
        }
    }

    function updateBaseValuesCPrice() public { 
        if (cBaseValue == 0 && cPriceInUSD() > 0) { 
            uint256 _cPriceCurrent = cPriceInUSD();
            cBaseValue = _cPriceCurrent;
            cBaseTimestamp = block.timestamp;
        }
    }   

    function updateBaseValuesStaikPrice() public { 
        if(experimentalFunctions == true) {
            uint256 _staikPriceCurrent = staikPriceInUSD(); // 0

            /// if testing is switched on 
            if (staikBaseValue == 0 && testingFunctions == true && staikPriceTestValue > 0) { // false
                staikBaseValue = staikPriceTestValue; 
                staikBaseTimestamp = block.timestamp;
                // initialize the growth timestamp
                staikBaseGrowthTimestamp = block.timestamp;
            }

            /// if base value has not been set or testing is off
            if (staikBaseValue == 0 && testingFunctions == false && _staikPriceCurrent > 0) { // false
                staikBaseValue = _staikPriceCurrent; 
                staikBaseTimestamp = block.timestamp;
                // initialize the growth timestamp
                staikBaseGrowthTimestamp = block.timestamp;
            }
        }
    }  


    /// @notice used by the setBPLSPR() function above to check if STAIK base value needs to be updated
    /// @dev potential for rounding errors, however this would have minimal impact
    function updateSTAIKBaseIfRequired() public {
        if (staikBaseGrowthWaitPeriod > 0 && staikBaseValue != 0) { // true
            uint256 periodsElapsed = (block.timestamp - staikBaseGrowthTimestamp) / staikBaseGrowthWaitPeriod;
            if (periodsElapsed > 0) {
                // update base value
                uint256 growthFactor = uint256(staikBaseGrowthPercent) ** uint256(periodsElapsed);
                staikBaseValue = (staikBaseValue * growthFactor) / 10000;
                // update timestamp
                staikBaseGrowthTimestamp += periodsElapsed * staikBaseGrowthWaitPeriod;
            }
        }
    }


    // /**
    // /// @notice used by the setBPLSPR() function if needed to update timers completed bools
    // /// will skip if base candidate timestamps haven't been set yet
    // */
    // function updateBaseCandidateTimersCompletedIfRequired() public {
    //    if (experimentalFunctions == true) {   
    //         if (cBaseCandidateTimestamp > 0 && cBaseCandidateTimestamp + cBaseCandidateWaitPeriod <= block.timestamp) { // false
    //             cBaseCandidateTimerComplete = true;
    //         }
    //         if (staikBaseCandidateTimestamp > 0 && staikBaseCandidateTimestamp + staikBaseCandidateWaitPeriod <= block.timestamp) { // false
    //             staikBaseCandidateTimerComplete = true;
    //         }
    //    } 
    //    else {
    //         if (cBaseCandidateTimestamp > 0 && cBaseCandidateTimestamp + cBaseCandidateWaitPeriod <= block.timestamp) { // false
    //             cBaseCandidateTimerComplete = true;
    //         }
    //    }    
    // }

    /**
    /// @notice used by the setBPLSPR() function if needed to update timers completed bools
    /// will skip if base candidate timestamps haven't been set yet
    */
    function updateBaseCandidateTimersCompletedIfRequiredv2() public {
        if(experimentalFunctions == true) {
            updateBaseCandidateTimersCompletedIfRequiredC();
            updateBaseCandidateTimersCompletedIfRequiredStaik();
        }
        else {
            updateBaseCandidateTimersCompletedIfRequiredC();
        }
    }


    function updateBaseCandidateTimersCompletedIfRequiredC() public {
        if (cBaseCandidateTimestamp > 0 && cBaseCandidateTimestamp + cBaseCandidateWaitPeriod <= block.timestamp) { // false
            cBaseCandidateTimerComplete = true;
        }
    }


    function updateBaseCandidateTimersCompletedIfRequiredStaik() public {
        if (staikBaseCandidateTimestamp > 0 && staikBaseCandidateTimestamp + staikBaseCandidateWaitPeriod <= block.timestamp) { // false
            staikBaseCandidateTimerComplete = true;
        }
    }






    // /// @notice used by the setBPLSPR() function if needed to update candidate values
    // /// and the cBPL cSPR staikBPL staikSPR values
    // function updateOutsideRangeIfRequired() public {
    //     if (testingFunctions == true) {
    //         uint256 _cPriceCurrent = cPriceInUSD();  // 30606840834207213715400
    //         uint256 _staikPriceCurrent = staikPriceInUSD(); // 10000

    //         uint256 _cBaseCandidate = cBaseCandidate; // 0
    //         uint256 _staikBaseCandidate = staikBaseCandidate; // 0

    //         uint256 _cUpperRange = getCpbUpperRange(); // 0
    //         uint256 _cLowerRange = getCpbLowerRange();  // 0
    //         uint256 _staikUpperRange = getStaikUpperRange(); // 0
    //         uint256 _staikLowerRange = getStaikLowerRange(); // 0

    //         bool _cBaseCandidateTimerComplete = cBaseCandidateTimerComplete; // false
    //         bool _staikBaseCandidateTimerComplete = staikBaseCandidateTimerComplete; // false


    //         // used for testing when STAIK value cannot be derived
    //         if (_staikPriceCurrent == 0 && testingFunctions == true) { // false
    //             _staikPriceCurrent = staikPriceTestValue;
    //         }
                
    //         /// if the current price is OUTSIDE range and timer is not complete

    //         /// if price is above upper range    
    //         if(_cPriceCurrent > _cUpperRange && _cBaseCandidateTimerComplete == false) {  // true
    //             uint256 increaseAsPercent = ((_cPriceCurrent - _cUpperRange) * 10000) / _cUpperRange;
    //             cBPL = uint16(increaseAsPercent);
    //         }

    //         if(_staikPriceCurrent > _staikUpperRange && _staikBaseCandidateTimerComplete == false) { // true
    //             uint256 increaseAsPercent = ((_staikPriceCurrent - _staikUpperRange) * 10000) / _staikUpperRange;
    //             staikBPL = uint16(increaseAsPercent);
    //         }

    //         /// if price is below lower range    
    //         if(_cPriceCurrent < _cLowerRange && _cBaseCandidateTimerComplete == false) {  // false
    //             uint256 decreaseAsPercent = ((_cLowerRange - _cPriceCurrent) * 10000) / _cLowerRange;
    //             cSPR = uint16(decreaseAsPercent);
    //         }

    //         if(_staikPriceCurrent < _staikUpperRange && _staikBaseCandidateTimerComplete == false) {  // false
    //             uint256 decreaseAsPercent = ((_staikLowerRange - _staikPriceCurrent) * 10000) / _staikLowerRange;
    //             staikSPR = uint16(decreaseAsPercent);
    //         }

    //         // outside range and candidate base timers complete - base candidate timestamp must have already been set
    //         // for base candidate timestamp to be true
                        
    //         if ((_cPriceCurrent > _cUpperRange || _cPriceCurrent < _cLowerRange) && _cBaseCandidateTimerComplete == true) {  // false
    //             /// update/reset values as candidate becomes the new base
    //             cBaseValue = _cBaseCandidate;  
    //             cBaseTimestamp = block.timestamp;  
    //             cBaseCandidate = 0;
    //             cBaseCandidateTimestamp = 0;
    //             cBaseCandidateTimerComplete = false;
    //             cBPL = 0;
    //             cSPR = 0;
    //         }

    //         if ((_staikPriceCurrent > _staikUpperRange || _staikPriceCurrent < _staikLowerRange) && _staikBaseCandidateTimerComplete == true) {  // false
    //             /// update/reset values as candidate becomes the new base
    //             staikBaseValue = _staikBaseCandidate;
    //             staikBaseTimestamp = block.timestamp;
    //             staikBaseCandidate = 0;
    //             staikBaseCandidateTimestamp = 0;
    //             staikBaseCandidateTimerComplete = false;
    //             staikBPL = 0;
    //             staikSPR = 0;
    //         }
    //     }

    //     else {
    //         uint256 _cPriceCurrent = cPriceInUSD();  // 30606840834207213715400

    //         uint256 _cBaseCandidate = cBaseCandidate; // 0

    //         uint256 _cUpperRange = getCpbUpperRange(); // 0
    //         uint256 _cLowerRange = getCpbLowerRange();  // 0

    //         bool _cBaseCandidateTimerComplete = cBaseCandidateTimerComplete; // false
               
    //         /// if the current price is OUTSIDE range and timer is not complete

    //         /// if price is above upper range    
    //         if(_cPriceCurrent > _cUpperRange && _cBaseCandidateTimerComplete == false) {  // true
    //             uint256 increaseAsPercent = ((_cPriceCurrent - _cUpperRange) * 10000) / _cUpperRange;
    //             cBPL = uint16(increaseAsPercent);
    //         }

    //         /// if price is below lower range    
    //         if(_cPriceCurrent < _cLowerRange && _cBaseCandidateTimerComplete == false) {  // false
    //             uint256 decreaseAsPercent = ((_cLowerRange - _cPriceCurrent) * 10000) / _cLowerRange;
    //             cSPR = uint16(decreaseAsPercent);
    //         }

    //         // outside range and candidate base timers complete - base candidate timestamp must have already been set
    //         // for base candidate timestamp to be true
                        
    //         if ((_cPriceCurrent > _cUpperRange || _cPriceCurrent < _cLowerRange) && _cBaseCandidateTimerComplete == true) {  // false
    //             /// update/reset values as candidate becomes the new base
    //             cBaseValue = _cBaseCandidate;  
    //             cBaseTimestamp = block.timestamp;  
    //             cBaseCandidate = 0;
    //             cBaseCandidateTimestamp = 0;
    //             cBaseCandidateTimerComplete = false;
    //             cBPL = 0;
    //             cSPR = 0;
    //         }
    //     }

    // }


    function updateOutsideRangeIfRequiredv2() public {
        if(experimentalFunctions == true) {
            updateOutsideRangeIfRequiredC();
            updateOutsideRangeIfRequiredStaik();
        }
        else {
            updateOutsideRangeIfRequiredC();
        }
    }
        
        
    function updateOutsideRangeIfRequiredC() public {
        uint256 _cPriceCurrent = cPriceInUSD();  // 30606840834207213715400

        uint256 _cBaseCandidate = cBaseCandidate; // 0

        uint256 _cUpperRange = getCpbUpperRange(); // 0
        uint256 _cLowerRange = getCpbLowerRange();  // 0

        bool _cBaseCandidateTimerComplete = cBaseCandidateTimerComplete; // false
               
        /// if the current price is OUTSIDE range and timer is not complete

        /// if price is above upper range   
        if (_cUpperRange != 0) { 
            if(_cPriceCurrent > _cUpperRange && _cBaseCandidateTimerComplete == false) {  // true
                uint256 increaseAsPercent = ((_cPriceCurrent - _cUpperRange) * 10000) / _cUpperRange;
                cBPL = uint16(increaseAsPercent);
            }
        } else cBPL = 0;

            /// if price is below lower range    
        if (_cLowerRange != 0) {
            if(_cPriceCurrent < _cLowerRange && _cBaseCandidateTimerComplete == false) {  // false
                uint256 decreaseAsPercent = ((_cLowerRange - _cPriceCurrent) * 10000) / _cLowerRange;
                cSPR = uint16(decreaseAsPercent);
            }
        } else cSPR = 0;

        // outside range and candidate base timers complete - base candidate timestamp must have already been set
        // for base candidate timestamp to be true
                       
        if ((_cPriceCurrent > _cUpperRange || _cPriceCurrent < _cLowerRange) && _cBaseCandidateTimerComplete == true) {  // false
            /// update/reset values as candidate becomes the new base
            cBaseValue = _cBaseCandidate;  
            cBaseTimestamp = block.timestamp;  
            cBaseCandidate = 0;
            cBaseCandidateTimestamp = 0;
            cBaseCandidateTimerComplete = false;
            cBPL = 0;
            cSPR = 0;
        }

    }


    function updateOutsideRangeIfRequiredStaik() public {
        uint256 _staikPriceCurrent = staikPriceInUSD();  

        uint256 _staikBaseCandidate = staikBaseCandidate; // 0

        uint256 _staikUpperRange = getStaikUpperRange(); // 0
        uint256 _staikLowerRange = getStaikLowerRange();  // 0

        bool _staikBaseCandidateTimerComplete = staikBaseCandidateTimerComplete; // false
               
        /// if the current price is OUTSIDE range and timer is not complete

        
        if (_staikUpperRange != 0) {
            /// if price is above upper range    
            if(_staikPriceCurrent > _staikUpperRange && _staikBaseCandidateTimerComplete == false) {  // true
                uint256 increaseAsPercent = ((_staikPriceCurrent - _staikUpperRange) * 10000) / _staikUpperRange;
                staikBPL = uint16(increaseAsPercent);
            }
        } else staikBPL = 0;

        if(_staikLowerRange != 0) {
            /// if price is below lower range    
            if(_staikPriceCurrent < _staikLowerRange && _staikBaseCandidateTimerComplete == false) {  // false
                uint256 decreaseAsPercent = ((_staikLowerRange - _staikPriceCurrent) * 10000) / _staikLowerRange;
                staikSPR = uint16(decreaseAsPercent);
            }
        } else staikSPR = 0;


        // outside range and candidate base timers complete - base candidate timestamp must have already been set
        // for base candidate timestamp to be true
                       
        if ((_staikPriceCurrent > _staikUpperRange || _staikPriceCurrent < _staikLowerRange) && _staikBaseCandidateTimerComplete == true) {  // false
            /// update/reset values as candidate becomes the new base
            staikBaseValue = _staikBaseCandidate;  
            staikBaseTimestamp = block.timestamp;  
            staikBaseCandidate = 0;
            staikBaseCandidateTimestamp = 0;
            staikBaseCandidateTimerComplete = false;
            staikBPL = 0;
            staikSPR = 0;
        }

    }






    // /// @notice used by the setBPLSPR() function if current price is inside range
    // function updateInsideRangeIfRequired() public {
    //     if (testingFunctions == true) {
    //         uint256 _cPriceCurrent = cPriceInUSD();     // 30606840834207213715400
    //         uint256 _staikPriceCurrent = staikPriceInUSD(); // 10000

    //         uint256 _cUpperRange = getCpbUpperRange(); // 0
    //         uint256 _cLowerRange = getCpbLowerRange(); // 0
    //         uint256 _staikUpperRange = getStaikUpperRange(); // 0
    //         uint256 _staikLowerRange = getStaikLowerRange(); // 0
            
    //         uint16 _cBPL = cBPL; // 0
    //         uint16 _cSPR = cSPR; // 0
    //         uint16 _staikBPL = staikBPL; // 0
    //         uint16 _staikSPR = staikSPR; // 0

    //         // if the price is inside range 

    //         if (_cPriceCurrent <= _cUpperRange && _cPriceCurrent >= _cLowerRange) { // false

    //             // reset individual BPL SPR values if necessary
    //             if (_cBPL != 0) {
    //                 cBPL = 0;
    //             }
    //             if (_cSPR != 0) {
    //                 cSPR = 0;
    //             }
    //             // Also reset candidate base value and timestamp if necessary
    //             if (cBaseCandidate != 0) {
    //                 cBaseCandidate = 0;
    //             }
    //             if (cBaseCandidateTimestamp != 0) {
    //                 cBaseCandidateTimestamp = 0;
    //             }          
    //         } 

    //         if (_staikPriceCurrent <= _staikUpperRange && _staikPriceCurrent >= _staikLowerRange) { // false

    //             if (_staikBPL != 0) {
    //                 staikBPL = 0;
    //             }
    //             if (_staikSPR != 0) {
    //                 staikSPR = 0;
    //             }
    //             // Also reset candidate base value and timestamp 
    //             if (staikBaseCandidate != 0) {
    //                 staikBaseCandidate = 0;
    //             }
    //             if (staikBaseCandidateTimestamp != 0) {
    //                 staikBaseCandidateTimestamp = 0;
    //             }          
    //         } 
    //     }

    //     else {
    //         uint256 _cPriceCurrent = cPriceInUSD();     // 30606840834207213715400

    //         uint256 _cUpperRange = getCpbUpperRange(); // 0
    //         uint256 _cLowerRange = getCpbLowerRange(); // 0
            
    //         uint16 _cBPL = cBPL; // 0
    //         uint16 _cSPR = cSPR; // 0

    //         // if the price is inside range 

    //         if (_cPriceCurrent <= _cUpperRange && _cPriceCurrent >= _cLowerRange) { // false

    //             // reset individual BPL SPR values if necessary
    //             if (_cBPL != 0) {
    //                 cBPL = 0;
    //             }
    //             if (_cSPR != 0) {
    //                 cSPR = 0;
    //             }
    //             // Also reset candidate base value and timestamp if necessary
    //             if (cBaseCandidate != 0) {
    //                 cBaseCandidate = 0;
    //             }
    //             if (cBaseCandidateTimestamp != 0) {
    //                 cBaseCandidateTimestamp = 0;
    //             }          
    //         } 
    //     }
    // }



    function updateInsideRangeIfRequiredv2() public {
        if(experimentalFunctions == true) {
            updateInsideRangeIfRequiredC();
            updateInsideRangeIfRequiredStaik();
        }
        else {
            updateInsideRangeIfRequiredC();
        }
    }
      
    function updateInsideRangeIfRequiredC() public {
        uint256 _cPriceCurrent = cPriceInUSD();

        uint256 _cUpperRange = getCpbUpperRange();
        uint256 _cLowerRange = getCpbLowerRange();

        uint16 _cBPL = cBPL;
        uint16 _cSPR = cSPR;

        // if the price is inside range
        if (
            _cUpperRange != 0 && 
            _cLowerRange != 0 && 
            _cPriceCurrent <= _cUpperRange &&
             _cPriceCurrent >= _cLowerRange
        ) {

            // reset individual BPL SPR values if necessary
            if (_cBPL != 0) {
                cBPL = 0;
            }
            if (_cSPR != 0) {
                cSPR = 0;
            }
            // Also reset candidate base value and timestamp if necessary
            if (cBaseCandidate != 0) {
                cBaseCandidate = 0;
            }
            if (cBaseCandidateTimestamp != 0) {
                cBaseCandidateTimestamp = 0;
            }          
        } 
    }

    function updateInsideRangeIfRequiredStaik() public {
        uint256 _staikPriceCurrent = staikPriceInUSD();

        uint256 _staikUpperRange = getStaikUpperRange();
        uint256 _staikLowerRange = getStaikLowerRange();

        uint16 _staikBPL = staikBPL;
        uint16 _staikSPR = staikSPR;

        // if the price is inside range
        if (
            _staikUpperRange != 0 && 
            _staikLowerRange != 0 && 
            _staikPriceCurrent <= _staikUpperRange 
            && _staikPriceCurrent >= _staikLowerRange
        ) {

            // reset individual BPL SPR values if necessary
            if (_staikBPL != 0) {
                staikBPL = 0;
            }
            if (_staikSPR != 0) {
                staikSPR = 0;
            }
            // Also reset candidate base value and timestamp if necessary
            if (staikBaseCandidate != 0) {
                staikBaseCandidate = 0;
            }
            if (staikBaseCandidateTimestamp != 0) {
                staikBaseCandidateTimestamp = 0;
            }          
        } 
    }




    /// @notice used by the setBPLSPR() function above to check if BPL SPR value needs to be limited
    function limitToMaxValue(uint16 addedTogether, uint16 max) public pure returns (uint16) {
        if (addedTogether > max) { // false
            return max;
        }
        return addedTogether;
    }

    /// @notice function used to check if considerably large transaction has been made
    function checkAntiWhale() public {

        // first confirm there is no stablecoin de-peg (market turbulence expected!)
        uint256 currentUSDTPrice = usdtPriceInUSD();
       
        // If there is a 5% USDC de-peg either way, set both buy and sell tax to max temporarily!
        if (currentUSDTPrice <= 950000000000000000 || currentUSDTPrice >= 1050000000000000000) {
            
            dynamicBPL = bplMax;
            dynamicSPR = sprMax;
        } else {
            // If no USDC de-peg detected, call both internal functions
            handleAntiWhaleBPL();
            handleAntiWhaleSPR();
        }
    }

    /// @notice function used by checkAntiWhale() for BPL
    function handleAntiWhaleBPL() public {
        // if anti-whale is TRUE, i.e.. large transaction detected....
        if (antiWhaleBPL) {
            // if anti-whale wasn't previously invoked....
            if (timeAntiWhaleBPLLastInvoked == 0) {
                timeAntiWhaleBPLLastInvoked = block.timestamp;
                // backup BPL
                bplPreAntiWhale = dynamicBPL;
                // set BPL to MAX
                dynamicBPL = bplMax;
            // anti-whale was previously invoked, but backoff time has now passed
            } else if ((timeAntiWhaleBPLLastInvoked + antiWhaleBackoff) <= block.timestamp) {
                // reset anti-whale
                antiWhaleBPL = false;
                timeAntiWhaleBPLLastInvoked = 0;
                dynamicBPL = bplPreAntiWhale;
                bplPreAntiWhale = 0;
            }
        }
    }

    /// @notice function used by checkAntiWhale() for SPR
    function handleAntiWhaleSPR() public {
        // if anti-whale is TRUE, i.e.. large transaction detected....
        if (antiWhaleSPR) {
            // if anti-whale wasn't previously invoked....
            if (timeAntiWhaleSPRLastInvoked == 0) {
                timeAntiWhaleSPRLastInvoked = uint32(block.timestamp);
                // backup SPR
                sprPreAntiWhale = dynamicSPR;
                // set SPR to MAX
                dynamicSPR = sprMax;
            // anti-whale was previously invoked, but backoff time has now passed
            } else if ((timeAntiWhaleSPRLastInvoked + antiWhaleBackoff) <= uint32(block.timestamp)) {
                // reset anti-whale
                antiWhaleSPR = false;
                timeAntiWhaleSPRLastInvoked = 0;
                dynamicSPR = sprPreAntiWhale;
                sprPreAntiWhale = 0;
            }
        }
    }


    //////////////////////////////////////////////////////////////////////////////////

    /// @notice used to check STAIK price in $
    /// @dev use try/catch for testing to avoid potential revert prior to adding to DEX pool
    function staikPriceInUSD() public view returns (uint256 staikPrice) {    
        if (experimentalFunctions == true) {
            if (staikOracle.getRate(STAIK, USDC, WETH) != 0) {
                return staikOracle.getRate(STAIK, USDC, WETH);
            }
            else return staikPriceTestValue;
        } else return 0;
    }



    //         // if (staikValueFromOracle == 0 && testingFunctions == true) {
    //         //     return staikPriceTestValue;
    //         // } else {
    //         //     return staikValueFromOracle;
    //         // }
           
           
           
           
    //         uint256 staikValueFromOracle;

    //         try staikOracle.getRate(STAIK, USDC, WETH) returns (uint256 fetchedRate) {
    //             staikValueFromOracle = fetchedRate;
    //         } catch {
    //             staikValueFromOracle = 0;
    //         }

    //         if (staikValueFromOracle == 0 && testingFunctions == true) {
    //             return staikPriceTestValue;
    //         } else {
    //             return staikValueFromOracle;
    //         }
    //     } else {
    //         return 0;
    //     }
    // }
    
    /// @notice used to check COMBINED WBTC and WETH price in $
    function cPriceInUSD() public view returns (uint256) {    
        uint256 currentWETHPrice = wethPriceInUSD();
        uint256 currentWBTCPrice = wbtcPriceInUSD();
        // check combined price without updating
        return currentWETHPrice + currentWBTCPrice; 
    }

    /// @notice used to check WETH price in $
    function wethPriceInUSD() public view returns (uint256) {
        if (staikOracle.getRate(WETH, USDC, WETH) != 0) {
            uint256 WETHPrice = staikOracle.getRate(WETH, USDC, WETH);
            // allows pricing to be returned at matching decimal precision as WBTC
            return WETHPrice * 1e12;
        } else return 0;
    }

    /// @notice used to check WBTC price in $
    function wbtcPriceInUSD() public view returns (uint256) {
        if (staikOracle.getRate(WBTC, USDC, WETH) != 0) {
            uint256 WBTCPrice = staikOracle.getRate(WBTC, USDC, WETH);
            // allows pricing to be returned at matching decimal precision as WETH
            return WBTCPrice * 1e2;
        } else return 0;
    }

    /// @notice used to confirm there is no USDC de-peg event!
    function usdtPriceInUSD() public view returns (uint256) {
        if (staikOracle.getRate(USDT, USDC, WETH) != 0) {
            return staikOracle.getRate(USDT, USDC, WETH);
        } else return 0;
    }

    //////////////////////////////////////////////////////////////////////////////////

 
    /// @notice used to view current BPL value
    function getBPL() public view returns (uint256) {
        return dynamicBPL;
    }

    /// @notice used to view current SPR value
    function getSPR() public view returns (uint256) {
        return dynamicSPR;
    }

    //////////////////////////////////////////////////////////

    /// @notice used to view antiwhale BPL
    function getAntiWhaleBPL() public view returns (bool) {
        return antiWhaleBPL;
    }

     /// @notice used to view antiwhale SPR
    function getAntiWhaleSPR() public view returns (bool) {
        return antiWhaleSPR;
    }

    /// @notice used to view combined Base upper range value
    function getCpbUpperRange() public view returns (uint256) {
        return (cBaseValue * (10000 + cPercentAbove)) / 10000;
    }

    /// @notice used to view combined Base lower range value
    function getCpbLowerRange() public view returns (uint256) {
        return (cBaseValue * (10000 + cPercentBelow)) / 10000;
    }

    /// @notice used to view STAIK Base upper range value
    function getStaikUpperRange() public view returns (uint256) {
        return (staikBaseValue * (10000 + staikPercentAbove)) / 10000;
    }

    /// @notice used to view STAIK Base lower range value
    function getStaikLowerRange() public view returns (uint256) {
        return (staikBaseValue * (10000 + staikPercentBelow)) / 10000;
    }


}