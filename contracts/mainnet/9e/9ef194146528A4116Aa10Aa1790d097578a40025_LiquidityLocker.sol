/**
 *Submitted for verification at Arbiscan on 2023-05-04
*/

// SPDX-License-Identifier: MIT LICENSE

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

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

interface INonfungiblePosition is IERC721Enumerable {
    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(
        uint256 tokenId
    )
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract LiquidityLocker is IERC721Receiver {
    event TokenLocked(address indexed sender, uint256 indexed tokenId, uint256 unlockBlock);
    event Withdraw(address indexed reciver, uint256 indexed tokenId);

    address public immutable uniswapV3PositionsNFT;
    address public immutable targetToken;

    // releaseBlock<<160 | owner
    mapping(uint256 => uint256) private _tokenData;

    constructor(address uniswapV3PositionsNFT_, address targetToken_) {
        uniswapV3PositionsNFT = uniswapV3PositionsNFT_;
        targetToken = targetToken_;
    }

    function infoOf(uint256 tokenId) public view returns (address owner, uint256 restBlock, uint256 liquidity, string memory metadata) {
        INonfungiblePosition nft = INonfungiblePosition(uniswapV3PositionsNFT);
        (, , , , , , , liquidity, , , , ) = nft.positions(tokenId);
        (owner, restBlock) = lockInfoOf(tokenId);
        if (restBlock > block.number) restBlock -= block.number;
        else restBlock = 0;
        metadata = nft.tokenURI(tokenId);
    }

    function lockInfoOf(uint256 tokenId) public view returns (address owner, uint256 releaseBlock) {
        uint256 data = _tokenData[tokenId];
        owner = address(uint160(data & (type(uint160).max)));
        releaseBlock = data >> 160;
    }

    function totalLiquidity() external view returns (uint256 liquidity) {
        INonfungiblePosition nft = INonfungiblePosition(uniswapV3PositionsNFT);
        uint256 count = nft.balanceOf(address(this));
        for (uint256 index = 0; index < count; ++index) {
            uint256 tokenId = nft.tokenOfOwnerByIndex(address(this), index);
            (, , , , , , , uint128 _liquidity, , , , ) = nft.positions(tokenId);
            liquidity += _liquidity;
        }
    }

    function withdraw(uint256[] calldata tokenIds) external {
        for (uint256 index = 0; index < tokenIds.length; ++index) {
            uint256 tokenId = tokenIds[index];
            (address owner, uint256 releaseBlock) = lockInfoOf(tokenId);
            delete _tokenData[tokenId];
            require(owner == msg.sender, "require token owner");
            require(block.number >= releaseBlock, "still in lock");
            IERC721(uniswapV3PositionsNFT).safeTransferFrom(address(this), msg.sender, tokenId);
            emit Withdraw(msg.sender, tokenId);
        }
    }

    function postpone(uint256 tokenId, uint256 lockBlocks) external {
        (address owner, uint256 releaseBlock) = lockInfoOf(tokenId);
        require(msg.sender == owner, "require token owner");
        if (releaseBlock < block.number) {
            releaseBlock = block.number;
        }
        releaseBlock += lockBlocks;
        _tokenData[tokenId] = (releaseBlock << 160) | uint256(uint160(owner));
        emit TokenLocked(owner, tokenId, releaseBlock);
    }

    function _deposit(address owner, uint256 tokenId, uint256 lockBlocks) private {
        uint256 releaseBlock = block.number + lockBlocks;
        _tokenData[tokenId] = (releaseBlock << 160) | uint256(uint160(owner));
        emit TokenLocked(owner, tokenId, releaseBlock);
    }

    function onERC721Received(address, address from, uint256 tokenId, bytes calldata data) public virtual override returns (bytes4) {
        require(msg.sender == address(uniswapV3PositionsNFT), "only accept UniswapV3PositionsNFT");
        (, , address token0, address token1, , , , , , , , ) = INonfungiblePosition(msg.sender).positions(tokenId);
        require(token0 == targetToken || token1 == targetToken, "only accept target token");
        uint256 lockBlocks = abi.decode(data, (uint256));
        _deposit(from, tokenId, lockBlocks);
        return this.onERC721Received.selector;
    }
}