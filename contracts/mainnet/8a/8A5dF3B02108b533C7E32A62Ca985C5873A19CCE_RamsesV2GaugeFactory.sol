// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Proxy.sol";
import "../utils/Address.sol";
import "./IBeacon.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from a {UpgradeableBeacon}.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */
contract BeaconProxy is Proxy {
    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 private constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializating the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    constructor(address beacon, bytes memory data) public payable {
        assert(_BEACON_SLOT == bytes32(uint256(keccak256("eip1967.proxy.beacon")) - 1));
        _setBeacon(beacon, data);
    }

    /**
     * @dev Returns the current beacon address.
     */
    function _beacon() internal view virtual returns (address beacon) {
        bytes32 slot = _BEACON_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            beacon := sload(slot)
        }
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation() internal view virtual override returns (address) {
        return IBeacon(_beacon()).implementation();
    }

    /**
     * @dev Changes the proxy to use a new beacon.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon.
     *
     * Requirements:
     *
     * - `beacon` must be a contract.
     * - The implementation returned by `beacon` must be a contract.
     */
    function _setBeacon(address beacon, bytes memory data) internal virtual {
        require(
            Address.isContract(beacon),
            "BeaconProxy: beacon is not a contract"
        );
        require(
            Address.isContract(IBeacon(beacon).implementation()),
            "BeaconProxy: beacon implementation is not a contract"
        );
        bytes32 slot = _BEACON_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, beacon)
        }

        if (data.length > 0) {
            Address.functionDelegateCall(_implementation(), data, "BeaconProxy: function call failed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
pragma solidity =0.7.6;

import "@openzeppelin-3.4.1/contracts/proxy/BeaconProxy.sol";

contract RamsesBeaconProxy is BeaconProxy {
    // Doing so the CREATE2 hash is easier to calculate
    constructor() payable BeaconProxy(msg.sender, "") {}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.0 <0.9.0;

interface IGaugeV2 {
    /// @notice Emitted when a reward notification is made.
    /// @param from The address from which the reward is notified.
    /// @param reward The address of the reward token.
    /// @param amount The amount of rewards notified.
    /// @param period The period for which the rewards are notified.
    event NotifyReward(
        address indexed from,
        address indexed reward,
        uint256 amount,
        uint256 period
    );

    /// @notice Emitted when a bribe is made.
    /// @param from The address from which the bribe is made.
    /// @param reward The address of the reward token.
    /// @param amount The amount of tokens bribed.
    /// @param period The period for which the bribe is made.
    event Bribe(
        address indexed from,
        address indexed reward,
        uint256 amount,
        uint256 period
    );

    /// @notice Emitted when rewards are claimed.
    /// @param period The period for which the rewards are claimed.
    /// @param _positionHash The identifier of the NFP for which rewards are claimed.
    /// @param receiver The address of the receiver of the claimed rewards.
    /// @param reward The address of the reward token.
    /// @param amount The amount of rewards claimed.
    event ClaimRewards(
        uint256 period,
        bytes32 _positionHash,
        address receiver,
        address reward,
        uint256 amount
    );

    /// @notice Initializes the contract with the provided gaugeFactory, voter, and pool addresses.
    /// @param _gaugeFactory The address of the gaugeFactory to set.
    /// @param _voter The address of the voter to set.
    /// @param _nfpManager The address of the NFP manager to set.
    /// @param _feeCollector The address of the fee collector to set.
    /// @param _pool The address of the pool to set.
    function initialize(
        address _gaugeFactory,
        address _voter,
        address _nfpManager,
        address _feeCollector,
        address _pool
    ) external;

    /// @notice Retrieves the value of the firstPeriod variable.
    /// @return The value of the firstPeriod variable.
    function firstPeriod() external returns (uint256);

    /// @notice Retrieves the total supply of a specific token for a given period.
    /// @param period The period for which to retrieve the total supply.
    /// @param token The address of the token for which to retrieve the total supply.
    /// @return The total supply of the specified token for the given period.
    function tokenTotalSupplyByPeriod(
        uint256 period,
        address token
    ) external view returns (uint256);

    /// @notice Retrieves the total boosted seconds for a specific period.
    /// @param period The period for which to retrieve the total boosted seconds.
    /// @return The total boosted seconds for the specified period.
    function periodTotalBoostedSeconds(
        uint256 period
    ) external view returns (uint256);

    /// @notice Retrieves the getTokenTotalSupplyByPeriod of the current period.
    /// @dev included to support voter's left() check during distribute().
    /// @param token The address of the token for which to retrieve the remaining amount.
    /// @return The amount of tokens left to distribute in this period.
    function left(address token) external view returns (uint256);

    /// @notice Retrieves the reward rate for a specific reward address.
    /// @dev this method returns the base rate without boost
    /// @param token The address of the reward for which to retrieve the reward rate.
    /// @return The reward rate for the specified reward address.
    function rewardRate(address token) external view returns (uint256);

    /// @notice Retrieves the claimed amount for a specific period, position hash, and user address.
    /// @param period The period for which to retrieve the claimed amount.
    /// @param _positionHash The identifier of the NFP for which to retrieve the claimed amount.
    /// @param reward The address of the token for the claimed amount.
    /// @return The claimed amount for the specified period, token ID, and user address.
    function periodClaimedAmount(
        uint256 period,
        bytes32 _positionHash,
        address reward
    ) external view returns (uint256);

    /// @notice Retrieves the last claimed period for a specific token, token ID combination.
    /// @param token The address of the reward token for which to retrieve the last claimed period.
    /// @param _positionHash The identifier of the NFP for which to retrieve the last claimed period.
    /// @return The last claimed period for the specified token and token ID.
    function lastClaimByToken(
        address token,
        bytes32 _positionHash
    ) external view returns (uint256);

    /// @notice Retrieves the reward address at the specified index in the rewards array.
    /// @param index The index of the reward address to retrieve.
    /// @return The reward address at the specified index.
    function rewards(uint256 index) external view returns (address);

    /// @notice Checks if a given address is a valid reward.
    /// @param reward The address to check.
    /// @return A boolean indicating whether the address is a valid reward.
    function isReward(address reward) external view returns (bool);

    /// @notice Returns an array of reward token addresses.
    /// @return An array of reward token addresses.
    function getRewardTokens() external view returns (address[] memory);

    /// @notice Returns the hash used to store positions in a mapping
    /// @param owner The address of the position owner
    /// @param index The index of the position
    /// @param tickLower The lower tick boundary of the position
    /// @param tickUpper The upper tick boundary of the position
    /// @return _hash The hash used to store positions in a mapping
    function positionHash(
        address owner,
        uint256 index,
        int24 tickLower,
        int24 tickUpper
    ) external pure returns (bytes32);

    /// @notice Retrieves the liquidity and boosted liquidity for a specific NFP.
    /// @param tokenId The identifier of the NFP.
    /// @return liquidity The liquidity of the position token.
    /// @return boostedLiquidity The boosted liquidity of the position token.
    /// @return veRamTokenId The attached veRam token
    function positionInfo(
        uint256 tokenId
    ) external view returns (uint128 liquidity, uint128 boostedLiquidity,uint256 veRamTokenId);

    /// @notice Returns the amount of rewards earned for an NFP.
    /// @param token The address of the token for which to retrieve the earned rewards.
    /// @param tokenId The identifier of the specific NFP for which to retrieve the earned rewards.
    /// @return reward The amount of rewards earned for the specified NFP and tokens.
    function earned(
        address token,
        uint256 tokenId
    ) external view returns (uint256 reward);

    /// @notice Returns the amount of rewards earned during a period for an NFP.
    /// @param period The period for which to retrieve the earned rewards.
    /// @param token The address of the token for which to retrieve the earned rewards.
    /// @param tokenId The identifier of the specific NFP for which to retrieve the earned rewards.
    /// @return reward The amount of rewards earned for the specified NFP and tokens.
    function periodEarned(
        uint256 period,
        address token,
        uint256 tokenId
    ) external view returns (uint256);

    /// @notice Retrieves the earned rewards for a specific period, token, owner, index, tickLower, and tickUpper.
    /// @param period The period for which to retrieve the earned rewards.
    /// @param token The address of the token for which to retrieve the earned rewards.
    /// @param owner The address of the owner for which to retrieve the earned rewards.
    /// @param index The index for which to retrieve the earned rewards.
    /// @param tickLower The tick lower bound for which to retrieve the earned rewards.
    /// @param tickUpper The tick upper bound for which to retrieve the earned rewards.
    /// @return The earned rewards for the specified period, token, owner, index, tickLower, and tickUpper.
    function periodEarned(
        uint256 period,
        address token,
        address owner,
        uint256 index,
        int24 tickLower,
        int24 tickUpper
    ) external view returns (uint256);

    /// @notice Retrieves the earned rewards for a specific period, token, owner, index, tickLower, and tickUpper.
    /// @dev used by getReward() and saves gas by saving states
    /// @param period The period for which to retrieve the earned rewards.
    /// @param token The address of the token for which to retrieve the earned rewards.
    /// @param owner The address of the owner for which to retrieve the earned rewards.
    /// @param index The index for which to retrieve the earned rewards.
    /// @param tickLower The tick lower bound for which to retrieve the earned rewards.
    /// @param tickUpper The tick upper bound for which to retrieve the earned rewards.
    /// @param caching Whether to cache the results or not.
    /// @return The earned rewards for the specified period, token, owner, index, tickLower, and tickUpper.
    function cachePeriodEarned(
        uint256 period,
        address token,
        address owner,
        uint256 index,
        int24 tickLower,
        int24 tickUpper,
        bool caching
    ) external returns (uint256);

    /// @notice Notifies the contract about the amount of rewards to be distributed for a specific token.
    /// @param token The address of the token for which to notify the reward amount.
    /// @param amount The amount of rewards to be distributed.
    function notifyRewardAmount(address token, uint256 amount) external;

    /// @notice Retrieves the reward amount for a specific period, NFP, and token addresses.
    /// @param period The period for which to retrieve the reward amount.
    /// @param tokens The addresses of the tokens for which to retrieve the reward amount.
    /// @param tokenId The identifier of the specific NFP for which to retrieve the reward amount.
    /// @param receiver The address of the receiver of the reward amount.
    function getPeriodReward(
        uint256 period,
        address[] calldata tokens,
        uint256 tokenId,
        address receiver
    ) external;

    /// @notice Retrieves the rewards for a specific period, set of tokens, owner, index, tickLower, tickUpper, and receiver.
    /// @param period The period for which to retrieve the rewards.
    /// @param tokens An array of token addresses for which to retrieve the rewards.
    /// @param owner The address of the owner for which to retrieve the rewards.
    /// @param index The index for which to retrieve the rewards.
    /// @param tickLower The tick lower bound for which to retrieve the rewards.
    /// @param tickUpper The tick upper bound for which to retrieve the rewards.
    /// @param receiver The address of the receiver of the rewards.
    function getPeriodReward(
        uint256 period,
        address[] calldata tokens,
        address owner,
        uint256 index,
        int24 tickLower,
        int24 tickUpper,
        address receiver
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title An interface for a contract that is capable of deploying Ramses V2 Gauges
/// @notice A contract that constructs a gauge must implement this to pass arguments to the gauge
/// @dev The store and retrieve method of supplying constructor arguments for CREATE2 isn't needed anymore
/// since we now use a beacon pattern
interface IRamsesV2GaugeDeployer {

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Ramses V2 Factory
/// @notice The Ramses V2 Factory facilitates creation of Ramses V2 pools and control over the protocol fees
interface IRamsesV2GaugeFactory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a gauge is created
    /// @param pool The address of the pool
    /// @param pool The address of the created gauge
    event GaugeCreated(address indexed pool, address gauge);

    /// @notice Emitted when pairs implementation is changed
    /// @param oldImplementation The previous implementation
    /// @param newImplementation The new implementation
    event ImplementationChanged(
        address indexed oldImplementation,
        address indexed newImplementation
    );

    /// @notice Emitted when the fee collector is changed
    /// @param oldFeeCollector The previous implementation
    /// @param newFeeCollector The new implementation
    event FeeCollectorChanged(
        address indexed oldFeeCollector,
        address indexed newFeeCollector
    );

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the RamsesV2 NFP Manager
    function nfpManager() external view returns (address);

    /// @notice Returns the Ramses Voting Sscrow (veRam)
    function veRam() external view returns (address);

    /// @notice Returns Ramses Voter
    function voter() external view returns (address);

    /// @notice Returns the gauge address for a given pool, or address 0 if it does not exist
    /// @param pool The pool address
    /// @return gauge The gauge address
    function getGauge(address pool) external view returns (address gauge);

    /// @notice Returns the address of the fee collector contract
    /// @dev Fee collector decides where the protocol fees go (fee distributor, treasury, etc.)
    function feeCollector() external view returns (address);

    /// @notice Creates a gauge for the given pool
    /// @param pool One of the desired gauge
    /// @return gauge The address of the newly created gauge
    function createGauge(address pool) external returns (address gauge);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import "./interfaces/IRamsesV2GaugeDeployer.sol";
import "./interfaces/IGaugeV2.sol";

import "./../RamsesBeaconProxy.sol";

import "@openzeppelin-3.4.1/contracts/proxy/IBeacon.sol";

contract RamsesV2GaugeDeployer is IRamsesV2GaugeDeployer, IBeacon {
    /// @inheritdoc IBeacon
    address public override implementation;

    /// @dev Deploys a pool with the given parameters by transiently setting the parameters storage slot and then
    /// clearing it after deploying the pool.
    /// @param _voter The address of the voter to set.
    /// @param _feeCollector The address of the fee collector to set.
    /// @param _pool The address of the pool to set.
    function _deploy(
        address _voter,
        address _nfpManager,
        address _feeCollector,
        address _pool
    ) internal returns (address gauge) {
        gauge = address(
            new RamsesBeaconProxy{
                salt: keccak256(abi.encodePacked(msg.sender, _pool))
            }()
        );
        IGaugeV2(gauge).initialize(
            address(this),
            _voter,
            _nfpManager,
            _feeCollector,
            _pool
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import "./interfaces/IRamsesV2GaugeFactory.sol";

import "./RamsesV2GaugeDeployer.sol";

import "./interfaces/IGaugeV2.sol";

import "@openzeppelin-3.4.1/contracts/proxy/Initializable.sol";

/// @title Canonical Ramses V2 factory
/// @notice Deploys Ramses V2 pools and manages ownership and control over pool protocol fees
contract RamsesV2GaugeFactory is
    IRamsesV2GaugeFactory,
    RamsesV2GaugeDeployer,
    Initializable
{
    /// @inheritdoc IRamsesV2GaugeFactory
    address public override owner;
    /// @inheritdoc IRamsesV2GaugeFactory
    address public override nfpManager;
    /// @inheritdoc IRamsesV2GaugeFactory
    address public override veRam;
    /// @inheritdoc IRamsesV2GaugeFactory
    address public override voter;

    /// @inheritdoc IRamsesV2GaugeFactory
    mapping(address => address) public override getGauge;

    /// @inheritdoc IRamsesV2GaugeFactory
    address public override feeCollector;

    // pool specific fee protocol if set
    mapping(address => uint8) _poolFeeProtocol;

    /// @dev prevents implementation from being initialized later
    constructor() initializer() {}

    function initialize(
        address _nfpManager,
        address _veRam,
        address _voter,
        address _feeCollector,
        address _implementation
    ) public initializer {
        owner = msg.sender;
        nfpManager = _nfpManager;
        veRam = _veRam;
        voter = _voter;
        feeCollector = _feeCollector;
        implementation = _implementation;

        emit OwnerChanged(address(0), msg.sender);
    }

    /// @inheritdoc IRamsesV2GaugeFactory
    function createGauge(
        address pool
    ) external override returns (address gauge) {
        require(msg.sender == voter, "AUTH");
        require(getGauge[pool] == address(0), "GE");
        gauge = _deploy(voter, nfpManager, feeCollector, pool);
        getGauge[pool] = gauge;
        emit GaugeCreated(pool, gauge);
    }

    /// @inheritdoc IRamsesV2GaugeFactory
    function setOwner(address _owner) external override {
        require(msg.sender == owner, "AUTH");
        emit OwnerChanged(owner, _owner);
        owner = _owner;
    }

    /// @dev Sets implementation for beacon proxies
    /// @param _implementation new implementation address
    function setImplementation(address _implementation) external {
        require(msg.sender == owner, "AUTH");
        emit ImplementationChanged(implementation, _implementation);
        implementation = _implementation;
    }
}