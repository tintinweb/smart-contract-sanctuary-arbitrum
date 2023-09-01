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

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// SPDX-License-Identifier: BUSL-1.1
// Last deployed from commit: de0a4e9ee653d2aade275c436805bb3217a8979d;
pragma solidity 0.8.17;

import "../../Pool.sol";


/**
 * @title BtcPool
 * @dev Contract allowing user to deposit to and borrow BTC.b from a dedicated user account
 */
contract BtcPool is Pool {
    function getMaxPoolUtilisationForBorrowing() override public view returns (uint256) {
        return 0.9e18;
    }

    function name() public virtual override pure returns(string memory _name){
        _name = "DeltaPrimeBitcoin";
    }

    function symbol() public virtual override pure returns(string memory _symbol){
        _symbol = "DPBTCb";
    }

    function decimals() public virtual override pure returns(uint8 decimals){
        decimals = 8;
    }
}

// SPDX-License-Identifier: BUSL-1.1
// Last deployed from commit: ;
pragma solidity 0.8.17;

/**
 * @title IBorrowersRegistry
 * Keeps a registry of created trading accounts to verify their borrowing rights
 */
interface IBorrowersRegistry {
    function canBorrow(address _account) external view returns (bool);

    function getLoanForOwner(address _owner) external view returns (address);

    function getOwnerOfLoan(address _loan) external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
// Last deployed from commit: c5c938a0524b45376dd482cd5c8fb83fa94c2fcc;
pragma solidity 0.8.17;

interface IIndex {

    function setRate(uint256 _rate) external;

    function updateUser(address user) external;

    function getIndex() external view returns (uint256);

    function getIndexedValue(uint256 value, address user) external view returns (uint256);

}

// SPDX-License-Identifier: BUSL-1.1
// Last deployed from commit: ;
pragma solidity ^0.8.17;

interface IPoolRewarder {

    function stakeFor(uint _amount, address _stakeFor) external;

    function withdrawFor(uint _amount, address _unstakeFor) external returns (uint);

    function getRewardsFor(address _user) external;

    function earned(address _account) external view returns (uint);

    function balanceOf(address _account) external view returns (uint);
}

// SPDX-License-Identifier: BUSL-1.1
// Last deployed from commit: ;
pragma solidity 0.8.17;

/**
 * @title IRatesCalculator
 * @dev Interface defining base method for contracts implementing interest rates calculation.
 * The calculated value could be based on the relation between funds borrowed and deposited.
 */
interface IRatesCalculator {
    function calculateBorrowingRate(uint256 totalLoans, uint256 totalDeposits) external view returns (uint256);

    function calculateDepositRate(uint256 totalLoans, uint256 totalDeposits) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
// Last deployed from commit: de0a4e9ee653d2aade275c436805bb3217a8979d;
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/IIndex.sol";
import "./interfaces/IRatesCalculator.sol";
import "./interfaces/IBorrowersRegistry.sol";
import "./interfaces/IPoolRewarder.sol";
import "./VestingDistributor.sol";


/**
 * @title Pool
 * @dev Contract allowing user to deposit to and borrow from a dedicated user account
 * Depositors are rewarded with the interest rates collected from borrowers.
 * The interest rates calculation is delegated to an external calculator contract.
 */
contract Pool is OwnableUpgradeable, ReentrancyGuardUpgradeable, IERC20 {
    using TransferHelper for address payable;

    uint256 public totalSupplyCap;

    mapping(address => mapping(address => uint256)) private _allowed;
    mapping(address => uint256) internal _deposited;

    mapping(address => uint256) public borrowed;

    IRatesCalculator public ratesCalculator;
    IBorrowersRegistry public borrowersRegistry;
    IPoolRewarder public poolRewarder;

    IIndex public depositIndex;
    IIndex public borrowIndex;

    address payable public tokenAddress;

    VestingDistributor public vestingDistributor;

    uint8 internal _decimals;

    modifier onlyWhitelistedAccounts {
        if(
            msg.sender == 0x0E5Bad4108a6A5a8b06820f98026a7f3A77466b2 ||
            msg.sender == 0x2fFA7E9624B923fA811d9B9995Aa34b715Db1945 ||
            msg.sender == 0x0d7137feA34BC97819f05544Ec7DE5c98617989C ||
            msg.sender == 0xC6ba6BB819f1Be84EFeB2E3f2697AD9818151e5D ||
            msg.sender == 0x14f69F9C351b798dF31fC53E33c09dD29bFAb547 ||
            msg.sender == 0x5C23Bd1BD272D22766eB3708B8f874CB93B75248 ||
            msg.sender == 0x000000F406CA147030BE7069149e4a7423E3A264 ||
            msg.sender == 0x5D80a1c0a5084163F1D2620c1B1F43209cd4dB12 ||
            msg.sender == 0x6C21A841d6f029243AF87EF01f6772F05832144b

        ){
            _;
        } else {
            revert("Not whitelisted");
        }
    }


    function initialize(IRatesCalculator ratesCalculator_, IBorrowersRegistry borrowersRegistry_, IIndex depositIndex_, IIndex borrowIndex_, address payable tokenAddress_, IPoolRewarder poolRewarder_, uint256 _totalSupplyCap) public initializer {
        require(AddressUpgradeable.isContract(address(ratesCalculator_))
            && AddressUpgradeable.isContract(address(borrowersRegistry_))
            && AddressUpgradeable.isContract(address(depositIndex_))
            && AddressUpgradeable.isContract(address(borrowIndex_))
            && (AddressUpgradeable.isContract(address(poolRewarder_)) || address(poolRewarder_) == address(0)), "Wrong init arguments");

        borrowersRegistry = borrowersRegistry_;
        ratesCalculator = ratesCalculator_;
        depositIndex = depositIndex_;
        borrowIndex = borrowIndex_;
        poolRewarder = poolRewarder_;
        tokenAddress = tokenAddress_;
        totalSupplyCap = _totalSupplyCap;

        _decimals = IERC20Metadata(tokenAddress_).decimals();

        __Ownable_init();
        __ReentrancyGuard_init();
        _updateRates();
    }

    /* ========== SETTERS ========== */

    /**
     * Sets new totalSupplyCap limiting how much in total can be deposited to the Pool.
     * Only the owner of the Contract can execute this function.
     * @dev _newTotalSupplyCap new deposit cap
    **/
    function setTotalSupplyCap(uint256 _newTotalSupplyCap) external onlyOwner {
        totalSupplyCap = _newTotalSupplyCap;
    }

    /**
     * Sets the new Pool Rewarder.
     * The IPoolRewarder that distributes additional token rewards to people having a stake in this pool proportionally to their stake and time of participance.
     * Only the owner of the Contract can execute this function.
     * @dev _poolRewarder the address of PoolRewarder
    **/
    function setPoolRewarder(IPoolRewarder _poolRewarder) external onlyOwner {
        if(!AddressUpgradeable.isContract(address(_poolRewarder)) && address(_poolRewarder) != address(0)) revert NotAContract(address(poolRewarder));
        poolRewarder = _poolRewarder;

        emit PoolRewarderChanged(address(_poolRewarder), block.timestamp);
    }

    /**
     * Sets the new rate calculator.
     * The calculator is an external contract that contains the logic for calculating deposit and borrowing rates.
     * Only the owner of the Contract can execute this function.
     * @dev ratesCalculator the address of rates calculator
     **/
    function setRatesCalculator(IRatesCalculator ratesCalculator_) external onlyOwner {
        // setting address(0) ratesCalculator_ freezes the pool
        if(!AddressUpgradeable.isContract(address(ratesCalculator_)) && address(ratesCalculator_) != address(0)) revert NotAContract(address(ratesCalculator_));
        ratesCalculator = ratesCalculator_;
        if (address(ratesCalculator_) != address(0)) {
            _updateRates();
        }

        emit RatesCalculatorChanged(address(ratesCalculator_), block.timestamp);
    }

    /**
     * Sets the new borrowers registry contract.
     * The borrowers registry decides if an account can borrow funds.
     * Only the owner of the Contract can execute this function.
     * @dev borrowersRegistry the address of borrowers registry
     **/
    function setBorrowersRegistry(IBorrowersRegistry borrowersRegistry_) external onlyOwner {
        if(!AddressUpgradeable.isContract(address(borrowersRegistry_))) revert NotAContract(address(borrowersRegistry_));

        borrowersRegistry = borrowersRegistry_;
        emit BorrowersRegistryChanged(address(borrowersRegistry_), block.timestamp);
    }

    /**
     * Sets the new Pool Rewarder.
     * The IPoolRewarder that distributes additional token rewards to people having a stake in this pool proportionally to their stake and time of participance.
     * Only the owner of the Contract can execute this function.
     * @dev _poolRewarder the address of PoolRewarder
    **/
    function setVestingDistributor(address _distributor) external onlyOwner {
        if(!AddressUpgradeable.isContract(_distributor) && _distributor != address(0)) revert NotAContract(_distributor);
        vestingDistributor = VestingDistributor(_distributor);

        emit VestingDistributorChanged(_distributor, block.timestamp);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        if(recipient == address(0)) revert TransferToZeroAddress();

        if(recipient == address(this)) revert TransferToPoolAddress();

        address account = msg.sender;
        _accumulateDepositInterest(account);

        (uint256 lockedAmount, uint256 transferrableAmount) = _getAmounts(account);
        if(amount > transferrableAmount) revert TransferAmountExceedsBalance(amount, transferrableAmount);

        _updateWithdrawn(account, amount, lockedAmount);

        // (this is verified in "require" above)
        unchecked {
            _deposited[account] -= amount;
        }

        _accumulateDepositInterest(recipient);
        _deposited[recipient] += amount;

        // Handle rewards
        if(address(poolRewarder) != address(0) && amount != 0){
            uint256 unstaked = poolRewarder.withdrawFor(amount, account);
            if(unstaked > 0) {
                poolRewarder.stakeFor(unstaked, recipient);
            }
        }

        emit Transfer(account, recipient, amount);

        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowed[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        if(spender == address(0)) revert SpenderZeroAddress();
        uint256 newAllowance = _allowed[msg.sender][spender] + addedValue;
        _allowed[msg.sender][spender] = newAllowance;

        emit Approval(msg.sender, spender, newAllowance);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        if(spender == address(0)) revert SpenderZeroAddress();
        uint256 currentAllowance = _allowed[msg.sender][spender];
        if(currentAllowance < subtractedValue) revert InsufficientAllowance(subtractedValue, currentAllowance);

        uint256 newAllowance = currentAllowance - subtractedValue;
        _allowed[msg.sender][spender] = newAllowance;

        emit Approval(msg.sender, spender, newAllowance);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        if(spender == address(0)) revert SpenderZeroAddress();
        _allowed[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowed[sender][msg.sender] < amount) revert InsufficientAllowance(amount, _allowed[sender][msg.sender]);

        if(recipient == address(0)) revert TransferToZeroAddress();

        if(recipient == address(this)) revert TransferToPoolAddress();

        _accumulateDepositInterest(sender);

        (uint256 lockedAmount, uint256 transferrableAmount) = _getAmounts(sender);
        if(amount > transferrableAmount) revert TransferAmountExceedsBalance(amount, transferrableAmount);

        _updateWithdrawn(sender, amount, lockedAmount);

        _deposited[sender] -= amount;
        _allowed[sender][msg.sender] -= amount;

        _accumulateDepositInterest(recipient);
        _deposited[recipient] += amount;

        // Handle rewards
        if(address(poolRewarder) != address(0) && amount != 0){
            uint256 unstaked = poolRewarder.withdrawFor(amount, sender);
            if(unstaked > 0) {
                poolRewarder.stakeFor(unstaked, recipient);
            }
        }

        emit Transfer(sender, recipient, amount);

        return true;
    }


    /**
     * Deposits the amount
     * It updates user deposited balance, total deposited and rates
     **/
    function deposit(uint256 _amount) public virtual onlyWhitelistedAccounts{
        depositOnBehalf(_amount, msg.sender);
    }

    /**
     * Deposits the amount on behalf of `_of` user.
     * It updates `_of` user deposited balance, total deposited and rates
     **/
    function depositOnBehalf(uint256 _amount, address _of) public virtual nonReentrant onlyWhitelistedAccounts {
        if(_amount == 0) revert ZeroDepositAmount();
        require(_of != address(0), "Address zero");
        require(_of != address(this), "Cannot deposit on behalf of pool");

        _amount = Math.min(_amount, IERC20(tokenAddress).balanceOf(msg.sender));

        _accumulateDepositInterest(_of);

        if(totalSupplyCap != 0){
            if(_deposited[address(this)] + _amount > totalSupplyCap) revert TotalSupplyCapBreached();
        }

        _transferToPool(msg.sender, _amount);

        _mint(_of, _amount);
        _deposited[address(this)] += _amount;
        _updateRates();

        if (address(poolRewarder) != address(0)) {
            poolRewarder.stakeFor(_amount, _of);
        }

        emit DepositOnBehalfOf(msg.sender, _of, _amount, block.timestamp);
    }

    function _transferToPool(address from, uint256 amount) internal virtual {
        tokenAddress.safeTransferFrom(from, address(this), amount);
    }

    function _transferFromPool(address to, uint256 amount) internal virtual {
        tokenAddress.safeTransfer(to, amount);
    }

    /**
     * Withdraws selected amount from the user deposits
     * @dev _amount the amount to be withdrawn
     **/
    function withdraw(uint256 _amount) external nonReentrant onlyWhitelistedAccounts {
        if(_amount > IERC20(tokenAddress).balanceOf(address(this))) revert InsufficientPoolFunds();

        _accumulateDepositInterest(msg.sender);

        if(_amount > _deposited[address(this)]) revert BurnAmountExceedsBalance();
        // verified in "require" above
        unchecked {
            _deposited[address(this)] -= _amount;
        }
        _burn(msg.sender, _amount);

        _updateRates();

        _transferFromPool(msg.sender, _amount);

        if (address(poolRewarder) != address(0)) {
            poolRewarder.withdrawFor(_amount, msg.sender);
        }

        emit Withdrawal(msg.sender, _amount, block.timestamp);
    }

    /**
     * Borrows the specified amount
     * It updates user borrowed balance, total borrowed amount and rates
     * @dev _amount the amount to be borrowed
     * @dev It is only meant to be used by a SmartLoanDiamondProxy
     **/
    function borrow(uint256 _amount) public virtual canBorrow nonReentrant {
        if (_amount > IERC20(tokenAddress).balanceOf(address(this))) revert InsufficientPoolFunds();

        _accumulateBorrowingInterest(msg.sender);

        borrowed[msg.sender] += _amount;
        borrowed[address(this)] += _amount;

        _transferFromPool(msg.sender, _amount);

        _updateRates();

        emit Borrowing(msg.sender, _amount, block.timestamp);
    }

    /**
     * Repays the amount
     * It updates user borrowed balance, total borrowed amount and rates
     * @dev It is only meant to be used by a SmartLoanDiamondProxy
     **/
    function repay(uint256 amount) external nonReentrant {
        _accumulateBorrowingInterest(msg.sender);

        if(amount > borrowed[msg.sender]) revert RepayingMoreThanWasBorrowed();
        _transferToPool(msg.sender, amount);

        borrowed[msg.sender] -= amount;
        borrowed[address(this)] -= amount;

        _updateRates();

        emit Repayment(msg.sender, amount, block.timestamp);
    }

    /* =========


    /**
     * Returns the current borrowed amount for the given user
     * The value includes the interest rates owned at the current moment
     * @dev _user the address of queried borrower
    **/
    function getBorrowed(address _user) public view returns (uint256) {
        return borrowIndex.getIndexedValue(borrowed[_user], _user);
    }

    function name() public virtual pure returns(string memory _name){
        _name = "";
    }

    function symbol() public virtual pure returns(string memory _symbol){
        _symbol = "";
    }

    function decimals() public virtual view returns(uint8){
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return balanceOf(address(this));
    }

    function totalBorrowed() public view returns (uint256) {
        return getBorrowed(address(this));
    }


    // Calls the IPoolRewarder.getRewardsFor() that sends pending rewards to msg.sender
    function getRewards() external {
        poolRewarder.getRewardsFor(msg.sender);
    }

    // Returns number of pending rewards for msg.sender
    function checkRewards() external view returns (uint256) {
        return poolRewarder.earned(msg.sender);
    }

    // Returns max. acceptable pool utilisation after borrow action
    function getMaxPoolUtilisationForBorrowing() virtual public view returns (uint256) {
        return 0.9e18;
    }

    /**
     * Returns the current deposited amount for the given user
     * The value includes the interest rates earned at the current moment
     * @dev _user the address of queried depositor
     **/
    function balanceOf(address user) public view override returns (uint256) {
        return depositIndex.getIndexedValue(_deposited[user], user);
    }

    /**
     * Returns the current interest rate for deposits
     **/
    function getDepositRate() public view returns (uint256) {
        return ratesCalculator.calculateDepositRate(totalBorrowed(), totalSupply());
    }

    /**
     * Returns the current interest rate for borrowings
     **/
    function getBorrowingRate() public view returns (uint256) {
        return ratesCalculator.calculateBorrowingRate(totalBorrowed(), totalSupply());
    }

    /**
     * Returns full pool status
     */
    function getFullPoolStatus() public view returns (uint256[5] memory) {
        return [
            totalSupply(),
            getDepositRate(),
            getBorrowingRate(),
            totalBorrowed(),
            getMaxPoolUtilisationForBorrowing()
        ];
    }

    /**
     * Recovers the surplus funds resultant from difference between deposit and borrowing rates
     **/
    function recoverSurplus(uint256 amount, address account) public onlyOwner nonReentrant {
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        uint256 surplus = balance + totalBorrowed() - totalSupply();

        if(amount > balance) revert InsufficientPoolFunds();
        if(surplus < amount) revert InsufficientSurplus();

        _transferFromPool(account, amount);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _mint(address to, uint256 amount) internal {
        if(to == address(0)) revert MintToAddressZero();

        _deposited[to] += amount;

        emit Transfer(address(0), to, amount);
    }

    function _burn(address account, uint256 amount) internal {
        if(amount > _deposited[account]) revert BurnAmountExceedsBalance();
        (uint256 lockedAmount, uint256 transferrableAmount) = _getAmounts(account);
        if(amount > transferrableAmount) revert BurnAmountExceedsAvailableForUser();

        _updateWithdrawn(account, amount, lockedAmount);

        // verified in "require" above
        unchecked {
            _deposited[account] -= amount;
        }

        emit Transfer(account, address(0), amount);
    }

    function _getAmounts(address account) internal view returns (uint256 lockedAmount, uint256 transferrableAmount) {
        if (address(vestingDistributor) != address(0)) {
            lockedAmount = vestingDistributor.locked(account);
            transferrableAmount = _deposited[account] - (lockedAmount - vestingDistributor.availableToWithdraw(account));
        } else {
            transferrableAmount = _deposited[account];
        }
    }

    function _updateWithdrawn(address account, uint256 amount, uint256 lockedAmount) internal {
        uint256 availableUnvested = _deposited[account] - lockedAmount;
        if (amount > availableUnvested && address(vestingDistributor) != address(0)) {
            vestingDistributor.updateWithdrawn(account, amount - availableUnvested);
        }
    }

    function _updateRates() internal {
        uint256 _totalBorrowed = totalBorrowed();
        uint256 _totalSupply = totalSupply();
        if(address(ratesCalculator) == address(0)) revert PoolFrozen();
        depositIndex.setRate(ratesCalculator.calculateDepositRate(_totalBorrowed, _totalSupply));
        borrowIndex.setRate(ratesCalculator.calculateBorrowingRate(_totalBorrowed, _totalSupply));
    }

    function _accumulateDepositInterest(address user) internal {
        uint256 interest = balanceOf(user) - _deposited[user];

        _mint(user, interest);
        _deposited[address(this)] = balanceOf(address(this));

        emit InterestCollected(user, interest, block.timestamp);

        depositIndex.updateUser(user);
        depositIndex.updateUser(address(this));
    }

    function _accumulateBorrowingInterest(address user) internal {
        borrowed[user] = getBorrowed(user);
        borrowed[address(this)] = getBorrowed(address(this));

        borrowIndex.updateUser(user);
        borrowIndex.updateUser(address(this));
    }

    /* ========== OVERRIDDEN FUNCTIONS ========== */

    function renounceOwnership() public virtual override {}

    /* ========== MODIFIERS ========== */

    modifier canBorrow() {
        if(address(borrowersRegistry) == address(0)) revert BorrowersRegistryNotConfigured();
        if(!borrowersRegistry.canBorrow(msg.sender)) revert NotAuthorizedToBorrow();
        if(totalSupply() == 0) revert InsufficientPoolFunds();
        _;
        if((totalBorrowed() * 1e18) / totalSupply() > getMaxPoolUtilisationForBorrowing()) revert MaxPoolUtilisationBreached();
    }

    /* ========== EVENTS ========== */

    /**
     * @dev emitted after the user deposits funds
     * @param user the address performing the deposit
     * @param value the amount deposited
     * @param timestamp of the deposit
     **/
    event Deposit(address indexed user, uint256 value, uint256 timestamp);

    /**
     * @dev emitted after the user deposits funds on behalf of other user
     * @param user the address performing the deposit
     * @param _of the address on behalf of which the deposit is being performed
     * @param value the amount deposited
     * @param timestamp of the deposit
     **/
    event DepositOnBehalfOf(address indexed user, address indexed _of, uint256 value, uint256 timestamp);

    /**
     * @dev emitted after the user withdraws funds
     * @param user the address performing the withdrawal
     * @param value the amount withdrawn
     * @param timestamp of the withdrawal
     **/
    event Withdrawal(address indexed user, uint256 value, uint256 timestamp);

    /**
     * @dev emitted after the user borrows funds
     * @param user the address that borrows
     * @param value the amount borrowed
     * @param timestamp time of the borrowing
     **/
    event Borrowing(address indexed user, uint256 value, uint256 timestamp);

    /**
     * @dev emitted after the user repays debt
     * @param user the address that repays debt
     * @param value the amount repaid
     * @param timestamp of the repayment
     **/
    event Repayment(address indexed user, uint256 value, uint256 timestamp);

    /**
     * @dev emitted after accumulating deposit interest
     * @param user the address that the deposit interest is accumulated for
     * @param value the amount that interest is calculated from
     * @param timestamp of the interest accumulation
     **/
    event InterestCollected(address indexed user, uint256 value, uint256 timestamp);

    /**
    * @dev emitted after changing borrowers registry
    * @param registry an address of the newly set borrowers registry
    * @param timestamp of the borrowers registry change
    **/
    event BorrowersRegistryChanged(address indexed registry, uint256 timestamp);

    /**
    * @dev emitted after changing rates calculator
    * @param calculator an address of the newly set rates calculator
    * @param timestamp of the borrowers registry change
    **/
    event RatesCalculatorChanged(address indexed calculator, uint256 timestamp);

    /**
    * @dev emitted after changing pool rewarder
    * @param poolRewarder an address of the newly set pool rewarder
    * @param timestamp of the pool rewarder change
    **/
    event PoolRewarderChanged(address indexed poolRewarder, uint256 timestamp);

    /**
    * @dev emitted after changing vesting distributor
    * @param distributor an address of the newly set distributor
    * @param timestamp of the distributor change
    **/
    event VestingDistributorChanged(address indexed distributor, uint256 timestamp);

    /* ========== ERRORS ========== */

    // Only authorized accounts may borrow
    error NotAuthorizedToBorrow();

    // Borrowers registry is not configured
    error BorrowersRegistryNotConfigured();

    // Pool is frozen
    error PoolFrozen();

    // Not enough funds in the pool.
    error InsufficientPoolFunds();

    // Insufficient pool surplus to cover the requested recover amount
    error InsufficientSurplus();

    // Address (`target`) must be a contract
    // @param target target address that must be a contract
    error NotAContract(address target);

    //  ERC20: Spender cannot be a zero address
    error SpenderZeroAddress();

    //  ERC20: cannot transfer to the zero address
    error TransferToZeroAddress();

    //  ERC20: cannot transfer to the pool address
    error TransferToPoolAddress();

    //  ERC20: transfer amount (`amount`) exceeds balance (`balance`)
    /// @param amount transfer amount
    /// @param balance available balance
    error TransferAmountExceedsBalance(uint256 amount, uint256 balance);

    //  ERC20: requested transfer amount (`requested`) exceeds current allowance (`allowance`)
    /// @param requested requested transfer amount
    /// @param allowance current allowance
    error InsufficientAllowance(uint256 requested, uint256 allowance);

    //  This deposit operation would result in a breach of the totalSupplyCap
    error TotalSupplyCapBreached();

    // The deposit amount must be > 0
    error ZeroDepositAmount();

    // ERC20: cannot mint to the zero address
    error MintToAddressZero();

    // ERC20: burn amount exceeds current pool indexed balance
    error BurnAmountExceedsBalance();

    // ERC20: burn amount exceeds current amount available (including vesting)
    error BurnAmountExceedsAvailableForUser();

    // Trying to repay more than was borrowed
    error RepayingMoreThanWasBorrowed();

    // getMaxPoolUtilisationForBorrowing was breached
    error MaxPoolUtilisationBreached();
}

// SPDX-License-Identifier: BUSL-1.1
// Last deployed from commit: 9f1e1bba11316303810f35a4440e20bc5ad0ef86;
pragma solidity 0.8.17;

import "./Pool.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @title VestingDistributor
 * @dev Contract distributing pool's spread among vesting participants.
 */
contract VestingDistributor {

    Pool pool;
    IERC20Metadata poolToken;
    address keeper;
    address pendingKeeper;

    uint256 totalLockedMultiplied;
    address[] public participants;
    mapping(address => uint256) public locked;
    mapping(address => uint256) public withdrawn;
    mapping(address => uint256) public unvestingTime;
    mapping(address => uint256) public unlockTimestamp;
    mapping(address => uint256) public multiplier;
    mapping(uint256 => uint256) rewardAmount;
    mapping(uint256 => mapping(address => bool)) rewardDistributed;
    mapping(uint256 => uint256) numRewardDistributed;

    uint256 lastUpdated;
    uint256 updateInterval = 6 hours;

    uint256 public constant ONE_DAY = 24 * 3600; // 24 hours * 3600 seconds
    uint256 public constant MIN_VESTING_TIME = ONE_DAY; // 1 day * 24 hours * 3600 seconds
    uint256 public constant MAX_VESTING_TIME = 30 * ONE_DAY; // 30 days * 24 hours * 3600 seconds

    modifier onlyPool() {
        require(msg.sender == address(pool), "Unauthorized: onlyPool");
        _;
    }

    modifier onlyKeeper() {
        require(msg.sender == keeper, "Unauthorized: onlyKeeper");
        _;
    }

    modifier onlyPendingKeeper() {
        require(msg.sender == pendingKeeper, "Unauthorized: onlyPendingKeeper");
        _;
    }

    constructor(address poolAddress, address keeperAddress) {
        pool = Pool(poolAddress);
        poolToken = IERC20Metadata(pool.tokenAddress());
        keeper = keeperAddress;
        lastUpdated = block.timestamp;
    }

    function transferKeeper(address keeperAddress) external onlyKeeper {
        pendingKeeper = keeperAddress;
    }

    function acceptKeeper() external onlyPendingKeeper {
        keeper = pendingKeeper;
        pendingKeeper = address(0);
    }

    /**
     * Add vesting participant (msg.sender)
     **/
    function startVesting(uint256 amount, uint256 time) public {
        if (time < MIN_VESTING_TIME || time > MAX_VESTING_TIME) revert InvalidVestingTime();
        if (pool.balanceOf(msg.sender) < amount) revert InsufficientPoolBalance();
        if (locked[msg.sender] > 0 || unvestingTime[msg.sender] > 0) revert AlreadyLocked();

        participants.push(msg.sender);
        locked[msg.sender] = amount;
        unvestingTime[msg.sender] = time;
        multiplier[msg.sender] = getMultiplier(time);

        totalLockedMultiplied += amount * multiplier[msg.sender] / 1e18;
    }

    /**
     * Increase vesting of msg.sender
     **/
    function increaseVesting(uint256 amount) public {
        if (locked[msg.sender] == 0 || unvestingTime[msg.sender] == 0) revert UserNotLocked();
        if (pool.balanceOf(msg.sender) < locked[msg.sender] + amount) revert InsufficientPoolBalance();
        if (unlockTimestamp[msg.sender] > 0) revert TooLate();

        locked[msg.sender] += amount;

        totalLockedMultiplied += amount * multiplier[msg.sender] / 1e18;
    }

    /**
     * Unlock funds - start of unvesting
     **/
    function unlock() public {
        if (locked[msg.sender] == 0 || unvestingTime[msg.sender] == 0) revert UserNotLocked();

        unlockTimestamp[msg.sender] = block.timestamp;
    }

    /**
     * Check how much user can withdraw
     **/
    function availableToWithdraw(address account) public view returns (uint256) {
        if (locked[account] == 0 || unvestingTime[account] == 0) revert UserNotLocked();
        if (unlockTimestamp[account] == 0) revert UserLocked();

        uint256 timeFromUnlock = block.timestamp - unlockTimestamp[account];
        if (timeFromUnlock > unvestingTime[account]) timeFromUnlock = unvestingTime[account];
        uint256 initialUnlock = ONE_DAY * locked[account] / (unvestingTime[account] + ONE_DAY); // 1D / vesting days * locked amount

        return initialUnlock + timeFromUnlock * (locked[account] - initialUnlock) / unvestingTime[account];
    }

    /**
     * Gets pool's spread and distributes among vesting participants.
     * @dev _totalLoans total value of loans
     * @dev _totalDeposits total value of deposits
     **/
    //TODO: run periodically by bots
    function distributeRewards(uint256 fromIndex, uint256 toIndex) public onlyKeeper {
        if (block.timestamp < lastUpdated + updateInterval) revert DistributeTooEarly();

        (fromIndex, toIndex) = fromIndex < toIndex ? (fromIndex, toIndex) : (toIndex, fromIndex);
        toIndex = toIndex < participants.length ? toIndex : participants.length - 1;

        if (rewardAmount[lastUpdated] == 0) {
            rewardAmount[lastUpdated] = pool.balanceOf(address(this));
        }
        uint256 rewards = rewardAmount[lastUpdated];

        for (uint256 i = fromIndex; i <= toIndex; i++) {
            address participant = participants[i];
            if (rewardDistributed[lastUpdated][participant]) {
                continue;
            }

            //TODO: right now we distribute rewards even when someone start withdrawing. The rewards should depend on the amount which is still locked.
            uint256 participantReward = rewards * (locked[participant] - withdrawn[participant]) * multiplier[participant] / 1e18 / totalLockedMultiplied;

            pool.transfer(participant, participantReward);

            rewardDistributed[lastUpdated][participant] = true;
            ++numRewardDistributed[lastUpdated];
            if (numRewardDistributed[lastUpdated] == participants.length) {
                lastUpdated = block.timestamp;
            }
        }
    }

    //TODO: run periodically by bots
    function updateParticipants(uint256 fromIndex, uint256 toIndex) public onlyKeeper {
        (fromIndex, toIndex) = fromIndex < toIndex ? (fromIndex, toIndex) : (toIndex, fromIndex);
        toIndex = toIndex < participants.length ? toIndex : participants.length - 1;
        for (uint256 i = fromIndex; i <= toIndex;) {
            address participant = participants[i];
            if (unlockTimestamp[participant] > 0 && (block.timestamp - unlockTimestamp[participant]) > unvestingTime[participant]) {
                totalLockedMultiplied -= (locked[participant] - withdrawn[participant]) * multiplier[participant] / 1e18;

                unvestingTime[participant] = 0;
                locked[participant] = 0;
                unlockTimestamp[participant] = 0;
                withdrawn[participant] = 0;
                multiplier[participant] = 0;

                participants[i] = participants[participants.length - 1];
                participants.pop();
                --toIndex;
            } else {
                ++i;
            }
        }
    }

    function updateWithdrawn(address account, uint256 amount) public onlyPool {
        withdrawn[account] += amount;
        if (withdrawn[account] > locked[account]) {
            revert WithdrawMoreThanLocked();
        }
        totalLockedMultiplied -= amount * multiplier[account] / 1e18;
    }

    function getMultiplier(uint256 time) public pure returns (uint256){
        if (time >= 30 * ONE_DAY) return 2e18; // min. 30 days
        if (time >= 29 * ONE_DAY) return 1.99e18; // min. 29 days
        if (time >= 28 * ONE_DAY) return 1.98e18; // min. 28 days
        if (time >= 27 * ONE_DAY) return 1.97e18; // min. 27 days
        if (time >= 26 * ONE_DAY) return 1.96e18; // min. 26 days
        if (time >= 25 * ONE_DAY) return 1.948e18; // min. 25 days
        if (time >= 24 * ONE_DAY) return 1.936e18; // min. 24 days
        if (time >= 23 * ONE_DAY) return 1.924e18; // min. 23 days
        if (time >= 22 * ONE_DAY) return 1.912e18; // min. 22 days
        if (time >= 21 * ONE_DAY) return 1.9e18; // min. 21 days
        if (time >= 20 * ONE_DAY) return 1.885e18; // min. 20 days
        if (time >= 19 * ONE_DAY) return 1.871e18; // min. 19 days
        if (time >= 18 * ONE_DAY) return 1.856e18; // min. 18 days
        if (time >= 17 * ONE_DAY) return 1.841e18; // min. 17 days
        if (time >= 16 * ONE_DAY) return 1.824e18; // min. 16 days
        if (time >= 15 * ONE_DAY) return 1.806e18; // min. 15 days
        if (time >= 14 * ONE_DAY) return 1.788e18; // min. 14 days
        if (time >= 13 * ONE_DAY) return 1.768e18; // min. 13 days
        if (time >= 12 * ONE_DAY) return 1.746e18; // min. 12 days
        if (time >= 11 * ONE_DAY) return 1.723e18; // min. 11 days
        if (time >= 10 * ONE_DAY) return 1.698e18; // min. 10 days
        if (time >= 9 * ONE_DAY) return 1.67e18; // min. 9 days
        if (time >= 8 * ONE_DAY) return 1.64e18; // min. 8 days
        if (time >= 7 * ONE_DAY) return 1.605e18; // min. 7 days
        if (time >= 6 * ONE_DAY) return 1.566e18; // min. 6 days
        if (time >= 5 * ONE_DAY) return 1.521e18; // min. 5 days
        if (time >= 4 * ONE_DAY) return 1.468e18; // min. 4 days
        if (time >= 3 * ONE_DAY) return 1.4e18; // min. 3 days
        if (time >= 2 * ONE_DAY) return 1.32e18; // min. 2 days
        if (time >= 1 * ONE_DAY) return 1.2e18; // min. 1 day

        return 1;
    }


    // Trying to distribute before the update interval has been reached
    error DistributeTooEarly();

    // Already participates in vesting
    error AlreadyLocked();

    // Vesting time is out of range
    error InvalidVestingTime();

    // Insufficient user balance of pool's tokens
    error InsufficientPoolBalance();

    // User not locked
    error UserNotLocked();

    // User funds are locked
    error UserLocked();

    // Too late
    error TooLate();

    // Withdraw amount is more than locked
    error WithdrawMoreThanLocked();
}