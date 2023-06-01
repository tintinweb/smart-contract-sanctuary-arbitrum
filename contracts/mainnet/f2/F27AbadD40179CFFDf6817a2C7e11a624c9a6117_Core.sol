// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
pragma solidity 0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICore.sol";

contract Core is ICore, Ownable, ReentrancyGuard {
    uint256 public constant DIVIDER = 1 ether;
    uint256 public constant CANCELATION_PERIOD = 15 minutes; // TODO: need set production value

    ICoreConfiguration.ImmutableConfiguration private _immutableConfiguration;
    Counters private _counters;
    mapping(uint256 => Position) private _positions;
    mapping(uint256 => Order) private _orders;

    ICoreConfiguration public immutable configuration;
    address public immutable permitPeriphery;
    mapping(uint256 => uint256) public positionIdToOrderId;
    mapping(address => uint256[]) public creatorToOrders;
    mapping(uint256 => uint256[]) public orderIdToPositions;

    function counters() external view returns (Counters memory) {
        return _counters;
    }

    function creatorOrdersCount(address creator) external view returns (uint256) {
        return creatorToOrders[creator].length;
    }

    function availableFeeAmount() public view returns (uint256) {
        return _immutableConfiguration.stable.balanceOf(address(this)) - _counters.totalStableAmount;
    }

    function orderIdPositionsCount(uint256 orderId) external view returns (uint256) {
        return orderIdToPositions[orderId].length;
    }

    function positions(uint256 id) external view returns (Position memory) {
        return _positions[id];
    }

    function orders(uint256 id) external view returns (Order memory) {
        return _orders[id];
    }

    constructor(address configuration_, address permitPeriphery_) {
        require(configuration_ != address(0), "Core: Configuration is zero address");
        require(permitPeriphery_ != address(0), "Core: PermitPeriphery is zero address");
        configuration = ICoreConfiguration(configuration_);
        (
            IFoxifyBlacklist blacklist,
            IFoxifyAffiliation affiliation,
            IPositionToken positionTokenAccepter,
            IERC20Stable stable
        ) = configuration.immutableConfiguration();
        _immutableConfiguration = ICoreConfiguration.ImmutableConfiguration(
            blacklist,
            affiliation,
            positionTokenAccepter,
            stable
        );
        permitPeriphery = permitPeriphery_;
    }

    function accept(
        address accepter,
        uint256 orderId,
        uint256 amount
    ) external nonReentrant notBlacklisted(accepter) returns (uint256 positionId) {
        if (msg.sender != permitPeriphery) accepter = msg.sender;
        ICoreConfiguration configuration_ = configuration;
        require(orderId > 0 && orderId <= _counters.ordersCount, "Core: Invalid order id");
        (uint256 minStableAmount,,,,) = configuration_.limitsConfiguration();
        require(amount > minStableAmount, "Core: Amount lt min value");
        Order storage order_ = _orders[orderId];
        require(!order_.closed, "Core: Order is closed");
        require(configuration_.oraclesWhitelistContains(order_.data.oracle), "Core: Oracle not whitelisted");
        Counters storage counters_ = _counters;
        counters_.positionsCount++;
        positionId = counters_.positionsCount;
        positionIdToOrderId[positionId] = orderId;
        orderIdToPositions[orderId].push(positionId);
        Position storage position_ = _positions[positionId];
        position_.startTime = block.timestamp;
        position_.endTime = block.timestamp + order_.data.duration;
        IOracleConnector oracle_ = IOracleConnector(order_.data.oracle);
        require(oracle_.validateTimestamp(position_.endTime), "Core: Position end time not supported");
        position_.startPrice = oracle_.getPrice();
        (,,position_.protocolFee,) = configuration_.feeConfiguration();
        position_.amountAccepter = amount;
        position_.amountCreator = (amount * order_.data.rate) / DIVIDER;
        position_.status = PositionStatus.PENDING;
        position_.deviationPrice = (position_.startPrice * order_.data.percent) / DIVIDER;
        require(position_.amountCreator <= order_.available, "Core: Insufficient creator balance");
        order_.available -= position_.amountCreator;
        order_.reserved += position_.amountCreator;
        counters_.totalStableAmount += amount;
        _immutableConfiguration.stable.transferFrom(msg.sender, address(this), amount);
        _immutableConfiguration.positionTokenAccepter.mint(accepter, positionId);
        emit Accepted(orderId, positionId, order_, position_, amount);
    }

    function autoResolve(uint256 positionId) external returns (bool) {
        require(configuration.keepersContains(msg.sender), "Core: Caller is not keeper");
        require(positionId > 0 && positionId <= _counters.positionsCount, "Core: Invalid position id");
        Order storage order_ = _orders[positionIdToOrderId[positionId]];
        Position storage position_ = _positions[positionId];
        require(position_.status == PositionStatus.PENDING, "Core: Auto resolve completed");
        require(position_.endTime <= block.timestamp, "Core: Position is active");
        position_.endPrice = IOracleConnector(order_.data.oracle).getPrice();
        address creator = order_.creator;
        address accepter = _immutableConfiguration.positionTokenAccepter.ownerOf(positionId);
        uint256 protocolStableFee = 0;
        uint256 autoResolveFee = 0;
        uint256 amountCreator = 0;
        uint256 amountAccepter = 0;
        order_.reserved -= position_.amountCreator;
        if (
            position_.endTime + CANCELATION_PERIOD <= block.timestamp
            || !configuration.oraclesWhitelistContains(order_.data.oracle)
        ) {
            order_.available += position_.amountCreator;
            amountAccepter = position_.amountAccepter;
            _counters.totalStableAmount -= amountAccepter;
            position_.status = PositionStatus.CANCELED;
        } else {
            uint256 gain = 0;
            if (
                (order_.data.direction == OrderDirectionType.UP && position_.endPrice >= position_.deviationPrice) ||
                (order_.data.direction == OrderDirectionType.DOWN && position_.endPrice <= position_.deviationPrice)
            ) {
                position_.winner = creator;
                gain = position_.amountAccepter;
            } else {
                position_.winner = accepter;
                gain = position_.amountCreator;
            }
            autoResolveFee = _swap(msg.sender, gain);
            protocolStableFee = _calculateStableFee(position_.winner, gain, position_.protocolFee);
            uint256 residual = gain - autoResolveFee;
            if (residual < protocolStableFee) protocolStableFee = residual;
            uint256 totalStableFee = protocolStableFee + autoResolveFee;
            _counters.totalStableAmount -= totalStableFee;
            gain -= totalStableFee;
            position_.status = PositionStatus.EXECUTED;
            if (position_.winner == creator) {
                order_.available += position_.amountCreator;
                if (gain > 0) {
                    if (order_.data.reinvest) {
                        order_.amount += gain;
                        order_.available += gain;
                    } else {
                        _counters.totalStableAmount -= gain;
                        amountCreator = gain;
                    }
                }
            } else {
                uint256 total = position_.amountAccepter + gain;
                order_.amount -= position_.amountCreator;
                _counters.totalStableAmount -= total;
                amountAccepter = total;
            }
        }
        _immutableConfiguration.positionTokenAccepter.burn(positionId);
        if (amountCreator > 0) _immutableConfiguration.stable.transfer(creator, amountCreator);
        if (amountAccepter > 0) _immutableConfiguration.stable.transfer(accepter, amountAccepter);
        emit AutoResolved(
            positionIdToOrderId[positionId],
            positionId,
            position_.winner,
            protocolStableFee,
            autoResolveFee
        );
        return true;
    }

    function closeOrder(uint256 orderId) external returns (bool) {
        require(orderId > 0 && orderId <= _counters.ordersCount, "Core: Invalid order id");
        Order storage order_ = _orders[orderId];
        require(order_.creator == msg.sender, "Core: Caller is not creator");
        order_.closed = true;
        emit OrderClosed(orderId, order_);
        return true;
    }

    function claimFee(uint256 amount) external onlyOwner returns (bool) {
        IERC20Stable stable_ = _immutableConfiguration.stable;
        require(amount <= availableFeeAmount(), "Core: Amount gt available");
        (address feeRecipient,,,) = configuration.feeConfiguration();
        stable_.transfer(feeRecipient, amount);
        emit FeeClaimed(amount);
        return true;
    }

    function createOrder(
        address creator,
        OrderDescription memory data,
        uint256 amount
    ) external nonReentrant notBlacklisted(creator) returns (uint256 orderId) {
        if (msg.sender != permitPeriphery) creator = msg.sender;
        ICoreConfiguration configuration_ = configuration;
        (
            ,uint256 minOrderRate,
            uint256 maxOrderRate,
            uint256 minDuration,
            uint256 maxDuration
        ) = configuration_.limitsConfiguration();
        require(data.rate >= minOrderRate && data.rate <= maxOrderRate, "Core: Position rate is invalid");
        require(data.duration >= minDuration && data.duration <= maxDuration, "Core: Duration is invalid");
        require(configuration_.oraclesWhitelistContains(data.oracle), "Core: Oracle not whitelisted");
        if (data.direction == OrderDirectionType.DOWN) require(data.percent < DIVIDER, "Core: Percent gt DIVIDER");
        else require(data.percent > DIVIDER, "Core: Percent lt DIVIDER");
        Counters storage counters_ = _counters;
        counters_.ordersCount++;
        orderId = counters_.ordersCount;
        Order storage order_ = _orders[orderId];
        order_.data = data;
        order_.creator = creator;
        order_.amount = amount;
        order_.available = amount;
        creatorToOrders[creator].push(orderId);
        counters_.totalStableAmount += amount;
        if (amount > 0) _immutableConfiguration.stable.transferFrom(msg.sender, address(this), amount);
        emit OrderCreated(orderId, order_);
    }

    function flashloan(
        address recipient,
        uint256 amount,
        bytes calldata data
    ) external nonReentrant notBlacklisted(msg.sender) returns (bool) {
        IERC20Stable stable = _immutableConfiguration.stable;
        uint256 balanceBefore = stable.balanceOf(address(this));
        require(amount > 0 && amount <= balanceBefore, "Core: Invalid amount");
        (,,,uint256 flashloanFee) = configuration.feeConfiguration();
        uint256 fee = _calculateStableFee(msg.sender, amount, flashloanFee);
        stable.transfer(recipient, amount);
        IOptionsFlashCallback(msg.sender).optionsFlashCallback(recipient, amount, fee, data);
        uint256 balanceAfter = stable.balanceOf(address(this));
        require(balanceBefore + fee <= balanceAfter, "Core: Invalid stable balance");
        emit Flashloan(msg.sender, recipient, amount, balanceAfter - balanceBefore);
        return true;
    }

    function increaseOrder(
        uint256 orderId,
        uint256 amount
    ) external nonReentrant notBlacklisted(msg.sender) returns (bool) {
        Counters storage counters_ = _counters;
        require(orderId > 0 && orderId <= counters_.ordersCount, "Core: Invalid order id");
        require(amount > 0, "Core: Amount is not positive");
        Order storage order_ = _orders[orderId];
        require(msg.sender == order_.creator, "Core: Caller is not creator");
        require(!order_.closed, "Core: Order is closed");
        order_.amount += amount;
        order_.available += amount;
        counters_.totalStableAmount += amount;
        _immutableConfiguration.stable.transferFrom(msg.sender, address(this), amount);
        emit OrderIncreased(orderId, amount);
        return true;
    }

    function withdrawOrder(uint256 orderId, uint256 amount) external nonReentrant returns (bool) {
        Counters storage counters_ = _counters;
        require(orderId > 0 && orderId <= counters_.ordersCount, "Core: Invalid order id");
        require(amount > 0, "Core: Amount is not positive");
        Order storage order_ = _orders[orderId];
        require(msg.sender == order_.creator, "Core: Caller is not creator");
        require(amount <= order_.available, "Core: Amount gt available");
        order_.amount -= amount;
        order_.available -= amount;
        counters_.totalStableAmount -= amount;
        _immutableConfiguration.stable.transfer(msg.sender, amount);
        emit OrderWithdrawal(orderId, amount);
        return true;
    }

    function _calculateStableFee(
        address affiliationUser,
        uint256 amount,
        uint256 fee
    ) private view returns (uint256) {
        IFoxifyAffiliation affiliation = _immutableConfiguration.affiliation;
        (uint256 bronze, uint256 silver, uint256 gold) = configuration.discount();
        AffiliationUserData memory affiliationUserData_;
        affiliationUserData_.activeId = affiliation.usersActiveID(affiliationUser);
        affiliationUserData_.team = affiliation.usersTeam(affiliationUser);
        affiliationUserData_.nftData = affiliation.data(affiliationUserData_.activeId);
        IFoxifyAffiliation.Level level = affiliationUserData_.nftData.level;
        if (level == IFoxifyAffiliation.Level.BRONZE) {
            affiliationUserData_.discount = bronze;
        } else if (level == IFoxifyAffiliation.Level.SILVER) {
            affiliationUserData_.discount = silver;
        } else if (level == IFoxifyAffiliation.Level.GOLD) {
            affiliationUserData_.discount = gold;
        }
        uint256 stableFee = (amount * fee) / DIVIDER;
        uint256 discount_ = (affiliationUserData_.discount * stableFee) / DIVIDER;
        return stableFee - discount_;
    }

    function _swap(address recipient, uint256 winnerTotalAmount) private returns (uint256 amountIn) {
        (ISwapperConnector swapperConnector, bytes memory path) = configuration.swapper();
        IERC20Stable stable = _immutableConfiguration.stable;
        (, uint256 autoResolveFee_,,) = configuration.feeConfiguration();
        amountIn = swapperConnector.getAmountIn(path, autoResolveFee_);
        if (amountIn > winnerTotalAmount) amountIn = winnerTotalAmount;
        stable.approve(address(swapperConnector), amountIn);
        swapperConnector.swap(path, address(stable), amountIn, recipient);
    }

    modifier notBlacklisted(address user) {
        require(_immutableConfiguration.blacklist.blacklistContains(user), "Core: Address blacklisted");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IFoxifyAffiliation.sol";
import "./ICoreConfiguration.sol";
import "./IOracleConnector.sol";
import "./IOptionsFlashCallback.sol";

interface ICore {
    enum PositionStatus {
        PENDING,
        EXECUTED,
        CANCELED
    }

    enum OrderDirectionType {
        UP,
        DOWN
    }

    struct AffiliationUserData {
        uint256 activeId;
        uint256 team;
        uint256 discount;
        IFoxifyAffiliation.NFTData nftData;
    }

    struct Counters {
        uint256 ordersCount;
        uint256 positionsCount;
        uint256 totalStableAmount;
    }

    struct Order {
        OrderDescription data;
        address creator;
        uint256 amount;
        uint256 reserved;
        uint256 available;
        bool closed;
    }

    struct OrderDescription {
        address oracle;
        uint256 percent;
        OrderDirectionType direction;
        uint256 rate;
        uint256 duration;
        bool reinvest;
    }

    struct Position {
        uint256 startTime;
        uint256 endTime;
        uint256 startPrice;
        uint256 endPrice;
        uint256 deviationPrice;
        uint256 protocolFee;
        uint256 amountCreator;
        uint256 amountAccepter;
        address winner;
        PositionStatus status;
    }

    function configuration() external view returns (ICoreConfiguration);
    function positionIdToOrderId(uint256) external view returns (uint256);
    function creatorToOrders(address, uint256) external view returns (uint256);
    function orderIdToPositions(uint256, uint256) external view returns (uint256);
    function counters() external view returns (Counters memory);
    function creatorOrdersCount(address creator) external view returns (uint256);
    function orderIdPositionsCount(uint256 orderId) external view returns (uint256);
    function positions(uint256 id) external view returns (Position memory);
    function orders(uint256 id) external view returns (Order memory);
    function availableFeeAmount() external view returns (uint256);
    function permitPeriphery() external view returns (address);

    event Accepted(
        uint256 indexed orderId,
        uint256 indexed positionId,
        Order order,
        Position position,
        uint256 amount
    );
    event AutoResolved(
        uint256 indexed orderId,
        uint256 indexed positionId,
        address indexed winner,
        uint256 protocolStableFee,
        uint256 autoResolveFee
    );
    event OrderCreated(uint256 orderId, Order order);
    event OrderClosed(uint256 orderId, Order order);
    event Flashloan(
        address indexed caller,
        address indexed receiver,
        uint256 amount,
        uint256 fee
    );
    event FeeClaimed(uint256 amount);
    event OrderIncreased(uint256 indexed orderId, uint256 amount);
    event OrderWithdrawal(uint256 indexed orderId, uint256 amount);

    function accept(address accepter, uint256 orderId, uint256 amount) external returns (uint256 positionId);
    function autoResolve(uint256 positionId) external returns (bool);
    function closeOrder(uint256 orderId) external returns (bool);
    function createOrder(address creator, OrderDescription memory data, uint256 amount) external returns (uint256 orderId);
    function flashloan(address recipient, uint256 amount, bytes calldata data) external returns (bool);
    function increaseOrder(uint256 orderId, uint256 amount) external returns (bool);
    function withdrawOrder(uint256 orderId, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IERC20Stable.sol";
import "./IPositionToken.sol";
import "./IFoxifyAffiliation.sol";
import "./IFoxifyBlacklist.sol";
import "./ISwapperConnector.sol";

interface ICoreConfiguration {
    struct FeeConfiguration {
        address feeRecipient;
        uint256 autoResolveFee;
        uint256 protocolFee;
        uint256 flashloanFee;
    }

    struct ImmutableConfiguration {
        IFoxifyBlacklist blacklist;
        IFoxifyAffiliation affiliation;
        IPositionToken positionTokenAccepter;
        IERC20Stable stable;
    }

    struct LimitsConfiguration {
        uint256 minStableAmount;
        uint256 minOrderRate;
        uint256 maxOrderRate;
        uint256 minDuration;
        uint256 maxDuration;
    }

    struct NFTDiscountLevel {
        uint256 bronze;
        uint256 silver;
        uint256 gold;
    }

    struct Swapper {
        ISwapperConnector swapperConnector;
        bytes path;
    }

    function discount() external view returns (uint256 bronze, uint256 silver, uint256 gold);
    function feeConfiguration() external view returns (
        address feeRecipient,
        uint256 autoResolveFee,
        uint256 protocolFee,
        uint256 flashloanFee
    );
    function immutableConfiguration() external view returns (
        IFoxifyBlacklist blacklist,
        IFoxifyAffiliation affiliation,
        IPositionToken positionTokenAccepter,
        IERC20Stable stable
    );
    function keepers(uint256 index) external view returns (address);
    function keepersCount() external view returns (uint256);
    function keepersContains(address keeper) external view returns (bool);
    function limitsConfiguration() external view returns (
        uint256 minStableAmount,
        uint256 minOrderRate,
        uint256 maxOrderRate,
        uint256 minDuration,
        uint256 maxDuration
    );
    function oracles(uint256 index) external view returns (address);
    function oraclesCount() external view returns (uint256);
    function oraclesContains(address oracle) external view returns (bool);
    function oraclesWhitelist(uint256 index) external view returns (address);
    function oraclesWhitelistCount() external view returns (uint256);
    function oraclesWhitelistContains(address oracle) external view returns (bool);
    function swapper() external view returns (ISwapperConnector swapperConnector, bytes memory path);

    event DiscountUpdated(NFTDiscountLevel discount_);
    event FeeConfigurationUpdated(FeeConfiguration config);
    event KeepersAdded(address[] keepers);
    event KeepersRemoved(address[] keepers);
    event LimitsConfigurationUpdated(LimitsConfiguration config);
    event OraclesAdded(address[] oracles);
    event OraclesRemoved(address[] oracles);
    event OraclesWhitelistRemoved(address[] oracles);
    event SwapperUpdated(Swapper swapper);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

interface IERC20Stable is IERC20, IERC20Permit {}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IFoxifyAffiliation {
    enum Level {
        UNKNOWN,
        BRONZE,
        SILVER,
        GOLD
    }

    struct NFTData {
        Level level;
        bytes32 randomValue;
        uint256 timestamp;
    }

    function data(uint256) external view returns (NFTData memory);
    function usersActiveID(address) external view returns (uint256);
    function usersTeam(address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IFoxifyBlacklist {
    function blacklist(uint256 index) external view returns (address);
    function blacklistCount() external view returns (uint256);
    function blacklistContains(address wallet) external view returns (bool);
    function blacklistList(uint256 offset, uint256 limit) external view returns (address[] memory output);

    event Blacklisted(address[] wallets);
    event Unblacklisted(address[] wallets);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IOptionsFlashCallback {
    function optionsFlashCallback(address account, uint256 amount, uint256 fee, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IOracleConnector {
    function name() external view returns (string memory);
    function decimals() external view returns (uint256);
    function validateTimestamp(uint256) external view returns (bool);
    function getPrice() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IPositionToken is IERC721Metadata {
    function burn(uint256 id) external returns (bool);
    function mint(address account, uint256 id) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ISwapperConnector {
    function getAmountIn(bytes memory path, uint256 amountOut) external returns (uint256 amountIn);

    event Swapped(address indexed recipient, address indexed tokenIn, uint256 amountIn, uint256 amountOut);

    function swap(
        bytes memory path,
        address tokenIn,
        uint256 amountIn,
        address recipient
    ) external returns (uint256 amountOut);
}