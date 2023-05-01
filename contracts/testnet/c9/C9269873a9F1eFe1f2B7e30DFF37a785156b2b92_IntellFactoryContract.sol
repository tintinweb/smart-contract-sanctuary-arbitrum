// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./lib/IIntellSetting.sol";
import "./lib/IShareERC721.sol";
import "./lib/IFactory.sol";
import "./lib/SafeMath.sol";
import "./lib/Strings.sol";
import "./lib/ECDSA.sol";
import "./lib/Ownable.sol";
import "./lib/IERC20.sol";
import "./ShareNFTContract.sol";

pragma experimental ABIEncoderV2;

contract IntellFactoryContract is IFactory, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;

    bytes32 public constant INIT_CODE_PAIR_HASH =
        keccak256(abi.encodePacked(type(ShareNFTContract).creationCode));

    mapping(uint256 => address) public override getShareNFTAddr;
    address[] public override allShareNFTAddrs;
    IIntellSetting private _intellSetting;

    mapping(address => bool) public enablePaymentTokenAddrs;

    constructor(IIntellSetting _intellSetting_, address _intellTokenAddr_) {
        _intellSetting = _intellSetting_;
        enablePaymentTokenAddrs[_intellTokenAddr_] = true;
    }

    modifier onlyFactory() {
        require(_intellSetting.factoryContractAddr() == msg.sender, "Ownable: caller is not the factory");
        _;
    }

    function setEnablePaymentTokenAddrs(
        address _newPaymentToken,
        bool enable
    ) external onlyOwner {
        enablePaymentTokenAddrs[_newPaymentToken] = enable;
    }

    function intellSetting() external view returns (IIntellSetting) {
        return _intellSetting;
    }

    function setIntellSetting(
        IIntellSetting _intellSetting_
    ) external onlyOwner {
        _intellSetting = _intellSetting_;
    }

    function shareLaunchPrice() public view returns (uint256) {
        return _intellSetting.shareNFTLaunchPrice();
    }

    function allShareNFTAddrsLength() external view override returns (uint256) {
        return allShareNFTAddrs.length;
    }

    function recoverSigner(
        bytes32 hash,
        bytes memory signature
    ) internal pure returns (address) {
        bytes32 messageDigest = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        return ECDSA.recover(messageDigest, signature);
    }

    function verifyMessage(
        bytes memory message,
        bytes memory signature
    ) internal view returns (bool) {
        bytes32 hash = keccak256(message);
        return recoverSigner(hash, signature) == _intellSetting.truthHolder();
    }

    function createShareNFTContract(
        bytes memory shareMessage,
        uint256 _CREATOR_NFT_TOKEN_ID
        
    ) external onlyFactory override returns (address investorNFT)  {

        (address _PAYMENT_TOKEN_ADDR) = abi.decode(
            shareMessage,
            (address)
        );

        require(
            enablePaymentTokenAddrs[_PAYMENT_TOKEN_ADDR],
            "DISABLED THIS PAYMENT TOKEN"
        );

        require(
            _intellSetting.creatorNFTContractAddr() != address(0),
            "NEEDS TO SENT SMART INTEGLLIGENCE EXCHANGE NFT CONTRACT ADDRESS"
        );

        require(
            getShareNFTAddr[_CREATOR_NFT_TOKEN_ID] == address(0),
            "THE INTELLIGENCE EXCHANGE: SHARE_NFT_EXISTS"
        );

        bytes memory bytecode = type(ShareNFTContract).creationCode;

        bytes32 salt = keccak256(shareMessage);
        assembly {
            investorNFT := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IShareERC721(investorNFT).launch(shareMessage, _intellSetting, _CREATOR_NFT_TOKEN_ID);

        emit InvestorNFTCreated(_CREATOR_NFT_TOKEN_ID, investorNFT);

        getShareNFTAddr[_CREATOR_NFT_TOKEN_ID] = investorNFT;
        allShareNFTAddrs.push(investorNFT);
    }

    function withdraw(IERC20 _paymentToken) external onlyOwner {
        _paymentToken.transfer(
            _msgSender(),
            _paymentToken.balanceOf(address(this))
        );
    }

    function version() external pure returns (uint256) {
        return 1; //version 1.0.0
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
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

    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
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
pragma solidity ^0.8.0;

import "./Context.sol";
import "./ERC165.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Receiver.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Address.sol";
import "./IFactory.sol";

contract ShareERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Factory
    address private _factory;

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
    constructor() {
        _factory = msg.sender;
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

    function setName(string memory _name_) internal {
        _name = _name_;
    }

    function setSymbol(string memory _symbol_) internal {
        _symbol = _symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ShareERC721.ownerOf(tokenId);
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
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
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
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

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
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ShareERC721.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

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

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ShareERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ShareERC721.ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ShareERC721.ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "./Context.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyAuthorized() {
        require(owner() == msg.sender);
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./IIntellSetting.sol";

interface IShareERC721 {
    function MAX_TOTAL_SUPPLY() external view returns (uint256);

    function MAX_MINT_PER_ADDR() external view returns (uint256);

    function MAX_MINT_PER_TX() external view returns (uint256);

    function CREATOR_NFT_TOKEN_ID() external view returns (uint256);

    function CREATOR_NFT_CONTRACT_ADDR() external view returns (address);

    function MINT_PRICE() external view returns (uint256);

    function PAYMENT_TOKEN_ADDR() external view returns (address);

    function LAUNCH_END_TIME() external view returns (uint256);

    function FOR_ONLY_US_INVESTOR() external view returns(bool);
    
    function WITHDRAWN() external view returns(bool);

    function BLOCKED() external view returns(bool);

    function launch(bytes calldata _data, IIntellSetting _intellSetting, uint256 _CREATOR_NFT_TOKEN_ID) external;

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IIntellSetting {
    function admin() external view returns(address);
    function truthHolder() external view returns(address);
    function creatorNFTMintPrice() external view returns(uint256);
    function shareNFTLaunchPrice() external view returns(uint256);
    function intellTokenAddr() external view returns(address);
    function factoryContractAddr() external view returns(address);
    function creatorNFTContractAddr() external view returns(address);
    function commissionForCreator() external view returns(uint256);
    function commissionForCreatorAndInvestor() external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFactory {
    event InvestorNFTCreated(uint256 indexed tokenId, address investorNFT);

    function getShareNFTAddr(uint256 _tokenId)
        external
        view
        returns (address investorNFT);

    function allShareNFTAddrs(uint256) external view returns (address);

    function allShareNFTAddrsLength() external view returns (uint256);

    function createShareNFTContract(
        bytes memory shareMessage,
        uint256 _CREATOR_NFT_TOKEN_ID
    ) external returns (address investorNFT);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC165.sol";
interface IERC721 is IERC165 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ShareERC721.sol";
import "./IERC721Enumerable.sol";

abstract contract ERC721ShareEnumerable is ShareERC721, IERC721Enumerable {
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
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ShareERC721)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < ShareERC721.balanceOf(owner),
            "ERC721Enumerable: owner index out of bounds"
        );
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
    function tokenByIndex(uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < ERC721ShareEnumerable.totalSupply(),
            "ERC721Enumerable: global index out of bounds"
        );
        return _allTokens[index];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

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

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ShareERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId)
        private
    {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ShareERC721.balanceOf(from) - 1;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC165.sol";
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    function tryRecover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address, RecoverError)
    {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    function recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(
                vs,
                0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            )
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, structHash)
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

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

pragma solidity ^0.8.0;

import "./lib/IIntellSetting.sol";
import "./lib/IShareERC721.sol";
import "./lib/ReentrancyGuard.sol";
import "./lib/SafeMath.sol";
import "./lib/Strings.sol";
import "./lib/ECDSA.sol";
import "./lib/ERC721ShareEnumerable.sol";
import "./lib/IERC20.sol";

pragma experimental ABIEncoderV2;

contract ShareNFTContract is
    ERC721ShareEnumerable,
    ReentrancyGuard,
    IShareERC721
{
    using Strings for uint256;
    using SafeMath for uint256;

    string _baseTokenURI;
    bool public _paused = false;

    uint256 public override MAX_TOTAL_SUPPLY;
    uint256 public override MAX_MINT_PER_ADDR;
    uint256 public override MAX_MINT_PER_TX;

    uint256 public override CREATOR_NFT_TOKEN_ID;
    address public override CREATOR_NFT_CONTRACT_ADDR;

    uint256 public override MINT_PRICE;
    address public override PAYMENT_TOKEN_ADDR;

    uint256 public override LAUNCH_END_TIME;
    bool public override FOR_ONLY_US_INVESTOR;
    bool public override WITHDRAWN = false;
    bool public override BLOCKED = false;

    IIntellSetting public intellSetting;

    event Minted(uint256 indexed tokenId, address to);
    event Stopped();

    mapping(address => uint256) public mintedPerAddress;

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyAdmin() {
        require(
            intellSetting.admin() == _msgSender(),
            "Ownable: caller is not the owner"
        );
        _;
    }

    function owner() public view returns (address) {
        return
            IERC721Enumerable(intellSetting.creatorNFTContractAddr()).ownerOf(
                CREATOR_NFT_TOKEN_ID
            );
    }

    function update(bytes calldata _data) external onlyAdmin {
        (
            string memory _NAME,
            string memory _SYMBOL,
            uint256 _MAX_TOTAL_SUPPLY,
            uint256 _MINT_PRICE,
            uint256 _MAX_MINT_PER_TX,
            uint256 _MAX_MINT_PER_ADDR,
            uint256 _LAUNCH_END_TIME,
            address _SHARE_NFT_ADDR
        ) = abi.decode(
                _data,
                (
                    string,
                    string,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    address
                )
            );

        require(
            bytes(_NAME).length > 0 &&
                bytes(_SYMBOL).length > 0 &&
                _SHARE_NFT_ADDR == address(this) &&
                _MAX_TOTAL_SUPPLY > 0 &&
                _MINT_PRICE > 0 &&
                _MAX_MINT_PER_TX > 0 &&
                _MAX_MINT_PER_ADDR > 0 &&
                _LAUNCH_END_TIME > block.timestamp,
            "INVALID INPUT DATA"
        );

        MAX_TOTAL_SUPPLY = _MAX_TOTAL_SUPPLY;
        MINT_PRICE = _MINT_PRICE;
        MAX_MINT_PER_ADDR = _MAX_MINT_PER_ADDR;
        MAX_MINT_PER_TX = _MAX_MINT_PER_TX;
        LAUNCH_END_TIME = _LAUNCH_END_TIME;

        setName(_NAME);
        setSymbol(_SYMBOL);
    }

    function launch(
        bytes calldata _data,
        IIntellSetting _intellSetting_,
        uint256 _CREATOR_NFT_TOKEN_ID
    ) external override {
        require(
            msg.sender == _intellSetting_.factoryContractAddr(),
            "The caller must be factory contract"
        );
        intellSetting = _intellSetting_;

        (
            address _PAYMENT_TOKEN_ADDR,
            string memory _NAME,
            string memory _SYMBOL,
            uint256 _MAX_TOTAL_SUPPLY,
            uint256 _MINT_PRICE,
            uint256 _MAX_MINT_PER_TX,
            uint256 _MAX_MINT_PER_ADDR,
            uint256 _LAUNCH_END_TIME,
            bool _FOR_ONLY_US_INVESTOR
        ) = abi.decode(
                _data,
                (
                    address,
                    string,
                    string,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    bool
                )
            );

        require(
            bytes(_NAME).length > 0 &&
                bytes(_SYMBOL).length > 0 &&
                _MAX_TOTAL_SUPPLY > 0 &&
                _MINT_PRICE > 0 &&
                _MAX_MINT_PER_TX > 0 &&
                _MAX_MINT_PER_ADDR > 0 &&
                _LAUNCH_END_TIME > block.timestamp,
            "INVALID INPUT DATA"
        );

        MAX_TOTAL_SUPPLY = _MAX_TOTAL_SUPPLY;
        MINT_PRICE = _MINT_PRICE;
        MAX_MINT_PER_ADDR = _MAX_MINT_PER_ADDR;
        MAX_MINT_PER_TX = _MAX_MINT_PER_TX;
        LAUNCH_END_TIME = _LAUNCH_END_TIME;

        CREATOR_NFT_TOKEN_ID = _CREATOR_NFT_TOKEN_ID;
        PAYMENT_TOKEN_ADDR = _PAYMENT_TOKEN_ADDR;

        FOR_ONLY_US_INVESTOR = _FOR_ONLY_US_INVESTOR;

        setName(_NAME);
        setSymbol(_SYMBOL);
        _paused = false;
    }

    function adopt(
        bytes calldata message,
        bytes calldata signature
    ) external nonReentrant {
        require(verifyMessage(message, signature), "NO SIGNER");

        (
            address _USER_ADDR,
            address _SHARE_NFT_ADDR,
            bool _KYC_VERIFICATION_AS_INVESTOR,
            bool _USER_SUSPENDED,
            bool _FROM_US,
            bool _STOP_SELLING_SHARE,
            bool _MODEL_SUSPEND,
            uint256 _NUM,
            uint256 _CREATOR_NFT_TOKEN_ID
        ) = abi.decode(
                message,
                (
                    address,
                    address,
                    bool,
                    bool,
                    bool,
                    bool,
                    bool,
                    uint256,
                    uint256
                )
            );

        require(!BLOCKED, "THIS INTELL SHARE NFT COLLECTION WAS BLOCKED");

        require(
            (FOR_ONLY_US_INVESTOR &&
                _FROM_US &&
                _KYC_VERIFICATION_AS_INVESTOR) ||
                (!FOR_ONLY_US_INVESTOR && !_FROM_US),
            "KYC is required"
        );

        require(
            !_USER_SUSPENDED &&
                !_MODEL_SUSPEND &&
                !_STOP_SELLING_SHARE &&
                _CREATOR_NFT_TOKEN_ID == CREATOR_NFT_TOKEN_ID &&
                _SHARE_NFT_ADDR == address(this),
            "THE USER PROFILE IS INVALID"
        );

        require(LAUNCH_END_TIME >= block.timestamp, "SALE WAS EXPIRED");
        uint256 supply = totalSupply();
        require(!_paused, "SALE STOPPED");
        require(_NUM <= MAX_MINT_PER_TX, "MINTING WOULD EXCEED MAX SUPPLY");
        require(
            supply + _NUM <= MAX_TOTAL_SUPPLY,
            "MINTING WOULD EXCEED MAX SUPPLY"
        );
        require(
            _NUM + mintedPerAddress[msg.sender] <= MAX_MINT_PER_ADDR,
            "SENDER ADDRESS CANNOT MINT MORE THAN MAX_MINT_PER_ADDR"
        );

        require(tx.origin == msg.sender && msg.sender == _USER_ADDR, "NO BOT");
        require(
            IERC20(PAYMENT_TOKEN_ADDR).balanceOf(msg.sender) >=
                MINT_PRICE * _NUM,
            "INSUFFICIENT BALANCE"
        );
        mintedPerAddress[msg.sender] += _NUM;
        IERC20(PAYMENT_TOKEN_ADDR).transferFrom(
            msg.sender,
            address(this),
            MINT_PRICE * _NUM
        );

        for (uint256 i = 1; i <= _NUM; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function walletOfOwner(
        address _owner
    ) public view override returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function stop() public onlyOwner {
        _paused = true;
        emit Stopped();
    }

    function blocked(bool val) public onlyAdmin {
        BLOCKED = val;
    }

    function recoverSigner(
        bytes32 hash,
        bytes memory signature
    ) internal pure returns (address) {
        bytes32 messageDigest = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        return ECDSA.recover(messageDigest, signature);
    }

    function verifyMessage(
        bytes memory message,
        bytes memory signature
    ) internal view returns (bool) {
        bytes32 hash = keccak256(message);
        return recoverSigner(hash, signature) == intellSetting.truthHolder();
    }

    function withdraw(
        bytes calldata message,
        bytes calldata signature
    ) public onlyOwner {
        require(LAUNCH_END_TIME < block.timestamp, "NOT FINISHED YET");
        require(verifyMessage(message, signature), "NO SIGNER");

        (bool _canWithdraw, address _owner) = abi.decode(
            message,
            (bool, address)
        );
        require(_canWithdraw && _owner == owner(), "THE CONDITION IS INVALID");

        uint256 amount = IERC20(PAYMENT_TOKEN_ADDR).balanceOf(address(this));
        IERC20(PAYMENT_TOKEN_ADDR).transfer(owner(), amount);
        WITHDRAWN = true;
    }

    function version() external pure returns (uint32) {
        return 1; //version 1.0.0
    }
}