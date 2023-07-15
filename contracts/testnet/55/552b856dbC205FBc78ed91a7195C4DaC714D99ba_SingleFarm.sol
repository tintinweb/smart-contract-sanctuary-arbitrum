// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

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
        if (_initialized != type(uint8).max) {
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.0;
interface IHasAdministrable {
  function admin() external view returns (address);
}

// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.0;
interface IHasOwnable {
  function owner() external view returns (address);
}

// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.0;

interface IHasPausable {
  function isPaused() external view returns (bool);
}

// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.0;
interface IHasTreasury {
  function treasury() external view returns (address);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

uint256 constant FEE_DENOMINATOR = 100e18;

error AboveMax(uint256 max, uint256 given);
error BelowMin(uint256 min, uint256 given);
error ZeroAddress();
error ZeroAmount();
error ZeroTokenBalance();
error NoAccess(address desired, address given);
error StillFundraising(uint256 desired, uint256 given);
error InvalidSignature(address desired, address given);

error NoManagerFund(address manager);
error NoBaseToken(address token);
error AlreadyOpened();
error CantClose();
error NotOpened();
error NotFinalised();
error OpenPosition();
error NoOpenPositions();

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IDepositConfig {
    function minInvestmentAmount() external view returns (uint256);
    function maxInvestmentAmount() external view returns (uint256);
    function minManagerInvestmentAmount() external view returns (uint256);
    function capacityPerFarm() external view returns (uint256);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ISingleFarmFactory} from "./ISingleFarmFactory.sol";

interface ISingleFarm {
    /// @notice Enum to describe the trading status of the farm
    /// @dev NOT_OPENED - Not open
    /// @dev OPENED - opened position
    /// @dev CLOSED - closed position
    /// @dev LIQUIDATED - liquidated position
    /// @dev CANCELLED - did not start due to deadline reached
    enum SfStatus {
        NOT_OPENED,
        OPENED,
        CLOSED,
        LIQUIDATED,
        CANCELLED
    }

    event Deposited(address indexed investor, uint256 amount);
    event FundraisingClosedAndPositionOpened();
    event FundraisingClosed();
    event PositionOpened();
    event PositionClosed();
    event Cancelled();
    event Liquidated();
    event Claimed(address investor, uint256 amount);
    event FundDeadlineChanged(uint256 fundDeadline);

    event StatusUpdated(address indexed from, ISingleFarm.SfStatus status);
    event TotalRaisedUpdated(address indexed from, uint256 totalRaised);
    event RemainingBalanceUpdated(address indexed from, uint256 remainingBalance);
    event OperatorUpdated(address indexed from, address operator);

    function deposit(uint256 amount) external;
    function closeFundraisingAndOpenPosition() external;
    function closeFundraising() external;
    function openPosition() external;
    function closePosition() external;
    function cancelByAdmin() external;
    function cancelByManager() external;
    function liquidate() external;
    function claim() external;
    function setFundDeadline(uint256 newFundDeadline) external;

    function getUserAmount(address _investor) external view returns (uint256);
    function getClaimAmount(address _investor) external view returns (uint256);
    function claimableAmount(address _investor) external view returns (uint256);
    function getClaimed(address _investor) external view returns (bool);
    function remainingAmountAfterClose() external view returns (uint256);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ISingleFarmFactory {
    event FarmFactoryInitialized(
        address singleFarmImplementation,
        uint256 capacityPerFarm,
        uint256 minInvestmentAmount,
        uint256 maxInvestmentAmount,
        uint256 minManagerInvestmentAmount,
        uint256 maxLeverage,
        address usdc,
        address admin,
        address maker,
        address treasury
    );

    event FarmCreated(
        address indexed farm,
        address indexed baseToken,
        uint256 fundraisingPeriod,
        uint256 entryPrice,
        uint256 targetPrice,
        uint256 liquidationPrice,
        uint256 leverage,
        bool tradeDirection,
        address indexed manager,
        uint256 managerFee,
        address operator
    );

    event CapacityPerFarmChanged(uint256 capacity);
    event MaxInvestmentAmountChanged(uint256 maxAmount);
    event MinInvestmentAmountChanged(uint256 maxAmount);
    event MinManagerInvestmentAmountChanged(uint256 maxAmount);
    event MaxLeverageChanged(uint256 maxLeverage);
    event MinLeverageChanged(uint256 minLeverage);
    event MaxFundraisingPeriodChanged(uint256 maxFundraisingPeriod);
    event MaxManagerFeeChanged(uint256 maxManagerFee);
    event ProtocolFeeChanged(uint256 protocolFee);
    event EthFeeChanged(uint256 ethFee);
    event FarmImplementationChanged(address indexed df);
    event UsdcAddressChanged(address indexed usdc);
    event AdminChanged(address indexed admin);
    event MakerChanged(address indexed maker);
    event TreasuryChanged(address indexed treasury);

    struct Sf {
        address baseToken;
        bool tradeDirection; // Long/Short
        uint256 fundraisingPeriod;
        uint256 entryPrice;
        uint256 targetPrice;
        uint256 liquidationPrice;
        uint256 leverage;
    }

/*     function minInvestmentAmount() external view returns (uint256);
    function maxInvestmentAmount() external view returns (uint256);
    function minManagerInvestmentAmount() external view returns (uint256);
    function capacityPerFarm() external view returns (uint256); */
    function getProtocolFee() external view returns (uint256, uint256);

    function createFarm(Sf calldata _sf, uint256 _managerFee, address _operator, bytes memory _signature) external payable returns (address);

    function setCapacityPerFarm(uint256 _capacity) external;

    function setMinInvestmentAmount(uint256 _amount) external;

    function setMaxInvestmentAmount(uint256 _amount) external;

    function setMinManagerInvestmentAmount(uint256 _amount) external;

    function setMaxLeverage(uint256 _maxLeverage) external;

    function setMinLeverage(uint256 _minLeverage) external;

    function setMaxManagerFee(uint256 _managerFee) external;

    function setProtocolFee(uint256 _protocolFee) external;

    function setSfImplementation(address _sf) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./Errors.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ISingleFarm} from "./interfaces/ISingleFarm.sol";
import {ISingleFarmFactory} from "./interfaces/ISingleFarmFactory.sol";
import {IDepositConfig} from "./interfaces/IDepositConfig.sol";
import "../interfaces/IHasOwnable.sol";
import {IHasAdministrable} from "../interfaces/IHasAdministrable.sol";
import "../interfaces/IHasPausable.sol";
import "../interfaces/IHasTreasury.sol";

/// @title SingleFarm
/// @notice Contract for the investors to deposit and for managers to open and close positions
contract SingleFarm is ISingleFarm, Initializable {
    bool private calledOpen;

    ISingleFarmFactory.Sf public sf;

    address public USDC;

    address public factory;
    address public manager;
    address public operator;
    uint256 public endTime;
    uint256 public fundDeadline;
    uint256 public totalRaised;
    uint256 public actualTotalRaised;
    SfStatus public status;
    uint256 public override remainingAmountAfterClose;
    mapping(address => uint256) public userAmount;
    mapping(address => uint256) public claimAmount;
    mapping(address => bool) public claimed;
    uint256 private managerFee;

    function initialize(
        ISingleFarmFactory.Sf calldata _sf,
        address _manager,
        uint256 _managerFee,
        address _usdc,
        address _operator
    ) public initializer {
        sf = _sf;
        factory = msg.sender;
        manager = _manager;
        managerFee = _managerFee;
        operator = _operator;
        endTime = block.timestamp + _sf.fundraisingPeriod;
        fundDeadline = 72 hours;
        USDC = _usdc;
    }

    modifier onlyOwner() {
        require(msg.sender == IHasOwnable(factory).owner(), "only owner");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == IHasAdministrable(factory).admin(), "only admin");
        _;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "only manager");
        _;
    }

    modifier openOnce() {
        require(!calledOpen, "can only open once");
        calledOpen = true;
        _;
    }

    modifier whenNotPaused() {
        require(!IHasPausable(factory).isPaused(), "contracts paused");
        _;
    }

    /// @notice deposit a particular amount into a farm for the manager to open a position
    /// @dev `fundraisingPeriod` has to end and the `totalRaised` should not be more than `capacityPerFarm`
    /// @dev amount has to be between `minInvestmentAmount` and `maxInvestmentAmount`
    /// @dev approve has to be called before this method for the investor to transfer usdc to this contract
    /// @param amount amount the investor wants to deposit
    function deposit(uint256 amount) external override whenNotPaused {
        IDepositConfig depositConfig = IDepositConfig(factory);

        if (block.timestamp > endTime) revert AboveMax(endTime, block.timestamp);
        if (amount <  depositConfig.minInvestmentAmount()) revert BelowMin(depositConfig.minInvestmentAmount(), amount);
        if (userAmount[msg.sender] + amount > depositConfig.maxInvestmentAmount()) {
            revert AboveMax(depositConfig.maxInvestmentAmount(), userAmount[msg.sender] + amount);
        }
        if (status != SfStatus.NOT_OPENED) revert AlreadyOpened();
        if (totalRaised + amount > depositConfig.capacityPerFarm()) revert AboveMax(depositConfig.capacityPerFarm(), totalRaised + amount);
        if (
            userAmount[manager] < depositConfig.minManagerInvestmentAmount() &&
            msg.sender != manager
        ) revert NoManagerFund(manager);

        IERC20Upgradeable(USDC).transferFrom(msg.sender, address(this), amount);

        totalRaised += amount;
        userAmount[msg.sender] += amount;
        actualTotalRaised += amount;

        emit Deposited(msg.sender, amount);
    }

    /// @notice allows the manager to end the `fundraisingPeriod` early and open a market position
    /// @dev transfers the `totalRaised` usdc of the farm to the operator
    function closeFundraisingAndOpenPosition() external override openOnce whenNotPaused {
        if(msg.sender != manager) revert NoAccess(manager, msg.sender);

        if (status != SfStatus.NOT_OPENED) revert AlreadyOpened();
        if (block.timestamp < endTime) revert CantClose();
        if (totalRaised < 1) revert ZeroAmount();

        // update state variables
        status = SfStatus.OPENED;
        endTime = block.timestamp;

        if(operator == address(0)) revert ZeroAddress();
        IERC20Upgradeable(USDC).transfer(operator, totalRaised);

        emit FundraisingClosedAndPositionOpened();
    }

    /// @notice allows the manager to close the fundraising and open a position later
    /// @dev changes the `endTime` to the current `block.timestamp`
    function closeFundraising() external override whenNotPaused {
        if (manager != msg.sender) revert NoAccess(manager, msg.sender);
        if (status != SfStatus.NOT_OPENED) revert AlreadyOpened();
        if (totalRaised < 1) revert ZeroAmount();
        if (block.timestamp < endTime) revert CantClose();

        endTime = block.timestamp;

        emit FundraisingClosed();
    }

    function openPosition() external override openOnce whenNotPaused {
        if(msg.sender != manager) revert NoAccess(manager, msg.sender);

        if (endTime > block.timestamp) revert StillFundraising(endTime, block.timestamp);
        if (status != SfStatus.NOT_OPENED) revert AlreadyOpened();
        if (totalRaised < 1) revert ZeroAmount();

        status = SfStatus.OPENED;

        if(operator == address(0)) revert ZeroAddress();
        IERC20Upgradeable(USDC).transfer(operator, totalRaised);

        emit PositionOpened();
    }

    /// @notice allows the manager/operator to mark farm as closed
    /// @dev can be called only if theres a position already open
    /// @dev `status` will be `PositionClosed`
    function closePosition() external override whenNotPaused {
        if (msg.sender != manager && msg.sender != operator) revert NoAccess(manager, msg.sender);
        if (status != SfStatus.OPENED) revert NoOpenPositions();

        IERC20Upgradeable usdc = IERC20Upgradeable(USDC);
        uint256 allowanceAmount = usdc.allowance(operator, address(this));
        if(allowanceAmount == 0) revert ZeroAmount();
        usdc.transferFrom(operator, address(this), allowanceAmount);

        uint256 _usdcBalance = usdc.balanceOf(address(this));

        if(_usdcBalance > totalRaised) {
            uint256 profits = _usdcBalance - totalRaised;

            uint256 _managerFee = (profits * managerFee) / FEE_DENOMINATOR;
            if(_managerFee > 0) usdc.transfer(manager, _managerFee);

            (uint256 _protocolFeeNumerator, ) = ISingleFarmFactory(factory).getProtocolFee();
            uint256 _protocolFee = (profits * _protocolFeeNumerator) / FEE_DENOMINATOR;
            if(_protocolFee > 0) usdc.transfer(IHasTreasury(factory).treasury(), _protocolFee);

            remainingAmountAfterClose = usdc.balanceOf(address(this));
        }
        else {
            remainingAmountAfterClose = _usdcBalance;
        }

        status = SfStatus.CLOSED;

        emit PositionClosed();
    }

    /// @notice the manager can cancel the farm if they want, after fundraising
    /// @dev can be called by the `manager`
    function cancelByManager() external override whenNotPaused {
        if (msg.sender != manager) revert NoAccess(manager, msg.sender);
        if (status != SfStatus.NOT_OPENED) revert OpenPosition();
        if (block.timestamp > endTime + fundDeadline) revert CantClose();

        fundDeadline = 0;
        endTime = 0;
        status = SfStatus.CANCELLED;

        emit Cancelled();
    }

    /// @notice set the `fundDeadline` for a particular farm to cancel the farm early if needed
    /// @dev can only be called by the `owner` or the `manager` of the df
    /// @param newFundDeadline new fundDeadline
    function setFundDeadline(uint256 newFundDeadline) external override {
        if (msg.sender != manager && msg.sender != IHasAdministrable(factory).admin()) revert NoAccess(manager, msg.sender);
        if (newFundDeadline > 72 hours) revert AboveMax(72 hours, newFundDeadline);
        fundDeadline = newFundDeadline;
        emit FundDeadlineChanged(newFundDeadline);
    }

    /// @notice transfers the collateral to the investor depending on the investor's weightage to the totalRaised by the farm
    /// @dev will revert if the investor did not invest in the farm during the fundraisingPeriod
    function claim() external override whenNotPaused {
        if (
            status != SfStatus.CLOSED &&
            status != SfStatus.CANCELLED
        ) revert NotFinalised();

        uint256 amount = claimableAmount(msg.sender);
        if (amount < 1) revert ZeroTokenBalance();

        claimed[msg.sender] = true;
        claimAmount[msg.sender] = amount;

        IERC20Upgradeable(USDC).transfer(msg.sender, amount);

        emit Claimed(msg.sender, amount);
    }

    /*//////////////////////////////////////////////////////////////
                            OWNER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Set the `status` of a farm in case of an emergency
    /// @param _status new `status` of the farm
    function setStatus(SfStatus _status) external onlyOwner {
        status = _status;
        emit StatusUpdated(msg.sender, _status);
    }

    /// @notice Set the `totalRaised` of an df in case of an emergency
    /// @dev is called only from the `Df` contract and reverts if called by another address
    /// @param _totalRaised new `totalRaised` of the df
    function setTotalRaised(uint256 _totalRaised) external onlyOwner {
        totalRaised = _totalRaised;
        emit TotalRaisedUpdated(msg.sender, _totalRaised);
    }

    /// @notice Set the `remainingAmountAfterClose` of an df in case of an emergency
    /// @dev is called only from the `Df` contract and reverts if called by another address
    /// @param _remainingBalance new `remainingAmountAfterClose` of the farm
    function setRemainingBalance(uint256 _remainingBalance) external onlyOwner {
        remainingAmountAfterClose = _remainingBalance;
        emit RemainingBalanceUpdated(msg.sender, _remainingBalance);
    }

    /// @notice Set the `operator` of an farm in case of an emergency
    /// @param _newOperator new `operator` of the farm
    function setOperator(address _newOperator) external onlyOwner {
        if(_newOperator == address(0)) revert ZeroAddress();
        operator = _newOperator;
        emit OperatorUpdated(msg.sender, operator);
    }

    /*//////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice will change the status of the df to `LIQUIDATED`
    /// @dev can be called once an df is liquidated from the dex
    /// @dev can only be called by the `admin`
    function liquidate() external override onlyAdmin whenNotPaused {
        if (status != SfStatus.OPENED) revert NotOpened();
        status = SfStatus.LIQUIDATED;
        emit Liquidated();
    }

    /// @notice will change the status of the df to `CANCELLED`
    /// @dev can be called if there was nothing raised during `fundraisingPeriod`
    /// @dev or can be called if the manager did not open any position within the `fundDeadline` (default - 72 hours)
    /// @dev can only be called by the `admin`
    function cancelByAdmin() external override onlyAdmin whenNotPaused {
        if (status != SfStatus.NOT_OPENED) revert OpenPosition();
        if (totalRaised == 0) {
            if (block.timestamp <= endTime) revert BelowMin(endTime, block.timestamp);
        } else {
            if (block.timestamp <= endTime + fundDeadline) revert BelowMin(endTime + fundDeadline, block.timestamp);
        }

        status = SfStatus.CANCELLED;

        emit Cancelled();
    }

    /*//////////////////////////////////////////////////////////////
                              VIEW
    //////////////////////////////////////////////////////////////*/

    function getInfo()
        external
        view
        returns (address, uint256, uint256, uint256, uint256, SfStatus)
    {
        return (
            manager,
            totalRaised,
            remainingAmountAfterClose,
            endTime,
            fundDeadline,
            status
        );
    }

    function getManagerFee() public view returns(uint256, uint256) {
        return (managerFee, FEE_DENOMINATOR);
    }

    function getStatus() public view returns (SfStatus) {
        return status;
    }

    function getUserAmount(address _investor) public view returns (uint256) {
        return userAmount[_investor];
    }

    /// @notice get the `claimableAmount` of the investor from a particular df
    /// @dev if theres no position opened, it'll return the deposited amount
    /// @dev after the position is closed, it'll calculate the `claimableAmount` depending on the weightage of the investor
    /// @param _investor address of the investor
    /// @return amount which can be claimed by the investor from a particular df
    function claimableAmount(address _investor) public view override returns (uint256 amount) {
        if (claimed[_investor] || status == SfStatus.OPENED) {
            amount = 0;
        } else if (status == SfStatus.CANCELLED || status == SfStatus.NOT_OPENED) {
            amount = (totalRaised * userAmount[_investor] * 1e18) / (actualTotalRaised * 1e18);
        } else if (status == SfStatus.CLOSED) {
            amount = (remainingAmountAfterClose * userAmount[_investor] * 1e18) / (actualTotalRaised * 1e18);
        } else {
            amount = 0;
        }
    }

    function getClaimAmount(address _investor) external view override returns (uint256) {
        return claimAmount[_investor];
    }


    function getClaimed(address _investor) external view override returns (bool) {
        return claimed[_investor];
    }

    function withdraw(address receiver, bool isEth, address token, uint256 amount) external onlyOwner returns (bool) {
        if(isEth) {
            payable(receiver).transfer(amount);
        }
        else {
            IERC20Upgradeable(token).transfer(receiver, amount);
        }

        return true;
    }
}