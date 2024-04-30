// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
pragma solidity ^0.8.0;

import "./Errors.sol";

abstract contract BebopPartner {

    struct PartnerInfo {
        uint16 fee;
        address beneficiary;
        bool registered;
    }
    mapping(uint64 => PartnerInfo) public partners;
    uint16 internal constant HUNDRED_PERCENT = 10000;

    constructor(){
        partners[0].registered = true;
    }


    /// @notice Register new partner
    /// @param partnerId the unique identifier for this partner
    /// @param fee the additional fee to add to each swap from this partner
    /// @param beneficiary the address to send the partner's share of fees to
    function registerPartner(uint64 partnerId, uint16 fee, address beneficiary) external {
        if(partners[partnerId].registered) revert PartnerAlreadyRegistered();
        if(fee > HUNDRED_PERCENT) revert PartnerFeeTooHigh();
        if (beneficiary == address(0)) revert NullBeneficiary();
        partners[partnerId] = PartnerInfo(fee, beneficiary, true);
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libs/Order.sol";
import "../libs/Signature.sol";
import "../libs/common/BytesLib.sol";
import "./Errors.sol";
import "lib/openzeppelin-contracts/contracts/interfaces/IERC1271.sol";
import "../libs/Transfer.sol";

abstract contract BebopSigning {

    event OrderSignerRegistered(address maker, address signer, bool allowed);

    bytes32 private constant DOMAIN_NAME = keccak256("BebopSettlement");
    bytes32 private constant DOMAIN_VERSION = keccak256("2");

    // bytes4(keccak256("isValidSignature(bytes32,bytes)"))
    bytes4 private constant EIP1271_MAGICVALUE = 0x1626ba7e;

    uint256 private constant ETH_SIGN_HASH_PREFIX = 0x19457468657265756d205369676e6564204d6573736167653a0a333200000000;

    /// @dev This value is pre-computed from the following expression
    /// keccak256(abi.encodePacked(
    ///   "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    /// ));
    bytes32 private constant EIP712_DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    /// @dev This value is pre-computed from the following expression
    /// keccak256(abi.encodePacked(
    ///   "AggregateOrder(uint64 partner_id,uint256 expiry,address taker_address,address[] maker_addresses,uint256[] maker_nonces,address[][] taker_tokens,address[][] maker_tokens,uint256[][] taker_amounts,uint256[][] maker_amounts,address receiver,bytes commands)"
    /// ));
    bytes32 private constant AGGREGATED_ORDER_TYPE_HASH = 0xe850f4ac05cb765eff6f120037e6d3286f8f71aaedad7f9f242af69d53091265;

    /// @dev This value is pre-computed from the following expression
    /// keccak256(abi.encodePacked(
    ///   "MultiOrder(uint64 partner_id,uint256 expiry,address taker_address,address maker_address,uint256 maker_nonce,address[] taker_tokens,address[] maker_tokens,uint256[] taker_amounts,uint256[] maker_amounts,address receiver,bytes commands)"
    /// ));
    bytes32 private constant MULTI_ORDER_TYPE_HASH = 0x34728ce057ec73e3b4f0871dced9cc875f5b1aece9fd07891e156fe852a858d9;

    /// @dev This value is pre-computed from the following expression
    /// keccak256(abi.encodePacked(
    ///   "SingleOrder(uint64 partner_id,uint256 expiry,address taker_address,address maker_address,uint256 maker_nonce,address taker_token,address maker_token,uint256 taker_amount,uint256 maker_amount,address receiver,uint256 packed_commands)"
    /// ));
    bytes32 private constant SINGLE_ORDER_TYPE_HASH = 0xe34225bc7cd92038d42c258ee3ff66d30f9387dd932213ba32a52011df0603fc;

    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    mapping(address => mapping(uint256 => uint256)) private makerNonceValidator;
    mapping(address => mapping(address => bool)) private orderSignerRegistry;

    constructor(){
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = keccak256(
            abi.encode(EIP712_DOMAIN_TYPEHASH, DOMAIN_NAME, DOMAIN_VERSION, block.chainid, address(this))
        );
    }

    /// @notice The domain separator used in the order validation signature
    /// @return The domain separator hash
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return block.chainid == _CACHED_CHAIN_ID
            ? _CACHED_DOMAIN_SEPARATOR
            : keccak256(
                abi.encode(EIP712_DOMAIN_TYPEHASH, DOMAIN_NAME, DOMAIN_VERSION, block.chainid, address(this))
            );
    }

    /// @notice Register another order signer for a maker
    /// @param signer The address of the additional signer
    /// @param allowed Whether the signer is allowed to sign orders for the maker
    function registerAllowedOrderSigner(address signer, bool allowed) external {
        orderSignerRegistry[msg.sender][signer] = allowed;
        emit OrderSignerRegistered(msg.sender, signer, allowed);
    }

    /// @notice Hash partnerId + Order.Single struct without `flags` field
    /// @param order Order.Single struct
    /// @param partnerId Unique partner identifier, 0 for no partner
    /// @param updatedMakerAmount Updated maker amount, 0 for no update
    /// @param updatedMakerNonce Updated maker nonce, 0 for no update
    /// @return The hash of the order
    function hashSingleOrder(
        Order.Single calldata order, uint64 partnerId, uint256 updatedMakerAmount, uint256 updatedMakerNonce
    ) public view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), keccak256(
            abi.encode(
                SINGLE_ORDER_TYPE_HASH, partnerId, order.expiry, order.taker_address, order.maker_address,
                updatedMakerNonce != 0 ? updatedMakerNonce : order.maker_nonce, order.taker_token, order.maker_token,
                order.taker_amount, updatedMakerAmount != 0 ? updatedMakerAmount : order.maker_amount, order.receiver,
                order.packed_commands
            )
        )));
    }

    /// @notice Hash partnerId + Order.Multi struct without `flags` field
    /// @param order Order.Multi struct
    /// @param partnerId Unique partner identifier, 0 for no partner
    /// @param updatedMakerAmounts Updated maker amounts, it replaces order.maker_amounts
    /// @param updatedMakerNonce Updated maker nonce, it replaces order.maker_nonce
    /// @return The hash of the order
    function hashMultiOrder(
        Order.Multi memory order, uint64 partnerId, uint256[] calldata updatedMakerAmounts, uint256 updatedMakerNonce
    ) public view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), keccak256(
            abi.encode(
                MULTI_ORDER_TYPE_HASH, partnerId, order.expiry, order.taker_address, order.maker_address, updatedMakerNonce,
                keccak256(abi.encodePacked(order.taker_tokens)), keccak256(abi.encodePacked(order.maker_tokens)),
                keccak256(abi.encodePacked(order.taker_amounts)), keccak256(abi.encodePacked(updatedMakerAmounts)),
                order.receiver, keccak256(order.commands)
            )
        )));
    }

    /// @notice Hash partnerId + Order.Aggregate struct without `flags` field
    /// @param order Order.Aggregate struct
    /// @param partnerId Unique partner identifier, 0 for no partner
    /// @param updatedMakerAmounts Updated maker amounts, it replaces order.maker_amounts
    /// @param updatedMakerNonces Updated maker nonces, it replaces order.maker_nonces
    /// @return The hash of the order
    function hashAggregateOrder(
        Order.Aggregate calldata order, uint64 partnerId, uint256[][] calldata updatedMakerAmounts, uint256[] calldata updatedMakerNonces
    ) public view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), keccak256(
            abi.encode(
                AGGREGATED_ORDER_TYPE_HASH, partnerId, order.expiry, order.taker_address,
                keccak256(abi.encodePacked(order.maker_addresses)), keccak256(abi.encodePacked(updatedMakerNonces)),
                keccak256(_encodeTightlyPackedNested(order.taker_tokens)), keccak256(_encodeTightlyPackedNested(order.maker_tokens)),
                keccak256(_encodeTightlyPackedNestedInt(order.taker_amounts)), keccak256(_encodeTightlyPackedNestedInt(updatedMakerAmounts)),
                order.receiver, keccak256(order.commands)
            )
        )));
    }

    /// @notice Validate the order signature
    /// @param validationAddress The address to validate the signature against
    /// @param hash The hash of the order
    /// @param signature The signature to validate
    /// @param signatureType The type of the signature
    /// @param isMaker Whether external signer from orderSignerRegistry is allowed or not
    function _validateSignature(
        address validationAddress, bytes32 hash, bytes calldata signature, Signature.Type signatureType, bool isMaker
    ) internal view {
        if (signatureType == Signature.Type.EIP712) {
            (bytes32 r, bytes32 s, uint8 v) = Signature.getRsv(signature);
            address signer = ecrecover(hash, v, r, s);
            if (signer == address(0)) revert OrderInvalidSigner();
            if (signer != validationAddress && (!isMaker || !orderSignerRegistry[validationAddress][signer])) {
                revert InvalidEIP721Signature();
            }
        } else if (signatureType == Signature.Type.EIP1271) {
            if (IERC1271(validationAddress).isValidSignature(hash, signature) != EIP1271_MAGICVALUE){
                revert InvalidEIP1271Signature();
            }
        } else if (signatureType == Signature.Type.ETHSIGN) {
            bytes32 ethSignHash;
            assembly {
                mstore(0, ETH_SIGN_HASH_PREFIX)
                mstore(28, hash)
                ethSignHash := keccak256(0, 60)
            }
            (bytes32 r, bytes32 s, uint8 v) = Signature.getRsv(signature);
            address signer = ecrecover(ethSignHash, v, r, s);
            if (signer == address(0)) revert OrderInvalidSigner();
            if (signer != validationAddress && (!isMaker || !orderSignerRegistry[validationAddress][signer])) {
                revert InvalidETHSIGNSignature();
            }
        } else {
            revert InvalidSignatureType();
        }
    }

    /// @notice Pack 2D array of integers into tightly packed bytes for hashing
    function _encodeTightlyPackedNestedInt(uint256[][] calldata _nested_array) private pure returns (bytes memory encoded) {
        uint nested_array_length = _nested_array.length;
        for (uint i; i < nested_array_length; ++i) {
            encoded = abi.encodePacked(encoded, keccak256(abi.encodePacked(_nested_array[i])));
        }
        return encoded;
    }

    /// @notice Pack 2D array of addresses into tightly packed bytes for hashing
    function _encodeTightlyPackedNested(address[][] calldata _nested_array) private pure returns (bytes memory encoded) {
        uint nested_array_length = _nested_array.length;
        for (uint i; i < nested_array_length; ++i) {
            encoded = abi.encodePacked(encoded, keccak256(abi.encodePacked(_nested_array[i])));
        }
        return encoded;
    }

    /// @notice Check maker nonce and invalidate it
    function _invalidateOrder(address maker, uint256 nonce) private {
        if (nonce == 0) revert ZeroNonce();
        uint256 invalidatorSlot = nonce >> 8;
        uint256 invalidatorBit = 1 << (nonce & 0xff);
        mapping(uint256 => uint256) storage invalidatorStorage = makerNonceValidator[maker];
        uint256 invalidator = invalidatorStorage[invalidatorSlot];
        if (invalidator & invalidatorBit == invalidatorBit) revert InvalidNonce();
        invalidatorStorage[invalidatorSlot] = invalidator | invalidatorBit;
    }

    /// @notice Validate maker signature and SingleOrder fields
    function _validateSingleOrder(
        Order.Single calldata order,
        Signature.MakerSignature calldata makerSignature
    ) internal {
        (, Signature.Type signatureType) = Signature.extractMakerFlags(makerSignature.flags);
        _validateSignature(
            order.maker_address, hashSingleOrder(order, Order.extractPartnerId(order.flags), 0, 0),
            makerSignature.signatureBytes, signatureType, true
        );
        _invalidateOrder(order.maker_address, order.maker_nonce);
        if (order.expiry <= block.timestamp) revert OrderExpired();
    }

    /// @notice Validate maker signature and MultiOrder fields
    function _validateMultiOrder(
        Order.Multi calldata order,
        Signature.MakerSignature calldata makerSignature,
        uint256 filledTakerAmount
    ) internal {
        (, Signature.Type signatureType) = Signature.extractMakerFlags(makerSignature.flags);
        _validateSignature(
            order.maker_address,
            hashMultiOrder(order, Order.extractPartnerId(order.flags), order.maker_amounts, order.maker_nonce),
            makerSignature.signatureBytes, signatureType, true
        );
        _invalidateOrder(order.maker_address, order.maker_nonce);
        if (
            order.taker_tokens.length != order.taker_amounts.length || order.maker_tokens.length != order.maker_amounts.length
        ) revert TokensLengthsMismatch();
        if (order.commands.length != order.taker_tokens.length + order.maker_tokens.length) revert InvalidCommandsLength();
        if (order.taker_tokens.length != 1 && order.maker_tokens.length != 1) revert ManyToManyNotSupported();
        if (order.taker_tokens.length > 1 && filledTakerAmount != 0){
            /// @dev Partial fill is not supported for many-to-one orders, so filledTakerAmount should be 0
            revert PartialFillNotSupported();
        }
        if (order.expiry <= block.timestamp) revert OrderExpired();
    }

    /// @notice Validate makers signatures and AggregateOrder fields
    function _validateAggregateOrder(
        Order.Aggregate calldata order,
        Signature.MakerSignature[] calldata makersSignatures
    ) internal {
        uint makersNum = makersSignatures.length;
        if (
            order.maker_addresses.length != makersNum || order.maker_nonces.length != makersNum
            || order.taker_tokens.length != makersNum || order.maker_tokens.length != makersNum
            || order.taker_amounts.length != makersNum || order.maker_amounts.length != makersNum
        ) revert OrdersLengthsMismatch();
        uint tokenTransfers;
        for (uint i; i < makersNum; ++i) {
            if (order.maker_tokens[i].length != order.maker_amounts[i].length
                || order.taker_tokens[i].length != order.taker_amounts[i].length)
                revert TokensLengthsMismatch();
            Order.Multi memory partialAggregateOrder = Order.Multi(
                order.expiry, order.taker_address, order.maker_addresses[i], order.maker_nonces[i],
                order.taker_tokens[i], order.maker_tokens[i], order.taker_amounts[i], order.maker_amounts[i],
                order.receiver, BytesLib.slice(
                    order.commands, tokenTransfers, order.maker_tokens[i].length + order.taker_tokens[i].length
                ), 0
            );
            bytes32 multiOrderHash = hashMultiOrder(
                partialAggregateOrder, Order.extractPartnerId(order.flags), order.maker_amounts[i], order.maker_nonces[i]
            );

            (, Signature.Type signatureType) = Signature.extractMakerFlags(makersSignatures[i].flags);
            _validateSignature(
                order.maker_addresses[i], multiOrderHash, makersSignatures[i].signatureBytes, signatureType, true
            );
            _invalidateOrder(order.maker_addresses[i], order.maker_nonces[i]);
            tokenTransfers += order.maker_tokens[i].length + order.taker_tokens[i].length;
        }
        if (tokenTransfers != order.commands.length) revert CommandsLengthsMismatch();
        if (order.expiry <= block.timestamp) revert OrderExpired();
    }

    /// @notice Validate taker signature for SingleOrder
    function _validateTakerSignatureForSingleOrder(
        Order.Single calldata order, bytes calldata takerSignature, Transfer.OldSingleQuote calldata takerQuoteInfo
    ) internal {
        if (order.maker_amount < takerQuoteInfo.makerAmount) revert UpdatedMakerAmountsTooLow();
        if (takerQuoteInfo.makerAmount == 0) revert ZeroMakerAmount();
        if (takerQuoteInfo.makerNonce != order.maker_nonce){
            _invalidateOrder(order.maker_address, takerQuoteInfo.makerNonce);
        }
        if (msg.sender != order.taker_address){
            Signature.Type signatureType = Order.extractSignatureType(order.flags);
            _validateSignature(
                order.taker_address,
                hashSingleOrder(order, Order.extractPartnerId(order.flags), takerQuoteInfo.makerAmount, takerQuoteInfo.makerNonce),
                takerSignature, signatureType, false
            );
        }
    }

    /// @notice Validate taker signature for MultiOrder
    function _validateTakerSignatureForMultiOrder(
        Order.Multi calldata order, bytes calldata takerSignature, Transfer.OldMultiQuote calldata takerQuoteInfo
    ) internal {
        if (takerQuoteInfo.makerAmounts.length != order.maker_amounts.length) revert MakerAmountsLengthsMismatch();
        for (uint i; i < takerQuoteInfo.makerAmounts.length; ++i){
            if (takerQuoteInfo.makerAmounts[i] == 0) revert ZeroMakerAmount();
            if (order.maker_amounts[i] < takerQuoteInfo.makerAmounts[i]) revert UpdatedMakerAmountsTooLow();
        }
        if (takerQuoteInfo.makerNonce != order.maker_nonce){
            _invalidateOrder(order.maker_address, takerQuoteInfo.makerNonce);
        }
        if (msg.sender != order.taker_address){
            Signature.Type signatureType = Order.extractSignatureType(order.flags);
            _validateSignature(
                order.taker_address,
                hashMultiOrder(order, Order.extractPartnerId(order.flags), takerQuoteInfo.makerAmounts, takerQuoteInfo.makerNonce),
                takerSignature, signatureType, false
            );
        }
    }

    /// @notice Validate taker signature for AggregateOrder
    function _validateTakerSignatureForAggregateOrder(
        Order.Aggregate calldata order, bytes calldata takerSignature, Transfer.OldAggregateQuote calldata takerQuoteInfo
    ) internal {
        if (takerQuoteInfo.makerAmounts.length != order.maker_amounts.length) revert MakerAmountsLengthsMismatch();
        for (uint i; i < order.maker_amounts.length; ++i){
            if (takerQuoteInfo.makerAmounts[i].length != order.maker_amounts[i].length) revert MakerAmountsLengthsMismatch();
            for (uint j; j < order.maker_amounts[i].length; ++j){
                if (order.maker_amounts[i][j] < takerQuoteInfo.makerAmounts[i][j]) revert UpdatedMakerAmountsTooLow();
            }
            if (takerQuoteInfo.makerNonces[i] != order.maker_nonces[i]){
                _invalidateOrder(order.maker_addresses[i], takerQuoteInfo.makerNonces[i]);
            }
        }
        if (msg.sender != order.taker_address){
            Signature.Type signatureType = Order.extractSignatureType(order.flags);
            _validateSignature(
                order.taker_address,
                hashAggregateOrder(order, Order.extractPartnerId(order.flags), takerQuoteInfo.makerAmounts, takerQuoteInfo.makerNonces),
                takerSignature, signatureType, false
            );
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interface/IDaiLikePermit.sol";
import "../interface/IPermit2.sol";
import "../interface/IWETH.sol";
import "../libs/Order.sol";
import "../libs/Signature.sol";
import "../libs/Transfer.sol";
import "../libs/Commands.sol";
import "../libs/common/SafeCast160.sol";
import "./BebopSigning.sol";
import "./BebopPartner.sol";
import "./Errors.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract BebopTransfer is BebopPartner {

    using SafeERC20 for IERC20;

    address internal immutable WRAPPED_NATIVE_TOKEN;
    address internal immutable DAI_TOKEN;

    IPermit2 internal immutable PERMIT2;

    uint private immutable _chainId;

    function _getChainId() private view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    constructor(address _wrappedNativeToken, address _permit2, address _daiAddress) {
        WRAPPED_NATIVE_TOKEN = _wrappedNativeToken;
        DAI_TOKEN = _daiAddress;
        PERMIT2 = IPermit2(_permit2);
        _chainId = _getChainId();
    }

    /// @notice Validates that partial fill is allowed and extract necessary information from Aggregate order
    /// @return quoteTakerAmount - full taker_amount for One-to-One or One-to-Many trades, for Many-to-One orders it's 0
    /// @return lenInfo - lengths of `pendingTransfers` and `batchTransferDetails` arrays
    function _getAggregateOrderInfo(
        Order.Aggregate calldata order,
        uint256 filledTakerAmount
    ) internal pure returns (uint quoteTakerAmount, Transfer.LengthsInfo memory lenInfo){
        uint commandsInd;
        address tokenAddress = order.taker_tokens[0][0];
        for (uint i; i < order.taker_tokens.length; ++i){
            commandsInd += order.maker_tokens[i].length;
            for (uint j; j < order.taker_tokens[i].length; ++j) {
                bytes1 curCommand = order.commands[commandsInd + j];
                if (curCommand != Commands.TRANSFER_FROM_CONTRACT){
                    if (filledTakerAmount > 0){
                        /// @dev partial fills works only for One-to-One or One-to-Many trades,
                        /// filledTakerAmount is partially filled amount of taker's token,
                        /// so filledTakerAmount should be 0 for Many-to-One orders and orders without partial fills
                        quoteTakerAmount += order.taker_amounts[i][j];
                        if (tokenAddress != order.taker_tokens[i][j]){
                            revert PartialFillNotSupported();
                        }
                    }
                    if (curCommand == Commands.NATIVE_TRANSFER) {
                        ++lenInfo.pendingTransfersLen;
                    } else if (curCommand == Commands.PERMIT2_TRANSFER || curCommand == Commands.CALL_PERMIT2_THEN_TRANSFER) {
                        ++lenInfo.permit2Len;
                    }
                } else {
                    ++lenInfo.pendingTransfersLen;
                }
            }
            commandsInd += order.taker_tokens[i].length;
        }
    }

    /// @notice Universal function for transferring tokens
    /// @param from address from which tokens will be transferred
    /// @param to address to which tokens will be transferred
    /// @param token address of token
    /// @param amount amount of token
    /// @param command Commands to indicate how to transfer token
    /// @param action Wrap or Unwrap native token
    /// @param partnerId identifier of partner to pay referral fee
    function _transferToken(
        address from, address to, address token, uint256 amount, bytes1 command, Transfer.Action action, uint64 partnerId
    ) internal {
        if (action == Transfer.Action.Wrap){
            if (token != WRAPPED_NATIVE_TOKEN) revert WrongWrappedTokenAddress();
            IWETH(WRAPPED_NATIVE_TOKEN).deposit{value: amount}();
        }
        uint fee;
        PartnerInfo memory partnerInfo;
        if (partnerId != 0){
            partnerInfo = partners[partnerId];
            if (partnerInfo.registered && partnerInfo.fee > 0){
                fee = amount * partnerInfo.fee / HUNDRED_PERCENT;
            }
        }
        address receiver = action == Transfer.Action.Unwrap ? address(this) : to;
        if (command == Commands.SIMPLE_TRANSFER || command == Commands.CALL_PERMIT_THEN_TRANSFER){
            if (fee > 0){
                IERC20(token).safeTransferFrom(from, partnerInfo.beneficiary, fee);
                amount -= fee;
            }
            IERC20(token).safeTransferFrom(from, receiver, amount);
        } else if (command == Commands.PERMIT2_TRANSFER || command == Commands.CALL_PERMIT2_THEN_TRANSFER){
            if (fee > 0){
                amount -= fee;
                IPermit2.AllowanceTransferDetails[] memory batchTransferDetails = new IPermit2.AllowanceTransferDetails[](2);
                batchTransferDetails[0] = IPermit2.AllowanceTransferDetails(from, partnerInfo.beneficiary, SafeCast160.toUint160(fee), token);
                batchTransferDetails[1] = IPermit2.AllowanceTransferDetails(from, receiver, SafeCast160.toUint160(amount), token);
                PERMIT2.transferFrom(batchTransferDetails);
            } else {
                PERMIT2.transferFrom(from, receiver, SafeCast160.toUint160(amount), token);
            }
        } else if (command == Commands.TRANSFER_FROM_CONTRACT || command == Commands.NATIVE_TRANSFER){
            IERC20(token).safeTransfer(to, amount);
        } else {
            revert InvalidCommand();
        }
        if (action == Transfer.Action.Unwrap){
            if (token != WRAPPED_NATIVE_TOKEN) revert WrongWrappedTokenAddress();
            IWETH(WRAPPED_NATIVE_TOKEN).withdraw(amount);
            (bool sent,) = to.call{value: amount}("");
            if (!sent) revert FailedToSendNativeToken();
        }
    }

    /// @notice For MultiOrder transfer taker's tokens to maker
    /// @param order MultiOrder
    function _transferTakerTokens(Order.Multi calldata order) internal {
        IPermit2.AllowanceTransferDetails[] memory batchTransferDetails;
        uint permit2Ind;
        for (uint i; i < order.taker_tokens.length; ++i) {
            bytes1 command = order.commands[i + order.maker_tokens.length];
            if (command == Commands.SIMPLE_TRANSFER || command == Commands.CALL_PERMIT_THEN_TRANSFER){
                IERC20(order.taker_tokens[i]).safeTransferFrom(
                    order.taker_address, order.maker_address, order.taker_amounts[i]
                );
            } else if (command == Commands.PERMIT2_TRANSFER || command == Commands.CALL_PERMIT2_THEN_TRANSFER){
                if (batchTransferDetails.length == 0){
                    batchTransferDetails = new IPermit2.AllowanceTransferDetails[](order.taker_tokens.length - i);
                }
                batchTransferDetails[permit2Ind++] = IPermit2.AllowanceTransferDetails({
                    from: order.taker_address,
                    to: order.maker_address,
                    amount: SafeCast160.toUint160(order.taker_amounts[i]),
                    token: order.taker_tokens[i]
                });
                continue;
            } else if (command == Commands.NATIVE_TRANSFER) {
                if (order.taker_tokens[i] != WRAPPED_NATIVE_TOKEN) revert WrongWrappedTokenAddress();
                IWETH(WRAPPED_NATIVE_TOKEN).deposit{value: order.taker_amounts[i]}();
                IERC20(WRAPPED_NATIVE_TOKEN).safeTransfer(order.maker_address, order.taker_amounts[i]);
            } else {
                revert InvalidCommand();
            }
            if (batchTransferDetails.length > 0){
                assembly {mstore(batchTransferDetails, sub(mload(batchTransferDetails), 1))}
            }
        }
        if (batchTransferDetails.length > 0){
            PERMIT2.transferFrom(batchTransferDetails);
        }
    }

    /// @notice Transfer tokens from maker to taker
    /// @param from maker_address from which tokens will be transferred
    /// @param to taker_address to which tokens will be transferred
    /// @param maker_tokens addresses of tokens
    /// @param maker_amounts amounts of tokens
    /// @param usingPermit2 indicates whether maker is Permit2 for transfers or not
    /// @param makerCommands commands to indicate how to transfer tokens
    /// @param partnerId identifier of partner to pay referral fee
    /// @return nativeToTaker amount of native token to transfer to taker
    function _transferMakerTokens(
        address from,
        address to,
        address[] calldata maker_tokens,
        uint256[] memory maker_amounts,
        bool usingPermit2,
        bytes memory makerCommands,
        uint64 partnerId
    ) internal returns (uint256) {
        uint256 nativeToTaker;
        IPermit2.AllowanceTransferDetails[] memory batchTransferDetails;
        uint batchInd;

        bool hasPartnerFee = partnerId != 0;
        PartnerInfo memory partnerInfo;
        if (hasPartnerFee){
            partnerInfo = partners[partnerId];
            hasPartnerFee = partnerInfo.registered && partnerInfo.fee > 0;
        }

        for (uint j; j < maker_tokens.length; ++j) {
            uint256 amount = maker_amounts[j];
            address receiver = to;
            if (makerCommands[j] != Commands.SIMPLE_TRANSFER){
                if (makerCommands[j] == Commands.TRANSFER_TO_CONTRACT) {
                    receiver = address(this);
                } else if (makerCommands[j] == Commands.NATIVE_TRANSFER) {
                    if (maker_tokens[j] != WRAPPED_NATIVE_TOKEN) revert WrongWrappedTokenAddress();
                    nativeToTaker += amount;
                    receiver = address(this);
                } else {
                    revert InvalidCommand();
                }
            }
            if (usingPermit2) {
                if (batchTransferDetails.length == 0){
                    batchTransferDetails = new IPermit2.AllowanceTransferDetails[](hasPartnerFee ? 2 * maker_tokens.length : maker_tokens.length);
                }
                if (hasPartnerFee){
                    if (makerCommands[j] != Commands.TRANSFER_TO_CONTRACT){
                        uint256 fee = amount * partnerInfo.fee / HUNDRED_PERCENT;
                        if (fee > 0){
                            batchTransferDetails[batchInd++] = IPermit2.AllowanceTransferDetails({
                                from: from,
                                to: partnerInfo.beneficiary,
                                amount: SafeCast160.toUint160(fee),
                                token: maker_tokens[j]
                            });
                            amount -= fee;
                            if (makerCommands[j] == Commands.NATIVE_TRANSFER){
                                nativeToTaker -= fee;
                            }
                        } else {
                            assembly {mstore(batchTransferDetails, sub(mload(batchTransferDetails), 1))}
                        }
                    } else {
                        assembly {mstore(batchTransferDetails, sub(mload(batchTransferDetails), 1))}
                    }
                }
                batchTransferDetails[batchInd++] = IPermit2.AllowanceTransferDetails({
                    from: from,
                    to: receiver,
                    amount: SafeCast160.toUint160(amount),
                    token: maker_tokens[j]
                });
            } else {
                if (hasPartnerFee && makerCommands[j] != Commands.TRANSFER_TO_CONTRACT){
                    uint256 fee = amount * partnerInfo.fee / HUNDRED_PERCENT;
                    if (fee > 0){
                        IERC20(maker_tokens[j]).safeTransferFrom(from, partnerInfo.beneficiary, fee);
                        amount -= fee;
                        if (makerCommands[j] == Commands.NATIVE_TRANSFER){
                            nativeToTaker -= fee;
                        }
                    }
                }
                IERC20(maker_tokens[j]).safeTransferFrom(from, receiver, amount);
            }
        }
        if (usingPermit2){
            if (batchInd != batchTransferDetails.length) revert InvalidPermit2Commands();
            PERMIT2.transferFrom(batchTransferDetails);
        }

        return nativeToTaker;
    }

    /// @notice Transfer tokens from taker to maker with index=i in Aggregate order
    /// @param order AggregateOrder
    /// @param i index of current maker
    /// @param filledTakerAmount Token amount which taker wants to swap, should be less or equal to order.taker_amount
    ///  if filledTakerAmount == 0 then order.taker_amounts will be used, Many-to-One trades don't support partial fill
    /// @param quoteTakerAmount - full taker_amount for One-to-One or One-to-Many trades, for Many-to-One orders it's 0
    /// @param indices helper structure to track indices
    /// @param nativeTokens helper structure to track native token transfers
    /// @param pendingTransfers helper structure to track pending transfers
    /// @param batchTransferDetails helper structure to track permit2 transfer
    function _transferTakerTokensForAggregateOrder(
        Order.Aggregate calldata order,
        uint256 i,
        uint256 filledTakerAmount,
        uint256 quoteTakerAmount,
        Transfer.IndicesInfo memory indices,
        Transfer.NativeTokens memory nativeTokens,
        Transfer.Pending[] memory pendingTransfers,
        IPermit2.AllowanceTransferDetails[] memory batchTransferDetails
    ) internal {
        for (uint k; k < order.taker_tokens[i].length; ++k) {
            uint currentTakerAmount = filledTakerAmount > 0 && filledTakerAmount < quoteTakerAmount ?
                order.taker_amounts[i][k] * filledTakerAmount / quoteTakerAmount : order.taker_amounts[i][k];
            bytes1 curCommand = order.commands[indices.commandsInd + k];
            if (curCommand == Commands.SIMPLE_TRANSFER || curCommand == Commands.CALL_PERMIT_THEN_TRANSFER){
                IERC20(order.taker_tokens[i][k]).safeTransferFrom(
                    order.taker_address, order.maker_addresses[i], currentTakerAmount
                );
            } else if (curCommand == Commands.PERMIT2_TRANSFER || curCommand == Commands.CALL_PERMIT2_THEN_TRANSFER){
                batchTransferDetails[indices.permit2Ind++] = IPermit2.AllowanceTransferDetails({
                    from: order.taker_address,
                    to: order.maker_addresses[i],
                    amount: SafeCast160.toUint160(currentTakerAmount),
                    token: order.taker_tokens[i][k]
                });
            } else if (curCommand == Commands.NATIVE_TRANSFER) {
                if (order.taker_tokens[i][k] != WRAPPED_NATIVE_TOKEN) revert WrongWrappedTokenAddress();
                nativeTokens.toMakers += currentTakerAmount;
                pendingTransfers[indices.pendingTransfersInd++] = Transfer.Pending(
                    order.taker_tokens[i][k], order.maker_addresses[i], currentTakerAmount
                );
            } else if (curCommand == Commands.TRANSFER_FROM_CONTRACT){
                // If using contract as an intermediate recipient for tokens transferring
                pendingTransfers[indices.pendingTransfersInd++] = Transfer.Pending(
                    order.taker_tokens[i][k], order.maker_addresses[i], currentTakerAmount
                );
            } else {
                revert InvalidCommand();
            }
        }
    }

    /// @notice Call 'permit' function for taker's token
    function _tokenPermit(
        address takerAddress, address tokenAddress, Signature.PermitSignature calldata takerPermitSignature
    ) internal {
        (bytes32 r, bytes32 s, uint8 v) = Signature.getRsv(takerPermitSignature.signatureBytes);
        if (tokenAddress == DAI_TOKEN){
            if (_chainId == 137){
                IDaiLikePermit(tokenAddress).permit(
                    takerAddress, address(this), IDaiLikePermit(tokenAddress).getNonce(takerAddress), takerPermitSignature.deadline, true, v, r, s
                );
            } else {
                IDaiLikePermit(tokenAddress).permit(
                    takerAddress, address(this), IERC20Permit(tokenAddress).nonces(takerAddress), takerPermitSignature.deadline, true, v, r, s
                );
            }
        } else {
            IERC20Permit(tokenAddress).permit(takerAddress, address(this), type(uint).max, takerPermitSignature.deadline, v, r, s);
        }
    }

    /// @notice On Permit2 contract call 'permit' function for taker's token
    function _tokenPermit2(
        address takerAddress, address tokenAddress, Signature.Permit2Signature calldata takerPermit2Signature
    ) internal {
        IPermit2.PermitDetails[] memory permitBatch = new IPermit2.PermitDetails[](1);
        permitBatch[0] = IPermit2.PermitDetails(
            tokenAddress, type(uint160).max, takerPermit2Signature.deadline, takerPermit2Signature.nonce
        );
        PERMIT2.permit(
            takerAddress,
            IPermit2.PermitBatch(permitBatch, address(this), takerPermit2Signature.deadline),
            takerPermit2Signature.signatureBytes
        );
    }

    /// @notice Call 'permit' function for one taker token that has command 'CALL_PERMIT_THEN_TRANSFER'
    function _tokenPermitForMultiOrder(
        Order.Multi calldata order, Signature.PermitSignature calldata takerPermitSignature
    ) internal {
        uint commandsInd = order.maker_tokens.length;
        for (uint i; i < order.taker_tokens.length; ++i){
            if (order.commands[commandsInd++] == Commands.CALL_PERMIT_THEN_TRANSFER){
                _tokenPermit(order.taker_address, order.taker_tokens[i], takerPermitSignature);
                return;
            }
        }
    }

    /// @notice On Permit2 contract call 'permit' for batch of tokens with transfer-command 'CALL_PERMIT2_THEN_TRANSFER'
    function _tokensPermit2ForMultiOrder(
        Order.Multi calldata order, Signature.MultiTokensPermit2Signature calldata infoPermit2
    ) internal {
        uint commandsInd = order.maker_tokens.length;
        uint batchToApproveInd;
        IPermit2.PermitDetails[] memory batchToApprove = new IPermit2.PermitDetails[](infoPermit2.nonces.length);
        for (uint i; i < order.taker_tokens.length; ++i){
            if (order.commands[commandsInd++] == Commands.CALL_PERMIT2_THEN_TRANSFER){
                batchToApprove[batchToApproveInd] = IPermit2.PermitDetails(
                    order.taker_tokens[i], type(uint160).max, infoPermit2.deadline, infoPermit2.nonces[batchToApproveInd]
                );
                ++batchToApproveInd;
            }
        }
        if (batchToApproveInd != batchToApprove.length) revert InvalidPermit2Commands();
        PERMIT2.permit(
            order.taker_address,
            IPermit2.PermitBatch(batchToApprove, address(this), infoPermit2.deadline),
            infoPermit2.signatureBytes
        );
    }

    /// @notice Call 'permit' function for one taker token that has command 'CALL_PERMIT_THEN_TRANSFER'
    function _tokenPermitForAggregateOrder(
        Order.Aggregate calldata order, Signature.PermitSignature calldata takerPermitSignature
    ) internal {
        uint commandsInd;
        for (uint i; i < order.taker_tokens.length; ++i){
            commandsInd += order.maker_tokens[i].length;
            for (uint j; j < order.taker_tokens[i].length; ++j) {
                if (order.commands[commandsInd++] == Commands.CALL_PERMIT_THEN_TRANSFER){
                    _tokenPermit(order.taker_address, order.taker_tokens[i][j], takerPermitSignature);
                    return;
                }
            }
        }
    }

    /// @notice On Permit2 contract call 'permit' for batch of tokens with transfer-command 'CALL_PERMIT2_THEN_TRANSFER'
    function _tokensPermit2ForAggregateOrder(
        Order.Aggregate calldata order, Signature.MultiTokensPermit2Signature calldata infoPermit2
    ) internal {
        uint commandsInd;
        uint batchToApproveInd;
        IPermit2.PermitDetails[] memory batchToApprove = new IPermit2.PermitDetails[](infoPermit2.nonces.length);
        for (uint i; i < order.taker_tokens.length; ++i){
            commandsInd += order.maker_tokens[i].length;
            for (uint j; j < order.taker_tokens[i].length; ++j) {
                if (order.commands[commandsInd++] == Commands.CALL_PERMIT2_THEN_TRANSFER){
                    batchToApprove[batchToApproveInd] = IPermit2.PermitDetails(
                        order.taker_tokens[i][j], type(uint160).max, infoPermit2.deadline, infoPermit2.nonces[batchToApproveInd]
                    );
                    ++batchToApproveInd;
                }
            }
        }
        if (batchToApproveInd != batchToApprove.length) revert InvalidPermit2Commands();
        PERMIT2.permit(
            order.taker_address,
            IPermit2.PermitBatch(batchToApprove, address(this), infoPermit2.deadline),
            infoPermit2.signatureBytes
        );
    }



}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


// Signature Errors
error OrderInvalidSigner();
error InvalidEIP721Signature();
error InvalidEIP1271Signature();
error InvalidETHSIGNSignature();
error InvalidSignatureType();
error InvalidSignatureLength();
error InvalidSignatureValueS();
error InvalidSignatureValueV();


// Validation Errors
error ZeroNonce();
error InvalidNonce();
error OrderExpired();
error OrdersLengthsMismatch();
error TokensLengthsMismatch();
error CommandsLengthsMismatch();
error InvalidPermit2Commands();
error InvalidCommand();
error InvalidCommandsLength();
error InvalidFlags();
error PartialFillNotSupported();
error UpdatedMakerAmountsTooLow();
error ZeroMakerAmount();
error MakerAmountsLengthsMismatch();

error NotEnoughNativeToken();
error WrongWrappedTokenAddress();
error FailedToSendNativeToken();

error InvalidSender();
error ManyToManyNotSupported();

error InvalidPendingTransfersLength();
error InvalidPermit2TransfersLength();

// Partner Errors
error PartnerAlreadyRegistered();
error PartnerFeeTooHigh();
error NullBeneficiary();

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "./interface/IBebopSettlement.sol";
import "./base/BebopSigning.sol";
import "./base/BebopTransfer.sol";
import "./libs/Order.sol";
import "./libs/Signature.sol";
import "./libs/Transfer.sol";

contract BebopSettlement is IBebopSettlement, BebopSigning, BebopTransfer {

    using SafeERC20 for IERC20;

    constructor(address _wrappedNativeToken, address _permit2, address _daiAddress)
        BebopTransfer(_wrappedNativeToken, _permit2, _daiAddress) {
    }

    receive() external payable {}


    //-----------------------------------------
    //
    //      One-to-One trade with one maker
    //           taker execution (RFQ-T)
    //
    // -----------------------------------------

    /// @inheritdoc IBebopSettlement
    function swapSingle(
        Order.Single calldata order,
        Signature.MakerSignature calldata makerSignature,
        uint256 filledTakerAmount
    ) external override payable {
        if (msg.sender != order.taker_address) revert InvalidSender();
        _executeSingleOrder(order, makerSignature, filledTakerAmount, Commands.SIMPLE_TRANSFER, order.maker_amount);
    }

    /// @inheritdoc IBebopSettlement
    function swapSingleFromContract(
        Order.Single calldata order,
        Signature.MakerSignature calldata makerSignature
    ) external override payable {
        if (msg.sender != order.taker_address) revert InvalidSender();
        _executeSingleOrder(
            order, makerSignature, IERC20(order.taker_token).balanceOf(address(this)), Commands.TRANSFER_FROM_CONTRACT, order.maker_amount
        );
    }


    //-----------------------------------------
    //
    //      One-to-One trade with one maker
    //           maker execution (RFQ-M)
    //
    // -----------------------------------------

    /// @inheritdoc IBebopSettlement
    function settleSingle(
        Order.Single calldata order,
        Signature.MakerSignature calldata makerSignature,
        uint256 filledTakerAmount,
        Transfer.OldSingleQuote calldata takerQuoteInfo,
        bytes calldata takerSignature
    ) external override payable {
        _validateTakerSignatureForSingleOrder(order, takerSignature, takerQuoteInfo);
        _executeSingleOrder(
            order, makerSignature, filledTakerAmount, Commands.SIMPLE_TRANSFER,
            takerQuoteInfo.useOldAmount ? takerQuoteInfo.makerAmount : order.maker_amount
        );
    }

    /// @inheritdoc IBebopSettlement
    function settleSingleAndSignPermit(
        Order.Single calldata order,
        Signature.MakerSignature calldata makerSignature,
        uint256 filledTakerAmount,
        Transfer.OldSingleQuote calldata takerQuoteInfo,
        bytes calldata takerSignature,
        Signature.PermitSignature calldata takerPermitSignature
    ) external override payable {
        _validateTakerSignatureForSingleOrder(order, takerSignature, takerQuoteInfo);
        _tokenPermit(order.taker_address, order.taker_token, takerPermitSignature);
        _executeSingleOrder(
            order, makerSignature, filledTakerAmount, Commands.SIMPLE_TRANSFER,
            takerQuoteInfo.useOldAmount ? takerQuoteInfo.makerAmount : order.maker_amount
        );
    }

    /// @inheritdoc IBebopSettlement
    function settleSingleAndSignPermit2(
        Order.Single calldata order,
        Signature.MakerSignature calldata makerSignature,
        uint256 filledTakerAmount,
        Transfer.OldSingleQuote calldata takerQuoteInfo,
        bytes calldata takerSignature,
        Signature.Permit2Signature calldata takerPermit2Signature
    ) external override payable {
        _validateTakerSignatureForSingleOrder(order, takerSignature, takerQuoteInfo);
        _tokenPermit2(order.taker_address, order.taker_token, takerPermit2Signature);
        _executeSingleOrder(
            order, makerSignature, filledTakerAmount, Commands.PERMIT2_TRANSFER,
            takerQuoteInfo.useOldAmount ? takerQuoteInfo.makerAmount : order.maker_amount
        );
    }


    //------------------------------------------------------
    //
    //      Many-to-One or One-to-Many trade with one maker
    //                taker execution (RFQ-T)
    //
    // ------------------------------------------------------

    /// @inheritdoc IBebopSettlement
    function swapMulti(
        Order.Multi calldata order,
        Signature.MakerSignature calldata makerSignature,
        uint256 filledTakerAmount
    ) external override payable {
        if (msg.sender != order.taker_address) revert InvalidSender();
        _executeMultiOrder(order, makerSignature, filledTakerAmount, order.maker_amounts);
    }


    //------------------------------------------------------
    //
    //      Many-to-One or One-to-Many trade with one maker
    //                maker execution (RFQ-M)
    //
    // ------------------------------------------------------

    /// @inheritdoc IBebopSettlement
    function settleMulti(
        Order.Multi calldata order,
        Signature.MakerSignature calldata makerSignature,
        uint256 filledTakerAmount,
        Transfer.OldMultiQuote calldata takerQuoteInfo,
        bytes calldata takerSignature
    ) external override payable {
        _validateTakerSignatureForMultiOrder(order, takerSignature, takerQuoteInfo);
        _executeMultiOrder(
            order, makerSignature, filledTakerAmount,
            takerQuoteInfo.useOldAmount ? takerQuoteInfo.makerAmounts : order.maker_amounts
        );
    }

    /// @inheritdoc IBebopSettlement
    function settleMultiAndSignPermit(
        Order.Multi calldata order,
        Signature.MakerSignature calldata makerSignature,
        uint256 filledTakerAmount,
        Transfer.OldMultiQuote calldata takerQuoteInfo,
        bytes calldata takerSignature,
        Signature.PermitSignature calldata takerPermitSignature
    ) external override payable {
        _validateTakerSignatureForMultiOrder(order, takerSignature, takerQuoteInfo);
        _tokenPermitForMultiOrder(order, takerPermitSignature);
        _executeMultiOrder(
            order, makerSignature, filledTakerAmount,
            takerQuoteInfo.useOldAmount ? takerQuoteInfo.makerAmounts : order.maker_amounts
        );
    }

    /// @inheritdoc IBebopSettlement
    function settleMultiAndSignPermit2(
        Order.Multi calldata order,
        Signature.MakerSignature calldata makerSignature,
        uint256 filledTakerAmount,
        Transfer.OldMultiQuote calldata takerQuoteInfo,
        bytes calldata takerSignature,
        Signature.MultiTokensPermit2Signature calldata infoPermit2
    ) external override payable {
        _validateTakerSignatureForMultiOrder(order, takerSignature, takerQuoteInfo);
        _tokensPermit2ForMultiOrder(order, infoPermit2);
        _executeMultiOrder(
            order, makerSignature, filledTakerAmount,
            takerQuoteInfo.useOldAmount ? takerQuoteInfo.makerAmounts : order.maker_amounts
        );
    }


    //-----------------------------------------
    //
    //      Any trade with multiple makers
    //          taker execution (RFQ-T)
    //
    // ----------------------------------------

    /// @inheritdoc IBebopSettlement
    function swapAggregate(
        Order.Aggregate calldata order,
        Signature.MakerSignature[] calldata makersSignatures,
        uint256 filledTakerAmount
    ) external override payable {
        if (msg.sender != order.taker_address) revert InvalidSender();
        _executeAggregateOrder(order, makersSignatures, filledTakerAmount, order.maker_amounts);
    }


    //-----------------------------------------
    //
    //      Any trade with multiple makers
    //          maker execution (RFQ-M)
    //
    // ----------------------------------------

    /// @inheritdoc IBebopSettlement
    function settleAggregate(
        Order.Aggregate calldata order,
        Signature.MakerSignature[] calldata makersSignatures,
        uint256 filledTakerAmount,
        Transfer.OldAggregateQuote calldata takerQuoteInfo,
        bytes calldata takerSignature
    ) external override payable {
        _validateTakerSignatureForAggregateOrder(order, takerSignature, takerQuoteInfo);
        _executeAggregateOrder(
            order, makersSignatures, filledTakerAmount,
            takerQuoteInfo.useOldAmount ? takerQuoteInfo.makerAmounts : order.maker_amounts
        );
    }

    /// @inheritdoc IBebopSettlement
    function settleAggregateAndSignPermit(
        Order.Aggregate calldata order,
        Signature.MakerSignature[] calldata makersSignatures,
        uint256 filledTakerAmount,
        Transfer.OldAggregateQuote calldata takerQuoteInfo,
        bytes calldata takerSignature,
        Signature.PermitSignature calldata takerPermitSignature
    ) external override payable {
        _validateTakerSignatureForAggregateOrder(order, takerSignature, takerQuoteInfo);
        _tokenPermitForAggregateOrder(order, takerPermitSignature);
        _executeAggregateOrder(
            order, makersSignatures, filledTakerAmount,
            takerQuoteInfo.useOldAmount ? takerQuoteInfo.makerAmounts : order.maker_amounts
        );
    }

    /// @inheritdoc IBebopSettlement
    function settleAggregateAndSignPermit2(
        Order.Aggregate calldata order,
        Signature.MakerSignature[] calldata makersSignatures,
        uint256 filledTakerAmount,
        Transfer.OldAggregateQuote calldata takerQuoteInfo,
        bytes calldata takerSignature,
        Signature.MultiTokensPermit2Signature calldata infoPermit2
    ) external override payable {
        _validateTakerSignatureForAggregateOrder(order, takerSignature, takerQuoteInfo);
        _tokensPermit2ForAggregateOrder(order, infoPermit2);
        _executeAggregateOrder(
            order, makersSignatures, filledTakerAmount,
            takerQuoteInfo.useOldAmount ? takerQuoteInfo.makerAmounts : order.maker_amounts
        );
    }


    /// @notice Execute One-to-One trade with one maker
    /// @param order All information about order
    /// @param makerSignature Maker signature for SingleOrder
    /// @param filledTakerAmount Token amount which taker wants to swap, should be less or equal to order.taker_amount
    ///                          if filledTakerAmount == 0 then order.taker_amount will be used
    /// @param takerTransferCommand Command to indicate how to transfer taker's token
    /// @param updatedMakerAmount for RFQ-M case maker amount can be improved
    function _executeSingleOrder(
        Order.Single calldata order,
        Signature.MakerSignature calldata makerSignature,
        uint256 filledTakerAmount,
        bytes1 takerTransferCommand,
        uint256 updatedMakerAmount
    ) internal {
        _validateSingleOrder(order, makerSignature);
        (uint128 eventId, uint64 partnerId) = Order.extractFlags(order.flags);
        (bool takerHasNative, bool makerHasNative, bool takerUsingPermit2) = Order.extractSingleOrderCommands(order.packed_commands);
        if (takerTransferCommand == Commands.TRANSFER_FROM_CONTRACT && takerHasNative){
            filledTakerAmount = address(this).balance;
        }
        _transferToken(
            order.taker_address, order.maker_address, order.taker_token,
            filledTakerAmount == 0 || filledTakerAmount > order.taker_amount ? order.taker_amount : filledTakerAmount,
            takerHasNative ? Commands.NATIVE_TRANSFER : (takerUsingPermit2 ? Commands.PERMIT2_TRANSFER : takerTransferCommand),
            takerHasNative ? Transfer.Action.Wrap : Transfer.Action.None, 0
        );
        uint256 newMakerAmount = updatedMakerAmount;
        if (filledTakerAmount != 0 && filledTakerAmount < order.taker_amount){
            newMakerAmount = (updatedMakerAmount * filledTakerAmount) / order.taker_amount;
        }
        (bool makerUsingPermit2, ) = Signature.extractMakerFlags(makerSignature.flags);
        _transferToken(
            order.maker_address, order.receiver, order.maker_token, newMakerAmount,
            makerUsingPermit2 ? Commands.PERMIT2_TRANSFER : Commands.SIMPLE_TRANSFER,
            makerHasNative ? Transfer.Action.Unwrap : Transfer.Action.None, partnerId
        );
        emit BebopOrder(eventId);
    }

    /// @notice Execute Many-to-One or One-to-Many trade with one maker
    /// @param order All information about order
    /// @param makerSignature Maker signature for SingleOrder
    /// @param filledTakerAmount Token amount which taker wants to swap, should be less or equal to order.taker_amount
    ///  if filledTakerAmount == 0 then order.taker_amounts will be used, Many-to-One trades don't support partial fill
    /// @param updatedMakerAmounts for RFQ-M case maker amounts can be improved
    function _executeMultiOrder(
        Order.Multi calldata order,
        Signature.MakerSignature calldata makerSignature,
        uint256 filledTakerAmount,
        uint256[] calldata updatedMakerAmounts
    ) internal {
        _validateMultiOrder(order, makerSignature, filledTakerAmount);
        (uint128 eventId, uint64 partnerId) = Order.extractFlags(order.flags);
        (bool makerUsingPermit2, ) = Signature.extractMakerFlags(makerSignature.flags);
        if (order.taker_tokens.length > 1){ // Many-to-One
            // transfer taker's tokens
            _transferTakerTokens(order);

            // transfer maker's token
            _transferToken(
                order.maker_address, order.receiver, order.maker_tokens[0], updatedMakerAmounts[0],
                makerUsingPermit2 ? Commands.PERMIT2_TRANSFER : Commands.SIMPLE_TRANSFER,
                order.commands[0] == Commands.NATIVE_TRANSFER ? Transfer.Action.Unwrap : Transfer.Action.None, partnerId
            );
        } else { // One-to-Many
            // transfer taker's token
            bytes1 takerCommand = order.commands[order.maker_tokens.length];
            _transferToken(
                order.taker_address, order.maker_address, order.taker_tokens[0],
                filledTakerAmount == 0 || filledTakerAmount > order.taker_amounts[0] ?
                    order.taker_amounts[0] : filledTakerAmount,
                takerCommand, takerCommand == Commands.NATIVE_TRANSFER ? Transfer.Action.Wrap : Transfer.Action.None, 0
            );

            // transfer maker's tokens
            uint[] memory makerAmounts = updatedMakerAmounts;
            if (filledTakerAmount > 0 && filledTakerAmount < order.taker_amounts[0]){
                for (uint j; j < updatedMakerAmounts.length; ++j){
                    makerAmounts[j] = updatedMakerAmounts[j] * filledTakerAmount / order.taker_amounts[0];
                }
            }
            uint nativeToTaker = _transferMakerTokens(
                order.maker_address, order.receiver, order.maker_tokens, makerAmounts, makerUsingPermit2,
                order.commands, partnerId
            );
            if (nativeToTaker > 0){
                IWETH(WRAPPED_NATIVE_TOKEN).withdraw(nativeToTaker);
                (bool sent,) = order.receiver.call{value: nativeToTaker}("");
                if (!sent) revert FailedToSendNativeToken();
            }
        }
        emit BebopOrder(eventId);
    }

    /// @notice Execute trade with multiple makers
    /// @param order All information about order
    /// @param makersSignatures Maker signatures for part of AggregateOrder(which is MultiOrder)
    /// @param filledTakerAmount Token amount which taker wants to swap, should be less or equal to order.taker_amount
    ///  if filledTakerAmount == 0 then order.taker_amounts will be used, Many-to-One trades don't support partial fill
    /// @param updatedMakerAmounts for RFQ-M case maker amounts can be improved
    function _executeAggregateOrder(
        Order.Aggregate calldata order,
        Signature.MakerSignature[] calldata makersSignatures,
        uint256 filledTakerAmount,
        uint256[][] calldata updatedMakerAmounts
    ) internal {
        _validateAggregateOrder(order, makersSignatures);
        (uint quoteTakerAmount, Transfer.LengthsInfo memory lenInfo) = _getAggregateOrderInfo(order, filledTakerAmount);
        Transfer.IndicesInfo memory indices = Transfer.IndicesInfo(0, 0, 0);
        Transfer.NativeTokens memory nativeTokens = Transfer.NativeTokens(0, 0);
        Transfer.Pending[] memory pendingTransfers = new Transfer.Pending[](lenInfo.pendingTransfersLen);
        IPermit2.AllowanceTransferDetails[] memory batchTransferDetails = new IPermit2.AllowanceTransferDetails[](lenInfo.permit2Len);
        for (uint i; i < order.maker_tokens.length; ++i){
            (bool makerUsingPermit2, ) = Signature.extractMakerFlags(makersSignatures[i].flags);
            uint[] memory makerAmounts = updatedMakerAmounts[i];
            if (filledTakerAmount > 0 && filledTakerAmount < quoteTakerAmount){ // partial fill
                for (uint j; j < updatedMakerAmounts[i].length; ++j){
                    makerAmounts[j] = updatedMakerAmounts[i][j] * filledTakerAmount / quoteTakerAmount;
                }
            }
            nativeTokens.toTaker += _transferMakerTokens(
                order.maker_addresses[i], order.receiver, order.maker_tokens[i], makerAmounts,
                makerUsingPermit2, BytesLib.slice(order.commands, indices.commandsInd, order.maker_tokens[i].length),
                Order.extractPartnerId(order.flags)
            );
            indices.commandsInd += order.maker_tokens[i].length;
            _transferTakerTokensForAggregateOrder(
                order, i, filledTakerAmount, quoteTakerAmount, indices, nativeTokens, pendingTransfers, batchTransferDetails
            );
            indices.commandsInd += order.taker_tokens[i].length;
        }
        if (indices.pendingTransfersInd != lenInfo.pendingTransfersLen) revert InvalidPendingTransfersLength();
        if (indices.permit2Ind != lenInfo.permit2Len) revert InvalidPermit2TransfersLength();
        if (lenInfo.permit2Len > 0) {
            // Transfer taker's tokens with Permit2 batch
            PERMIT2.transferFrom(batchTransferDetails);
        }

        // Transfer tokens from contract to makers
        if (lenInfo.pendingTransfersLen > 0) {
            // Wrap taker's native token
            if (nativeTokens.toMakers > 0){
                if (msg.value < nativeTokens.toMakers) revert NotEnoughNativeToken();
                IWETH(WRAPPED_NATIVE_TOKEN).deposit{value: nativeTokens.toMakers}();
            }
            for (uint i; i < pendingTransfers.length; ++i) {
                if (pendingTransfers[i].amount > 0) {
                    IERC20(pendingTransfers[i].token).safeTransfer(
                        pendingTransfers[i].to, pendingTransfers[i].amount
                    );
                }
            }
        }

        // Unwrap and transfer native token to receiver
        if (nativeTokens.toTaker > 0) {
            IWETH(WRAPPED_NATIVE_TOKEN).withdraw(nativeTokens.toTaker);
            (bool sent,) = order.receiver.call{value: nativeTokens.toTaker}("");
            if (!sent) revert FailedToSendNativeToken();
        }

        emit BebopOrder(Order.extractEventId(order.flags));
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../libs/Order.sol";
import "../libs/Signature.sol";
import "../libs/Transfer.sol";

interface IBebopSettlement {

    event BebopOrder(uint128 indexed eventId);

    /// @notice Taker execution of one-to-one trade with one maker
    /// @param order Single order struct
    /// @param makerSignature Maker's signature for SingleOrder
    /// @param filledTakerAmount Partially filled taker amount, 0 for full fill
    function swapSingle(
        Order.Single calldata order,
        Signature.MakerSignature calldata makerSignature,
        uint256 filledTakerAmount
    ) external payable;

    /// @notice Taker execution of one-to-one trade with one maker.
    /// Using current contract's balance of taker_token as partial fill amount
    /// @param order Single order struct
    /// @param makerSignature Maker's signature for SingleOrder
    function swapSingleFromContract(
        Order.Single calldata order,
        Signature.MakerSignature calldata makerSignature
    ) external payable;

    /// @notice Maker execution of one-to-one trade with one maker
    /// @param order Single order struct
    /// @param makerSignature Maker's signature for SingleOrder
    /// @param filledTakerAmount Partially filled taker amount, 0 for full fill
    /// @param takerQuoteInfo If maker_amount has improved then it contains old quote values that taker signed,
    ///                       otherwise it contains same values as in order
    /// @param takerSignature Taker's signature to approve executing order by maker,
    ///        if taker executes order himself then signature can be '0x' (recommended to use swapSingle for this case)
    function settleSingle(
        Order.Single calldata order,
        Signature.MakerSignature calldata makerSignature,
        uint256 filledTakerAmount,
        Transfer.OldSingleQuote calldata takerQuoteInfo,
        bytes calldata takerSignature
    ) external payable;

    /// @notice Maker execution of one-to-one trade with one maker.
    /// Sign permit for taker_token before execution of the order
    /// @param order Single order struct
    /// @param makerSignature Maker's signature for SingleOrder
    /// @param filledTakerAmount Partially filled taker amount, 0 for full fill
    /// @param takerQuoteInfo If maker_amount has improved then it contains old quote values that taker signed,
    ///                       otherwise it contains same values as in order
    /// @param takerSignature Taker's signature to approve executing order by maker,
    ///                       if taker executes order himself then signature can be '0x'
    /// @param takerPermitSignature Taker's signature to approve spending of taker_token by calling token.permit(..)
    function settleSingleAndSignPermit(
        Order.Single calldata order,
        Signature.MakerSignature calldata makerSignature,
        uint256 filledTakerAmount,
        Transfer.OldSingleQuote calldata takerQuoteInfo,
        bytes calldata takerSignature,
        Signature.PermitSignature calldata takerPermitSignature
    ) external payable;

    /// @notice Maker execution of one-to-one trade with one maker.
    /// Sign permit2 for taker_token before execution of the order
    /// @param order Single order struct
    /// @param makerSignature Maker's signature for SingleOrder
    /// @param filledTakerAmount Partially filled taker amount, 0 for full fill
    /// @param takerQuoteInfo If maker_amount has improved then it contains old quote values that taker signed,
    ///                       otherwise it contains same values as in order
    /// @param takerSignature Taker's signature to approve executing order by maker,
    ///                       if taker executes order himself then signature can be '0x'
    /// @param takerPermit2Signature Taker's signature to approve spending of taker_token by calling Permit2.permit(..)
    function settleSingleAndSignPermit2(
        Order.Single calldata order,
        Signature.MakerSignature calldata makerSignature,
        uint256 filledTakerAmount,
        Transfer.OldSingleQuote calldata takerQuoteInfo,
        bytes calldata takerSignature,
        Signature.Permit2Signature calldata takerPermit2Signature
    ) external payable;


    /// @notice Taker execution of one-to-many or many-to-one trade with one maker
    /// @param order Multi order struct
    /// @param makerSignature Maker's signature for MultiOrder
    /// @param filledTakerAmount Partially filled taker amount, 0 for full fill. Many-to-one doesnt support partial fill
    function swapMulti(
        Order.Multi calldata order,
        Signature.MakerSignature calldata makerSignature,
        uint256 filledTakerAmount
    ) external payable;

    /// @notice Maker execution of one-to-many or many-to-one trade with one maker
    /// @param order Multi order struct
    /// @param makerSignature Maker's signature for MultiOrder
    /// @param filledTakerAmount Partially filled taker amount, 0 for full fill. Many-to-one doesnt support partial fill
    /// @param takerQuoteInfo If maker_amounts have improved then it contains old quote values that taker signed,
    ///                       otherwise it contains same values as in order
    /// @param takerSignature Taker's signature to approve executing order by maker,
    ///        if taker executes order himself then signature can be '0x' (recommended to use swapMulti for this case)
    function settleMulti(
        Order.Multi calldata order,
        Signature.MakerSignature calldata makerSignature,
        uint256 filledTakerAmount,
        Transfer.OldMultiQuote calldata takerQuoteInfo,
        bytes calldata takerSignature
    ) external payable;

    /// @notice Maker execution of one-to-many or many-to-one trade with one maker.
    /// Before execution of the order, signs permit for one of taker_tokens
    /// @param order Multi order struct
    /// @param makerSignature Maker's signature for MultiOrder
    /// @param filledTakerAmount Partially filled taker amount, 0 for full fill. Many-to-one doesnt support partial fill
    /// @param takerQuoteInfo If maker_amounts have improved then it contains old quote values that taker signed,
    ///                       otherwise it contains same values as in order
    /// @param takerSignature Taker's signature to approve executing order by maker,
    ///                       if taker executes order himself then signature can be '0x'
    /// @param takerPermitSignature Taker's signature to approve spending of taker_token by calling token.permit(..)
    function settleMultiAndSignPermit(
        Order.Multi calldata order,
        Signature.MakerSignature calldata makerSignature,
        uint256 filledTakerAmount,
        Transfer.OldMultiQuote calldata takerQuoteInfo,
        bytes calldata takerSignature,
        Signature.PermitSignature calldata takerPermitSignature
    ) external payable;

    /// @notice Maker execution of one-to-many or many-to-one trade with one maker.
    /// Sign permit2 for taker_tokens before execution of the order
    /// @param order Multi order struct
    /// @param makerSignature Maker's signature for MultiOrder
    /// @param filledTakerAmount Partially filled taker amount, 0 for full fill. Many-to-one doesnt support partial fill
    /// @param takerQuoteInfo If maker_amounts have improved then it contains old quote values that taker signed,
    ///                       otherwise it contains same values as in order
    /// @param takerSignature Taker's signature to approve executing order by maker,
    ///                       if taker executes order himself then signature can be '0x'
    /// @param infoPermit2 Taker's signature to approve spending of taker_tokens by calling Permit2.permit(..)
    function settleMultiAndSignPermit2(
        Order.Multi calldata order,
        Signature.MakerSignature calldata makerSignature,
        uint256 filledTakerAmount,
        Transfer.OldMultiQuote calldata takerQuoteInfo,
        bytes calldata takerSignature,
        Signature.MultiTokensPermit2Signature calldata infoPermit2
    ) external payable;


    /// @notice Taker execution of any trade with multiple makers
    /// @param order Aggregate order struct
    /// @param makersSignatures Makers signatures for MultiOrder (can be contructed as part of current AggregateOrder)
    /// @param filledTakerAmount Partially filled taker amount, 0 for full fill. Many-to-one doesnt support partial fill
    function swapAggregate(
        Order.Aggregate calldata order,
        Signature.MakerSignature[] calldata makersSignatures,
        uint256 filledTakerAmount
    ) external payable;

    /// @notice Maker execution of any trade with multiple makers
    /// @param order Aggregate order struct
    /// @param makersSignatures Makers signatures for MultiOrder (can be contructed as part of current AggregateOrder)
    /// @param filledTakerAmount Partially filled taker amount, 0 for full fill. Many-to-one doesnt support partial fill
    /// @param takerQuoteInfo If maker_amounts have improved then it contains old quote values that taker signed,
    ///                       otherwise it contains same values as in order
    /// @param takerSignature Taker's signature to approve executing order by maker,
    ///      if taker executes order himself then signature can be '0x' (recommended to use swapAggregate for this case)
    function settleAggregate(
        Order.Aggregate calldata order,
        Signature.MakerSignature[] calldata makersSignatures,
        uint256 filledTakerAmount,
        Transfer.OldAggregateQuote calldata takerQuoteInfo,
        bytes calldata takerSignature
    ) external payable;

    /// @notice Maker execution of any trade with multiple makers.
    /// Before execution of the order, signs permit for one of taker_tokens
    /// @param order Aggregate order struct
    /// @param makersSignatures Makers signatures for MultiOrder (can be contructed as part of current AggregateOrder)
    /// @param filledTakerAmount Partially filled taker amount, 0 for full fill. Many-to-one doesnt support partial fill
    /// @param takerQuoteInfo If maker_amounts have improved then it contains old quote values that taker signed,
    ///                       otherwise it contains same values as in order
    /// @param takerSignature Taker's signature to approve executing order by maker,
    ///                       if taker executes order himself then signature can be '0x'
    /// @param takerPermitSignature Taker's signature to approve spending of taker_token by calling token.permit(..)
    function settleAggregateAndSignPermit(
        Order.Aggregate calldata order,
        Signature.MakerSignature[] calldata makersSignatures,
        uint256 filledTakerAmount,
        Transfer.OldAggregateQuote calldata takerQuoteInfo,
        bytes calldata takerSignature,
        Signature.PermitSignature calldata takerPermitSignature
    ) external payable;

    /// @notice Maker execution of any trade with multiple makers.
    /// Sign permit2 for taker_tokens before execution of the order
    /// @param order Aggregate order struct
    /// @param makersSignatures Makers signatures for MultiOrder (can be contructed as part of current AggregateOrder)
    /// @param filledTakerAmount Partially filled taker amount, 0 for full fill. Many-to-one doesnt support partial fill
    /// @param takerQuoteInfo If maker_amounts have improved then it contains old quote values that taker signed,
    ///                       otherwise it contains same values as in order
    /// @param takerSignature Taker's signature to approve executing order by maker,
    ///                       if taker executes order himself then signature can be '0x'
    /// @param infoPermit2 Taker's signature to approve spending of taker_tokens by calling Permit2.permit(..)
    function settleAggregateAndSignPermit2(
        Order.Aggregate calldata order,
        Signature.MakerSignature[] calldata makersSignatures,
        uint256 filledTakerAmount,
        Transfer.OldAggregateQuote calldata takerQuoteInfo,
        bytes calldata takerSignature,
        Signature.MultiTokensPermit2Signature calldata infoPermit2
    ) external payable;


}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IDaiLikePermit {
    /// @param holder The address of the token owner.
    /// @param spender The address of the token spender.
    /// @param nonce The owner's nonce, increases at each call to permit.
    /// @param expiry The timestamp at which the permit is no longer valid.
    /// @param allowed Boolean that sets approval amount, true for type(uint256).max and false for 0.
    /// @param v Must produce valid secp256k1 signature from the owner along with r and s.
    /// @param r Must produce valid secp256k1 signature from the owner along with v and s.
    /// @param s Must produce valid secp256k1 signature from the owner along with r and v.
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    // DAI's Polygon getNonce, instead of `nonces(address)` function
    function getNonce(address user) external view returns (uint256 nonce);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


// Part of IAllowanceTransfer(https://github.com/Uniswap/permit2/blob/main/src/interfaces/IAllowanceTransfer.sol)
interface IPermit2 {

    // ------------------
    // IAllowanceTransfer
    // ------------------

    /// @notice Details for a token transfer.
    struct AllowanceTransferDetails {
        // the owner of the token
        address from;
        // the recipient of the token
        address to;
        // the amount of the token
        uint160 amount;
        // the token to be transferred
        address token;
    }

    /// @notice The permit data for a token
    struct PermitDetails {
        // ERC20 token address
        address token;
        // the maximum amount allowed to spend
        uint160 amount;
        // timestamp at which a spender's token allowances become invalid
        uint48 expiration;
        // an incrementing value indexed per owner,token,and spender for each signature
        uint48 nonce;
    }

    /// @notice The permit message signed for multiple token allowances
    struct PermitBatch {
        // the permit data for multiple token allowances
        PermitDetails[] details;
        // address permissioned on the allowed tokens
        address spender;
        // deadline on the permit signature
        uint256 sigDeadline;
    }

    /// @notice A mapping from owner address to token address to spender address to PackedAllowance struct, which contains details and conditions of the approval.
    /// @notice The mapping is indexed in the above order see: allowance[ownerAddress][tokenAddress][spenderAddress]
    /// @dev The packed slot holds the allowed amount, expiration at which the allowed amount is no longer valid, and current nonce thats updated on any signature based approvals.
    function allowance(address user, address token, address spender)
    external
    view
    returns (uint160 amount, uint48 expiration, uint48 nonce);

    /// @notice Permit a spender to the signed amounts of the owners tokens via the owner's EIP-712 signature
    /// @dev May fail if the owner's nonce was invalidated in-flight by invalidateNonce
    /// @param owner The owner of the tokens being approved
    /// @param permitBatch Data signed over by the owner specifying the terms of approval
    /// @param signature The owner's signature over the permit data
    function permit(address owner, PermitBatch memory permitBatch, bytes calldata signature) external;

    /// @notice Transfer approved tokens from one address to another
    /// @param from The address to transfer from
    /// @param to The address of the recipient
    /// @param amount The amount of the token to transfer
    /// @param token The token address to transfer
    /// @dev Requires the from address to have approved at least the desired amount
    /// of tokens to msg.sender.
    function transferFrom(address from, address to, uint160 amount, address token) external;

    /// @notice Transfer approved tokens in a batch
    /// @param transferDetails Array of owners, recipients, amounts, and tokens for the transfers
    /// @dev Requires the from addresses to have approved at least the desired amount
    /// of tokens to msg.sender.
    function transferFrom(AllowanceTransferDetails[] calldata transferDetails) external;

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/// @title Commands
/// @notice Commands are used to specify how tokens are transferred
library Commands {
    bytes1 internal constant SIMPLE_TRANSFER = 0x00; // simple transfer with standard transferFrom
    bytes1 internal constant PERMIT2_TRANSFER = 0x01; // transfer using Permit2.transfer
    bytes1 internal constant CALL_PERMIT_THEN_TRANSFER = 0x02; // call permit then standard transferFrom
    bytes1 internal constant CALL_PERMIT2_THEN_TRANSFER = 0x03; // call Permit2.permit then Permit2.transfer
    bytes1 internal constant NATIVE_TRANSFER = 0x04; // wrap/unwrap native token and transfer
    bytes1 internal constant TRANSFER_TO_CONTRACT = 0x07; // transfer to bebop contract
    bytes1 internal constant TRANSFER_FROM_CONTRACT = 0x08; // transfer from bebop contract
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library BytesLib {
    function slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        // Check length is 0. `iszero` return 1 for `true` and 0 for `false`.
        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // Calculate length mod 32 to handle slices that are not a multiple of 32 in size.
                let lengthmod := and(_length, 31)

                // tempBytes will have the following format in memory: <length><data>
                // When copying data we will offset the start forward to avoid allocating additional memory
                // Therefore part of the length area will be written, but this will be overwritten later anyways.
                // In case no offset is require, the start is set to the data region (0x20 from the tempBytes)
                // mc will be used to keep track where to copy the data to.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // Same logic as for mc is applied and additionally the start offset specified for the method is added
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    // increase `mc` and `cc` to read the next word from memory
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // Copy the data from source (cc location) to the slice data (mc location)
                    mstore(mc, mload(cc))
                }

                // Store the length of the slice. This will overwrite any partial data that
                // was copied when having slices that are not a multiple of 32.
                mstore(tempBytes, _length)

                // update free-memory pointer
                // allocating the array padded to 32 bytes like the compiler does now
                // To set the used memory as a multiple of 32, add 31 to the actual memory usage (mc)
                // and remove the modulo 32 (the `and` with `not(31)`)
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            // if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                // zero out the 32 bytes slice we are about to return
                // we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                // update free-memory pointer
                // tempBytes uses 32 bytes in memory (even when empty) for the length.
                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeCast160 {
    /// @notice Thrown when a valude greater than type(uint160).max is cast to uint160
    error UnsafeCast();

    /// @notice Safely casts uint256 to uint160
    /// @param value The uint256 to be cast
    function toUint160(uint256 value) internal pure returns (uint160) {
        if (value > type(uint160).max) revert UnsafeCast();
        return uint160(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Signature.sol";
import "../base/Errors.sol";

library Order {

    /// @notice Struct for one-to-one trade with one maker
    struct Single {
        uint256 expiry;
        address taker_address;
        address maker_address;
        uint256 maker_nonce;
        address taker_token;
        address maker_token;
        uint256 taker_amount;
        uint256 maker_amount;
        address receiver;
        uint256 packed_commands;
        uint256 flags; // `hashSingleOrder` doesn't use this field for SingleOrder hash
    }

    /// @notice Struct for many-to-one or one-to-many trade with one maker
    /// Also this struct is used as maker order which is part of AggregateOrder
    struct Multi {
        uint256 expiry;
        address taker_address;
        address maker_address;
        uint256 maker_nonce;
        address[] taker_tokens;
        address[] maker_tokens;
        uint256[] taker_amounts;
        uint256[] maker_amounts;
        address receiver;
        bytes commands;
        uint256 flags; // `hashMultiOrder` doesn't use this field for MultiOrder hash
    }

    /// @notice Struct for any trade with multiple makers
    struct Aggregate {
        uint256 expiry;
        address taker_address;
        address[] maker_addresses;
        uint256[] maker_nonces;
        address[][] taker_tokens;
        address[][] maker_tokens;
        uint256[][] taker_amounts;
        uint256[][] maker_amounts;
        address receiver;
        bytes commands;
        uint256 flags; // `hashAggregateOrder` doesn't use this field for AggregateOrder hash
    }


    /// @dev Decode Single order packed_commands
    ///
    ///       ...     | 2 | 1 | 0 |
    /// -+------------+---+---+---+
    ///  |  reserved  | * | * | * |
    ///                 |   |   |
    ///                 |   |   +------- takerHasNative bit, 0 for erc20 token
    ///                 |   |                                1 for native token
    ///                 |   +----------- makerHasNative bit, 0 for erc20 token
    ///                 |                                    1 for native token
    ///                 +-------------takerUsingPermit2 bit, 0 for standard transfer
    ///                                                      1 for permit2 transfer
    function extractSingleOrderCommands(
        uint256 commands
    ) internal pure returns (bool takerHasNative, bool makerHasNative, bool takerUsingPermit2){
        takerHasNative = (commands & 0x01) != 0;
        makerHasNative = (commands & 0x02) != 0;
        takerUsingPermit2 = (commands & 0x04) != 0;
        if (takerHasNative && takerUsingPermit2){
            revert InvalidFlags();
        }
    }

    /// @dev Order flags
    ///
    ///  |    255..128    |      127..64     |   ...    | 1 | 0 |
    /// -+----------------+------------------+----------+---+---+
    ///   uint128 eventID | uint64 partnerId | reserved | *   * |
    ///                                                   |   |
    ///                                                   +---+----- signature type
    ///                                                               00: EIP-712
    ///                                                               01: EIP-1271
    ///                                                               10: ETH_SIGN
    function extractSignatureType(uint256 flags) internal pure returns (Signature.Type signatureType){
        signatureType = Signature.Type(flags & 0x03);
    }

    function extractFlags(uint256 flags) internal pure returns (uint128 eventId, uint64 partnerId){
        eventId = uint128(flags >> 128);
        partnerId = uint64(flags >> 64);
    }

    function extractPartnerId(uint256 flags) internal pure returns (uint64 partnerId){
        partnerId = uint64(flags >> 64);
    }

    function extractEventId(uint256 flags) internal pure returns (uint128 eventId){
        eventId = uint128(flags >> 128);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../base/Errors.sol";

library Signature {

    enum Type {
        EIP712,  //0
        EIP1271, //1
        ETHSIGN  //2
    }

    struct PermitSignature {
        bytes signatureBytes;
        uint256 deadline;
    }

    struct Permit2Signature {
        bytes signatureBytes;
        uint48 deadline;
        uint48 nonce;
    }

    struct MultiTokensPermit2Signature {
        bytes signatureBytes;
        uint48 deadline;
        uint48[] nonces;
    }

    struct MakerSignature {
        bytes signatureBytes;
        uint256 flags;
    }

    /// @dev Decode maker flags
    ///
    ///  |   ...    | 2 | 1 | 0 |
    /// -+----------+---+-------+
    ///  | reserved | * | *   * |
    ///               |   |   |
    ///               |   +---+--- signature type bits
    ///               |               00: EIP-712
    ///               |               01: EIP-1271
    ///               |               10: ETH_SIGN
    ///               |
    ///               +-------------makerUsingPermit2 bit, 0 for standard transfer
    ///                                                    1 for permit2 transfer
    function extractMakerFlags(uint256 flags) internal pure returns (bool usingPermit2, Type signatureType){
        signatureType = Type(flags & 0x03);
        usingPermit2 = (flags & 0x04) != 0;
    }

    /// @notice Split signature into `r`, `s`, `v` variables
    function getRsv(bytes calldata sig) internal pure returns (bytes32, bytes32, uint8){
        if(sig.length != 65) revert InvalidSignatureLength();
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := calldataload(sig.offset)
            s := calldataload(add(sig.offset, 32))
            v := calldataload(add(sig.offset, 33))
        }
        if (v < 27) v += 27;
        if(uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) revert InvalidSignatureValueS();
        if(v != 27 && v != 28) revert InvalidSignatureValueV();
        return (r, s, v);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Transfer {


    struct OldSingleQuote {
        bool useOldAmount;
        uint256 makerAmount;
        uint256 makerNonce;
    }

    struct OldMultiQuote {
        bool useOldAmount;
        uint256[] makerAmounts;
        uint256 makerNonce;
    }

    struct OldAggregateQuote {
        bool useOldAmount;
        uint256[][] makerAmounts;
        uint256[] makerNonces;
    }


    //-----------------------------------------
    //      Internal Helper Data Structures
    // -----------------------------------------

    enum Action {
        None,
        Wrap,
        Unwrap
    }

    struct Pending {
        address token;
        address to;
        uint256 amount;
    }

    struct NativeTokens {
        uint256 toTaker;  // accumulated amount of tokens that will be sent to the taker (receiver)
        uint256 toMakers; // accumulated amount of tokens that will be sent to the makers
    }

    struct LengthsInfo {
        uint48 pendingTransfersLen; // length of `pendingTransfers` array
        uint48 permit2Len; // length of `batchTransferDetails` array
    }

    struct IndicesInfo {
        uint48 pendingTransfersInd;
        uint48 permit2Ind;
        uint256 commandsInd;
    }
}