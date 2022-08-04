// SPDX-FileCopyrightText: 2022 Lido <[email protected]>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import {IERC20Bridged} from "../token/interfaces/IERC20Bridged.sol";
import {IL2TokenGateway, IInterchainTokenGateway} from "./interfaces/IL2TokenGateway.sol";

import {L2CrossDomainEnabled} from "./L2CrossDomainEnabled.sol";
import {L2OutboundDataParser} from "./libraries/L2OutboundDataParser.sol";
import {InterchainERC20TokenGateway} from "./InterchainERC20TokenGateway.sol";

/// @author psirex
/// @notice Contract implements ITokenGateway interface and with counterpart L1ERC20TokenGateway
///     allows bridging registered ERC20 compatible tokens between Arbitrum and Ethereum chains
contract L2ERC20TokenGateway is
    InterchainERC20TokenGateway,
    L2CrossDomainEnabled,
    IL2TokenGateway
{
    /// @param arbSys_ Address of the Arbitrum’s ArbSys contract in the L2 chain
    /// @param router_ Address of the router in the L2 chain
    /// @param counterpartGateway_ Address of the counterpart L1 gateway
    /// @param l1Token_ Address of the bridged token in the L1 chain
    /// @param l2Token_ Address of the token minted on the Arbitrum chain when token bridged
    constructor(
        address arbSys_,
        address router_,
        address counterpartGateway_,
        address l1Token_,
        address l2Token_
    )
        InterchainERC20TokenGateway(
            router_,
            counterpartGateway_,
            l1Token_,
            l2Token_
        )
        L2CrossDomainEnabled(arbSys_)
    {}

    /// @inheritdoc IL2TokenGateway
    function outboundTransfer(
        address l1Token_,
        address to_,
        uint256 amount_,
        uint256, // maxGas
        uint256, // gasPriceBid
        bytes calldata data_
    )
        external
        whenWithdrawalsEnabled
        onlySupportedL1Token(l1Token_)
        returns (bytes memory res)
    {
        address from = L2OutboundDataParser.decode(router, data_);

        IERC20Bridged(l2Token).bridgeBurn(from, amount_);

        uint256 id = sendCrossDomainMessage(
            from,
            counterpartGateway,
            getOutboundCalldata(l1Token_, from, to_, amount_, "")
        );

        // The current implementation doesn't support fast withdrawals, so we
        // always use 0 for the exitNum argument in the event
        emit WithdrawalInitiated(l1Token_, from, to_, id, 0, amount_);

        return abi.encode(id);
    }

    /// @inheritdoc IInterchainTokenGateway
    function finalizeInboundTransfer(
        address l1Token_,
        address from_,
        address to_,
        uint256 amount_,
        bytes calldata
    )
        external
        whenDepositsEnabled
        onlySupportedL1Token(l1Token_)
        onlyFromCrossDomainAccount(counterpartGateway)
    {
        IERC20Bridged(l2Token).bridgeMint(to_, amount_);

        emit DepositFinalized(l1Token_, from_, to_, amount_);
    }
}

// SPDX-FileCopyrightText: 2022 Lido <[email protected]>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @author psirex
/// @notice Extends the ERC20 functionality that allows the bridge to mint/burn tokens
interface IERC20Bridged is IERC20 {
    /// @notice Returns bridge which can mint and burn tokens on L2
    function bridge() external view returns (address);

    /// @notice Creates amount_ tokens and assigns them to account_, increasing the total supply
    /// @param account_ An address of the account to mint tokens
    /// @param amount_ An amount of tokens to mint
    function bridgeMint(address account_, uint256 amount_) external;

    /// @notice Destroys amount_ tokens from account_, reducing the total supply
    /// @param account_ An address of the account to burn tokens
    /// @param amount_ An amount of tokens to burn
    function bridgeBurn(address account_, uint256 amount_) external;
}

// SPDX-FileCopyrightText: 2022 Lido <[email protected]>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import {IInterchainTokenGateway} from "./IInterchainTokenGateway.sol";

/// @author psirex
/// @notice L2 part of the tokens bridge compatible with Arbitrum's GatewayRouter
interface IL2TokenGateway is IInterchainTokenGateway {
    /// @notice Initiates the withdrawing process from the Arbitrum chain into the Ethereum chain
    /// @param l1Token_ Address in the L1 chain of the token to withdraw
    /// @param to_ Address of the recipient of the token on the corresponding chain
    /// @param amount_ Amount of tokens to bridge
    /// @param data_ Additional data required for transaction
    function outboundTransfer(
        address l1Token_,
        address to_,
        uint256 amount_,
        uint256 maxGas_,
        uint256 gasPriceBid_,
        bytes calldata data_
    ) external returns (bytes memory);

    event DepositFinalized(
        address indexed l1Token,
        address indexed from,
        address indexed to,
        uint256 amount
    );

    event WithdrawalInitiated(
        address l1Token,
        address indexed from,
        address indexed to,
        uint256 indexed l2ToL1Id,
        uint256 exitNum,
        uint256 amount
    );
}

// SPDX-FileCopyrightText: 2022 Lido <[email protected]>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import {IArbSys} from "./interfaces/IArbSys.sol";

/// @author psirex
/// @notice A helper contract to simplify Arbitrum to Ethereum communication process
contract L2CrossDomainEnabled {
    uint160 private constant ADDRESS_OFFSET =
        uint160(0x1111000000000000000000000000000000001111);

    /// @notice Address of the Arbitrum’s ArbSys contract
    IArbSys public immutable arbSys;

    /// @param arbSys_ Address of the Arbitrum’s ArbSys contract
    constructor(address arbSys_) {
        arbSys = IArbSys(arbSys_);
    }

    /// @notice Sends the message to the Ethereum chain
    /// @param sender_ Address of the sender of the message
    /// @param recipient_ Address of the recipient of the message on the Ethereum chain
    /// @param data_ Data passed to the recipient in the message
    /// @return id Unique identifier for this L2-to-L1 transaction
    function sendCrossDomainMessage(
        address sender_,
        address recipient_,
        bytes memory data_
    ) internal returns (uint256 id) {
        id = IArbSys(arbSys).sendTxToL1(recipient_, data_);
        emit TxToL1(sender_, recipient_, id, data_);
    }

    /// @dev L1 addresses are transformed durng l1 -> l2 calls
    function applyL1ToL2Alias(address l1Address_)
        private
        pure
        returns (address l1Address)
    {
        unchecked {
            l1Address = address(uint160(l1Address_) + ADDRESS_OFFSET);
        }
    }

    /// @notice Validates that the sender address with applied Arbitrum's aliasing is equal to
    ///     the crossDomainAccount_ address
    modifier onlyFromCrossDomainAccount(address crossDomainAccount_) {
        if (msg.sender != applyL1ToL2Alias(crossDomainAccount_)) {
            revert ErrorWrongCrossDomainSender();
        }
        _;
    }

    event TxToL1(
        address indexed from,
        address indexed to,
        uint256 indexed id,
        bytes data
    );

    error ErrorWrongCrossDomainSender();
}

// SPDX-FileCopyrightText: 2022 Lido <[email protected]>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

/// @author psirex
/// @notice A helper library to parse data passed to outboundTransfer() of L2ERC20TokenGateway
library L2OutboundDataParser {
    /// @dev Decodes value contained in data_ bytes array and returns it
    /// @param router_ Address of the Arbitrum’s L2GatewayRouter
    /// @param data_ Data encoded for the outboundTransfer() method
    /// @return from_ address of the sender
    function decode(address router_, bytes memory data_)
        internal
        view
        returns (address from_)
    {
        bytes memory extraData;
        if (msg.sender == router_) {
            (from_, extraData) = abi.decode(data_, (address, bytes));
        } else {
            (from_, extraData) = (msg.sender, data_);
        }
        if (extraData.length != 0) {
            revert ExtraDataNotEmpty();
        }
    }

    error ExtraDataNotEmpty();
}

// SPDX-FileCopyrightText: 2022 Lido <[email protected]>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import {BridgingManager} from "../BridgingManager.sol";
import {BridgeableTokens} from "../BridgeableTokens.sol";

import {IInterchainTokenGateway} from "./interfaces/IInterchainTokenGateway.sol";

/// @author psirex
/// @notice The contract keeps logic shared among both L1 and L2 gateways, adding the methods for
///     bridging management: enabling and disabling withdrawals/deposits
abstract contract InterchainERC20TokenGateway is
    BridgingManager,
    BridgeableTokens,
    IInterchainTokenGateway
{
    /// @notice Address of the router in the corresponding chain
    address public immutable router;

    /// @inheritdoc IInterchainTokenGateway
    address public immutable counterpartGateway;

    /// @param router_ Address of the router in the corresponding chain
    /// @param counterpartGateway_ Address of the counterpart gateway used in the bridging process
    /// @param l1Token_ Address of the bridged token in the Ethereum chain
    /// @param l2Token_ Address of the token minted on the Arbitrum chain when token bridged
    constructor(
        address router_,
        address counterpartGateway_,
        address l1Token_,
        address l2Token_
    ) BridgeableTokens(l1Token_, l2Token_) {
        router = router_;
        counterpartGateway = counterpartGateway_;
    }

    /// @inheritdoc IInterchainTokenGateway
    /// @dev The current implementation returns the l2Token address when passed l1Token_ equals
    ///     to l1Token declared in the contract and address(0) in other cases
    function calculateL2TokenAddress(address l1Token_)
        external
        view
        returns (address)
    {
        if (l1Token_ == l1Token) {
            return l2Token;
        }
        return address(0);
    }

    /// @inheritdoc IInterchainTokenGateway
    function getOutboundCalldata(
        address l1Token_,
        address from_,
        address to_,
        uint256 amount_,
        bytes memory // data_
    ) public pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                IInterchainTokenGateway.finalizeInboundTransfer.selector,
                l1Token_,
                from_,
                to_,
                amount_,
                ""
            );
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

// SPDX-FileCopyrightText: 2022 Lido <[email protected]>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

/// @author psirex
/// @notice Keeps logic shared among both L1 and L2 gateways.
interface IInterchainTokenGateway {
    /// @notice Finalizes the bridging of the tokens between chains
    /// @param l1Token_ Address in the L1 chain of the token to withdraw
    /// @param from_ Address of the account initiated withdrawing
    /// @param to_ Address of the recipient of the tokens
    /// @param amount_ Amount of tokens to withdraw
    /// @param data_ Additional data required for the transaction
    function finalizeInboundTransfer(
        address l1Token_,
        address from_,
        address to_,
        uint256 amount_,
        bytes calldata data_
    ) external;

    /// @notice Calculates address of token, which will be minted on the Arbitrum chain,
    ///     on l1Token_ bridging
    /// @param l1Token_ Address of the token on the Ethereum chain
    /// @return Address of the token minted on the L2 on bridging
    function calculateL2TokenAddress(address l1Token_)
        external
        view
        returns (address);

    /// @notice Returns address of the counterpart gateway used in the bridging process
    function counterpartGateway() external view returns (address);

    /// @notice Returns encoded transaction data to send into the counterpart gateway to finalize
    ///     the tokens bridging process.
    /// @param l1Token_ Address in the Ethereum chain of the token to bridge
    /// @param from_ Address of the account initiated bridging in the current chain
    /// @param to_ Address of the recipient of the token in the counterpart chain
    /// @param amount_  Amount of tokens to bridge
    /// @param data_  Custom data to pass into finalizeInboundTransfer method
    /// @return Encoded transaction data of finalizeInboundTransfer call
    function getOutboundCalldata(
        address l1Token_,
        address from_,
        address to_,
        uint256 amount_,
        bytes memory data_
    ) external view returns (bytes memory);
}

// SPDX-FileCopyrightText: 2022 Lido <[email protected]>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

/// @title Precompiled contract that exists in every Arbitrum chain at address(100),
///     0x0000000000000000000000000000000000000064. Exposes a variety of system-level functionality
interface IArbSys {
    /// @notice Send a transaction to L1
    /// @param destination_ Recipient address on L1
    /// @param calldataForL1_ (optional) Calldata for L1 contract call
    /// @return Unique identifier for this L2-to-L1 transaction
    function sendTxToL1(address destination_, bytes calldata calldataForL1_)
        external
        payable
        returns (uint256);
}

// SPDX-FileCopyrightText: 2022 Lido <[email protected]>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/// @author psirex
/// @notice Contains administrative methods to retrieve and control the state of the bridging
contract BridgingManager is AccessControl {
    /// @dev Stores the state of the bridging
    /// @param isInitialized Shows whether the contract is initialized or not
    /// @param isDepositsEnabled Stores the state of the deposits
    /// @param isWithdrawalsEnabled Stores the state of the withdrawals
    struct State {
        bool isInitialized;
        bool isDepositsEnabled;
        bool isWithdrawalsEnabled;
    }

    bytes32 public constant DEPOSITS_ENABLER_ROLE =
        keccak256("BridgingManager.DEPOSITS_ENABLER_ROLE");
    bytes32 public constant DEPOSITS_DISABLER_ROLE =
        keccak256("BridgingManager.DEPOSITS_DISABLER_ROLE");
    bytes32 public constant WITHDRAWALS_ENABLER_ROLE =
        keccak256("BridgingManager.WITHDRAWALS_ENABLER_ROLE");
    bytes32 public constant WITHDRAWALS_DISABLER_ROLE =
        keccak256("BridgingManager.WITHDRAWALS_DISABLER_ROLE");

    /// @dev The location of the slot with State
    bytes32 private constant STATE_SLOT =
        keccak256("BridgingManager.bridgingState");

    /// @notice Initializes the contract to grant DEFAULT_ADMIN_ROLE to the admin_ address
    /// @dev This method might be called only once
    /// @param admin_ Address of the account to grant the DEFAULT_ADMIN_ROLE
    function initialize(address admin_) external {
        State storage s = _loadState();
        if (s.isInitialized) {
            revert ErrorAlreadyInitialized();
        }
        _setupRole(DEFAULT_ADMIN_ROLE, admin_);
        s.isInitialized = true;
        emit Initialized(admin_);
    }

    /// @notice Returns whether the contract is initialized or not
    function isInitialized() public view returns (bool) {
        return _loadState().isInitialized;
    }

    /// @notice Returns whether the deposits are enabled or not
    function isDepositsEnabled() public view returns (bool) {
        return _loadState().isDepositsEnabled;
    }

    /// @notice Returns whether the withdrawals are enabled or not
    function isWithdrawalsEnabled() public view returns (bool) {
        return _loadState().isWithdrawalsEnabled;
    }

    /// @notice Enables the deposits if they are disabled
    function enableDeposits() external onlyRole(DEPOSITS_ENABLER_ROLE) {
        if (isDepositsEnabled()) {
            revert ErrorDepositsEnabled();
        }
        _loadState().isDepositsEnabled = true;
        emit DepositsEnabled(msg.sender);
    }

    /// @notice Disables the deposits if they aren't disabled yet
    function disableDeposits()
        external
        whenDepositsEnabled
        onlyRole(DEPOSITS_DISABLER_ROLE)
    {
        _loadState().isDepositsEnabled = false;
        emit DepositsDisabled(msg.sender);
    }

    /// @notice Enables the withdrawals if they are disabled
    function enableWithdrawals() external onlyRole(WITHDRAWALS_ENABLER_ROLE) {
        if (isWithdrawalsEnabled()) {
            revert ErrorWithdrawalsEnabled();
        }
        _loadState().isWithdrawalsEnabled = true;
        emit WithdrawalsEnabled(msg.sender);
    }

    /// @notice Disables the withdrawals if they aren't disabled yet
    function disableWithdrawals()
        external
        whenWithdrawalsEnabled
        onlyRole(WITHDRAWALS_DISABLER_ROLE)
    {
        _loadState().isWithdrawalsEnabled = false;
        emit WithdrawalsDisabled(msg.sender);
    }

    /// @dev Returns the reference to the slot with State struct
    function _loadState() private pure returns (State storage r) {
        bytes32 slot = STATE_SLOT;
        assembly {
            r.slot := slot
        }
    }

    /// @dev Validates that deposits are enabled
    modifier whenDepositsEnabled() {
        if (!isDepositsEnabled()) {
            revert ErrorDepositsDisabled();
        }
        _;
    }

    /// @dev Validates that withdrawals are enabled
    modifier whenWithdrawalsEnabled() {
        if (!isWithdrawalsEnabled()) {
            revert ErrorWithdrawalsDisabled();
        }
        _;
    }

    event DepositsEnabled(address indexed enabler);
    event DepositsDisabled(address indexed disabler);
    event WithdrawalsEnabled(address indexed enabler);
    event WithdrawalsDisabled(address indexed disabler);
    event Initialized(address indexed admin);

    error ErrorDepositsEnabled();
    error ErrorDepositsDisabled();
    error ErrorWithdrawalsEnabled();
    error ErrorWithdrawalsDisabled();
    error ErrorAlreadyInitialized();
}

// SPDX-FileCopyrightText: 2022 Lido <[email protected]>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

/// @author psirex
/// @notice Contains the logic for validation of tokens used in the bridging process
contract BridgeableTokens {
    /// @notice Address of the bridged token in the L1 chain
    address public immutable l1Token;

    /// @notice Address of the token minted on the L2 chain when token bridged
    address public immutable l2Token;

    /// @param l1Token_ Address of the bridged token in the L1 chain
    /// @param l2Token_ Address of the token minted on the L2 chain when token bridged
    constructor(address l1Token_, address l2Token_) {
        l1Token = l1Token_;
        l2Token = l2Token_;
    }

    /// @dev Validates that passed l1Token_ is supported by the bridge
    modifier onlySupportedL1Token(address l1Token_) {
        if (l1Token_ != l1Token) {
            revert ErrorUnsupportedL1Token();
        }
        _;
    }

    /// @dev Validates that passed l2Token_ is supported by the bridge
    modifier onlySupportedL2Token(address l2Token_) {
        if (l2Token_ != l2Token) {
            revert ErrorUnsupportedL2Token();
        }
        _;
    }

    /// @dev validates that account_ is not zero address
    modifier onlyNonZeroAccount(address account_) {
        if (account_ == address(0)) {
            revert ErrorAccountIsZeroAddress();
        }
        _;
    }

    error ErrorUnsupportedL1Token();
    error ErrorUnsupportedL2Token();
    error ErrorAccountIsZeroAddress();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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