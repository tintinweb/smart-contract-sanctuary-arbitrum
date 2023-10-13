// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/UpgradeableBeacon.sol)

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../../access/Ownable.sol";
import "../../utils/Address.sol";

/**
 * @dev This contract is used in conjunction with one or more instances of {BeaconProxy} to determine their
 * implementation contract, which is where they will delegate all function calls.
 *
 * An owner is able to change the implementation the beacon points to, thus upgrading the proxies that use this beacon.
 */
contract UpgradeableBeacon is IBeacon, Ownable {
    address private _implementation;

    /**
     * @dev Emitted when the implementation returned by the beacon is changed.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Sets the address of the initial implementation, and the deployer account as the owner who can upgrade the
     * beacon.
     */
    constructor(address implementation_) {
        _setImplementation(implementation_);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view virtual override returns (address) {
        return _implementation;
    }

    /**
     * @dev Upgrades the beacon to a new implementation.
     *
     * Emits an {Upgraded} event.
     *
     * Requirements:
     *
     * - msg.sender must be the owner of the contract.
     * - `newImplementation` must be a contract.
     */
    function upgradeTo(address newImplementation) public virtual onlyOwner {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Sets the implementation contract address for this beacon
     *
     * Requirements:
     *
     * - `newImplementation` must be a contract.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableBeacon: implementation is not a contract");
        _implementation = newImplementation;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

pragma solidity ^0.8.0;

interface IGmxRouter {
    function addPlugin(address _plugin) external;

    function approvePlugin(address _plugin) external;

    function pluginTransfer(
        address _token,
        address _account,
        address _receiver,
        uint256 _amount
    ) external;

    function pluginIncreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong
    ) external;

    function pluginDecreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver
    ) external returns (uint256);

    function swap(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _minOut,
        address _receiver
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPositionRouter {
    function minExecutionFee() external view returns (uint256);

    function increasePositionRequestKeysStart() external returns (uint256);

    function decreasePositionRequestKeysStart() external returns (uint256);

    function executeIncreasePositions(
        uint256 _count,
        address payable _executionFeeReceiver
    ) external;

    function executeDecreasePositions(
        uint256 _count,
        address payable _executionFeeReceiver
    ) external;

    function createIncreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) external payable;

    function createDecreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _acceptablePrice,
        uint256 _minOut,
        uint256 _executionFee,
        bool _withdrawETH,
        address _callbackTarget
    ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IPriceFeed {
    function description() external view returns (string memory);
    function aggregator() external view returns (address);
    function latestAnswer() external view returns (int256);
    function latestRound() external view returns (uint80);
    function decimals() external view returns (uint256);
    function getRoundData(uint80 roundId) external view returns (uint80, int256, uint256, uint256, uint80);
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.0;

enum FundState {
    Closed,
    Opened
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDripOperator {
    // returns true if a report was finished
    function drip(uint256 fundId, uint256 tradeTvl) external returns (bool);
    function isDripInProgress(uint256 fundId) external view returns (bool);
    function isDripEnabled(uint256 fundId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IToken.sol";

uint256 constant MAX_USERS_PER_BATCH = 20;
uint256 constant DRIP_GAS_USAGE = 1530000;
interface IFeeder {

    struct UserPosition {
        uint256 totalDeposit; // USDT
        uint256 totalWithdrawal; // USDT
        uint256 tokenAmount; // USDT
    }

    struct UserAccruals {
        uint256 deposit; // user pending deposit amount (USDT)
        uint256 withdraw; // user pending withdrawals amount (iTOKEN)
        uint256 indentedWithdraw;
    }

    struct FundInfo {
        uint256 lastPeriod;
        IToken itoken;
        address trade;
    }

    struct FundHwmData {
        bool hwm;
        uint256 hwmValue;
    }

    /**
    * Events
    */
    event NewFund(uint256 fundId, address manager);

    event Deposit(uint256 fundId, address depositedFrom, uint256 amount);
    event DepositCancelled(uint256 fundId, address indexed user, uint256 amount);
    event DepositProcessed(uint256 indexed fundId, address indexed user, uint256 amount, uint256 sharesAmount);

    event WithdrawalRequested(uint256 fundId, address indexed user, uint256 amount);
    event Withdrawal(uint256 fundId, address indexed user, uint256 amount);
    event WithdrawalCancelled(uint256 fundId, address indexed user, uint256 amount);

    event FundsTransferredToTrader(uint256 fundId, address trader, uint256 amount);

    event FeesChanged(address newFees);
    /**
    * Public
    */

    function stake(uint256 fundId, address user, uint256 amount) external returns (uint256 stakedAmount);

    function requestWithdrawal(uint256 fundId, address user, uint256 amount, bool indented) external;

    function cancelDeposit(uint256 fundId, address user) external returns (uint256);
    function cancelWithdrawal(uint256 fundId, address user) external returns (uint256);

    /**
    * Auth
    */

    function newFund(uint256 fundId,
        address manager,
        IToken itoken,
        address trade,
        bool hwm
    ) external;

    // returns count of actually processed withdrawals
    function withdrawMultiple(uint256 fundId, uint256 supply, uint256 toWithdraw, uint256 tradeTvl, uint256 maxBatchSize) external returns (uint256);
    // returns count of actually processed deposits and amount of debt left
    function drip(uint256 fundId, uint256 subtracted, uint256 tokenSupply, uint256 tradeTvl, uint256 maxBatchSize) external returns (uint256, uint256);
    // returns count of remaining indented withdrawals
    function moveIndentedWithdrawals(uint256 fundId, uint256 maxBatchSize) external returns (uint256);
    function gatherFees(uint256 fundId, uint256 tradeTvl, uint256 executionFee) external;
    function saveHWM(uint256 fundId, uint256 tradeTvl) external;
    function transferFromTrade(uint256 fundId, uint256 amount) external;

    /**
    * View
    */
    function getFund(uint256 fundId) external view returns (FundInfo memory);
    function userWaitingForWithdrawal(uint256 fundId) external view returns (address[] memory);
    function userWaitingForDeposit(uint256 fundId) external view returns(address[] memory);
    function getPendingOperationsCount(uint256 fundId) external view returns (uint256);

    function tokenRate(uint256 fundId, uint256 tradeTvl) external view returns (uint256);
    function hwmValue(uint256 fundId) external view returns (uint256);
    function pendingTvl(uint256 fundId, uint256 tradeTvl) external view returns (uint256, uint256, uint256);
    function calculatePf(uint256 fundId, uint256 tradeTvl) external view returns (uint256);
    function getUserAccrual(uint256 fundId, address user) external view returns (uint256, uint256, uint256);
    function getUserData(uint256 fundId, address user) external view returns (uint256, uint256, uint256, uint256);
    function managers(uint256 fundId) external view returns(address);
    function fundWithdrawals(uint256 fundId) external view returns (uint256);
    function fundDeposits(uint256 fundId) external view returns (uint256);
    function fundTotalWithdrawals(uint256 fundId) external view returns (uint256);
    function hasUnprocessedWithdrawals() external view returns (bool);
    function getPendingExecutionFee(uint256 fundId, uint256 tradeTvl, uint256 gasPrice) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFees {

    struct FundFees {
        uint256 live;
        uint256 sf;
        uint256 pf;
        uint256 mf;
    }


    /**
    * Events
    */
    event NewFund(uint256 fundId, uint256 sf, uint256 pf, uint256 mf);

    event SfCharged(uint256 indexed fundId, uint256 amount);
    event PfCharged(uint256 indexed fundId, uint256 amount);
    event MfCharged(uint256 indexed fundId, uint256 amount);
    event EfCharged(uint256 indexed fundId, uint256 amount);

    event Withdrawal(address indexed user, address token, uint256 amount);
    event WithdrawalFund(uint256 indexed fundId, address destination, address token, uint256 amount);

    event ServiceFeesChanged(uint256 sf, uint256 pf, uint256 mf);
    /**
    * Public
    */

    /**
    * Auth
    */

    function newFund(uint256 fundId, uint256 sf, uint256 pf, uint256 mf) external;

    /**
    * View
    */
    function fees(uint256 fundId) external view returns(uint256 sf, uint256 pf, uint256 mf);
    function serviceFees() external view returns(uint256 sf, uint256 pf, uint256 mf);
    function gatheredFees(uint256 fundId) external view returns(uint256 live, uint256 sf, uint256 pf, uint256 mf);

    function gatherSf(uint256 fundId, uint256 pending, address token) external returns(uint256);

    function gatherPf(uint256 fundId, uint256 pending, address token) external;

    function gatherMf(uint256 fundId, uint256 pending, address token, address manager) external;

    function gatherEf(uint256 fundId, uint256 amount, address token) external;
    function gatherCf(uint256 fundId, address payer, uint256 amount, address token) external;
    function calculatePF(uint256 fundId, uint256 amount) external view returns (uint256);

    function withdraw(address user, uint256 amount) external;

    function withdrawFund(uint256 fundId, address destination, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IFees.sol";

interface IFundFactory {

    struct FundInfo {
        uint256 id;
        bool hwm;
        uint256 subscriptionFee;
        uint256 managementFee;
        uint256 performanceFee;
        uint256 investPeriod;
        uint256 indent;
        bytes whitelistMask;
        uint256 serviceMask;
    }

    /// On fund created
    event FundCreated(address indexed manager,
        uint256 id,
        bool hwm,
        uint256 sf,
        uint256 pf,
        uint256 mf,
        uint256 period,
        bytes whitelistMask,
        uint256 serviceMask
    );

    event FeesChanged(address newFees);
    event TriggerChanged(address newTrigger);

    function newFund(FundInfo calldata fundInfo) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IToken.sol";
import "./FundState.sol";

interface IInteraction {

    struct FundInfo {
        address trade;
        uint256 period;
        uint256 nextPeriod;
        IToken itoken;
        bool hwm;
        uint256 indent;
    }

    struct FundPendingTvlInfo {
        uint256 deposit;
        uint256 withdraw;
        uint256 pf;
        uint256 mustBePaid;
        uint256 totalFees;
        uint256 stakers;
        uint256 totalWithdrawals;
    }

    event NewFund(uint256 indexed fundId, address manager, address itoken);
    event NextPeriod(uint256 indexed fundId, uint256 nextPeriod);
    event Stake(uint256 indexed fundId, address user, uint256 depositAmount, uint256 tokenAmount, uint256 commissionPaid);
    event UnStake(uint256 indexed fundId, address user, uint256 amount, uint256 positionLeft);

    event FundStateChanged(uint256 indexed fundId, FundState state);

    // available values for investPeriod are
    // - 604800 (weekly)
    // - 2592000 (monthly)
    // - 7776000 (quarterly)
    function newFund(
        uint256 fundId,
        bool hwm,
        uint256 investPeriod,
        address manager,
        IToken itoken,
        address tradeContract,
        uint256 indent
    ) external;

    function drip(uint256 fundId, uint256 tradeTvl) external;

    function stake(uint256 fundId, uint256 amount) external returns (uint256);
    function unstake(uint256 fundId, uint256 amount) external;

    function show(uint256 fundId) external;
    function hide(uint256 fundId) external;
    // VIEWS

    function fundExist(uint256 fundId) external view returns(bool);

    function tokenForFund(uint256 fundId) external view returns (address);

    function stakers(uint256 fundId) external view returns (uint256);
    function estimatedWithdrawAmount(uint256 fundId, uint256 tradeTvl, uint256 amount) external view returns (uint256);
    function fundInfo(uint256 fundId) external view returns (address, uint256, uint256);
    function tokenRate(uint256 fundId, uint256 tradeTvl) external view returns (uint256);
    function hwmValue(uint256 fundId) external view returns (uint256);
    function userTVL(uint256 fundId, uint256 tradeTvl, address user) external view returns (uint256);
    function tokenSupply(uint256 fundId) external view returns (uint256);
    function userTokensAmount(uint256 fundId, address user) external view returns (uint256);
    function totalFees(uint256 fundId) external view returns (uint256);
    function pendingDepositAndWithdrawals(uint256 fundId, address user) external view returns (uint256, uint256, uint256);
    function pendingTvl(uint256[] calldata _funds, uint256[] calldata _tradeTvls, uint256 gasPrice) external view returns(
        FundPendingTvlInfo[] memory results
    );
    function cancelWithdraw(uint256 fundId) external;
    function cancelDeposit(uint256 fundId) external;

    function deposits(uint256 fundId) external view returns (uint256);
    function withdrawals(uint256 fundId) external view returns (uint256);
    function isDripEnabled(uint256 fundId) external view returns (bool);
}

// SPDX-License-Identifier: ISC
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import "./IFeeder.sol";
import "./IInteraction.sol";
import "./IDripOperator.sol";
import "./IFees.sol";
import "./IFeeder.sol";
import "./IWhitelist.sol";
import "./IUpgrader.sol";
import "./IFundFactory.sol";
import "./ITradeParamsUpdater.sol";
import "../integration/gmx/IGmxRouter.sol";
import "../integration/gmx/IPositionRouter.sol";
import "../integration/oracles/interfaces/IPriceFeed.sol";

pragma solidity ^0.8.0;

interface IRegistry {
    function triggerServer() external view returns (address);
    function usdt() external view returns (IERC20MetadataUpgradeable);
    function feeder() external view returns (IFeeder);
    function interaction() external view returns (IInteraction);
    function fees() external view returns (IFees);
    function tradeBeacon() external view returns (address);
    function dripOperator() external view returns (IDripOperator);
    function ethPriceFeed() external view returns (IPriceFeed);
    function whitelist() external view returns (IWhitelist);
    function tradeParamsUpdater() external view returns (ITradeParamsUpdater);
    function upgrader() external view returns (IUpgrader);
    function swapper() external view returns (address);
    function aavePoolDataProvider() external view returns (address);
    function aavePool() external view returns (address);
    function gmxRouter() external view returns (IGmxRouter);
    function gmxPositionRouter() external view returns (IPositionRouter);
    function fundFactory() external view returns (IFundFactory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IToken is IERC20 {

    function mint(address investor, uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;

    function holders() external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITradeParamsUpdater {
    function nearestUpdate(address _destination) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUpgradeable {
    function upgradeTo(address implementation) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IUpgradeable.sol";

interface IUpgrader {
    struct Upgrade {
        IUpgradeable destination;
        address implementation;
    }
    event UpgradeRequested(Upgrade[] _upgrades, uint256 _upgradePeriod);

    function requestUpgrade(Upgrade[] memory _upgrades) external;
    function upgrade() external;
    function cancelUpgrade() external;
    function nextUpgradeDate() external view returns (uint256);
    function setUpgradePeriod(uint256 _upgradePeriod) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWhitelist {
    event TokenAdded(address indexed token, uint256 index);
    event TokenRemoved(address indexed token, uint256 index);

    function tokenCount() external view returns (uint256);
    function getTokenIndex(address token) external view returns (uint256, bool);
    function addToken(address token) external;
    function removeToken(address token) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IFeeder.sol";
import "../interfaces/IUpgrader.sol";
import "../interfaces/IRegistry.sol";

// @address:REGISTRY
IRegistry constant registry = IRegistry(0x5517dB2A5C94B3ae95D3e2ec12a6EF86aD5db1a5);

contract Upgrader is IUpgrader, Ownable {
    uint256 public minUpgradePeriod;
    uint256 public upgradePeriod;
    uint256 public nextUpgradeDate;
    IFeeder public feeder;
    Upgrade[] public upgrades;

    constructor(uint256 _minUpgradePeriod, uint256 _upgradePeriod) {
        minUpgradePeriod = _minUpgradePeriod;
        upgradePeriod = _upgradePeriod;
    }

    function setUpgradePeriod(uint256 _upgradePeriod) external onlyOwner {
        require(_upgradePeriod >= minUpgradePeriod, "TU/UPS"); // upgrade period too short
        upgradePeriod = _upgradePeriod;
    }
 
    function requestUpgrade(Upgrade[] memory _upgrades) external onlyOwner {
        for (uint i = 0; i < _upgrades.length; i++) {
            require(_upgrades[i].implementation != address(0), "TU/II"); // invalid implementation
        }
        upgrades = _upgrades;
        nextUpgradeDate = block.timestamp + upgradePeriod;
        emit UpgradeRequested(_upgrades, upgradePeriod);
    }

    function upgrade() external onlyOwner {
        require(block.timestamp >= nextUpgradeDate, "TU/UPNE"); // upgrade period not expired
        require(!registry.feeder().hasUnprocessedWithdrawals(), "TU/UW"); // has unprocessed withdrawals
        for (uint i = 0; i < upgrades.length; i++) {
            upgrades[i].destination.upgradeTo(upgrades[i].implementation);
        }
        nextUpgradeDate = 0;
        delete upgrades;
    }

    function pendingUpgrades() public view returns (Upgrade[] memory) {
        return upgrades;
    }

    function cancelUpgrade() external onlyOwner {
        nextUpgradeDate = 0;
        delete upgrades;
    }
}