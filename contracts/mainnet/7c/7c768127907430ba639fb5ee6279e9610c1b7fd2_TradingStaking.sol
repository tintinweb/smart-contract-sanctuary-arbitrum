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

// SPDX-License-Identifier: BUSL-1.1
// This code is made available under the terms and conditions of the Business Source License 1.1 (BUSL-1.1).
// The act of publishing this code is driven by the aim to promote transparency and facilitate its utilization for educational purposes.

pragma solidity 0.8.18;

interface IRewarder {
  function name() external view returns (string memory);

  function rewardToken() external view returns (address);

  function rewardRate() external view returns (uint256);

  function onDeposit(address user, uint256 shareAmount) external;

  function onWithdraw(address user, uint256 shareAmount) external;

  function onHarvest(address user, address receiver) external;

  function pendingReward(address user) external view returns (uint256);

  function feed(uint256 feedAmount, uint256 duration) external;

  function feedWithExpiredAt(uint256 feedAmount, uint256 expiredAt) external;

  function accRewardPerShare() external view returns (uint128);

  function userRewardDebts(address user) external view returns (int256);

  function lastRewardTime() external view returns (uint64);

  function setFeeder(address feeder_) external;
}

// SPDX-License-Identifier: BUSL-1.1
// This code is made available under the terms and conditions of the Business Source License 1.1 (BUSL-1.1).
// The act of publishing this code is driven by the aim to promote transparency and facilitate its utilization for educational purposes.

pragma solidity 0.8.18;

interface ITradingStaking {
  function deposit(address to, uint256 marketIndex, uint256 amount) external;

  function withdraw(address to, uint256 marketIndex, uint256 amount) external;

  function getUserTokenAmount(uint256 marketIndex, address sender) external view returns (uint256);

  function getMarketIndexRewarders(uint256 _marketIndex) external view returns (address[] memory);

  function harvest(address[] memory rewarders) external;

  function harvestToCompounder(address user, address[] memory rewarders) external;

  function calculateTotalShare(address rewarder) external view returns (uint256);

  function calculateShare(address rewarder, address user) external view returns (uint256);

  function isRewarder(address rewarder) external view returns (bool);

  function addRewarder(address newRewarder, uint256[] memory _newMarketIndex) external;

  function setWhitelistedCaller(address _whitelistedCaller) external;

  function isMarketIndex(uint256 marketIndex) external returns (bool);

  function marketIndexRewarders(uint256, uint256) external view returns (address);

  function removeRewarderForMarketIndexByIndex(
    uint256 _removeRewarderIndex,
    uint256 _marketIndex
  ) external;
}

// SPDX-License-Identifier: BUSL-1.1
// This code is made available under the terms and conditions of the Business Source License 1.1 (BUSL-1.1).
// The act of publishing this code is driven by the aim to promote transparency and facilitate its utilization for educational purposes.
//   _   _ __  ____  __
//  | | | |  \/  \ \/ /
//  | |_| | |\/| |\  /
//  |  _  | |  | |/  \
//  |_| |_|_|  |_/_/\_\
//

pragma solidity 0.8.18;

import { OwnableUpgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import { IRewarder } from "./interfaces/IRewarder.sol";
import { ITradingStaking } from "./interfaces/ITradingStaking.sol";

contract TradingStaking is OwnableUpgradeable, ITradingStaking {
  /**
   * Errors
   */
  error TradingStaking_UnknownMarketIndex();
  error TradingStaking_InsufficientTokenAmount();
  error TradingStaking_NotRewarder();
  error TradingStaking_NotCompounder();
  error TradingStaking_BadDecimals();
  error TradingStaking_DuplicateStakingToken();
  error TradingStaking_Forbidden();

  /**
   * Events
   */
  event LogDeposit(
    address indexed caller,
    address indexed user,
    uint256 marketIndex,
    uint256 amount
  );
  event LogWithdraw(address indexed caller, uint256 marketIndex, uint256 amount);
  event LogAddStakingToken(uint256 newMarketIndex, address[] newRewarders);
  event LogAddRewarder(address newRewarder, uint256[] newTokens);
  event LogSetCompounder(address oldCompounder, address newCompounder);
  event LogSetWhitelistedCaller(address oldAddress, address newAddress);

  /**
   * States
   */
  mapping(uint256 => mapping(address => uint256)) public userTokenAmount;
  mapping(uint256 => uint256) public totalShares;
  mapping(address => bool) public isRewarder;
  mapping(uint256 => bool) public isMarketIndex;
  mapping(uint256 => address[]) public marketIndexRewarders;
  mapping(address => uint256[]) public rewarderMarketIndex;
  address public compounder;
  address public whitelistedCaller;

  /**
   * Modifiers
   */
  modifier onlyWhitelistedCaller() {
    if (msg.sender != whitelistedCaller) revert TradingStaking_Forbidden();
    _;
  }

  function initialize() external initializer {
    OwnableUpgradeable.__Ownable_init();
  }

  /// @dev Add a new Market Pool for multiple rewarding addresses. Only the owner of the contract can call this function.
  /// @param _newMarketIndex The index of the new market pool to be added
  /// @param _newRewarders An array of addresses to be added as rewarder to the new market pool
  function addPool(uint256 _newMarketIndex, address[] memory _newRewarders) external onlyOwner {
    //Obtaining the length of the new rewarder addresses array to process each one of them on the loop
    uint256 length = _newRewarders.length;

    //Executing an iteration over each of the rewarders passed as parameter to add them to the pool
    for (uint256 i = 0; i < length; ) {
      //Updating the pool data for this rewarder address and the new markey index provided
      _updatePool(_newMarketIndex, _newRewarders[i]);

      //Incrementing iterator inside 'unchecked' block
      unchecked {
        ++i;
      }
    }

    //Logging the addition of the new staking token to the system
    emit LogAddStakingToken(_newMarketIndex, _newRewarders);
  }

  /// @dev Add a new rewarder to the pool and sets a market index.
  /// @param _newRewarder The address for the new rewarder.
  /// @param _newMarketIndex The array of new market indexes to be set for this rewarder.
  /// Emits a {LogAddRewarder} event indicating that a new rewarder was added.
  function addRewarder(address _newRewarder, uint256[] memory _newMarketIndex) external onlyOwner {
    //Obtaining the length of the market index array to process each one of them on the loop
    uint256 length = _newMarketIndex.length;
    //Iterating over provided market indexes to set new rewarder
    for (uint256 i = 0; i < length; ) {
      //Updating the pool data for this rewarder and the corresponding market index provided
      _updatePool(_newMarketIndex[i], _newRewarder);

      //Emitting LogAddRewarder event
      emit LogAddRewarder(_newRewarder, _newMarketIndex);

      //Incrementing iterator inside 'unchecked' block
      unchecked {
        ++i;
      }
    }
  }

  /// @dev Removes a rewarder address from a market index by its corresponding index. The function deletes the removed rewarder from the
  /// marketIndexRewarders list.
  /// @param _removeRewarderIndex The index of the rewarder address to be removed from the market index
  /// @param _marketIndex The index of the market whose mapped rewarder will be removed
  function removeRewarderForMarketIndexByIndex(
    uint256 _removeRewarderIndex,
    uint256 _marketIndex
  ) external onlyOwner {
    uint256 _marketIndexLength = marketIndexRewarders[_marketIndex].length;
    address removedRewarder = marketIndexRewarders[_marketIndex][_removeRewarderIndex];
    marketIndexRewarders[_marketIndex][_removeRewarderIndex] = marketIndexRewarders[_marketIndex][
      _marketIndexLength - 1
    ];
    marketIndexRewarders[_marketIndex].pop();

    uint256 rewarderLength = rewarderMarketIndex[removedRewarder].length;
    for (uint256 i = 0; i < rewarderLength; ) {
      if (rewarderMarketIndex[removedRewarder][i] == _marketIndex) {
        rewarderMarketIndex[removedRewarder][i] = rewarderMarketIndex[removedRewarder][
          rewarderLength - 1
        ];
        rewarderMarketIndex[removedRewarder].pop();
        if (rewarderLength == 1) isRewarder[removedRewarder] = false;

        break;
      }
      unchecked {
        ++i;
      }
    }
  }

  /// @dev Internal function to update a staking pool for a new rewarder and market index
  /// If the provided newRewarder address is not already in marketIndexRewarders for _marketIndex, it will be added
  /// Additionally, if the _marketIndex is not already associated with the provided newRewarder, it will be pushed into rewarderMarketIndex
  /// Also makes sure the _marketIndex is marked as existing by setting isMarketIndex to true
  /// Finally, sets the value of isRewarder[newRewarder] to true
  /// @param _marketIndex uint256 Market index to add staking data to
  /// @param _newRewarder address Address of new rewarder account to add to the specified market index's rewarders
  function _updatePool(uint256 _marketIndex, address _newRewarder) internal {
    if (!isDuplicatedRewarder(_marketIndex, _newRewarder))
      marketIndexRewarders[_marketIndex].push(_newRewarder);
    if (!isDuplicatedStakingToken(_marketIndex, _newRewarder))
      rewarderMarketIndex[_newRewarder].push(_marketIndex);

    isMarketIndex[_marketIndex] = true;
    if (!isRewarder[_newRewarder]) {
      isRewarder[_newRewarder] = true;
    }
  }

  /// @dev Internal function to check if an address is already on the list of rewarders for a given market index
  /// @param _marketIndex uint256 representing the market index to verify
  /// @param _rewarder address of the user's rewarder object to verificar
  /// @return bool value indicating if duplicate entry has been found
  function isDuplicatedRewarder(
    uint256 _marketIndex,
    address _rewarder
  ) internal view returns (bool) {
    uint256 length = marketIndexRewarders[_marketIndex].length;
    for (uint256 i = 0; i < length; ) {
      if (marketIndexRewarders[_marketIndex][i] == _rewarder) {
        return true;
      }
      unchecked {
        ++i;
      }
    }
    return false;
  }

  /// @dev Check whether a staking token address is already part of a market index
  /// @param _marketIndex uint256 ID of the market index to check on
  /// @param _rewarder Address of the rewarder to check
  /// @return bool indicating whether the staking token was found or not
  function isDuplicatedStakingToken(
    uint256 _marketIndex,
    address _rewarder
  ) internal view returns (bool) {
    uint256 length = rewarderMarketIndex[_rewarder].length;
    for (uint256 i = 0; i < length; ) {
      if (rewarderMarketIndex[_rewarder][i] == _marketIndex) {
        return true;
      }
      unchecked {
        ++i;
      }
    }
    return false;
  }

  /// @dev Changes the address of the contract's Compounder. Only callable by the current owner.
  ///Emits a `LogSetCompounder` event with previous and new compounder addresses after successful execution of this function.
  ///@param _compounder Address of the new Compounder contract.
  function setCompounder(address _compounder) external onlyOwner {
    emit LogSetCompounder(compounder, _compounder);
    compounder = _compounder;
  }

  /// @dev Set the address of an account authorized to modify balances in CrossMarginTrading.sol contract
  /// Emits a LogSetWhitelistedCaller event.
  /// @param _whitelistedCaller The new address allowed to perform whitelisted calls.
  function setWhitelistedCaller(address _whitelistedCaller) external onlyOwner {
    emit LogSetWhitelistedCaller(whitelistedCaller, _whitelistedCaller);
    whitelistedCaller = _whitelistedCaller;
  }

  /// @dev Deposits _amount tokens from the caller's account to the contract and assign them to _to user's balance for market index _marketIndex.
  /// Only allowed for the whitelisted caller.
  /// If the _marketIndex is not registered, it will revert with TradingStaking_UnknownMarketIndex() error.
  /// Calls onDeposit() function for each rewarder registered on market index _marketIndex using its respective address specified in marketIndexRewarders.
  /// After calling each rewarder, the _amount is added to the user's token balance at the _marketIndex, along with total shares.
  /// Emits a LogDeposit event with information about caller, _to, _marketIndex and _amount.
  ///
  /// Requirements:
  ///
  /// The caller must be whitelisted through setWhitelistedCaller() function.
  /// _to address must be valid.
  /// Calling contract needs to have an allowance of at least _amount on the caller's behalf.
  /// @param _to The address of the primary account
  /// @param _marketIndex Market index
  /// @param _amount Position Size
  function deposit(
    address _to,
    uint256 _marketIndex,
    uint256 _amount
  ) external onlyWhitelistedCaller {
    if (!isMarketIndex[_marketIndex]) revert TradingStaking_UnknownMarketIndex();

    uint256 length = marketIndexRewarders[_marketIndex].length;
    for (uint256 i = 0; i < length; ) {
      address rewarder = marketIndexRewarders[_marketIndex][i];

      IRewarder(rewarder).onDeposit(_to, _amount);

      unchecked {
        ++i;
      }
    }

    userTokenAmount[_marketIndex][_to] += _amount;
    totalShares[_marketIndex] += _amount;

    emit LogDeposit(msg.sender, _to, _marketIndex, _amount);
  }

  function getUserTokenAmount(
    uint256 _marketIndex,
    address sender
  ) external view returns (uint256) {
    return userTokenAmount[_marketIndex][sender];
  }

  function getMarketIndexRewarders(uint256 _marketIndex) external view returns (address[] memory) {
    return marketIndexRewarders[_marketIndex];
  }

  function getRewarderMarketIndex(address rewarder) external view returns (uint256[] memory) {
    return rewarderMarketIndex[rewarder];
  }

  function withdraw(
    address _to,
    uint256 _marketIndex,
    uint256 _amount
  ) external onlyWhitelistedCaller {
    _withdraw(_to, _marketIndex, _amount);
  }

  /// @dev Executes the withdrawal process for a given amount of tokens, associated with a certain market index,
  /// to a specified address. Throws if the provided market index does not exist or the user doesn't have enough token,
  /// to execute this transaction.
  /// During the withdrawal process, it will call onWithdraw() for each rewarder associate with this market index and
  /// Subtract the amount tokens from the userTokenAmount and totalShares relating to the provided market index.
  ///
  /// @param _to The Receiver's address where the withdrawn amount should go.
  /// @param _marketIndex The market index for which tokens should be withdrawn.
  /// @param _amount The Amount of tokens that should be withdrawn from the given market index.
  function _withdraw(address _to, uint256 _marketIndex, uint256 _amount) internal {
    if (!isMarketIndex[_marketIndex]) revert TradingStaking_UnknownMarketIndex();
    if (userTokenAmount[_marketIndex][_to] < _amount)
      revert TradingStaking_InsufficientTokenAmount();

    uint256 length = marketIndexRewarders[_marketIndex].length;
    for (uint256 i = 0; i < length; ) {
      address rewarder = marketIndexRewarders[_marketIndex][i];

      IRewarder(rewarder).onWithdraw(_to, _amount);

      unchecked {
        ++i;
      }
    }
    userTokenAmount[_marketIndex][_to] -= _amount;
    totalShares[_marketIndex] -= _amount;

    emit LogWithdraw(_to, _marketIndex, _amount);
  }

  function harvest(address[] memory _rewarders) external {
    _harvestFor(msg.sender, msg.sender, _rewarders);
  }

  function harvestToCompounder(address _user, address[] memory _rewarders) external {
    if (compounder != msg.sender) revert TradingStaking_NotCompounder();
    _harvestFor(_user, compounder, _rewarders);
  }

  /**

  @dev Internal function to distribute rewards accumulated for provided _user among all of the _rewarders.

  @param _user The address of the user whose rewards are being harvested.

  @param _receiver The address which will receive the rewards.

  @param _rewarders The list containing all the rewarders that will receive their share from the rewards.

  Once passed through a loop and each rewarder receives its own share from the _user's harvest,

  it will automatically emit the LogHarvest() event with respective details including _receiver address,

  _user address, and current time.
  */
  function _harvestFor(address _user, address _receiver, address[] memory _rewarders) internal {
    uint256 length = _rewarders.length;
    for (uint256 i = 0; i < length; ) {
      if (!isRewarder[_rewarders[i]]) {
        revert TradingStaking_NotRewarder();
      }

      IRewarder(_rewarders[i]).onHarvest(_user, _receiver);

      unchecked {
        ++i;
      }
    }
  }

  function calculateShare(address _rewarder, address _user) external view returns (uint256) {
    uint256[] memory marketIndices = rewarderMarketIndex[_rewarder];
    uint256 share = 0;
    uint256 length = marketIndices.length;
    for (uint256 i = 0; i < length; ) {
      share += userTokenAmount[marketIndices[i]][_user];

      unchecked {
        ++i;
      }
    }
    return share;
  }

  function calculateTotalShare(address _rewarder) external view returns (uint256) {
    uint256[] memory marketIndices = rewarderMarketIndex[_rewarder];
    uint256 totalShare = 0;
    uint256 length = marketIndices.length;
    for (uint256 i = 0; i < length; ) {
      totalShare += totalShares[marketIndices[i]];

      unchecked {
        ++i;
      }
    }
    return totalShare;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }
}