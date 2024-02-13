// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
pragma abicoder v2;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MintParams} from "../structs/erc404/ERC404Structs.sol";
import "../interfaces/IOmniseaERC404.sol";
import "../interfaces/IOmniseaERC404Factory.sol";

contract OmniseaERC404Manager is ReentrancyGuard {
    event Minted(address collection, address minter, uint256 quantity, uint256 value);

    uint256 public fixedFee;
    uint256 public dynamicFee;
    IERC20 public osea;
    mapping (address => uint256) public collectionsOsea; // Overrides the "dynamicFee" if >= "minOseaPerCollection" OSEA present per Collection
    mapping (address => uint256) public collectionsOseaPerToken;
    uint256 public minOseaPerCollection;
    bool public isOseaEnabled;
    address private _revenueManager;
    address private _owner;
    bool private _isPaused;
    IOmniseaERC404Factory private _factory;

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    constructor(address factory_) {
        _owner = msg.sender;
        _revenueManager = address(0x61104fBe07ecc735D8d84422c7f045f8d29DBf15);
        _factory = IOmniseaERC404Factory(factory_);
        dynamicFee = 0;
        fixedFee = 150000000000000;
    }

    function setOSEA(address _osea, uint256 _minOseaPerCollection, bool _isEnabled) external onlyOwner {
        if (address(osea) == address(0)) {
            osea = IERC20(_osea);
        }
        minOseaPerCollection = _minOseaPerCollection;
        isOseaEnabled = _isEnabled;
    }

    function setFee(uint256 fee_) external onlyOwner {
        require(fee_ <= 20);
        dynamicFee = fee_;
    }

    function setFixedFee(uint256 fee_) external onlyOwner {
        fixedFee = fee_;
    }

    function setRevenueManager(address _manager) external onlyOwner {
        _revenueManager = _manager;
    }

    function addOseaToCollection(address _collection, uint256 _oseaAmount, uint256 _oseaAmountPerToken) external {
        require(isOseaEnabled && _factory.drops(_collection));
        require(_oseaAmount > 0 && _oseaAmountPerToken > 0);
        uint256 collectionOsea = collectionsOsea[_collection];
        require(collectionOsea + _oseaAmount >= minOseaPerCollection);

        // If the collections already has added OSEA, only the owner can modify "collectionsOseaPerToken"
        if (collectionOsea > 0 && collectionsOseaPerToken[_collection] != _oseaAmountPerToken) {
            IOmniseaERC404 collection = IOmniseaERC404(_collection);
            require(msg.sender == collection.collectionOwner());
        }

        uint256 addAmount = _oseaAmount * 95 / 100;
        uint256 burnAmount = _oseaAmount - addAmount;
        require(osea.transferFrom(msg.sender, address(this), addAmount));
        require(osea.transferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), burnAmount));
        collectionsOsea[_collection] += addAmount;
        require(_oseaAmountPerToken <= collectionsOsea[_collection], ">oseaAmountPerToken");
        collectionsOseaPerToken[_collection] = _oseaAmountPerToken;
    }

    function mint(MintParams calldata _params) external payable nonReentrant {
        require(!_isPaused);
        require(_factory.drops(_params.collection));
        IOmniseaERC404 collection = IOmniseaERC404(_params.collection);
        address recipient = _params.to;

        uint256 price = collection.mintPrice(_params.phaseId);
        uint256 quantityPrice = price * _params.quantity;
        require(msg.value == quantityPrice + fixedFee, "!=price");

        uint256 collectionOsea = collectionsOsea[_params.collection];
        uint256 dynamicFee_ = dynamicFee;
        if (isOseaEnabled && collectionOsea > 0) {
            dynamicFee_ = 0;
            uint256 totalOsea = collectionsOseaPerToken[_params.collection] * _params.quantity;
            uint256 oseaAmount = collectionOsea > totalOsea ? totalOsea : collectionOsea;
            osea.transfer(recipient, oseaAmount);
            collectionsOsea[_params.collection] -= oseaAmount;
        }

        if (quantityPrice > 0) {
            uint256 paidToOwner = quantityPrice * (100 - dynamicFee_) / 100;
            (bool p1,) = payable(collection.collectionOwner()).call{value: paidToOwner}("");
            require(p1, "!p1");

            (bool p2,) = payable(_revenueManager).call{value: msg.value - paidToOwner}("");
            require(p2, "!p2");
        } else {
            (bool p3,) = payable(_revenueManager).call{value: msg.value}("");
            require(p3, "!p3");
        }

        collection.mint(recipient, _params.quantity, _params.merkleProof, _params.phaseId);
        emit Minted(_params.collection, recipient, _params.quantity, msg.value);
    }

    function setPause(bool isPaused_) external onlyOwner {
        _isPaused = isPaused_;
    }

    function withdraw() external onlyOwner {
        (bool p,) = payable(_owner).call{value: address(this).balance}("");
        require(p, "!p");
    }

    receive() external payable {}
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

import {CreateParams} from "../structs/erc404/ERC404Structs.sol";

interface IOmniseaERC404Factory {
    function create(CreateParams calldata params) external;
    function drops(address) external returns (bool);
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