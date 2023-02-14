// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
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
pragma solidity ^0.8.0;

contract Governable {
    address public gov;
    event GovChange(address pre, address next);

    constructor() {
        gov = msg.sender;
        emit GovChange(address(0x0), msg.sender);
    }

    modifier onlyGov() {
        require(msg.sender == gov, "Governable: forbidden");
        _;
    }

    function setGov(address _gov) external onlyGov {
        emit GovChange(gov, _gov);
        gov = _gov;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRoleManager {
    function grantRole(address account, bytes32 key) external;

    function revokeRole(address account, bytes32 key) external;

    function hasRole(address account, bytes32 key) external view returns (bool);

    function getRoleCount() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Governable.sol";
import "./interfaces/IRoleManager.sol";

contract Roles {
    IRoleManager public roles;

    constructor(IRoleManager rs) {
        roles = rs;
    }

    modifier hasRole(bytes32 role) {
        require(roles.hasRole(msg.sender, role), "!role");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../interfaces/Types.sol";

interface ITrading {
    event OpenPostion(
        bytes32 orderId,
        address owner,
        bool isLong,
        uint16 pairId,
        uint16 leverage,
        uint32 timestamp,
        uint256 amount,
        uint256 tp,
        uint256 sl
    );

    event ClosePosition(bytes32 orderId, int256 pnl);

    function openPosition(Types.Order calldata order)
        external
        returns (bytes32);

    function openPositionGasLess(
        Types.Order calldata order,
        Types.GasLess calldata gasLess
    ) external returns (bytes32);

    function openLimitPosition(Types.OrderLimit calldata order)
        external
        returns (bytes32);

    function openPositionWithPermit(
        Types.Order calldata order,
        Types.Permit calldata permit
    ) external returns (bytes32);

    function openPositionGasLessWithPermit(
        Types.Order calldata order,
        Types.GasLess calldata gasLess,
        Types.Permit calldata permit
    ) external returns (bytes32);

    function openLimitPositionWithPermit(
        Types.OrderLimit calldata order,
        Types.Permit calldata permit
    ) external returns (bytes32);

    function closePositionBySelf(bytes32 orderId) external;

    function closePostion(bytes32 orderId, uint256 price) external;

    function selfLiquidatePosition(bytes32 orderId) external;

    function liquidatePositions(
        bytes32[] calldata orderIds,
        uint256[] calldata prices
    ) external;

    function updateLimit(
        bytes32 orderId,
        uint256 tp,
        uint256 sl
    ) external;

    function updateMargin(bytes32 orderId, uint256 leverage) external;

    function increasePosition(bytes32 orderId, uint256 price) external;

    function decreasePosition(bytes32 orderId, uint256 price) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "../access/Roles.sol";
import "../interfaces/Types.sol";
import "./interfaces/ITrading.sol";

interface IUSDC is IERC20, IERC20Permit {}

contract Trading is Roles, ERC2771Context, ITrading {
    //TODO Review all modifier
    //TODO edit all fee
    IUSDC immutable usdc;
    uint256 public openFee = 1000; //0,1% => 1=1e6
    uint256 public closeFee = 1000; //0,1% =>1=1e6
    uint256 public excutionFee = 2e5; //0.2 USDC
    uint256 public permitFee = 1e5; //O.1 USDC

    constructor(
        IRoleManager _roles,
        IUSDC _usdc,
        address _trustedForwarder
    ) Roles(_roles) ERC2771Context(_trustedForwarder) {
        usdc = _usdc;
    }

    function openPosition(Types.Order calldata order)
        external
        virtual
        override
        returns (bytes32)
    {
        return _openPosition(_msgSender(), order);
    }

    function openPositionGasLess(
        Types.Order calldata order,
        Types.GasLess calldata gasLess
    ) external virtual override returns (bytes32) {
        //TODO credit Fee excution
        //TODO validate gassLess & msgSender()
        return _openPosition(_msgSender(), order);
    }

    function openLimitPosition(Types.OrderLimit calldata order)
        external
        virtual
        override
        returns (bytes32)
    {
        //TODO convert Limit to Market
        Types.Order memory _order = Types.Order(
            order.isLong,
            order.pairId,
            order.leverage,
            order.amount,
            order.tp,
            order.sl
        );
        return _openPosition(_msgSender(), _order);
    }

    function openPositionWithPermit(
        Types.Order calldata order,
        Types.Permit calldata permit
    ) external virtual override returns (bytes32) {
        //TODO credit Permit fee
        usdc.permit(
            permit.owner,
            permit.spender,
            permit.value,
            permit.deadline,
            permit.v,
            permit.r,
            permit.s
        );
        return _openPosition(_msgSender(), order);
    }

    function openPositionGasLessWithPermit(
        Types.Order calldata order,
        Types.GasLess calldata gasLess,
        Types.Permit calldata permit
    ) external virtual override returns (bytes32) {
        //TODO credit Fee excution & permit
        //TODO validate gassLess & msgSender()
        usdc.permit(
            permit.owner,
            permit.spender,
            permit.value,
            permit.deadline,
            permit.v,
            permit.r,
            permit.s
        );
        return _openPosition(_msgSender(), order);
    }

    function openLimitPositionWithPermit(
        Types.OrderLimit calldata order,
        Types.Permit calldata permit
    ) external virtual override returns (bytes32) {
        //TODO credit Fee permit
        usdc.permit(
            permit.owner,
            permit.spender,
            permit.value,
            permit.deadline,
            permit.v,
            permit.r,
            permit.s
        );
        //TODO convert Limit to Market
        Types.Order memory _order = Types.Order(
            order.isLong,
            order.pairId,
            order.leverage,
            order.amount,
            order.tp,
            order.sl
        );
        return _openPosition(_msgSender(), _order);
    }

    function _openPosition(address owner, Types.Order memory order)
        internal
        returns (bytes32)
    {
        //TODO openPosition
        bytes32 orderId = keccak256(
            abi.encode(
                owner,
                order.isLong,
                order.pairId,
                order.leverage,
                block.timestamp
            )
        );
        emit OpenPostion(
            orderId,
            owner,
            order.isLong,
            order.pairId,
            order.leverage,
            uint32(block.timestamp),
            order.amount,
            order.tp,
            order.sl
        );
        return orderId;
    }

    function closePositionBySelf(bytes32 orderId) external virtual override {
        //TODO get price
        uint256 price = 1212;
        _excutePostion(orderId, price);
    }

    function closePostion(bytes32 orderId, uint256 price)
        external
        virtual
        override
    {
        _excutePostion(orderId, price);
    }

    function selfLiquidatePosition(bytes32 orderId) external virtual override {
        //TODO get price
        uint256 price = 1212;
        _excutePostion(orderId, price);
    }

    function liquidatePositions(
        bytes32[] calldata orderIds,
        uint256[] calldata prices
    ) external virtual override {
        require(orderIds.length == prices.length, "!length");
        for (uint256 i = 0; i < orderIds.length; i++) {
            _excutePostion(orderIds[i], prices[i]);
        }
    }

    function _excutePostion(bytes32 orderId, uint256 price) internal {
        //TODO not have pnl
        emit ClosePosition(orderId, 0);
    }

    function updateLimit(
        bytes32 orderId,
        uint256 tp,
        uint256 sl
    ) external virtual override {}

    function updateMargin(bytes32 orderId, uint256 leverage)
        external
        virtual
        override
    {}

    function increasePosition(bytes32 orderId, uint256 price)
        external
        virtual
        override
    {}

    function decreasePosition(bytes32 orderId, uint256 price)
        external
        virtual
        override
    {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface Types {
    struct Order {
        bool isLong;
        uint16 pairId;
        uint16 leverage;
        uint256 amount;
        uint256 tp;
        uint256 sl;
    }

    struct OrderLimit {
        bool isLong;
        uint8 orderType;
        uint16 pairId;
        uint16 leverage;
        uint32 expire;
        uint256 amount;
        uint256 limitPrice;
        uint256 tp;
        uint256 sl;
    }

    struct OrderStorage {
        address owner;
        bool isLong;
        uint16 pairId;
        uint16 leverage;
        uint256 entryPrice;
        uint256 amount;
    }

    struct GasLess {
        address owner;
        uint256 deadline;
        uint256 nonce;
        bytes signature;
    }

    struct Permit {
        address owner;
        address spender;
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
}