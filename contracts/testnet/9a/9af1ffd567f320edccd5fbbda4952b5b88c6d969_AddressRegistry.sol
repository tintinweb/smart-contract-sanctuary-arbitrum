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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@strategy/IStrategy.sol";
import "@vault/FeeOracle.sol";

contract AddressRegistry is OwnableUpgradeable {
    FeeOracle public feeOracle;
    address public router;
    mapping(address => IStrategy[]) public coinToStrategy;
    mapping(IStrategy => uint256) public strategyWhitelist;
    mapping(address => uint256) public rebalancerWhitelist;
    address[] public supportedCoinAddresses;

    event SET_ROUTER(address);
    event ADD_STRATEGY(IStrategy, address[]);
    event ADD_REBALANCER(address);
    event REMOVE_STRATEGY(IStrategy);
    event REMOVE_REBALANCER(address);

    constructor() {
        _disableInitializers();
    }

    function init(FeeOracle _feeOracle, address _router) external initializer {
        require(
            address(_feeOracle) != address(0),
            "_feeOracle address can't be zero"
        );
        require(_router != address(0), "_router address can't be zero");

        __Ownable_init();
        feeOracle = _feeOracle;
        router = _router;
    }

    function setRouter(address _router) external onlyOwner {
        require(_router != address(0), "_router address can't be zero");
        router = _router;

        emit SET_ROUTER(_router);
    } 

    function addStrategy(
        IStrategy strategy,
        address[] calldata coins
    ) external onlyOwner {
        require(strategyWhitelist[strategy] == 0, "Strategy already whitelisted");
        for (uint256 i; i < coins.length; ) {
            IStrategy[] memory strategiesForCoin = coinToStrategy[coins[i]];
            uint256 j;
            /// check strategy is already registered for the coin
            for (; j < strategiesForCoin.length; j++) {
                if (address(strategiesForCoin[j]) == address(strategy)) break;
            }
            /// add strategy if it's not registered
            if (j == strategiesForCoin.length) {
                coinToStrategy[coins[i]].push(strategy);
            }
            unchecked {
                i++;
            }
        }
        strategyWhitelist[strategy] = block.timestamp + 1 days;

        emit ADD_STRATEGY(strategy, coins);
    }

    function addRebalancer(address rebalancer) external onlyOwner {
        require(
            rebalancerWhitelist[rebalancer] == 0,
            "Rebalancer already whitelisted"
        );
        rebalancerWhitelist[rebalancer] = block.timestamp + 1 days;

        emit ADD_REBALANCER(rebalancer);
    }

    function removeStrategy(IStrategy strategy) external onlyOwner {
        require(strategyWhitelist[strategy] != 0, "Strategy not whitelisted");
        strategyWhitelist[strategy] = 0;

        emit REMOVE_STRATEGY(strategy);
    }

    function removeRebalancer(address rebalancer) external onlyOwner {
        require(
            rebalancerWhitelist[rebalancer] != 0,
            "Rebalancer not whitelisted"
        );
        rebalancerWhitelist[rebalancer] = 0;

        emit REMOVE_REBALANCER(rebalancer);
    }

    function getCoinToStrategy(
        address coin
    ) external view returns (IStrategy[] memory strategies) {
      uint256 activeStrategies = 0;
      // count active strategies
      for(uint256 i; i < coinToStrategy[coin].length; i++) {
        if(strategyWhitelist[coinToStrategy[coin][i]] < block.timestamp && strategyWhitelist[coinToStrategy[coin][i]] != 0) {
          activeStrategies++;
        }
      }
      // create array of active strategies
      uint j = 0;
      strategies = new IStrategy[](activeStrategies);
      for(uint256 i; i < coinToStrategy[coin].length; i++) {
        if(strategyWhitelist[coinToStrategy[coin][i]] < block.timestamp && strategyWhitelist[coinToStrategy[coin][i]] != 0) {
          strategies[j] = coinToStrategy[coin][i];
          j++;
        }
      }
    }

    function getWhitelistedStrategies(
        IStrategy strategy
    ) external view returns (bool) {
        return block.timestamp >= strategyWhitelist[strategy] && strategyWhitelist[strategy] != 0;
    }

    function getWhitelistedRebalancer(
        address rebalancer
    ) external view returns (bool) {
        return block.timestamp >= rebalancerWhitelist[rebalancer] && rebalancerWhitelist[rebalancer] != 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// Strategy Interface
interface IStrategy {
    function getComponentAmount(address coin) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@vault/IVault.sol";
import "@structs/structs.sol";

/// Fee oracle contract that provides deposit and withdrawal fees to be used by vault contract
/// Find the formulas here: https://docs.google.com/spreadsheets/d/1K-x2kDNVfSKCEjaOtOS_gbQu5PcrkRccioJP1UBuLhs/edit#gid=0
/// The fees are based on the current weight of a coin in the vault compared to its target
contract FeeOracle is OwnableUpgradeable {
    /// targets
    CoinWeight[50] public targets;
    /// length of coin weight targets
    uint256 public targetsLength;
    /// max fee
    uint256 public maxFee;
    /// max bonus
    uint256 public maxBonus;
    /// weight denominator for weight calculation
    uint256 public weightDenominator;

    event SET_TARGETS(CoinWeight[]);

    constructor() {
        _disableInitializers();
    }

    function init(uint256 _maxFee, uint256 _maxBonus) external initializer {
        require(_maxFee <= 100, "_maxFee can't greater than 100");
        require(_maxBonus <= 100, "_maxFee can't greater than 100");

        __Ownable_init();
        maxFee = _maxFee;
        maxBonus = _maxBonus;
        weightDenominator = 100;
    }

    function setMaxFee(uint256 _maxFee) external onlyOwner {
        maxFee = _maxFee;
    }

    function setMaxBonus(uint256 _maxBonus) external onlyOwner {
        maxBonus = _maxBonus;
    }

    /// @notice Set target coin weights
    /// @param weights Coin weightes to set
    function setTargets(CoinWeight[] memory weights) external onlyOwner {
        targetsLength = weights.length;
        for (uint8 i; i < weights.length; ) {
            targets[i] = weights[i];
            unchecked {
                ++i;
            }
        }
        isNormalizedWeightArray(weights);
        emit SET_TARGETS(weights);
    }

    function isInTarget(address coin) public view returns (bool) {
        for (uint8 i; i < targetsLength; ) {
            if (targets[i].coin == coin) return true;
            unchecked {
                ++i;
            }
        }
        return false;
    }

    /// @notice Get deposit fee
    /// @param params Deposit fee params
    /// @return fee Deposit fee
    /// @return weights Latest coin weights for vault before deposit
    /// @return tvlUSD1e18X Latest tvl for vault before deposit
    function getDepositFee(
        DepositFeeParams memory params
    )
        external
        view
        returns (int256 fee, CoinWeight[] memory weights, uint256 tvlUSD1e18X)
    {
        CoinWeightsParams memory coinWeightParams = CoinWeightsParams({
            cpu: params.cpu,
            vault: params.vault,
            expireTimestamp: params.expireTimestamp
        });
        (weights, tvlUSD1e18X) = getCoinWeights(coinWeightParams);
        CoinWeight memory target = targets[params.position];
        CoinWeight memory currentCoinWeight = weights[params.position];
        uint256 __decimals = target.coin == address(0)
            ? 18
            : IERC20Metadata(target.coin).decimals();

        /// new weight calc
        /// formula: depositValue = depositAmount * depositPrice / 10**decimals
        uint256 depositValueUSD1e18X = (params.amount *
            params.cpu[params.position].price) / 10 ** __decimals;

        /// formula: currentCoinValue = currentCoinWeight * tvl / weightDenominator
        uint256 currentCoinValue = (currentCoinWeight.weight * tvlUSD1e18X) /
            weightDenominator;

        /// formula: newWeight = (currentCoinValue + depositValue) * weightDenominator / (tvl + depositValue)
        uint256 newWeight = ((currentCoinValue + depositValueUSD1e18X) *
            weightDenominator) / (tvlUSD1e18X + depositValueUSD1e18X);

        /// calculate distance
        /// calculate original distance
        /// formula: originalDistance = abs(currentWeight - targetWeight) / targetWeight
        uint256 originalDistance = getDistance(
            target.weight,
            currentCoinWeight.weight
        );
        /// calculate new distance
        /// formula: newDistance = abs(newWeight - targetWeight) / targetWeight
        uint256 newDistance = getDistance(target.weight, newWeight);
        require(newDistance < weightDenominator, "Too far away from target");
        if (originalDistance > newDistance) {
            // bonus
            uint256 improvement = originalDistance - newDistance;
            fee =
                (int256(improvement * maxBonus) * -1) /
                int256(weightDenominator);
        } else {
            // penalty
            uint256 deterioration = newDistance - originalDistance;
            fee = int256(deterioration * maxFee) / int256(weightDenominator);
        }
    }

    /// @notice Get withdrawal fee
    /// @param params Withdrawal fee params
    /// @return fee Withdrawal fee
    /// @return weights Latest coin weight for vault before withdraw
    /// @return tvlUSD1e18X Latest tvl for vault before withdraw
    function getWithdrawalFee(
        WithdrawalFeeParams memory params
    )
        external
        view
        returns (int256 fee, CoinWeight[] memory weights, uint256 tvlUSD1e18X)
    {
        CoinWeightsParams memory coinWeightParams = CoinWeightsParams({
            cpu: params.cpu,
            vault: params.vault,
            expireTimestamp: params.expireTimestamp
        });
        (weights, tvlUSD1e18X) = getCoinWeights(coinWeightParams);
        CoinWeight memory target = targets[params.position];
        CoinWeight memory currentCoinWeight = weights[params.position];
        uint256 __decimals = target.coin == address(0)
            ? 18
            : IERC20Metadata(target.coin).decimals();

        /// new weight calc
        /// formula: withdrawalValue = withdrawalAmount * withdrawalPrice / 10**decimals
        uint256 withdrawalValueUSD1e18X = (params.amount *
            params.cpu[params.position].price) / 10 ** __decimals;

        /// formula: currentCoinValue = currentCoinWeight * tvl / weightDenominator
        uint256 currentCoinValue = (currentCoinWeight.weight * tvlUSD1e18X) /
            weightDenominator;

        /// formula: newWeight = (currentCoinValue - withdrawalValue) * weightDenominator / (tvl - withdrawalValue)
        uint256 newWeight = ((currentCoinValue - withdrawalValueUSD1e18X) *
            weightDenominator) / (tvlUSD1e18X - withdrawalValueUSD1e18X);

        // calculate distance
        /// calculate original distance
        /// formula: originalDistance = abs(currentWeight - targetWeight) / targetWeight
        uint256 originalDistance = getDistance(
            target.weight,
            currentCoinWeight.weight
        );
        /// calculate new distance
        /// formula: newDistance = abs(newWeight - targetWeight) / targetWeight
        uint256 newDistance = getDistance(target.weight, newWeight);
        require(newDistance < weightDenominator, "Too far away from target");
        if (originalDistance > newDistance) {
            // bonus
            uint256 improvement = originalDistance - newDistance;
            fee = int256(improvement * maxBonus) / int256(weightDenominator);
        } else {
            // penalty
            uint256 deterioration = newDistance - originalDistance;
            fee =
                (int256(deterioration * maxFee) * -1) /
                int256(weightDenominator);
        }
    }

    /// @notice Get targets
    /// @return targets coin weights
    function getTargets() external view returns (CoinWeight[] memory) {
        CoinWeight[] memory _targets = new CoinWeight[](targetsLength);
        for (uint8 i; i < targetsLength; ) {
            _targets[i] = targets[i];
            unchecked {
                ++i;
            }
        }
        return _targets;
    }

    /// @notice Get current coin weights and tvl for given params
    /// @param params CoinWeightsPrams for get coin weights
    /// @return weights Current coin weights for given params
    /// @return tvlUSD1e18X TVL for given vault
    function getCoinWeights(
        CoinWeightsParams memory params
    ) public view returns (CoinWeight[] memory weights, uint256 tvlUSD1e18X) {
        weights = new CoinWeight[](targetsLength);
        require(
            block.timestamp < params.expireTimestamp,
            "Execution window passed"
        );
        // verify signature
        require(params.cpu.length == targetsLength, "Oracle length error");
        CoinWeight[50] memory _targets = targets;
        uint256 _targetsLength = targetsLength;
        for (uint8 i; i < _targetsLength; ) {
            require(
                params.cpu[i].coin == _targets[i].coin,
                "Oracle order error"
            );
            /// Get available amount of coin for the vault per every coin
            /// formula: coinVaultAmount + coinStrategiesAmount - coinDebtAmount
            uint256 amount = params.vault.getAmountAcrossStrategies(
                _targets[i].coin
            ) - params.vault.debt(_targets[i].coin);
            /// Initialize coinWeight with available amount of coin
            weights[i] = CoinWeight(params.cpu[i].coin, amount);
            unchecked {
                i++;
            }
        }

        /// Calc tvl
        uint8[] memory __decimals = new uint8[](_targetsLength);
        for (uint8 i; i < _targetsLength; ) {
            __decimals[i] = _targets[i].coin == address(0)
                ? 18
                : IERC20Metadata(_targets[i].coin).decimals();
            /// Calculate tvl over the coin weights
            /// Set weight with every coin value
            /// formula: coinValue = coinAmount * coinPirceUSD / 10**coinDecimal
            weights[i].weight =
                (weights[i].weight * params.cpu[i].price) /
                10 ** __decimals[i];
            /// formula: tvl += coinValue
            tvlUSD1e18X += weights[i].weight;
            unchecked {
                i++;
            }
        }

        /// Normalize
        for (uint8 i; i < _targetsLength; ) {
            /// Normalize coin weights
            /// formula: weight = coinValue * weightDenominator / tvl
            weights[i].weight =
                (weights[i].weight * weightDenominator) /
                tvlUSD1e18X;
            unchecked {
                i++;
            }
        }
        isNormalizedWeightArray(weights);
    }

    /// @notice Check if weights array is normalized or not
    /// @param weights Coin weight array that needs to be checked
    function isNormalizedWeightArray(
        CoinWeight[] memory weights
    ) internal pure {
        uint256 totalWeight = 0;
        uint8 j;
        for (uint8 i; i < weights.length; ) {
            totalWeight += weights[i].weight;
            unchecked {
                i++;
            }
            unchecked {
                j++;
            }
        }
        // compensate for rounding errors
        require(totalWeight >= 100 - j, "Weight error");
        require(totalWeight <= 100, "Weight error 2");
    }

    /// @notice Get distance between two weights. The "distance" is calculated as a percentage change of the new weight compared to the target weight.
    /// @param targetWeight Standard weight that calculate distance
    /// @param comparedWeight Compared weight that calculate distance
    /// @return disatnce
    function getDistance(
        uint256 targetWeight,
        uint256 comparedWeight
    ) internal view returns (uint256) {
        /// formula: distance = abs(targetWeight - comparedWeight) * weightDenominator / targetWeight
        return
            targetWeight >= comparedWeight
                ? ((targetWeight - comparedWeight) * weightDenominator) /
                    targetWeight
                : ((comparedWeight - targetWeight) * weightDenominator) /
                    targetWeight;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// Vault Interface
interface IVault {
    function getAmountAcrossStrategies(
        address coin
    ) external view returns (uint256 value);

    function debt(address coin) external view returns (uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@vault/IVault.sol";

enum PairType {
    USDC,
    WETH
}

struct CoinPriceUSD {
    address coin;
    uint256 price;
}

struct CoinWeight {
    address coin;
    uint256 weight;
}

struct CoinValue {
    address coin;
    uint256 value;
}

struct CoinWeightsParams {
    CoinPriceUSD[] cpu;
    IVault vault;
    uint256 expireTimestamp;
}

struct DepositFeeParams {
    CoinPriceUSD[] cpu;
    IVault vault;
    uint256 expireTimestamp;
    uint256 position;
    uint256 amount;
}

struct WithdrawalFeeParams {
    CoinPriceUSD[] cpu;
    IVault vault;
    uint256 expireTimestamp;
    uint256 position;
    uint256 amount;
}