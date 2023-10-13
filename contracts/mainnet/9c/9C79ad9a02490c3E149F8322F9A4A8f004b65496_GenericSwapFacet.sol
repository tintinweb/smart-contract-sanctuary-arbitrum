// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "ISo.sol";
import "LibAsset.sol";
import "ReentrancyGuard.sol";
import "GenericErrors.sol";
import "Swapper.sol";
import "LibCross.sol";
import "ILibSoFeeV2.sol";

/// @title Generic Swap Facet
/// @notice Provides functionality for swapping through ANY APPROVED DEX
/// @dev Uses calldata to execute APPROVED arbitrary methods on DEXs
contract GenericSwapFacet is ISo, Swapper, ReentrancyGuard {
    /// Events ///

    event SoSwappedGeneric(
        bytes32 indexed transactionId,
        address fromAssetId,
        address toAssetId,
        uint256 fromAmount,
        uint256 toAmount
    );

    /// External Methods ///

    /// @notice Performs multiple swaps in one transaction
    /// @param soDataNo data used purely for tracking and analytics
    /// @param swapDataNo an array of swap related data for performing swaps before bridging
    function swapTokensGeneric(
        ISo.NormalizedSoData calldata soDataNo,
        LibSwap.NormalizedSwapData[] calldata swapDataNo
    ) external payable nonReentrant {
        ISo.SoData memory soData = LibCross.denormalizeSoData(soDataNo);
        LibSwap.SwapData[] memory swapData = LibCross.denormalizeSwapData(
            swapDataNo
        );

        if (swapData.length == 0) revert NoSwapDataProvided();
        uint256 fromAmount = _getSwapAmount(swapData);

        if (!LibAsset.isNativeAsset(swapData[0].sendingAssetId)) {
            LibAsset.depositAsset(swapData[0].sendingAssetId, fromAmount);
        } else {
            require(msg.value >= fromAmount, "NotEnoughValue");
        }
        uint256 postSwapBalance = this.executeAndCheckSwapsV2(soData, swapData);
        address receivingAssetId = swapData[swapData.length - 1]
            .receivingAssetId;

        uint256 soFee = getGenericSoFee(postSwapBalance);
        address soBasicBeneficiary = getGenericBasicBeneficiary();
        if (soBasicBeneficiary != address(0x0) && soFee > 0) {
            transferUnwrappedAsset(
                receivingAssetId,
                soData.receivingAssetId,
                soFee,
                soBasicBeneficiary
            );
            postSwapBalance -= soFee;
        }

        transferUnwrappedAsset(
            receivingAssetId,
            soData.receivingAssetId,
            postSwapBalance,
            soData.receiver
        );

        emit SoSwappedGeneric(
            soData.transactionId,
            soData.sendingAssetId,
            soData.receivingAssetId,
            fromAmount,
            postSwapBalance
        );
    }

    /// @dev Get so fee
    function getGenericSoFee(uint256 amount) public view returns (uint256) {
        address soFee = appStorage.gatewaySoFeeSelectors[address(0x0)];
        if (soFee == address(0x0)) {
            return 0;
        } else {
            return ILibSoFeeV2(soFee).getFees(amount);
        }
    }

    /// @dev Get basic beneficiary
    function getGenericBasicBeneficiary() public view returns (address) {
        address soFee = appStorage.gatewaySoFeeSelectors[address(0x0)];
        if (soFee == address(0x0)) {
            return address(0x0);
        } else {
            return ILibSoFeeV2(soFee).getBasicBeneficiary();
        }
    }

    /// @dev Get basic fee
    function getGenericBasicFee() public view returns (uint256) {
        address soFee = appStorage.gatewaySoFeeSelectors[address(0x0)];
        if (soFee == address(0x0)) {
            return 0;
        } else {
            return ILibSoFeeV2(soFee).getBasicFee();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface ISo {
    /// Structs ///

    struct SoData {
        bytes32 transactionId; // unique identification id
        address payable receiver; // token receiving account
        uint16 sourceChainId; // source chain id
        address sendingAssetId; // The starting token address of the source chain
        uint16 destinationChainId; // destination chain id
        address receivingAssetId; // The final token address of the destination chain
        uint256 amount; // User enters amount
    }

    struct NormalizedSoData {
        bytes transactionId; // unique identification id
        bytes receiver; // token receiving account
        uint16 sourceChainId; // source chain id
        bytes sendingAssetId; // The starting token address of the source chain
        uint16 destinationChainId; // destination chain id
        bytes receivingAssetId; // The final token address of the destination chain
        uint256 amount; // User enters amount
    }

    /// Events ///

    event SoTransferStarted(bytes32 indexed transactionId);

    event SoTransferFailed(
        bytes32 indexed transactionId,
        string revertReason,
        bytes otherReason
    );

    event SoTransferCompleted(
        bytes32 indexed transactionId,
        uint256 receiveAmount
    );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;
import {NullAddrIsNotAnERC20Token, NullAddrIsNotAValidSpender, NoTransferToNullAddress, InvalidAmount, NativeValueWithERC, NativeAssetTransferFailed} from "GenericErrors.sol";
import "SafeERC20.sol";
import "IERC20.sol";

/// @title LibAsset
/// @author Connext <[email protected]>
/// @notice This library contains helpers for dealing with onchain transfers
///         of assets, including accounting for the native asset `assetId`
///         conventions and any noncompliant ERC20 transfers
library LibAsset {
    uint256 private constant MAX_INT = type(uint256).max;

    address internal constant NULL_ADDRESS =
        0x0000000000000000000000000000000000000000; //address(0)

    /// @dev All native assets use the empty address for their asset id
    ///      by convention

    address internal constant NATIVE_ASSETID = NULL_ADDRESS; //address(0)

    /// @notice Gets the balance of the inheriting contract for the given asset
    /// @param assetId The asset identifier to get the balance of
    /// @return Balance held by contracts using this library
    function getOwnBalance(address assetId) internal view returns (uint256) {
        return
            assetId == NATIVE_ASSETID
                ? address(this).balance
                : IERC20(assetId).balanceOf(address(this));
    }

    /// @notice Transfers ether from the inheriting contract to a given
    ///         recipient
    /// @param recipient Address to send ether to
    /// @param amount Amount to send to given recipient
    function transferNativeAsset(address payable recipient, uint256 amount)
        private
    {
        if (recipient == NULL_ADDRESS) revert NoTransferToNullAddress();
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = recipient.call{value: amount}("");
        if (!success) revert NativeAssetTransferFailed();
    }

    /// @notice Gives MAX approval for another address to spend tokens
    /// @param assetId Token address to transfer
    /// @param spender Address to give spend approval to
    /// @param amount Amount to approve for spending
    function maxApproveERC20(
        IERC20 assetId,
        address spender,
        uint256 amount
    ) internal {
        if (address(assetId) == NATIVE_ASSETID) return;
        if (spender == NULL_ADDRESS) revert NullAddrIsNotAValidSpender();
        uint256 allowance = assetId.allowance(address(this), spender);
        if (allowance < amount)
            SafeERC20.safeApprove(IERC20(assetId), spender, MAX_INT);
    }

    /// @notice Transfers tokens from the inheriting contract to a given
    ///         recipient
    /// @param assetId Token address to transfer
    /// @param recipient Address to send token to
    /// @param amount Amount to send to given recipient
    function transferERC20(
        address assetId,
        address recipient,
        uint256 amount
    ) private {
        if (isNativeAsset(assetId)) revert NullAddrIsNotAnERC20Token();
        SafeERC20.safeTransfer(IERC20(assetId), recipient, amount);
    }

    /// @notice Transfers tokens from a sender to a given recipient
    /// @param assetId Token address to transfer
    /// @param from Address of sender/owner
    /// @param to Address of recipient/spender
    /// @param amount Amount to transfer from owner to spender
    function transferFromERC20(
        address assetId,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (assetId == NATIVE_ASSETID) revert NullAddrIsNotAnERC20Token();
        if (to == NULL_ADDRESS) revert NoTransferToNullAddress();
        SafeERC20.safeTransferFrom(IERC20(assetId), from, to, amount);
    }

    /// @notice Deposits an asset into the contract and performs checks to avoid NativeValueWithERC
    /// @param tokenId Token to deposit
    /// @param amount Amount to deposit
    /// @param isNative Wether the token is native or ERC20
    function depositAsset(
        address tokenId,
        uint256 amount,
        bool isNative
    ) internal {
        if (amount == 0) revert InvalidAmount();
        if (isNative) {
            if (msg.value != amount) revert InvalidAmount();
        } else {
            //            if (msg.value != 0) revert NativeValueWithERC();
            uint256 _fromTokenBalance = LibAsset.getOwnBalance(tokenId);
            LibAsset.transferFromERC20(
                tokenId,
                msg.sender,
                address(this),
                amount
            );
            if (LibAsset.getOwnBalance(tokenId) - _fromTokenBalance != amount)
                revert InvalidAmount();
        }
    }

    /// @notice Overload for depositAsset(address tokenId, uint256 amount, bool isNative)
    /// @param tokenId Token to deposit
    /// @param amount Amount to deposit
    function depositAsset(address tokenId, uint256 amount) internal {
        return depositAsset(tokenId, amount, tokenId == NATIVE_ASSETID);
    }

    /// @notice Determines whether the given assetId is the native asset
    /// @param assetId The asset identifier to evaluate
    /// @return Boolean indicating if the asset is the native asset
    function isNativeAsset(address assetId) internal pure returns (bool) {
        return assetId == NATIVE_ASSETID;
    }

    /// @notice Wrapper function to transfer a given asset (native or erc20) to
    ///         some recipient. Should handle all non-compliant return value
    ///         tokens as well by using the SafeERC20 contract by open zeppelin.
    /// @param assetId Asset id for transfer (address(0) for native asset,
    ///                token address for erc20s)
    /// @param recipient Address to send asset to
    /// @param amount Amount to send to given recipient
    function transferAsset(
        address assetId,
        address payable recipient,
        uint256 amount
    ) internal {
        (assetId == NATIVE_ASSETID)
            ? transferNativeAsset(recipient, amount)
            : transferERC20(assetId, recipient, amount);
    }

    /// @dev Checks whether the given address is a contract and contains code
    function isContract(address contractAddr) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(contractAddr)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

error InvalidAmount(); // 0x2c5211c6
error TokenAddressIsZero(); // 0xdc2e5e8d
error CannotBridgeToSameNetwork(); // 0x4ac09ad3
error ZeroPostSwapBalance(); // 0xf74e8909
error InvalidBridgeConfigLength(); // 0x10502ef9
error NoSwapDataProvided(); // 0x0503c3ed
error NotSupportedSwapRouter(); // 0xe986f686
error NativeValueWithERC(); // 0x003f45b5
error ContractCallNotAllowed(); // 0x94539804
error NullAddrIsNotAValidSpender(); // 0x63ba9bff
error NullAddrIsNotAnERC20Token(); // 0xd1bebf0c
error NoTransferToNullAddress(); // 0x21f74345
error NativeAssetTransferFailed(); // 0x5a046737
error InvalidContract(); // 0x6eefed20
error InvalidConfig(); // 0x35be3ac8

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Address.sol";

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

/// @title Reentrancy Guard
/// @author LI.FI (https://li.fi)
/// @notice Abstract contract to provide protection against reentrancy
abstract contract ReentrancyGuard {
    /// Storage ///

    bytes32 private constant NAMESPACE =
        hex"a65bb2f450488ab0858c00edc14abc5297769bf42adb48cfb77752890e8b697b";

    /// Types ///

    struct ReentrancyStorage {
        uint256 status;
    }

    /// Errors ///

    error ReentrancyError();

    /// Constants ///

    uint256 private constant _NOT_ENTERED = 0;
    uint256 private constant _ENTERED = 1;

    /// Modifiers ///

    modifier nonReentrant() {
        ReentrancyStorage storage s = reentrancyStorage();
        if (s.status == _ENTERED) revert ReentrancyError();
        s.status = _ENTERED;
        _;
        s.status = _NOT_ENTERED;
    }

    /// Private Methods ///

    /// @dev fetch local storage
    function reentrancyStorage()
        private
        pure
        returns (ReentrancyStorage storage data)
    {
        bytes32 position = NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            data.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IWETH} from "IWETH.sol";
import {ISo} from "ISo.sol";
import {ICorrectSwap} from "ICorrectSwap.sol";
import {LibSwap} from "LibSwap.sol";
import {LibAsset} from "LibAsset.sol";
import {LibUtil} from "LibUtil.sol";
import {LibStorage} from "LibStorage.sol";
import {LibAsset} from "LibAsset.sol";
import {InvalidAmount, ContractCallNotAllowed, NoSwapDataProvided, NotSupportedSwapRouter} from "GenericErrors.sol";

/// @title Swapper
/// @notice Abstract contract to provide swap functionality
contract Swapper is ISo {
    /// Storage ///

    LibStorage internal appStorage;

    struct CacheSwapInnerParam {
        LibSwap.SwapData currentSwapData;
        uint256 fromAmount;
        uint256 minAmount;
        uint256 swapBalance;
        address receivedToken;
    }

    struct CacheSwapParam {
        address correctSwap;
        uint256[] sliceIndex;
        uint256 deltaFromAmount;
        uint256 deltaMinAmount;
        uint256 startIndex;
        uint256 endIndex;
        bool flag;
        uint256 fromAmount;
        uint256 minAmount;
    }

    /// External Methods ///

    /// @dev Validates input before executing swaps
    /// @param soData So tracking data
    /// @param swapData Array of data used to execute swaps
    function executeAndCheckSwaps(
        SoData memory soData,
        LibSwap.SwapData[] calldata swapData
    ) external returns (uint256) {
        require(msg.sender == address(this), "NotDiamond");
        uint256 nSwaps = swapData.length;
        if (nSwaps == 0) revert NoSwapDataProvided();
        address finalTokenId = swapData[swapData.length - 1].receivingAssetId;
        uint256 swapBalance = LibAsset.getOwnBalance(finalTokenId);
        _executeSwaps(soData, swapData);
        swapBalance = LibAsset.getOwnBalance(finalTokenId) - swapBalance;
        if (swapBalance == 0) revert InvalidAmount();
        return swapBalance;
    }

    /// @dev Validates input before executing swaps. Support dynamic slice swap
    /// @param soData So tracking data
    /// @param swapData Array of data used to execute swaps
    function executeAndCheckSwapsV2(
        SoData memory soData,
        LibSwap.SwapData[] calldata swapData
    ) external returns (uint256) {
        require(msg.sender == address(this), "NotDiamond");
        uint256 nSwaps = swapData.length;
        if (nSwaps == 0) revert NoSwapDataProvided();
        address finalTokenId = swapData[swapData.length - 1].receivingAssetId;
        uint256 swapBalance = LibAsset.getOwnBalance(finalTokenId);
        _executeSwapsV2(soData, swapData);
        swapBalance = LibAsset.getOwnBalance(finalTokenId) - swapBalance;
        if (swapBalance == 0) revert InvalidAmount();
        return swapBalance;
    }

    function libSwap(bytes32 transactionId, LibSwap.SwapData memory _swapData)
        external
    {
        require(msg.sender == address(this), "NotDiamond");
        LibSwap.swap(transactionId, _swapData);
    }

    /// Internal Methods ///

    /// @dev Convert eth to wrapped eth and Transfer.
    function transferWrappedAsset(
        address currentAssetId,
        address expectAssetId,
        uint256 amount
    ) internal {
        if (currentAssetId == expectAssetId) {
            require(
                LibAsset.getOwnBalance(currentAssetId) >= amount,
                "NotEnough"
            );
            return;
        }

        if (LibAsset.isNativeAsset(currentAssetId)) {
            // eth -> weth
            try IWETH(expectAssetId).deposit{value: amount}() {} catch {
                revert("DepositErr");
            }
        } else if (LibAsset.isNativeAsset(expectAssetId)) {
            // weth -> eth
            try IWETH(currentAssetId).withdraw(amount) {} catch {
                revert("WithdrawErr");
            }
        } else {
            // weth -> eth -> weth
            if (currentAssetId != expectAssetId) {
                try IWETH(currentAssetId).withdraw(amount) {} catch {
                    revert("WithdrawDepositErr");
                }
                try IWETH(expectAssetId).deposit{value: amount}() {} catch {
                    revert("WithdrawDepositErr");
                }
            }
        }
    }

    /// @dev Convert wrapped eth to eth and Transfer.
    function transferUnwrappedAsset(
        address currentAssetId,
        address expectAssetId,
        uint256 amount,
        address receiver
    ) internal {
        if (LibAsset.isNativeAsset(expectAssetId)) {
            if (currentAssetId != expectAssetId) {
                try IWETH(currentAssetId).withdraw(amount) {} catch {
                    revert("WithdrawErr");
                }
            }
        } else {
            require(currentAssetId == expectAssetId, "AssetIdErr");
        }
        if (receiver != address(this)) {
            require(
                LibAsset.getOwnBalance(expectAssetId) >= amount,
                "NotEnough"
            );
            LibAsset.transferAsset(expectAssetId, payable(receiver), amount);
        }
    }

    /// @dev Find swap slice
    /// @param swapData Array of data used to execute swaps
    function _getSwapAmount(LibSwap.SwapData[] memory swapData)
        internal
        returns (uint256)
    {
        address sendingAssetId = swapData[0].sendingAssetId;
        uint256 amount;
        for (uint256 i = 0; i < swapData.length; i++) {
            if (
                swapData[i].sendingAssetId == sendingAssetId &&
                swapData[i].fromAmount > 0
            ) {
                amount += swapData[i].fromAmount;
            }
        }
        return amount;
    }

    /// Private Methods ///

    /// @dev Executes swaps and checks that DEXs used are in the allowList
    /// @param soData So tracking data
    /// @param swapData Array of data used to execute swaps
    /// @param startIndex Start index used to execute swaps
    /// @param endIndex End index used to execute swaps
    /// @param deltaFromAmount Delta fromAmount used to execute swaps,
    /// @param deltaMinAmount Delta minAmount used to execute swaps,
    /// @param correctSwap Correct swap address
    function _executeSwapsInner(
        SoData memory soData,
        LibSwap.SwapData[] calldata swapData,
        uint256 startIndex,
        uint256 endIndex,
        uint256 deltaFromAmount,
        uint256 deltaMinAmount,
        address correctSwap
    )
        private
        returns (
            bool,
            uint256,
            uint256
        )
    {
        CacheSwapInnerParam memory cache;
        cache.currentSwapData = swapData[startIndex];
        cache.fromAmount = cache.currentSwapData.fromAmount;
        (cache.minAmount, ) = ICorrectSwap(correctSwap).fixMinAmount(
            swapData[endIndex - 1].callData,
            deltaMinAmount
        );
        cache.swapBalance = cache.currentSwapData.fromAmount + deltaFromAmount;

        for (uint256 i = startIndex; i < endIndex; i++) {
            if (i + 1 == endIndex && deltaMinAmount > 0) {
                (, cache.currentSwapData.callData) = ICorrectSwap(correctSwap)
                    .fixMinAmount(
                        cache.currentSwapData.callData,
                        deltaMinAmount
                    );
            }

            cache.currentSwapData.fromAmount = cache.swapBalance;
            cache.currentSwapData.callData = ICorrectSwap(correctSwap)
                .correctSwap(
                    cache.currentSwapData.callData,
                    cache.currentSwapData.fromAmount
                );

            cache.receivedToken = cache.currentSwapData.receivingAssetId;
            cache.swapBalance = LibAsset.getOwnBalance(cache.receivedToken);

            if (
                !(appStorage.dexAllowlist[cache.currentSwapData.approveTo] &&
                    appStorage.dexAllowlist[cache.currentSwapData.callTo] &&
                    appStorage.dexFuncSignatureAllowList[
                        bytes32(
                            LibUtil.getSlice(
                                cache.currentSwapData.callData,
                                0,
                                4
                            )
                        )
                    ])
            ) revert ContractCallNotAllowed();

            try
                this.libSwap(soData.transactionId, cache.currentSwapData)
            {} catch {
                return (false, cache.fromAmount, cache.minAmount);
            }

            cache.swapBalance =
                LibAsset.getOwnBalance(cache.receivedToken) -
                cache.swapBalance;

            if (i + 1 < swapData.length) {
                cache.currentSwapData = swapData[i + 1];
            }
        }
        return (true, cache.fromAmount, cache.minAmount);
    }

    /// @dev Executes swaps and checks that DEXs used are in the allowList
    /// @param soData So tracking data
    /// @param swapData Array of data used to execute swaps
    function _executeSwaps(
        SoData memory soData,
        LibSwap.SwapData[] calldata swapData
    ) private {
        address correctSwap = appStorage.correctSwapRouterSelectors;
        if (correctSwap == address(0)) revert NotSupportedSwapRouter();
        _executeSwapsInner(
            soData,
            swapData,
            0,
            swapData.length,
            0,
            0,
            correctSwap
        );
    }

    /// @dev Find swap slice
    /// @param swapData Array of data used to execute swaps
    function _findSwapSlice(LibSwap.SwapData[] calldata swapData)
        private
        returns (uint256[] memory)
    {
        address sendingAssetId = swapData[0].sendingAssetId;
        uint256 sliceLength = 0;
        for (uint256 i = 0; i < swapData.length; i++) {
            if (
                swapData[i].sendingAssetId == sendingAssetId &&
                swapData[i].fromAmount > 0
            ) {
                sliceLength += 1;
            }
        }

        uint256[] memory sliceIndex = new uint256[](sliceLength);
        uint256 index = 0;
        for (uint256 i = 0; i < swapData.length; i++) {
            if (
                swapData[i].sendingAssetId == sendingAssetId &&
                swapData[i].fromAmount > 0
            ) {
                sliceIndex[index] = i;
                index += 1;
            }
        }
        return sliceIndex;
    }

    /// @dev Executes swaps and checks that DEXs used are in the allowList. Support dynamic slice swap
    /// @param soData So tracking data
    /// @param swapData Array of data used to execute swaps
    function _executeSwapsV2(
        SoData memory soData,
        LibSwap.SwapData[] calldata swapData
    ) private {
        CacheSwapParam memory cache;
        cache.correctSwap = appStorage.correctSwapRouterSelectors;
        if (cache.correctSwap == address(0)) revert NotSupportedSwapRouter();
        cache.sliceIndex = _findSwapSlice(swapData);
        for (uint256 k = 0; k < cache.sliceIndex.length; k++) {
            cache.startIndex = cache.sliceIndex[k];
            if (k + 1 == cache.sliceIndex.length) {
                cache.endIndex = swapData.length;
            } else {
                cache.endIndex = cache.sliceIndex[k + 1];
            }
            (
                bool flag,
                uint256 fromAmount,
                uint256 minAmount
            ) = _executeSwapsInner(
                    soData,
                    swapData,
                    cache.startIndex,
                    cache.endIndex,
                    cache.deltaFromAmount,
                    cache.deltaMinAmount,
                    cache.correctSwap
                );
            if (!flag) {
                cache.deltaFromAmount += fromAmount;
                cache.deltaMinAmount += minAmount;
            } else {
                cache.deltaFromAmount = 0;
                cache.deltaMinAmount = 0;
            }
        }
    }
}

pragma solidity 0.8.13;

import "IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

interface ICorrectSwap {
    function correctSwap(bytes calldata, uint256)
        external
        pure
        returns (bytes memory);

    function fixMinAmount(bytes calldata, uint256)
        external
        view
        returns (uint256, bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {LibAsset, IERC20} from "LibAsset.sol";
import {LibUtil} from "LibUtil.sol";
import {InvalidContract} from "GenericErrors.sol";

library LibSwap {
    error NoSwapFromZeroBalance();

    struct SwapData {
        address callTo; // The swap address
        address approveTo; // The swap address
        address sendingAssetId; // The swap start token address
        address receivingAssetId; // The swap final token address
        uint256 fromAmount; // The swap start token amount
        bytes callData; // The swap callData
    }

    struct NormalizedSwapData {
        bytes callTo; // The swap address
        bytes approveTo; // The swap address
        bytes sendingAssetId; // The swap start token address
        bytes receivingAssetId; // The swap final token address
        uint256 fromAmount; // The swap start token amount
        bytes callData; // The swap callData
    }

    event AssetSwapped(
        bytes32 transactionId,
        address dex,
        address fromAssetId,
        address toAssetId,
        uint256 fromAmount,
        uint256 toAmount,
        uint256 timestamp
    );

    function swap(bytes32 transactionId, SwapData memory _swapData) internal {
        if (!LibAsset.isContract(_swapData.callTo)) revert InvalidContract();
        uint256 fromAmount = _swapData.fromAmount;
        if (fromAmount == 0) revert NoSwapFromZeroBalance();
        uint256 nativeValue = 0;
        address fromAssetId = _swapData.sendingAssetId;
        address toAssetId = _swapData.receivingAssetId;
        uint256 initialSendingAssetBalance = LibAsset.getOwnBalance(
            fromAssetId
        );
        uint256 initialReceivingAssetBalance = LibAsset.getOwnBalance(
            toAssetId
        );
        uint256 toDeposit = initialSendingAssetBalance < fromAmount
            ? fromAmount - initialSendingAssetBalance
            : 0;

        if (!LibAsset.isNativeAsset(fromAssetId)) {
            LibAsset.maxApproveERC20(
                IERC20(fromAssetId),
                _swapData.approveTo,
                fromAmount
            );
            if (toDeposit != 0) {
                LibAsset.transferFromERC20(
                    fromAssetId,
                    msg.sender,
                    address(this),
                    toDeposit
                );
            }
        } else {
            nativeValue = fromAmount;
        }

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory res) = _swapData.callTo.call{
            value: nativeValue
        }(_swapData.callData);
        if (!success) {
            string memory reason = LibUtil.getRevertMsg(res);
            revert(reason);
        }

        emit AssetSwapped(
            transactionId,
            _swapData.callTo,
            _swapData.sendingAssetId,
            toAssetId,
            fromAmount,
            LibAsset.getOwnBalance(toAssetId) - initialReceivingAssetBalance,
            block.timestamp
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "LibBytes.sol";

library LibUtil {
    using LibBytes for bytes;

    function getRevertMsg(bytes memory _res)
        internal
        pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_res.length < 68) return "Transaction reverted silently";
        bytes memory revertData = _res.slice(4, _res.length - 4); // Remove the selector which is the first 4 bytes
        return abi.decode(revertData, (string)); // All that remains is the revert string
    }

    function getSlice(
        bytes memory _data,
        uint256 _start,
        uint256 _end
    ) internal pure returns (bytes memory) {
        require(_start < _end && _end <= _data.length, "DataLength error!");
        bytes memory _out = bytes("");
        for (uint256 i = _start; i < _end; i++) {
            _out = bytes.concat(_out, _data[i]);
        }
        return _out;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

library LibBytes {
    // solhint-disable no-inline-assembly

    function concat(bytes memory _preBytes, bytes memory _postBytes)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(
                0x40,
                and(
                    add(add(end, iszero(add(length, mload(_preBytes)))), 31),
                    not(31) // Round down to the nearest 32 bytes.
                )
            )
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes)
        internal
    {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(
                and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)),
                2
            )
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function indexOf(
        bytes memory _bytes,
        uint8 _e,
        uint256 _start
    ) internal pure returns (uint256) {
        while (_start < _bytes.length) {
            if (toUint8(_bytes, _start) == _e) {
                return _start;
            }
            _start += 1;
        }
        return _bytes.length;
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(
                    add(tempBytes, lengthmod),
                    mul(0x20, iszero(lengthmod))
                )
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(
                        add(
                            add(_bytes, lengthmod),
                            mul(0x20, iszero(lengthmod))
                        ),
                        _start
                    )
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (address)
    {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(
                mload(add(add(_bytes, 0x20), _start)),
                0x1000000000000000000000000
            )
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint8)
    {
        require(_bytes.length >= _start + 1, "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint16)
    {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint32)
    {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint64)
    {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint96)
    {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint128)
    {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint256)
    {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (bytes32)
    {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes)
        internal
        pure
        returns (bool)
    {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                    // the next line is the loop condition:
                    // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(bytes storage _preBytes, bytes memory _postBytes)
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(
                and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)),
                2
            )
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        // solhint-disable-next-line no-empty-blocks
                        for {

                        } eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

struct LibStorage {
    mapping(address => bool) dexAllowlist;
    mapping(bytes32 => bool) dexFuncSignatureAllowList;
    address[] dexs;
    // maps gateway facet addresses to sofee address
    mapping(address => address) gatewaySoFeeSelectors;
    // Storage correct swap address
    address correctSwapRouterSelectors;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {ISo} from "ISo.sol";
import {LibSwap} from "LibSwap.sol";
import {LibBytes} from "LibBytes.sol";

library LibCross {
    using LibBytes for bytes;

    function normalizeSoData(ISo.SoData memory soData)
        internal
        pure
        returns (ISo.NormalizedSoData memory)
    {
        ISo.NormalizedSoData memory data;
        data.transactionId = abi.encodePacked(soData.transactionId);
        data.receiver = abi.encodePacked(soData.receiver);
        data.sourceChainId = soData.sourceChainId;
        data.sendingAssetId = abi.encodePacked(soData.sendingAssetId);
        data.destinationChainId = soData.destinationChainId;
        data.receivingAssetId = abi.encodePacked(soData.receivingAssetId);
        data.amount = soData.amount;

        return data;
    }

    function tryAddress(bytes memory data) internal pure returns (address) {
        if (data.length == 20) {
            return data.toAddress(0);
        } else {
            return address(0);
        }
    }

    function denormalizeSoData(ISo.NormalizedSoData memory data)
        internal
        pure
        returns (ISo.SoData memory)
    {
        return
            ISo.SoData({
                transactionId: data.transactionId.toBytes32(0),
                receiver: payable(tryAddress(data.receiver)),
                sourceChainId: data.sourceChainId,
                sendingAssetId: tryAddress(data.sendingAssetId),
                destinationChainId: data.destinationChainId,
                receivingAssetId: tryAddress(data.receivingAssetId),
                amount: data.amount
            });
    }

    function normalizeSwapData(LibSwap.SwapData[] memory swapData)
        internal
        pure
        returns (LibSwap.NormalizedSwapData[] memory)
    {
        LibSwap.NormalizedSwapData[]
            memory data = new LibSwap.NormalizedSwapData[](swapData.length);

        for (uint256 i = 0; i < swapData.length; i++) {
            data[i].callTo = abi.encodePacked(swapData[i].callTo);
            data[i].approveTo = abi.encodePacked(swapData[i].approveTo);
            data[i].sendingAssetId = abi.encodePacked(
                swapData[i].sendingAssetId
            );
            data[i].receivingAssetId = abi.encodePacked(
                swapData[i].receivingAssetId
            );
            data[i].fromAmount = swapData[i].fromAmount;
            data[i].callData = abi.encodePacked(swapData[i].callData);
        }

        return data;
    }

    function denormalizeSwapData(LibSwap.NormalizedSwapData[] memory data)
        internal
        pure
        returns (LibSwap.SwapData[] memory)
    {
        LibSwap.SwapData[] memory swapData = new LibSwap.SwapData[](
            data.length
        );
        for (uint256 i = 0; i < swapData.length; i++) {
            swapData[i].callTo = data[i].callTo.toAddress(0);
            swapData[i].approveTo = data[i].approveTo.toAddress(0);
            swapData[i].sendingAssetId = data[i].sendingAssetId.toAddress(0);
            swapData[i].receivingAssetId = data[i].receivingAssetId.toAddress(
                0
            );
            swapData[i].fromAmount = data[i].fromAmount;
            swapData[i].callData = data[i].callData;
        }
        return swapData;
    }

    function encodeNormalizedSoData(ISo.NormalizedSoData memory data)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory encodeData = abi.encodePacked(
            uint64(data.transactionId.length),
            data.transactionId,
            uint64(data.receiver.length),
            data.receiver,
            data.sourceChainId
        );
        // Avoid variable value1 is 1 slot(s) too deep;
        encodeData = encodeData.concat(
            abi.encodePacked(
                uint64(data.sendingAssetId.length),
                data.sendingAssetId,
                data.destinationChainId,
                uint64(data.receivingAssetId.length),
                data.receivingAssetId,
                data.amount
            )
        );
        return encodeData;
    }

    function decodeNormalizedSoData(bytes memory soData)
        internal
        pure
        returns (ISo.NormalizedSoData memory)
    {
        ISo.NormalizedSoData memory data;
        uint256 index;
        uint256 nextLen;

        nextLen = uint256(soData.toUint64(index));
        index += 8;
        data.transactionId = soData.slice(index, nextLen);
        index += nextLen;

        nextLen = uint256(soData.toUint64(index));
        index += 8;
        data.receiver = soData.slice(index, nextLen);
        index += nextLen;

        nextLen = 2;
        data.sourceChainId = soData.toUint16(index);
        index += nextLen;

        nextLen = uint256(soData.toUint64(index));
        index += 8;
        data.sendingAssetId = soData.slice(index, nextLen);
        index += nextLen;

        nextLen = 2;
        data.destinationChainId = soData.toUint16(index);
        index += nextLen;

        nextLen = uint256(soData.toUint64(index));
        index += 8;
        data.receivingAssetId = soData.slice(index, nextLen);
        index += nextLen;

        nextLen = 32;
        data.amount = soData.toUint256(index);
        index += nextLen;

        require(index == soData.length, "Length error");

        return data;
    }

    function encodeNormalizedSwapData(LibSwap.NormalizedSwapData[] memory data)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory encodeData = bytes("");

        if (data.length > 0) {
            encodeData = abi.encodePacked(uint64(data.length));
        }

        for (uint256 i = 0; i < data.length; i++) {
            encodeData = encodeData.concat(
                abi.encodePacked(
                    uint64(data[i].callTo.length),
                    data[i].callTo,
                    uint64(data[i].approveTo.length),
                    data[i].approveTo,
                    uint64(data[i].sendingAssetId.length),
                    data[i].sendingAssetId
                )
            );
            // Avoid variable value1 is 1 slot(s) too deep;
            encodeData = encodeData.concat(
                abi.encodePacked(
                    uint64(data[i].receivingAssetId.length),
                    data[i].receivingAssetId,
                    data[i].fromAmount,
                    uint64(data[i].callData.length),
                    data[i].callData
                )
            );
        }

        return encodeData;
    }

    function decodeNormalizedSwapData(bytes memory swapData)
        internal
        pure
        returns (LibSwap.NormalizedSwapData[] memory)
    {
        uint256 index;
        uint256 nextLen;

        nextLen = 8;
        uint256 swapLen = uint256(swapData.toUint64(index));
        index += nextLen;

        LibSwap.NormalizedSwapData[]
            memory data = new LibSwap.NormalizedSwapData[](swapLen);

        for (uint256 i = 0; i < swapLen; i++) {
            nextLen = uint256(swapData.toUint64(index));
            index += 8;
            data[i].callTo = swapData.slice(index, nextLen);
            index += nextLen;

            nextLen = uint256(swapData.toUint64(index));
            index += 8;
            data[i].approveTo = swapData.slice(index, nextLen);
            index += nextLen;

            nextLen = uint256(swapData.toUint64(index));
            index += 8;
            data[i].sendingAssetId = swapData.slice(index, nextLen);
            index += nextLen;

            nextLen = uint256(swapData.toUint64(index));
            index += 8;
            data[i].receivingAssetId = swapData.slice(index, nextLen);
            index += nextLen;

            nextLen = 32;
            data[i].fromAmount = swapData.toUint256(index);
            index += nextLen;

            nextLen = uint256(swapData.toUint64(index));
            index += 8;
            data[i].callData = swapData.slice(index, nextLen);
            index += nextLen;
        }

        require(index == swapData.length, "Length error");

        return data;
    }

    function serializeU256WithHexStr(uint256 data)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory encodeData = abi.encodePacked(uint8(data & 0xFF));
        data = data >> 8;

        while (data != 0) {
            encodeData = abi.encodePacked(uint8(data & 0xFF)).concat(
                encodeData
            );
            data = data >> 8;
        }
        return encodeData;
    }

    function deserializeU256WithHexStr(bytes memory data)
        internal
        pure
        returns (uint256)
    {
        uint256 buf = 0;
        for (uint256 i = 0; i < data.length; i++) {
            buf = (buf << 8) + data.toUint8(i);
        }
        return buf;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

interface ILibSoFeeV2 {
    function getFees(uint256 _amount) external view returns (uint256 s);

    function getRestoredAmount(uint256 _amount)
        external
        view
        returns (uint256 r);

    function getTransferForGas() external view returns (uint256);

    function getVersion() external view returns (string memory);

    function getBasicBeneficiary() external view returns (address);

    function getBasicFee() external view returns (uint256);
}