// SPDX-License-Identifier: MIT

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;

interface ISwapLogic {
    struct CurrencyAmount {
        address currency;
        uint256 amount;
    }

    struct Whitelist {
        address target;
        bool allowed;
    }


    event Transfer(address currency, address receiver, uint256 amount);
    
    event Swap(
        address inputCurrency, 
        address outputCurrency, 
        uint256 inputAmount, 
        uint256 outputAmount, 
        uint256 fee, 
        uint256 feeRate
    );

    event Deposit(
        address inputCurrency, 
        address outputCurrency, 
        uint256 inputAmount, 
        uint256 outputAmount, 
        uint256 fee, 
        uint256 feeRate
    );

    /// @notice Deposit the collateral token for other account
    /// @param input The address of the account to deposit to
    /// @param outputCurrency The address of collateral token
    /// @param recipient The address of collateral token
    /// @param to The address of collateral token
    /// @param callData The address of collateral token
    function swap(
        CurrencyAmount calldata input,
        address outputCurrency,
        address recipient,
        address to,
        bytes calldata callData
    ) external payable;

    /// @notice Deposit the collateral token for other account
    /// @param input The address of the account to deposit to
    /// @param token The address of collateral token
    /// @param recipient The address of collateral token
    /// @param to The address of collateral token
    /// @param callData The address of collateral token
    function deposit(
        CurrencyAmount calldata input,
        address token,
        address recipient,
        address to,
        bytes calldata callData
    ) external payable;

    function setWhitelist(Whitelist[] calldata whitelist) external;

    function setFeeRate(uint256 feeRate) external;

    function setFeeRecipient(address feeRecipient) external;

    function setVault(address vault) external;

    function getFeeRate() external view returns (uint256);

    function getFeeRecipient() external view returns (address);

    function getVault() external view returns (address);

    function allowed(address target) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;

interface IVault {
    event Deposited(address indexed collateralToken, address indexed trader, uint256 amount);

    event Withdrawn(address indexed collateralToken, address indexed trader, uint256 amount);

    /// @param token the address of the token to deposit;
    ///        once multi-collateral is implemented, the token is not limited to settlementToken
    /// @param amountX10_D the amount of the token to deposit in decimals D (D = _decimals)
    function deposit(address token, uint256 amountX10_D) external;

    /// @notice Deposit the collateral token for other account
    /// @param to The address of the account to deposit to
    /// @param token The address of collateral token
    /// @param amountX10_D The amount of the token to deposit
    function depositFor(
        address to,
        address token,
        uint256 amountX10_D
    ) external;

    /// @param token the address of the token sender is going to withdraw
    ///        once multi-collateral is implemented, the token is not limited to settlementToken
    /// @param amountX10_D the amount of the token to withdraw in decimals D (D = _decimals)
    function withdraw(address token, uint256 amountX10_D) external;

    function getBalance(address account) external view returns (int256);

    /// @param trader The address of the trader to query
    /// @return freeCollateral Max(0, amount of collateral available for withdraw or opening new positions or orders)
    function getFreeCollateral(address trader) external view returns (uint256);

    /// @dev there are three configurations for different insolvency risk tolerances: conservative, moderate, aggressive
    ///      we will start with the conservative one and gradually move to aggressive to increase capital efficiency
    /// @param trader the address of the trader
    /// @param ratio the margin requirement ratio, imRatio or mmRatio
    /// @return freeCollateralByRatio freeCollateral, by using the input margin requirement ratio; can be negative
    function getFreeCollateralByRatio(address trader, uint24 ratio) external view returns (int256);

    function getSettlementToken() external view returns (address);

    /// @dev cached the settlement token's decimal for gas optimization
    function decimals() external view returns (uint8);

    function getTotalDebt() external view returns (uint256);

    function getClearingHouseConfig() external view returns (address);

    function getPositionMgmt() external view returns (address);

    function getInsuranceFund() external view returns (address);

    function getMarketTaker() external view returns (address);

    function getClearingHouse() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;

/// @notice For future upgrades, do not change SwapStorageV1. Create a new
/// contract which implements SwapStorageV1 and following the naming convention
/// SwapStorageV2.
abstract contract SwapStorageV1 {
    // --------- IMMUTABLE ---------

    address internal constant NATIVE_CURRENCY = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    
    address internal constant EMPTY_ADDRESS = address(0);

    // --------- ^^^^^^^^^ ---------

    uint256 internal _feeRate = 0;
    address internal _vault = EMPTY_ADDRESS;
    address internal _feeRecipient = EMPTY_ADDRESS;

    // key: exchange, allowed
    mapping(address => bool) internal _whitelist;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interface/ISwap.sol";
import "../interface/IVault.sol";
import "../storage/SwapStorage.sol";

contract SwapLogic is ISwapLogic, Initializable, OwnableUpgradeable, SwapStorageV1 {
    function initialize(
        address vault,
        address feeRecipient, 
        uint256 feeRate, 
        Whitelist[] calldata whitelist
    ) public initializer {
        __Ownable_init();
        setVault(vault);
        setFeeRecipient(feeRecipient);
        setFeeRate(feeRate);
        setWhitelist(whitelist);
    }

    /**
     * Returns the amount of `currency` owned by the contract.
     */
    function _balanceOf(address currency) view private returns (uint256) {
        if (currency == NATIVE_CURRENCY) {
            return address(this).balance;
        } else {
            return IERC20(currency).balanceOf(address(this));
        }
    }

    /**
     * Transfer `amount` `currency` from the contract's account to `recipient`.
     */
    function _transfer(address currency, address recipient, uint256 amount) private {
        if (currency == NATIVE_CURRENCY) {
            payable(recipient).transfer(amount);
        } else {
            IERC20(currency).transfer(recipient, amount);
        }
        emit Transfer(currency, recipient, amount);
    }

    function _execute(
        CurrencyAmount calldata input,
        address outputCurrency,
        address to,
        bytes calldata callData
    ) private returns (uint256, uint256) {
        require(allowed(to), "Swap: address not allowed");

        if (input.currency == NATIVE_CURRENCY) {
            require(msg.value >= input.amount, "Swap: Insufficient balance");
        } else {
            IERC20(input.currency).transferFrom(msg.sender, address(this), input.amount);
            IERC20(input.currency).approve(to, input.amount);
        }

        (bool success, bytes memory ret) = to.call{value: msg.value}(callData);
        require(success, string(ret));

        // Get the output amount after execution
        uint256 amount = _balanceOf(outputCurrency);
        uint256 fee = 0;
        uint256 feeRate = getFeeRate();
        address feeRecipient = getFeeRecipient();

        // Deduct fee when feeRate > 0
        if (feeRate > 0 && feeRecipient != EMPTY_ADDRESS) {
            fee = amount * feeRate / 10000;
            amount = amount - fee;

            _transfer(outputCurrency, feeRecipient, fee);
        }

        return (amount, fee);
    }

    /// @inheritdoc ISwapLogic
    function swap(
        CurrencyAmount calldata input,
        address outputCurrency,
        address recipient,
        address to,
        bytes calldata callData
    ) external override payable {
        (uint256 amount, uint256 fee) = _execute(input, outputCurrency, to, callData);

        // Transfer the remaining amount to the recipient
        _transfer(outputCurrency, recipient, amount);

        emit Swap(
            input.currency,
            outputCurrency, 
            input.amount, 
            amount, 
            fee, 
            _feeRate
        );
    }

    function deposit(
        CurrencyAmount calldata input,
        address outputCurrency,
        address recipient,
        address to,
        bytes calldata callData
    ) external override payable {
        (uint256 amount, uint256 fee) = _execute(input, outputCurrency, to, callData);
        uint256 feeRate = getFeeRate();
        address vault = getVault();

        if (outputCurrency != NATIVE_CURRENCY) {
            IERC20(outputCurrency).approve(vault, amount);
        }
        IVault(vault).depositFor(recipient, outputCurrency, amount);

        emit Deposit(
            input.currency,
            outputCurrency, 
            input.amount, 
            amount, 
            fee, 
            feeRate
        );
    }

    /**
     * Configuration related functions
     */
    function setWhitelist(Whitelist[] calldata whitelist) public override onlyOwner {
        for (uint256 i = 0; i < whitelist.length; i++) {
            _whitelist[whitelist[i].target] = whitelist[i].allowed;
        }
    }

    function setFeeRate(uint256 feeRate) public override onlyOwner {
        _feeRate = feeRate;
    }

    function setFeeRecipient(address feeRecipient) public override onlyOwner {
        _feeRecipient = feeRecipient;
    }

    function setVault(address vault) public override onlyOwner {
        _vault = vault;
    }

    function getFeeRate() public override view returns (uint256) {
        return _feeRate;
    }

    function getFeeRecipient() public override view returns (address) {
        return _feeRecipient;
    }

    function getVault() public override view returns (address) {
        return _vault;
    }

    function allowed(address target) public override view returns (bool) {
        return _whitelist[target];
    }

    receive() external payable {}
}