/**
 *Submitted for verification at Arbiscan on 2023-04-25
*/

// Sources flattened with hardhat v2.14.0 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/utils/[email protected]


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
// interface for on-chain price oracle
interface ISTAIKOracle {
    function getRate(IERC20 srcToken, IERC20 dstToken, bool useWrappers) external view returns (uint256 weightedRate);
}

contract STESTHELPER is Initializable, OwnableUpgradeable {

    // STAIK Token address //
    address public staikAddress; // add once token is deployed
    
    // STAIKOracle for spot prices
    // address public staikOracleAddress = 0x75256775F58105bFebb5eC1838E2e82352604561;   
    address public staikOracleAddress;  
    
    // ISTAIKOracle public staikOracle = ISTAIKOracle(staikOracleAddress);
    
    // Arbitrum token contract addresses //
    // address public wethAddress = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    // address public wbtcAddress = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;
    // address public usdcAddress = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    // // used to check for de-peg events!
    // address public usdtAddress = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;

    address public wethAddress;
    address public wbtcAddress;
    address public usdcAddress;
    // used to check for de-peg events!
    address public usdtAddress;



    // DAO governance multisig
    address public DAO;
   
    // IERC20 public STAIK = IERC20(staikAddress);

    // IERC20 public WETH = IERC20(wethAddress);
    // IERC20 public WBTC = IERC20(wbtcAddress);
    // IERC20 public USDC = IERC20(usdcAddress);
    // IERC20 public USDT = IERC20(usdtAddress);

    IERC20 public STAIK;

    IERC20 public WETH;
    IERC20 public WBTC;
    IERC20 public USDC;
    IERC20 public USDT;

    ISTAIKOracle public staikOracle;



    //////////////////////////////////////////////////////////////////////////////

    // Burner address 
    // address public burnerAddress = 0x000000000000000000000000000000000000dEaD;
    address public burnerAddress;

    // WBTC + WETH price combined
    uint256 public combinePriceBase;
    uint256 public combinePriceCurrent;
    // STAIK base price
    uint256 public staikPriceBase;
    uint256 public staikPriceCurrent;

    // percentage above base (in bps)
    // uint256 public cpbPercentAbove = 200; // initially set to 2% (200 bps)
    uint256 public cpbPercentAbove; // initially set to 2% (200 bps)
    // percentage below base (in bps)
    // uint256 public cpbPercentBelow = 100; // initially set to 1% (100 bps)
    uint256 public cpbPercentBelow; // initially set to 1% (100 bps)

    // base higher range value
    uint256 public cpbHigherRange;
    // base range lower
    uint256 public cpbLowerRange;

    // STAIK percentage above base (in bps)
    // uint256 public staikPercentAbove = 2000; // initially set to 20% (2000 bps)
    uint256 public staikPercentAbove; // initially set to 20% (2000 bps)
    // STAIK percentage below base (in bps)
    // uint256 public staikPercentBelow = 1000; // initially set to 10% (1000 bps)
    uint256 public staikPercentBelow; // initially set to 10% (1000 bps)
    // STAIK base higher range value
    uint256 public staikHigherRange;
    // STAIK base range lower
    uint256 public staikLowerRange;

    // candidtate price and time
    uint256 public combinePriceBaseCandidate;
    uint256 public candidateTimestamp;

    // candidtate STAIK price and time
    uint256 public staikPriceBaseCandidate;
    uint256 public staikCandidateTimestamp;
    ///////////////////////////////////////////////////////////////

    // current BPL and SPR values
    uint256 public dynamicBPL;
    uint256 public dynamicSPR;
    // previous BPL and SPR values
    uint256 public dynamicBPLPrevious;
    uint256 public dynamicSPRPrevious;
    // confirm if BPL SPR is active
    // bool public isBPLActive = true;
    bool public isBPLActive;
    // bool public isSPRActive = true;
    bool public isSPRActive;
    // min max values for BPL and SPR
    // uint256 public bplMin = 0; // bps
    uint256 public bplMin; // bps
    // uint256 public bplMax = 2500; // 25% expressed as bps
    uint256 public bplMax; // 25% expressed as bps
    // uint256 public sprMin = 0; // bps
    uint256 public sprMin; // bps
    // uint256 public sprMax = 2500; // 25% expressed as bps
    uint256 public sprMax; // 25% expressed as bps
    // snapshot time (epoch)
    uint256 public snapshotCurrent;
    ///////////////////////////////////////////////////////////////

    // uint256 public waitPeriod = 86400;
    uint256 public waitPeriod;
    // uint256 public staikWaitPeriod = 21600; // 6 hours
    uint256 public staikWaitPeriod; // 6 hours

    // bool public baseTimerComplete = false;
    bool public baseTimerComplete;
    uint256 public baseTimer;
    // uint256 public baseGrowth = 200; // initially set to 2% (200 bps)
    uint256 public baseGrowth; // initially set to 2% (200 bps)


    ///// Anti-Whale ////////////////////////////
    // uint256 public antiWhaleBackoff = 21600;  // 6 hours
    uint256 public antiWhaleBackoff;  // 6 hours

    bool public antiWhaleBPL;
    uint256 public bplPreAntiWhale;
    uint256 public timeAntiWhaleBPLLastInvoked;
 
    bool public antiWhaleSPR;
    uint256 public sprPreAntiWhale;
    uint256 public timeAntiWhaleSPRLastInvoked;
     
    // contract functions /////////////////////////////////////////////////////

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // Initializer - part of upgradeable contract process

    /// @notice Initializer
    function initialize(
        address initialStaikOracleAddress,
        address initialWethAddress,
        address initialWbtcAddress,
        address initialUsdcAddress,
        address initialUsdtAddress,
        address initialBurnerAddress,
        // uint256 initialCpbPercentAbove,
        // uint256 initialCpbPercentBelow,
        // uint256 initialStaikPercentAbove,
        // uint256 initialStaikPercentBelow,
        bool initialIsBPLActive,
        bool initialIsSPRActive
        // uint256 initialBplMin,
        // uint256 initialBplMax,
        // uint256 initialSprMin,
        // uint256 initialSprMax,
        // uint256 initialWaitPeriod,
        // uint256 initialStaikWaitPeriod,
        // bool initialBaseTimerComplete,
        // uint256 initialBaseGrowth,
        // uint256 initialAntiWhaleBackoff

        /// used to override the initializer 
        ) initializer public {

        /// ownableUpgradeble call __Ownable_init function
        OwnableUpgradeable.__Ownable_init();
        /// transfers ownership of contract to owner set in initializer
        // transferOwnership(owner_);

        staikOracleAddress = initialStaikOracleAddress;
        wethAddress = initialWethAddress;
        wbtcAddress = initialWbtcAddress;
        usdcAddress = initialUsdcAddress;
        usdtAddress = initialUsdtAddress;
        burnerAddress = initialBurnerAddress;
        // cpbPercentAbove = initialCpbPercentAbove;
        // cpbPercentBelow = initialCpbPercentBelow;
        // staikPercentAbove = initialStaikPercentAbove;
        // staikPercentBelow = initialStaikPercentBelow;
        isBPLActive = initialIsBPLActive;
        isSPRActive = initialIsSPRActive;
        // bplMin = initialBplMin;
        // bplMax = initialBplMax;
        // sprMin = initialSprMin;
        // sprMax = initialSprMax;
        // waitPeriod = initialWaitPeriod;
        // staikWaitPeriod = initialStaikWaitPeriod;
        // baseTimerComplete = initialBaseTimerComplete;
        // baseGrowth = initialBaseGrowth;
        // antiWhaleBackoff = initialAntiWhaleBackoff;

        WETH = IERC20(wethAddress);
        WBTC = IERC20(wbtcAddress);
        USDC = IERC20(usdcAddress);
        USDT = IERC20(usdtAddress);

        staikOracle = ISTAIKOracle(staikOracleAddress);

        // temporarily set owner to DAO
        DAO = msg.sender;
    }

    // modifier for DAO governance to call functions
    modifier onlyDAO {
        require(msg.sender == DAO, "Only DAO can call this function");
        _;
    }

    // transition to DAO governance
    function setDAO(address _multisig) external onlyDAO {
        require(
            _multisig != address(0) &&
            _multisig != burnerAddress &&
            _multisig != staikAddress &&
            _multisig != staikOracleAddress
        );
        DAO = _multisig;
    } 

    // set the STAIK token deployed address
    function setSTAIKTokenAddress(address _address) external onlyDAO {
        require(
            _address != address(0) &&
            _address != burnerAddress &&
            _address != staikOracleAddress
        );
        staikAddress = _address;
        STAIK = IERC20(_address);
        // STAIK = _staik;
    }

    // set/update the STAIK oracle deployed address
    function setSTAIKOracleAddress(address _address) external onlyDAO {
        require(
            _address != address(0) &&
            _address != burnerAddress &&
            _address != staikAddress
        );
        staikOracleAddress = _address;
        staikOracle = ISTAIKOracle(staikOracleAddress);
        // ISTAIKOracle _staikOracle = ISTAIKOracle(_address);
        // staikOracle = _staikOracle;
    }

    // set tracked tokens
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


    // disable/enable both the BPL and SPR
    function setBPLSPRActive(bool _bpl, bool _spr) external onlyDAO {
        sprActive(_bpl);
        bplActive(_spr);
    }

    // set BPL/SPR min/max values (bps)
    function setBPLSPRMinMax(uint16 _bplMin, uint16 _bplMax, uint16 _sprMin, uint16 _sprMax) external onlyDAO {
        require (_bplMin >= 0 && _sprMin >= 0 && _bplMax <= 2500 && _sprMax <= 2500);
        bplMin = _bplMin;
        bplMax = _bplMax;
        sprMin = _sprMin;
        sprMax = _sprMax;
    }

    // turns on/off the antiWhale BPL and SPR
    function antiWhaleTesting(bool _setantiWhaleBPL, bool _setantiWhaleSPR) external onlyDAO {
        antiWhaleBPL = _setantiWhaleBPL;
        antiWhaleSPR = _setantiWhaleSPR;
    }

    // sets the AntiWhale backoff period (in seconds)
    function setAntiWhaleBackoff(uint32 _backoff) external onlyDAO {
        antiWhaleBackoff = _backoff;
    }


    // sets the wait period in seconds before candidate base price becomes new base price
    function setWaitPeriod (uint256 _wait) external onlyDAO {
        waitPeriod = _wait;
    }

    // sets the wait period in seconds before candidate base price becomes new base price
    function setStaikWaitPeriod (uint256 _wait) external onlyDAO {
        staikWaitPeriod = _wait;
    }

    // sets the baseGrowth value percentage for STAIK Value
    function setBaseGrowth(uint256 _percent) external onlyDAO {
        baseGrowth = _percent;
    }



    // sets the upper and lower boundary ranges
    function setPercentAboveAndBelow (uint256 _above, uint256 _below) external onlyDAO {
        require(_above <= 10000 && _below <= 10000);
        cpbPercentAbove = _above;
        cpbPercentBelow = _below;
    }

    // sets the upper and lower boundary ranges for STAIK
    function setSTAIKPercentAboveAndBelow (uint256 _above, uint256 _below) external onlyDAO {
        require(_above <= 10000 && _below <= 10000);
        staikPercentAbove = _above;
        staikPercentBelow = _below;
    }

    // disable/enable BPL
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

    // disable/enable SPR
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



    // Core function of the contract that sets BPL and also checks antiWhale //
    //////////////////////////////////////////////////////

    function setBPLSPR() public returns (uint256, uint256) {

        // first confirm BPL and SPR values are in scope
        require(isBPLActive && isSPRActive);

        require(combinePriceRealtime() > 0);

        // get the latest combined price of WBTC and ETH
        combinePriceCurrent = combinePriceRealtime();

        // get the latest price of STAIK
        staikPriceCurrent = staikPriceRealtime();
        
        // set a base value if this is first call. If it is already set, then skip
        if (combinePriceBase == 0) {
            combinePriceBase = combinePriceCurrent;
        }

        // check if base timer is greater than 24 hours (86400s)
        if (baseTimer > 0 && baseTimer + 86400 <= block.timestamp) {
            baseTimerComplete = true;
        }

        // set a base timer value if this is first call. If it is already set, then skip
        if (baseTimer == 0) {
            baseTimer = block.timestamp;
        }

        // used to encourage growth in price range
        if (staikPriceBase > 0 && baseTimerComplete == true) {
            staikPriceBase = staikPriceBase * (10000 + baseGrowth) / 10000;
            baseTimer = block.timestamp;
            baseTimerComplete = false;
        }

        // set a base value if this is first call. If it is already set, then skip
        if (staikPriceBase == 0) {
            staikPriceBase = staikPriceCurrent;
        }

        // check if higher range or lower ranges have already been set... if not, set them
        if (cpbHigherRange == 0 || cpbLowerRange == 0) {
            cpbHigherRange = (combinePriceBase * (10000 + cpbPercentAbove)) / 10000;
            cpbLowerRange = (combinePriceBase * (10000 - cpbPercentBelow)) / 10000;
        }

        // now check if current combined price is outside of the range 
        if (combinePriceCurrent > cpbHigherRange || combinePriceCurrent < cpbLowerRange) {    

            // if price IS outside of range, check if base "candidate" hasn't been set yet
            if (combinePriceBaseCandidate == 0) {
                combinePriceBaseCandidate = combinePriceCurrent;
                candidateTimestamp = block.timestamp;
            }

            // if it was already set, check it's now not on the OPPOSITE side of the range...
            if (combinePriceBaseCandidate != 0) {
                    // now above range, but previously below range on last call
                if ((combinePriceCurrent > combinePriceBase && combinePriceBase > combinePriceBaseCandidate) ||
                    // now below range, but previously above range on last call
                    (combinePriceCurrent < combinePriceBase && combinePriceBase < combinePriceBaseCandidate)) {
                    // set new candidate base    
                    combinePriceBaseCandidate = combinePriceCurrent;
                    candidateTimestamp = block.timestamp;
                }
            }

            // Now check if the time passed is LESS than the wait period...
            if (candidateTimestamp + waitPeriod > block.timestamp) {       

                // if new price is higher, work out the value of BPL
                if (combinePriceCurrent > combinePriceBase) {
                    uint256 increaseAsPercent = ((combinePriceCurrent - combinePriceBase) * 10000) / combinePriceBase;
                    uint256 newBPL = increaseAsPercent;
                    dynamicBPL = newBPL > bplMax ? bplMax : newBPL;
                }

                // if new price is lower, work out the value of SPR
                else {
                    uint256 decreaseAsPercent = ((combinePriceBase - combinePriceCurrent) * 10000) / combinePriceBase;
                    uint256 newSPR = decreaseAsPercent;          
                    dynamicSPR = newSPR > sprMax ? sprMax : newSPR;
                }
            }

            // If the time passed from Candidate Timestamp is 7 days or more it requires a new base!
            else {
                resetState();
            }
        }

        // if the price was not outside range, then the latest call must be in existing range
        else {
            // check if any base candidate was set in a previous call. if it was, it should now be reset
            if (combinePriceBaseCandidate != 0) {
                resetState();
            }
        }

        // now apply similar logic using STAIK token price
            
        // check if higher range or lower ranges have already been set... if not, set them
        if (staikHigherRange == 0 || staikLowerRange == 0) {
            staikHigherRange = (staikPriceBase * (10000 + staikPercentAbove)) / 10000;
            staikLowerRange = (staikPriceBase * (10000 - staikPercentBelow)) / 10000;
        }

        // now check if current STAIK price is outside of the range 
        if (staikPriceCurrent > staikHigherRange || staikPriceCurrent < staikLowerRange) {    

            // if price IS outside of range, check if base "candidate" hasn't been set yet
            if (staikPriceBaseCandidate == 0) {
                staikPriceBaseCandidate = staikPriceCurrent;
                staikCandidateTimestamp = block.timestamp;
            }

            // if it was already set, check it's now not on the OPPOSITE side of the range...
            if (staikPriceBaseCandidate != 0) {
                    // now above range, but previously below range on last call
                if ((staikPriceCurrent > staikPriceBase && staikPriceBase > staikPriceBaseCandidate) ||
                    // now below range, but previously above range on last call
                    (staikPriceCurrent < staikPriceBase && staikPriceBase < staikPriceBaseCandidate)) {
                    // set new candidate base    
                    staikPriceBaseCandidate = staikPriceCurrent;
                    staikCandidateTimestamp = block.timestamp;
                }
            }

            // Now check if the time passed is LESS than the wait period...
            if (staikCandidateTimestamp + staikWaitPeriod > block.timestamp) {       

                // if new price is higher, work out the value of BPL
                if (staikPriceCurrent > staikPriceBase) {
                    uint256 increaseAsPercent = ((staikPriceCurrent - staikPriceBase) * 10000) / staikPriceBase;
                    uint256 staikBPL = increaseAsPercent;
                    // add to dynamic BPL
                    dynamicBPL = staikBPL + dynamicBPL > bplMax ? bplMax : staikBPL + dynamicBPL;
                }

                // if new price is lower, work out the value of SPR
                else {
                    uint256 decreaseAsPercent = ((staikPriceBase - staikPriceCurrent) * 10000) / staikPriceBase;
                    uint256 staikSPR = decreaseAsPercent;    
                    // add to dynamic SPR      
                    dynamicSPR = staikSPR + dynamicSPR > sprMax ? sprMax : staikSPR + dynamicSPR;
                }
            }

            // If the time passed from Candidate Timestamp is 1 day or more it requires a new base!
            else {
                updateState();
            }
        }

        // if the price was not outside range, then the latest call must be in existing range
        else {
            // check if any base candidate was set in a previous call. if it was, it should now be reset
            if (staikPriceBaseCandidate != 0) {
                resetState();
            }
        }

    // check the antiWhale function for any overrides
    checkAntiWhale();

    // return BPL and SPR values
    return (dynamicBPL, dynamicSPR);
    }


    // used to reset state when price returns back into range
    function resetState() internal {
        combinePriceBase = combinePriceCurrent;
        dynamicBPL = 0;
        dynamicSPR = 0;
        candidateTimestamp = 0;
        combinePriceBaseCandidate = 0;
        cpbHigherRange = 0;
        cpbLowerRange = 0;
    }

    // used to update STAIK state daily
    function updateState() internal {
        dynamicBPL = 0;
        dynamicSPR = 0;
        staikCandidateTimestamp = 0;
        staikPriceBaseCandidate = 0;
        staikHigherRange = 0;
        staikLowerRange = 0;
    }

    // function used to check if large transaction has been made
    function checkAntiWhale() internal {

        // first confirm there is no stablecoin de-peg (market turbulence expected!)
        uint256 currentUSDTPrice = staikOracle.getRate(USDT, USDC, true);
       
        // If there is a 5% USDC de-peg, set both buy and sell tax to max temporarily!
        if (currentUSDTPrice <= 950000000000000000 || currentUSDTPrice >= 1050000000000000000) {
            
            dynamicBPL = bplMax;
            dynamicSPR = sprMax;
        } else {
            // If no USDC de-peg detected, call both internal functions
            handleAntiWhaleBPL();
            handleAntiWhaleSPR();
        }
    }

    function handleAntiWhaleBPL() internal {
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

    function handleAntiWhaleSPR() internal {
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



    /////////////////////////////////////////////////////////////////////////////////////////

    function combinePriceRealtime() public view returns (uint256) {    
        uint256 currentWETHPrice = wethPriceInUSDC();  // example 17699376660000000000 (16 decimals) 
        uint256 currentWBTCPrice = wbtcPriceInUSDC();  // example 280815441307261178303 (16 decimals)
        // check combined price without updating
        return currentWETHPrice + currentWBTCPrice; 
    }

    function wethPriceInUSDC() public view returns (uint256) {
        uint256 WETHPrice = staikOracle.getRate(WETH, USDC, true);
        // allows pricing to be returned at matching decimal precision as WBTC
        return WETHPrice * 1e12;
    }

    function wbtcPriceInUSDC() public view returns (uint256) {
        uint256 WBTCPrice = staikOracle.getRate(WBTC, USDC, true);
        // allows pricing to be returned at matching decimal precision as WETH
        return WBTCPrice * 1e2;
    }

    function staikPriceRealtime() public view returns (uint256) {    
        uint256 currentSTAIKPrice = staikPriceInUSDC(); 
        return currentSTAIKPrice; 
    }

    // used to check STAIK own price
    function staikPriceInUSDC() public view returns (uint256) {
        return staikOracle.getRate(STAIK, USDC, true);
    }

    // used to confirm there is no USDC de-peg event!
    function usdtPriceInUSDC() public view returns (uint256) {
        return staikOracle.getRate(USDT, USDC, true);
    }


    //////////////////////////////////////////////////////////

    function getBPL() public view returns (uint256) {
        return dynamicBPL;
    }

    function getSPR() public view returns (uint256) {
        return dynamicSPR;
    }

    //////////////////////////////////////////////////////////

    function getAntiWhaleBPL() public view returns (bool) {
        return antiWhaleBPL;
    }

    function getAntiWhaleSPR() public view returns (bool) {
        return antiWhaleSPR;
    }

}