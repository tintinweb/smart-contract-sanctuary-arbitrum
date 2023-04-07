/**
 *Submitted for verification at Arbiscan on 2023-04-06
*/

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @api3/airnode-protocol/contracts/rrp/interfaces/IWithdrawalUtilsV0.sol


pragma solidity ^0.8.0;

interface IWithdrawalUtilsV0 {
    event RequestedWithdrawal(
        address indexed airnode,
        address indexed sponsor,
        bytes32 indexed withdrawalRequestId,
        address sponsorWallet
    );

    event FulfilledWithdrawal(
        address indexed airnode,
        address indexed sponsor,
        bytes32 indexed withdrawalRequestId,
        address sponsorWallet,
        uint256 amount
    );

    function requestWithdrawal(address airnode, address sponsorWallet) external;

    function fulfillWithdrawal(
        bytes32 withdrawalRequestId,
        address airnode,
        address sponsor
    ) external payable;

    function sponsorToWithdrawalRequestCount(address sponsor)
        external
        view
        returns (uint256 withdrawalRequestCount);
}

// File: @api3/airnode-protocol/contracts/rrp/interfaces/ITemplateUtilsV0.sol


pragma solidity ^0.8.0;

interface ITemplateUtilsV0 {
    event CreatedTemplate(
        bytes32 indexed templateId,
        address airnode,
        bytes32 endpointId,
        bytes parameters
    );

    function createTemplate(
        address airnode,
        bytes32 endpointId,
        bytes calldata parameters
    ) external returns (bytes32 templateId);

    function getTemplates(bytes32[] calldata templateIds)
        external
        view
        returns (
            address[] memory airnodes,
            bytes32[] memory endpointIds,
            bytes[] memory parameters
        );

    function templates(bytes32 templateId)
        external
        view
        returns (
            address airnode,
            bytes32 endpointId,
            bytes memory parameters
        );
}

// File: @api3/airnode-protocol/contracts/rrp/interfaces/IAuthorizationUtilsV0.sol


pragma solidity ^0.8.0;

interface IAuthorizationUtilsV0 {
    function checkAuthorizationStatus(
        address[] calldata authorizers,
        address airnode,
        bytes32 requestId,
        bytes32 endpointId,
        address sponsor,
        address requester
    ) external view returns (bool status);

    function checkAuthorizationStatuses(
        address[] calldata authorizers,
        address airnode,
        bytes32[] calldata requestIds,
        bytes32[] calldata endpointIds,
        address[] calldata sponsors,
        address[] calldata requesters
    ) external view returns (bool[] memory statuses);
}

// File: @api3/airnode-protocol/contracts/rrp/interfaces/IAirnodeRrpV0.sol


pragma solidity ^0.8.0;




interface IAirnodeRrpV0 is
    IAuthorizationUtilsV0,
    ITemplateUtilsV0,
    IWithdrawalUtilsV0
{
    event SetSponsorshipStatus(
        address indexed sponsor,
        address indexed requester,
        bool sponsorshipStatus
    );

    event MadeTemplateRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        uint256 requesterRequestCount,
        uint256 chainId,
        address requester,
        bytes32 templateId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes parameters
    );

    event MadeFullRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        uint256 requesterRequestCount,
        uint256 chainId,
        address requester,
        bytes32 endpointId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes parameters
    );

    event FulfilledRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        bytes data
    );

    event FailedRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        string errorMessage
    );

    function setSponsorshipStatus(address requester, bool sponsorshipStatus)
        external;

    function makeTemplateRequest(
        bytes32 templateId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata parameters
    ) external returns (bytes32 requestId);

    function makeFullRequest(
        address airnode,
        bytes32 endpointId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata parameters
    ) external returns (bytes32 requestId);

    function fulfill(
        bytes32 requestId,
        address airnode,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata data,
        bytes calldata signature
    ) external returns (bool callSuccess, bytes memory callData);

    function fail(
        bytes32 requestId,
        address airnode,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        string calldata errorMessage
    ) external;

    function sponsorToRequesterToSponsorshipStatus(
        address sponsor,
        address requester
    ) external view returns (bool sponsorshipStatus);

    function requesterToRequestCountPlusOne(address requester)
        external
        view
        returns (uint256 requestCountPlusOne);

    function requestIsAwaitingFulfillment(bytes32 requestId)
        external
        view
        returns (bool isAwaitingFulfillment);
}

// File: @api3/airnode-protocol/contracts/rrp/requesters/RrpRequesterV0.sol


pragma solidity ^0.8.0;


/// @title The contract to be inherited to make Airnode RRP requests
contract RrpRequesterV0 {
    IAirnodeRrpV0 public immutable airnodeRrp;

    /// @dev Reverts if the caller is not the Airnode RRP contract.
    /// Use it as a modifier for fulfill and error callback methods, but also
    /// check `requestId`.
    modifier onlyAirnodeRrp() {
        require(msg.sender == address(airnodeRrp), "Caller not Airnode RRP");
        _;
    }

    /// @dev Airnode RRP address is set at deployment and is immutable.
    /// RrpRequester is made its own sponsor by default. RrpRequester can also
    /// be sponsored by others and use these sponsorships while making
    /// requests, i.e., using this default sponsorship is optional.
    /// @param _airnodeRrp Airnode RRP contract address
    constructor(address _airnodeRrp) {
        airnodeRrp = IAirnodeRrpV0(_airnodeRrp);
        IAirnodeRrpV0(_airnodeRrp).setSponsorshipStatus(address(this), true);
    }
}

// File: @openzeppelin/contracts/utils/Base64.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/utils/math/Math.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;


/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;








/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}
}

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;



/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        if (batchSize > 1) {
            // Will only trigger during construction. Batch transferring (minting) is not available afterwards.
            revert("ERC721Enumerable: consecutive transfers not supported");
        }

        uint256 tokenId = firstTokenId;

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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
}

// File: Gainlings/GainlingsStorage.sol



pragma solidity ^0.8.0;



contract GainlingsStorage is Ownable {

    constructor()   {
        seedTraits();
        seedPossibilities();
        seedEffects();
    }
    
    string public imageStartString;
    string public imageEndString;
    string public characterImage;
    string public unrevealedImage;

    mapping(string => string[]) private _possibleTraits;  //_traitTypeName ->possibleTraits 
    mapping(string => uint256[])private _traitPossibilities;  //_traitTypeName ->possibilies to get the trait
    mapping(string => int256[3]) private _traitEffects; //trait => effects

    string[6] private _traitTypeNames = ["Armour","Boots","Helmet","Shield","Weapon","Aura"]; 
    //["Attack","Defense","Weight"]; 

    function seedTraits() private {

        _possibleTraits[_traitTypeNames[0]] = ["None","SwimWear","Toga","TornTop","Leather","Chainmail","Firechain","Ninja","LifeJacket","Golden","Fatbelly","Jedi","Nun Top","Sixpack","Target"];
        _possibleTraits[_traitTypeNames[1]] = ["Grass","Leatherette","Sneakers","Fine","Fire","Diving","Socks","Winged","Electric","Heals","Cowboy","Hover","Rockets","Rollers","Sandals"];
        _possibleTraits[_traitTypeNames[2]] = ["Trucker","Propeller","PaperBoat","Witch","Viking","Headphones","Sweatband","Ninjamask","DirtyTrucker","Spartan","Bloody","Feather","Sombrero","Gasmask","Hockeymask"];
        _possibleTraits[_traitTypeNames[3]] = ["Rusty Buckler","Light Buckler","Hardened Buckler","Plain Square","Gold Square","Legion Square","Weighted Heater","Gold Studded Heater","Liquid Studded Heater","Solid Gold Heater","Blank Face","Butterknife","Storm Plate","Thunderbolt","Trophy"];
        _possibleTraits[_traitTypeNames[4]] = ["Scissors","Luxury Pistol","Longsword","Laser","Golfbat","Dog Leash","Rocket Launcher","Chainsaw","Calculator","Bubblegun","Hammer","Lasso","Light Saber","Molotov","Scoped Pistol"];
        _possibleTraits[_traitTypeNames[5]] = ["Aqua","Blood","Cute","Dark","Earth","Gold","Heaven","Nature","Psychic","Sweet","Angel","Orc","Paladin","Werewolf","Wizards"];

    } 
    function seedPossibilities() private {
        _traitPossibilities[_traitTypeNames[0]] =  [125,245,355,460,560,650,730,800,860,910,950,975,990,996,1000]; // 12.5% / 12% / 11% / 10.5% / 10% / 9% / 8% / 7% / 6% / 5% / 4% / 2.5% / 1.5% / 0.6% / 0.4%
        _traitPossibilities[_traitTypeNames[1]] =  [125,245,355,460,560,650,730,800,860,910,950,975,990,996,1000];
        _traitPossibilities[_traitTypeNames[2]] =  [125,245,355,460,560,650,730,800,860,910,950,975,990,996,1000];
        _traitPossibilities[_traitTypeNames[3]] =  [125,245,355,460,560,650,730,800,860,910,950,975,990,996,1000];
        _traitPossibilities[_traitTypeNames[4]] =  [125,245,355,460,560,650,730,800,860,910,950,975,990,996,1000];
        _traitPossibilities[_traitTypeNames[5]] =  [67,134,201,268,335,402,469,536,603,670,737,804,871,938,1000]; //6.7% each
        
    }
    function seedEffects() private {

        //Armour
            _traitEffects["None"] =         [int256(0),int256(5),int256(0)];
            _traitEffects["SwimWear"] =     [int256(0),int256(10),int256(100)];
            _traitEffects["Toga"] =         [int256(0),int256(25),int256(250)];
            _traitEffects["TornTop"] =      [int256(0),int256(40),int256(300)];
            _traitEffects["Leather"] =      [int256(0),int256(50),int256(250)];
            _traitEffects["Chainmail"] =    [int256(0),int256(55),int256(250)];
            _traitEffects["Firechain"] =    [int256(0),int256(60),int256(350)];
            _traitEffects["Ninja"] =        [int256(0),int256(60),int256(180)];
            _traitEffects["LifeJacket"] =   [int256(0),int256(75),int256(250)];
            _traitEffects["Golden"] =         [int256(0),int256(100),int256(800)];
            _traitEffects["Fatbelly"] =     [int256(0),int256(80),int256(700)];
            _traitEffects["Jedi"] =         [int256(0),int256(80),int256(600)];
            _traitEffects["Nun Top"] =      [int256(0),int256(100),int256(500)];
            _traitEffects["Sixpack"] =      [int256(50),int256(20),int256(100)];
            _traitEffects["Target"] =       [int256(50),int256(0),int256(10)];

        //Boots
            _traitEffects["Grass"] =        [int256(0),int256(5),int256(100)];
            _traitEffects["Leatherette"] =      [int256(0),int256(5),int256(80)];
            _traitEffects["Sneakers"] =     [int256(0),int256(8),int256(85)];
            _traitEffects["Fine"] =         [int256(0),int256(8),int256(75)];
            _traitEffects["Fire"] =         [int256(10),int256(10),int256(125)];
            _traitEffects["Diving"] =       [int256(0),int256(10),int256(100)];
            _traitEffects["Socks"] =        [int256(0),int256(12),int256(125)];
            _traitEffects["Winged"] =       [int256(0),int256(12),int256(60)];
            _traitEffects["Electric"] =     [int256(15),int256(14),int256(200)];
            _traitEffects["Heals"] =        [int256(0),int256(14),int256(125)];
            _traitEffects["Cowboy"] =       [int256(0),int256(16),int256(150)];
            _traitEffects["Hover"] =        [int256(0),int256(16),int256(80)];
            _traitEffects["Rockets"] =      [int256(0),int256(20),int256(80)];
            _traitEffects["Rollers"] =      [int256(0),int256(25),int256(150)];
            _traitEffects["Sandals"] =      [int256(0),int256(25),int256(125)];
        
        //Helmet
            _traitEffects["Trucker"] =      [int256(0),int256(25),int256(250)];
            _traitEffects["Propeller"] =    [int256(0),int256(10),int256(50)];
            _traitEffects["PaperBoat"] =    [int256(0),int256(30),int256(200)]; 
            _traitEffects["Witch"] =        [int256(0),int256(35),int256(200)];
            _traitEffects["Viking"] =       [int256(10),int256(40),int256(350)];
            _traitEffects["Headphones"] =   [int256(0),int256(45),int256(250)]; 
            _traitEffects["Sweatband"] =    [int256(0),int256(30),int256(125)];
            _traitEffects["Ninjamask"] =    [int256(0),int256(35),int256(125)];
            _traitEffects["DirtyTrucker"] = [int256(0),int256(50),int256(350)]; 
            _traitEffects["Spartan"] =      [int256(0),int256(75),int256(400)];
            _traitEffects["Bloody"] =       [int256(0),int256(50),int256(250)]; 
            _traitEffects["Feather"] =      [int256(0),int256(20),int256(80)]; 
            _traitEffects["Sombrero"] =     [int256(0),int256(30),int256(125)]; 
            _traitEffects["Gasmask"] =      [int256(0),int256(75),int256(180)]; 
            _traitEffects["Hockeymask"] =   [int256(0),int256(75),int256(150)]; 
            
        //Shield
            _traitEffects["Rusty Buckler"] =        [int256(0),int256(25),int256(900)];
            _traitEffects["Light Buckler"] =        [int256(0),int256(25),int256(800)];
            _traitEffects["Hardened Buckler"] =     [int256(0),int256(30),int256(900)];        
            _traitEffects["Plain Square"] =         [int256(0),int256(40),int256(800)];
            _traitEffects["Gold Square"] =          [int256(0),int256(50),int256(1000)];
            _traitEffects["Legion Square"] =        [int256(0),int256(45),int256(800)];        
            _traitEffects["Weighted Heater"] =      [int256(0),int256(45),int256(700)];
            _traitEffects["Gold Studded Heater"] =  [int256(0),int256(60),int256(1100)];
            _traitEffects["Liquid Studded Heater"] =[int256(0),int256(50),int256(800)];        
            _traitEffects["Solid Gold Heater"] =    [int256(0),int256(75),int256(1200)];
            _traitEffects["Blank Face"] =           [int256(0),int256(55),int256(700)];
            _traitEffects["Butterknife"] =          [int256(40),int256(0),int256(300)];
            _traitEffects["Storm Plate"] =          [int256(0),int256(75),int256(900)];
            _traitEffects["Thunderbolt"] =          [int256(25),int256(50),int256(1000)];
            _traitEffects["Trophy"] =               [int256(50),int256(25),int256(800)];
            

        //Weapon
            _traitEffects["Scissors"] =             [int256(200),int256(0),int256(500)];
            _traitEffects["Luxury Pistol"] =        [int256(320),int256(0),int256(900)];
            _traitEffects["Longsword"] =            [int256(350),int256(0),int256(500)]; 
            _traitEffects["Laser"] =                [int256(300),int256(0),int256(700)];
            _traitEffects["Golfbat"] =              [int256(250),int256(0),int256(900)];
            _traitEffects["Dog Leash"] =            [int256(250),int256(0),int256(700)]; 
            _traitEffects["Rocket Launcher"] =      [int256(450),int256(0),int256(500)];
            _traitEffects["Chainsaw"] =             [int256(400),int256(0),int256(1100)];
            _traitEffects["Calculator"] =           [int256(380),int256(0),int256(800)];
            _traitEffects["Bubblegun"] =            [int256(400),int256(0),int256(700)];
            _traitEffects["Hammer"] =               [int256(500),int256(0),int256(1600)];
            _traitEffects["Lasso"] =                [int256(420),int256(0),int256(700)];
            _traitEffects["Light Saber"] =          [int256(420),int256(0),int256(600)];
            _traitEffects["Molotov"] =              [int256(450),int256(0),int256(800)];
            _traitEffects["Scoped Pistol"] =        [int256(480),int256(0),int256(600)];
            
        //Background
            _traitEffects["Aqua"] = [int256(0),int256(0),int256(0)];
            _traitEffects["Blood"] = [int256(0),int256(0),int256(0)];
            _traitEffects["Cute"] = [int256(0),int256(0),int256(0)];
            _traitEffects["Dark"] = [int256(0),int256(0),int256(0)];
            _traitEffects["Earth"] = [int256(0),int256(0),int256(0)];
            _traitEffects["Gold"] = [int256(0),int256(0),int256(0)];
            _traitEffects["Heaven"] = [int256(0),int256(0),int256(0)];
            _traitEffects["Nature"] = [int256(0),int256(0),int256(0)];
            _traitEffects["Psychic"] = [int256(0),int256(0),int256(0)];
            _traitEffects["Sweet"] = [int256(0),int256(0),int256(0)];
            _traitEffects["Angel"] = [int256(0),int256(0),int256(0)];
            _traitEffects["Orc"] = [int256(0),int256(0),int256(0)];
            _traitEffects["Paladin"] = [int256(0),int256(0),int256(0)];
            _traitEffects["Werewolf"] = [int256(0),int256(0),int256(0)];
            _traitEffects["Wizards"] = [int256(0),int256(0),int256(0)];
        
   
    }

    function overrideTraitTypeNames(string[6] memory traitTypeNames) public onlyOwner{
        _traitTypeNames = traitTypeNames;
    }
    function overridePossibleTraits(string[][6]memory possibleTraits) public onlyOwner{
        for(uint256 i = 0; i <possibleTraits.length;i++ ){
             _possibleTraits[_traitTypeNames[i]] = possibleTraits[i];
        }
    }    
    function overrideTraitPossibilities(uint256[][6]memory traitPossibilities) public onlyOwner{
        for(uint256 i = 0; i < traitPossibilities.length; i++){
             _traitPossibilities[_traitTypeNames[i]] = traitPossibilities[i];
        }
    }
    function overrideTraitEffects(string[] memory traitNames, int256[3][] memory traitValues) public onlyOwner{
        for(uint256 i = 0; i < traitNames.length; i++){
             _traitEffects[traitNames[i]] = traitValues[i];
        }
    }
    
    function retrievePossibleTrait(uint256  traitTypeNr) public view returns (string[] memory){
        string memory traitTypeName = _traitTypeNames[traitTypeNr];
        return _possibleTraits[traitTypeName];
    }
    function retrieveTraitPossibility(uint256  traitTypeNr) public view returns (uint256[] memory){
        string memory traitTypeName = _traitTypeNames[traitTypeNr];
        return _traitPossibilities[traitTypeName];
    }
    function retrieveTraitEffect(string memory traitName) public view returns (int256[3] memory){
        return _traitEffects[traitName];
    }



    function setImageStartString(string memory _imageStartString) public {
        imageStartString = _imageStartString;
    }
    function setImageEndString(string memory _imageEndString) public {
        imageEndString = _imageEndString;
    }
    function setCharacterImageString(string memory _characterImage) public {
        characterImage = _characterImage;
    }
    function setUnrevealedImageString(string memory _unrevaledImage) public {
        unrevealedImage = _unrevaledImage;
    }


    mapping(uint256 => mapping (string => string)) private _art;  //_traitTypeName ->possibleTraits 


    function writeImage(uint256 _type,string memory _name, string memory data)public onlyOwner{
        _art[_type][_name] = data;
    }
    function getImageRaw(uint256 _type, string memory _name)public view returns (string memory data){
        return _art[_type][_name];
    }
    function getCompleteImage(string [6] memory _traitNames) public view returns (string memory data){
        //TRAIT NAMES COME IN WRONG ORDER THUS NO RESULT THUS NAKED GAINLING
        data =  string(abi.encodePacked(imageStartString,_art[5][_traitNames[5]],characterImage));

        for(uint256 i = 0;i < _traitNames.length-1 ; i++){
            string memory art = _art[i][_traitNames[i]];
            data = string(abi.encodePacked(data,art));
        }
        data =  string(abi.encodePacked(data,imageEndString));
        return data;
    }
    function getUnrevealedImage()public view returns (string memory data){
        data =  string(abi.encodePacked(imageStartString,unrevealedImage,imageEndString));
        return data;
    }
    
}

//0x9B7849d01B42da57AE388a2e410f95FEE8CbA26c
//0x28c9a31366a94B2E8302a8CA999984d771d83373
// File: @openzeppelin/contracts/access/IAccessControl.sol


// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// File: @openzeppelin/contracts/access/AccessControl.sol


// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;





/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// File: Gainlings/GainlingsLibrary.sol


pragma solidity ^0.8.0;




contract GainlingsLibrary is Ownable {

    ///// libraries \\\\\
    using Strings for uint256;

    constructor()   {
       
    }
    
    function getFightResultOutput(uint256 attacker, uint256 defender, uint256 aRandom, uint256 bRandom, uint256 winner) public view returns (string memory output){
         bytes memory dataURI = abi.encodePacked(
            '{',
                '"attacker": "',attacker.toString(),'",',
                '"defender": "',defender.toString(),'",',
                '"aRandom": "',aRandom.toString(),'",',
                '"dRandom": "',bRandom.toString(),'",',     
                '"time": "',block.timestamp.toString(),'",', 
                '"winner": "',winner.toString(),'"');
               
        dataURI = abi.encodePacked(dataURI,'}');
        return string(dataURI);
    }
    function getMintResultOutput(uint256 tokenId, uint256 tokenSeed) public pure returns (string memory output){
        //_tokenBounties[tokenId]
         bytes memory dataURI = abi.encodePacked(
            '{',
                '"id": "',tokenId.toString(),'",',
                '"seed": "',tokenSeed.toString(),'"');
               
        dataURI = abi.encodePacked(dataURI,'}');
        return string(dataURI);
    }
    function splitRandom(uint256 numbers) public pure returns (uint256[6] memory randoms){
        uint256 a = 999;
         return [
            numbers % a,
            (numbers / a) % a,
            (numbers / a / a) % a,
            (numbers / a / a / a) % a,
            (numbers / a / a / a / a) % a,
            (numbers / a / a / a / a / a) % a
        ];
    }
    function splitRandomInTwo(uint256 numbers) public pure returns (uint256[2] memory randoms){
        uint256 a = 999;
         return [
            numbers % a,
            (numbers / a) % a
        ];
    }
    function splitRandomAvgWithOffset(uint256 numbers,uint256 min1, uint256 min2) public pure returns (uint256[2] memory randoms){
        uint256 a = 999 - min1;
        uint256 b = 999 - min2;

        uint256[6] memory rnds =  [
            numbers % a + min1,
            (numbers / a) % a + min1,
            (numbers / a / a) % a + min1,
            (numbers / a / a / b) % b + min2,
            (numbers / a / a / b / b) % b + min2,
            (numbers / a / a / b / b / b) % b + min2
            
        ];

         return [
            (rnds[0] + rnds[1] + rnds[2]) / 3,
            (rnds[3] + rnds[4] + rnds[5]) / 3
        ];
    }
    function splitRandomInTwoAvgWithOffset(uint256 numbers,uint256 min1, uint256 min2) public pure returns (uint256[2] memory randoms){
        uint256 a = 999 - min1;
        uint256 b = 999 - min2;

        uint256[4] memory rnds =  [
            numbers % a + min1,
            (numbers / a) % a + min1,
            (numbers / a / b) % b + min2,
            (numbers / a / b / b) % b + min2
        ];

         return [
            (rnds[0] + rnds[1]) / 2,
            (rnds[2] + rnds[3]) / 2
        ];
    }
}

//0x9B7849d01B42da57AE388a2e410f95FEE8CbA26c
//0x28c9a31366a94B2E8302a8CA999984d771d83373
// File: @openzeppelin/contracts/utils/cryptography/MerkleProof.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// File: Gainlings/GainlingsFactory.sol


pragma solidity ^0.8.0;












contract GainlingsFactory is ERC721Enumerable, RrpRequesterV0, ReentrancyGuard, Ownable
{
    struct AttackRequest{
        Warrior attacker;
        Warrior defender;
    }
    struct Warrior{
        uint256 id;
        uint256 attack;
        uint256 defense;
        uint256 weight;
        int256 cat;
    }


    ///// API3 \\\\
    address public airnode;
    bytes32 public endpointIdUint256;
    address public sponsorWallet;

    ///// interfaces \\\\
    GainlingsStorage _traitStorage;
    GainlingsLibrary _gainlingsLibrary;

    ///// libraries \\\\\
    using Strings for uint256;

    ///// properties \\\\\
    address private _traitStorageAddress;
    address private _libraryAddress;

    uint256 public _phase = 0;
    uint256 public _baseCoolDown = 3600;
    uint256 public _baseAttack = 1000;
    uint256 public _baseDefense = 250;
    uint256 public _seasonStartBlock = 0;
    uint256 public _seasonBattleStartBlockTime = 0;
    uint256 public _seasonNumber = 0;


    string private _imageBaseUri = "";
    string private _animationBaseUri = "";
    bytes32 public merkleRoot;

    ///// parameters \\\\\
    uint256 private _totalMint = 10000;
    uint256 public _publicPrice = 0.0001 ether;
    uint256 public _buffStartFactor = 228;
    uint256 public _trophySubtrahend = 28;
    uint256 public _maxLevel = 8;
    uint256 public _weightMultiplier = 1;
    uint256 public _cooldownBuff = 200;
    uint256 public _randomCap = 990;
    bool public _startCooldownActive = false;


   // event GainlingsEvent(uint256 outputType, string output);

    event GainlingApproached(
        uint256 attacker,
        uint256 defender,
        uint256 aBounty,
        uint256 dBounty,
        uint256 aStack,
        uint256 dStack
    );
    event GainlingAttacked(
        uint256 attacker,
        uint256 defender,
        uint256 aRandom,
        uint256 dRandom,
        uint256 time,
        uint256 winner
    );
    event GainlingMinted(
        address indexed issuer,
        uint256 quantity
    );
    event GainlingSeeded(
        uint256 indexed tokenId,
        uint256 seed
    );
    event StageIncreased(
        uint256 indexed stage
    );

    ///// dictionaries \\\\\
    mapping(uint256 => uint256)     public _tokenSeeds;
    mapping(bytes32 => bool)        public requestToWaitingState;
    mapping(bytes32 => uint256)     public requestToTokenId;
    mapping(bytes32 => AttackRequest) private requestIdToAttackRequest; 

    mapping(uint256 => uint256)   public _tokenLevels;
    mapping(uint256 => uint256)   public _tokenBounties;
    mapping(uint256 => uint256)   public _tokenStacks;
    mapping(uint256 => uint256)   private _tokenLabn; 
    mapping(string => int256)     private _combatStyles;
    mapping(uint256 => bool)      private _warriorLocks;
    mapping(uint256 => address)   private _founderWallets;
    mapping(uint256 => Warrior)   private _preppedWarriors;
    mapping(address => uint256)   public _mints;

    string[] private _traitTypeNames = ["Armour","Boots","Helmet","Shield","Weapon","Aura"]; 
    string[] private _attributeNames = ["Attack", "Defense", "Weight"]; 

    constructor( address _airnodeRrp) 
    ERC721("The Gainlings P2B", "TGS") 
    RrpRequesterV0(_airnodeRrp) {
        initContract();
        _seasonNumber = 0;
        _seasonStartBlock = block.number;
    }


    function initContract() internal {
        _combatStyles["Aqua"] = 0;
        _combatStyles["Blood"] = 1;
        _combatStyles["Cute"] = 2;
        _combatStyles["Dark"] = 3;
        _combatStyles["Earth"] = 4;
        _combatStyles["Gold"] = 5;
        _combatStyles["Heaven"] = 6;
        _combatStyles["Nature"] = 7;
        _combatStyles["Psychic"] = 8;
        _combatStyles["Sweet"] = 9;
        _combatStyles["Angel"] = 10;
        _combatStyles["Orc"] = 11;
        _combatStyles["Paladin"] = 12;
        _combatStyles["Werewolf"] = 13;
        _combatStyles["Wizards"] = 14;

        _founderWallets[0] = 0x70e896078078b3d912F0e568862b372e6e435a1C;
        _founderWallets[1] = 0x7dC68D8ac0E8aa16DA49e4a8b19ff77071F8b6a8;
        _founderWallets[2] = 0xA410bCd7Ec410b1EF5b50E88f050BD1D8a7bEee8;
        _founderWallets[3] = 0xb55c5190eB8593da7bDF5bDcF7093761a18bc849;
        _founderWallets[4] = 0xcafcF692cB351C48F1d95Cb1031aFE00a39b5740;
    }

    ///// API3 \\\\
    function setRequestParameters(address _airnode,bytes32 _endpointIdUint256,address _sponsorWallet)  external onlyOwner {
        airnode = _airnode;
        endpointIdUint256 = _endpointIdUint256;
        sponsorWallet = _sponsorWallet;
    }
    function whitelistMint(uint256 amount, bytes32[] calldata _proof) external payable nonReentrant{
        uint256 supply = totalSupply();
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        uint256 mints =  _mints[msg.sender];
        require(mints + amount <= 5, "only five per wallet");
        require(MerkleProof.verify(_proof, merkleRoot, leaf), "not on the list?");
        require(_phase == 1, "Its not allowlist minting phase");
        require(totalSupply() + amount <= _totalMint, "token supply to small");
        require(msg.value >= amount * _publicPrice, "ether sent is not correct");
        _mints[msg.sender] = mints + amount;

        for (uint256 i; i < amount; i++) {

            bytes32 requestId = airnodeRrp.makeFullRequest(airnode, endpointIdUint256, address(this),sponsorWallet,address(this),this.fulfillRandomnessMint.selector, "" );

            requestToWaitingState[requestId] = true;
            requestToTokenId[requestId] = supply + i;

            _safeMint(msg.sender, supply + i);
            _tokenBounties[supply + i] = msg.value / amount / 10 * 8;
            _tokenStacks [supply + i] = 0;
            _tokenLevels [supply + i] = 0;
            
        }
        emit GainlingMinted(msg.sender,amount);
        //emit GainlingsEvent(0, amount.toString());
    }
    function mintAirdrop(uint256 amount)  external payable nonReentrant onlyOwner{
        uint256 supply = totalSupply();
        require(totalSupply() + amount <= _totalMint, "token supply to small");
        require(msg.value >= amount * _publicPrice, "ether sent is not correct");

        for (uint256 i; i < amount; i++) {

            bytes32 requestId = airnodeRrp.makeFullRequest(
                airnode, 
                endpointIdUint256, 
                address(this),
                sponsorWallet,
                address(this),
                this.fulfillRandomnessMint.selector, "" );

            requestToWaitingState[requestId] = true;
            requestToTokenId[requestId] = supply + i;

            _safeMint(msg.sender, supply + i);
            _tokenBounties[supply + i] = msg.value / amount / 10 * 8;
            _tokenStacks [supply + i] = 0;
            _tokenLevels [supply + i] = 0;
        }

         emit GainlingMinted(msg.sender,amount);
        //emit GainlingsEvent(0, amount.toString());
    }
    function mintQRNG(uint256 amount)  external payable nonReentrant{
        uint256 supply = totalSupply();
        uint256 mints =  _mints[msg.sender];
        require(mints + amount <= 5, "only five per wallet"); 
        require(_phase == 2, "Its not public minting phase");
        require(totalSupply() + amount <= _totalMint, "token supply to small");
        require(msg.value >= amount * _publicPrice, "ether sent is not correct");
        _mints[msg.sender] = mints + amount;

        for (uint256 i; i < amount; i++) {

            bytes32 requestId = airnodeRrp.makeFullRequest(
                airnode, 
                endpointIdUint256, 
                address(this),
                sponsorWallet,
                address(this),
                this.fulfillRandomnessMint.selector, "" );

            requestToWaitingState[requestId] = true;
            requestToTokenId[requestId] = supply + i;

            _safeMint(msg.sender, supply + i);
            _tokenBounties[supply + i] = msg.value / amount / 10 * 8;
            _tokenStacks [supply + i] = 0;
            _tokenLevels [supply + i] = 0;
        }

        emit GainlingMinted(msg.sender,amount);
        //emit GainlingsEvent(0, amount.toString());
    }
    function reseedMint(uint256 tokenId) external onlyOwner {
        require(_tokenSeeds[tokenId] == 0, "already seeded");
        
        bytes32 requestId = airnodeRrp.makeFullRequest(
            airnode, 
            endpointIdUint256, 
            address(this),
            sponsorWallet,
            address(this),
            this.fulfillRandomnessMint.selector, "" );

        requestToWaitingState[requestId] = true;
        requestToTokenId[requestId] = tokenId;
    }
    function fulfillRandomnessMint(bytes32 requestId, bytes calldata data) external onlyAirnodeRrp{
        require( requestToWaitingState[requestId],"Request ID not known");

        requestToWaitingState[requestId] = false;
        uint256 qrngUint256 = abi.decode(data, (uint256));
        uint256 tokenId = requestToTokenId[requestId];
        
        _tokenSeeds[tokenId] = qrngUint256;
        _preppedWarriors[tokenId] = getPreppedWarrior(tokenId); 

         emit GainlingSeeded(tokenId,qrngUint256);
         //emit GainlingsEvent(4, _gainlingsLibrary.getMintResultOutput(tokenId,qrngUint256));
    }
    function fulfillRandomnessAttack(bytes32 requestId, bytes calldata data) external onlyAirnodeRrp{
        require(requestToWaitingState[requestId],"Request ID not known");

        requestToWaitingState[requestId] = false;
        uint256 qrngUint256 = abi.decode(data, (uint256));
        AttackRequest memory attackRequest = requestIdToAttackRequest[requestId];
        attackWarrior(attackRequest,qrngUint256);
    }
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }
    function isTokenInCooldown(uint256 id, uint256 weight) public view returns (bool isInCooldown){
        uint256 _defenderLastAttack = _tokenLabn[id] > _seasonBattleStartBlockTime ? _tokenLabn[id] : _seasonBattleStartBlockTime; 
        isInCooldown =  (_defenderLastAttack + weight*_weightMultiplier)  >= block.timestamp;
        return isInCooldown;
    }
    ///// game functions \\\\\
    function attack(uint256 attackerTokenId, uint256 defenderTokenId) external nonReentrant  {
        require(gasleft() > 600000, "I need a lot of gas");
        require(_phase == 4, "its not the right time");
        require(attackerTokenId != defenderTokenId, "attacker is defender");
        require(_exists(attackerTokenId) , "attacker already dead");
        require(_exists(defenderTokenId) , "defender already dead");
        require(ownerOf(attackerTokenId) == msg.sender, "not owner of this token");
        require(_warriorLocks[attackerTokenId] == false, "attacker already in a fight");
        require(_warriorLocks[defenderTokenId] == false, "defender already in a fight");
        Warrior memory attacker = getPrePreppedWarrior(attackerTokenId);
        Warrior memory defender =  getPrePreppedWarrior(defenderTokenId);


        uint256 _tokenLastAttack = _tokenLabn[attacker.id]; 
        if(_startCooldownActive){
            _tokenLastAttack =  _tokenLabn[attacker.id] > _seasonBattleStartBlockTime ? _tokenLabn[attacker.id] : _seasonBattleStartBlockTime; 
        }

        require((_tokenLastAttack + attacker.weight*_weightMultiplier)  <= block.timestamp, "please cool down"); 

        _warriorLocks[attackerTokenId] = true;
        _warriorLocks[defenderTokenId] = true;

        //emit GainlingsEvent(1, getFightStartOutput(attackerTokenId, defenderTokenId));

        bytes32 requestId = airnodeRrp.makeFullRequest(
            airnode,
            endpointIdUint256,
            address(this),
            sponsorWallet,
            address(this),
            this.fulfillRandomnessAttack.selector,
            ""
        );
        requestToWaitingState[requestId] = true;
        requestIdToAttackRequest[requestId] = AttackRequest(attacker,defender);

        emit GainlingApproached(
            attackerTokenId,
            defenderTokenId,
            _tokenBounties[attackerTokenId],
            _tokenBounties[defenderTokenId],
            _tokenStacks[attackerTokenId],
            _tokenStacks[defenderTokenId]);   

    }
    function attackWarrior(AttackRequest memory attackRequest,uint256 randomness)  internal  {

        //_approveuint256[2] memory randoms = splitRandomInTwo(randomness);
        uint256 attackerAttack = attackRequest.attacker.attack;
        uint256 defenderAttack = attackRequest.defender.attack;

        uint256 attRandMin = _buffStartFactor * _tokenLevels[attackRequest.attacker.id] - ((_tokenLevels[attackRequest.attacker.id]+1) * _tokenLevels[attackRequest.attacker.id] * _trophySubtrahend / 2);
        uint256 defRandMin = _buffStartFactor * _tokenLevels[attackRequest.defender.id] - ((_tokenLevels[attackRequest.defender.id]+1) * _tokenLevels[attackRequest.defender.id] * _trophySubtrahend / 2);
        
        if(isTokenInCooldown(attackRequest.defender.id,attackRequest.defender.weight)){
            defRandMin = defRandMin + _cooldownBuff;
            defRandMin = defRandMin > _randomCap ? _randomCap : defRandMin;
        }

        uint256[2] memory randoms = _gainlingsLibrary.splitRandomAvgWithOffset(randomness,attRandMin,defRandMin);
        attackerAttack += randoms[0];
        defenderAttack += randoms[1];

        int256 catNumber = int256(attackRequest.defender.cat) - int256(attackRequest.attacker.cat);
      
        if(catNumber == 1 || catNumber == -14)//attacker bonus
        {
            attackerAttack = attackerAttack + attackRequest.attacker.defense;
        }
        else if(catNumber == -1 || catNumber == 14)// defender bonus
        {
            defenderAttack = defenderAttack + attackRequest.defender.defense;
        }
        else
        {
            attackerAttack = attackerAttack + attackRequest.attacker.defense;
            defenderAttack = defenderAttack + attackRequest.defender.defense;
        }

        uint256 winnerToken = attackRequest.defender.id;
        uint256 loserToken = attackRequest.attacker.id;

        if (attackerAttack > defenderAttack) {
            winnerToken = attackRequest.attacker.id;
            loserToken = attackRequest.defender.id;
        }
        
        transferBounty(winnerToken,loserToken);
        withdrawStack(loserToken);
        _burn(loserToken);

        _tokenLevels[winnerToken] = _tokenLevels[winnerToken] + 1 > _maxLevel ? _maxLevel : _tokenLevels[winnerToken] + 1;
        _tokenLabn[attackRequest.attacker.id] = block.timestamp;
        _warriorLocks[attackRequest.attacker.id] = false;
        _warriorLocks[attackRequest.defender.id] = false;

        emit GainlingAttacked(
            attackRequest.attacker.id,
            attackRequest.defender.id,
            randoms[0],
            randoms[1],
            block.timestamp,
            winnerToken);   
        
        //emit GainlingsEvent(2,  _gainlingsLibrary.getFightResultOutput(attackRequest.attacker.id, attackRequest.defender.id, randoms[0], randoms[1],winnerToken));
    }
    function reseedAttack(uint256 attackerTokenId, uint256 defenderTokenId)public onlyOwner {
        Warrior memory attacker = getPrePreppedWarrior(attackerTokenId);
        Warrior memory defender =  getPrePreppedWarrior(defenderTokenId);

        bytes32 requestId = airnodeRrp.makeFullRequest(
            airnode,
            endpointIdUint256,
            address(this),
            sponsorWallet,
            address(this),
            this.fulfillRandomnessAttack.selector,
            ""
        );
        requestToWaitingState[requestId] = true;
        requestIdToAttackRequest[requestId] = AttackRequest(attacker,defender);

    }
    function transferBounty(uint256 winnerTokenId, uint256 loserTokenId) internal{
        uint256 share = _tokenBounties[loserTokenId] / 2;
        _tokenBounties[winnerTokenId] += share;
        _tokenStacks[winnerTokenId] += share;
        _tokenBounties[loserTokenId] = 0;
    }
    function withdrawStack(uint256 tokenId) internal {
        if( _tokenStacks[tokenId] > 0){
            address loser = ownerOf(tokenId);
            payable(loser).transfer(_tokenStacks[tokenId]);
        }
    }
    function getPrePreppedWarrior(uint256 tokenId) internal view returns(Warrior memory warrior) {
        return _preppedWarriors[tokenId];
    }
    function getPreppedWarrior(uint256 tokenId) internal view returns (Warrior memory warrior){
        string [6] memory stringTraits = buildTraitsFromSeed(_tokenSeeds[tokenId]);
        uint256[3] memory attributeTraits = buildAttributesTraits(stringTraits);

        warrior = Warrior(tokenId, attributeTraits[0],attributeTraits[1],attributeTraits[2],_combatStyles[stringTraits[5]]);
        
        return warrior;
    } 
    function buildTraitsFromSeed(uint256 numbers) internal view returns (string[6] memory traits){
        uint256[6] memory randoms = _gainlingsLibrary.splitRandom(numbers); 

        for (uint256 i = 0; i < _traitTypeNames.length; i++) {
            string memory trait = getRandomTrait(randoms[i], i);
            traits[i] = trait;
        }  
        return traits;
    }
    function buildAttributesTraits(string[6] memory traits) internal view returns (uint256[3] memory attributes){

        attributes = [
            _baseAttack,
            _baseDefense,
            _baseCoolDown
        ];

        for (uint256 j = 0;j < traits.length; j++ ) {
            string memory trait = traits[j];
            int256[3] memory traitModifiers = _traitStorage.retrieveTraitEffect(trait);
            for ( uint256 k = 0; k < attributes.length; k++) {
                attributes[k] += uint256(traitModifiers[k]);
            }
        }
        return attributes;
    }
    function getRandomTrait(uint256 random, uint256 traitTypeNr) internal  view  returns (string memory trait) {
        
        string[] memory possibleTraits = _traitStorage.retrievePossibleTrait(traitTypeNr);
        uint256[] memory possibilities = _traitStorage.retrieveTraitPossibility(traitTypeNr);
        bool control = true;

        for (uint256 i = 0; i < possibleTraits.length; i++) {
            if (random < possibilities[i] && control) {
                trait = possibleTraits[i];
                control = false;
            }
        }
        return trait;
    }
    function claimReward() external nonReentrant{
        require(totalSupply() == 1, "only one can get the reward");
        uint256 winnerToken = tokenByIndex(0);
        address ownerOfWinner = ownerOf(winnerToken);
        uint256 balance = address(this).balance;
        _burn(winnerToken);
        _tokenBounties[winnerToken] = 0;
        _tokenStacks[winnerToken] = 0;
        payable(ownerOfWinner).transfer(balance);
    }


    ///// owner functions \\\\\
    function increaseStage() external onlyOwner {
        _phase = _phase == 4 ? 0 : _phase + 1;
        if(_phase == 0) {//Contract reset, inactive

        }
        else if(_phase == 1){//Whitelist Mint open
            _seasonNumber++;
            _seasonStartBlock = block.number;
        }
        else if(_phase == 2){//Public Mint open
            
        }
        else if(_phase == 3){//Preparation
            
        }
        else if(_phase == 4){//Fight
            _seasonBattleStartBlockTime = block.timestamp;
            withdrawRake();
        }

        emit StageIncreased(_phase);
        //emit GainlingsEvent(3, _phase.toString());

    }
    function setImageBaseUri(string memory uri) external onlyOwner {
        _imageBaseUri = uri;
    }
    function setStorageAddress(address traitStorageAddress) external onlyOwner {
        _traitStorageAddress = traitStorageAddress;
        _traitStorage = GainlingsStorage(_traitStorageAddress);
    }
    function setLibraryAddress(address libraryAddress)external onlyOwner {
        _libraryAddress = libraryAddress;
        _gainlingsLibrary = GainlingsLibrary(_libraryAddress);
    }
    function setAnimationBaseUri(string memory uri) external onlyOwner {
        _animationBaseUri = uri;
    }

    function withdrawRake()internal {
        uint256 share = address(this).balance / 5 / 5;
        
        payable(_founderWallets[0]).transfer(share); //THE DRAWER
        payable(_founderWallets[1]).transfer(share); //THE TALKER
        payable(_founderWallets[2]).transfer(share); //THE CODER
        payable(_founderWallets[3]).transfer(share); //THE GENERALIST
        payable(_founderWallets[4]).transfer(share); //THE PROJECT
    }
    function setPrice(uint256 price) external onlyOwner {
        _publicPrice = price;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    ///// override basecontract \\\\\
    function tokenURI(uint256 tokenId)public view override  returns (string memory) {
        return getTokenUri(tokenId, true);
    }

    ///// private get \\\\\

    function getFightStartOutput(uint256 attacker, uint256 defender) internal view returns (string memory output){
        //_tokenBounties[tokenId]
         bytes memory dataURI = abi.encodePacked(
            '{',
                '"attacker": "',attacker.toString(),'",',
                '"defender": "',defender.toString(),'",',
                '"aBounty": "',_tokenBounties[attacker].toString(),'",',
                '"dBounty": "',_tokenBounties[defender].toString(),'",',
                '"aStack": "',_tokenStacks[attacker].toString(),'",',
                '"dStack": "',_tokenStacks[defender].toString(),'"');
               
        dataURI = abi.encodePacked(dataURI,'}');
        return string(dataURI);
    }

    ///// public get \\\\\
    function getTokenUri(uint256 tokenId,bool encode)public view returns (string memory){
        //require(_exists(tokenId), "invalid token ID");
        if(_tokenSeeds[tokenId] != 0){
            return getRevealedToken(tokenId,encode,_tokenSeeds[tokenId]);
        }
        else{
            return getUnrevealedToken(tokenId,encode);
        }
    }
    function getRevealedToken(uint256 tokenId,bool encode,uint256 seeed)internal view returns (string memory){
        //require(_exists(tokenId), "invalid token ID");
        
        string [6] memory stringTraits = buildTraitsFromSeed(seeed);
        uint256[3] memory attributeTraits = buildAttributesTraits(stringTraits);
        string memory svg = _traitStorage.getCompleteImage(stringTraits);
        string memory aliveString = _tokenBounties[tokenId] > 0 ? "true" : "false";
        bytes memory dataURI = abi.encodePacked(
            '{',
                '"name": "Gainling #',tokenId.toString(),'",', //name of the token
                '"description":"No risk?! No gains!",', //description
                '"animation_url":"',getAnimationURI(tokenId),'",', //webgl url
                '"external_url":"',getAnimationURI(tokenId),'",', //webgl url
                '"image_data":"',svg,'",', //title image url (example image before mint, real image after mint)
                '"attributes":',
                '[');
        dataURI = abi.encodePacked( dataURI,'{"trait_type":"Alive","value": "',aliveString,'"}');

            dataURI = abi.encodePacked( dataURI,',');
            for (uint256 i = 0; i < _traitTypeNames.length; i++) {
                string memory trait = stringTraits[i];
                dataURI = abi.encodePacked( dataURI,'{"trait_type":"', _traitTypeNames[i],'","value": "',trait,'"},'); //add all string attributes
            }
    
            for (uint256 j = 0; j < _attributeNames.length; j++) {
                string memory attribute = attributeTraits[j].toString();
                
                if(j < _attributeNames.length-1){
                    dataURI = abi.encodePacked(dataURI,'{"trait_type":"', _attributeNames[j],'","value": ',attribute,'},'); //add all integer attributes
                }
                else{
                    dataURI = abi.encodePacked(dataURI,'{"trait_type":"', _attributeNames[j],'","value": ',attribute,'}'); //missing the comma in the end, for the last entry only
                }
            }

        
        dataURI = abi.encodePacked(dataURI,']');
        dataURI = abi.encodePacked(dataURI,'}');
        if(!encode)return string(dataURI);
        return string(abi.encodePacked("data:application/json;base64,",Base64.encode(bytes(dataURI))));
    }
    function getUnrevealedToken(uint256 tokenId,bool encode)internal view returns (string memory){
        //require(_exists(tokenId), "invalid token ID");
        string memory svg = _traitStorage.getUnrevealedImage();
        string memory aliveString = _tokenBounties[tokenId] > 0 ? "true" : "false";
        bytes memory dataURI = abi.encodePacked(
            '{',
                '"name": "Gainling #',tokenId.toString(),'",', //name of the token
                '"description":"No risk?! No gains!",', //description
                '"animation_url":"',getAnimationURI(tokenId),'",', //webgl url
                '"external_url":"',getAnimationURI(tokenId),'",', //webgl url
                '"image_data":"',svg,'",', //title image url (example image before mint, real image after mint)
                '"attributes":',
                '[');
        dataURI = abi.encodePacked( dataURI,'{"trait_type":"Alive","value": "',aliveString,'"}]}');
        if(!encode)return string(dataURI);
        return string(abi.encodePacked("data:application/json;base64,",Base64.encode(bytes(dataURI))));
    }
    function getImageURI(uint256 tokenId) public view returns (string memory) {
        return string(abi.encodePacked(_imageBaseUri, tokenId.toString()));
    }
    function getAnimationURI(uint256 tokenId) public  view returns (string memory) {
        return string(abi.encodePacked(
                    _animationBaseUri,
                    "?tokenId=",
                    tokenId.toString()
                )
            );
    }
    function getBounty(uint256 tokenId) public view returns (uint256 bounty){
        return  _tokenBounties[tokenId];
    }
    function getStack(uint256 tokenId) public view returns (uint256 stack){
        return  _tokenStacks[tokenId];
    }
    function getCooldown(uint256 tokenId) public view returns (uint256 cooldown){
        uint256 lastAttack =_tokenLabn[tokenId];
        if(_startCooldownActive){
            lastAttack =  _tokenLabn[tokenId] > _seasonBattleStartBlockTime ? _tokenLabn[tokenId] : _seasonBattleStartBlockTime; 
        }
        Warrior memory tokenAttributes = getPreppedWarrior(tokenId);

        uint256 nextAttackBlock = lastAttack + tokenAttributes.weight * _weightMultiplier; 

        if(block.timestamp >= nextAttackBlock){
            cooldown = 0;
        }
        else{
            cooldown = nextAttackBlock - block.timestamp;
        }
        return cooldown;
    }
    function getTokenIds(address _owner)public view returns (uint256[] memory){
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) return new uint256[](0);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

}