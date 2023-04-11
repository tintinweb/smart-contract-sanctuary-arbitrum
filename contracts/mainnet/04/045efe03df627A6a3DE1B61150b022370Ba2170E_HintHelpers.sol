// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
pragma solidity 0.8.6;

import "../libraries/UnboundMath.sol";

import '../interfaces/IUNDToken.sol';
import '../interfaces/ISortedAccounts.sol';
import '../interfaces/IMainPool.sol';
import '../interfaces/IUnboundBase.sol';
import '../interfaces/IUnboundFeesFactory.sol';
import '../interfaces/ICollSurplusPool.sol';

contract UnboundBase is IUnboundBase{

    uint256 public constant DECIMAL_PRECISION = 1e18;

    // Minimum collateral ratio for individual accounts
    uint256 public override MCR; // 1e18 is 100%

    // Minimum amount of net UND debt a account must have
    uint256 constant public MIN_NET_DEBT = 50e18; //100 UND - 100e18

    ISortedAccounts public override sortedAccounts;
    IUNDToken public override undToken;
    IERC20 public override depositToken;
    IMainPool public override mainPool;

    IUnboundFeesFactory public override unboundFeesFactory;

    ICollSurplusPool public override collSurplusPool;

    function getEntireSystemColl() public view returns (uint256 entireSystemColl) {
        entireSystemColl = mainPool.getCollateral();
    }

    function getEntireSystemDebt() public view returns (uint256 entireSystemDebt) {
        entireSystemDebt = mainPool.getUNDDebt();
    }

    function BORROWING_FEE_FLOOR() public view returns (uint256 borrowingFeeFloor) {
        borrowingFeeFloor = unboundFeesFactory.BORROWING_FEE_FLOOR();
    }

    function REDEMPTION_FEE_FLOOR() public view returns (uint256 redemptionFeeFloor) {
        redemptionFeeFloor = unboundFeesFactory.REDEMPTION_FEE_FLOOR();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import './base/UnboundBase.sol';

import './interfaces/IAccountManager.sol';
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract HintHelpers is UnboundBase, Initializable{

    IAccountManager public accountManager;

    function initialize(
        address _accountManager,
        address _sortedAccounts
    ) public initializer {
        accountManager = IAccountManager(_accountManager);
        sortedAccounts = ISortedAccounts(_sortedAccounts);
        MCR = accountManager.MCR();
    }

    // --- Functions ---

    /* getRedemptionHints() - Helper function for finding the right hints to pass to redeemCollateral().
     *
     * It simulates a redemption of `_UNDamount` to figure out where the redemption sequence will start and what state the final Account
     * of the sequence will end up in.
     *
     * Returns three hints:
     *  - `firstRedemptionHint` is the address of the first Account with ICR >= MCR (i.e. the first Account that will be redeemed).
     *  - `partialRedemptionHintNICR` is the final nominal ICR of the last Account of the sequence after being hit by partial redemption,
     *     or zero in case of no partial redemption.
     *  - `truncatedUNDamount` is the maximum amount that can be redeemed out of the the provided `_UNDamount`. This can be lower than
     *    `_UNDamount` when redeeming the full amount would leave the last Account of the redemption sequence with less net debt than the
     *    minimum allowed value (i.e. MIN_NET_DEBT).
     *
     * The number of Accounts to consider for redemption can be capped by passing a non-zero value as `_maxIterations`, while passing zero
     * will leave it uncapped.
     */

    function getRedemptionHints(
        uint _UNDamount, 
        uint _price,
        uint _maxIterations
    )
        external
        view
        returns (
            address firstRedemptionHint,
            uint partialRedemptionHintNICR,
            uint truncatedUNDamount
        )
    {
        ISortedAccounts sortedAccountsCached = sortedAccounts;

        uint remainingUND = _UNDamount;
        address currentAccountuser = sortedAccountsCached.getLast();

        while (currentAccountuser != address(0) && accountManager.getCurrentICR(currentAccountuser, _price) < MCR) {
            currentAccountuser = sortedAccountsCached.getPrev(currentAccountuser);
        }

        firstRedemptionHint = currentAccountuser;

        if (_maxIterations == 0) {
            _maxIterations = type(uint256).max;
        }

        while (currentAccountuser != address(0) && remainingUND > 0 && _maxIterations > 0) {
            uint netUNDDebt = accountManager.getAccountDebt(currentAccountuser);
            if (netUNDDebt > remainingUND) {
                if (netUNDDebt > MIN_NET_DEBT) {
                    uint maxRedeemableUND = UnboundMath._min(remainingUND, netUNDDebt - MIN_NET_DEBT);

                    uint Collateral = accountManager.getAccountColl(currentAccountuser);

                    uint newColl = Collateral - ((maxRedeemableUND * DECIMAL_PRECISION) / _price);
                    uint newDebt = netUNDDebt - maxRedeemableUND;

                    partialRedemptionHintNICR = UnboundMath._computeNominalCR(newColl, newDebt);

                    remainingUND = remainingUND - maxRedeemableUND;

                }
                break;
            } else {
                remainingUND = remainingUND - netUNDDebt;
            }

            currentAccountuser = sortedAccountsCached.getPrev(currentAccountuser);
            _maxIterations--;
        }

        truncatedUNDamount = _UNDamount - remainingUND;
    }


    /* getApproxHint() - return address of a Account that is, on average, (length / numTrials) positions away in the 
    sortedAccounts list from the correct insert position of the Account to be inserted. 
    
    Note: The output address is worst-case O(n) positions away from the correct insert position, however, the function 
    is probabilistic. Input can be tuned to guarantee results to a high degree of confidence, e.g:

    Submitting numTrials = k * sqrt(length), with k = 15 makes it very, very likely that the ouput address will 
    be <= sqrt(length) positions away from the correct insert position.
    */

    function getApproxHint(uint _CR, uint _numTrials, uint _inputRandomSeed)
        external
        view
        returns (address hintAddress, uint diff, uint latestRandomSeed)
    {
        uint arrayLength = accountManager.getAccountOwnersCount();

        if (arrayLength == 0) {
            return (address(0), 0, _inputRandomSeed);
        }

        hintAddress = sortedAccounts.getLast();
        diff = UnboundMath._getAbsoluteDifference(_CR, accountManager.getNominalICR(hintAddress));
        latestRandomSeed = _inputRandomSeed;

        uint i = 1;

        while (i < _numTrials) {
            latestRandomSeed = uint(keccak256(abi.encodePacked(latestRandomSeed)));

            uint arrayIndex = latestRandomSeed % arrayLength;
            address currentAddress = accountManager.getAccountFromAccountOwnersArray(arrayIndex);
            uint currentNICR = accountManager.getNominalICR(currentAddress);

            // check if abs(current - CR) > abs(closest - CR), and update closest if current is closer
            uint currentDiff = UnboundMath._getAbsoluteDifference(currentNICR, _CR);

            if (currentDiff < diff) {
                diff = currentDiff;
                hintAddress = currentAddress;
            }
            i++;
        }

    }

    function computeNominalCR(uint _coll, uint _debt) external pure returns (uint) {
        return UnboundMath._computeNominalCR(_coll, _debt);
    }

    function computeCR(uint _coll, uint _debt, uint _price) external pure returns (uint) {
        return UnboundMath._computeCR(_coll, _debt, _price);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IUnboundBase.sol";
interface IAccountManager is IUnboundBase{

    enum AccountManagerOperation {
        liquidation,
        redeemCollateral
    }
    
    event AccountIndexUpdated(address _borrower, uint _newIndex);
    event AccountUpdated(address indexed _borrower, uint _debt, uint _coll, AccountManagerOperation _operation);
    event Redemption(uint _attemptedUNDAmount, uint _actualUNDAmount, uint _CollateralSent, uint _CollateralFee);
    event AccountLiquidated(address indexed _borrower, uint _debt, uint _coll, AccountManagerOperation _operation);
    event Liquidation(uint _liquidatedDebt, uint _liquidatedColl, uint _liquidationCompensation);

    function borrowerOperations() external view returns(address);
    
    function maxPercentDiff() external view returns (uint256);
    function allowedDelay() external view returns (uint256);

    function governanceFeeAddress() external view returns (address);

    function chainLinkRegistry() external view returns (address);

    function getAccountOwnersCount() external view returns (uint);
    function getAccountFromAccountOwnersArray(uint256 _index) external view returns (address);

    function getAccountStatus(address _borrower) external view returns (uint);
    function getAccountDebt(address _borrower) external view returns (uint);
    function getAccountColl(address _borrower) external view returns (uint);
    function getEntireDebtAndColl(address _borrower) external view returns(uint256 debt, uint256 coll);

    function getNominalICR(address _borrower) external view returns (uint);
    function getCurrentICR(address _borrower, uint _price) external view returns (uint);
    
    function setAccountStatus(address _borrower, uint _num) external;
    function increaseAccountColl(address _borrower, uint _collIncrease) external returns (uint);
    function decreaseAccountColl(address _borrower, uint _collDecrease) external returns (uint);
    function increaseAccountDebt(address _borrower, uint _debtIncrease) external returns (uint);
    function decreaseAccountDebt(address _borrower, uint _debtDecrease) external returns (uint);
    
    function addAccountOwnerToArray(address _borrower) external returns (uint index);

    function closeAccount(address _borrower) external;

    function redeemCollateral(
        uint _UNDamount,
        address _firstRedemptionHint,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint _partialRedemptionHintNICR,
        uint _maxIterations,
        uint _maxFeePercentage
    ) external;

    function liquidate(address _borrower) external;

    function liquidateAccounts(uint _n) external;
    
    function batchLiquidateAccounts(address[] memory _accountArray) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface ICollSurplusPool {

    function getTotalCollateral() external view returns (uint);

    function getUserCollateral(address _account) external view returns (uint);

    function claimColl(IERC20 _depositToken, address _account) external;

    function accountSurplus(address _account, uint _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IMainPool {

    event MainPoolCollateralUpdated(uint _amount);
    event MainPoolUNDDebtUpdated(uint _amount);
    event MainPoolCollateralBalanceUpdated(uint _amount);
    event CollateralSent(address _account, uint _amount);
    event UNDMintLimitChanged(uint _newMintLimit);



    function undMintLimit() external view returns(uint256);
    
    function increaseCollateral(uint _amount) external;
    function increaseUNDDebt(uint _amount) external;
    function decreaseUNDDebt(uint _amount) external;
    function getCollateral() external view returns (uint);

    function getUNDDebt() external view returns (uint);

    function sendCollateral(IERC20 _depositToken, address _account, uint _amount) external;

    function stake(address user, uint256 amount) external;
    function unstake(address user, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

// Common interface for the SortedAccounts Doubly Linked List.
interface ISortedAccounts {

    // --- Events ---
    
    event NodeAdded(address _id, uint _NICR);
    event NodeRemoved(address _id);

    // --- Functions ---
    
    function insert(address _id, uint256 _ICR, address _prevId, address _nextId) external;

    function remove(address _id) external;

    function reInsert(address _id, uint256 _newICR, address _prevId, address _nextId) external;

    function contains(address _id) external view returns (bool);

    function isFull() external view returns (bool);

    function isEmpty() external view returns (bool);

    function getSize() external view returns (uint256);

    function getMaxSize() external view returns (uint256);

    function getFirst() external view returns (address);

    function getLast() external view returns (address);

    function getNext(address _id) external view returns (address);

    function getPrev(address _id) external view returns (address);

    function validInsertPosition(uint256 _ICR, address _prevId, address _nextId) external view returns (bool);

    function findInsertPosition(uint256 _ICR, address _prevId, address _nextId) external view returns (address, address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../interfaces/IUNDToken.sol';
import '../interfaces/ISortedAccounts.sol';
import '../interfaces/IMainPool.sol';
import '../interfaces/ICollSurplusPool.sol';
import '../interfaces/IUnboundFeesFactory.sol';

interface IUnboundBase {
    function MCR() external view returns (uint256);
    function undToken() external view returns (IUNDToken);
    function sortedAccounts() external view returns (ISortedAccounts);
    function depositToken() external view returns (IERC20);
    function mainPool() external view returns (IMainPool);
    function unboundFeesFactory() external view returns (IUnboundFeesFactory);
    function collSurplusPool() external view returns (ICollSurplusPool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IUnboundFeesFactory {
    
    event BaseRateUpdated(uint _baseRate);
    event LastFeeOpTimeUpdated(uint _lastFeeOpTime);
    event AccountManagerUpdated(address _accManager, bool _status);
    event BorrowOpsUpdated(address _borrowOps, bool _status);

    function REDEMPTION_FEE_FLOOR() external view returns (uint);
    function BORROWING_FEE_FLOOR() external view returns (uint);

    function getBorrowingRate() external view returns (uint);
    function getBorrowingRateWithDecay() external view returns (uint);

    function getBorrowingFee(uint _UNDDebt) external view returns (uint);
    function getBorrowingFeeWithDecay(uint _UNDDebt) external view returns (uint);

    function getRedemptionRate() external view returns (uint);
    function getRedemptionFee(uint _UNDDebt) external view returns (uint);
    function getRedemptionRateWithDecay() external view returns (uint);
    function getRedemptionFeeWithDecay(uint _CollateralDrawn) external view returns (uint);

    function decayBaseRateFromBorrowing() external;

    function updateBaseRateFromRedemption(uint _CollateralDrawn,  uint _price, uint _totalUNDSupply) external returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IUNDToken {

    function mint(address _account, uint256 _amount) external;
    function burn(address _account, uint256 _amount) external;
    function balanceOf(address _account) external view returns(uint256);
    function totalSupply() external view returns(uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

library UnboundMath {

    uint internal constant DECIMAL_PRECISION = 1e18;

    /* Precision for Nominal ICR (independent of price). Rationale for the value:
     *
     * - Making it “too high” could lead to overflows.
     * - Making it “too low” could lead to an ICR equal to zero, due to truncation from Solidity floor division. 
     *
     * This value of 1e20 is chosen for safety: the NICR will only overflow for numerator > ~1e39 LPTs,
     * and will only truncate to 0 if the denominator is at least 1e20 times greater than the numerator.
     *
     */
    uint internal constant NICR_PRECISION = 1e20;

    function _min(uint _a, uint _b) internal pure returns (uint) {
        return (_a < _b) ? _a : _b;
    }

    function _max(uint _a, uint _b) internal pure returns (uint) {
        return (_a >= _b) ? _a : _b;
    }

    /* 
    * Multiply two decimal numbers and use normal rounding rules:
    * -round product up if 19'th mantissa digit >= 5
    * -round product down if 19'th mantissa digit < 5
    *
    * Used only inside the exponentiation, _decPow().
    */
    function decMul(uint x, uint y) internal pure returns (uint decProd) {
        uint prod_xy = x * y;

        decProd = (prod_xy + (DECIMAL_PRECISION / 2)) / DECIMAL_PRECISION;
    }

    /* 
    * _decPow: Exponentiation function for 18-digit decimal base, and integer exponent n.
    * 
    * Uses the efficient "exponentiation by squaring" algorithm. O(log(n)) complexity. 
    * 
    * Called by two functions that represent time in units of minutes:
    * 1) UnboundFeesFactory._calcDecayedBaseRate
    * 2) CommunityIssuance._getCumulativeIssuanceFraction 
    * 
    * The exponent is capped to avoid reverting due to overflow. The cap 525600000 equals
    * "minutes in 1000 years": 60 * 24 * 365 * 1000
    * 
    * If a period of > 1000 years is ever used as an exponent in either of the above functions, the result will be
    * negligibly different from just passing the cap, since: 
    *
    * In function 1), the decayed base rate will be 0 for 1000 years or > 1000 years
    * In function 2), the difference in tokens issued at 1000 years and any time > 1000 years, will be negligible
    */
    function _decPow(uint _base, uint _minutes) internal pure returns (uint) {
       
        if (_minutes > 525600000) {_minutes = 525600000;}  // cap to avoid overflow
    
        if (_minutes == 0) {return DECIMAL_PRECISION;}

        uint y = DECIMAL_PRECISION;
        uint x = _base;
        uint n = _minutes;

        // Exponentiation-by-squaring
        while (n > 1) {
            if (n % 2 == 0) {
                x = decMul(x, x);
                n = n / 2;
            } else { // if (n % 2 != 0)
                y = decMul(x, y);
                x = decMul(x, x);
                n = (n - 1) / 2;
            }
        }

        return decMul(x, y);
  }

    function _getAbsoluteDifference(uint _a, uint _b) internal pure returns (uint) {
        return (_a >= _b) ? _a - _b : _b - _a;
    }

    function _computeNominalCR(uint _coll, uint _debt) internal pure returns (uint) {
        if (_debt > 0) {
            return (_coll * NICR_PRECISION) / _debt;
        }
        // Return the maximal value for uint256 if the Account has a debt of 0. Represents "infinite" CR.
        else { // if (_debt == 0)
            return 2**256 - 1;
        }
    }

    function _computeCR(uint _coll, uint _debt, uint _price) internal pure returns (uint) {
        if (_debt > 0) {
            uint newCollRatio = (_coll * _price) / _debt;

            return newCollRatio;
        }
        // Return the maximal value for uint256 if the Account has a debt of 0. Represents "infinite" CR.
        else { // if (_debt == 0)
            return 2**256 - 1; 
        }
    }
}