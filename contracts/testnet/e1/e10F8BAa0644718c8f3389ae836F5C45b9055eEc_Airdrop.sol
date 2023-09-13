// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/IERC1155.sol)

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
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface InterfaceAvatar {
    struct NftAvatarSpec {
        bool isOpen;
        bytes32 merkleRoot;
        uint256 supply;
        uint256 maxTokenId;
        uint256 startTokenId;
        uint256 maxAmountPerAddress;
        uint256 cost;
        uint256 tokenIdCounter;
    }

    enum TierAvatar {
        legendary,
        epic,
        rare
    }

    error ExceedeedTokenClaiming();
    error SupplyExceedeed();
    error InsufficientFunds();
    error InvalidProof();
    error CannotZeroAmount();
    error InvalidTierInput();
    error MintingClose();
    error TokenNotExist();

    function exist(uint256 tokenId) external view returns (bool);

    function ownerOf(uint256 tokenId) external view returns (address);

    function getAddressAlreadyClaimed(
        TierAvatar tier,
        address holder
    ) external view returns (uint256);

}

error InvalidInputParam();
error NeedApproveFromOwner();
error BalanceExceeded();
error ErrorApprove(uint256 amount);
error TokenIsNotTheOwner(address to, uint256 tokenId);
error ErrorTransferFrom(address spender, address to, uint256 amount);

contract Airdrop {
    // address owner, cannot be change
    // this address mush have balance from ERC20, ERC721, and ERC1155
    address private _owner;

    // ERC721 avatar contract
    InterfaceAvatar private immutable _nftAvatar;

    mapping(InterfaceAvatar.TierAvatar => uint256) private _amountAirdropERC20;
    mapping(InterfaceAvatar.TierAvatar => mapping(uint256 => uint256)) private _nftAirdrop1155;

    constructor(address nft721_) {
        // smart contract address is immutable that can be initiate when deploy but cannot be change.
        _nftAvatar = InterfaceAvatar(nft721_);
        _owner = msg.sender;

        // set up the reward in amount of token ERC20 Legendary
        _amountAirdropERC20[InterfaceAvatar.TierAvatar.legendary] = 100;
        _amountAirdropERC20[InterfaceAvatar.TierAvatar.epic] = 50;
        _amountAirdropERC20[InterfaceAvatar.TierAvatar.rare] = 20;
    }

    /**
     * @dev a modifier to check the wallet address id an owner
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "Not Owner");
        _;
    }

    // ===================================================================
    //                           SETUP REWARD VALUE
    // ===================================================================
    /**
     * @dev function to setup amount of reward for ERC20 token airdrop
     * @param tier is state of tier nft avatar
     * @param amount is how many tokens will send to this address
     */
    function setAmountErc20ByTier(
        InterfaceAvatar.TierAvatar tier,
        uint256 amount
    ) external onlyOwner() {
        _amountAirdropERC20[tier] = amount;
    }

    /**
     * @dev function to setup amount of reward for ERC1155 token airdrop
     * @param tier is state of tier nft avatar
     * @param tokenIdNft is unique identifier of NFT (NFT-ID) ERC1155
     * @param amount is how many tokens will send to this address
     */
    function setAmountErc1155ByTier(
        InterfaceAvatar.TierAvatar tier,
        uint256 tokenIdNft,
        uint256 amount
    ) external onlyOwner() {
        _nftAirdrop1155[tier][tokenIdNft] = amount;
    }

    // ===================================================================
    //                          PRIVATE FUNCTION
    // ===================================================================
    /**
     * @dev a private function to get what tier the token is from the token ID number
     * @param tokenId is token id from the nft avatar
     */
    function _getTokenTier(
        uint256 tokenId
    ) private pure returns (InterfaceAvatar.TierAvatar) {
        if (tokenId < 56) {
            return InterfaceAvatar.TierAvatar.legendary;
        }

        if (tokenId > 55 && tokenId < 1001) {
            return InterfaceAvatar.TierAvatar.epic;
        }

        if (tokenId > 1000 && tokenId < 3001) {
            return InterfaceAvatar.TierAvatar.rare;
        }
        revert InvalidInputParam();
    }

    /**
     * @dev a private function for check that wallet address contain token id that eligibely amount token/nft by tier to get airdrop
     * @param tokenId is token id from the nft avatar
     */
    function _getAmountRewardERC20ByTier(
        uint256 tokenId
    ) private view returns (uint256) {
        InterfaceAvatar.TierAvatar onTier = _getTokenTier(tokenId);
        return _amountAirdropERC20[onTier];
    }

    /**
     * @dev a private function for check that wallet address contain token id that eligibely amount token/nft by tier to get airdrop
     * @param tokenIdAvatar is token id from the nft avatar
     * @param tokenIdNft1155 is token id from the nft 1155 that want to airdrop
     */
    function _getAmountRewardERC1155ByTier(
        uint256 tokenIdAvatar,
        uint256 tokenIdNft1155
    ) private view returns (uint256) {
        InterfaceAvatar.TierAvatar onTier = _getTokenTier(tokenIdAvatar);
        return _nftAirdrop1155[onTier][tokenIdNft1155];
    }

    /**
     * @dev a private function for check that wallet address have NFT Avatar
     * @param tokenIdAvatar is token id from the nft avatar
     * @param holder is token id from the nft 1155 that want to airdrop
     */
    function _checkOwnerOfNftAvatar(
        uint256 tokenIdAvatar,
        address holder
    ) private view {
        // check the token Id is same as `to` address
        if (_nftAvatar.ownerOf(tokenIdAvatar) != holder) {
            revert TokenIsNotTheOwner(holder, tokenIdAvatar);
        }
    }

    /**
     * @dev private airdrop function for token ERC20 to wherever wallet address and without verification that address has nft avatar
     * @dev function will set owner to `approve` this smart contract to send the `amount` of token
     * @param to is an destination address
     * @param tokenIdAvatar is token id from wallet address nft avatar
     * @param amount is how many tokens will send to this address
     */
    function _wrapAirdropERC20(
        IERC20 tokenAddress,
        address to,
        uint256 tokenIdAvatar,
        uint256 amount
    ) private {
        if (amount == 0) {
            revert InterfaceAvatar.CannotZeroAmount();
        }
        _checkOwnerOfNftAvatar(tokenIdAvatar, to);
        if (!tokenAddress.approve(address(this), amount)) {
            revert ErrorApprove(amount);
        }
        if (!tokenAddress.transferFrom(_owner, to, amount)) {
            revert ErrorTransferFrom(_owner, to, amount);
        }
    }

    /**
     * @dev private airdrop function for nft ERC20 that the amount is already set by the owner
     * @dev function will set owner to `approve` this smart contract to send the `amount` of token supply
     * @param to is an destination address
     * @param tokenIdAvatar is token id from wallet address nft avatar
     */
    function _wrapAirdropERC20(
        IERC20 tokenAddress,
        address to,
        uint256 tokenIdAvatar
    ) private {
        uint256 _amount = _getAmountRewardERC20ByTier(tokenIdAvatar);
        _wrapAirdropERC20(tokenAddress, to, tokenIdAvatar, _amount);
    }

    /**
     * @dev private airdrop function for nft ERC721
     * @dev function will set owner to `approve` this smart contract to send the `token id` of nft
     * @param to is an destination address
     * @param tokenIdAvatar is token id from wallet address nft avatar
     * @param tokenIdErc721 is an token ID nft erc721 that owner have and want to transfer
     */
    function _wrapAirdropNFT721(
        IERC721 nftAddress721,
        address to,
        uint256 tokenIdAvatar,
        uint256 tokenIdErc721
    ) private {
        if (!nftAddress721.isApprovedForAll(_owner, address(this))) {
            revert NeedApproveFromOwner();
        }
        // check nft to airdrop is exist
        if (nftAddress721.ownerOf(tokenIdErc721) == address(0)) {
            revert InterfaceAvatar.TokenNotExist();
        }
        if (nftAddress721.ownerOf(tokenIdErc721) != _owner) {
            revert TokenIsNotTheOwner(_owner, tokenIdErc721);
        }
        _checkOwnerOfNftAvatar(tokenIdAvatar, to);

        // nftAddress721.approve(address(this), tokenIdErc721);
        nftAddress721.safeTransferFrom(_owner, to, tokenIdErc721);
    }

    /**
     * @dev private airdrop function for nft ERC1155
     * @dev function will set owner to `approve` this smart contract to send the `token id` of nft
     * @param to is an destination address
     * @param tokenIdAvatar is token id from wallet address nft avatar
     * @param tokenIdERC1155 is an token ID nft erc1155 that owner have and want to transfer
     * @param amount is amount of nft want to sent
     */
    function _wrapAirdropNFT1155(
        IERC1155 nftAddress1155,
        address to,
        uint256 tokenIdAvatar,
        uint256 tokenIdERC1155,
        uint256 amount
    ) private {
        if (!nftAddress1155.isApprovedForAll(_owner, address(this))) {
            revert NeedApproveFromOwner();
        }
        if (amount == 0) {
            revert InterfaceAvatar.CannotZeroAmount();
        }
        if (nftAddress1155.balanceOf(_owner, tokenIdERC1155) == 0) {
            revert BalanceExceeded();
        }
        _checkOwnerOfNftAvatar(tokenIdAvatar, to);

        nftAddress1155.safeTransferFrom(_owner, to, tokenIdERC1155, amount, "");
    }

    /**
     * @dev private airdrop function for nft ERC1155 that the amount is already set by the owner
     * @dev function will set owner to `approve` this smart contract to send the `token id` of nft
     * @param to is an destination address
     * @param tokenIdAvatar is token id from wallet address nft avatar
     * @param tokenIdERC1155 is an token ID nft erc1155 that owner have and want to transfer
     */
    function _wrapAirdropNFT1155(
        IERC1155 nftAddress1155,
        address to,
        uint256 tokenIdAvatar,
        uint256 tokenIdERC1155
    ) private {
        uint256 _amount = _getAmountRewardERC1155ByTier(
            tokenIdAvatar,
            tokenIdERC1155
        );
        _wrapAirdropNFT1155(
            nftAddress1155,
            to,
            tokenIdAvatar,
            tokenIdERC1155,
            _amount
        );
    }

    // ===================================================================
    //                           AIRDROP ERC20
    // ===================================================================

    /**
     * @dev airdrop function for token ERC20 with verification that address has nft avatar
     * @param to is an destination address that have nft avatar
     * @param tokenIdAvatar is the token of nft avatar from address `to`
     * @param amount is how many tokens will send to this address
     */
    function airdropToken(
        IERC20 tokenAddress,
        address to,
        uint256 tokenIdAvatar,
        uint256 amount
    ) external onlyOwner(){
        _wrapAirdropERC20(tokenAddress, to, tokenIdAvatar, amount);
    }

    /**
     * @dev bulk airdrop function for token ERC20 with verification that address has nft avatar
     * @dev `to`, `tokenIdAvatar`, and `amount` must have same length value
     */
    function batchAirdropToken(
        IERC20 tokenAddress,
        address[] calldata to,
        uint256[] calldata tokenIdAvatar,
        uint256[] calldata amount
    ) external onlyOwner() {
        uint256 totalAddress = to.length;
        if (
            totalAddress != tokenIdAvatar.length &&
            totalAddress != amount.length
        ) {
            revert InvalidInputParam();
        }

        for (uint256 i = 0; i < totalAddress; ) {
            _wrapAirdropERC20(tokenAddress, to[i], tokenIdAvatar[i], amount[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev airdrop function for token ERC20 with verification that address has nft avatar
     * @dev amount token is automatically set by the tier. Legenday, epic, and rare.
     * @param holder is an destination address that have nft avatar
     * @param tokenIdAvatar is the token of nft avatar from address `holder`
     */
    function airdropTokenToByTier(
        IERC20 tokenAddress,
        address holder,
        uint256 tokenIdAvatar
    ) external onlyOwner() {
        _wrapAirdropERC20(tokenAddress, holder, tokenIdAvatar);
    }

    /**
     * @dev bulk airdrop function for token ERC20 with verification that address has nft avatar
     * @dev amount token is automatically set by the tier. Legenday, epic, and rare.
     */
    function batchAirdropTokenByTier(
        IERC20 tokenAddress,
        address[] calldata holder,
        uint256[] calldata tokenIdAvatar
    ) external onlyOwner() {
        uint256 totalAddress = holder.length;
        if (totalAddress != tokenIdAvatar.length) {
            revert InvalidInputParam();
        }

        for (uint256 i = 0; i < totalAddress; ) {
            _wrapAirdropERC20(tokenAddress, holder[i], tokenIdAvatar[i]);
            unchecked {
                ++i;
            }
        }
    }

    // ===================================================================
    //                           AIRDROP ERC721
    // ===================================================================
    /**
     * @dev airdrop function for token ERC721 with verification that address has nft avatar
     * @param to is an destination address that have nft avatar
     * @param tokenIdAvatar is the token of nft avatar from address `to`
     * @param tokenIdNFT721 is token id from ERC1155 want to transfer
     */
    function airdropNFT721(
        IERC721 nftAddress721,
        address to,
        uint256 tokenIdAvatar,
        uint256 tokenIdNFT721
    ) external onlyOwner() {
        _wrapAirdropNFT721(nftAddress721, to, tokenIdAvatar, tokenIdNFT721);
    }

    /**
     * @dev bulk airdrop function for token ERC721 with verification that address has nft avatar
     * @dev `to`, `tokenIdAvatar`, and `tokenIdNFT721` must have same length value
     */
    function batchAirdropNFT721(
        IERC721 nftAddress721,
        address[] calldata to,
        uint256[] calldata tokenIdAvatar,
        uint256[] calldata tokenIdNFT721
    ) external onlyOwner() {
        uint256 _totalAddress = to.length;
        if (
            _totalAddress != tokenIdAvatar.length &&
            _totalAddress != tokenIdNFT721.length
        ) {
            revert InvalidInputParam();
        }
        for (uint256 i = 0; i < _totalAddress;) {
            _wrapAirdropNFT721(
                nftAddress721,
                to[i],
                tokenIdAvatar[i],
                tokenIdNFT721[i]
            );
            unchecked {
                ++i;
            }
        }
    }

    // ===================================================================
    //                           AIRDROP ERC1155
    // ===================================================================
    /**
     * @dev airdrop function for token ERC20 with verification that address has nft avatar
     * @param to is an destination address that have nft avatar
     * @param tokenIdAvatar is the token of nft avatar from address `to`
     * @param tokenIdNFT1155 is token id from ERC1155 want to transfer
     * @param amount is amount of NFT from `tokenIdNFT1155` want to sent
     */
    function airdropNFT1155(
        IERC1155 nftAddress1155,
        address to,
        uint256 tokenIdAvatar,
        uint256 tokenIdNFT1155,
        uint256 amount
    ) external onlyOwner() {
        _wrapAirdropNFT1155(
            nftAddress1155,
            to,
            tokenIdAvatar,
            tokenIdNFT1155,
            amount
        );
    }

    /**
     * @dev bulk airdrop function for token ERC1155 with verification that address has nft avatar
     * @dev `to`, `tokenIdAvatar`, `tokenIdNFT1155`, and `amount` must have same length value
     */
    function batchAirdropNFT1155(
        IERC1155 nftAddress1155,
        address[] calldata to,
        uint256[] calldata tokenIdAvatar,
        uint256 tokenIdNFT1155,
        uint256[] calldata amount
    ) external onlyOwner() {
        uint256 _totalAddress = to.length;
        if (
            _totalAddress != tokenIdAvatar.length &&
            _totalAddress != amount.length
        ) {
            revert InvalidInputParam();
        }
        for (uint256 i = 0; i < _totalAddress; ) {
            _wrapAirdropNFT1155(
                nftAddress1155,
                to[i],
                tokenIdAvatar[i],
                tokenIdNFT1155,
                amount[i]
            );
            unchecked {
                ++i;
            }
        }
    }

    function airdropNFT1155ByTier(
        IERC1155 nftAddress1155,
        address to,
        uint256 tokenIdAvatar,
        uint256 tokenIdNFT1155
    ) external onlyOwner() {
        _wrapAirdropNFT1155(nftAddress1155, to, tokenIdAvatar, tokenIdNFT1155);
    }

    function batchAirdropNFT1155ByTier(
        IERC1155 nftAddress1155,
        address[] calldata to,
        uint256[] calldata tokenIdAvatar,
        uint256 tokenIdNFT1155
    ) external onlyOwner() {
        uint256 _totalAddress = to.length;
        if (
            _totalAddress != tokenIdAvatar.length
        ) {
            revert InvalidInputParam();
        }
        for (uint256 i = 0; i < _totalAddress; ) {
            _wrapAirdropNFT1155(
                nftAddress1155,
                to[i],
                tokenIdAvatar[i],
                tokenIdNFT1155
            );
            unchecked {
                ++i;
            }
        }
    }
}