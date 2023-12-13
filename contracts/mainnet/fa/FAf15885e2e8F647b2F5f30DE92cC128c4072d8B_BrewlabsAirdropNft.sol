// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
pragma solidity ^0.8.4;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IBrewlabsDiscountManager} from "./libs/IBrewlabsDiscountManager.sol";

contract BrewlabsAirdropNft is Ownable {
    uint256 public constant DISCOUNT_MAX = 10_000;

    uint256 public commission = 0.00066 ether;
    uint256 public commissionLimit = 3 ether;
    uint256 public maxTxLimit = 200;

    /* options for 50% discount */
    address[] private tokensForDiscount;

    /* list of addresses for no fee */
    address[] private whitelist;

    address discountMgr;
    address public feeAddress = 0xE1f1dd010BBC2860F81c8F90Ea4E38dB949BB16F;

    /* events */
    event AddedToWhitelist(address addr);
    event RemovedFromWhitelist(address addr);

    event AddedToDicountList(address token);
    event RemovedFromDicountList(address token);

    event DiscountMgrUpdated(address addr);
    event FeeAddressUpdated(address addr);

    event CommissionUpdated(uint256 amount);
    event CommissionLimitUpdated(uint256 amount);
    event CommissionTxLimitUpdated(uint256 amount);

    constructor() {}

    /* Airdrop Begins */
    function multiTransfer(
        address token,
        address[] calldata addresses,
        uint256[] calldata tokenIds
    ) external payable {
        require(token != address(0x0), "Invalid token");
        require(
            addresses.length <= maxTxLimit,
            "GAS Error: max airdrop limit is 200 addresses"
        );
        require(
            addresses.length == tokenIds.length,
            "Mismatch between address and tokenId"
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            IERC721(token).safeTransferFrom(
                msg.sender,
                addresses[i],
                tokenIds[i]
            );
        }

        uint256 fee = estimateServiceFee(token, addresses.length);
        if (fee > 0) {
            require(msg.value == fee, "must send correct fee");

            payable(feeAddress).transfer(fee);
        }
    }

    function estimateServiceFee(
        address token,
        uint256 count
    ) public view returns (uint256) {
        if (isInWhitelist(msg.sender)) return 0;

        uint256 fee = commission * count;
        if (fee > commissionLimit) fee = commissionLimit;

        if (isInDiscountList(token)) return fee / 2;

        if (discountMgr != address(0)) {
            uint256 discount = IBrewlabsDiscountManager(discountMgr).discountOf(
                msg.sender
            );
            fee = (fee * (DISCOUNT_MAX - discount)) / DISCOUNT_MAX;
        }
        return fee;
    }

    function addToDiscount(address token) external onlyOwner {
        require(token != address(0x0), "Invalid address");
        require(
            isInDiscountList(token) == false,
            "Already added to token list for discount"
        );

        tokensForDiscount.push(token);

        emit AddedToDicountList(token);
    }

    function removeFromDiscount(address token) external onlyOwner {
        require(token != address(0x0), "Invalid address");
        require(
            isInDiscountList(token) == true,
            "Not exist in token list for discount"
        );

        for (uint256 i = 0; i < tokensForDiscount.length; i++) {
            if (tokensForDiscount[i] == token) {
                tokensForDiscount[i] = tokensForDiscount[
                    tokensForDiscount.length - 1
                ];
                tokensForDiscount[tokensForDiscount.length - 1] = address(0x0);
                tokensForDiscount.pop();
                break;
            }
        }

        emit RemovedFromDicountList(token);
    }

    function isInDiscountList(address token) public view returns (bool) {
        for (uint256 i = 0; i < tokensForDiscount.length; i++) {
            if (tokensForDiscount[i] == token) {
                return true;
            }
        }

        return false;
    }

    function addToWhitelist(address addr) external onlyOwner {
        require(addr != address(0x0), "Invalid address");
        require(isInWhitelist(addr) == false, "Already added to whitelsit");

        whitelist.push(addr);

        emit AddedToWhitelist(addr);
    }

    function removeFromWhitelist(address addr) external onlyOwner {
        require(addr != address(0x0), "Invalid address");
        require(isInWhitelist(addr) == true, "Not exist in whitelist");

        for (uint256 i = 0; i < whitelist.length; i++) {
            if (whitelist[i] == addr) {
                whitelist[i] = whitelist[whitelist.length - 1];
                whitelist[whitelist.length - 1] = address(0x0);
                whitelist.pop();
                break;
            }
        }

        emit RemovedFromWhitelist(addr);
    }

    function isInWhitelist(address addr) public view returns (bool) {
        for (uint256 i = 0; i < whitelist.length; i++) {
            if (whitelist[i] == addr) {
                return true;
            }
        }

        return false;
    }

    function setFeeAddress(address addr) external onlyOwner {
        require(addr != address(0x0), "Invalid address");

        feeAddress = addr;

        emit FeeAddressUpdated(addr);
    }

    function setDiscountMgrAddress(address addr) external onlyOwner {
        require(
            addr == address(0) || isContract(addr),
            "Invalid discount manager"
        );
        discountMgr = addr;

        emit DiscountMgrUpdated(addr);
    }

    function setCommission(uint256 _commission) external onlyOwner {
        require(_commission > 0, "Invalid amount");
        commission = _commission;

        emit CommissionUpdated(_commission);
    }

    function setCommissionLimit(uint256 _limit) external onlyOwner {
        require(_limit > 0, "Invalid amount");
        commissionLimit = _limit;

        emit CommissionLimitUpdated(_limit);
    }

    function setMaxTxLimit(uint256 _txLimit) external onlyOwner {
        require(_txLimit > 0, "Invalid amount");
        maxTxLimit = _txLimit;

        emit CommissionTxLimitUpdated(_txLimit);
    }

    function isContract(address _addr) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBrewlabsDiscountManager {
    function discountOf(address _to) external view returns (uint256);
}