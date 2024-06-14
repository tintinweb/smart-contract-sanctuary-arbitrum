// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {StrSlice, toSlice} from "dk1a/solidity-stringutils/StrSlice.sol";
import {IERC7231} from "./interface/IERC7231.sol";

contract ThirdfiID is
    IERC7231,
    ERC721Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable
{
    using Strings for uint256;
    using {toSlice} for string;

    // ERC7231
    mapping(uint256 => bytes32) private _idMultiIdentitiesRootBinding;
    mapping(uint256 => mapping(bytes32 => bool)) internal _idSignatureSetting;

    mapping(uint256 => uint256) public boostCount;
    mapping(address => bytes32[]) public hashList;
    address public mintSigner;
    uint256 public boostFee;
    uint256 private nextTokenId;

    error ALREADY_MINTED();
    error NOT_ENOUGH_FEE();
    error INVALID_SIGNATURE();
    error SIGNATURE_EXPIRED();
    error FEE_TRANSFER_FAILED();
    error TRANSFER_NOT_ALLOWED();
    error ONLY_TOKEN_OWNER();
    error INCORRECT_TOKEN_OWNER();

    event Boost(uint256 tokenId, address owner, uint256 amount, uint256 boostCount, bytes32 hash);
    event FeeWithdraw(address to, uint256 amount);
    event MintSignerSet(address mintSigner);
    event BoostFeeSet(uint256 boostFee);
    event Mint(address indexed to, uint256 tokenId);

    function initialize(
        address admin,
        address _mintSigner,
        uint256 _boostFee
    ) public initializer {
        __ERC721_init("ThirdFi ID", "ThirdFi ID");
        __Ownable_init(admin);

        mintSigner = _mintSigner;
        boostFee = _boostFee;

        nextTokenId = 1;
    }

    function boost(uint256 tokenId) external payable nonReentrant {
        address tokenOwner = ownerOf(tokenId);
        // ownerOf(tokenId) will throw error ERC721NonexistentToken(tokenId)
        // if tokenId does not exist

        if (msg.value < boostFee) {
            revert NOT_ENOUGH_FEE();
        }

        boostCount[tokenId] += 1;

        bytes32 calculatedHash = _calculateHash(msg.sender, tokenId, boostCount[tokenId]);
        hashList[msg.sender].push(calculatedHash);

        emit Boost(
            tokenId, 
            tokenOwner,
            boostFee, 
            boostCount[tokenId], 
            calculatedHash
        );
    }

    function mint(
        uint256 fee,
        uint256 expiry,
        bytes calldata signature // required for using our platform to mint
    ) external payable nonReentrant {
        if (balanceOf(msg.sender) > 0) {
            revert ALREADY_MINTED();
        }

        if (msg.value < fee) {
            revert NOT_ENOUGH_FEE();
        }

        if (block.timestamp > expiry) {
            revert SIGNATURE_EXPIRED();
        }

        bytes32 hash = keccak256(
            abi.encodePacked(msg.sender, block.chainid, fee, expiry)
        );
        bytes32 messageHash = MessageHashUtils.toEthSignedMessageHash(hash);
        address signer = ECDSA.recover(messageHash, signature);

        if (signer != mintSigner) {
            revert INVALID_SIGNATURE();
        }

        uint256 tokenId = nextTokenId;
        super._mint(msg.sender, tokenId);
        nextTokenId++;

        bytes32 calculatedHash = _calculateHash(msg.sender, tokenId, 0);
        hashList[msg.sender].push(calculatedHash);

        emit Boost(
            tokenId, 
            msg.sender,
            fee,
            0,
            calculatedHash
        );
        
        emit Mint(msg.sender, tokenId);
    }

    function transferFrom(
        address,
        address,
        uint256
    ) public pure override {
        revert TRANSFER_NOT_ALLOWED();
    }

    function withdrawFee(address payable to) external onlyOwner {
        uint256 amount = address(this).balance;

        if (amount > 0) {
            (bool success, ) = to.call{value: amount}("");
             if (!success) revert FEE_TRANSFER_FAILED();
        }
        emit FeeWithdraw(to, amount);
    }

    receive() external payable {}

    function setMintSigner(address _mintSigner) external onlyOwner {
        mintSigner = _mintSigner;
        emit MintSignerSet(_mintSigner);
    }

    function setBoostFee(uint _boostFee) external onlyOwner {
        boostFee = _boostFee;
        emit BoostFeeSet(_boostFee);
    }

    function tokenURI(
        uint256
    ) public view virtual override returns (string memory) {
        return string.concat("ipfs://QmVvJZfPhMzVFHRQs8SViWC93CyLKYveYd4hZj2DmmeNX7");
    }

    function _calculateHash(address caller, uint256 tokenId, uint256 count) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(
            caller,
            tokenId,
            block.chainid,
            count,
            block.timestamp,
            blockhash(block.number - (block.timestamp % 255))
        ));
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyOwner {}

    //////////////////////////////////////////////////////////////////
    ///////////////////////////// ERC 7231 ///////////////////////////
    //////////////////////////////////////////////////////////////////

    modifier onlyTokenOwner(uint256 id) {
        if (ownerOf(id) != msg.sender) {
            revert ONLY_TOKEN_OWNER();
        }
        _;
    }

    function setIdentitiesRoot(
        uint256 id,
        bytes32 multiIdentitiesRoot
    ) external override onlyTokenOwner(id) {
        _idMultiIdentitiesRootBinding[id] = multiIdentitiesRoot;
        emit SetIdentitiesRoot(id, multiIdentitiesRoot);
    }

    function getIdentitiesRoot(
        uint256 id
    ) external view override returns (bytes32) {
        return _idMultiIdentitiesRootBinding[id];
    }

    function verifyIdentitiesBinding(
        uint256 id,
        address nftOwnerAddress,
        string[] memory userIDs,
        bytes32 multiIdentitiesRoot,
        bytes calldata signature
    ) external view override returns (bool) {
        //nft ownership validation
        if (ownerOf(id) != nftOwnerAddress) {
            revert INCORRECT_TOKEN_OWNER();
        }

        //multi-identities root consistency validation
        require(_idMultiIdentitiesRootBinding[id] == multiIdentitiesRoot, "");

        //user id format validtion
        uint256 userIDLen = userIDs.length;
        require(userIDLen > 0, "userID cannot be empty");

        for (uint i = 0; i < userIDLen; i++) {
            _verifyUserID(userIDs[i]);
        }

        //signature validation from nft owner
        bool isVerified = SignatureChecker.isValidSignatureNow(
            msg.sender,
            multiIdentitiesRoot,
            signature
        );
        return isVerified;
    }

    function _verifyUserID(string memory userID) internal view {
        if (bytes(userID).length == 0) {
            revert USERID_CANNOT_BE_EMPTY();
        }

        //first part(encryption algorithm or did) check
        string memory strSplit = ":";
        bool found;
        StrSlice left;
        StrSlice right = userID.toSlice();
        (found, left, right) = right.splitOnce(strSplit.toSlice());
        if (!found) {
            revert THE_FIRST_PART_DELIMITER_DOES_NOT_EXIST();
        }
        if (bytes(right.toString()).length == 0) {
            revert THE_FIRST_PART_DOES_NOT_EXIST();
        }

        //second part(Organization Information) check
        (found, left, right) = right.splitOnce(strSplit.toSlice());
        if (!found) {
            revert THE_SECOND_PART_DELIMITER_DOES_NOT_EXIST();
        }
        if (bytes(right.toString()).length == 0) {
            revert THE_SECOND_PART_DOES_NOT_EXIST();
        }

        //id hash check
        if (bytes(right.toString()).length != 64) {
            revert ID_HASH_LENGTH_IS_NOT_CORRECT();
        }
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC7231).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.20;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {ContextUpgradeable} from "../../utils/ContextUpgradeable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {ERC165Upgradeable} from "../../utils/introspection/ERC165Upgradeable.sol";
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {Initializable} from "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
abstract contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721, IERC721Metadata, IERC721Errors {
    using Strings for uint256;

    /// @custom:storage-location erc7201:openzeppelin.storage.ERC721
    struct ERC721Storage {
        // Token name
        string _name;

        // Token symbol
        string _symbol;

        mapping(uint256 tokenId => address) _owners;

        mapping(address owner => uint256) _balances;

        mapping(uint256 tokenId => address) _tokenApprovals;

        mapping(address owner => mapping(address operator => bool)) _operatorApprovals;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.ERC721")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ERC721StorageLocation = 0x80bb2b638cc20bc4d0a60d66940f3ab4a00c1d7b313497ca82fb0b4ab0079300;

    function _getERC721Storage() private pure returns (ERC721Storage storage $) {
        assembly {
            $.slot := ERC721StorageLocation
        }
    }

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        ERC721Storage storage $ = _getERC721Storage();
        $._name = name_;
        $._symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual returns (uint256) {
        ERC721Storage storage $ = _getERC721Storage();
        if (owner == address(0)) {
            revert ERC721InvalidOwner(address(0));
        }
        return $._balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        return _requireOwned(tokenId);
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual returns (string memory) {
        ERC721Storage storage $ = _getERC721Storage();
        return $._name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual returns (string memory) {
        ERC721Storage storage $ = _getERC721Storage();
        return $._symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        _requireOwned(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string.concat(baseURI, tokenId.toString()) : "";
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
    function approve(address to, uint256 tokenId) public virtual {
        _approve(to, tokenId, _msgSender());
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual returns (address) {
        _requireOwned(tokenId);

        return _getApproved(tokenId);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        ERC721Storage storage $ = _getERC721Storage();
        return $._operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        // Setting an "auth" arguments enables the `_isAuthorized` check which verifies that the token exists
        // (from != 0). Therefore, it is not needed to verify that the return value is not 0 here.
        address previousOwner = _update(to, tokenId, _msgSender());
        if (previousOwner != from) {
            revert ERC721IncorrectOwner(from, tokenId, previousOwner);
        }
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual {
        transferFrom(from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, data);
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     *
     * IMPORTANT: Any overrides to this function that add ownership of tokens not tracked by the
     * core ERC721 logic MUST be matched with the use of {_increaseBalance} to keep balances
     * consistent with ownership. The invariant to preserve is that for any address `a` the value returned by
     * `balanceOf(a)` must be equal to the number of tokens such that `_ownerOf(tokenId)` is `a`.
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        ERC721Storage storage $ = _getERC721Storage();
        return $._owners[tokenId];
    }

    /**
     * @dev Returns the approved address for `tokenId`. Returns 0 if `tokenId` is not minted.
     */
    function _getApproved(uint256 tokenId) internal view virtual returns (address) {
        ERC721Storage storage $ = _getERC721Storage();
        return $._tokenApprovals[tokenId];
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `owner`'s tokens, or `tokenId` in
     * particular (ignoring whether it is owned by `owner`).
     *
     * WARNING: This function assumes that `owner` is the actual owner of `tokenId` and does not verify this
     * assumption.
     */
    function _isAuthorized(address owner, address spender, uint256 tokenId) internal view virtual returns (bool) {
        return
            spender != address(0) &&
            (owner == spender || isApprovedForAll(owner, spender) || _getApproved(tokenId) == spender);
    }

    /**
     * @dev Checks if `spender` can operate on `tokenId`, assuming the provided `owner` is the actual owner.
     * Reverts if `spender` does not have approval from the provided `owner` for the given token or for all its assets
     * the `spender` for the specific `tokenId`.
     *
     * WARNING: This function assumes that `owner` is the actual owner of `tokenId` and does not verify this
     * assumption.
     */
    function _checkAuthorized(address owner, address spender, uint256 tokenId) internal view virtual {
        if (!_isAuthorized(owner, spender, tokenId)) {
            if (owner == address(0)) {
                revert ERC721NonexistentToken(tokenId);
            } else {
                revert ERC721InsufficientApproval(spender, tokenId);
            }
        }
    }

    /**
     * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
     *
     * NOTE: the value is limited to type(uint128).max. This protect against _balance overflow. It is unrealistic that
     * a uint256 would ever overflow from increments when these increments are bounded to uint128 values.
     *
     * WARNING: Increasing an account's balance using this function tends to be paired with an override of the
     * {_ownerOf} function to resolve the ownership of the corresponding tokens so that balances and ownership
     * remain consistent with one another.
     */
    function _increaseBalance(address account, uint128 value) internal virtual {
        ERC721Storage storage $ = _getERC721Storage();
        unchecked {
            $._balances[account] += value;
        }
    }

    /**
     * @dev Transfers `tokenId` from its current owner to `to`, or alternatively mints (or burns) if the current owner
     * (or `to`) is the zero address. Returns the owner of the `tokenId` before the update.
     *
     * The `auth` argument is optional. If the value passed is non 0, then this function will check that
     * `auth` is either the owner of the token, or approved to operate on the token (by the owner).
     *
     * Emits a {Transfer} event.
     *
     * NOTE: If overriding this function in a way that tracks balances, see also {_increaseBalance}.
     */
    function _update(address to, uint256 tokenId, address auth) internal virtual returns (address) {
        ERC721Storage storage $ = _getERC721Storage();
        address from = _ownerOf(tokenId);

        // Perform (optional) operator check
        if (auth != address(0)) {
            _checkAuthorized(from, auth, tokenId);
        }

        // Execute the update
        if (from != address(0)) {
            // Clear approval. No need to re-authorize or emit the Approval event
            _approve(address(0), tokenId, address(0), false);

            unchecked {
                $._balances[from] -= 1;
            }
        }

        if (to != address(0)) {
            unchecked {
                $._balances[to] += 1;
            }
        }

        $._owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        return from;
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
    function _mint(address to, uint256 tokenId) internal {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        address previousOwner = _update(to, tokenId, address(0));
        if (previousOwner != address(0)) {
            revert ERC721InvalidSender(address(0));
        }
    }

    /**
     * @dev Mints `tokenId`, transfers it to `to` and checks for `to` acceptance.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);
        _checkOnERC721Received(address(0), to, tokenId, data);
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
    function _burn(uint256 tokenId) internal {
        address previousOwner = _update(address(0), tokenId, address(0));
        if (previousOwner == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        }
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
    function _transfer(address from, address to, uint256 tokenId) internal {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        address previousOwner = _update(to, tokenId, address(0));
        if (previousOwner == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        } else if (previousOwner != from) {
            revert ERC721IncorrectOwner(from, tokenId, previousOwner);
        }
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking that contract recipients
     * are aware of the ERC721 standard to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is like {safeTransferFrom} in the sense that it invokes
     * {IERC721Receiver-onERC721Received} on the receiver, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `tokenId` token must exist and be owned by `from`.
     * - `to` cannot be the zero address.
     * - `from` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId) internal {
        _safeTransfer(from, to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeTransfer-address-address-uint256-}[`_safeTransfer`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, data);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * The `auth` argument is optional. If the value passed is non 0, then this function will check that `auth` is
     * either the owner of the token, or approved to operate on all tokens held by this owner.
     *
     * Emits an {Approval} event.
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address to, uint256 tokenId, address auth) internal {
        _approve(to, tokenId, auth, true);
    }

    /**
     * @dev Variant of `_approve` with an optional flag to enable or disable the {Approval} event. The event is not
     * emitted in the context of transfers.
     */
    function _approve(address to, uint256 tokenId, address auth, bool emitEvent) internal virtual {
        ERC721Storage storage $ = _getERC721Storage();
        // Avoid reading the owner unless necessary
        if (emitEvent || auth != address(0)) {
            address owner = _requireOwned(tokenId);

            // We do not use _isAuthorized because single-token approvals should not be able to call approve
            if (auth != address(0) && owner != auth && !isApprovedForAll(owner, auth)) {
                revert ERC721InvalidApprover(auth);
            }

            if (emitEvent) {
                emit Approval(owner, to, tokenId);
            }
        }

        $._tokenApprovals[tokenId] = to;
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Requirements:
     * - operator can't be the address zero.
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        ERC721Storage storage $ = _getERC721Storage();
        if (operator == address(0)) {
            revert ERC721InvalidOperator(operator);
        }
        $._operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` doesn't have a current owner (it hasn't been minted, or it has been burned).
     * Returns the owner.
     *
     * Overrides to ownership logic should be done to {_ownerOf}.
     */
    function _requireOwned(uint256 tokenId) internal view returns (address) {
        address owner = _ownerOf(tokenId);
        if (owner == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        }
        return owner;
    }

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target address. This will revert if the
     * recipient doesn't accept the token transfer. The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                if (retval != IERC721Receiver.onERC721Received.selector) {
                    revert ERC721InvalidReceiver(to);
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert ERC721InvalidReceiver(to);
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {ContextUpgradeable} from "../utils/ContextUpgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    /// @custom:storage-location erc7201:openzeppelin.storage.Ownable
    struct OwnableStorage {
        address _owner;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Ownable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant OwnableStorageLocation = 0x9016d09d72d40fdae2fd8ceac6b6234c7706214fd39c1cd1e609a0528c199300;

    function _getOwnableStorage() private pure returns (OwnableStorage storage $) {
        assembly {
            $.slot := OwnableStorageLocation
        }
    }

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    function __Ownable_init(address initialOwner) internal onlyInitializing {
        __Ownable_init_unchained(initialOwner);
    }

    function __Ownable_init_unchained(address initialOwner) internal onlyInitializing {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        OwnableStorage storage $ = _getOwnableStorage();
        return $._owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        OwnableStorage storage $ = _getOwnableStorage();
        address oldOwner = $._owner;
        $._owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;
import {Initializable} from "../proxy/utils/Initializable.sol";

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
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    /// @custom:storage-location erc7201:openzeppelin.storage.ReentrancyGuard
    struct ReentrancyGuardStorage {
        uint256 _status;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.ReentrancyGuard")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ReentrancyGuardStorageLocation = 0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00;

    function _getReentrancyGuardStorage() private pure returns (ReentrancyGuardStorage storage $) {
        assembly {
            $.slot := ReentrancyGuardStorageLocation
        }
    }

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
        $._status = NOT_ENTERED;
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
        ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if ($._status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        $._status = ENTERED;
    }

    function _nonReentrantAfter() private {
        ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        $._status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
        return $._status == ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.20;

import {IERC1822Proxiable} from "../../interfaces/draft-IERC1822.sol";
import {ERC1967Utils} from "../ERC1967/ERC1967Utils.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 */
abstract contract UUPSUpgradeable is IERC1822Proxiable {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable __self = address(this);

    /**
     * @dev The version of the upgrade interface of the contract. If this getter is missing, both `upgradeTo(address)`
     * and `upgradeToAndCall(address,bytes)` are present, and `upgradeTo` must be used if no function should be called,
     * while `upgradeToAndCall` will invoke the `receive` function if the second argument is the empty byte string.
     * If the getter returns `"5.0.0"`, only `upgradeToAndCall(address,bytes)` is present, and the second argument must
     * be the empty byte string if no function should be called, making it impossible to invoke the `receive` function
     * during an upgrade.
     */
    string public constant UPGRADE_INTERFACE_VERSION = "5.0.0";

    /**
     * @dev The call is from an unauthorized context.
     */
    error UUPSUnauthorizedCallContext();

    /**
     * @dev The storage `slot` is unsupported as a UUID.
     */
    error UUPSUnsupportedProxiableUUID(bytes32 slot);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        _checkProxy();
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        _checkNotDelegated();
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual notDelegated returns (bytes32) {
        return ERC1967Utils.IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) public payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data);
    }

    /**
     * @dev Reverts if the execution is not performed via delegatecall or the execution
     * context is not of a proxy with an ERC1967-compliant implementation pointing to self.
     * See {_onlyProxy}.
     */
    function _checkProxy() internal view virtual {
        if (
            address(this) == __self || // Must be called through delegatecall
            ERC1967Utils.getImplementation() != __self // Must be called through an active proxy
        ) {
            revert UUPSUnauthorizedCallContext();
        }
    }

    /**
     * @dev Reverts if the execution is performed via delegatecall.
     * See {notDelegated}.
     */
    function _checkNotDelegated() internal view virtual {
        if (address(this) != __self) {
            // Must not be called through delegatecall
            revert UUPSUnauthorizedCallContext();
        }
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev Performs an implementation upgrade with a security check for UUPS proxies, and additional setup call.
     *
     * As a security check, {proxiableUUID} is invoked in the new implementation, and the return value
     * is expected to be the implementation slot in ERC1967.
     *
     * Emits an {IERC1967-Upgraded} event.
     */
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data) private {
        try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
            if (slot != ERC1967Utils.IMPLEMENTATION_SLOT) {
                revert UUPSUnsupportedProxiableUUID(slot);
            }
            ERC1967Utils.upgradeToAndCall(newImplementation, data);
        } catch {
            // The implementation is not UUPS
            revert ERC1967Utils.ERC1967InvalidImplementation(newImplementation);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Strings.sol)

pragma solidity ^0.8.20;

import {Math} from "./math/Math.sol";
import {SignedMath} from "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant HEX_DIGITS = "0123456789abcdef";
    uint8 private constant ADDRESS_LENGTH = 20;

    /**
     * @dev The `value` string doesn't fit in the specified `length`.
     */
    error StringsInsufficientHexLength(uint256 value, uint256 length);

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
                    mstore8(ptr, byte(mod(value, 10), HEX_DIGITS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toStringSigned(int256 value) internal pure returns (string memory) {
        return string.concat(value < 0 ? "-" : "", toString(SignedMath.abs(value)));
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
        uint256 localValue = value;
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = HEX_DIGITS[localValue & 0xf];
            localValue >>= 4;
        }
        if (localValue != 0) {
            revert StringsInsufficientHexLength(value, length);
        }
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal
     * representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return bytes(a).length == bytes(b).length && keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.20;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS
    }

    /**
     * @dev The signature derives the `address(0)`.
     */
    error ECDSAInvalidSignature();

    /**
     * @dev The signature has an invalid length.
     */
    error ECDSAInvalidSignatureLength(uint256 length);

    /**
     * @dev The signature has an S value that is in the upper half order.
     */
    error ECDSAInvalidSignatureS(bytes32 s);

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with `signature` or an error. This will not
     * return address(0) without also returning an error description. Errors are documented using an enum (error type)
     * and a bytes32 providing additional information about the error.
     *
     * If no error is returned, then the address can be used for verification purposes.
     *
     * The `ecrecover` EVM precompile allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {MessageHashUtils-toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError, bytes32) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength, bytes32(signature.length));
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM precompile allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {MessageHashUtils-toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, signature);
        _throwError(error, errorArg);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError, bytes32) {
        unchecked {
            bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
            // We do not check for an overflow here since the shift operation results in 0 or 1.
            uint8 v = uint8((uint256(vs) >> 255) + 27);
            return tryRecover(hash, v, r, s);
        }
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, r, vs);
        _throwError(error, errorArg);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError, bytes32) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS, s);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature, bytes32(0));
        }

        return (signer, RecoverError.NoError, bytes32(0));
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, v, r, s);
        _throwError(error, errorArg);
        return recovered;
    }

    /**
     * @dev Optionally reverts with the corresponding custom error according to the `error` argument provided.
     */
    function _throwError(RecoverError error, bytes32 errorArg) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert ECDSAInvalidSignature();
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert ECDSAInvalidSignatureLength(uint256(errorArg));
        } else if (error == RecoverError.InvalidSignatureS) {
            revert ECDSAInvalidSignatureS(errorArg);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/cryptography/MessageHashUtils.sol)

pragma solidity ^0.8.20;

import {Strings} from "../Strings.sol";

/**
 * @dev Signature message hash utilities for producing digests to be consumed by {ECDSA} recovery or signing.
 *
 * The library provides methods for generating a hash of a message that conforms to the
 * https://eips.ethereum.org/EIPS/eip-191[EIP 191] and https://eips.ethereum.org/EIPS/eip-712[EIP 712]
 * specifications.
 */
library MessageHashUtils {
    /**
     * @dev Returns the keccak256 digest of an EIP-191 signed data with version
     * `0x45` (`personal_sign` messages).
     *
     * The digest is calculated by prefixing a bytes32 `messageHash` with
     * `"\x19Ethereum Signed Message:\n32"` and hashing the result. It corresponds with the
     * hash signed when using the https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`] JSON-RPC method.
     *
     * NOTE: The `messageHash` parameter is intended to be the result of hashing a raw message with
     * keccak256, although any bytes32 value can be safely used because the final digest will
     * be re-hashed.
     *
     * See {ECDSA-recover}.
     */
    function toEthSignedMessageHash(bytes32 messageHash) internal pure returns (bytes32 digest) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32") // 32 is the bytes-length of messageHash
            mstore(0x1c, messageHash) // 0x1c (28) is the length of the prefix
            digest := keccak256(0x00, 0x3c) // 0x3c is the length of the prefix (0x1c) + messageHash (0x20)
        }
    }

    /**
     * @dev Returns the keccak256 digest of an EIP-191 signed data with version
     * `0x45` (`personal_sign` messages).
     *
     * The digest is calculated by prefixing an arbitrary `message` with
     * `"\x19Ethereum Signed Message:\n" + len(message)` and hashing the result. It corresponds with the
     * hash signed when using the https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`] JSON-RPC method.
     *
     * See {ECDSA-recover}.
     */
    function toEthSignedMessageHash(bytes memory message) internal pure returns (bytes32) {
        return
            keccak256(bytes.concat("\x19Ethereum Signed Message:\n", bytes(Strings.toString(message.length)), message));
    }

    /**
     * @dev Returns the keccak256 digest of an EIP-191 signed data with version
     * `0x00` (data with intended validator).
     *
     * The digest is calculated by prefixing an arbitrary `data` with `"\x19\x00"` and the intended
     * `validator` address. Then hashing the result.
     *
     * See {ECDSA-recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(hex"19_00", validator, data));
    }

    /**
     * @dev Returns the keccak256 digest of an EIP-712 typed data (EIP-191 version `0x01`).
     *
     * The digest is calculated from a `domainSeparator` and a `structHash`, by prefixing them with
     * `\x19\x01` and hashing the result. It corresponds to the hash signed by the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`] JSON-RPC method as part of EIP-712.
     *
     * See {ECDSA-recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 digest) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, hex"19_01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            digest := keccak256(ptr, 0x42)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.20;

import {ECDSA} from "./ECDSA.sol";
import {IERC1271} from "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Safe Wallet (previously Gnosis Safe).
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(address signer, bytes32 hash, bytes memory signature) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error, ) = ECDSA.tryRecover(hash, signature);
        return
            (error == ECDSA.RecoverError.NoError && recovered == signer) ||
            isValidERC1271SignatureNow(signer, hash, signature);
    }

    /**
     * @dev Checks if a signature is valid for a given signer and data hash. The signature is validated
     * against the signer smart contract using ERC1271.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidERC1271SignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeCall(IERC1271.isValidSignature, (hash, signature))
        );
        return (success &&
            result.length >= 32 &&
            abi.decode(result, (bytes32)) == bytes32(IERC1271.isValidSignature.selector));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { Slice, Slice__, Slice__OutOfBounds } from "./Slice.sol";
import { StrChar, StrChar__ } from "./StrChar.sol";
import { StrCharsIter, StrCharsIter__ } from "./StrCharsIter.sol";
import { isValidUtf8 } from "./utils/utf8.sol";
import { memIsAscii } from "./utils/memascii.sol";
import { PackPtrLen } from "./utils/PackPtrLen.sol";

/**
 * @title A string slice.
 * @dev String slices must always be valid UTF-8.
 * Internally `StrSlice` uses `Slice`, adding only UTF-8 related logic on top.
 */
type StrSlice is uint256;

/*//////////////////////////////////////////////////////////////////////////
                                CUSTOM ERRORS
//////////////////////////////////////////////////////////////////////////*/

error StrSlice__InvalidCharBoundary();

/*//////////////////////////////////////////////////////////////////////////
                              STATIC FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

library StrSlice__ {
    /**
     * @dev Converts a `string` to a `StrSlice`.
     * The string is not copied.
     * `StrSlice` points to the memory of `string`, right after the length word.
     */
    function from(string memory str) internal pure returns (StrSlice slice) {
        uint256 _ptr;
        assembly {
            _ptr := add(str, 0x20)
        }
        return fromRawParts(_ptr, bytes(str).length);
    }

    /**
     * @dev Creates a new `StrSlice` directly from length and memory pointer.
     * Note that the caller MUST guarantee memory-safety.
     * This method is primarily for internal use.
     */
    function fromRawParts(uint256 _ptr, uint256 _len) internal pure returns (StrSlice slice) {
        return StrSlice.wrap(Slice.unwrap(
            Slice__.fromRawParts(_ptr, _len)
        ));
    }

    /**
     * @dev Returns true if the byte slice starts with a valid UTF-8 character.
     * Note this does not validate the whole slice.
     */
    function isBoundaryStart(Slice slice) internal pure returns (bool) {
        bytes32 b = slice.toBytes32();
        return isValidUtf8(b) != 0;
    }
}

/**
 * @dev Alternative to StrSlice__.from()
 * Put this in your file (using for global is only for user-defined types):
 * ```
 * using { toSlice } for string;
 * ```
 */
function toSlice(string memory str) pure returns (StrSlice slice) {
    return StrSlice__.from(str);
}

/*//////////////////////////////////////////////////////////////////////////
                              GLOBAL FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

using {
    asSlice,
    ptr, len, isEmpty,
    // conversion
    toString,
    keccak,
    // concatenation
    add, join,
    // compare
    cmp, eq, ne, lt, lte, gt, gte,
    // index
    isCharBoundary,
    get,
    splitAt, getSubslice,
    // search
    find, rfind, contains,
    startsWith, endsWith,
    // modify
    stripPrefix, stripSuffix,
    splitOnce, rsplitOnce,
    replacen,
    // iteration
    chars,
    // ascii
    isAscii
} for StrSlice global;

/**
 * @dev Returns the underlying `Slice`.
 * WARNING: manipulating `Slice`s can break UTF-8 for related `StrSlice`s!
 */
function asSlice(StrSlice self) pure returns (Slice) {
    return Slice.wrap(StrSlice.unwrap(self));
}

/**
 * @dev Returns the pointer to the start of an in-memory string slice.
 * This method is primarily for internal use.
 */
function ptr(StrSlice self) pure returns (uint256) {
    return StrSlice.unwrap(self) >> 128;
}

/**
 * @dev Returns the length in bytes, not codepoints.
 */
function len(StrSlice self) pure returns (uint256) {
    return StrSlice.unwrap(self) & PackPtrLen.MASK_LEN;
}

/**
 * @dev Returns true if the slice has a length of 0.
 */
function isEmpty(StrSlice self) pure returns (bool) {
    return StrSlice.unwrap(self) & PackPtrLen.MASK_LEN == 0;
}

/**
 * @dev Copies `StrSlice` to a newly allocated string.
 * The `StrSlice` will NOT point to the new string.
 */
function toString(StrSlice self) view returns (string memory) {
    return string(self.asSlice().toBytes());
}

/**
 * @dev Returns keccak256 of all the bytes of `StrSlice`.
 * Note that for any `string memory b`, keccak256(b) == b.toSlice().keccak()
 * (keccak256 does not include the length byte)
 */
function keccak(StrSlice self) pure returns (bytes32 result) {
    return self.asSlice().keccak();
}

/**
 * @dev Concatenates two `StrSlice`s into a newly allocated string.
 */
function add(StrSlice self, StrSlice other) view returns (string memory) {
    return string(self.asSlice().add(other.asSlice()));
}

/**
 * @dev Flattens an array of `StrSlice`s into a single newly allocated string,
 * placing `self` as the separator between each.
 */
function join(StrSlice self, StrSlice[] memory strs) view returns (string memory) {
    Slice[] memory slices;
    assembly {
        slices := strs
    }
    return string(self.asSlice().join(slices));
}

/**
 * @dev Compare string slices lexicographically.
 * @return result 0 for equal, < 0 for less than and > 0 for greater than.
 */
function cmp(StrSlice self, StrSlice other) pure returns (int256 result) {
    return self.asSlice().cmp(other.asSlice());
}

/// @dev `self` == `other`
/// Note more efficient than cmp
function eq(StrSlice self, StrSlice other) pure returns (bool) {
    return self.asSlice().eq(other.asSlice());
}

/// @dev `self` != `other`
/// Note more efficient than cmp
function ne(StrSlice self, StrSlice other) pure returns (bool) {
    return self.asSlice().ne(other.asSlice());
}

/// @dev `self` < `other`
function lt(StrSlice self, StrSlice other) pure returns (bool) {
    return self.cmp(other) < 0;
}

/// @dev `self` <= `other`
function lte(StrSlice self, StrSlice other) pure returns (bool) {
    return self.cmp(other) <= 0;
}

/// @dev `self` > `other`
function gt(StrSlice self, StrSlice other) pure returns (bool) {
    return self.cmp(other) > 0;
}

/// @dev `self` >= `other`
function gte(StrSlice self, StrSlice other) pure returns (bool) {
    return self.cmp(other) >= 0;
}

/**
 * @dev Checks that `index`-th byte is safe to split on.
 * The start and end of the string (when index == self.len()) are considered to be boundaries.
 * Returns false if index is greater than self.len().
 */
function isCharBoundary(StrSlice self, uint256 index) pure returns (bool) {
    if (index < self.len()) {
        return isValidUtf8(self.asSlice().getAfter(index).toBytes32()) != 0;
    } else if (index == self.len()) {
        return true;
    } else {
        return false;
    }
}

/**
 * @dev Returns the character at `index` (in bytes).
 * Reverts if index is out of bounds.
 */
function get(StrSlice self, uint256 index) pure returns (StrChar char) {
    bytes32 b = self.asSlice().getAfterStrict(index).toBytes32();
    uint256 charLen = isValidUtf8(b);
    if (charLen == 0) revert StrSlice__InvalidCharBoundary();
    return StrChar__.fromUnchecked(b, charLen);
}

/**
 * @dev Divides one string slice into two at an index.
 * Reverts when splitting on a non-boundary (use isCharBoundary).
 */
function splitAt(StrSlice self, uint256 mid) pure returns (StrSlice, StrSlice) {
    (Slice lSlice, Slice rSlice) = self.asSlice().splitAt(mid);
    if (!StrSlice__.isBoundaryStart(lSlice) || !StrSlice__.isBoundaryStart(rSlice)) {
        revert StrSlice__InvalidCharBoundary();
    }
    return (
        StrSlice.wrap(Slice.unwrap(lSlice)),
        StrSlice.wrap(Slice.unwrap(rSlice))
    );
}

/**
 * @dev Returns a subslice [start..end) of `self`.
 * Reverts when slicing a non-boundary (use isCharBoundary).
 */
function getSubslice(StrSlice self, uint256 start, uint256 end) pure returns (StrSlice) {
    Slice subslice = self.asSlice().getSubslice(start, end);
    if (!StrSlice__.isBoundaryStart(subslice)) revert StrSlice__InvalidCharBoundary();
    if (end != self.len()) {
        (, Slice nextSubslice) = self.asSlice().splitAt(end);
        if (!StrSlice__.isBoundaryStart(nextSubslice)) revert StrSlice__InvalidCharBoundary();
    }
    return StrSlice.wrap(Slice.unwrap(subslice));
}

/**
 * @dev Returns the byte index of the first slice of `self` that matches `pattern`.
 * Returns type(uint256).max if the `pattern` does not match.
 */
function find(StrSlice self, StrSlice pattern) pure returns (uint256) {
    return self.asSlice().find(pattern.asSlice());
}

/**
 * @dev Returns the byte index of the last slice of `self` that matches `pattern`.
 * Returns type(uint256).max if the `pattern` does not match.
 */
function rfind(StrSlice self, StrSlice pattern) pure returns (uint256) {
    return self.asSlice().rfind(pattern.asSlice());
}

/**
 * @dev Returns true if the given pattern matches a sub-slice of this string slice.
 */
function contains(StrSlice self, StrSlice pattern) pure returns (bool) {
    return self.asSlice().contains(pattern.asSlice());
}

/**
 * @dev Returns true if the given pattern matches a prefix of this string slice.
 */
function startsWith(StrSlice self, StrSlice pattern) pure returns (bool) {
    return self.asSlice().startsWith(pattern.asSlice());
}

/**
 * @dev Returns true if the given pattern matches a suffix of this string slice.
 */
function endsWith(StrSlice self, StrSlice pattern) pure returns (bool) {
    return self.asSlice().endsWith(pattern.asSlice());
}

/**
 * @dev Returns a subslice with the prefix removed.
 * If it does not start with `prefix`, returns `self` unmodified.
 */
function stripPrefix(StrSlice self, StrSlice pattern) pure returns (StrSlice result) {
    return StrSlice.wrap(Slice.unwrap(
        self.asSlice().stripPrefix(pattern.asSlice())
    ));
}

/**
 * @dev Returns a subslice with the suffix removed.
 * If it does not end with `suffix`, returns `self` unmodified.
 */
function stripSuffix(StrSlice self, StrSlice pattern) pure returns (StrSlice result) {
    return StrSlice.wrap(Slice.unwrap(
        self.asSlice().stripSuffix(pattern.asSlice())
    ));
}

/**
 * @dev Splits a slice into 2 on the first match of `pattern`.
 * If found == true, `prefix` and `suffix` will be strictly before and after the match.
 * If found == false, `prefix` will be the entire string and `suffix` will be empty.
 */
function splitOnce(StrSlice self, StrSlice pattern)
    pure
    returns (bool found, StrSlice prefix, StrSlice suffix)
{
    uint256 index = self.asSlice().find(pattern.asSlice());
    if (index == type(uint256).max) {
        // not found
        return (false, self, StrSlice.wrap(0));
    } else {
        // found
        return self._splitFound(index, pattern.len());
    }
}

/**
 * @dev Splits a slice into 2 on the last match of `pattern`.
 * If found == true, `prefix` and `suffix` will be strictly before and after the match.
 * If found == false, `prefix` will be empty and `suffix` will be the entire string.
 */
function rsplitOnce(StrSlice self, StrSlice pattern)
    pure
    returns (bool found, StrSlice prefix, StrSlice suffix)
{
    uint256 index = self.asSlice().rfind(pattern.asSlice());
    if (index == type(uint256).max) {
        // not found
        return (false, StrSlice.wrap(0), self);
    } else {
        // found
        return self._splitFound(index, pattern.len());
    }
}

/**
 * *EXPERIMENTAL*
 * @dev Replaces first `n` matches of a pattern with another string slice.
 * Returns the result in a newly allocated string.
 * Note this does not modify the string `self` is a slice of.
 * WARNING: Requires 0 < pattern.len() <= to.len()
 */
function replacen(
    StrSlice self,
    StrSlice pattern,
    StrSlice to,
    uint256 n
) view returns (string memory str) {
    uint256 patLen = pattern.len();
    uint256 toLen = to.len();
    // TODO dynamic string; atm length can be reduced but not increased
    assert(patLen >= toLen);
    assert(patLen > 0);

    str = new string(self.len());
    Slice iterSlice = self.asSlice();
    Slice resultSlice = Slice__.from(bytes(str));

    uint256 matchNum;
    while (matchNum < n) {
        uint256 index = iterSlice.find(pattern.asSlice());
        // break if no more matches
        if (index == type(uint256).max) break;
        // copy prefix
        if (index > 0) {
            resultSlice
                .getBefore(index)
                .copyFromSlice(
                    iterSlice.getBefore(index)
                );
        }

        uint256 indexToEnd;
        // TODO this is fine atm only because patLen <= toLen
        unchecked {
            indexToEnd = index + toLen;
        }

        // copy replacement
        resultSlice
            .getSubslice(index, indexToEnd)
            .copyFromSlice(to.asSlice());

        // advance slices past the match
        iterSlice = iterSlice.getAfter(index + patLen);
        resultSlice = resultSlice.getAfter(indexToEnd);

        // break if iterSlice is done
        if (iterSlice.len() == 0) {
            break;
        }
        // safe because of `while` condition
        unchecked {
            matchNum++;
        }
    }

    uint256 realLen = resultSlice.ptr() - StrSlice__.from(str).ptr();
    // copy suffix
    uint256 iterLen = iterSlice.len();
    if (iterLen > 0) {
        resultSlice
            .getBefore(iterLen)
            .copyFromSlice(iterSlice);
        realLen += iterLen;
    }
    // remove extra length
    if (bytes(str).length != realLen) {
        // TODO atm only accepting patLen <= toLen
        assert(realLen <= bytes(str).length);
        /// @solidity memory-safe-assembly
        assembly {
            mstore(str, realLen)
        }
    }
    return str;
}

/**
 * @dev Returns an character iterator over the slice.
 * The iterator yields items from either side.
 */
function chars(StrSlice self) pure returns (StrCharsIter memory) {
    return StrCharsIter(self.ptr(), self.len());
}

/**
 * @dev Checks if all characters are within the ASCII range.
 * 
 * Note this does NOT explicitly validate UTF-8.
 * Whereas ASCII certainly is valid UTF-8, non-ASCII *could* be invalid UTF-8.
 * Use `StrCharsIter` for explicit validation.
 */
function isAscii(StrSlice self) pure returns (bool) {
    return memIsAscii(self.ptr(), self.len());
}

/*//////////////////////////////////////////////////////////////////////////
                              FILE FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

using { _splitFound } for StrSlice;

/**
 * @dev Splits a slice into [:index] and [index+patLen:].
 * CALLER GUARANTEE: `index` < self.len()
 * For internal use by split/rsplit.
 *
 * This is mostly just a faster alternative to `getBefore`+`getAfter`.
 */
function _splitFound(StrSlice self, uint256 index, uint256 patLen)
    pure
    returns (bool, StrSlice prefix, StrSlice suffix)
{
    uint256 selfPtr = self.ptr();
    uint256 selfLen = self.len();
    uint256 indexAfterPat;
    // safe because caller guarantees index to be < selfLen
    unchecked {
        indexAfterPat = index + patLen;
        if (indexAfterPat > selfLen) revert Slice__OutOfBounds();
    }
    // [:index] (inlined `getBefore`)
    prefix = StrSlice.wrap(Slice.unwrap(
        Slice__.fromUnchecked(selfPtr, index)
    ));
    // [(index+patLen):] (inlined `getAfter`)
    // safe because indexAfterPat <= selfLen
    unchecked {
        suffix = StrSlice.wrap(Slice.unwrap(
            Slice__.fromUnchecked(selfPtr + indexAfterPat, selfLen - indexAfterPat)
        ));
    }
    return (true, prefix, suffix);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.20;

interface IERC7231 {

    error USERID_CANNOT_BE_EMPTY();
    error THE_FIRST_PART_DELIMITER_DOES_NOT_EXIST();
    error THE_SECOND_PART_DELIMITER_DOES_NOT_EXIST();
    error THE_FIRST_PART_DOES_NOT_EXIST();
    error THE_SECOND_PART_DOES_NOT_EXIST();
    error ID_HASH_LENGTH_IS_NOT_CORRECT();

    /**
     * @notice emit the use binding information
     * @param id nft id 
     * @param identitiesRoot new identity root
     */
    event SetIdentitiesRoot(
        uint256 id,
        bytes32 identitiesRoot
    );

    /**
     * @notice 
     * @dev set the user ID binding information of NFT with identitiesRoot
     * @param id nft id 
     * @param identitiesRoot multi UserID Root data hash
     * MUST allow external calls
     */
    function setIdentitiesRoot(
        uint256 id,
        bytes32 identitiesRoot
    ) external;

    /**
     * @notice 
     * @dev get the multi-userID root by  NFTID
     * @param id nft id 
     * MUST return the bytes32 multiUserIDsRoot
     * MUST NOT modify the state
     * MUST allow external calls
     */
    function getIdentitiesRoot(
        uint256 id
    ) external returns(bytes32);

    /**
     * @notice 
     * @dev verify the userIDs binding 
    * @param id nft id 
     * @param userIDs userIDs for check
     * @param identitiesRoot msg hash to verify
     * @param signature ECDSA signature 
     * MUST If the verification is passed, return true, otherwise return false
     * MUST NOT modify the state
     * MUST allow external calls
     */
    function verifyIdentitiesBinding(
        uint256 id,address nftOwnerAddress,string[] memory userIDs,bytes32 identitiesRoot, bytes calldata signature
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.20;

import {IERC165} from "../../utils/introspection/IERC165.sol";

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
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or
     *   {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
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
     * - The `operator` cannot be the address zero.
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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.20;

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
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be
     * reverted.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.20;

import {IERC721} from "../IERC721.sol";

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
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;
import {Initializable} from "../proxy/utils/Initializable.sol";

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/ERC165.sol)

pragma solidity ^0.8.20;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {Initializable} from "../../proxy/utils/Initializable.sol";

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
 */
abstract contract ERC165Upgradeable is Initializable, IERC165 {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/draft-IERC6093.sol)
pragma solidity ^0.8.20;

/**
 * @dev Standard ERC20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in EIP-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.20;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Storage of the initializable contract.
     *
     * It's implemented on a custom ERC-7201 namespace to reduce the risk of storage collisions
     * when using with upgradeable contracts.
     *
     * @custom:storage-location erc7201:openzeppelin.storage.Initializable
     */
    struct InitializableStorage {
        /**
         * @dev Indicates that the contract has been initialized.
         */
        uint64 _initialized;
        /**
         * @dev Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant INITIALIZABLE_STORAGE = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    /**
     * @dev The contract is already initialized.
     */
    error InvalidInitialization();

    /**
     * @dev The contract is not initializing.
     */
    error NotInitializing();

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint64 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that in the context of a constructor an `initializer` may be invoked any
     * number of times. This behavior in the constructor can be useful during testing and is not expected to be used in
     * production.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        // Cache values to avoid duplicated sloads
        bool isTopLevelCall = !$._initializing;
        uint64 initialized = $._initialized;

        // Allowed calls:
        // - initialSetup: the contract is not in the initializing state and no previous version was
        //                 initialized
        // - construction: the contract is initialized at version 1 (no reininitialization) and the
        //                 current contract is just being deployed
        bool initialSetup = initialized == 0 && isTopLevelCall;
        bool construction = initialized == 1 && address(this).code.length == 0;

        if (!initialSetup && !construction) {
            revert InvalidInitialization();
        }
        $._initialized = 1;
        if (isTopLevelCall) {
            $._initializing = true;
        }
        _;
        if (isTopLevelCall) {
            $._initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: Setting the version to 2**64 - 1 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint64 version) {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing || $._initialized >= version) {
            revert InvalidInitialization();
        }
        $._initialized = version;
        $._initializing = true;
        _;
        $._initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        _checkInitializing();
        _;
    }

    /**
     * @dev Reverts if the contract is not in an initializing state. See {onlyInitializing}.
     */
    function _checkInitializing() internal view virtual {
        if (!_isInitializing()) {
            revert NotInitializing();
        }
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing) {
            revert InvalidInitialization();
        }
        if ($._initialized != type(uint64).max) {
            $._initialized = type(uint64).max;
            emit Initialized(type(uint64).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint64) {
        return _getInitializableStorage()._initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _getInitializableStorage()._initializing;
    }

    /**
     * @dev Returns a pointer to the storage namespace.
     */
    // solhint-disable-next-line var-name-mixedcase
    function _getInitializableStorage() private pure returns (InitializableStorage storage $) {
        assembly {
            $.slot := INITIALIZABLE_STORAGE
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.20;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/ERC1967/ERC1967Utils.sol)

pragma solidity ^0.8.20;

import {IBeacon} from "../beacon/IBeacon.sol";
import {Address} from "../../utils/Address.sol";
import {StorageSlot} from "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 */
library ERC1967Utils {
    // We re-declare ERC-1967 events here because they can't be used directly from IERC1967.
    // This will be fixed in Solidity 0.8.21. At that point we should remove these events.
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1.
     */
    // solhint-disable-next-line private-vars-leading-underscore
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev The `implementation` of the proxy is invalid.
     */
    error ERC1967InvalidImplementation(address implementation);

    /**
     * @dev The `admin` of the proxy is invalid.
     */
    error ERC1967InvalidAdmin(address admin);

    /**
     * @dev The `beacon` of the proxy is invalid.
     */
    error ERC1967InvalidBeacon(address beacon);

    /**
     * @dev An upgrade function sees `msg.value > 0` that may be lost.
     */
    error ERC1967NonPayable();

    /**
     * @dev Returns the current implementation address.
     */
    function getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        if (newImplementation.code.length == 0) {
            revert ERC1967InvalidImplementation(newImplementation);
        }
        StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Performs implementation upgrade with additional setup call if data is nonempty.
     * This function is payable only if the setup call is performed, otherwise `msg.value` is rejected
     * to avoid stuck value in the contract.
     *
     * Emits an {IERC1967-Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);

        if (data.length > 0) {
            Address.functionDelegateCall(newImplementation, data);
        } else {
            _checkNonPayable();
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1.
     */
    // solhint-disable-next-line private-vars-leading-underscore
    bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Returns the current admin.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using
     * the https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        if (newAdmin == address(0)) {
            revert ERC1967InvalidAdmin(address(0));
        }
        StorageSlot.getAddressSlot(ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {IERC1967-AdminChanged} event.
     */
    function changeAdmin(address newAdmin) internal {
        emit AdminChanged(getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is the keccak-256 hash of "eip1967.proxy.beacon" subtracted by 1.
     */
    // solhint-disable-next-line private-vars-leading-underscore
    bytes32 internal constant BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Returns the current beacon.
     */
    function getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        if (newBeacon.code.length == 0) {
            revert ERC1967InvalidBeacon(newBeacon);
        }

        StorageSlot.getAddressSlot(BEACON_SLOT).value = newBeacon;

        address beaconImplementation = IBeacon(newBeacon).implementation();
        if (beaconImplementation.code.length == 0) {
            revert ERC1967InvalidImplementation(beaconImplementation);
        }
    }

    /**
     * @dev Change the beacon and trigger a setup call if data is nonempty.
     * This function is payable only if the setup call is performed, otherwise `msg.value` is rejected
     * to avoid stuck value in the contract.
     *
     * Emits an {IERC1967-BeaconUpgraded} event.
     *
     * CAUTION: Invoking this function has no effect on an instance of {BeaconProxy} since v5, since
     * it uses an immutable beacon without looking at the value of the ERC-1967 beacon slot for
     * efficiency.
     */
    function upgradeBeaconToAndCall(address newBeacon, bytes memory data) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);

        if (data.length > 0) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        } else {
            _checkNonPayable();
        }
    }

    /**
     * @dev Reverts if `msg.value` is not zero. It can be used to avoid `msg.value` stuck in the contract
     * if an upgrade doesn't perform an initialization call.
     */
    function _checkNonPayable() private {
        if (msg.value > 0) {
            revert ERC1967NonPayable();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/Math.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

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

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
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

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
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
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC1271.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
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

pragma solidity ^0.8.17;

import { mload8, memmove, memcmp, memeq, mstoreN, leftMask } from "./utils/mem.sol";
import { memchr, memrchr } from "./utils/memchr.sol";
import { PackPtrLen } from "./utils/PackPtrLen.sol";

import { SliceIter, SliceIter__ } from "./SliceIter.sol";

/**
 * @title A view into a contiguous sequence of 1-byte items.
 */
type Slice is uint256;

/*//////////////////////////////////////////////////////////////////////////
                                CUSTOM ERRORS
//////////////////////////////////////////////////////////////////////////*/

error Slice__OutOfBounds();
error Slice__LengthMismatch();

/*//////////////////////////////////////////////////////////////////////////
                              STATIC FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

library Slice__ {
    /**
     * @dev Converts a `bytes` to a `Slice`.
     * The bytes are not copied.
     * `Slice` points to the memory of `bytes`, right after the length word.
     */
    function from(bytes memory b) internal pure returns (Slice slice) {
        uint256 _ptr;
        assembly {
            _ptr := add(b, 0x20)
        }
        return fromRawParts(_ptr, b.length);
    }

    /**
     * @dev Creates a new `Slice` directly from length and memory pointer.
     * Note that the caller MUST guarantee memory-safety.
     * This method is primarily for internal use.
     */
    function fromRawParts(uint256 _ptr, uint256 _len) internal pure returns (Slice slice) {
        return Slice.wrap(PackPtrLen.pack(_ptr, _len));
    }

    /**
     * @dev Like `fromRawParts`, but does NO validity checks.
     * _ptr and _len MUST fit into uint128.
     * The caller MUST guarantee memory-safety.
     * Primarily for internal use.
     */
    function fromUnchecked(uint256 _ptr, uint256 _len) internal pure returns (Slice slice) {
        return Slice.wrap(
            (_ptr << 128) | (_len & PackPtrLen.MASK_LEN)
        );
    }
}

/**
 * @dev Alternative to Slice__.from()
 * Put this in your file (using for global is only for user-defined types):
 * ```
 * using { toSlice } for bytes;
 * ```
 */
function toSlice(bytes memory b) pure returns (Slice slice) {
    return Slice__.from(b);
}

/*//////////////////////////////////////////////////////////////////////////
                              GLOBAL FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

using {
    ptr, len, isEmpty,
    // conversion
    toBytes, toBytes32,
    keccak,
    // concatenation
    add, join,
    // copy
    copyFromSlice, copyFromValue, copyFromValueRightAligned,
    // compare
    cmp, eq, ne, lt, lte, gt, gte,
    // index
    get, first, last,
    splitAt, getSubslice, getBefore, getAfter, getAfterStrict,
    // search
    find, rfind, contains,
    startsWith, endsWith,
    // modify
    stripPrefix, stripSuffix,
    // iteration
    iter
} for Slice global;

/**
 * @dev Returns the pointer to the start of an in-memory slice.
 */
function ptr(Slice self) pure returns (uint256) {
    return Slice.unwrap(self) >> 128;
}

/**
 * @dev Returns the length in bytes.
 */
function len(Slice self) pure returns (uint256) {
    return Slice.unwrap(self) & PackPtrLen.MASK_LEN;
}

/**
 * @dev Returns true if the slice has a length of 0.
 */
function isEmpty(Slice self) pure returns (bool) {
    return Slice.unwrap(self) & PackPtrLen.MASK_LEN == 0;
}

/**
 * @dev Copies `Slice` to a new `bytes`.
 * The `Slice` will NOT point to the new `bytes`.
 */
function toBytes(Slice self) view returns (bytes memory b) {
    b = new bytes(self.len());
    uint256 bPtr;
    assembly {
        bPtr := add(b, 0x20)
    }

    memmove(bPtr, self.ptr(), self.len());
    return b;
}

/**
 * @dev Fills a `bytes32` (value type) with the first 32 bytes of `Slice`.
 * Goes from left(MSB) to right(LSB).
 * If len < 32, the leftover bytes are zeros.
 */
function toBytes32(Slice self) pure returns (bytes32 b) {
    uint256 selfPtr = self.ptr();

    // mask removes any trailing bytes
    uint256 selfLen = self.len();
    uint256 mask = leftMask(selfLen);

    /// @solidity memory-safe-assembly
    assembly {
        b := and(mload(selfPtr), mask)
    }
    return b;
}

/**
 * @dev Returns keccak256 of all the bytes of `Slice`.
 * Note that for any `bytes memory b`, keccak256(b) == b.toSlice().keccak()
 * (keccak256 does not include the length byte)
 */
function keccak(Slice self) pure returns (bytes32 result) {
    uint256 selfPtr = self.ptr();
    uint256 selfLen = self.len();
    /// @solidity memory-safe-assembly
    assembly {
        result := keccak256(selfPtr, selfLen)
    }
}

/**
 * @dev Concatenates two `Slice`s into a newly allocated `bytes`.
 */
function add(Slice self, Slice other) view returns (bytes memory b) {
    uint256 selfLen = self.len();
    uint256 otherLen = other.len();

    b = new bytes(selfLen + otherLen);
    uint256 bPtr;
    assembly {
        bPtr := add(b, 0x20)
    }

    memmove(bPtr, self.ptr(), selfLen);
    memmove(bPtr + selfLen, other.ptr(), otherLen);
    return b;
}

/**
 * @dev Flattens an array of `Slice`s into a single newly allocated `bytes`,
 * placing `self` as the separator between each.
 *
 * TODO this is the wrong place for this method, but there are no other places atm
 * (since there's no proper chaining/reducers/anything)
 */
function join(Slice self, Slice[] memory slices) view returns (bytes memory b) {
    uint256 slicesLen = slices.length;
    if (slicesLen == 0) return "";

    uint256 selfLen = self.len();
    uint256 repetitionLen;
    // -1 is safe because of ==0 check earlier
    unchecked {
        repetitionLen = slicesLen - 1;
    }
    // add separator repetitions length
    uint256 totalLen = selfLen * repetitionLen;
    // add slices length
    for (uint256 i; i < slicesLen; i++) {
        totalLen += slices[i].len();
    }

    b = new bytes(totalLen);
    uint256 bPtr;
    assembly {
        bPtr := add(b, 0x20)
    }
    for (uint256 i; i < slicesLen; i++) {
        Slice slice = slices[i];
        // copy slice
        memmove(bPtr, slice.ptr(), slice.len());
        bPtr += slice.len();
        // copy separator (skips the last cycle)
        if (i < repetitionLen) {
            memmove(bPtr, self.ptr(), selfLen);
            bPtr += selfLen;
        }
    }
}

/**
 * @dev Copies all elements from `src` into `self`.
 * The length of `src` must be the same as `self`.
 */
function copyFromSlice(Slice self, Slice src) view {
    uint256 selfLen = self.len();
    if (selfLen != src.len()) revert Slice__LengthMismatch();

    memmove(self.ptr(), src.ptr(), selfLen);
}

/**
 * @dev Copies `length` bytes from `value` into `self`, starting from MSB.
 */
function copyFromValue(Slice self, bytes32 value, uint256 length) pure {
    if (length > self.len() || length > 32) {
        revert Slice__OutOfBounds();
    }

    mstoreN(self.ptr(), value, length);
}

/**
 * @dev Shifts `value` to MSB by (32 - `length`),
 * then copies `length` bytes from `value` into `self`, starting from MSB.
 * (this is for right-aligned values like uint32, so you don't have to shift them to MSB yourself)
 */
function copyFromValueRightAligned(Slice self, bytes32 value, uint256 length) pure {
    if (length > self.len() || length > 32) {
        revert Slice__OutOfBounds();
    }
    if (length < 32) {
        // safe because length < 32
        unchecked {
            value <<= (32 - length) * 8;
        }
    }

    mstoreN(self.ptr(), value, length);
}

/**
 * @dev Compare slices lexicographically.
 * @return result 0 for equal, < 0 for less than and > 0 for greater than.
 */
function cmp(Slice self, Slice other) pure returns (int256 result) {
    uint256 selfLen = self.len();
    uint256 otherLen = other.len();
    uint256 minLen = selfLen;
    if (otherLen < minLen) {
        minLen = otherLen;
    }

    result = memcmp(self.ptr(), other.ptr(), minLen);
    if (result == 0) {
        // the longer slice is greater than its prefix
        // (lengths take only 16 bytes, so signed sub is safe)
        unchecked {
            return int256(selfLen) - int256(otherLen);
        }
    }
    // if not equal, return the diff sign
    return result;
}

/// @dev self == other
/// Note more efficient than cmp
function eq(Slice self, Slice other) pure returns (bool) {
    uint256 selfLen = self.len();
    if (selfLen != other.len()) return false;
    return memeq(self.ptr(), other.ptr(), selfLen);
}

/// @dev self != other
/// Note more efficient than cmp
function ne(Slice self, Slice other) pure returns (bool) {
    uint256 selfLen = self.len();
    if (selfLen != other.len()) return true;
    return !memeq(self.ptr(), other.ptr(), selfLen);
}

/// @dev `self` < `other`
function lt(Slice self, Slice other) pure returns (bool) {
    return self.cmp(other) < 0;
}

/// @dev `self` <= `other`
function lte(Slice self, Slice other) pure returns (bool) {
    return self.cmp(other) <= 0;
}

/// @dev `self` > `other`
function gt(Slice self, Slice other) pure returns (bool) {
    return self.cmp(other) > 0;
}

/// @dev `self` >= `other`
function gte(Slice self, Slice other) pure returns (bool) {
    return self.cmp(other) >= 0;
}

/**
 * @dev Returns the byte at `index`.
 * Reverts if index is out of bounds.
 */
function get(Slice self, uint256 index) pure returns (uint8 item) {
    if (index >= self.len()) revert Slice__OutOfBounds();

    // ptr and len are uint128 (because PackPtrLen); index < len
    unchecked {
        return mload8(self.ptr() + index);
    }
}

/**
 * @dev Returns the first byte of the slice.
 * Reverts if the slice is empty.
 */
function first(Slice self) pure returns (uint8 item) {
    if (self.len() == 0) revert Slice__OutOfBounds();
    return mload8(self.ptr());
}

/**
 * @dev Returns the last byte of the slice.
 * Reverts if the slice is empty.
 */
function last(Slice self) pure returns (uint8 item) {
    uint256 selfLen = self.len();
    if (selfLen == 0) revert Slice__OutOfBounds();
    // safe because selfLen > 0 (ptr+len is implicitly safe)
    unchecked {
        return mload8(self.ptr() + (selfLen - 1));
    }
}

/**
 * @dev Divides one slice into two at an index.
 */
function splitAt(Slice self, uint256 mid) pure returns (Slice, Slice) {
    uint256 selfPtr = self.ptr();
    uint256 selfLen = self.len();
    if (mid > selfLen) revert Slice__OutOfBounds();
    return (Slice__.fromUnchecked(selfPtr, mid), Slice__.fromUnchecked(selfPtr + mid, selfLen - mid));
}

/**
 * @dev Returns a subslice [start:end] of `self`.
 * Reverts if start/end are out of bounds.
 */
function getSubslice(Slice self, uint256 start, uint256 end) pure returns (Slice) {
    if (!(start <= end && end <= self.len())) revert Slice__OutOfBounds();
    // selfPtr + start is safe because start <= selfLen (pointers are implicitly safe)
    // end - start is safe because start <= end
    unchecked {
        return Slice__.fromUnchecked(self.ptr() + start, end - start);
    }
}

/**
 * @dev Returns a subslice [:index] of `self`.
 * Reverts if `index` > length.
 */
function getBefore(Slice self, uint256 index) pure returns (Slice) {
    uint256 selfLen = self.len();
    if (index > selfLen) revert Slice__OutOfBounds();
    return Slice__.fromUnchecked(self.ptr(), index);
}

/**
 * @dev Returns a subslice [index:] of `self`.
 * Reverts if `index` > length.
 */
function getAfter(Slice self, uint256 index) pure returns (Slice) {
    uint256 selfLen = self.len();
    if (index > selfLen) revert Slice__OutOfBounds();
    // safe because index <= selfLen (ptr+len is implicitly safe)
    unchecked {
        return Slice__.fromUnchecked(self.ptr() + index, selfLen - index);
    }
}

/**
 * @dev Returns a non-zero subslice [index:] of `self`.
 * Reverts if `index` >= length.
 */
function getAfterStrict(Slice self, uint256 index) pure returns (Slice) {
    uint256 selfLen = self.len();
    if (index >= selfLen) revert Slice__OutOfBounds();
    // safe because index < selfLen (ptr+len is implicitly safe)
    unchecked {
        return Slice__.fromUnchecked(self.ptr() + index, selfLen - index);
    }
}

/**
 * @dev Returns the byte index of the first slice of `self` that matches `pattern`.
 * Returns type(uint256).max if the `pattern` does not match.
 */
function find(Slice self, Slice pattern) pure returns (uint256) {
    // offsetLen == selfLen initially, then starts shrinking
    uint256 offsetLen = self.len();
    uint256 patLen = pattern.len();
    if (patLen == 0) {
        return 0;
    } else if (offsetLen == 0 || patLen > offsetLen) {
        return type(uint256).max;
    }

    uint256 offsetPtr = self.ptr();
    uint256 patPtr = pattern.ptr();
    // low-level alternative to `first()` (safe because patLen != 0)
    uint8 patFirst = mload8(patPtr);

    while (true) {
        uint256 index = memchr(offsetPtr, offsetLen, patFirst);
        // not found
        if (index == type(uint256).max) return type(uint256).max;

        // move pointer to the found byte
        // safe because index < offsetLen (ptr+len is implicitly safe)
        unchecked {
            offsetPtr += index;
            offsetLen -= index;
        }
        // can't find, pattern won't fit after index
        if (patLen > offsetLen) {
            return type(uint256).max;
        }

        if (memeq(offsetPtr, patPtr, patLen)) {
            // found, return offset index
            return (offsetPtr - self.ptr());
        } else if (offsetLen == 1) {
            // not found and this was the last character
            return type(uint256).max;
        } else {
            // not found and can keep going;
            // increment pointer, memchr shouldn't receive what it returned (otherwise infinite loop)
            unchecked {
                // safe because offsetLen > 1 (see offsetLen -= index, and index < offsetLen)
                offsetPtr++;
                offsetLen--;
            }
        }
    }
    return type(uint256).max;
}

/**
 * @dev Returns the byte index of the last slice of `self` that matches `pattern`.
 * Returns type(uint256).max if the `pattern` does not match.
 */
function rfind(Slice self, Slice pattern) pure returns (uint256) {
    // offsetLen == selfLen initially, then starts shrinking
    uint256 offsetLen = self.len();
    uint256 patLen = pattern.len();
    if (patLen == 0) {
        return 0;
    } else if (offsetLen == 0 || patLen > offsetLen) {
        return type(uint256).max;
    }

    uint256 selfPtr = self.ptr();
    uint256 patPtr = pattern.ptr();
    uint8 patLast = pattern.last();
    // using indexes instead of lengths saves some gas on redundant increments/decrements
    uint256 patLastIndex;
    // safe because of patLen == 0 check earlier
    unchecked {
        patLastIndex = patLen - 1;
    }

    while (true) {
        uint256 endIndex = memrchr(selfPtr, offsetLen, patLast);
        // not found
        if (endIndex == type(uint256).max) return type(uint256).max;
        // can't find, pattern won't fit after index
        if (patLastIndex > endIndex) return type(uint256).max;

        // (endIndex - patLastIndex is safe because of the check just earlier)
        // (selfPtr + startIndex is safe because startIndex <= endIndex < offsetLen <= selfLen)
        // (ptr+len is implicitly safe)
        unchecked {
            // need startIndex, but memrchr returns endIndex
            uint256 startIndex = endIndex - patLastIndex;

            if (memeq(selfPtr + startIndex, patPtr, patLen)) {
                // found, return index
                return startIndex;
            } else if (endIndex > 0) {
                // not found and can keep going;
                // "decrement pointer", memrchr shouldn't receive what it returned
                // (index is basically a decremented length already, saves an op)
                // (I could even use 1 variable for both, but that'd be too confusing)
                offsetLen = endIndex;
                // an explicit continue is better for optimization here
                continue;
            } else {
                // not found and this was the last character
                return type(uint256).max;
            }
        }
    }
    return type(uint256).max;
}

/**
 * @dev Returns true if the given pattern matches a sub-slice of this `bytes` slice.
 */
function contains(Slice self, Slice pattern) pure returns (bool) {
    return self.find(pattern) != type(uint256).max;
}

/**
 * @dev Returns true if the given pattern matches a prefix of this slice.
 */
function startsWith(Slice self, Slice pattern) pure returns (bool) {
    uint256 selfLen = self.len();
    uint256 patLen = pattern.len();
    if (selfLen < patLen) return false;

    Slice prefix = self;
    // make prefix's length equal patLen
    if (selfLen > patLen) {
        prefix = self.getBefore(patLen);
    }
    return prefix.eq(pattern);
}

/**
 * @dev Returns true if the given pattern matches a suffix of this slice.
 */
function endsWith(Slice self, Slice pattern) pure returns (bool) {
    uint256 selfLen = self.len();
    uint256 patLen = pattern.len();
    if (selfLen < patLen) return false;

    Slice suffix = self;
    // make suffix's length equal patLen
    if (selfLen > patLen) {
        suffix = self.getAfter(selfLen - patLen);
    }
    return suffix.eq(pattern);
}

/**
 * @dev Returns a subslice with the prefix removed.
 * If it does not start with `prefix`, returns `self` unmodified.
 */
function stripPrefix(Slice self, Slice pattern) pure returns (Slice) {
    uint256 selfLen = self.len();
    uint256 patLen = pattern.len();
    if (patLen > selfLen) return self;

    (Slice prefix, Slice suffix) = self.splitAt(patLen);

    if (prefix.eq(pattern)) {
        return suffix;
    } else {
        return self;
    }
}

/**
 * @dev Returns a subslice with the suffix removed.
 * If it does not end with `suffix`, returns `self` unmodified.
 */
function stripSuffix(Slice self, Slice pattern) pure returns (Slice) {
    uint256 selfLen = self.len();
    uint256 patLen = pattern.len();
    if (patLen > selfLen) return self;

    uint256 index;
    // safe because selfLen >= patLen
    unchecked {
        index = selfLen - patLen;
    }
    (Slice prefix, Slice suffix) = self.splitAt(index);

    if (suffix.eq(pattern)) {
        return prefix;
    } else {
        return self;
    }
}

/**
 * @dev Returns an iterator over the slice.
 * The iterator yields items from either side.
 */
function iter(Slice self) pure returns (SliceIter memory) {
    return SliceIter__.from(self);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { isValidUtf8 as _isValidUtf8, utf8CharWidth } from "./utils/utf8.sol";
import { decodeUtf8, encodeUtf8 } from "./utils/unicode.sol";
import { leftMask } from "./utils/mem.sol";

/**
 * @title A single UTF-8 encoded character.
 * @dev Internally it is stored as UTF-8 encoded bytes starting from left/MSB.
 */
type StrChar is bytes32;

/*//////////////////////////////////////////////////////////////////////////
                                CUSTOM ERRORS
//////////////////////////////////////////////////////////////////////////*/

error StrChar__InvalidUTF8();

/*//////////////////////////////////////////////////////////////////////////
                              STATIC FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

library StrChar__ {
    /**
     * @dev Converts the first 1-4 bytes of `bytes32` to a `StrChar`.
     * Starts from left/MSB, reverts if not valid UTF-8.
     * @param b UTF-8 encoded character in the most significant bytes.
     */
    function from(bytes32 b) internal pure returns (StrChar char) {
        uint256 charLen = _isValidUtf8(b);
        if (charLen == 0) revert StrChar__InvalidUTF8();
        return fromUnchecked(b, charLen);
    }

    /**
    * @dev Converts a unicode code point to a `StrChar`.
    * E.g. for '€' code point = 0x20AC; wheareas UTF-8 = 0xE282AC.
    */
    function fromCodePoint(uint256 code) internal pure returns (StrChar char) {
        return StrChar.wrap(encodeUtf8(code));
    }

    /**
     * @dev Like `from`, but does NO validity checks.
     * Uses provided `_len` instead of calculating it. This allows invalid/malformed characters.
     *
     * MSB of `bytes32` SHOULD be valid UTF-8.
     * And `bytes32` SHOULD be zero-padded after the first UTF-8 character.
     * Primarily for internal use.
     */
    function fromUnchecked(bytes32 b, uint256 _len) internal pure returns (StrChar char) {
        return StrChar.wrap(bytes32(
            // zero-pad after the character
            uint256(b) & leftMask(_len)
        ));
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                GLOBAL FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

using { 
    len,
    toBytes32, toString, toCodePoint,
    cmp, eq, ne, lt, lte, gt, gte,
    isValidUtf8,
    isAscii
} for StrChar global;

/**
 * @dev Returns the character's length in bytes (1-4).
 * Returns 0 for some (not all!) invalid characters (e.g. due to unsafe use of fromUnchecked).
 */
function len(StrChar self) pure returns (uint256) {
    return utf8CharWidth(
        // extract the leading byte
        uint256(uint8(StrChar.unwrap(self)[0]))
    );
}

/**
 * @dev Converts a `StrChar` to its underlying bytes32 value.
 */
function toBytes32(StrChar self) pure returns (bytes32) {
    return StrChar.unwrap(self);
}

/**
 * @dev Converts a `StrChar` to a newly allocated `string`.
 */
function toString(StrChar self) pure returns (string memory str) {
    uint256 _len = self.len();
    str = new string(_len);
    /// @solidity memory-safe-assembly
    assembly {
        mstore(add(str, 0x20), self)
    }
    return str;
}

/**
 * @dev Converts a `StrChar` to its unicode code point (aka unicode scalar value).
 */
function toCodePoint(StrChar self) pure returns (uint256) {
    return decodeUtf8(StrChar.unwrap(self));
}

/**
 * @dev Compare characters lexicographically.
 * @return result 0 for equal, < 0 for less than and > 0 for greater than.
 */
function cmp(StrChar self, StrChar other) pure returns (int256 result) {
    uint256 selfUint = uint256(StrChar.unwrap(self));
    uint256 otherUint = uint256(StrChar.unwrap(other));
    if (selfUint > otherUint) {
        return 1;
    } else if (selfUint < otherUint) {
        return -1;
    } else {
        return 0;
    }
}

/// @dev `self` == `other`
function eq(StrChar self, StrChar other) pure returns (bool) {
    return uint256(StrChar.unwrap(self)) == uint256(StrChar.unwrap(other));
}

/// @dev `self` != `other`
function ne(StrChar self, StrChar other) pure returns (bool) {
    return uint256(StrChar.unwrap(self)) != uint256(StrChar.unwrap(other));
}

/// @dev `self` < `other`
function lt(StrChar self, StrChar other) pure returns (bool) {
    return uint256(StrChar.unwrap(self)) < uint256(StrChar.unwrap(other));
}

/// @dev `self` <= `other`
function lte(StrChar self, StrChar other) pure returns (bool) {
    return uint256(StrChar.unwrap(self)) <= uint256(StrChar.unwrap(other));
}

/// @dev `self` > `other`
function gt(StrChar self, StrChar other) pure returns (bool) {
    return uint256(StrChar.unwrap(self)) > uint256(StrChar.unwrap(other));
}

/// @dev `self` >= `other`
function gte(StrChar self, StrChar other) pure returns (bool) {
    return uint256(StrChar.unwrap(self)) >= uint256(StrChar.unwrap(other));
}

/**
 * @dev Returns true if `StrChar` is valid UTF-8.
 * Can be false if it was formed with an unsafe method (fromUnchecked, wrap).
 */
function isValidUtf8(StrChar self) pure returns (bool) {
    return _isValidUtf8(StrChar.unwrap(self)) != 0;
}

/**
 * @dev Returns true if `StrChar` is within the ASCII range.
 */
function isAscii(StrChar self) pure returns (bool) {
    return StrChar.unwrap(self)[0] < 0x80;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { Slice, Slice__ } from "./Slice.sol";
import { StrSlice } from "./StrSlice.sol";
import { SliceIter, SliceIter__, SliceIter__StopIteration } from "./SliceIter.sol";
import { StrChar, StrChar__, StrChar__InvalidUTF8 } from "./StrChar.sol";
import { isValidUtf8, utf8CharWidth } from "./utils/utf8.sol";
import { leftMask } from "./utils/mem.sol";

/**
 * @title String chars iterator.
 * @dev This struct is created by the iter method on `StrSlice`.
 * Iterates 1 UTF-8 encoded character at a time (which may have 1-4 bytes).
 *
 * Note StrCharsIter iterates over UTF-8 encoded codepoints, not unicode scalar values.
 * This is mostly done for simplicity, since solidity doesn't care about unicode anyways.
 *
 * TODO think about actually adding char and unicode awareness?
 * https://github.com/devstein/unicode-eth attempts something like that
 */
struct StrCharsIter {
    uint256 _ptr;
    uint256 _len;
}

/*//////////////////////////////////////////////////////////////////////////
                                STATIC FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

library StrCharsIter__ {
    /**
     * @dev Creates a new `StrCharsIter` from `StrSlice`.
     * Note the `StrSlice` is assumed to be memory-safe.
     */
    function from(StrSlice slice) internal pure returns (StrCharsIter memory) {
        return StrCharsIter(slice.ptr(), slice.len());

        // TODO I'm curious about gas differences
        // return StrCharsIter(SliceIter__.from(str.asSlice()));
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                GLOBAL FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

using {
    asStr,
    ptr, len, isEmpty,
    next, nextBack, unsafeNext,
    count, validateUtf8, unsafeCount
} for StrCharsIter global;

/**
 * @dev Views the underlying data as a subslice of the original data.
 */
function asStr(StrCharsIter memory self) pure returns (StrSlice slice) {
    return StrSlice.wrap(Slice.unwrap(
        self.asSlice()
    ));
}

/**
 * @dev Returns the pointer to the start of an in-memory string slice.
 * This method is primarily for internal use.
 */
function ptr(StrCharsIter memory self) pure returns (uint256) {
    return self._ptr;
}

/**
 * @dev Returns the length in bytes, not codepoints.
 */
function len(StrCharsIter memory self) pure returns (uint256) {
    return self._len;
}

/**
 * @dev Returns true if the iterator is empty.
 */
function isEmpty(StrCharsIter memory self) pure returns (bool) {
    return self._len == 0;
}

/**
 * @dev Advances the iterator and returns the next character.
 * Reverts if len == 0.
 * Reverts on invalid UTF-8.
 */
function next(StrCharsIter memory self) pure returns (StrChar) {
    if (self._len == 0) revert SliceIter__StopIteration();
    (bytes32 b, uint256 charLen) = self._nextRaw(true);
    // safe because _nextRaw guarantees charLen <= selfLen as long as selfLen != 0.
    unchecked {
        // charLen > 0 because of `revertOnInvalid` flag
        self._len -= charLen;
    }
    // safe because _nextRaw reverts on invalid UTF-8
    return StrChar__.fromUnchecked(b, charLen);
}

/**
 * @dev Advances the iterator from the back and returns the next character.
 * Reverts if len == 0.
 * Reverts on invalid UTF-8.
 */
function nextBack(StrCharsIter memory self) pure returns (StrChar char) {
    if (self._len == 0) revert SliceIter__StopIteration();

    // _self shares memory with self!
    SliceIter memory _self = self._sliceIter();

    bool isValid;
    uint256 b;
    for (uint256 i; i < 4; i++) {
        // an example of what's going on in the loop:
        // b = 0x0000000000..00
        // nextBack = 0x80
        // b = 0x8000000000..00 (not valid UTF-8)
        // nextBack = 0x92
        // b = 0x9280000000..00 (not valid UTF-8)
        // nextBack = 0x9F
        // b = 0x9F92800000..00 (not valid UTF-8)
        // nextBack = 0xF0
        // b = 0xF09F928000..00 (valid UTF-8, break)

        // safe because i < 4
        unchecked {
            // free the space in MSB
            b = (b >> 8) | (
                // get 1 byte in LSB
                uint256(_self.nextBack())
                // flip it to MSB
                << (31 * 8)
            );
        }
        // break if the char is valid
        if (isValidUtf8(bytes32(b)) != 0) {
            isValid = true;
            break;
        }
    }
    if (!isValid) revert StrChar__InvalidUTF8();

    // construct the character;
    // wrap is safe, because UTF-8 was validated,
    // and the trailing bytes are 0 (since the loop went byte-by-byte)
    char = StrChar.wrap(bytes32(b));
    // the iterator was already advanced by `_self.nextBack()`
    return char;
}

/**
 * @dev Advances the iterator and returns the next character.
 * Does NOT validate iterator length. It could underflow!
 * Does NOT revert on invalid UTF-8.
 * WARNING: for invalid UTF-8 bytes, advances by 1 and returns an invalid `StrChar` with len 0!
 */
function unsafeNext(StrCharsIter memory self) pure returns (StrChar char) {
    // _nextRaw guarantees charLen <= selfLen IF selfLen != 0
    (bytes32 b, uint256 charLen) = self._nextRaw(false);
    if (charLen > 0) {
        // safe IF the caller ensures that self._len != 0
        unchecked {
            self._len -= charLen;
        }
        // ALWAYS produces a valid character
        return StrChar__.fromUnchecked(b, charLen);
    } else {
        // safe IF the caller ensures that self._len != 0
        unchecked {
            self._len -= 1;
        }
        // NEVER produces a valid character (this is always a single 0x80-0xFF byte)
        return StrChar__.fromUnchecked(b, 1);
    }
}

/**
 * @dev Consumes the iterator, counting the number of UTF-8 characters.
 * Note O(n) time!
 * Reverts on invalid UTF-8.
 */
function count(StrCharsIter memory self) pure returns (uint256 result) {
    uint256 endPtr;
    // (ptr+len is implicitly safe)
    unchecked {
        endPtr = self._ptr + self._len;
    }
    while (self._ptr < endPtr) {
        self._nextRaw(true);
        // +1 is safe because 2**256 cycles are impossible
        unchecked {
            result += 1;
        }
    }
    // _nextRaw does NOT modify len to allow optimizations like setting it once at the end
    self._len = 0;
    return result;
}

/**
 * @dev Consumes the iterator, validating UTF-8 characters.
 * Note O(n) time!
 * Returns true if all are valid; otherwise false on the first invalid UTF-8 character.
 */
function validateUtf8(StrCharsIter memory self) pure returns (bool) {
    uint256 endPtr;
    // (ptr+len is implicitly safe)
    unchecked {
        endPtr = self._ptr + self._len;
    }
    while (self._ptr < endPtr) {
        (, uint256 charLen) = self._nextRaw(false);
        if (charLen == 0) return false;
    }
    return true;
}

/**
 * @dev VERY UNSAFE - a single invalid UTF-8 character can severely alter the result!
 * Consumes the iterator, counting the number of UTF-8 characters.
 * Significantly faster than safe `count`, especially for long mutlibyte strings.
 *
 * Note `count` is actually a bit more efficient than `validateUtf8`.
 * `count` is much more efficient than calling `validateUtf8` and `unsafeCount` together.
 * Use `unsafeCount` only when you are already certain that UTF-8 is valid.
 * If you want speed and no validation, just use byte length, it's faster and more predictably wrong.
 *
 * Some gas usage metrics:
 * 1 ascii char:
 *   count:       571 gas
 *   unsafeCount: 423 gas
 * 100 ascii chars:
 *   count:       27406 gas
 *   unsafeCount: 12900 gas
 * 1000 chinese chars (3000 bytes):
 *   count:       799305 gas
 *   unsafeCount: 178301 gas
 */
function unsafeCount(StrCharsIter memory self) pure returns (uint256 result) {
    uint256 endPtr;
    // (ptr+len is implicitly safe)
    unchecked {
        endPtr = self._ptr + self._len;
    }
    while (self._ptr < endPtr) {
        uint256 leadingByte;
        // unchecked mload
        // (unsafe, the last character could move the pointer past the boundary, but only once)
        /// @solidity memory-safe-assembly
        assembly {
            leadingByte := byte(0, mload(
                // load self._ptr (this is an optimization trick, since it's 1st in the struct)
                mload(self)
            ))
        }
        unchecked {
            // this is a very unsafe version of `utf8CharWidth`,
            // basically 1 invalid UTF-8 character can severely change the count result
            // (no real infinite loop risks, only one potential corrupt memory read)
            if (leadingByte < 0x80) {
                self._ptr += 1;
            } else if (leadingByte < 0xE0) {
                self._ptr += 2;
            } else if (leadingByte < 0xF0) {
                self._ptr += 3;
            } else {
                self._ptr += 4;
            }
            // +1 is safe because 2**256 cycles are impossible
            result += 1;
        }
    }
    self._len = 0;

    return result;
}

/*//////////////////////////////////////////////////////////////////////////
                            FILE-LEVEL FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

using { asSlice, _nextRaw, _sliceIter } for StrCharsIter;

/**
 * @dev Views the underlying data as a `bytes` subslice of the original data.
 */
function asSlice(StrCharsIter memory self) pure returns (Slice slice) {
    return Slice__.fromUnchecked(self._ptr, self._len);
}

/**
 * @dev Used internally to efficiently reuse iteration logic. Has a lot of caveats.
 * NEITHER checks NOR modifies iterator length.
 * (Caller MUST guarantee that len != 0. Caller MUST modify len correctly themselves.)
 * Does NOT form the character properly, and returns raw unmasked bytes and length.
 * Does advance the iterator pointer.
 *
 * Validates UTF-8.
 * For valid chars advances the pointer by charLen.
 * For invalid chars behaviour depends on `revertOnInvalid`:
 * revertOnInvalid == true: revert.
 * revertOnInvalid == false: advance the pointer by 1, but return charLen 0.
 *
 * @return b raw unmasked bytes; if not discarded, then charLen SHOULD be used to mask it.
 * @return charLen length of a valid UTF-8 char; 0 for invalid chars.
 * Guarantees that charLen <= self._len (as long as self._len != 0, which is the caller's guarantee)
 */
function _nextRaw(StrCharsIter memory self, bool revertOnInvalid)
    pure
    returns (bytes32 b, uint256 charLen)
{
    // unchecked mload
    // (isValidUtf8 only checks the 1st character, which exists since caller guarantees len != 0)
    /// @solidity memory-safe-assembly
    assembly {
        b := mload(
            // load self._ptr (this is an optimization trick, since it's 1st in the struct)
            mload(self)
        )
    }
    // validate character (0 => invalid; 1-4 => valid)
    charLen = isValidUtf8(b);

    if (charLen > self._len) {
        // mload didn't check bounds,
        // so a character that goes out of bounds could've been seen as valid.
        if (revertOnInvalid) revert StrChar__InvalidUTF8();
        // safe because caller guarantees _len != 0
        unchecked {
            self._ptr += 1;
        }
        // invalid
        return (b, 0);
    } else if (charLen == 0) {
        if (revertOnInvalid) revert StrChar__InvalidUTF8();
        // safe because caller guarantees _len != 0
        unchecked {
            self._ptr += 1;
        }
        // invalid
        return (b, 0);
    } else {
        // safe because of the `charLen > self._len` check earlier
        unchecked {
            self._ptr += charLen;
        }
        // valid
        return (b, charLen);
    }
}

/**
 * @dev Returns the underlying `SliceIter`.
 * AVOID USING THIS EXTERNALLY!
 * Advancing the underlying slice could lead to invalid UTF-8 for StrCharsIter.
 */
function _sliceIter(StrCharsIter memory self) pure returns (SliceIter memory result) {
    assembly {
        result := self
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**
 * @dev Returns the byte length for a UTF-8 character with the leading byte.
 * Returns 0 for invalid leading bytes.
 */
function utf8CharWidth(uint256 leadingByte) pure returns (uint256) {
    if (leadingByte < 0x80) {
        return 1;
    } else if (leadingByte < 0xC2) {
        return 0;
    } else if (leadingByte < 0xE0) {
        return 2;
    } else if (leadingByte < 0xF0) {
        return 3;
    } else if (leadingByte < 0xF5) {
        return 4;
    } else {
        return 0;
    }
}

/**
 * @dev Returns true if `b` is a valid UTF-8 leading byte.
 */
function isLeadingByte(uint256 b) pure returns (bool) {
    return utf8CharWidth(b) > 0;
}

/**
 * @dev Returns character length if the 1-4 bytes at MSB are a valid UTF-8 encoded character.
 * Returns 0 for invalid characters.
 * (utf8CharWidth validates ONLY the leading byte, not the whole character)
 *
 * Note if MSB is 0x00, this will return 1, since 0x00 is valid UTF-8.
 * Works faster for smaller code points.
 *
 * https://www.rfc-editor.org/rfc/rfc3629#section-4
 * UTF8-char   = UTF8-1 / UTF8-2 / UTF8-3 / UTF8-4
 * UTF8-1      = %x00-7F
 * UTF8-2      = %xC2-DF UTF8-tail
 * UTF8-3      = %xE0 %xA0-BF UTF8-tail / %xE1-EC 2( UTF8-tail ) /
 *               %xED %x80-9F UTF8-tail / %xEE-EF 2( UTF8-tail )
 * UTF8-4      = %xF0 %x90-BF 2( UTF8-tail ) / %xF1-F3 3( UTF8-tail ) /
 *               %xF4 %x80-8F 2( UTF8-tail )
 * UTF8-tail   = %x80-BF
 */
function isValidUtf8(bytes32 b) pure returns (uint256) {
    // TODO you can significantly optimize comparisons with bitmasks,
    // some stuff to look at:
    // https://github.com/zwegner/faster-utf8-validator/blob/master/z_validate.c
    // https://github.com/websockets/utf-8-validate/blob/master/src/validation.c
    // https://github.com/simdutf/simdutf/blob/master/src/scalar/utf8.h

    uint8 first = uint8(b[0]);
    // UTF8-1 = %x00-7F
    if (first <= 0x7F) {
        // fast path for ascii
        return 1;
    }

    uint256 w = utf8CharWidth(first);
    if (w == 2) {
        // UTF8-2
        if (
            // %xC2-DF UTF8-tail
            0xC2 <= first && first <= 0xDF
            && _utf8Tail(uint8(b[1]))
        ) {
            return 2;
        } else {
            return 0;
        }
    } else if (w == 3) {
        uint8 second = uint8(b[1]);
        // UTF8-3
        bool valid12 =
            // = %xE0 %xA0-BF UTF8-tail
            first == 0xE0
            && 0xA0 <= second && second <= 0xBF
            // / %xE1-EC 2( UTF8-tail )
            || 0xE1 <= first && first <= 0xEC
            && _utf8Tail(second)
            // / %xED %x80-9F UTF8-tail
            || first == 0xED
            && 0x80 <= second && second <= 0x9F
            // / %xEE-EF 2( UTF8-tail )
            || 0xEE <= first && first <= 0xEF
            && _utf8Tail(second);

        if (valid12 && _utf8Tail(uint8(b[2]))) {
            return 3;
        } else {
            return 0;
        }
    } else if (w == 4) {
        uint8 second = uint8(b[1]);
        // UTF8-4
        bool valid12 =
            // = %xF0 %x90-BF 2( UTF8-tail )
            first == 0xF0
            && 0x90 <= second && second <= 0xBF
            // / %xF1-F3 3( UTF8-tail )
            || 0xF1 <= first && first <= 0xF3
            && _utf8Tail(second)
            // / %xF4 %x80-8F 2( UTF8-tail )
            || first == 0xF4
            && 0x80 <= second && second <= 0x8F;

        if (valid12 && _utf8Tail(uint8(b[2])) && _utf8Tail(uint8(b[3]))) {
            return 4;
        } else {
            return 0;
        }
    } else {
        return 0;
    }
}

/// @dev UTF8-tail = %x80-BF
function _utf8Tail(uint256 b) pure returns (bool) {
    // and,cmp should be faster than cmp,cmp,and
    // 0xC0 = 0b1100_0000, 0x80 = 0b1000_0000
    return b & 0xC0 == 0x80;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { leftMask } from "./mem.sol";

/*
 * These functions are VERY DANGEROUS!
 * They operate directly on memory pointers, use with caution.
 *
 * Assembly here is marked as memory-safe for optimization.
 * The caller MUST use pointers in a memory-safe way!
 * https://docs.soliditylang.org/en/latest/assembly.html#memory-safety
 */

/// @dev 32 0x80 bytes. 0x80 = 1000_0000
uint256 constant ASCII_MASK = 0x80 * (type(uint256).max / type(uint8).max);

/**
 * @dev Efficiently checks if all bytes are within the ASCII range.
 */
function memIsAscii(uint256 textPtr, uint256 textLen) pure returns (bool) {
    uint256 tailLen;
    uint256 endPtr;
    // safe because tailLen <= textLen (ptr+len is implicitly safe)
    unchecked {
        tailLen = textLen % 32;
        endPtr = textPtr + (textLen - tailLen);
    }

    // check 32 byte chunks with the ascii mask
    uint256 b;
    while (textPtr < endPtr) {
        /// @solidity memory-safe-assembly
        assembly {
            b := mload(textPtr)
        }
        // break if any non-ascii byte is found
        if (b & ASCII_MASK != 0) {
            return false;
        }
        // safe because textPtr < endPtr, and endPtr = textPtr + n*32 (see tailLen)
        unchecked {
            textPtr += 32;
        }
    }

    // this mask removes any trailing bytes
    uint256 trailingMask = leftMask(tailLen);
    /// @solidity memory-safe-assembly
    assembly {
        b := and(mload(endPtr), trailingMask)
    }
    // check tail with the ascii mask
    return b & ASCII_MASK == 0;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

error PackedPtrLen__PtrOverflow();
error PackedPtrLen__LenOverflow();

/**
 * @title Pack ptr and len uint128 values into 1 uint256.
 * @dev ptr is left/MSB. len is right/LSB.
 */
library PackPtrLen {
    uint256 constant MAX = type(uint128).max;

    uint256 constant MASK_PTR = uint256(type(uint128).max) << 128;
    uint256 constant MASK_LEN = uint256(type(uint128).max);

    function pack(uint256 ptr, uint256 len) internal pure returns (uint256 packed) {
        if (ptr > MAX) revert PackedPtrLen__PtrOverflow();
        if (len > MAX) revert PackedPtrLen__LenOverflow();
        return (ptr << 128) | (len & MASK_LEN);
    }

    function getPtr(uint256 packed) internal pure returns (uint256) {
        return packed >> 128;
    }

    function getLen(uint256 packed) internal pure returns (uint256) {
        return packed & MASK_LEN;
    }

    function setPtr(uint256 packed, uint256 ptr) internal pure returns (uint256) {
        return (packed & MASK_PTR) | (ptr << 128);
    }

    function setLen(uint256 packed, uint256 len) internal pure returns (uint256) {
        return (packed & MASK_LEN) | (len);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.20;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {UpgradeableBeacon} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.20;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.20;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(newImplementation.code.length > 0);
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/*
 * These functions are VERY DANGEROUS!
 * They operate directly on memory pointers, use with caution.
 *
 * Assembly here is marked as memory-safe for optimization.
 * The caller MUST use pointers in a memory-safe way!
 * https://docs.soliditylang.org/en/latest/assembly.html#memory-safety
 */

/**
 * @dev Load 1 byte from the pointer.
 * The result is in the least significant byte, hence uint8.
 */
function mload8(uint256 ptr) pure returns (uint8 item) {
    /// @solidity memory-safe-assembly
    assembly {
        item := byte(0, mload(ptr))
    }
    return item;
}

/**
 * @dev Copy `n` memory bytes.
 * WARNING: Does not handle pointer overlap!
 */
function memcpy(uint256 ptrDest, uint256 ptrSrc, uint256 length) pure {
    // copy 32-byte chunks
    while (length >= 32) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(ptrDest, mload(ptrSrc))
        }
        // safe because total addition will be <= length (ptr+len is implicitly safe)
        unchecked {
            ptrDest += 32;
            ptrSrc += 32;
            length -= 32;
        }
    }
    // copy the 0-31 length tail
    // (the rest is an inlined `mstoreN`)
    uint256 mask = leftMask(length);
    /// @solidity memory-safe-assembly
    assembly {
        mstore(ptrDest,
            or(
                // store the left part
                and(mload(ptrSrc), mask),
                // preserve the right part
                and(mload(ptrDest), not(mask))
            )
        )
    }
}

/**
 * @dev mstore `n` bytes (left-aligned) of `data`
 */
function mstoreN(uint256 ptrDest, bytes32 data, uint256 n) pure {
    uint256 mask = leftMask(n);
    /// @solidity memory-safe-assembly
    assembly {
        mstore(ptrDest,
            or(
                // store the left part
                and(data, mask),
                // preserve the right part
                and(mload(ptrDest), not(mask))
            )
        )
    }
}

/**
 * @dev Copy `n` memory bytes using identity precompile.
 */
function memmove(uint256 ptrDest, uint256 ptrSrc, uint256 n) view {
    /// @solidity memory-safe-assembly
    assembly {
        pop(
            staticcall(
                gas(),   // gas (unused is returned)
                0x04,    // identity precompile address
                ptrSrc,  // argsOffset
                n,       // argsSize: byte size to copy
                ptrDest, // retOffset
                n        // retSize: byte size to copy
            )
        )
    }
}

/**
 * @dev Compare `n` memory bytes lexicographically.
 * Returns 0 for equal, < 0 for less than and > 0 for greater than.
 *
 * https://doc.rust-lang.org/std/cmp/trait.Ord.html#lexicographical-comparison
 */
function memcmp(uint256 ptrSelf, uint256 ptrOther, uint256 n) pure returns (int256) {
    // binary search for the first inequality
    while (n >= 32) {
        // safe because total addition will be <= n (ptr+len is implicitly safe)
        unchecked {
            uint256 nHalf = n / 2;
            if (memeq(ptrSelf, ptrOther, nHalf)) {
                ptrSelf += nHalf;
                ptrOther += nHalf;
                // (can't do n /= 2 instead of nHalf, some bytes would be skipped)
                n -= nHalf;
                // an explicit continue is better for optimization here
                continue;
            } else {
                n -= nHalf;
            }
        }
    }

    uint256 mask = leftMask(n);
    int256 diff;
    /// @solidity memory-safe-assembly
    assembly {
        // for <32 bytes subtraction can be used for comparison,
        // just need to shift away from MSB
        diff := sub(
            shr(8, and(mload(ptrSelf), mask)),
            shr(8, and(mload(ptrOther), mask))
        )
    }
    return diff;
}

/**
 * @dev Returns true if `n` memory bytes are equal.
 *
 * It's faster (up to 4x) than memcmp, especially on medium byte lengths like 32-320.
 * The benefit gets smaller for larger lengths, for 10000 it's only 30% faster.
 */
function memeq(uint256 ptrSelf, uint256 ptrOther, uint256 n) pure returns (bool result) {
    /// @solidity memory-safe-assembly
    assembly {
        result := eq(keccak256(ptrSelf, n), keccak256(ptrOther, n))
    }
}

/**
 * @dev Left-aligned byte mask (e.g. for partial mload/mstore).
 * For length >= 32 returns type(uint256).max
 *
 * length 0:   0x000000...000000
 * length 1:   0xff0000...000000
 * length 2:   0xffff00...000000
 * ...
 * length 30:  0xffffff...ff0000
 * length 31:  0xffffff...ffff00
 * length 32+: 0xffffff...ffffff
 */
function leftMask(uint256 length) pure returns (uint256) {
    unchecked {
        return ~(
            type(uint256).max >> (length * 8)
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/*
 * These functions are VERY DANGEROUS!
 * They operate directly on memory pointers, use with caution.
 *
 * Assembly here is marked as memory-safe for optimization.
 * The caller MUST use pointers in a memory-safe way!
 * https://docs.soliditylang.org/en/latest/assembly.html#memory-safety
 *
 * Loosely based on https://doc.rust-lang.org/1.65.0/core/slice/memchr/
 */

/**
 * @dev Returns the first index matching the byte `x` in text;
 * or type(uint256).max if not found.
 */
function memchr(uint256 ptrText, uint256 lenText, uint8 x) pure returns (uint256 index) {
    if (lenText <= 32) {
        // Fast path for small slices.
        return memchrWord(ptrText, lenText, x);
    }

    uint256 ptrStart = ptrText;
    uint256 lenTail;
    uint256 ptrEnd;
    // safe because lenTail <= lenText (ptr+len is implicitly safe)
    unchecked {
        // (unchecked % saves a little gas)
        lenTail = lenText % 32;
        ptrEnd = ptrText + (lenText - lenTail);
    }
    uint256 repeatedX = repeatByte(x);
    while (ptrText < ptrEnd) {
        // any bytes equal to `x` become zeros
        // (this helps find `x` faster, values of non-zero bytes don't matter)
        uint256 chunkXZero;
        /// @solidity memory-safe-assembly
        assembly {
            chunkXZero := xor(mload(ptrText), repeatedX)
        }
        // break if there is a matching byte
        if (nonZeroIfXcontainsZeroByte(chunkXZero) != 0) {
            // - is safe because ptrText >= ptrStart (ptrText = ptrStart + 32*n)
            // + is safe because index + offsetLen < lenText
            // (ptr+len is implicitly safe)
            unchecked {
                return
                    // index
                    memchrWord(ptrText, 32, x)
                    // + offsetLen
                    + (ptrText - ptrStart);
            }
        }

        // safe because ptrText < ptrEnd, and ptrEnd = ptrText + n*32 (see lenTail)
        unchecked {
            ptrText += 32;
        }
    }

    if (lenTail == 0) return type(uint256).max;

    index = memchrWord(ptrEnd, lenTail, x);
    if (index == type(uint256).max) {
        return type(uint256).max;
    } else {
        // - is safe because ptrEnd >= ptrStart (ptrEnd = ptrStart + lenText - lenTail)
        // + is safe because index + offsetLen < lenText
        // (ptr+len is implicitly safe)
        unchecked {
            return index
                // + offsetLen
                + (ptrEnd - ptrStart);
        }
    }
}

/**
 * @dev Returns the last index matching the byte `x` in text;
 * or type(uint256).max if not found.
 */
function memrchr(uint256 ptrText, uint256 lenText, uint8 x) pure returns (uint256) {
    if (lenText <= 32) {
        // Fast path for small slices.
        return memrchrWord(ptrText, lenText, x);
    }

    uint256 lenTail;
    uint256 offsetPtr;
    // safe because pointers are guaranteed to be valid by the caller
    unchecked {
        // (unchecked % saves a little gas)
        lenTail = lenText % 32;
        offsetPtr = ptrText + lenText;
    }

    if (lenTail != 0) {
        // remove tail length
        // - is safe because lenTail <= lenText <= offsetPtr
        unchecked {
            offsetPtr -= lenTail;
        }
        // return if there is a matching byte
        uint256 index = memrchrWord(offsetPtr, lenTail, x);
        if (index != type(uint256).max) {
            // - is safe because offsetPtr > ptrText (offsetPtr = ptrText + lenText - lenTail)
            // + is safe because index + offsetLen < lenText
            unchecked {
                return index
                    // + offsetLen
                    + (offsetPtr - ptrText);
            }
        }
    }

    uint256 repeatedX = repeatByte(x);
    while (offsetPtr > ptrText) {
        // - is safe because 32 <= lenText <= offsetPtr
        unchecked {
            offsetPtr -= 32;
        }

        // any bytes equal to `x` become zeros
        // (this helps find `x` faster, values of non-zero bytes don't matter)
        uint256 chunkXZero;
        /// @solidity memory-safe-assembly
        assembly {
            chunkXZero := xor(mload(offsetPtr), repeatedX)
        }
        // break if there is a matching byte
        if (nonZeroIfXcontainsZeroByte(chunkXZero) != 0) {
            // - is safe because offsetPtr > ptrText (see the while condition)
            // + is safe because index + offsetLen < lenText
            unchecked {
                return
                    // index
                    memrchrWord(offsetPtr, 32, x)
                    // + offsetLen
                    + (offsetPtr - ptrText);
            }
        }
    }
    // not found
    return type(uint256).max;
}

/**
 * @dev Returns the first index matching the byte `x` in text;
 * or type(uint256).max if not found.
 * 
 * WARNING: it works ONLY for length 32 or less.
 * This is for use by memchr after its chunk search.
 */
function memchrWord(uint256 ptrText, uint256 lenText, uint8 x) pure returns (uint256) {
    uint256 chunk;
    /// @solidity memory-safe-assembly
    assembly {
        chunk := mload(ptrText)
    }

    uint256 i;
    if (lenText > 32) {
        lenText = 32;
    }

    ////////binary search start
    // Some manual binary searches, cost ~50gas, could save up to ~1500
    // (comment them out and the function will work fine)
    if (lenText >= 16 + 2) {
        uint256 repeatedX = chunk ^ repeatByte(x);

        if (nonZeroIfXcontainsZeroByte(repeatedX | type(uint128).max) == 0) {
            i = 16;

            if (lenText >= 24 + 2) {
                if (nonZeroIfXcontainsZeroByte(repeatedX | type(uint64).max) == 0) {
                    i = 24;
                }
            }
        } else if (nonZeroIfXcontainsZeroByte(repeatedX | type(uint192).max) == 0) {
            i = 8;
        }
    } else if (lenText >= 8 + 2) {
        uint256 repeatedX = chunk ^ repeatByte(x);

        if (nonZeroIfXcontainsZeroByte(repeatedX | type(uint192).max) == 0) {
            i = 8;
        }
    }
    ////////binary search end
    
    // ++ is safe because lenText <= 32
    unchecked {
        for (i; i < lenText; i++) {
            uint8 b;
            assembly {
                b := byte(i, chunk)
            }
            if (b == x) return i;
        }
    }
    // not found
    return type(uint256).max;
}

/**
 * @dev Returns the last index matching the byte `x` in text;
 * or type(uint256).max if not found.
 * 
 * WARNING: it works ONLY for length 32 or less.
 * This is for use by memrchr after its chunk search.
 */
function memrchrWord(uint256 ptrText, uint256 lenText, uint8 x) pure returns (uint256) {
    if (lenText > 32) {
        lenText = 32;
    }
    uint256 chunk;
    /// @solidity memory-safe-assembly
    assembly {
        chunk := mload(ptrText)
    }

    while (lenText > 0) {
        // -- is safe because lenText > 0
        unchecked {
            lenText--;
        }
        uint8 b;
        assembly {
            b := byte(lenText, chunk)
        }
        if (b == x) return lenText;
    }
    // not found
    return type(uint256).max;
}

/// @dev repeating low bit for containsZeroByte
uint256 constant LO_U256 = 0x0101010101010101010101010101010101010101010101010101010101010101;
/// @dev repeating high bit for containsZeroByte
uint256 constant HI_U256 = 0x8080808080808080808080808080808080808080808080808080808080808080;

/**
 * @dev Returns a non-zero value if `x` contains any zero byte.
 * (returning a bool would be less efficient)
 *
 * From *Matters Computational*, J. Arndt:
 *
 * "The idea is to subtract one from each of the bytes and then look for
 * bytes where the borrow propagated all the way to the most significant bit."
 */
function nonZeroIfXcontainsZeroByte(uint256 x) pure returns (uint256) {
    unchecked {
        return (x - LO_U256) & (~x) & HI_U256;
    }
    /*
     * An example of how it works:
     *                                              here is 00
     * x    0x0101010101010101010101010101010101010101010101000101010101010101
     * x-LO 0xffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000
     * ~x   0xfefefefefefefefefefefefefefefefefefefefefefefefffefefefefefefefe
     * &1   0xfefefefefefefefefefefefefefefefefefefefefefefeff0000000000000000
     * &2   0x8080808080808080808080808080808080808080808080800000000000000000
     */
}

/// @dev Repeat byte `b` 32 times
function repeatByte(uint8 b) pure returns (uint256) {
    // safe because uint8 can't cause overflow:
    // e.g. 0x5A * 0x010101..010101 = 0x5A5A5A..5A5A5A
    // and  0xFF * 0x010101..010101 = 0xFFFFFF..FFFFFF
    unchecked {
        return b * (type(uint256).max / type(uint8).max);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { mload8 } from "./utils/mem.sol";
import { Slice, Slice__ } from "./Slice.sol";

/**
 * @title Slice iterator.
 * @dev This struct is created by the iter method on `Slice`.
 * Iterates only 1 byte (uint8) at a time.
 */
struct SliceIter {
    uint256 _ptr;
    uint256 _len;
}

/*//////////////////////////////////////////////////////////////////////////
                                CUSTOM ERRORS
//////////////////////////////////////////////////////////////////////////*/

error SliceIter__StopIteration();

/*//////////////////////////////////////////////////////////////////////////
                              STATIC FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

library SliceIter__ {
    /**
     * @dev Creates a new `SliceIter` from `Slice`.
     * Note the `Slice` is assumed to be memory-safe.
     */
    function from(Slice slice) internal pure returns (SliceIter memory) {
        return SliceIter(slice.ptr(), slice.len());
    }
}

/*//////////////////////////////////////////////////////////////////////////
                              GLOBAL FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

using { asSlice, ptr, len, isEmpty, next, nextBack } for SliceIter global;

/**
 * @dev Views the underlying data as a subslice of the original data.
 */
function asSlice(SliceIter memory self) pure returns (Slice slice) {
    return Slice__.fromUnchecked(self._ptr, self._len);
}

/**
 * @dev Returns the pointer to the start of an in-memory slice.
 */
function ptr(SliceIter memory self) pure returns (uint256) {
    return self._ptr;
}

/**
 * @dev Returns the length in bytes.
 */
function len(SliceIter memory self) pure returns (uint256) {
    return self._len;
}

/**
 * @dev Returns true if the iterator is empty.
 */
function isEmpty(SliceIter memory self) pure returns (bool) {
    return self._len == 0;
}

/**
 * @dev Advances the iterator and returns the next value.
 * Reverts if len == 0.
 */
function next(SliceIter memory self) pure returns (uint8 value) {
    uint256 selfPtr = self._ptr;
    uint256 selfLen = self._len;
    if (selfLen == 0) revert SliceIter__StopIteration();

    // safe because selfLen != 0 (ptr+len is implicitly safe and 1<=len)
    unchecked {
        // advance the iterator
        self._ptr = selfPtr + 1;
        self._len = selfLen - 1;
    }

    return mload8(selfPtr);
}

/**
 * @dev Advances the iterator from the back and returns the next value.
 * Reverts if len == 0.
 */
function nextBack(SliceIter memory self) pure returns (uint8 value) {
    uint256 selfPtr = self._ptr;
    uint256 selfLen = self._len;
    if (selfLen == 0) revert SliceIter__StopIteration();

    // safe because selfLen != 0 (ptr+len is implicitly safe)
    unchecked {
        // advance the iterator
        self._len = selfLen - 1;

        return mload8(selfPtr + (selfLen - 1));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { utf8CharWidth } from "./utf8.sol";

/*
 * IMPORTANT: Here `uint256` represents 1 code point (aka unicode scalar values),
 * NOT a UTF-8 encoded character!
 * E.g. for '€' code point = 0x20AC; wheareas UTF-8 encoding = 0xE282AC.
 *
 * Only conversion to/from UTF-8 is addressed here.
 * Note that UTF-16 surrogate halves are invalid code points even if UTF-16 was supported.
 */

error Unicode__InvalidCode();

/// @dev The highest valid code point.
uint256 constant MAX = 0x10FFFF;

// UTF-8 ranges
uint256 constant MAX_ONE_B = 0x80;
uint256 constant MAX_TWO_B = 0x800;
uint256 constant MAX_THREE_B = 0x10000;
// and tags for encoding characters
uint256 constant TAG_CONT = 0x80;
uint256 constant TAG_TWO_B = 0xC0;
uint256 constant TAG_THREE_B = 0xE0;
uint256 constant TAG_FOUR_B = 0xF0;
// and continuation byte mask
uint256 constant MASK_CONT = 0x3F;

/**
 * @dev Encodes a unicode code point as UTF-8.
 * Reverts if the code point is invalid.
 * The result is 1-4 bytes starting at MSB.
 */
function encodeUtf8(uint256 code) pure returns (bytes32) {
    if (code < MAX_ONE_B) {
        return bytes32(
            (code                                ) << (31 * 8)
        );
    } else if (code < MAX_TWO_B) {
        return bytes32(
            (code >> 6              | TAG_TWO_B  ) << (31 * 8) |
            (code       & MASK_CONT | TAG_CONT   ) << (30 * 8)
        );
    } else if (code < MAX_THREE_B) {
        if (code & 0xF800 == 0xD800) {
            // equivalent to `code >= 0xD800 && code <= 0xDFFF`
            // U+D800–U+DFFF are invalid UTF-16 surrogate halves
            revert Unicode__InvalidCode();
        }
        return bytes32(
            (code >> 12             | TAG_THREE_B) << (31 * 8) |
            (code >> 6  & MASK_CONT | TAG_CONT   ) << (30 * 8) |
            (code       & MASK_CONT | TAG_CONT   ) << (29 * 8)
        );
    } else if (code <= MAX) {
        return bytes32(
            (code >> 18             | TAG_FOUR_B ) << (31 * 8) |
            (code >> 12 & MASK_CONT | TAG_CONT   ) << (30 * 8) |
            (code >> 6  & MASK_CONT | TAG_CONT   ) << (29 * 8) |
            (code       & MASK_CONT | TAG_CONT   ) << (28 * 8)
        );
    } else {
        revert Unicode__InvalidCode();
    }
}

/**
 * @dev Decodes a UTF-8 character into its code point.
 * Validates ONLY the leading byte, use `isValidCodePoint` on the result if UTF-8 wasn't validated.
 * The input is 1-4 bytes starting at MSB.
 */
function decodeUtf8(bytes32 str) pure returns (uint256) {
    uint256 leadingByte = uint256(uint8(str[0]));
    uint256 width = utf8CharWidth(leadingByte);

    if (width == 1) {
        return leadingByte;
    } else if (width == 2) {
        uint256 byte1 = uint256(uint8(str[1]));
        return uint256(
            // 0x1F = 0001_1111
            (leadingByte & 0x1F     ) << 6 |
            (byte1       & MASK_CONT)
        );
    } else if (width == 3) {
        uint256 byte1 = uint256(uint8(str[1]));
        uint256 byte2 = uint256(uint8(str[2]));
        return uint256(
            // 0x0F = 0000_1111
            (leadingByte & 0x0F     ) << 12 |
            (byte1       & MASK_CONT) << 6  |
            (byte2       & MASK_CONT)
        );
    } else if (width == 4) {
        uint256 byte1 = uint256(uint8(str[1]));
        uint256 byte2 = uint256(uint8(str[2]));
        uint256 byte3 = uint256(uint8(str[3]));
        return uint256(
            // 0x07 = 0000_0111
            (leadingByte & 0x07     ) << 18 |
            (byte1       & MASK_CONT) << 12 |
            (byte2       & MASK_CONT) << 6  |
            (byte3       & MASK_CONT)
        );
    } else {
        revert Unicode__InvalidCode();
    }
}

/**
 * @dev Returns the length of a code point in UTF-8 encoding.
 * Does NOT validate it.
 * WARNING: atm this function is neither used nor tested in this repo
 */
function lenUtf8(uint256 code) pure returns (uint256) {
    if (code < MAX_ONE_B) {
        return 1;
    } else if (code < MAX_TWO_B) {
        return 2;
    } else if (code < MAX_THREE_B) {
        return 3;
    } else {
        return 4;
    }
}

/**
 * @dev Returns true if the code point is valid.
 * WARNING: atm this function is neither used nor tested in this repo
 */
function isValidCodePoint(uint256 code) pure returns (bool) {
    // U+D800–U+DFFF are invalid UTF-16 surrogate halves
    if (code < 0xD800) {
        return true;
    } else {
        return code > 0xDFFF && code <= MAX;
    }
}