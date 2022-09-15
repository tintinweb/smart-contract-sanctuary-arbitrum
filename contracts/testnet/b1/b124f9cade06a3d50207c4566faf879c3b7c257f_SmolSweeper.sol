// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

//           _____                    _____                   _______                   _____            _____                    _____                    _____                    _____
//          /\    \                  /\    \                 /::\    \                 /\    \          /\    \                  /\    \                  /\    \                  /\    \
//         /::\    \                /::\____\               /::::\    \               /::\____\        /::\    \                /::\____\                /::\    \                /::\    \
//        /::::\    \              /::::|   |              /::::::\    \             /:::/    /       /::::\    \              /:::/    /               /::::\    \              /::::\    \
//       /::::::\    \            /:::::|   |             /::::::::\    \           /:::/    /       /::::::\    \            /:::/   _/___            /::::::\    \            /::::::\    \
//      /:::/\:::\    \          /::::::|   |            /:::/~~\:::\    \         /:::/    /       /:::/\:::\    \          /:::/   /\    \          /:::/\:::\    \          /:::/\:::\    \
//     /:::/__\:::\    \        /:::/|::|   |           /:::/    \:::\    \       /:::/    /       /:::/__\:::\    \        /:::/   /::\____\        /:::/__\:::\    \        /:::/__\:::\    \
//     \:::\   \:::\    \      /:::/ |::|   |          /:::/    / \:::\    \     /:::/    /        \:::\   \:::\    \      /:::/   /:::/    /       /::::\   \:::\    \      /::::\   \:::\    \
//   ___\:::\   \:::\    \    /:::/  |::|___|______   /:::/____/   \:::\____\   /:::/    /       ___\:::\   \:::\    \    /:::/   /:::/   _/___    /::::::\   \:::\    \    /::::::\   \:::\    \
//  /\   \:::\   \:::\    \  /:::/   |::::::::\    \ |:::|    |     |:::|    | /:::/    /       /\   \:::\   \:::\    \  /:::/___/:::/   /\    \  /:::/\:::\   \:::\    \  /:::/\:::\   \:::\____\
// /::\   \:::\   \:::\____\/:::/    |:::::::::\____\|:::|____|     |:::|    |/:::/____/       /::\   \:::\   \:::\____\|:::|   /:::/   /::\____\/:::/  \:::\   \:::\____\/:::/  \:::\   \:::|    |
// \:::\   \:::\   \::/    /\::/    / ~~~~~/:::/    / \:::\    \   /:::/    / \:::\    \       \:::\   \:::\   \::/    /|:::|__/:::/   /:::/    /\::/    \:::\  /:::/    /\::/    \:::\  /:::|____|
//  \:::\   \:::\   \/____/  \/____/      /:::/    /   \:::\    \ /:::/    /   \:::\    \       \:::\   \:::\   \/____/  \:::\/:::/   /:::/    /  \/____/ \:::\/:::/    /  \/_____/\:::\/:::/    /
//   \:::\   \:::\    \                  /:::/    /     \:::\    /:::/    /     \:::\    \       \:::\   \:::\    \       \::::::/   /:::/    /            \::::::/    /            \::::::/    /
//    \:::\   \:::\____\                /:::/    /       \:::\__/:::/    /       \:::\    \       \:::\   \:::\____\       \::::/___/:::/    /              \::::/    /              \::::/    /
//     \:::\  /:::/    /               /:::/    /         \::::::::/    /         \:::\    \       \:::\  /:::/    /        \:::\__/:::/    /               /:::/    /                \::/____/
//      \:::\/:::/    /               /:::/    /           \::::::/    /           \:::\    \       \:::\/:::/    /          \::::::::/    /               /:::/    /                  ~~
//       \::::::/    /               /:::/    /             \::::/    /             \:::\    \       \::::::/    /            \::::::/    /               /:::/    /
//        \::::/    /               /:::/    /               \::/____/               \:::\____\       \::::/    /              \::::/    /               /:::/    /
//         \::/    /                \::/    /                 ~~                      \::/    /        \::/    /                \::/____/                \::/    /
//          \/____/                  \/____/                                           \/____/          \/____/                  ~~                       \/____/

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "../token/ANFTReceiver2.sol";

import "./diamond/Diamond.sol";
import "./diamond/facets/OwnershipFacet.sol";

contract SmolSweeper is Diamond, ANFTReceiver2, OwnershipModifers {
  using SafeERC20 for IERC20;

  constructor(address _contractOwner, address _diamondCutFacet)
    Diamond(_contractOwner, _diamondCutFacet)
  {}
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../token/ERC1155/AERC1155Receiver2.sol";
import "../token/ERC721/AERC721Receiver2.sol";

abstract contract ANFTReceiver2 is AERC721Receiver2, AERC1155Receiver2 {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

// import "@forge-std/src/console.sol";

import {LibDiamond} from "./libraries/LibDiamond.sol";
import {LibOwnership} from "./libraries/LibOwnership.sol";
import {IDiamondCut} from "./interfaces/IDiamondCut.sol";

// import "@forge-std/src/Test.sol";

contract Diamond {
  constructor(address _contractOwner, address _diamondCutFacet) payable {
    LibOwnership.setContractOwner(_contractOwner);

    // Add the diamondCut external function from the diamondCutFacet
    IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
    bytes4[] memory functionSelectors = new bytes4[](1);
    functionSelectors[0] = IDiamondCut.diamondCut.selector;
    cut[0] = IDiamondCut.FacetCut({
      facetAddress: _diamondCutFacet,
      action: IDiamondCut.FacetCutAction.Add,
      functionSelectors: functionSelectors
    });
    LibDiamond.diamondCut(cut, address(0), "");
  }

  // Find facet for function that is called and execute the
  // function if a facet is found and return any value.
  fallback() external payable {
    LibDiamond.DiamondStorage storage ds;
    // get diamond storage
    bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
    // get facet from function selector
    address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
    require(facet != address(0), "Diamond: Function does not exist");
    // Execute external function from facet using delegatecall and return any value.
    assembly {
      // copy function selector and any arguments
      calldatacopy(0, 0, calldatasize())
      // execute function call using the facet
      let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
      // get any return value
      returndatacopy(0, 0, returndatasize())
      // return any return value or error back to the caller
      switch result
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }

  // receive() external payable {
  // }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC173} from "../interfaces/IERC173.sol";
import {LibOwnership} from "../libraries/LibOwnership.sol";
import {IDiamondInit} from "../interfaces/IDiamondInit.sol";

error NotOwner();

abstract contract OwnershipModifers {
  modifier onlyOwner() {
    if (msg.sender != LibOwnership.diamondStorage().contractOwner)
      revert NotOwner();
    _;
  }
}

contract OwnershipFacet is IERC173 {
  function transferOwnership(address _newOwner) external override {
    LibOwnership.enforceIsContractOwner();
    LibOwnership.setContractOwner(_newOwner);
  }

  function owner() external view override returns (address owner_) {
    owner_ = LibOwnership.contractOwner();
  }
}

contract OwnershipDiamondInit is IDiamondInit {
  function init() external {
    LibOwnership.setContractOwner(msg.sender);
  }
}

// SPDX-License-Identifier: MIT
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
pragma solidity ^0.8.11;

abstract contract AERC1155Receiver2 {
    /**
     * Always returns `IERC1155Receiver.onERC1155ReceivedFrom.selector`.
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * Always returns `IERC1155Receiver.onERC1155BatchReceived.selector`.
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract AERC721Receiver2 {
    /**
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

library LibDiamond {
  error InValidFacetCutAction();
  error NotDiamondOwner();
  error NoSelectorsInFacet();
  error NoZeroAddress();
  error SelectorExists(bytes4 selector);
  error SameSelectorReplacement(bytes4 selector);
  error MustBeZeroAddress();
  error NoCode();
  error NonExistentSelector(bytes4 selector);
  error ImmutableFunction(bytes4 selector);
  error NonEmptyCalldata();
  error EmptyCalldata();
  error InitCallFailed();
  
  bytes32 constant DIAMOND_STORAGE_POSITION =
    keccak256("diamond.standard.diamond.storage");

  struct FacetAddressAndPosition {
    address facetAddress;
    uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
  }

  struct FacetFunctionSelectors {
    bytes4[] functionSelectors;
    uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
  }

  struct DiamondStorage {
    // maps function selector to the facet address and
    // the position of the selector in the facetFunctionSelectors.selectors array
    mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
    // maps facet addresses to function selectors
    mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
    // facet addresses
    address[] facetAddresses;
    // Used to query if a contract implements an interface.
    // Used to implement ERC-165.
    mapping(bytes4 => bool) supportedInterfaces;
    // owner of the contract
  }

  function diamondStorage() internal pure returns (DiamondStorage storage ds) {
    bytes32 position = DIAMOND_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  event DiamondCut(
    IDiamondCut.FacetCut[] _diamondCut,
    address _init,
    bytes _calldata
  );

  // Internal function version of diamondCut
  function diamondCut(
    IDiamondCut.FacetCut[] memory _diamondCut,
    address _init,
    bytes memory _calldata
  ) internal {
    for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
      IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
      if (action == IDiamondCut.FacetCutAction.Add) {
        addFunctions(
          _diamondCut[facetIndex].facetAddress,
          _diamondCut[facetIndex].functionSelectors
        );
      } else if (action == IDiamondCut.FacetCutAction.Replace) {
        replaceFunctions(
          _diamondCut[facetIndex].facetAddress,
          _diamondCut[facetIndex].functionSelectors
        );
      } else if (action == IDiamondCut.FacetCutAction.Remove) {
        removeFunctions(
          _diamondCut[facetIndex].facetAddress,
          _diamondCut[facetIndex].functionSelectors
        );
      } else {
        revert InValidFacetCutAction();
      }
    }
    emit DiamondCut(_diamondCut, _init, _calldata);
    initializeDiamondCut(_init, _calldata);
  }

  function addFunctions(
    address _facetAddress,
    bytes4[] memory _functionSelectors
  ) internal {
    if (_functionSelectors.length <= 0) revert NoSelectorsInFacet();
    DiamondStorage storage ds = diamondStorage();
    if (_facetAddress == address(0)) revert NoZeroAddress();
    uint96 selectorPosition = uint96(
      ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
    );
    // add new facet address if it does not exist
    if (selectorPosition == 0) {
      addFacet(ds, _facetAddress);
    }
    for (
      uint256 selectorIndex;
      selectorIndex < _functionSelectors.length;
      selectorIndex++
    ) {
      bytes4 selector = _functionSelectors[selectorIndex];
      address oldFacetAddress = ds
        .selectorToFacetAndPosition[selector]
        .facetAddress;
      if (oldFacetAddress != address(0)) revert SelectorExists(selector);
      addFunction(ds, selector, selectorPosition, _facetAddress);
      selectorPosition++;
    }
  }

  function replaceFunctions(
    address _facetAddress,
    bytes4[] memory _functionSelectors
  ) internal {
    if (_functionSelectors.length <= 0) revert NoSelectorsInFacet();
    DiamondStorage storage ds = diamondStorage();
    if (_facetAddress == address(0)) revert NoZeroAddress();
    uint96 selectorPosition = uint96(
      ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
    );
    // add new facet address if it does not exist
    if (selectorPosition == 0) {
      addFacet(ds, _facetAddress);
    }
    for (
      uint256 selectorIndex;
      selectorIndex < _functionSelectors.length;
      selectorIndex++
    ) {
      bytes4 selector = _functionSelectors[selectorIndex];
      address oldFacetAddress = ds
        .selectorToFacetAndPosition[selector]
        .facetAddress;
      if (oldFacetAddress == _facetAddress)
        revert SameSelectorReplacement(selector);
      removeFunction(ds, oldFacetAddress, selector);
      addFunction(ds, selector, selectorPosition, _facetAddress);
      selectorPosition++;
    }
  }

  function removeFunctions(
    address _facetAddress,
    bytes4[] memory _functionSelectors
  ) internal {
    if (_functionSelectors.length <= 0) revert NoSelectorsInFacet();
    DiamondStorage storage ds = diamondStorage();
    // if function does not exist then do nothing and return
    if (_facetAddress != address(0)) revert MustBeZeroAddress();
    for (
      uint256 selectorIndex;
      selectorIndex < _functionSelectors.length;
      selectorIndex++
    ) {
      bytes4 selector = _functionSelectors[selectorIndex];
      address oldFacetAddress = ds
        .selectorToFacetAndPosition[selector]
        .facetAddress;
      removeFunction(ds, oldFacetAddress, selector);
    }
  }

  function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
    enforceHasContractCode(_facetAddress);
    ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds
      .facetAddresses
      .length;
    ds.facetAddresses.push(_facetAddress);
  }

  function addFunction(
    DiamondStorage storage ds,
    bytes4 _selector,
    uint96 _selectorPosition,
    address _facetAddress
  ) internal {
    ds
      .selectorToFacetAndPosition[_selector]
      .functionSelectorPosition = _selectorPosition;
    ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
    ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
  }

  function removeFunction(
    DiamondStorage storage ds,
    address _facetAddress,
    bytes4 _selector
  ) internal {
    if (_facetAddress == address(0)) revert NonExistentSelector(_selector);
    // an immutable function is a function defined directly in a diamond
    if (_facetAddress == address(this)) revert ImmutableFunction(_selector);
    // replace selector with last selector, then delete last selector
    uint256 selectorPosition = ds
      .selectorToFacetAndPosition[_selector]
      .functionSelectorPosition;
    uint256 lastSelectorPosition = ds
      .facetFunctionSelectors[_facetAddress]
      .functionSelectors
      .length - 1;
    // if not the same then replace _selector with lastSelector
    if (selectorPosition != lastSelectorPosition) {
      bytes4 lastSelector = ds
        .facetFunctionSelectors[_facetAddress]
        .functionSelectors[lastSelectorPosition];
      ds.facetFunctionSelectors[_facetAddress].functionSelectors[
          selectorPosition
        ] = lastSelector;
      ds
        .selectorToFacetAndPosition[lastSelector]
        .functionSelectorPosition = uint96(selectorPosition);
    }
    // delete the last selector
    ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
    delete ds.selectorToFacetAndPosition[_selector];

    // if no more selectors for facet address then delete the facet address
    if (lastSelectorPosition == 0) {
      // replace facet address with last facet address and delete last facet address
      uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
      uint256 facetAddressPosition = ds
        .facetFunctionSelectors[_facetAddress]
        .facetAddressPosition;
      if (facetAddressPosition != lastFacetAddressPosition) {
        address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
        ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
        ds
          .facetFunctionSelectors[lastFacetAddress]
          .facetAddressPosition = facetAddressPosition;
      }
      ds.facetAddresses.pop();
      delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
    }
  }

  function initializeDiamondCut(address _init, bytes memory _calldata)
    internal
  {
    if (_init == address(0)) {
      if (_calldata.length > 0) revert NonEmptyCalldata();
    } else {
      if (_calldata.length == 0) revert EmptyCalldata();
      if (_init != address(this)) {
        enforceHasContractCode(_init);
      }
      (bool success, bytes memory error) = _init.delegatecall(_calldata);
      if (!success) {
        if (error.length > 0) {
          // bubble up the error
          revert(string(error));
        } else {
          revert InitCallFailed();
        }
      }
    }
  }

  function enforceHasContractCode(address _contract) internal view {
    uint256 contractSize;
    assembly {
      contractSize := extcodesize(_contract)
    }
    if (contractSize <= 0) revert NoCode();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "./LibDiamond.sol";

error NotDiamondOwner();

library LibOwnership {
  bytes32 constant DIAMOND_STORAGE_POSITION =
    keccak256("diamond.standard.ownership.storage");

  struct DiamondStorage {
    // owner of the contract
    address contractOwner;
  }

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  function diamondStorage() internal pure returns (DiamondStorage storage ds) {
    bytes32 position = DIAMOND_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  function setContractOwner(address _newOwner) internal {
    DiamondStorage storage ds = diamondStorage();
    address previousOwner = ds.contractOwner;
    ds.contractOwner = _newOwner;
    emit OwnershipTransferred(previousOwner, _newOwner);
  }

  function contractOwner() internal view returns (address contractOwner_) {
    contractOwner_ = diamondStorage().contractOwner;
  }

  function enforceIsContractOwner() internal view {
    if (msg.sender != diamondStorage().contractOwner) revert NotDiamondOwner();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
  enum FacetCutAction {
    Add,
    Replace,
    Remove
  }
  // Add=0, Replace=1, Remove=2

  struct FacetCut {
    address facetAddress;
    FacetCutAction action;
    bytes4[] functionSelectors;
  }

  /// @notice Add/replace/remove any number of functions and optionally execute
  ///         a function with delegatecall
  /// @param _diamondCut Contains the facet addresses and function selectors
  /// @param _init The address of the contract or facet to execute _calldata
  /// @param _calldata A function call, including function selector and arguments
  ///                  _calldata is executed with delegatecall on _init
  function diamondCut(
    FacetCut[] calldata _diamondCut,
    address _init,
    bytes calldata _calldata
  ) external;

  event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
  /// @dev This emits when ownership of a contract changes.
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /// @notice Get the address of the owner
  /// @return owner_ The address of the owner.
  function owner() external view returns (address owner_);

  /// @notice Set the address of the new owner of the contract
  /// @dev Set _newOwner to address(0) to renounce any ownership.
  /// @param _newOwner The address of the new owner of the contract
  function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDiamondInit {
  function init() external;
}