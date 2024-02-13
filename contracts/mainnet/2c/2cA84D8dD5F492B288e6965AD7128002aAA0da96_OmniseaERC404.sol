// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "../interfaces/IOmniseaDropsScheduler.sol";
import "../interfaces/IERC2981Royalties.sol";
import "../interfaces/IOmniseaERC404.sol";
import {CreateParams, Phase} from "../structs/erc404/ERC404Structs.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC404.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract OmniseaERC404 is IOmniseaERC404, ERC404, ReentrancyGuard {
    using Strings for uint256;

    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    IOmniseaDropsScheduler public scheduler;
    address internal immutable _revenueManager = address(0x61104fBe07ecc735D8d84422c7f045f8d29DBf15);
    uint24 public maxSupply;
    string public collectionURI;
    address public override dropsManager;
    string public tokensURI;
    uint256 public override endTime;
    uint24 public royaltyAmount;
    bool private isInitialized;
    bool private isMintedToPlatform;

    function initialize(
        CreateParams memory params,
        address _owner,
        address _dropsManager,
        address _scheduler
    ) external {
        require(!isInitialized);
        require(bytes(params.tokensURI).length > 0, "!tokensURI");
        require(maxSupply > 0, "!maxSupply");
        _init(params.name, params.symbol, 18, params.maxSupply, _owner);
        isInitialized = true;
        dropsManager = _dropsManager;
        tokensURI = params.tokensURI;
        maxSupply = params.maxSupply;
        collectionURI = params.uri;
        endTime = params.endTime;
        royaltyAmount = params.royaltyAmount;
        scheduler = IOmniseaDropsScheduler(_scheduler);
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked("ipfs://", collectionURI));
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(tokenId > 0, "!tokenId");

        uint256 effectiveId;
        if (tokenId <= maxSupply) {
            effectiveId = tokenId;
        } else {
            effectiveId = ((tokenId - 1) % maxSupply) + 1;
        }

        return string(abi.encodePacked("ipfs://", tokensURI, "/", effectiveId.toString(), ".json"));
    }

    function mint(address _minter, uint24 _quantity, bytes32[] memory _merkleProof, uint8 _phaseId) external override nonReentrant returns (uint256) {
        require(msg.sender == dropsManager);
        require(isAllowed(_minter, _quantity, _merkleProof, _phaseId), "!isAllowed");
        scheduler.increasePhaseMintedCount(_minter, _phaseId, _quantity);

        for (uint24 i = 0; i < _quantity; i++) {
            _mint(_minter);
            _mintFractions(_minter);
        }

        return minted;
    }

    // @dev Introduces fair initial ERC-404 distribution and prevents underflow on balanceOf subtraction in the after-mint transferFrom
    function _mintFractions(address _minter) internal {
        balanceOf[_minter] += _getUnit();
    }

    function mintPrice(uint8 _phaseId) public view override returns (uint256) {
        return scheduler.mintPrice(_phaseId);
    }

    function isAllowed(address _account, uint24 _quantity, bytes32[] memory _merkleProof, uint8 _phaseId) internal view returns (bool) {
        require(block.timestamp < endTime);
        if (maxSupply > 0) require(maxSupply >= (minted + _quantity));

        return scheduler.isAllowed(_account, _quantity, _merkleProof, _phaseId);
    }

    function setPhase(
        uint8 _phaseId,
        uint256 _from,
        uint256 _to,
        bytes32 _merkleRoot,
        uint24 _maxPerAddress,
        uint256 _price,
        address _token,
        uint256 _minToken
    ) external onlyOwner {
        scheduler.setPhase(_phaseId, _from, _to, _merkleRoot, _maxPerAddress, _price, _token, _minToken);
    }

    function setTokensURI(string memory _uri) external onlyOwner {
        require(block.timestamp < endTime);
        tokensURI = _uri;
        emit BatchMetadataUpdate(1, type(uint256).max);
    }

    function preMintToTeam(uint256 _quantity) external nonReentrant onlyOwner {
        if (maxSupply > 0) {
            require(maxSupply >= minted + _quantity);
        } else {
            require(block.timestamp < endTime);
        }

        for (uint256 i = 0; i < _quantity; i++) {
            _mint(owner);
            _mintFractions(owner);
        }
    }

    function preMintToPlatform(uint256 _quantity) external {
        require(msg.sender == _revenueManager && !isMintedToPlatform && _quantity <= 5);
        if (maxSupply > 0) {
            require(maxSupply >= minted + _quantity);
        } else {
            require(block.timestamp < endTime);
        }
        isMintedToPlatform = true;

        for (uint256 i = 0; i < _quantity; i++) {
            _mint(_revenueManager);
            _mintFractions(_revenueManager);
        }
    }

    function royaltyInfo(uint256, uint256 value) external view returns (address _receiver, uint256 _royaltyAmount) {
        _receiver = owner;
        _royaltyAmount = (value * royaltyAmount) / 10000;
    }

    function setRoyaltyAmount(uint24 _royaltyAmount) external onlyOwner {
        royaltyAmount = _royaltyAmount;
    }

    function collectionOwner() public view override returns (address) {
        return owner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IOmniseaDropsScheduler {
    function isAllowed(address _account, uint24 _quantity, bytes32[] memory _merkleProof, uint8 _phaseId) external view returns (bool);
    function setPhase(
        uint8 _phaseId,
        uint256 _from,
        uint256 _to,
        bytes32 _merkleRoot,
        uint24 _maxPerAddress,
        uint256 _price,
        address _token,
        uint256 _minToken
    ) external;
    function increasePhaseMintedCount(address _account,uint8 _phaseId, uint24 _quantity) external;
    function mintPrice(uint8 _phaseId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC2981Royalties {
    function royaltyInfo(uint256 _tokenId, uint256 _value) external view returns (address _receiver, uint256 _royaltyAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import {CreateParams} from "../structs/erc404/ERC404Structs.sol";
import "../ERC404/ERC404.sol";

interface IOmniseaERC404 {
    function initialize(CreateParams memory params, address _owner, address _manager, address _scheduler) external;
    function mint(address _minter, uint24 _quantity, bytes32[] memory _merkleProof, uint8 _phaseId) external returns (uint256);
    function mintPrice(uint8 _phaseId) external view returns (uint256);
    function collectionOwner() external view returns (address);
    function dropsManager() external view returns (address);
    function endTime() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

struct CreateParams {
    string name;
    string symbol;
    string uri;
    string tokensURI;
    uint24 maxSupply;
    uint24 royaltyAmount;
    uint256 endTime;
}

struct MintParams {
    address to;
    address collection;
    uint24 quantity;
    bytes32[] merkleProof;
    uint8 phaseId;
}

struct Phase {
    uint256 from;
    uint256 to;
    uint24 maxPerAddress;
    uint256 price;
    bytes32 merkleRoot;
    address token;
    uint256 minToken;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

abstract contract Ownable {
    event OwnershipTransferred(address indexed user, address indexed newOwner);

    error Unauthorized();
    error InvalidOwner();

    address public owner;

    modifier onlyOwner() virtual {
        if (msg.sender != owner) revert Unauthorized();

        _;
    }

    function transferOwnership(address _owner) public virtual onlyOwner {
        if (_owner == address(0)) revert InvalidOwner();

        owner = _owner;

        emit OwnershipTransferred(msg.sender, _owner);
    }

    function revokeOwnership() public virtual onlyOwner {
        owner = address(0);

        emit OwnershipTransferred(msg.sender, address(0));
    }
}

abstract contract ERC721Receiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721Receiver.onERC721Received.selector;
    }
}

/// @notice ERC404
///         A gas-efficient, mixed ERC20 / ERC721 implementation
///         with native liquidity and fractionalization.
///
///         This is an experimental standard designed to integrate
///         with pre-existing ERC20 / ERC721 support as smoothly as
///         possible.
///
/// @dev    In order to support full functionality of ERC20 and ERC721
///         supply assumptions are made that slightly constraint usage.
///         Ensure decimals are sufficiently large (standard 18 recommended)
///         as ids are effectively encoded in the lowest range of amounts.
///
///         NFTs are spent on ERC20 functions in a FILO queue, this is by
///         design.
///
abstract contract ERC404 is Ownable {
    // Events
    event ERC20Transfer(
        address indexed from,
        address indexed to,
        uint256 amount
    );
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed id
    );
    event ERC721Approval(
        address indexed owner,
        address indexed spender,
        uint256 indexed id
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    // Errors
    error NotFound();
    error AlreadyExists();
    error InvalidRecipient();
    error InvalidSender();
    error UnsafeRecipient();

    // Metadata
    /// @dev Token name
    string public name;

    /// @dev Token symbol
    string public symbol;

    /// @dev Decimals for fractional representation. Immutable after initialization
    uint8 public decimals;

    /// @dev Total supply in fractionalized representation. Immutable after initialization
    uint256 public totalSupply;

    /// @dev Current mint counter, monotonically increasing to ensure accurate ownership
    uint256 public minted;

    // Mappings
    /// @dev Balance of user in fractional representation
    mapping(address => uint256) public balanceOf;

    /// @dev Allowance of user in fractional representation
    mapping(address => mapping(address => uint256)) public allowance;

    /// @dev Approval in native representaion
    mapping(uint256 => address) public getApproved;

    /// @dev Approval for all in native representation
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /// @dev Owner of id in native representation
    mapping(uint256 => address) internal _ownerOf;

    /// @dev Array of owned ids in native representation
    mapping(address => uint256[]) internal _owned;

    /// @dev Tracks indices for the _owned mapping
    mapping(uint256 => uint256) internal _ownedIndex;

    /// @dev Addresses whitelisted from minting / burning for gas savings (pairs, routers, etc)
    mapping(address => bool) public whitelist;

    // Constructor
    function _init(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalNativeSupply,
        address _owner
    ) internal {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalNativeSupply * (10 ** decimals);

        if (_owner == address(0)) revert InvalidOwner();

        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /// @notice Initialization function to set pairs / etc
    ///         saving gas by avoiding mint / burn on unnecessary targets
    function setWhitelist(address target, bool state) public onlyOwner {
        whitelist[target] = state;
    }

    /// @notice Function to find owner of a given native token
    function ownerOf(uint256 id) public view virtual returns (address owner) {
        owner = _ownerOf[id];

        if (owner == address(0)) {
            revert NotFound();
        }
    }

    /// @notice tokenURI must be implemented by child contract
    function tokenURI(uint256 id) public view virtual returns (string memory);

    /// @notice Function for token approvals
    /// @dev This function assumes id / native if amount less than or equal to current max id
    function approve(
        address spender,
        uint256 amountOrId
    ) public virtual returns (bool) {
        if (amountOrId <= minted && amountOrId > 0) {
            address owner = _ownerOf[amountOrId];

            if (msg.sender != owner && !isApprovedForAll[owner][msg.sender]) {
                revert Unauthorized();
            }

            getApproved[amountOrId] = spender;

            emit Approval(owner, spender, amountOrId);
        } else {
            allowance[msg.sender][spender] = amountOrId;

            emit Approval(msg.sender, spender, amountOrId);
        }

        return true;
    }

    /// @notice Function native approvals
    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice Function for mixed transfers
    /// @dev This function assumes id / native if amount less than or equal to current max id
    function transferFrom(
        address from,
        address to,
        uint256 amountOrId
    ) public virtual {
        if (amountOrId <= minted) {
            if (from != _ownerOf[amountOrId]) {
                revert InvalidSender();
            }

            if (to == address(0)) {
                revert InvalidRecipient();
            }

            if (
                msg.sender != from &&
                !isApprovedForAll[from][msg.sender] &&
                msg.sender != getApproved[amountOrId]
            ) {
                revert Unauthorized();
            }

            balanceOf[from] -= _getUnit();

            unchecked {
                balanceOf[to] += _getUnit();
            }

            _ownerOf[amountOrId] = to;
            delete getApproved[amountOrId];

            // update _owned for sender
            uint256 updatedId = _owned[from][_owned[from].length - 1];
            _owned[from][_ownedIndex[amountOrId]] = updatedId;
            // pop
            _owned[from].pop();
            // update index for the moved id
            _ownedIndex[updatedId] = _ownedIndex[amountOrId];
            // push token to to owned
            _owned[to].push(amountOrId);
            // update index for to owned
            _ownedIndex[amountOrId] = _owned[to].length - 1;

            emit Transfer(from, to, amountOrId);
            emit ERC20Transfer(from, to, _getUnit());
        } else {
            uint256 allowed = allowance[from][msg.sender];

            if (allowed != type(uint256).max)
                allowance[from][msg.sender] = allowed - amountOrId;

            _transfer(from, to, amountOrId);
        }
    }

    /// @notice Function for fractional transfers
    function transfer(
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        return _transfer(msg.sender, to, amount);
    }

    /// @notice Function for native transfers with contract support
    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        if (
            to.code.length != 0 &&
            ERC721Receiver(to).onERC721Received(msg.sender, from, id, "") !=
            ERC721Receiver.onERC721Received.selector
        ) {
            revert UnsafeRecipient();
        }
    }

    /// @notice Function for native transfers with contract support and callback data
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        if (
            to.code.length != 0 &&
            ERC721Receiver(to).onERC721Received(msg.sender, from, id, data) !=
            ERC721Receiver.onERC721Received.selector
        ) {
            revert UnsafeRecipient();
        }
    }

    /// @notice Internal function for fractional transfers
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        uint256 unit = _getUnit();
        uint256 balanceBeforeSender = balanceOf[from];
        uint256 balanceBeforeReceiver = balanceOf[to];

        balanceOf[from] -= amount;

        unchecked {
            balanceOf[to] += amount;
        }

        // Skip burn for certain addresses to save gas
        if (!whitelist[from]) {
            uint256 tokens_to_burn = (balanceBeforeSender / unit) -
                (balanceOf[from] / unit);
            for (uint256 i = 0; i < tokens_to_burn; i++) {
                _burn(from);
            }
        }

        // Skip minting for certain addresses to save gas
        if (!whitelist[to]) {
            uint256 tokens_to_mint = (balanceOf[to] / unit) -
                (balanceBeforeReceiver / unit);
            for (uint256 i = 0; i < tokens_to_mint; i++) {
                _mint(to);
            }
        }

        emit ERC20Transfer(from, to, amount);
        return true;
    }

    // Internal utility logic
    function _getUnit() internal view returns (uint256) {
        return 10 ** decimals;
    }

    function _mint(address to) internal virtual {
        if (to == address(0)) {
            revert InvalidRecipient();
        }

        unchecked {
            minted++;
        }

        uint256 id = minted;

        if (_ownerOf[id] != address(0)) {
            revert AlreadyExists();
        }

        _ownerOf[id] = to;
        _owned[to].push(id);
        _ownedIndex[id] = _owned[to].length - 1;

        emit Transfer(address(0), to, id);
    }

    function _burn(address from) internal virtual {
        if (from == address(0)) {
            revert InvalidSender();
        }

        uint256 id = _owned[from][_owned[from].length - 1];
        _owned[from].pop();
        delete _ownedIndex[id];
        delete _ownerOf[id];
        delete getApproved[id];

        emit Transfer(from, address(0), id);
    }

    function _setNameSymbol(
        string memory _name,
        string memory _symbol
    ) internal {
        name = _name;
        symbol = _symbol;
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