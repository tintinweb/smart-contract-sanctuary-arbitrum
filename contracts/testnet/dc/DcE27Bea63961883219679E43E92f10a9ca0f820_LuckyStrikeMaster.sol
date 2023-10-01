// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/vault/IFeeCollectorV2.sol";
import "../../interfaces/core/ILuckyStrikeMaster.sol";
import "../../interfaces/vault/IVault.sol";

contract LuckyStrikeMaster is AccessControl, ILuckyStrikeMaster {
  uint256 public constant TOTAL_DRAW_ODDS = 1e7; // 10 million
  uint256 public chancePerUSDWager = 1; // 1 in 1e7 chance to win the jackpot per 1 USD wagered
  mapping(address => bool) public allowedGames;

  address[] public allWhitelistedTokensFeeCollector;

  IERC20 public wlp;
  IVault public vault;
  IFeeCollectorV2 public feeCollector;

  constructor() {
    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  modifier onlyGovernance() {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "VM: Not governance");
    _;
  }

  // modifier if caller is allowed game
  modifier onlyAllowedGames() {
    require(allowedGames[_msgSender()], "LuckyStrikeMaster: Only allowed games");
    _;
  }

  // function that sets feecollector address
  function setFeeCollector(IFeeCollectorV2 _feeCollector) external onlyGovernance {
    feeCollector = _feeCollector;
  }

  // function that sets chancePerUSDWager
  function setChancePerUSDWager(uint256 _chancePerUSDWager) external onlyGovernance {
    chancePerUSDWager = _chancePerUSDWager;
  }

  // function that sets wlp address
  function setWLP(IERC20 _wlp) external onlyGovernance {
    wlp = _wlp;
  }

  // function that sets vault address
  function setVault(IVault _vault) external onlyGovernance {
    vault = _vault;
  }

  /**
   * @notice function that returns how much usd value of tokens, sit in the vault that will be partly go towards the jackpot
   */
  function getWagerFeesValueTotalInVault() public view returns (uint256 totalValue_) {
    uint256 length_ = allWhitelistedTokensFeeCollector.length;
    uint256 amount_;
    for (uint256 i = 0; i < length_; ++i) {
      address token_ = allWhitelistedTokensFeeCollector[i];
      amount_ = vault.wagerFeeReserves(token_);
      totalValue_ += vault.tokenToUsdMin(token_, amount_);
    }
    return totalValue_;
  }

  function valueOfLuckyStrikeJackpot() external view returns (uint256 valueTotalJackpot_) {
    // fetch amount of WLP in the feeCollector
    uint256 wlpInFeeCollector_ = feeCollector.returnAmountWlpForLuckyStrike();
    // fetch amount of WLP in this contract
    uint256 balance_ = wlp.balanceOf(address(this));
    // calculate the value of the wlp in the feeCollector and in this contract
    uint256 valueOfWlpContract_ = ((balance_ + wlpInFeeCollector_) * vault.getWlpValue()) / 1e18;

    // calculate the total value of the tokens in the vault that will be used for the jackpot when it is farmed/collected (in case player wins the jackpot)
    uint256 valueOnCollect_ = getWagerFeesValueTotalInVault();

    // calculate how much of the 'to be collected' wagerfees will go toward the progressive jackpot
    uint256 valueForJackpot_ = (valueOnCollect_ * feeCollector.returnLuckyStrikeRatio()) / 1e4;

    // calculate the total value of the jackpot in usd (scaled 1e30)
    valueTotalJackpot_ = valueForJackpot_ + valueOfWlpContract_;
  }

  function syncTokens() external onlyGovernance {
    _syncWhitelistedTokens();
  }

  /**
   * @notice function that syncs the whitelisted tokens with the vault
   */
  function _syncWhitelistedTokens() internal {
    delete allWhitelistedTokensFeeCollector;
    uint256 count_ = feeCollector.allWhitelistedTokensLength();
    for (uint256 i = 0; i < count_; ++i) {
      address token_ = feeCollector.allWhitelistedTokensFeeCollectorAtIndex(i);
      allWhitelistedTokensFeeCollector.push(token_);
    }
    emit SyncTokens();
  }

  function hasLuckyStrike(
    uint256 _randomness,
    uint256 _wagerUSD
  ) external view returns (bool hasWon_) {
    // scale the random number to the TOTAL_DRAW_ODDS (so a value below 1e7 or whatever te max odds value is)
    uint256 scaledRandom_;
    unchecked {
      scaledRandom_ = (_randomness % TOTAL_DRAW_ODDS) + 1;
    }

    /**
     * Lottery flow:
     * 1. Calculate the odds for the wager with chancePerUSDWager
     * 2. Take the randomness of the VRF and scale it to the TOTAL_DRAW_ODDS (so a value below 1e7)
     * 3. The result is a random value between 0 and 1e7 (should be evenly distributed, to be checked?)
     * 4. If the scaled random number is below the odds for the category, the player has won the lottery
     *
     * The higher the odds value, the larger the chance of the oddsForCategory_ to be lower than scaledRandom_. scaledRandom_ is a random number between 0 and 1e7, so the higher the oddsForCategory_ the higher the chance of winning. Since higher odds means higher number so larger change the scaledRandom_ is lower than that number.
     *
     * This gives us the desired effect of having a higher chance of winning the lottery when the wager is higher.
     */

    unchecked {
      if (((chancePerUSDWager * _wagerUSD) / 1e30) >= scaledRandom_) {
        hasWon_ = true;
      }
    }
  }

  function withdrawTokenByGovernance(address _token, uint256 _amount) external onlyGovernance {
    IERC20(_token).transfer(_msgSender(), _amount);
    emit WithdrawByGovernance(_token, _amount);
  }

  function processLuckyStrike(
    address _player
  ) external onlyAllowedGames returns (uint256 wlpBalance_) {
    // collect the pending fees in the feecollector for the progressive jackpot
    feeCollector.collectFeesOnLotteryWin();
    // check how much wlp tokens are now in this contract (so this is the jackpot)
    wlpBalance_ = wlp.balanceOf(address(this));
    // transfer the wlp to the winning player
    wlp.transfer(_player, wlpBalance_);
    emit LuckyStrikePayout(_player, wlpBalance_);
    return wlpBalance_;
  }

  // function that adds a game to the allowed games mapping
  function addGame(address _game) external onlyGovernance {
    allowedGames[_game] = true;
    emit GameAdded(_game);
  }

  // function that removes a game from the allowed games mapping
  function removeGame(address _game) external onlyGovernance {
    allowedGames[_game] = false;
    emit GameRemoved(_game);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ILuckyStrikeMaster {
  event LuckyStrikePayout(address indexed player, uint256 wonAmount);
  event DeleteTokenFromWhitelist(address indexed token);
  event TokenAddedToWhitelist(address indexed token);
  event SyncTokens();
  event GameRemoved(address indexed game);
  event GameAdded(address indexed game);
  event DeleteAllWhitelistedTokens();
  event LuckyStrike(address indexed player, uint256 wonAmount, bool won);
  event WithdrawByGovernance(address indexed token, uint256 amount);

  function withdrawTokenByGovernance(address _token, uint256 _amount) external;

  function hasLuckyStrike(
    uint256 _randomness,
    uint256 _wagerUSD
  ) external view returns (bool hasWon_);

  function valueOfLuckyStrikeJackpot() external view returns (uint256 valueTotal_);

  function processLuckyStrike(address _player) external returns (uint256 wonAmount_);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IFeeCollectorV2 {
  struct SwapDistributionRatio {
    uint64 wlpHolders;
    uint64 staking;
    uint64 buybackAndBurn;
    uint64 core;
  }

  struct WagerDistributionRatio {
    uint64 staking;
    uint64 buybackAndBurn;
    uint64 core;
    uint64 luckyStrikePot;
  }

  struct Reserve {
    uint256 wlpHolders;
    uint256 staking;
    uint256 buybackAndBurn;
    uint256 core;
    uint256 luckyStrikePot;
  }

  // *** Destination addresses for the farmed fees from the vault *** //
  // note: the 4 addresses below need to be able to receive ERC20 tokens
  struct DistributionAddresses {
    // the destination address for the collected fees attributed to WLP holders
    address wlpClaim;
    // the destination address for the collected fees attributed  to WINR stakers
    address winrStaking;
    // address of the contract that does the 'buyback and burn'
    address buybackAndBurn;
    // the destination address for the collected fees attributed to core development
    address core;
    // address of the contract/EOA that will distribute the referral fees
    address referral;
    address luckyStrikePot;
  }

  struct DistributionTimes {
    uint256 wlpClaim;
    uint256 winrStaking;
    uint256 buybackAndBurn;
    uint256 core;
    uint256 referral;
    uint256 luckyStrikePot;
  }

  function getReserves() external returns (Reserve memory);

  function getSwapDistribution() external returns (SwapDistributionRatio memory);

  function getWagerDistribution() external returns (WagerDistributionRatio memory);

  function getAddresses() external returns (DistributionAddresses memory);

  function allWhitelistedTokensLength() external view returns (uint256 whitelistedLength_);

  function allWhitelistedTokensFeeCollectorAtIndex(
    uint256 _index
  ) external view returns (address token_);

  function calculateDistribution(
    uint256 _amountToDistribute,
    uint64 _ratio
  ) external pure returns (uint256 amount_);

  function withdrawFeesAll() external;

  function isWhitelistedDestination(address _address) external returns (bool);

  function syncWhitelistedTokens() external;

  function addToWhitelist(address _toWhitelistAddress, bool _setting) external;

  function setLuckyStrikeContract(address _luckyStrikeContract) external;

  function returnLuckyStrikeRatio() external view returns (uint256);

  function setReferralDistributor(address _distributorAddress) external;

  function setCoreDevelopment(address _coreDevelopment) external;

  function setWinrStakingContract(address _winrStakingContract) external;

  function transferToLuckyStrikeContract() external;

  function setBuyBackAndBurnContract(address _buybackAndBurnContract) external;

  function setWlpClaimContract(address _wlpClaimContract) external;

  function returnAmountWlpForLuckyStrike() external view returns (uint256);

  function setWagerDistribution(
    uint64 _stakingRatio,
    uint64 _burnRatio,
    uint64 _coreRatio,
    uint64 _luckyStrikeRatio
  ) external;

  function setSwapDistribution(
    uint64 _wlpHoldersRatio,
    uint64 _stakingRatio,
    uint64 _buybackRatio,
    uint64 _coreRatio
  ) external;

  function addTokenToWhitelistList(address _tokenToAdd) external;

  function deleteWhitelistTokenList() external;

  function collectFeesBeforeLPEvent() external;

  function collectFeesOnLotteryWin() external;

  /*==================== Events *====================*/
  event DistributionSync();
  event WithdrawSync();
  event WhitelistEdit(address whitelistAddress, bool setting);
  event EmergencyWithdraw(address caller, address token, uint256 amount, address destination);
  event ManualGovernanceDistro();
  event FeesDistributed();
  event WagerFeesManuallyFarmed(address tokenAddress, uint256 amountFarmed);
  event ManualDistributionManager(
    address targetToken,
    uint256 amountToken,
    address destinationAddress
  );
  event SetRewardInterval(uint256 timeInterval);
  event SetCoreDestination(address newDestination);
  event SetBuybackAndBurnDestination(address newDestination);
  event SetClaimDestination(address newDestination);
  event SetReferralDestination(address referralDestination);
  event SetStakingDestination(address newDestination);
  event SwapFeesManuallyFarmed(address tokenAddress, uint256 totalAmountCollected);
  event CollectedWagerFees(address tokenAddress, uint256 amountCollected);
  event CollectedSwapFees(address tokenAddress, uint256 amountCollected);
  event NothingToDistribute(address token);
  event DistributionComplete(
    address token,
    uint256 toWLP,
    uint256 toStakers,
    uint256 toBuyBack,
    uint256 toCore,
    uint256 toReferral
  );
  event WagerDistributionSet(
    uint64 stakingRatio,
    uint64 burnRatio,
    uint64 coreRatio,
    uint64 luckyStrikeRatio
  );
  event SwapDistributionSet(
    uint64 _wlpHoldersRatio,
    uint64 _stakingRatio,
    uint64 _buybackRatio,
    uint64 _coreRatio
  );
  event SyncTokens();
  event DeleteAllWhitelistedTokens();
  event TokenAddedToWhitelist(address addedTokenAddress);
  event TokenTransferredByTimelock(address token, address recipient, uint256 amount);
  event SetLuckyStrikeDestination(address newDestination);
  event TransferLuckyStrikeTokens(address receiver, uint256 amount);

  event ManualFeeWithdraw(
    address token,
    uint256 swapFeesCollected,
    uint256 wagerFeesCollected,
    uint256 referralFeesCollected
  );

  event TransferBuybackAndBurnTokens(address receiver, uint256 amount);
  event TransferCoreTokens(address receiver, uint256 amount);
  event TransferWLPRewardTokens(address receiver, uint256 amount);
  event TransferWinrStakingTokens(address receiver, uint256 amount);
  event TransferReferralTokens(address token, address receiver, uint256 amount);
  event VaultUpdated(address vault);
  event WLPManagerUpdated(address wlpManager);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IVault {
  function getReserve() external view returns (uint256);

  function getWlpValue() external view returns (uint256);

  function getMinPrice(address _token) external view returns (uint256);

  function payout(
    address _wagerAsset,
    address _escrowAddress,
    uint256 _escrowAmount,
    address _recipient,
    uint256 _totalAmount
  ) external;

  function payoutNoEscrow(address _wagerAsset, address _recipient, uint256 _totalAmount) external;

  function payin(address _inputToken, address _escrowAddress, uint256 _escrowAmount) external;

  function payinWagerFee(address _tokenIn) external;

  function deposit(address _token, address _receiver) external returns (uint256);

  function withdraw(address _token, address _receiver) external;

  function wagerFeeReserves(address _token) external view returns (uint256);

  function allWhitelistedTokensLength() external view returns (uint256);

  function allWhitelistedTokens(uint256) external view returns (address);

  function payinPoolProfits(address _tokenIn) external;

  function tokenToUsdMin(
    address _tokenToPrice,
    uint256 _tokenAmount
  ) external view returns (uint256);

  function setVaultManagerAddress(
		address _vaultManagerAddress,
		bool _setting
	) external;
}