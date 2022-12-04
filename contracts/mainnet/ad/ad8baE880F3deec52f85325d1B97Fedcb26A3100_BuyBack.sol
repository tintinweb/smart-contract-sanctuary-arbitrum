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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IMarket.sol";
import "./interfaces/ILabs.sol";
import "./interfaces/IBonds.sol";

import "./utils/Math.sol";

contract BuyBack is Ownable , ReentrancyGuard{
  uint256 public  dayOfBuyBack;
  uint256 public immutable dayOfWithdraw;
  bytes32 private hashTimeInTheDay;
  address public market;
  IERC20BurnableMinter immutable usdc;
  IERC20BurnableMinter immutable labs;


  constructor(
    uint _dayOfWithdraw,
    uint256 interval,
    IERC20BurnableMinter _lab,
    IERC20BurnableMinter _usdc
  ) {
    dayOfWithdraw = _dayOfWithdraw;
    dayOfBuyBack = _dayOfWithdraw + interval;
    labs= _lab;
    usdc = _usdc;
  }

  function setMarket(address _market) external onlyOwner {
    market = _market;
  }
  /**
   * @dev Constructor.
   * @param _salt - to randomise  the hour of buyback , mixed with block.difficulty , which is surely impredictible
   * 
   */
  function mixTime(string calldata _salt) external {
    require(block.timestamp < dayOfBuyBack, "Too Late");
    hashTimeInTheDay = triHash(
      hashTimeInTheDay,
      keccak256(abi.encodePacked(_salt)),
      keccak256(abi.encodePacked(block.difficulty))
    );
  }
  function triHash(
    bytes32 a,
    bytes32 b,
    bytes32 c
  ) private pure returns (bytes32 value) {
    assembly {
      mstore(0x00, a)
      mstore(0x20, b)
      mstore(0x40, c)
      value := keccak256(0x00, 0x60)
    }
  }

  function _getNumber() internal view returns (uint256 dayTime) {
    uint16 value = uint16(bytes2(hashTimeInTheDay << 16)) / 9;

    dayTime = uint256(value);
  }

  function isOpenned() public view returns (bool isIt) {
    isIt = block.timestamp >= dayOfBuyBack + _getNumber();
  }
/**
 * @dev core function of the buyback
 * Simulate a pool 
 */
  function selllab(uint256 amountToSell) public nonReentrant{
    require(
      isOpenned(),
      "Not Now"
    );
    uint256 ammount0 = usdc.balanceOf(address(this));
    uint256 ammount1 = labs.balanceOf(address(this));
    uint k = ammount0 * ammount1;
    uint256 labAfter = ammount1 + amountToSell;
    uint256 stablesYouGet = ammount0 - (k / labAfter);
    labs.transferFrom(msg.sender, address(this), amountToSell);
    usdc.transfer(msg.sender, stablesYouGet);
  }

/**
 * @dev
 * @param ratiox100  set the y/x ratio , impact the slope of the buyback
 */
  function getStables(uint ratiox100) external onlyOwner {
    require(ratiox100< 100, "Too damn boring");
    require(dayOfWithdraw < block.timestamp , "Not now");
    IMarket(market).pause();
    uint256 stableBal = usdc.balanceOf(market);
    usdc.transferFrom(market, address(this), stableBal);
    ILabs(address(labs)).mintForBuyBack(stableBal * 1e10 * ratiox100);
  }

// in case of missing ratio
  function burnRest(uint amount) external onlyOwner {
    uint day = 3600 * 24; 
    require(dayOfBuyBack + day < block.timestamp, " Let people take the buyback");
      labs.burn(labs.balanceOf(address(this)) - amount);
      dayOfBuyBack += day;
}


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./IERC20BurnableMinter.sol";
import "./IStakePool.sol";
import "./IMarket.sol";

interface IBank {
  // DSD token address
  function DSD() external view returns (IERC20BurnableMinter);

  // Market contract address
  function market() external view returns (IMarket);

  // StakePool contract address
  function pool() external view returns (IStakePool);

  // helper contract address
  function helper() external view returns (address);

  // user debt
  function debt(address user) external view returns (uint256);

  // developer address
  function dev() external view returns (address);

  // fee for borrowing DSD
  function borrowFee() external view returns (uint32);

  /**
   * @dev Constructor.
   * NOTE This function can only called through delegatecall.
   * @param _DSD - DSD token address.
   * @param _market - Market contract address.
   * @param _pool - StakePool contract address.
   * @param _helper - Helper contract address.
   * @param _owner - Owner address.
   */
  function constructor1(
    IERC20BurnableMinter _DSD,
    IMarket _market,
    IStakePool _pool,
    address _helper,
    address _owner
  ) external;

  /**
   * @dev Set bank options.
   *      The caller must be owner.
   * @param _dev - Developer address
   * @param _borrowFee - Fee for borrowing DSD
   */
  function setOptions(address _dev, uint32 _borrowFee) external;

  /**
   * @dev Calculate the amount of Lab that can be withdrawn.
   * @param user - User address
   */
  function withdrawable(address user) external view returns (uint256);

  /**
   * @dev Calculate the amount of Lab that can be withdrawn.
   * @param user - User address
   * @param amountLab - User staked Lab amount
   */
  function withdrawable(address user, uint256 amountLab)
    external
    view
    returns (uint256);

  /**
   * @dev Calculate the amount of DSD that can be borrowed.
   * @param user - User address
   */
  function available(address user) external view returns (uint256);

  /**
   * @dev Borrow DSD.
   * @param amount - The amount of DSD
   * @return borrowed - Borrowed DSD
   * @return fee - Borrow fee
   */
  function borrow(uint256 amount)
    external
    returns (uint256 borrowed, uint256 fee);

  /**
   * @dev Borrow DSD from user and directly mint to msg.sender.
   *      The caller must be helper contract.
   * @param user - User address
   * @param amount - The amount of DSD
   * @return borrowed - Borrowed DSD
   * @return fee - Borrow fee
   */
  function borrowFrom(address user, uint256 amount)
    external
    returns (uint256 borrowed, uint256 fee);

  /**
   * @dev Repay DSD.
   * @param amount - The amount of DSD
   */
  function repay(uint256 amount) external;

  /**
   * @dev Triggers stopped state.
   *      The caller must be owner.
   */
  function pause() external;

  /**
   * @dev Returns to normal state.
   *      The caller must be owner.
   */
  function unpause() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IMarket.sol";
struct Bond {
  // start timestamp
  uint256 startAt;
  // end timestamp
  uint256 endAt;
  // the price of Lab borne by the treasury
  uint256 deductedPrice;
  // the total amount of Lab issued by bonds
  uint256 maxAmount;
  // the reserve amount of Lab issued by bonds
  uint256 reserveAmount;
  // the duration for the linear release of the of this bond's reward
  uint256 releaseDuration;
}

struct BUserInfo {
  // Lab balance
  uint256 amount;
  // locked reward
  uint256 lockedReward;
  // released reward
  uint256 releasedReward;
  // timestamp of last update
  uint256 timestamp;
  // the duration for the linear release of the reward
  uint256 releaseDuration;
}

interface IBonds {
  // Lab token address
  function Lab() external view returns (IERC20);

  // market contract address
  function market() external view returns (IMarket);

  // bond helper contract address
  function helper() external view returns (address);

  // auto increment bond id
  function bondsLength() external view returns (uint256);

  // bond info
  function bonds(uint256 id)
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    );

  // user info
  function userInfo(address user)
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    );

  /**
   * @dev Constructor.
   * NOTE This function can only called through delegatecall.
   * @param _Lab - Lab token address
   * @param _market - Market contract address
   * @param _helper - Helper contract address
   * @param _owner - Owner address
   */
  function constructor1(
    IERC20 _Lab,
    IMarket _market,
    address _helper,
    address _owner
  ) external;

  /**
   * @dev Estimate user pending reward
   * @param userAddress - User address
   * @return released - Pending reward from the last settlement until now
   * @return lockedReward - Pending locked reward
   * @return releasedReward - Pending released reward
   * @return amount - User Lab balance
   */
  function estimatePendingReward(address userAddress)
    external
    view
    returns (
      uint256 released,
      uint256 lockedReward,
      uint256 releasedReward,
      uint256 amount
    );

  /**
   * @dev Estimate how much stablecoin users need to pay
   *      in addition to the part burdened by the treasury
   * @param id - Bond id
   * @param token - Stablecoin address
   * @param amount - The amount of Lab
   * @return fee - The fee charged by the developer(Lab)
   * @return worth - The amount of stablecoins that users should pay
   * @return worth1e18 - The amount of stablecoins that users should pay(1e18)
   * @return newDebt1e18 - Newly incurred treasury debt(1e18)
   * @return newPrice - New price
   */
  function estimateBuy(
    uint256 id,
    address token,
    uint256 amount
  )
    external
    view
    returns (
      uint256 fee,
      uint256 worth,
      uint256 worth1e18,
      uint256 newDebt1e18,
      uint256 newPrice
    );

  /**
   * @dev Buy Lab
   * @param id - Bond id
   * @param token - Stablecoin address
   * @param maxAmount - The max number of Lab the user wants to buy
   * @param desired - The max amount of stablecoins that users are willing to pay
   * @return worth - The amount of stablecoins actually paid by user
   * @return amount - The number of Lab actually purchased by the user
   * @return newDebt1e18 - Newly incurred treasury debt(1e18)
   * @return fee - The fee charged by the developer(Lab)
   */
  function buy(
    uint256 id,
    address token,
    uint256 maxAmount,
    uint256 desired
  )
    external
    returns (
      uint256 worth,
      uint256 amount,
      uint256 newDebt1e18,
      uint256 fee
    );

  /**
   * @dev Estimate how much stablecoin it will cost to claim Lab
   * @param user - User address
   * @param amount - Claim amount
   * @param token - Stablecoin address
   * @return repayDebt - Debt the user needs to pay
   */
  function estimateClaim(
    address user,
    uint256 amount,
    address token
  ) external view returns (uint256 repayDebt);

  /**
   * @dev Claim Lab
   * @param amount - Claim amount
   * @param token - Stablecoin address
   * @return repayDebt -  Debt the user needs to pay
   */
  function claim(uint256 amount, address token)
    external
    returns (uint256 repayDebt);

  /**
   * @dev Claim Lab for user
   * @param userAddress - User address
   * @param amount - Claim amount
   * @param token - Stablecoin address
   * @return repayDebt -  Debt the user needs to pay
   */
  function claimFor(
    address userAddress,
    uint256 amount,
    address token
  ) external returns (uint256 repayDebt);

  /**
   * @dev Add a new bond.
   *      The caller must be the owner.
   * @param startAt - Start timestamp
   * @param endAt - End timestamp
   * @param deductedPrice - The price of Lab borne by the treasury
   * @param maxAmount -  The total amount of Lab issued by bonds
   * @param releaseDuration - The duration for the linear release of the reward
   * @return id - New bond id
   */
  function add(
    uint256 startAt,
    uint256 endAt,
    uint256 deductedPrice,
    uint256 maxAmount,
    uint256 releaseDuration
  ) external returns (uint256);

  /**
   * @dev Stop a bond.
   *      The caller must be the owner.
   * @param id - Bond id
   */
  function stop(uint256 id) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IERC20BurnableMinter is IERC20Metadata {
  function mint(address to, uint256 amount) external;

  function burn(uint256 amount) external;

  function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;


interface ILabs {



  function mintForBuyBack( uint256 amount) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";
import "./IERC20BurnableMinter.sol";
import "./IStakePool.sol";

interface IMarket is IAccessControlEnumerable {
  function totalVolume() external view returns (uint256);

  function paused() external view returns (bool);

  function Lab() external view returns (IERC20BurnableMinter);

  function prLab() external view returns (IERC20BurnableMinter);

  function pool() external view returns (IStakePool);

  // target funding ratio (target/10000)
  function target() external view returns (uint32);

  // target adjusted funding ratio (targetAdjusted/10000)
  function targetAdjusted() external view returns (uint32);

  // minimum value of target
  function minTarget() external view returns (uint32);

  // maximum value of the targetAdjusted
  function maxTargetAdjusted() external view returns (uint32);

  // step value of each raise
  function raiseStep() external view returns (uint32);

  // step value of each lower
  function lowerStep() external view returns (uint32);

  // interval of each lower
  function lowerInterval() external view returns (uint32);

  // the time when ratio was last modified
  function latestUpdateTimestamp() external view returns (uint256);

  // developer address
  function dev() external view returns (address);

  // fee for buying Lab
  function buyFee() external view returns (uint32);

  // fee for selling Lab
  function sellFee() external view returns (uint32);

  // the slope of the price function (1/(k * 1e18))
  function k() external view returns (uint256);

  // current Lab price
  function c() external view returns (uint256);

  // floor Lab price
  function f() external view returns (uint256);

  // floor supply
  function p() external view returns (uint256);

  // total worth
  function w() external view returns (uint256);

  // stablecoins decimals
  function stablecoinsDecimals(address token) external view returns (uint8);

  /**
   * @dev Startup market.
   *      The caller must be owner.
   * @param _token - Initial stablecoin address
   * @param _w - Initial stablecoin worth
   * @param _t - Initial Lab total supply
   */
  function startup(
    address _token,
    uint256 _w,
    uint256 _t
  ) external;

  /**
   * @dev Get the number of stablecoins that can buy Lab.
   */
  function stablecoinsCanBuyLength() external view returns (uint256);

  /**
   * @dev Get the address of the stablecoin that can buy Lab according to the index.
   * @param index - Stablecoin index
   */
  function stablecoinsCanBuyAt(uint256 index) external view returns (address);

  /**
   * @dev Get whether the token can be used to buy Lab.
   * @param token - Token address
   */
  function stablecoinsCanBuyContains(address token)
    external
    view
    returns (bool);

  /**
   * @dev Get the number of stablecoins that can be exchanged with Lab.
   */
  function stablecoinsCanSellLength() external view returns (uint256);

  /**
   * @dev Get the address of the stablecoin that can be exchanged with Lab,
   *      according to the index.
   * @param index - Stablecoin index
   */
  function stablecoinsCanSellAt(uint256 index) external view returns (address);

  /**
   * @dev Get whether the token can be exchanged with Lab.
   * @param token - Token address
   */
  function stablecoinsCanSellContains(address token)
    external
    view
    returns (bool);

  /**
   * @dev Calculate current funding ratio.
   */
  function currentFundingRatio()
    external
    view
    returns (uint256 numerator, uint256 denominator);

  /**
   * @dev Estimate adjust result.
   * @param _k - Slope
   * @param _tar - Target funding ratio
   * @param _w - Total worth
   * @param _t - Total supply
   * @return success - Whether the calculation was successful
   * @return _c - Current price
   * @return _f - Floor price
   * @return _p - Point of intersection
   */
  function estimateAdjust(
    uint256 _k,
    uint256 _tar,
    uint256 _w,
    uint256 _t
  )
    external
    pure
    returns (
      bool success,
      uint256 _c,
      uint256 _f,
      uint256 _p
    );

  /**
   * @dev Estimate next raise price.
   * @return success - Whether the calculation was successful
   * @return _t - The total supply when the funding ratio reaches targetAdjusted
   * @return _c - The price when the funding ratio reaches targetAdjusted
   * @return _w - The total worth when the funding ratio reaches targetAdjusted
   * @return raisedFloorPrice - The floor price after market adjusted
   */
  function estimateRaisePrice()
    external
    view
    returns (
      bool success,
      uint256 _t,
      uint256 _c,
      uint256 _w,
      uint256 raisedFloorPrice
    );

  /**
   * @dev Estimate raise price by input value.
   * @param _f - Floor price
   * @param _k - Slope
   * @param _p - Floor supply
   * @param _tar - Target funding ratio
   * @param _tarAdjusted - Target adjusted funding ratio
   * @return success - Whether the calculation was successful
   * @return _t - The total supply when the funding ratio reaches _tar
   * @return _c - The price when the funding ratio reaches _tar
   * @return _w - The total worth when the funding ratio reaches _tar
   * @return raisedFloorPrice - The floor price after market adjusted
   */
  function estimateRaisePrice(
    uint256 _f,
    uint256 _k,
    uint256 _p,
    uint256 _tar,
    uint256 _tarAdjusted
  )
    external
    pure
    returns (
      bool success,
      uint256 _t,
      uint256 _c,
      uint256 _w,
      uint256 raisedFloorPrice
    );

  /**
   * @dev Lower target and targetAdjusted with lowerStep.
   */
  function lowerAndAdjust() external;

  /**
   * @dev Set market options.
   *      The caller must has MANAGER_ROLE.
   *      This function can only be called before the market is started.
   * @param _k - Slope
   * @param _target - Target funding ratio
   * @param _targetAdjusted - Target adjusted funding ratio
   */
  function setMarketOptions(
    uint256 _k,
    uint32 _target,
    uint32 _targetAdjusted
  ) external;

  /**
   * @dev Set adjust options.
   *      The caller must be owner.
   * @param _minTarget - Minimum value of target
   * @param _maxTargetAdjusted - Maximum value of the targetAdjusted
   * @param _raiseStep - Step value of each raise
   * @param _lowerStep - Step value of each lower
   * @param _lowerInterval - Interval of each lower
   */
  function setAdjustOptions(
    uint32 _minTarget,
    uint32 _maxTargetAdjusted,
    uint32 _raiseStep,
    uint32 _lowerStep,
    uint32 _lowerInterval
  ) external;

  /**
   * @dev Set fee options.
   *      The caller must be owner.
   * @param _dev - Dev address
   * @param _buyFee - Fee for buying Lab
   * @param _sellFee - Fee for selling Lab
   */
  function setFeeOptions(
    address _dev,
    uint32 _buyFee,
    uint32 _sellFee
  ) external;

  /**
   * @dev Manage stablecoins.
   *      Add/Delete token to/from stablecoinsCanBuy/stablecoinsCanSell.
   *      The caller must be owner.
   * @param token - Token address
   * @param buyOrSell - Buy or sell token
   * @param addOrDelete - Add or delete token
   */
  function manageStablecoins(
    address token,
    bool buyOrSell,
    bool addOrDelete
  ) external;

  /**
   * @dev Estimate how much Lab user can buy.
   * @param token - Stablecoin address
   * @param tokenWorth - Number of stablecoins
   * @return amount - Number of Lab
   * @return fee - Dev fee
   * @return worth1e18 - The amount of stablecoins being exchanged(1e18)
   * @return newPrice - New Lab price
   */
  function estimateBuy(address token, uint256 tokenWorth)
    external
    view
    returns (
      uint256 amount,
      uint256 fee,
      uint256 worth1e18,
      uint256 newPrice
    );

  /**
   * @dev Estimate how many stablecoins will be needed to realize prLab.
   * @param amount - Number of prLab user want to realize
   * @param token - Stablecoin address
   * @return worth1e18 - The amount of stablecoins being exchanged(1e18)
   * @return worth - The amount of stablecoins being exchanged
   */
  function estimateRealize(uint256 amount, address token)
    external
    view
    returns (uint256 worth1e18, uint256 worth);

  /**
   * @dev Estimate how much stablecoins user can sell.
   * @param amount - Number of Lab user want to sell
   * @param token - Stablecoin address
   * @return fee - Dev fee
   * @return worth1e18 - The amount of stablecoins being exchanged(1e18)
   * @return worth - The amount of stablecoins being exchanged
   * @return newPrice - New Lab price
   */
  function estimateSell(uint256 amount, address token)
    external
    view
    returns (
      uint256 fee,
      uint256 worth1e18,
      uint256 worth,
      uint256 newPrice
    );

  /**
   * @dev Buy Lab.
   * @param token - Address of stablecoin used to buy Lab
   * @param tokenWorth - Number of stablecoins
   * @param desired - Minimum amount of Lab user want to buy
   * @return amount - Number of Lab
   * @return fee - Dev fee(Lab)
   */
  function buy(
    address token,
    uint256 tokenWorth,
    uint256 desired
  ) external returns (uint256, uint256);

  /**
   * @dev Buy Lab for user.
   * @param token - Address of stablecoin used to buy Lab
   * @param tokenWorth - Number of stablecoins
   * @param desired - Minimum amount of Lab user want to buy
   * @param user - User address
   * @return amount - Number of Lab
   * @return fee - Dev fee(Lab)
   */
  function buyFor(
    address token,
    uint256 tokenWorth,
    uint256 desired,
    address user
  ) external returns (uint256, uint256);

  /**
   * @dev Realize Lab with floor price and equal amount of prLab.
   * @param amount - Amount of prLab user want to realize
   * @param token - Address of stablecoin used to realize prLab
   * @param desired - Maximum amount of stablecoin users are willing to pay
   * @return worth - The amount of stablecoins being exchanged
   */
  function realize(
    uint256 amount,
    address token,
    uint256 desired
  ) external returns (uint256);

  /**
   * @dev Realize Lab with floor price and equal amount of prLab for user.
   * @param amount - Amount of prLab user want to realize
   * @param token - Address of stablecoin used to realize prLab
   * @param desired - Maximum amount of stablecoin users are willing to pay
   * @param user - User address
   * @return worth - The amount of stablecoins being exchanged
   */
  function realizeFor(
    uint256 amount,
    address token,
    uint256 desired,
    address user
  ) external returns (uint256);

  /**
   * @dev Sell Lab.
   * @param amount - Amount of Lab user want to sell
   * @param token - Address of stablecoin used to buy Lab
   * @param desired - Minimum amount of stablecoins user want to get
   * @return fee - Dev fee(Lab)
   * @return worth - The amount of stablecoins being exchanged
   */
  function sell(
    uint256 amount,
    address token,
    uint256 desired
  ) external returns (uint256, uint256);

  /**
   * @dev Sell Lab for user.
   * @param amount - Amount of Lab user want to sell
   * @param token - Address of stablecoin used to buy Lab
   * @param desired - Minimum amount of stablecoins user want to get
   * @param user - User address
   * @return fee - Dev fee(Lab)
   * @return worth - The amount of stablecoins being exchanged
   */
  function sellFor(
    uint256 amount,
    address token,
    uint256 desired,
    address user
  ) external returns (uint256, uint256);

  /**
   * @dev Burn Lab.
   *      It will preferentially transfer the excess value after burning to PSL.
   * @param amount - The amount of Lab the user wants to burn
   */
  function burn(uint256 amount) external;

  /**
   * @dev Burn Lab for user.
   *      It will preferentially transfer the excess value after burning to PSL.
   * @param amount - The amount of Lab the user wants to burn
   * @param user - User address
   */
  function burnFor(uint256 amount, address user) external;

  /**
   * @dev Triggers stopped state.
   *      The caller must be owner.
   */
  function pause() external;

  /**
   * @dev Returns to normal state.
   *      The caller must be owner.
   */
  function unpause() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IERC20BurnableMinter.sol";
import "./IBank.sol";

// The stakepool will mint prLab according to the total supply of Lab and
// then distribute it to all users according to the amount of Lab deposited by each user.
// Info of each pool.
struct PoolInfo {
  IERC20 lpToken; // Address of LP token contract.
  uint256 allocPoint; // How many allocation points assigned to this pool. prLabs to distribute per block.
  uint256 lastRewardBlock; // Last block number that prLabs distribution occurs.
  uint256 accPerShare; // Accumulated prLabs per share, times 1e12. See below.
}

// Info of each user.
struct UserInfo {
  uint256 amount; // How many LP tokens the user has provided.
  uint256 rewardDebt; // Reward debt. See explanation below.
  //
  // We do some fancy math here. Basically, any point in time, the amount of prLabs
  // entitled to a user but is pending to be distributed is:
  //
  //   pending reward = (user.amount * pool.accPerShare) - user.rewardDebt
  //
  // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
  //   1. The pool's `accPerShare` (and `lastRewardBlock`) gets updated.
  //   2. User receives the pending reward sent to his/her address.
  //   3. User's `amount` gets updated.
  //   4. User's `rewardDebt` gets updated.
}

interface IStakePool {
  // The Lab token
  function Lab() external view returns (IERC20);

  // The prLab token
  function prLab() external view returns (IERC20BurnableMinter);

  // The bank contract address
  function bank() external view returns (IBank);

  // Info of each pool.
  function poolInfo(uint256 index)
    external
    view
    returns (
      IERC20,
      uint256,
      uint256,
      uint256
    );

  // Info of each user that stakes LP tokens.
  function userInfo(uint256 pool, address user)
    external
    view
    returns (uint256, uint256);

  // Total allocation poitns. Must be the sum of all allocation points in all pools.
  function totalAllocPoint() external view returns (uint256);

  // Daily minted Lab as a percentage of total supply, the value is mintPercentPerDay / 1000.
  function mintPercentPerDay() external view returns (uint32);

  // How many blocks are there in a day.
  function blocksPerDay() external view returns (uint256);

  // Developer address.
  function dev() external view returns (address);

  // Withdraw fee(Lab).
  function withdrawFee() external view returns (uint32);

  // Mint fee(prLab).
  function mintFee() external view returns (uint32);

  // Constructor.
  function constructor1(
    IERC20 _Lab,
    IERC20BurnableMinter _prLab,
    IBank _bank,
    address _owner
  ) external;

  function poolLength() external view returns (uint256);

  // Add a new lp to the pool. Can only be called by the owner.
  // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
  function add(
    uint256 _allocPoint,
    IERC20 _lpToken,
    bool _withUpdate
  ) external;

  // Update the given pool's prLab allocation point. Can only be called by the owner.
  function set(
    uint256 _pid,
    uint256 _allocPoint,
    bool _withUpdate
  ) external;

  // Set options. Can only be called by the owner.
  function setOptions(
    uint32 _mintPercentPerDay,
    uint256 _blocksPerDay,
    address _dev,
    uint32 _withdrawFee,
    uint32 _mintFee,
    bool _withUpdate
  ) external;

  // View function to see pending prLabs on frontend.
  function pendingRewards(uint256 _pid, address _user)
    external
    view
    returns (uint256);

  // Update reward vairables for all pools. Be careful of gas spending!
  function massUpdatePools() external;

  // Deposit LP tokens to StakePool for prLab allocation.
  function deposit(uint256 _pid, uint256 _amount) external;

  // Deposit LP tokens to StakePool for user for prLab allocation.
  function depositFor(
    uint256 _pid,
    uint256 _amount,
    address _user
  ) external;

  // Withdraw LP tokens from StakePool.
  function withdraw(uint256 _pid, uint256 _amount) external;

  // Claim reward.
  function claim(uint256 _pid) external;

  // Claim reward for user.
  function claimFor(uint256 _pid, address _user) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

library MathNew {
  // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
  function sqrt(uint256 y) internal pure returns (uint256 z) {
    if (y > 3) {
      z = y;
      uint256 x = y / 2 + 1;
      while (x < z) {
        z = x;
        x = (y / x + x) / 2;
      }
    } else if (y != 0) {
      z = 1;
    }
  }

  /**
   * @dev Convert value from srcDecimals to dstDecimals.
   */
  function convertDecimals(
    uint256 value,
    uint8 srcDecimals,
    uint8 dstDecimals
  ) internal pure returns (uint256 result) {
    if (srcDecimals == dstDecimals) {
      result = value;
    } else if (srcDecimals < dstDecimals) {
      result = value * (10**(dstDecimals - srcDecimals));
    } else {
      result = value / (10**(srcDecimals - dstDecimals));
    }
  }

  /**
   * @dev Convert value from srcDecimals to dstDecimals, rounded up.
   */
  function convertDecimalsCeil(
    uint256 value,
    uint8 srcDecimals,
    uint8 dstDecimals
  ) internal pure returns (uint256 result) {
    if (srcDecimals == dstDecimals) {
      result = value;
    } else if (srcDecimals < dstDecimals) {
      result = value * (10**(dstDecimals - srcDecimals));
    } else {
      uint256 temp = 10**(srcDecimals - dstDecimals);
      result = value / temp;
      if (value % temp != 0) {
        result += 1;
      }
    }
  }
}