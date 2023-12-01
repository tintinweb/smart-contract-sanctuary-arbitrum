// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// This should be owned by the microservice that is paying for gas.
interface IAxelarGasService {
    error NothingReceived();
    error InvalidAddress();
    error NotCollector();
    error InvalidAmounts();

    event GasPaidForContractCall(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event GasPaidForContractCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasPaidForContractCall(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasPaidForContractCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event GasPaidForExpressCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasPaidForExpressCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event GasAdded(
        bytes32 indexed txHash,
        uint256 indexed logIndex,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasAdded(bytes32 indexed txHash, uint256 indexed logIndex, uint256 gasFeeAmount, address refundAddress);

    event ExpressGasAdded(
        bytes32 indexed txHash,
        uint256 indexed logIndex,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeExpressGasAdded(
        bytes32 indexed txHash,
        uint256 indexed logIndex,
        uint256 gasFeeAmount,
        address refundAddress
    );

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payGasForContractCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payGasForContractCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payNativeGasForContractCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundAddress
    ) external payable;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payNativeGasForContractCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address refundAddress
    ) external payable;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payGasForExpressCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payNativeGasForExpressCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address refundAddress
    ) external payable;

    function addGas(
        bytes32 txHash,
        uint256 txIndex,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    function addNativeGas(
        bytes32 txHash,
        uint256 logIndex,
        address refundAddress
    ) external payable;

    function addExpressGas(
        bytes32 txHash,
        uint256 txIndex,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    function addNativeExpressGas(
        bytes32 txHash,
        uint256 logIndex,
        address refundAddress
    ) external payable;

    function collectFees(
        address payable receiver,
        address[] calldata tokens,
        uint256[] calldata amounts
    ) external;

    function refund(
        address payable receiver,
        address token,
        uint256 amount
    ) external;

    function gasCollector() external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAxelarGateway {
    /**********\
    |* Errors *|
    \**********/

    error NotSelf();
    error NotProxy();
    error InvalidCodeHash();
    error SetupFailed();
    error InvalidAuthModule();
    error InvalidTokenDeployer();
    error InvalidAmount();
    error InvalidChainId();
    error InvalidCommands();
    error TokenDoesNotExist(string symbol);
    error TokenAlreadyExists(string symbol);
    error TokenDeployFailed(string symbol);
    error TokenContractDoesNotExist(address token);
    error BurnFailed(string symbol);
    error MintFailed(string symbol);
    error InvalidSetMintLimitsParams();
    error ExceedMintLimit(string symbol);

    /**********\
    |* Events *|
    \**********/

    event TokenSent(
        address indexed sender,
        string destinationChain,
        string destinationAddress,
        string symbol,
        uint256 amount
    );

    event ContractCall(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload
    );

    event ContractCallWithToken(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload,
        string symbol,
        uint256 amount
    );

    event Executed(bytes32 indexed commandId);

    event TokenDeployed(string symbol, address tokenAddresses);

    event ContractCallApproved(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event ContractCallApprovedWithMint(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event TokenMintLimitUpdated(string symbol, uint256 limit);

    event OperatorshipTransferred(bytes newOperatorsData);

    event Upgraded(address indexed implementation);

    /********************\
    |* Public Functions *|
    \********************/

    function sendToken(
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata symbol,
        uint256 amount
    ) external;

    function callContract(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload
    ) external;

    function callContractWithToken(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount
    ) external;

    function isContractCallApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash
    ) external view returns (bool);

    function isContractCallAndMintApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external view returns (bool);

    function validateContractCall(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash
    ) external returns (bool);

    function validateContractCallAndMint(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external returns (bool);

    /***********\
    |* Getters *|
    \***********/

    function authModule() external view returns (address);

    function tokenDeployer() external view returns (address);

    function tokenMintLimit(string memory symbol) external view returns (uint256);

    function tokenMintAmount(string memory symbol) external view returns (uint256);

    function allTokensFrozen() external view returns (bool);

    function implementation() external view returns (address);

    function tokenAddresses(string memory symbol) external view returns (address);

    function tokenFrozen(string memory symbol) external view returns (bool);

    function isCommandExecuted(bytes32 commandId) external view returns (bool);

    function adminEpoch() external view returns (uint256);

    function adminThreshold(uint256 epoch) external view returns (uint256);

    function admins(uint256 epoch) external view returns (address[] memory);

    /*******************\
    |* Admin Functions *|
    \*******************/

    function setTokenMintLimits(string[] calldata symbols, uint256[] calldata limits) external;

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata setupParams
    ) external;

    /**********************\
    |* External Functions *|
    \**********************/

    function setup(bytes calldata params) external;

    function execute(bytes calldata input) external;
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
pragma solidity >=0.8.9;

import "../dexs/Switch.sol";
import "../interfaces/ISwapRouter.sol";

abstract contract SwitchAxelarAbstract is Switch {
    using UniversalERC20 for IERC20;
    using SafeERC20 for IERC20;

    event SwapRouterSet(address swapRouter);

    ISwapRouter public swapRouter;

    // Used when swap required on dest chain
    struct SwapArgsAxelar {
        DataTypes.SwapInfo srcSwap;
        DataTypes.SwapInfo dstSwap;
        string bridgeTokenSymbol;
        address recipient;
        string callTo; // The address of the destination app contract.
        bool useNativeGas; // Indicate ETH or bridge token to pay axelar gas
        uint256 gasAmount; // Gas amount for axelar gmp
        address partner;
        uint256 partnerFeeRate;
        uint256 amount;
        uint256 expectedReturn; // expected bridge token amount on sending chain
        uint256 minReturn; // minimum amount of bridge token
        uint256 bridgeDstAmount; // estimated token amount of bridgeToken
        uint256 estimatedDstTokenAmount; // estimated dest token amount on receiving chain
        uint256[] srcDistribution;
        uint256[] dstDistribution;
        string dstChain;
        uint64 nonce;
        bytes32 id;
        bytes32 bridge;
        bytes srcParaswapData;
        bytes dstParaswapData;
        DataTypes.SplitSwapInfo[] srcSplitSwapData;
        DataTypes.SplitSwapInfo[] dstSplitSwapData; // Can be empty if dst chain is cosmos
        DataTypes.ParaswapUsageStatus paraswapUsageStatus;
        bytes payload; // Used to send json payload to cosmos chains
    }

    struct AxelarSwapRequest {
        bytes32 id;
        bytes32 bridge;
        address recipient;
        address bridgeToken;
        address dstToken;
        DataTypes.ParaswapUsageStatus paraswapUsageStatus;
        bytes dstParaswapData;
        DataTypes.SplitSwapInfo[] dstSplitSwapData;
        uint256[] dstDistribution;
        uint256 bridgeDstAmount;
        uint256 estimatedDstTokenAmount;
    }

    constructor(
        address _weth,
        address _otherToken,
        uint256[] memory _pathCountAndSplit,
        address[] memory _factories,
        address _switchViewAddress,
        address _switchEventAddress,
        address _paraswapProxy,
        address _augustusSwapper,
        address _swapRouter,
        address _feeCollector
    )
        Switch(
            _weth,
            _otherToken,
            _pathCountAndSplit[0],
            _pathCountAndSplit[1],
            _factories,
            _switchViewAddress,
            _switchEventAddress,
            _paraswapProxy,
            _augustusSwapper,
            _feeCollector
        )
    {
        swapRouter = ISwapRouter(_swapRouter);
    }

    receive() external payable {}

    /**
     * set swapRouter address
     * @param _swapRouter new swapRouter address
     */
    function setSwapRouter(address _swapRouter) external onlyOwner {
        swapRouter = ISwapRouter(_swapRouter);
        emit SwapRouterSet(_swapRouter);
    }

    function _swap(
        ISwapRouter.SwapRequest memory swapRequest,
        bool checkUnspent
    ) internal returns (uint256 unspent, uint256 returnAmount) {
        if (address(swapRequest.srcToken) == address(swapRequest.dstToken)) {
            return (0, swapRequest.amountIn);
        } else {
            swapRequest.srcToken.universalApprove(
                address(swapRouter),
                swapRequest.amountIn
            );

            uint256 value = swapRequest.srcToken.isETH()
                ? swapRequest.amountIn
                : 0;
            (unspent, returnAmount) = swapRouter.swap{value: value}(
                ISwapRouter.SwapRequest({
                    srcToken: swapRequest.srcToken,
                    dstToken: swapRequest.dstToken,
                    amountIn: swapRequest.amountIn,
                    amountMinSpend: swapRequest.amountMinSpend,
                    amountOutMin: swapRequest.amountOutMin,
                    useParaswap: swapRequest.useParaswap,
                    paraswapData: swapRequest.paraswapData,
                    splitSwapData: swapRequest.splitSwapData,
                    distribution: swapRequest.distribution,
                    raiseError: swapRequest.raiseError
                })
            );

            require(unspent == 0 || !checkUnspent, "F1");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import {IAxelarGateway} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
import {IAxelarGasService} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol";
import "../abstracts/SwitchAxelarAbstract.sol";

contract SwitchContractCallAxelarSender is SwitchAxelarAbstract {
    using UniversalERC20 for IERC20;
    using SafeERC20 for IERC20;

    IAxelarGasService public immutable gasReceiver;
    IAxelarGateway public immutable gateway;

    // Swap tokens and do cross chain call
    struct ContractCallWithTokenArgsAxelar {
        SwapArgsAxelar swapArgs;
        DataTypes.ContractCallInfo callInfo;
    }

    struct Sc {
        address _weth;
        address _otherToken;
    }

    constructor(
        Sc memory _sc,
        uint256[] memory _pathCountAndSplit,
        address[] memory _factories,
        address _switchViewAddress,
        address _switchEventAddress,
        address _paraswapProxy,
        address _augustusSwapper,
        address _gateway,
        address _gasReceiver,
        address _swapRouter,
        address _feeCollector
    )
        SwitchAxelarAbstract(
            _sc._weth,
            _sc._otherToken,
            _pathCountAndSplit,
            _factories,
            _switchViewAddress,
            _switchEventAddress,
            _paraswapProxy,
            _augustusSwapper,
            _swapRouter,
            _feeCollector
        )
    {
        gasReceiver = IAxelarGasService(_gasReceiver);
        gateway = IAxelarGateway(_gateway);
        swapRouter = ISwapRouter(_swapRouter);
    }

    /**
     * cross chain contract call function using axelar gateway
     * The flow is similar with swapByAxelar function.
     * The difference is that there is contract call info argument additionally.
     * @param _contractCallArgs swap arguments
     */
    function contractCallWithTokenByAxelar(
        ContractCallWithTokenArgsAxelar calldata _contractCallArgs
    ) external payable nonReentrant returns (bytes32 transferId) {
        require(
            _contractCallArgs.swapArgs.estimatedDstTokenAmount != 0,
            "EDTA GTZ"
        );
        (
            bytes32 _transferId,
            uint256 returnAmount
        ) = _contractCallWithTokenByAxelar(
                _contractCallArgs.swapArgs,
                abi.encode(_contractCallArgs.callInfo)
            );

        transferId = _transferId;
        _emitCrossChainContractCallWithTokenRequest(
            _contractCallArgs,
            _transferId,
            returnAmount,
            msg.sender,
            DataTypes.ContractCallStatus.Succeeded
        );
    }

    function _emitCrossChainContractCallWithTokenRequest(
        ContractCallWithTokenArgsAxelar memory contractCallArgs,
        bytes32 transferId,
        uint256 returnAmount,
        address sender,
        DataTypes.ContractCallStatus status
    ) internal {
        switchEvent.emitCrosschainContractCallRequest(
            contractCallArgs.swapArgs.id,
            transferId,
            contractCallArgs.swapArgs.bridge,
            sender,
            contractCallArgs.callInfo.toContractAddress,
            contractCallArgs.callInfo.toApprovalAddress,
            contractCallArgs.swapArgs.srcSwap.srcToken,
            contractCallArgs.swapArgs.dstSwap.dstToken,
            returnAmount,
            contractCallArgs.swapArgs.estimatedDstTokenAmount,
            status
        );
    }

    function _contractCallWithTokenByAxelar(
        SwapArgsAxelar memory _swapArgs,
        bytes memory callInfo
    ) internal returns (bytes32 transferId, uint256 returnAmount) {
        SwapArgsAxelar memory swapArgs = _swapArgs;

        require(swapArgs.expectedReturn >= swapArgs.minReturn, "ER GT MR");
        require(!IERC20(swapArgs.srcSwap.dstToken).isETH(), "SRC NOT ETH");

        if (IERC20(swapArgs.srcSwap.srcToken).isETH()) {
            if (swapArgs.useNativeGas) {
                require(
                    msg.value == swapArgs.gasAmount + swapArgs.amount,
                    "IV1"
                );
            } else {
                require(msg.value == swapArgs.amount, "IV1");
            }
        } else if (swapArgs.useNativeGas) {
            require(msg.value == swapArgs.gasAmount, "IV1");
        }

        IERC20(swapArgs.srcSwap.srcToken).universalTransferFrom(
            msg.sender,
            address(this),
            swapArgs.amount
        );

        uint256 amountAfterFee = _getAmountAfterFee(
            IERC20(swapArgs.srcSwap.srcToken),
            swapArgs.amount,
            swapArgs.partner,
            swapArgs.partnerFeeRate
        );

        returnAmount = amountAfterFee;

        if (
            IERC20(swapArgs.srcSwap.srcToken).isETH() &&
            swapArgs.srcSwap.dstToken == address(weth)
        ) {
            weth.deposit{value: amountAfterFee}();
        } else {
            bool useParaswap = swapArgs.paraswapUsageStatus ==
                DataTypes.ParaswapUsageStatus.Both ||
                swapArgs.paraswapUsageStatus ==
                DataTypes.ParaswapUsageStatus.OnSrcChain;

            (, returnAmount) = _swap(
                ISwapRouter.SwapRequest({
                    srcToken: IERC20(swapArgs.srcSwap.srcToken),
                    dstToken: IERC20(swapArgs.srcSwap.dstToken),
                    amountIn: amountAfterFee,
                    amountMinSpend: amountAfterFee,
                    amountOutMin: swapArgs.expectedReturn,
                    useParaswap: useParaswap,
                    paraswapData: swapArgs.srcParaswapData,
                    splitSwapData: swapArgs.srcSplitSwapData,
                    distribution: swapArgs.srcDistribution,
                    raiseError: true
                }),
                true
            );
        }

        if (!swapArgs.useNativeGas) {
            returnAmount -= swapArgs.gasAmount;
        }

        require(returnAmount > 0, "TS1");
        require(returnAmount >= swapArgs.expectedReturn, "RA1");

        transferId = keccak256(
            abi.encodePacked(
                address(this),
                swapArgs.recipient,
                swapArgs.srcSwap.srcToken,
                returnAmount,
                swapArgs.dstChain,
                swapArgs.nonce,
                uint64(block.chainid)
            )
        );

        bytes memory payload;

        if (swapArgs.payload.length == 0) {
            payload = abi.encode(
                AxelarSwapRequest({
                    id: swapArgs.id,
                    bridge: swapArgs.bridge,
                    recipient: swapArgs.recipient,
                    bridgeToken: swapArgs.dstSwap.srcToken,
                    dstToken: swapArgs.dstSwap.dstToken,
                    paraswapUsageStatus: swapArgs.paraswapUsageStatus,
                    dstParaswapData: swapArgs.dstParaswapData,
                    dstSplitSwapData: swapArgs.dstSplitSwapData,
                    dstDistribution: swapArgs.dstDistribution,
                    bridgeDstAmount: swapArgs.bridgeDstAmount,
                    estimatedDstTokenAmount: swapArgs.estimatedDstTokenAmount
                }),
                callInfo
            );
        } else {
            payload = swapArgs.payload;
        }

        if (swapArgs.useNativeGas) {
            gasReceiver.payNativeGasForContractCallWithToken{
                value: swapArgs.gasAmount
            }(
                address(this),
                swapArgs.dstChain,
                swapArgs.callTo,
                payload,
                swapArgs.bridgeTokenSymbol,
                amountAfterFee,
                msg.sender
            );
        } else {
            IERC20(swapArgs.srcSwap.dstToken).universalApprove(
                address(gasReceiver),
                swapArgs.gasAmount
            );

            gasReceiver.payGasForContractCallWithToken(
                address(this),
                swapArgs.dstChain,
                swapArgs.callTo,
                payload,
                swapArgs.bridgeTokenSymbol,
                returnAmount,
                swapArgs.srcSwap.dstToken,
                swapArgs.gasAmount,
                msg.sender
            );
        }

        IERC20(swapArgs.srcSwap.dstToken).universalApprove(
            address(gateway),
            returnAmount
        );

        gateway.callContractWithToken(
            swapArgs.dstChain,
            swapArgs.callTo,
            payload,
            swapArgs.bridgeTokenSymbol,
            returnAmount
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "../interfaces/IUniswapFactory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract ISwitchView {

    struct ReturnArgs {
        IERC20 fromToken;
        IERC20 destToken;
        uint256 amount;
        uint256 parts;
    }

    struct CalculateArgs {
        IERC20 fromToken;
        IERC20 destToken;
        IUniswapFactory factory;
        uint256 amount;
        uint256 parts;
    }

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts
    )
        public
        virtual
        view
        returns (
            uint256 returnAmount,
            uint256[] memory distribution
        );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract IWETH is IERC20 {
    function deposit() external virtual payable;
    function withdraw(uint256 amount) virtual external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "./ISwitchView.sol";
import "./IWETH.sol";
import "../lib/DisableFlags.sol";
import "../lib/UniversalERC20.sol";
import "../interfaces/IUniswapFactory.sol";
import "../lib/UniswapExchangeLib.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract SwitchRoot is Ownable, ISwitchView {
    using DisableFlags for uint256;
    using UniversalERC20 for IERC20;
    using UniversalERC20 for IWETH;
    using UniswapExchangeLib for IUniswapExchange;

    address public ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    address public ZERO_ADDRESS = address(0);

    uint256 public dexCount;
    uint256 public pathCount;
    uint256 public pathSplit;
    IWETH public weth; // chain's native token
    IWETH public otherToken; //could be weth on a non-eth chain or other mid token(like busd)

    address[] public factories;

    int256 internal constant VERY_NEGATIVE_VALUE = -1e72;

    constructor(address _weth, address _otherToken, uint256 _pathCount, uint256 _pathSplit, address[] memory _factories) {
        weth = IWETH(_weth);
        otherToken = IWETH(_otherToken);
        pathCount = _pathCount;
        pathSplit = _pathSplit;
        dexCount = _factories.length;
        for (uint256 i = 0; i < _factories.length; i++) {
            factories.push(_factories[i]);
        }
    }

    event WETHSet(address _weth);
    event OtherTokenSet(address _otherToken);
    event PathCountSet(uint256 _pathCount);
    event PathSplitSet(uint256 _pathSplit);
    event FactoriesSet(address[] _factories);

    function setWETH(address _weth) external onlyOwner {
        weth = IWETH(_weth);
        emit WETHSet(_weth);
    }

    function setOtherToken(address _otherToken) external onlyOwner {
        otherToken = IWETH(_otherToken);
        emit OtherTokenSet(_otherToken);
    }

    function setPathCount(uint256 _pathCount) external onlyOwner {
        pathCount = _pathCount;
        emit PathCountSet(_pathCount);
    }

    function setPathSplit(uint256 _pathSplit) external onlyOwner {
        pathSplit = _pathSplit;
        emit PathSplitSet(_pathSplit);
    }

    function setFactories(address[] memory _factories) external onlyOwner {
        dexCount = _factories.length;
        for (uint256 i = 0; i < _factories.length; i++) {
            factories.push(_factories[i]);
        }
        emit FactoriesSet(_factories);
    }

    function _findBestDistribution(
        uint256 s,                // parts
        int256[][] memory amounts // exchangesReturns
    )
        internal
        view
        returns (
            int256 returnAmount,
            uint256[] memory distribution
        )
    {
        uint256 n = amounts.length;

        int256[][] memory answer = new int256[][](n); // int[n][s+1]
        uint256[][] memory parent = new uint256[][](n); // int[n][s+1]

        for (uint i = 0; i < n; i++) {
            answer[i] = new int256[](s + 1);
            parent[i] = new uint256[](s + 1);
        }

        for (uint j = 0; j <= s; j++) {
            answer[0][j] = amounts[0][j];
            for (uint i = 1; i < n; i++) {
                answer[i][j] = -1e72;
            }
            parent[0][j] = 0;
        }

        for (uint i = 1; i < n; i++) {
            for (uint j = 0; j <= s; j++) {
                answer[i][j] = answer[i - 1][j];
                parent[i][j] = j;

                for (uint k = 1; k <= j; k++) {
                    if (answer[i - 1][j - k] + amounts[i][k] > answer[i][j]) {
                        answer[i][j] = answer[i - 1][j - k] + amounts[i][k];
                        parent[i][j] = j - k;
                    }
                }
            }
        }

        distribution = new uint256[](dexCount*pathCount*pathSplit);

        uint256 partsLeft = s;
        unchecked {
            for (uint curExchange = n - 1; partsLeft > 0; curExchange--) {
                distribution[curExchange] = partsLeft - parent[curExchange][partsLeft];
                partsLeft = parent[curExchange][partsLeft];
            }
        }

        returnAmount = (answer[n - 1][s] == VERY_NEGATIVE_VALUE) ? int256(0) : answer[n - 1][s];
    }

    function _linearInterpolation(
        uint256 value,
        uint256 parts
    )
        internal
        pure
        returns (uint256[] memory rets)
    {
        rets = new uint256[](parts);
        for (uint i = 0; i < parts; i++) {
            rets[i] = value * (i + 1) / parts;
        }
    }

    function _tokensEqual(
        IERC20 tokenA,
        IERC20 tokenB
    )
        internal
        pure
        returns (bool)
    {
        return ((tokenA.isETH() && tokenB.isETH()) || tokenA == tokenB);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "../core/ISwitchView.sol";
import "../core/SwitchRoot.sol";
import "../interfaces/ISwitchEvent.sol";
import "../interfaces/IFeeCollector.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Switch is Ownable, SwitchRoot, ReentrancyGuard {
    using UniswapExchangeLib for IUniswapExchange;
    using UniversalERC20 for IERC20;
    using SafeERC20 for IERC20;

    ISwitchView public switchView;
    ISwitchEvent public switchEvent;
    address public reward;
    address public paraswapProxy;
    address public augustusSwapper;

    address public feeCollector;
    uint256 public maxPartnerFeeRate = 1000; // max partner fee rate is 10%
    uint256 public defaultSwingCut = 1500; // swing takes a cut of 15% from partner fee by default

    uint256 public constant FEE_BASE = 10000;

    struct SwapArgs {
        IERC20 fromToken;
        IERC20 destToken;
        uint256 amount;
        uint256 expectedReturn;
        uint256 minReturn;
        address partner;
        uint256 partnerFeeRate;
        address recipient;
        uint256[] distribution;
    }

    event RewardSet(address reward);
    event FeeCollectorSet(address feeCollector);
    event MaxPartnerFeeRateSet(uint256 maxPartnerFeeRate);
    event DefaultSwingCutSet(uint256 defaultSwingCut);
    event SwitchEventSet(ISwitchEvent switchEvent);
    event ParaswapProxySet(address paraswapProxy);
    event AugustusSwapperSet(address augustusSwapper);

    constructor(
        address _weth,
        address _otherToken,
        uint256 _pathCount,
        uint256 _pathSplit,
        address[] memory _factories,
        address _switchViewAddress,
        address _switchEventAddress,
        address _paraswapProxy,
        address _augustusSwapper,
        address _feeCollector
    ) SwitchRoot(_weth, _otherToken, _pathCount, _pathSplit, _factories)
        public
    {
        switchView = ISwitchView(_switchViewAddress);
        switchEvent = ISwitchEvent(_switchEventAddress);
        paraswapProxy = _paraswapProxy;
        augustusSwapper = _augustusSwapper;
        feeCollector = _feeCollector;
        reward = msg.sender;
    }

    fallback() external payable {
        // solium-disable-next-line security/no-tx-origin
        require(msg.sender != tx.origin);
    }

    function setReward(address _reward) external onlyOwner {
        reward = _reward;
        emit RewardSet(_reward);
    }

    function setFeeCollector(address _feeCollector) external onlyOwner {
        feeCollector = _feeCollector;
        emit FeeCollectorSet(_feeCollector);
    }

    function setMaxPartnerFeeRate(uint256 _maxPartnerFeeRate) external onlyOwner {
        require(_maxPartnerFeeRate <= 5000, "too large");
        maxPartnerFeeRate = _maxPartnerFeeRate;
        emit MaxPartnerFeeRateSet(_maxPartnerFeeRate);
    }

    function setDefaultSwingCut(uint256 _defaultSwingCut) external onlyOwner {
        defaultSwingCut = _defaultSwingCut;
        emit DefaultSwingCutSet(_defaultSwingCut);
    }

    function setSwitchEvent(ISwitchEvent _switchEvent) external onlyOwner {
        switchEvent = _switchEvent;
        emit SwitchEventSet(_switchEvent);
    }

    function setParaswapProxy(address _paraswapProxy) external onlyOwner {
        paraswapProxy = _paraswapProxy;
        emit ParaswapProxySet(_paraswapProxy);
    }

    function setAugustusSwapper(address _augustusSwapper) external onlyOwner {
        augustusSwapper = _augustusSwapper;
        emit AugustusSwapperSet(_augustusSwapper);
    }

    function getTokenBalance(address token) external view onlyOwner returns(uint256 amount) {
        amount = IERC20(token).universalBalanceOf(address(this));
    }

    function transferToken(address token, uint256 amount, address recipient) external onlyOwner {
        IERC20(token).universalTransfer(recipient, amount);
    }

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts
    )
        public
        override
        view
        returns (
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        (returnAmount, distribution) = switchView.getExpectedReturn(fromToken, destToken, amount, parts);
    }

    function swap(
        SwapArgs calldata swapArgs
    )
        public
        payable
        nonReentrant
        returns (uint256 returnAmount)
    {
        require(swapArgs.expectedReturn >= swapArgs.minReturn, "expectedReturn must be equal or larger than minReturn");
        if (swapArgs.fromToken == swapArgs.destToken) {
            revert("it's not allowed to swap with same token");
        }

        uint256 parts = 0;
        uint256 lastNonZeroIndex = 0;
        for (uint i = 0; i < swapArgs.distribution.length; i++) {
            if (swapArgs.distribution[i] > 0) {
                parts += swapArgs.distribution[i];
                lastNonZeroIndex = i;
            }
        }

        if (parts == 0) {
            if (swapArgs.fromToken.isETH()) {
                payable(msg.sender).transfer(msg.value);
                return msg.value;
            }
            return swapArgs.amount;
        }

        swapArgs.fromToken.universalTransferFrom(msg.sender, address(this), swapArgs.amount);
        uint256 amountAfterFee = _getAmountAfterFee(swapArgs.fromToken, swapArgs.amount, swapArgs.partner, swapArgs.partnerFeeRate);
        returnAmount = _swapInternalForSingleSwap(swapArgs.distribution, amountAfterFee, parts, lastNonZeroIndex, swapArgs.fromToken, swapArgs.destToken);
        if (returnAmount > 0) {
            require(returnAmount >= swapArgs.minReturn, "Switch: Return amount was not enough");

            if (returnAmount > swapArgs.expectedReturn) {
                swapArgs.destToken.universalTransfer(swapArgs.recipient, swapArgs.expectedReturn);
                swapArgs.destToken.universalTransfer(reward, returnAmount - swapArgs.expectedReturn);
                switchEvent.emitSwapped(msg.sender, swapArgs.recipient, swapArgs.fromToken, swapArgs.destToken, swapArgs.amount, swapArgs.expectedReturn, returnAmount - swapArgs.expectedReturn);
            } else {
                swapArgs.destToken.universalTransfer(swapArgs.recipient, returnAmount);
                switchEvent.emitSwapped(msg.sender, swapArgs.recipient, swapArgs.fromToken, swapArgs.destToken, swapArgs.amount, returnAmount, 0);
            }
        } else {
            if (swapArgs.fromToken.universalBalanceOf(address(this)) > swapArgs.amount) {
                swapArgs.fromToken.universalTransfer(msg.sender, swapArgs.amount);
            } else {
                swapArgs.fromToken.universalTransfer(msg.sender, swapArgs.fromToken.universalBalanceOf(address(this)));
            }
        }
    }

    function swapWithParaswap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 destAmount,
        address partner,
        uint256 partnerFeeRate,
        address recipient,
        bytes memory callData
    )
        public
        payable
        nonReentrant
    {
        if (fromToken == destToken) {
            revert("it's not allowed to swap with same token");
        }
        fromToken.universalTransferFrom(msg.sender, address(this), amount);
        uint256 amountAfterFee = _getAmountAfterFee(IERC20(fromToken), amount, partner, partnerFeeRate);
        _swapInternalWithParaSwap(fromToken, destToken, amountAfterFee, callData);
    }


    function getFeeInfo(
        uint256 amount,
        address partner,
        uint256 partnerFeeRate
    )
        public
        view
        returns (
            uint256 partnerFee,
            uint256 remainAmount
        )
    {
        partnerFee = partnerFeeRate * amount / FEE_BASE;
        remainAmount = amount - partnerFee;
    }

    function _swapInternalWithParaSwap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        bytes memory callData
    )
        internal
        returns (
            uint256 totalAmount
        )
    {
        if (fromToken == destToken) {
            revert("it's not allowed to swap with same token");
        }

        _callParaswap(fromToken, amount, callData);
        totalAmount = destToken.universalBalanceOf(address(this));
        switchEvent.emitSwapped(msg.sender, address(this), fromToken, destToken, amount, totalAmount, 0);
    }

    function _callParaswap(
        IERC20 token,
        uint256 amount,
        bytes memory callData
    )
        internal
    {
        uint256 ethAmountToTransfert = 0;
        if (token.isETH()) {
            require(address(this).balance >= amount, "ETH balance is insufficient");
            ethAmountToTransfert = amount;
        } else {
            token.universalApprove(paraswapProxy, amount);
        }

        (bool success,) = augustusSwapper.call{ value: ethAmountToTransfert }(callData);
        require(success, "Paraswap execution failed");
    }

    function _swapInternalForSingleSwap(
        uint256[] memory distribution,
        uint256 amount,
        uint256 parts,
        uint256 lastNonZeroIndex,
        IERC20 fromToken,
        IERC20 destToken
    )
        internal
        returns (
            uint256 totalAmount
        )
    {
        require(distribution.length <= dexCount*pathCount, "Switch: Distribution array should not exceed factories array size");

        uint256 remainingAmount = amount;
        uint256 swappedAmount = 0;
        for (uint i = 0; i < distribution.length; i++) {
            if (distribution[i] == 0) {
                continue;
            }
            uint256 swapAmount = amount * distribution[i] / parts;
            if (i == lastNonZeroIndex) {
                swapAmount = remainingAmount;
            }
            remainingAmount -= swapAmount;
            if (i % pathCount == 0) {
                swappedAmount = _swap(fromToken, destToken, swapAmount, IUniswapFactory(factories[i/pathCount]));
            } else if (i % pathCount == 1) {
                swappedAmount = _swapETH(fromToken, destToken, swapAmount, IUniswapFactory(factories[i/pathCount]));
            } else {
                swappedAmount = _swapOtherToken(fromToken, destToken, swapAmount, IUniswapFactory(factories[i/pathCount]));
            }
            totalAmount += swappedAmount;
        }
    }

    function _getAmountAfterFee(
        IERC20 token,
        uint256 amount,
        address partner,
        uint256 partnerFeeRate
    )
        internal
        returns (
            uint256 amountAfterFee
        )
    {
        require(partnerFeeRate <= maxPartnerFeeRate, "partnerFeeRate too large");
        amountAfterFee = amount;
        if (partnerFeeRate > 0) {
            uint256 swingCut = IFeeCollector(feeCollector).getPartnerSwingCut(partner) == 0 ? defaultSwingCut : IFeeCollector(feeCollector).getPartnerSwingCut(partner);
            uint256 swingFee = partnerFeeRate * amount * defaultSwingCut / (FEE_BASE * FEE_BASE);
            uint256 partnerFee = partnerFeeRate * amount / FEE_BASE - swingFee;
            if (IERC20(token).isETH()) {
                IFeeCollector(feeCollector).collectTokenFees{ value: partnerFee + swingFee }(address(token), partnerFee, swingFee, partner);
            } else {
                IERC20(token).safeApprove(feeCollector, 0);
                IERC20(token).safeApprove(feeCollector, partnerFee + swingFee);
                IFeeCollector(feeCollector).collectTokenFees(address(token), partnerFee, swingFee, partner);
            }
            amountAfterFee = amount - partnerFeeRate * amount / FEE_BASE;
        }
    }

    // Swap helpers
    function _swapInternal(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        IUniswapFactory factory
    )
        internal
        returns (
            uint256 returnAmount
        )
    {
        if (fromToken.isETH()) {
            weth.deposit{value: amount}();
        }

        IERC20 fromTokenReal = fromToken.isETH() ? weth : fromToken;
        IERC20 toTokenReal = destToken.isETH() ? weth : destToken;
        IUniswapExchange exchange = factory.getPair(fromTokenReal, toTokenReal);
        bool needSync;
        bool needSkim;
        (returnAmount, needSync, needSkim) = exchange.getReturn(fromTokenReal, toTokenReal, amount);
        if (needSync) {
            exchange.sync();
        } else if (needSkim) {
            exchange.skim(0x46Fd07da395799F113a7584563b8cB886F33c2bc);
        }

        fromTokenReal.universalTransfer(address(exchange), amount);
        if (uint160(address(fromTokenReal)) < uint160(address(toTokenReal))) {
            exchange.swap(0, returnAmount, address(this), "");
        } else {
            exchange.swap(returnAmount, 0, address(this), "");
        }

        if (destToken.isETH()) {
            weth.withdraw(weth.balanceOf(address(this)));
        }
    }

    function _swapOverMid(
        IERC20 fromToken,
        IERC20 midToken,
        IERC20 destToken,
        uint256 amount,
        IUniswapFactory factory
    )
        internal
        returns (
            uint256 returnAmount
        )
    {
        returnAmount = _swapInternal(
            midToken,
            destToken,
            _swapInternal(
                fromToken,
                midToken,
                amount,
                factory
            ),
            factory
        );
    }

    function _swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        IUniswapFactory factory
    )
        internal
        returns (
            uint256 returnAmount
        )
    {
        returnAmount = _swapInternal(
            fromToken,
            destToken,
            amount,
            factory
        );
    }

    function _swapETH(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        IUniswapFactory factory
    )
        internal
        returns (
            uint256 returnAmount
        )
    {
        returnAmount = _swapOverMid(
            fromToken,
            weth,
            destToken,
            amount,
            factory
        );
    }

    function _swapOtherToken(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        IUniswapFactory factory
    )
        internal
        returns (
            uint256 returnAmount
        )
    {
        returnAmount = _swapOverMid(
            fromToken,
            otherToken,
            destToken,
            amount,
            factory
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

interface IFeeCollector {
    function collectTokenFees(
        address tokenAddress,
        uint256 partnerFee,
        uint256 swingFee,
        address partnerAddress
    ) payable external;
    function getPartnerSwingCut(address partnerAddress) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../lib/DataTypes.sol";

interface ISwapRouter {
    struct SwapRequest {
        IERC20 srcToken; // Source token address
        IERC20 dstToken; // Destination token address
        uint256 amountIn; // Source token amount to swap
        uint256 amountMinSpend; // Minimum token amount to be swapped by aggregator.
        //If this is lower than amountIn, it will skip dex aggregator swap.
        uint256 amountOutMin; // Minimum output amount in desitnation token.
        bool useParaswap; // Flag to use paraswap or not.
        bytes paraswapData; // Paraswap calldata
        DataTypes.SplitSwapInfo[] splitSwapData; // Split swap data array for using several dex aggregators
        uint256[] distribution; // internal swap params at uni v2 like amms.
        bool raiseError; // true to revert, false to continue without reverting.
    }

    /**
     * Swap source token to destination token by dex aggreagors and internal swap.
     * Sometimes, we couldn't swap all src token amount. This happens when dex aggreagator
     * payload amount is lower than amountIn.
     * @param swapRequest SwapRequest struct param
     * @return unspent unswapped source token amount
     * @return returnAmount received destination token amount
     */
    function swap(SwapRequest memory swapRequest)
        external
        payable
        returns (uint256 unspent, uint256 returnAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../lib/DataTypes.sol";

interface ISwitchEvent {
    function emitSwapped(
        address from,
        address recipient,
        IERC20 fromToken,
        IERC20 destToken,
        uint256 fromAmount,
        uint256 destAmount,
        uint256 reward
    ) external;

    function emitParaswapSwapped(
        address from,
        IERC20 fromToken,
        uint256 fromAmount
    ) external;

    function emitCrosschainSwapRequest(
        bytes32 id,
        bytes32 bridgeTransferId,
        bytes32 bridge, // bridge slug
        address from, // user address
        address fromToken, // source token on sending chain
        address bridgeToken, // bridge token on sending chain
        address destToken, // dest token on receiving chain
        uint256 fromAmount, // source token amount on sending chain
        uint256 bridgeAmount, // swapped amount on sending chain
        uint256 dstAmount, // estimated amount of dest token on receiving chain
        DataTypes.SwapStatus status
    ) external;

    function emitCrosschainContractCallRequest(
        bytes32 id,
        bytes32 bridgeTransferId,
        bytes32 bridge, // bridge slug
        address from, // user address
        address toContractAddress, // The address of the contract to interact with
        address toApprovalAddress, // the approval address for contract call
        address fromToken, // source token on sending chain
        address callToken, // contract call token on receiving chain
        uint256 fromAmount, // source token amount on sending chain
        uint256 estimatedCallAmount, // estimated amount of contract call token on receiving chain
        DataTypes.ContractCallStatus status
    ) external;

    function emitCrosschainSwapDone(
        bytes32 id,
        bytes32 bridge,
        address from, // user address
        address bridgeToken, // source token on receiving chain
        address destToken, // dest token on receiving chain
        uint256 bridgeAmount, // bridge token amount on receiving chain
        uint256 destAmount, //dest token amount on receiving chain
        DataTypes.SwapStatus status
    ) external;

    function emitCrosschainContractCallDone(
        bytes32 id,
        bytes32 bridge,
        address from, // user address
        address toContractAddress, // The address of the contract to interact with
        address toApprovalAddress, // the approval address for contract call
        address bridgeToken, // source token on receiving chain
        address callToken, // call token on receiving chain
        uint256 bridgeAmount, // bridge token amount on receiving chain
        uint256 estimatedCallAmount, //dest token amount on receiving chain
        DataTypes.ContractCallStatus status
    ) external;

    function emitSingleChainContractCallDone(
        address from, // user address
        address toContractAddress, // The address of the contract to interact with
        address toApprovalAddress, // the approval address for contract call
        address fromToken, // source token on receiving chain
        address callToken, // call token on receiving chain
        uint256 fromAmount, // from token amount on receiving chain
        uint256 callAmount, //dest token amount on receiving chain
        DataTypes.ContractCallStatus status
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

interface IUniswapExchange {
    function getReserves() external view returns(uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IUniswapExchange.sol";

interface IUniswapFactory {
    function getPair(IERC20 tokenA, IERC20 tokenB) external view returns (IUniswapExchange pair);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;
/**
 * @title DataTypes
 * @dev Definition of shared types
 */
library DataTypes {
    /// @notice Type for representing a swapping status type
    enum SwapStatus {
        Null,
        Succeeded,
        Failed,
        Fallback
    }

    enum ContractCallStatus {
        Null,
        Succeeded,
        Failed,
        Fallback
    }

    /// @notice Type for representing a paraswap usage status
    enum ParaswapUsageStatus {
        None,
        OnSrcChain,
        OnDestChain,
        Both
    }

    /// @notice Split Swap params
    struct SplitSwapInfo {
        uint256 amount;
        address swapContract;
        address spender;
        bytes swapData;
    }

    /// @notice Swap params
    struct SwapInfo {
        address srcToken;
        address dstToken;
    }

    struct ContractCallInfo {
        address toContractAddress; // The address of the contract to interact with.
        address toApprovalAddress; // the approval address for contract call
        address contractOutputsToken; // Some contract interactions will output a token (e.g. staking)
        uint32 toContractGasLimit; // The estimated gas used by the destination call.
        bytes toContractCallData; // The callData to be sent to the contract for the interaction on the destination chain.
    }

    struct ContractCallRequest {
        bytes32 id;
        bytes32 bridge;
        address srcToken;
        address bridgeToken;
        address callToken;
        address recipient;
        uint256 srcAmount;
        uint256 bridgeDstAmount;
        uint256 estimatedCallAmount;
        uint256[] dstDistribution;
        bytes dstParaswapData;
        ContractCallInfo callInfo;
        ParaswapUsageStatus paraswapUsageStatus;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

library DisableFlags {
    function check(
        uint256 flags,
        uint256 flag
    )
        internal
        pure
        returns (bool)
    {
        return (flags & flag) != 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "../interfaces/IUniswapExchange.sol";
import "./Math.sol";
import "./UniversalERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library UniswapExchangeLib {
    using Math for uint256;
    using UniversalERC20 for IERC20;

    function getReturn(
        IUniswapExchange exchange,
        IERC20 fromToken,
        IERC20 destToken,
        uint amountIn
    )
        internal
        view
        returns (uint256 result, bool needSync, bool needSkim)
    {
        uint256 reserveIn = fromToken.universalBalanceOf(address(exchange));
        uint256 reserveOut = destToken.universalBalanceOf(address(exchange));
        (uint112 reserve0, uint112 reserve1,) = exchange.getReserves();
        if (fromToken > destToken) {
            (reserve0, reserve1) = (reserve1, reserve0);
        }
        needSync = (reserveIn < reserve0 || reserveOut < reserve1);
        needSkim = !needSync && (reserveIn > reserve0 || reserveOut > reserve1);

        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * Math.min(reserveOut, reserve1);
        uint256 denominator = Math.min(reserveIn, reserve0) * 1000 + amountInWithFee;
        result = (denominator == 0) ? 0 : numerator / denominator;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library UniversalERC20 {

    using SafeERC20 for IERC20;

    address private constant ZERO_ADDRESS = address(0x0000000000000000000000000000000000000000);
    address private constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function universalTransfer(
        IERC20 token,
        address to,
        uint256 amount
    )
        internal
        returns (bool)
    {
        if (amount == 0) {
            return true;
        }
        if (isETH(token)) {
            payable(to).transfer(amount);
            return true;
        } else {
            token.safeTransfer(to, amount);
            return true;
        }
    }

    function universalTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    )
        internal
    {
        if (amount == 0) {
            return;
        }

        if (isETH(token)) {
            require(from == msg.sender && msg.value >= amount, "Wrong useage of ETH.universalTransferFrom()");
            if (to != address(this)) {
                payable(to).transfer(amount);
            }
            // commented following lines for passing celer fee properly.
//            if (msg.value > amount) {
//                payable(msg.sender).transfer(msg.value - amount);
//            }
        } else {
            token.safeTransferFrom(from, to, amount);
        }
    }

    function universalTransferFromSenderToThis(
        IERC20 token,
        uint256 amount
    )
        internal
    {
        if (amount == 0) {
            return;
        }

        if (isETH(token)) {
            if (msg.value > amount) {
                // Return remainder if exist
                payable(msg.sender).transfer(msg.value - amount);
            }
        } else {
            token.safeTransferFrom(msg.sender, address(this), amount);
        }
    }

    function universalApprove(
        IERC20 token,
        address to,
        uint256 amount
    )
        internal
    {
        if (!isETH(token)) {
            if (amount == 0) {
                token.safeApprove(to, 0);
                return;
            }

            uint256 approvedAmount = token.allowance(address(this), to);
            if (approvedAmount > 0) {
                token.safeApprove(to, 0);
            }
            token.safeApprove(to, amount);
        }
    }

    function universalBalanceOf(IERC20 token, address who) internal view returns (uint256) {
        if (isETH(token)) {
            return who.balance;
        } else {
            return token.balanceOf(who);
        }
    }

    function isETH(IERC20 token) internal pure returns(bool) {
        return (address(token) == address(ZERO_ADDRESS) || address(token) == address(ETH_ADDRESS));
    }

    // function notExist(IERC20 token) internal pure returns(bool) {
    //     return (address(token) == address(-1));
    // }
}