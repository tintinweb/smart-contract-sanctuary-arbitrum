// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "../Realm/IRealm.sol";
import "../Utils/IProduction.sol";
import "./ICollectible.sol";

import "../Manager/ManagerModifier.sol";

contract CollectibleProducerWithParticle is
  ReentrancyGuard,
  Pausable,
  ManagerModifier
{
  using SafeERC20 for IERC20;

  //=======================================
  // Immutables
  //=======================================
  IRealm public immutable REALM;
  IProduction public immutable PRODUCTION;
  ICollectible public immutable COLLECTIBLE;
  address public immutable VAULT;
  IERC20 public immutable TOKEN;

  //=======================================
  // Immutables
  //=======================================

  //=======================================
  // Uintss
  //=======================================
  uint256 public defaultCooldownAddition;
  uint256 public maxCollectibles;
  uint256 public maxSeconds;

  //=======================================
  // Arrays
  //=======================================
  uint256[] public cooldowns;
  uint256[] public costs;

  //=======================================
  // Mappings
  //=======================================
  mapping(uint256 => mapping(uint256 => bool)) public geos;
  mapping(uint256 => uint256) public exotics;
  mapping(uint256 => uint256) public rarityHolder;

  //=======================================
  // Events
  //=======================================
  event Activated(uint256 realmId);
  event Produced(
    uint256 realmId,
    uint256 collectibleId,
    uint256 quantity,
    uint256 cost
  );

  //=======================================
  // Constructor
  //=======================================
  constructor(
    address _realm,
    address _manager,
    address _production,
    address _collectible,
    address _vault,
    address _token,
    uint256 _maxCollectibles,
    uint256 _maxSeconds
  ) ManagerModifier(_manager) {
    REALM = IRealm(_realm);
    PRODUCTION = IProduction(_production);
    COLLECTIBLE = ICollectible(_collectible);
    VAULT = _vault;
    TOKEN = IERC20(_token);

    maxCollectibles = _maxCollectibles;
    maxSeconds = _maxSeconds;

    exotics[0] = 1;
    exotics[1] = 23;
    exotics[2] = 16;
    exotics[3] = 34;

    // Nourishment
    geos[0][0] = true; // Pond
    geos[0][1] = true; // Valley
    geos[0][5] = true; // Canal
    geos[0][7] = true; // Prairie
    geos[0][11] = true; // River
    geos[0][25] = true; // Biosphere
    geos[0][26] = true; // Lagoon
    geos[0][31] = true; // Oasis
    geos[0][32] = true; // Waterfall

    // Aquatic
    geos[1][12] = true; // Sea
    geos[1][14] = true; // Lake
    geos[1][20] = true; // Fjord
    geos[1][23] = true; // Ocean
    geos[1][13] = true; // Cove
    geos[1][2] = true; // Gulf
    geos[1][17] = true; // Bay
    geos[1][33] = true; // Reef

    // Technological
    geos[2][16] = true; // Tundra
    geos[2][24] = true; // Desert
    geos[2][30] = true; // Cave
    geos[2][6] = true; // Cape
    geos[2][10] = true; // Peninsula
    geos[2][15] = true; // Swamp
    geos[2][19] = true; // Dune
    geos[2][28] = true; // Island
    geos[2][21] = true; // Geyser

    // Earthen
    geos[3][3] = true; // Basin
    geos[3][8] = true; // Plateau
    geos[3][9] = true; // Mesa
    geos[3][18] = true; // Ice Shelf
    geos[3][22] = true; // Glacier
    geos[3][4] = true; // Butte
    geos[3][29] = true; // Canyon
    geos[3][27] = true; // Mountain
    geos[3][34] = true; // Volcano

    // Common
    rarityHolder[0] = 0;
    rarityHolder[1] = 0;
    rarityHolder[10] = 0;
    rarityHolder[11] = 0;
    rarityHolder[20] = 0;
    rarityHolder[21] = 0;
    rarityHolder[30] = 0;
    rarityHolder[31] = 0;

    // Uncommon
    rarityHolder[2] = 1;
    rarityHolder[3] = 1;
    rarityHolder[12] = 1;
    rarityHolder[13] = 1;
    rarityHolder[22] = 1;
    rarityHolder[23] = 1;
    rarityHolder[32] = 1;
    rarityHolder[33] = 1;

    // Rare
    rarityHolder[4] = 2;
    rarityHolder[5] = 2;
    rarityHolder[14] = 2;
    rarityHolder[15] = 2;
    rarityHolder[24] = 2;
    rarityHolder[25] = 2;
    rarityHolder[34] = 2;
    rarityHolder[35] = 2;

    // Epic
    rarityHolder[6] = 3;
    rarityHolder[16] = 3;
    rarityHolder[26] = 3;
    rarityHolder[36] = 3;

    // Legendary
    rarityHolder[7] = 4;
    rarityHolder[17] = 4;
    rarityHolder[27] = 4;
    rarityHolder[37] = 4;

    // Mythic
    rarityHolder[8] = 5;
    rarityHolder[18] = 5;
    rarityHolder[28] = 5;
    rarityHolder[38] = 5;

    // Exotic
    rarityHolder[9] = 6;
    rarityHolder[19] = 6;
    rarityHolder[29] = 6;
    rarityHolder[39] = 6;

    cooldowns = [86400, 86400, 129600, 129600, 172800, 172800, 259200];
    costs = [
      500000000000000000,
      750000000000000000,
      1500000000000000000,
      2500000000000000000,
      10000000000000000000,
      12500000000000000000,
      20000000000000000000
    ];
  }

  //=======================================
  // External
  //=======================================
  function collect(
    uint256[] calldata _realmIds,
    uint256[][] calldata _collectibleIds,
    uint256[][] calldata _quantities
  ) external nonReentrant whenNotPaused {
    for (uint256 h = 0; h < _realmIds.length; h++) {
      uint256 realmId = _realmIds[h];

      // Check ownership
      require(
        REALM.ownerOf(realmId) == msg.sender,
        "CollectibleProducer: You do not own this Realm"
      );

      uint256[] memory collectibleIds = _collectibleIds[h];
      uint256[] memory quantities = _quantities[h];

      // Check if _collectibleIds are below max
      require(
        collectibleIds.length <= maxCollectibles,
        "CollectibleProducer: Above max Collectibles"
      );

      // If not productive, set to 6 days ago
      if (!PRODUCTION.isProductive(realmId)) {
        PRODUCTION.setProduction(realmId, block.timestamp - 6 days);
      }

      // Get production start date
      uint256 startedAt = PRODUCTION.getStartedAt(realmId);

      for (uint256 j = 0; j < collectibleIds.length; j++) {
        uint256 collectibleId = collectibleIds[j];
        uint256 desiredQuantity = quantities[j];

        // Collect
        _collect(realmId, collectibleId, desiredQuantity, startedAt);
      }
    }
  }

  function getSecondsElapsed(uint256 _realmId) external view returns (uint256) {
    uint256 startedAt = PRODUCTION.getStartedAt(_realmId);

    // Return 0 if production hasn't been started
    if (startedAt == 0) return 0;

    return _secondsElapsed(startedAt);
  }

  function getQuantity(uint256 _realmId, uint256 _collectibleId)
    external
    view
    returns (uint256)
  {
    uint256 rarity = _getRarity(_collectibleId);
    uint256 startedAt = PRODUCTION.getStartedAt(_realmId);

    // Return 0 if production hasn't been started
    if (startedAt == 0) return 0;

    uint256 cooldown = cooldowns[rarity];

    return _secondsElapsed(startedAt) / cooldown;
  }

  function secondsTillIncrease(uint256 _realmId, uint256 _collectibleId)
    external
    view
    returns (uint256)
  {
    uint256 rarity = _getRarity(_collectibleId);
    uint256 startedAt = PRODUCTION.getStartedAt(_realmId);

    // Return 0 if production hasn't been started
    if (startedAt == 0) return 0;

    uint256 cooldown = cooldowns[rarity];
    uint256 elapsedTime = _secondsElapsed(startedAt);

    return cooldown - (elapsedTime - ((elapsedTime / cooldown) * cooldown));
  }

  //=======================================
  // Admin
  //=======================================
  function pause() external onlyAdmin {
    _pause();
  }

  function unpause() external onlyAdmin {
    _unpause();
  }

  function updateCosts(uint256[] calldata _costs) external onlyAdmin {
    costs = _costs;
  }

  function updateCooldowns(uint256[] calldata _cooldowns) external onlyAdmin {
    cooldowns = _cooldowns;
  }

  function updateMaxCollectibles(uint256 _maxCollectibles) external onlyAdmin {
    maxCollectibles = _maxCollectibles;
  }

  function updateMaxSeconds(uint256 _maxSeconds) external onlyAdmin {
    maxSeconds = _maxSeconds;
  }

  //=======================================
  // Internal
  //=======================================

  function _collect(
    uint256 _realmId,
    uint256 _collectibleId,
    uint256 _desiredQuantity,
    uint256 _startedAt
  ) internal {
    // Get rarity
    uint256 rarity = _getRarity(_collectibleId);

    // Get cooldown
    uint256 cooldown = cooldowns[rarity];

    // Get category
    uint256 category = _getCategory(_collectibleId);

    // Store if has Geo Feature
    bool hasGeo = _hasGeo(_realmId, category);

    // Check if trying to collect Exotic
    if (rarity == 6) {
      require(
        _hasExotic(_realmId, category),
        "CollectibleProducer: You cannot produce Exotic Collectible"
      );
    }

    // Require Geo Feature if not Common Rarity
    if (rarity != 0) {
      require(
        hasGeo,
        "CollectibleProducer: You cannot produce this Collectible"
      );
    }

    // Seconds elapsed
    uint256 secondsElapsed = _secondsElapsed(_startedAt);

    // Check over max seconds to collect
    if (secondsElapsed > maxSeconds) {
      secondsElapsed = maxSeconds;
    }

    // Get quantity
    uint256 quantity = secondsElapsed / cooldown;

    // Check if quantity is greater than 0
    require(
      quantity > 0,
      "CollectibleProducer: Max quantity allowed must be above 0"
    );

    // Check if desired quantity is allowed
    require(
      quantity >= _desiredQuantity,
      "CollectibleProducer: Desired quantity is above max quantity allowed"
    );

    // Update production
    PRODUCTION.setProduction(_realmId, block.timestamp);

    // Get cost
    uint256 cost = costs[rarity] * _desiredQuantity;

    // Transfer to vault
    TOKEN.safeTransferFrom(msg.sender, VAULT, cost);

    // Mint
    COLLECTIBLE.mintFor(msg.sender, _collectibleId, _desiredQuantity);

    emit Produced(_realmId, _collectibleId, _desiredQuantity, cost);
  }

  function _getCategory(uint256 _collectibleId)
    internal
    pure
    returns (uint256)
  {
    if (_collectibleId < 10) {
      return 0;
    } else if (_collectibleId < 20) {
      return 1;
    } else if (_collectibleId < 30) {
      return 2;
    } else {
      return 3;
    }
  }

  function _secondsElapsed(uint256 _time) internal view returns (uint256) {
    if (block.timestamp <= _time) {
      return 0;
    }

    return (block.timestamp - _time);
  }

  function _getRarity(uint256 _collectibleId) internal view returns (uint256) {
    return rarityHolder[_collectibleId];
  }

  function _hasGeo(uint256 _realmId, uint256 _category)
    internal
    view
    returns (bool)
  {
    (uint256 a, uint256 b, uint256 c) = _realmFeatures(_realmId);

    if (geos[_category][a] || geos[_category][b] || geos[_category][c]) {
      return true;
    }

    return false;
  }

  function _hasExotic(uint256 _realmId, uint256 _category)
    internal
    view
    returns (bool)
  {
    (uint256 a, uint256 b, uint256 c) = _realmFeatures(_realmId);

    if (
      a == exotics[_category] ||
      b == exotics[_category] ||
      c == exotics[_category]
    ) {
      return true;
    }

    return false;
  }

  function _realmFeatures(uint256 _realmId)
    internal
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    return (
      REALM.realmFeatures(_realmId, 0),
      REALM.realmFeatures(_realmId, 1),
      REALM.realmFeatures(_realmId, 2)
    );
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IRealm {
  function balanceOf(address owner) external view returns (uint256);

  function ownerOf(uint256 _realmId) external view returns (address owner);

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function isApprovedForAll(address owner, address operator)
    external
    returns (bool);

  function realmFeatures(uint256 realmId, uint256 index)
    external
    view
    returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IProduction {
  function setProduction(uint256 _realmId, uint256 _timestamp) external;

  function isProductive(uint256 _realmId) external view returns (bool);

  function getStartedAt(uint256 _realmId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface ICollectible {
  function mintFor(
    address _for,
    uint256 _id,
    uint256 _amount
  ) external;

  function mintBatchFor(
    address _for,
    uint256[] memory _ids,
    uint256[] memory _amounts
  ) external;

  function burn(uint256 _id, uint256 _amount) external;

  function burnBatch(uint256[] memory ids, uint256[] memory amounts) external;

  function safeBatchTransferFrom(
    address _from,
    address _to,
    uint256[] calldata _ids,
    uint256[] calldata _amounts,
    bytes calldata data
  ) external;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _ids,
    uint256 _amounts,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../Manager/IManager.sol";

abstract contract ManagerModifier {
  //=======================================
  // Immutables
  //=======================================
  IManager public immutable MANAGER;

  //=======================================
  // Constructor
  //=======================================
  constructor(address _manager) {
    MANAGER = IManager(_manager);
  }

  //=======================================
  // Modifiers
  //=======================================
  modifier onlyAdmin() {
    require(MANAGER.isAdmin(msg.sender), "Manager: Not an Admin");
    _;
  }

  modifier onlyManager() {
    require(MANAGER.isManager(msg.sender, 0), "Manager: Not manager");
    _;
  }

  modifier onlyMinter() {
    require(MANAGER.isManager(msg.sender, 1), "Manager: Not minter");
    _;
  }

  modifier onlyTokenMinter() {
    require(MANAGER.isManager(msg.sender, 2), "Manager: Not token minter");
    _;
  }

  modifier onlyBinder() {
    require(MANAGER.isManager(msg.sender, 3), "Manager: Not binder");
    _;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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

pragma solidity ^0.8.4;

interface IManager {
  function isAdmin(address _addr) external view returns (bool);

  function isManager(address _addr, uint256 _type) external view returns (bool);

  function addManager(address _addr, uint256 _type) external;

  function removeManager(address _addr, uint256 _type) external;

  function addAdmin(address _addr) external;

  function removeAdmin(address _addr) external;
}