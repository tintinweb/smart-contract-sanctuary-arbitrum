//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./TestOnChainLegionMetadata.sol";

contract TestOnChainLegion is ERC721, Ownable, ReentrancyGuard {

   //Interfaces
   TestOnChainLegionMetadata metadata;

   constructor() ERC721("TEST", "TEST") { }

   function mint(address to, uint256 tokenId) external nonReentrant {
      mintInternal(to, tokenId);
   }

   function mintInternal(address to, uint256 tokenId) private {
      _safeMint(to, tokenId);
   }

   /// @notice View a token's tokenURI
   /// @param tokenId, the desired tokenId.
   /// @return a JSON string tokenURI
   function tokenURI(uint256 tokenId) public view override returns (string memory) {
      require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

      return metadata.generateTokenURI(tokenId);
   }

   /// @notice Set address for external contracts
   function setContracts(
      address _metadata
   ) external {
      metadata = TestOnChainLegionMetadata(_metadata);
   }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

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
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
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
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
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

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
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

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
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
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
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
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
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

//	SPDX-License-Identifier: MIT

/// @title  ETHTerrestrials by Kye descriptor (v1). An on-chain migration of assets from the OpenSea shared storefront token.
/// @notice Image and traits stored on-chain (non-generative)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./InflateLib.sol";
import "./Base64.sol";
import "./SSTORE2.sol";

contract TestOnChainLegionMetadata {
   using Strings for uint8;
   using Strings for uint256;
   using InflateLib for bytes;

   /// @notice Storage entry for a token
   struct Token {
      address imageStore; //SSTORE2 storage location for a base64 encoded PNG, compressed using DEFLATE (python zlib). Header (first 2 bytes) and checksum (last 4 bytes) truncated.
      uint96 imagelen; //The length of the uncomressed image data (required for decompression).
   }
   mapping(uint256 => Token[]) public tokenData;

   address private deployer;

   constructor() {
      deployer = msg.sender;
   }

   string imageTagOpen =
      '<image x="0" y="0" width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,';

   /// @notice Returns an ERC721 standard tokenURI
   /// @param tokenId, the desired tokenId to display
   /// @return output, a base64 encoded JSON string containing the tokenURI (metadata and image)
   function generateTokenURI(uint256 tokenId) external view returns (string memory) {
      string memory name = string(abi.encodePacked("Test #", tokenId.toString()));
      string memory description = "testtttttt";
      string memory svg = getSvg(tokenId);

      string memory json = 
         string(
            abi.encodePacked(
               '{"name": "',
               name,
               '", "description": "',
               description,
               '", "attributes": []',
               ',"image": "data:image/svg+xml;base64,',
               Base64.encode(bytes(svg)),
               '"}'
            )
         );

      string memory output = json;
      return output;
   }

   /// @notice Generates an unencoded SVG image for a given token
   /// @param tokenId, the desired tokenId to display
   /// @dev PNG images are added into an SVG for easy scaling
   /// @return an SVG string
   function getSvg(uint256 tokenId) public view returns (string memory) {
      string memory SVG = '<svg id="testt" width="100%" height="100%" version="1.1" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">';
      uint256 len = tokenData[tokenId].length;
      string memory png;
      for (uint256 i = 0; i < len; i++) {
         png = string(abi.encodePacked(png,getSvgPart(tokenId,i)));
      }
      SVG = string(
         abi.encodePacked(
            SVG,
            png,
            "</svg>"
         )
      );
      return SVG;
   }

   function getSvgPart(uint256 tokenId, uint256 index) internal view returns (string memory) {
      string memory base64encodedPNG = decompress(SSTORE2.read(tokenData[tokenId][index].imageStore), tokenData[tokenId][index].imagelen);
      return string(
         abi.encodePacked(
            imageTagOpen,
            base64encodedPNG,
            '"/>'
         )
      );
   }

   function decompress(bytes memory input, uint256 len) public pure returns (string memory) {
      (, bytes memory decompressed) = InflateLib.puff(input, len);
      return string(decompressed);
   }

   /// @notice Establishes the tokenData for a list of tokens (image and trait build code)
   function setTokenData(
      uint8 _newTokenId,
      Token[] memory _tokenData,
      bytes[] memory _imageData
   ) external {
      require(_imageData.length == _tokenData.length);
      for (uint8 i; i < _tokenData.length; i++) {
         _tokenData[i].imageStore = SSTORE2.write(_imageData[i]);
         tokenData[_newTokenId].push(_tokenData[i]);
      }
   }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

/// https://github.com/adlerjohn/inflate-sol
/// @notice Based on https://github.com/madler/zlib/blob/master/contrib/puff
library InflateLib {
   // Maximum bits in a code
   uint256 constant MAXBITS = 15;
   // Maximum number of literal/length codes
   uint256 constant MAXLCODES = 286;
   // Maximum number of distance codes
   uint256 constant MAXDCODES = 30;
   // Maximum codes lengths to read
   uint256 constant MAXCODES = (MAXLCODES + MAXDCODES);
   // Number of fixed literal/length codes
   uint256 constant FIXLCODES = 288;

   // Error codes
   enum ErrorCode {
      ERR_NONE, // 0 successful inflate
      ERR_NOT_TERMINATED, // 1 available inflate data did not terminate
      ERR_OUTPUT_EXHAUSTED, // 2 output space exhausted before completing inflate
      ERR_INVALID_BLOCK_TYPE, // 3 invalid block type (type == 3)
      ERR_STORED_LENGTH_NO_MATCH, // 4 stored block length did not match one's complement
      ERR_TOO_MANY_LENGTH_OR_DISTANCE_CODES, // 5 dynamic block code description: too many length or distance codes
      ERR_CODE_LENGTHS_CODES_INCOMPLETE, // 6 dynamic block code description: code lengths codes incomplete
      ERR_REPEAT_NO_FIRST_LENGTH, // 7 dynamic block code description: repeat lengths with no first length
      ERR_REPEAT_MORE, // 8 dynamic block code description: repeat more than specified lengths
      ERR_INVALID_LITERAL_LENGTH_CODE_LENGTHS, // 9 dynamic block code description: invalid literal/length code lengths
      ERR_INVALID_DISTANCE_CODE_LENGTHS, // 10 dynamic block code description: invalid distance code lengths
      ERR_MISSING_END_OF_BLOCK, // 11 dynamic block code description: missing end-of-block code
      ERR_INVALID_LENGTH_OR_DISTANCE_CODE, // 12 invalid literal/length or distance code in fixed or dynamic block
      ERR_DISTANCE_TOO_FAR, // 13 distance is too far back in fixed or dynamic block
      ERR_CONSTRUCT // 14 internal: error in construct()
   }

   // Input and output state
   struct State {
      //////////////////
      // Output state //
      //////////////////
      // Output buffer
      bytes output;
      // Bytes written to out so far
      uint256 outcnt;
      /////////////////
      // Input state //
      /////////////////
      // Input buffer
      bytes input;
      // Bytes read so far
      uint256 incnt;
      ////////////////
      // Temp state //
      ////////////////
      // Bit buffer
      uint256 bitbuf;
      // Number of bits in bit buffer
      uint256 bitcnt;
      //////////////////////////
      // Static Huffman codes //
      //////////////////////////
      Huffman lencode;
      Huffman distcode;
   }

   // Huffman code decoding tables
   struct Huffman {
      uint256[] counts;
      uint256[] symbols;
   }

   function bits(State memory s, uint256 need) private pure returns (ErrorCode, uint256) {
      // Bit accumulator (can use up to 20 bits)
      uint256 val;

      // Load at least need bits into val
      val = s.bitbuf;
      while (s.bitcnt < need) {
         if (s.incnt == s.input.length) {
            // Out of input
            return (ErrorCode.ERR_NOT_TERMINATED, 0);
         }

         // Load eight bits
         val |= uint256(uint8(s.input[s.incnt++])) << s.bitcnt;
         s.bitcnt += 8;
      }

      // Drop need bits and update buffer, always zero to seven bits left
      s.bitbuf = val >> need;
      s.bitcnt -= need;

      // Return need bits, zeroing the bits above that
      uint256 ret = (val & ((1 << need) - 1));
      return (ErrorCode.ERR_NONE, ret);
   }

   function _stored(State memory s) private pure returns (ErrorCode) {
      // Length of stored block
      uint256 len;

      // Discard leftover bits from current byte (assumes s.bitcnt < 8)
      s.bitbuf = 0;
      s.bitcnt = 0;

      // Get length and check against its one's complement
      if (s.incnt + 4 > s.input.length) {
         // Not enough input
         return ErrorCode.ERR_NOT_TERMINATED;
      }
      len = uint256(uint8(s.input[s.incnt++]));
      len |= uint256(uint8(s.input[s.incnt++])) << 8;

      if (uint8(s.input[s.incnt++]) != (~len & 0xFF) || uint8(s.input[s.incnt++]) != ((~len >> 8) & 0xFF)) {
         // Didn't match complement!
         return ErrorCode.ERR_STORED_LENGTH_NO_MATCH;
      }

      // Copy len bytes from in to out
      if (s.incnt + len > s.input.length) {
         // Not enough input
         return ErrorCode.ERR_NOT_TERMINATED;
      }
      if (s.outcnt + len > s.output.length) {
         // Not enough output space
         return ErrorCode.ERR_OUTPUT_EXHAUSTED;
      }
      while (len != 0) {
         // Note: Solidity reverts on underflow, so we decrement here
         len -= 1;
         s.output[s.outcnt++] = s.input[s.incnt++];
      }

      // Done with a valid stored block
      return ErrorCode.ERR_NONE;
   }

   function _decode(State memory s, Huffman memory h) private pure returns (ErrorCode, uint256) {
      // Current number of bits in code
      uint256 len;
      // Len bits being decoded
      uint256 code = 0;
      // First code of length len
      uint256 first = 0;
      // Number of codes of length len
      uint256 count;
      // Index of first code of length len in symbol table
      uint256 index = 0;
      // Error code
      ErrorCode err;

      for (len = 1; len <= MAXBITS; len++) {
         // Get next bit
         uint256 tempCode;
         (err, tempCode) = bits(s, 1);
         if (err != ErrorCode.ERR_NONE) {
            return (err, 0);
         }
         code |= tempCode;
         count = h.counts[len];

         // If length len, return symbol
         if (code < first + count) {
            return (ErrorCode.ERR_NONE, h.symbols[index + (code - first)]);
         }
         // Else update for next length
         index += count;
         first += count;
         first <<= 1;
         code <<= 1;
      }

      // Ran out of codes
      return (ErrorCode.ERR_INVALID_LENGTH_OR_DISTANCE_CODE, 0);
   }

   function _construct(
      Huffman memory h,
      uint256[] memory lengths,
      uint256 n,
      uint256 start
   ) private pure returns (ErrorCode) {
      // Current symbol when stepping through lengths[]
      uint256 symbol;
      // Current length when stepping through h.counts[]
      uint256 len;
      // Number of possible codes left of current length
      uint256 left;
      // Offsets in symbol table for each length
      uint256[MAXBITS + 1] memory offs;

      // Count number of codes of each length
      for (len = 0; len <= MAXBITS; len++) {
         h.counts[len] = 0;
      }
      for (symbol = 0; symbol < n; symbol++) {
         // Assumes lengths are within bounds
         h.counts[lengths[start + symbol]]++;
      }
      // No codes!
      if (h.counts[0] == n) {
         // Complete, but decode() will fail
         return (ErrorCode.ERR_NONE);
      }

      // Check for an over-subscribed or incomplete set of lengths

      // One possible code of zero length
      left = 1;

      for (len = 1; len <= MAXBITS; len++) {
         // One more bit, double codes left
         left <<= 1;
         if (left < h.counts[len]) {
            // Over-subscribed--return error
            return ErrorCode.ERR_CONSTRUCT;
         }
         // Deduct count from possible codes

         left -= h.counts[len];
      }

      // Generate offsets into symbol table for each length for sorting
      offs[1] = 0;
      for (len = 1; len < MAXBITS; len++) {
         offs[len + 1] = offs[len] + h.counts[len];
      }

      // Put symbols in table sorted by length, by symbol order within each length
      for (symbol = 0; symbol < n; symbol++) {
         if (lengths[start + symbol] != 0) {
            h.symbols[offs[lengths[start + symbol]]++] = symbol;
         }
      }

      // Left > 0 means incomplete
      return left > 0 ? ErrorCode.ERR_CONSTRUCT : ErrorCode.ERR_NONE;
   }

   function _codes(
      State memory s,
      Huffman memory lencode,
      Huffman memory distcode
   ) private pure returns (ErrorCode) {
      // Decoded symbol
      uint256 symbol;
      // Length for copy
      uint256 len;
      // Distance for copy
      uint256 dist;
      // TODO Solidity doesn't support constant arrays, but these are fixed at compile-time
      // Size base for length codes 257..285
      uint16[29] memory lens = [
         3,
         4,
         5,
         6,
         7,
         8,
         9,
         10,
         11,
         13,
         15,
         17,
         19,
         23,
         27,
         31,
         35,
         43,
         51,
         59,
         67,
         83,
         99,
         115,
         131,
         163,
         195,
         227,
         258
      ];
      // Extra bits for length codes 257..285
      uint8[29] memory lext = [0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0];
      // Offset base for distance codes 0..29
      uint16[30] memory dists = [
         1,
         2,
         3,
         4,
         5,
         7,
         9,
         13,
         17,
         25,
         33,
         49,
         65,
         97,
         129,
         193,
         257,
         385,
         513,
         769,
         1025,
         1537,
         2049,
         3073,
         4097,
         6145,
         8193,
         12289,
         16385,
         24577
      ];
      // Extra bits for distance codes 0..29
      uint8[30] memory dext = [0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13];
      // Error code
      ErrorCode err;

      // Decode literals and length/distance pairs
      while (symbol != 256) {
         (err, symbol) = _decode(s, lencode);
         if (err != ErrorCode.ERR_NONE) {
            // Invalid symbol
            return err;
         }

         if (symbol < 256) {
            // Literal: symbol is the byte
            // Write out the literal
            if (s.outcnt == s.output.length) {
               return ErrorCode.ERR_OUTPUT_EXHAUSTED;
            }
            s.output[s.outcnt] = bytes1(uint8(symbol));
            s.outcnt++;
         } else if (symbol > 256) {
            uint256 tempBits;
            // Length
            // Get and compute length
            symbol -= 257;
            if (symbol >= 29) {
               // Invalid fixed code
               return ErrorCode.ERR_INVALID_LENGTH_OR_DISTANCE_CODE;
            }

            (err, tempBits) = bits(s, lext[symbol]);
            if (err != ErrorCode.ERR_NONE) {
               return err;
            }
            len = lens[symbol] + tempBits;

            // Get and check distance
            (err, symbol) = _decode(s, distcode);
            if (err != ErrorCode.ERR_NONE) {
               // Invalid symbol
               return err;
            }
            (err, tempBits) = bits(s, dext[symbol]);
            if (err != ErrorCode.ERR_NONE) {
               return err;
            }
            dist = dists[symbol] + tempBits;
            if (dist > s.outcnt) {
               // Distance too far back
               return ErrorCode.ERR_DISTANCE_TOO_FAR;
            }

            // Copy length bytes from distance bytes back
            if (s.outcnt + len > s.output.length) {
               return ErrorCode.ERR_OUTPUT_EXHAUSTED;
            }
            while (len != 0) {
               // Note: Solidity reverts on underflow, so we decrement here
               len -= 1;
               s.output[s.outcnt] = s.output[s.outcnt - dist];
               s.outcnt++;
            }
         } else {
            s.outcnt += len;
         }
      }

      // Done with a valid fixed or dynamic block
      return ErrorCode.ERR_NONE;
   }

   function _build_fixed(State memory s) private pure returns (ErrorCode) {
      // Build fixed Huffman tables
      // TODO this is all a compile-time constant
      uint256 symbol;
      uint256[] memory lengths = new uint256[](FIXLCODES);

      // Literal/length table
      for (symbol = 0; symbol < 144; symbol++) {
         lengths[symbol] = 8;
      }
      for (; symbol < 256; symbol++) {
         lengths[symbol] = 9;
      }
      for (; symbol < 280; symbol++) {
         lengths[symbol] = 7;
      }
      for (; symbol < FIXLCODES; symbol++) {
         lengths[symbol] = 8;
      }

      _construct(s.lencode, lengths, FIXLCODES, 0);

      // Distance table
      for (symbol = 0; symbol < MAXDCODES; symbol++) {
         lengths[symbol] = 5;
      }

      _construct(s.distcode, lengths, MAXDCODES, 0);

      return ErrorCode.ERR_NONE;
   }

   function _fixed(State memory s) private pure returns (ErrorCode) {
      // Decode data until end-of-block code
      return _codes(s, s.lencode, s.distcode);
   }

   function _build_dynamic_lengths(State memory s) private pure returns (ErrorCode, uint256[] memory) {
      uint256 ncode;
      // Index of lengths[]
      uint256 index;
      // Descriptor code lengths
      uint256[] memory lengths = new uint256[](MAXCODES);
      // Error code
      ErrorCode err;
      // Permutation of code length codes
      uint8[19] memory order = [16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15];

      (err, ncode) = bits(s, 4);
      if (err != ErrorCode.ERR_NONE) {
         return (err, lengths);
      }
      ncode += 4;

      // Read code length code lengths (really), missing lengths are zero
      for (index = 0; index < ncode; index++) {
         (err, lengths[order[index]]) = bits(s, 3);
         if (err != ErrorCode.ERR_NONE) {
            return (err, lengths);
         }
      }
      for (; index < 19; index++) {
         lengths[order[index]] = 0;
      }

      return (ErrorCode.ERR_NONE, lengths);
   }

   function _build_dynamic(State memory s)
      private
      pure
      returns (
         ErrorCode,
         Huffman memory,
         Huffman memory
      )
   {
      // Number of lengths in descriptor
      uint256 nlen;
      uint256 ndist;
      // Index of lengths[]
      uint256 index;
      // Error code
      ErrorCode err;
      // Descriptor code lengths
      uint256[] memory lengths = new uint256[](MAXCODES);
      // Length and distance codes
      Huffman memory lencode = Huffman(new uint256[](MAXBITS + 1), new uint256[](MAXLCODES));
      Huffman memory distcode = Huffman(new uint256[](MAXBITS + 1), new uint256[](MAXDCODES));
      uint256 tempBits;

      // Get number of lengths in each table, check lengths
      (err, nlen) = bits(s, 5);
      if (err != ErrorCode.ERR_NONE) {
         return (err, lencode, distcode);
      }
      nlen += 257;
      (err, ndist) = bits(s, 5);
      if (err != ErrorCode.ERR_NONE) {
         return (err, lencode, distcode);
      }
      ndist += 1;

      if (nlen > MAXLCODES || ndist > MAXDCODES) {
         // Bad counts
         return (ErrorCode.ERR_TOO_MANY_LENGTH_OR_DISTANCE_CODES, lencode, distcode);
      }

      (err, lengths) = _build_dynamic_lengths(s);
      if (err != ErrorCode.ERR_NONE) {
         return (err, lencode, distcode);
      }

      // Build huffman table for code lengths codes (use lencode temporarily)
      err = _construct(lencode, lengths, 19, 0);
      if (err != ErrorCode.ERR_NONE) {
         // Require complete code set here
         return (ErrorCode.ERR_CODE_LENGTHS_CODES_INCOMPLETE, lencode, distcode);
      }

      // Read length/literal and distance code length tables
      index = 0;
      while (index < nlen + ndist) {
         // Decoded value
         uint256 symbol;
         // Last length to repeat
         uint256 len;

         (err, symbol) = _decode(s, lencode);
         if (err != ErrorCode.ERR_NONE) {
            // Invalid symbol
            return (err, lencode, distcode);
         }

         if (symbol < 16) {
            // Length in 0..15
            lengths[index++] = symbol;
         } else {
            // Repeat instruction
            // Assume repeating zeros
            len = 0;
            if (symbol == 16) {
               // Repeat last length 3..6 times
               if (index == 0) {
                  // No last length!
                  return (ErrorCode.ERR_REPEAT_NO_FIRST_LENGTH, lencode, distcode);
               }
               // Last length
               len = lengths[index - 1];
               (err, tempBits) = bits(s, 2);
               if (err != ErrorCode.ERR_NONE) {
                  return (err, lencode, distcode);
               }
               symbol = 3 + tempBits;
            } else if (symbol == 17) {
               // Repeat zero 3..10 times
               (err, tempBits) = bits(s, 3);
               if (err != ErrorCode.ERR_NONE) {
                  return (err, lencode, distcode);
               }
               symbol = 3 + tempBits;
            } else {
               // == 18, repeat zero 11..138 times
               (err, tempBits) = bits(s, 7);
               if (err != ErrorCode.ERR_NONE) {
                  return (err, lencode, distcode);
               }
               symbol = 11 + tempBits;
            }

            if (index + symbol > nlen + ndist) {
               // Too many lengths!
               return (ErrorCode.ERR_REPEAT_MORE, lencode, distcode);
            }
            while (symbol != 0) {
               // Note: Solidity reverts on underflow, so we decrement here
               symbol -= 1;

               // Repeat last or zero symbol times
               lengths[index++] = len;
            }
         }
      }

      // Check for end-of-block code -- there better be one!
      if (lengths[256] == 0) {
         return (ErrorCode.ERR_MISSING_END_OF_BLOCK, lencode, distcode);
      }

      // Build huffman table for literal/length codes
      err = _construct(lencode, lengths, nlen, 0);
      if (
         err != ErrorCode.ERR_NONE &&
         (err == ErrorCode.ERR_NOT_TERMINATED || err == ErrorCode.ERR_OUTPUT_EXHAUSTED || nlen != lencode.counts[0] + lencode.counts[1])
      ) {
         // Incomplete code ok only for single length 1 code
         return (ErrorCode.ERR_INVALID_LITERAL_LENGTH_CODE_LENGTHS, lencode, distcode);
      }

      // Build huffman table for distance codes
      err = _construct(distcode, lengths, ndist, nlen);
      if (
         err != ErrorCode.ERR_NONE &&
         (err == ErrorCode.ERR_NOT_TERMINATED || err == ErrorCode.ERR_OUTPUT_EXHAUSTED || ndist != distcode.counts[0] + distcode.counts[1])
      ) {
         // Incomplete code ok only for single length 1 code
         return (ErrorCode.ERR_INVALID_DISTANCE_CODE_LENGTHS, lencode, distcode);
      }

      return (ErrorCode.ERR_NONE, lencode, distcode);
   }

   function _dynamic(State memory s) private pure returns (ErrorCode) {
      // Length and distance codes
      Huffman memory lencode;
      Huffman memory distcode;
      // Error code
      ErrorCode err;

      (err, lencode, distcode) = _build_dynamic(s);
      if (err != ErrorCode.ERR_NONE) {
         return err;
      }

      // Decode data until end-of-block code
      return _codes(s, lencode, distcode);
   }

   function puff(bytes memory source, uint256 destlen) internal pure returns (ErrorCode, bytes memory) {
      // Input/output state
      State memory s = State(
         new bytes(destlen),
         0,
         source,
         0,
         0,
         0,
         Huffman(new uint256[](MAXBITS + 1), new uint256[](FIXLCODES)),
         Huffman(new uint256[](MAXBITS + 1), new uint256[](MAXDCODES))
      );
      // Temp: last bit
      uint256 last;
      // Temp: block type bit
      uint256 t;
      // Error code
      ErrorCode err;

      // Build fixed Huffman tables
      err = _build_fixed(s);
      if (err != ErrorCode.ERR_NONE) {
         return (err, s.output);
      }

      // Process blocks until last block or error
      while (last == 0) {
         // One if last block
         (err, last) = bits(s, 1);
         if (err != ErrorCode.ERR_NONE) {
            return (err, s.output);
         }

         // Block type 0..3
         (err, t) = bits(s, 2);
         if (err != ErrorCode.ERR_NONE) {
            return (err, s.output);
         }

         err = (t == 0 ? _stored(s) : (t == 1 ? _fixed(s) : (t == 2 ? _dynamic(s) : ErrorCode.ERR_INVALID_BLOCK_TYPE)));
         // type == 3, invalid

         if (err != ErrorCode.ERR_NONE) {
            // Return with error
            break;
         }
      }

      return (err, s.output);
   }
}

// SPDX-License-Identifier: MIT
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>

library Base64 {
   string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

   function encode(bytes memory data) internal pure returns (string memory) {
      if (data.length == 0) return "";

      // load the table into memory
      string memory table = TABLE;

      // multiply by 4/3 rounded up
      uint256 encodedLen = 4 * ((data.length + 2) / 3);

      // add some extra buffer at the end required for the writing
      string memory result = new string(encodedLen + 32);

      assembly {
         // set the actual output length
         mstore(result, encodedLen)

         // prepare the lookup table
         let tablePtr := add(table, 1)

         // input ptr
         let dataPtr := data
         let endPtr := add(dataPtr, mload(data))

         // result ptr, jump over length
         let resultPtr := add(result, 32)

         // run over the input, 3 bytes at a time
         for {

         } lt(dataPtr, endPtr) {

         } {
            dataPtr := add(dataPtr, 3)

            // read 3 bytes
            let input := mload(dataPtr)

            // write 4 characters
            mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
            resultPtr := add(resultPtr, 1)
            mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
            resultPtr := add(resultPtr, 1)
            mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
            resultPtr := add(resultPtr, 1)
            mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
            resultPtr := add(resultPtr, 1)
         }

         // padding with '='
         switch mod(mload(data), 3)
         case 1 {
            mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
         }
         case 2 {
            mstore(sub(resultPtr, 1), shl(248, 0x3d))
         }
      }

      return result;
   }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Bytecode.sol";

/**
  @title A key-value storage with auto-generated keys for storing chunks of data with a lower write & read cost.
  @author Agustin Aguilar <[email protected]>

  Readme: https://github.com/0xsequence/sstore2#readme
*/
library SSTORE2 {
  error WriteError();

  /**
    @notice Stores `_data` and returns `pointer` as key for later retrieval
    @dev The pointer is a contract address with `_data` as code
    @param _data to be written
    @return pointer Pointer to the written `_data`
  */
  function write(bytes memory _data) internal returns (address pointer) {
    // Append 00 to _data so contract can't be called
    // Build init code
    bytes memory code = Bytecode.creationCodeFor(
      abi.encodePacked(
        hex'00',
        _data
      )
    );

    // Deploy contract using create
    assembly { pointer := create(0, add(code, 32), mload(code)) }

    // Address MUST be non-zero
    if (pointer == address(0)) revert WriteError();
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @return data read from `_pointer` contract
  */
  function read(address _pointer) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, 1, type(uint256).max);
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @return data read from `_pointer` contract
  */
  function read(address _pointer, uint256 _start) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, _start + 1, type(uint256).max);
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @param _end index before which to end extraction
    @return data read from `_pointer` contract
  */
  function read(address _pointer, uint256 _start, uint256 _end) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, _start + 1, _end + 1);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library Bytecode {
  error InvalidCodeAtRange(uint256 _size, uint256 _start, uint256 _end);

  /**
    @notice Generate a creation code that results on a contract with `_code` as bytecode
    @param _code The returning value of the resulting `creationCode`
    @return creationCode (constructor) for new contract
  */
  function creationCodeFor(bytes memory _code) internal pure returns (bytes memory) {
    /*
      0x00    0x63         0x63XXXXXX  PUSH4 _code.length  size
      0x01    0x80         0x80        DUP1                size size
      0x02    0x60         0x600e      PUSH1 14            14 size size
      0x03    0x60         0x6000      PUSH1 00            0 14 size size
      0x04    0x39         0x39        CODECOPY            size
      0x05    0x60         0x6000      PUSH1 00            0 size
      0x06    0xf3         0xf3        RETURN
      <CODE>
    */

    return abi.encodePacked(
      hex"63",
      uint32(_code.length),
      hex"80_60_0E_60_00_39_60_00_F3",
      _code
    );
  }

  /**
    @notice Returns the size of the code on a given address
    @param _addr Address that may or may not contain code
    @return size of the code on the given `_addr`
  */
  function codeSize(address _addr) internal view returns (uint256 size) {
    assembly { size := extcodesize(_addr) }
  }

  /**
    @notice Returns the code of a given address
    @dev It will fail if `_end < _start`
    @param _addr Address that may or may not contain code
    @param _start number of bytes of code to skip on read
    @param _end index before which to end extraction
    @return oCode read from `_addr` deployed bytecode

    Forked from: https://gist.github.com/KardanovIR/fe98661df9338c842b4a30306d507fbd
  */
  function codeAt(address _addr, uint256 _start, uint256 _end) internal view returns (bytes memory oCode) {
    uint256 csize = codeSize(_addr);
    if (csize == 0) return bytes("");

    if (_start > csize) return bytes("");
    if (_end < _start) revert InvalidCodeAtRange(csize, _start, _end); 

    unchecked {
      uint256 reqSize = _end - _start;
      uint256 maxSize = csize - _start;

      uint256 size = maxSize < reqSize ? maxSize : reqSize;

      assembly {
        // allocate output byte array - this could also be done without assembly
        // by using o_code = new bytes(size)
        oCode := mload(0x40)
        // new "memory end" including padding
        mstore(0x40, add(oCode, and(add(add(size, 0x20), 0x1f), not(0x1f))))
        // store length in memory
        mstore(oCode, size)
        // actually retrieve the code, this needs assembly
        extcodecopy(_addr, add(oCode, 0x20), _start, size)
      }
    }
  }
}