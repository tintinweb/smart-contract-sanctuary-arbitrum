// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import { ERC165CheckerUpgradeable as ERC165Checker } from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import { IERC20Upgradeable as IERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { IERC20MetadataUpgradeable as IERC20Metadata } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import { SafeERC20Upgradeable as SafeERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/beacon/IFrabricBeacon.sol";
import "../interfaces/erc20/IAuction.sol";
import { IFrabricWhitelistCore, IFrabricERC20, IFrabricERC20Initializable } from "../interfaces/erc20/IFrabricERC20.sol";
import "../interfaces/thread/IThread.sol";
import "../interfaces/thread/ICrowdfund.sol";
import { ITimelock } from "../interfaces/erc20/ITimelock.sol";

import "../common/Composable.sol";

import "../interfaces/thread/IThreadDeployer.sol";

contract ThreadDeployer is OwnableUpgradeable, Composable, IThreadDeployerInitializable {
  using ERC165Checker for address;
  using SafeERC20 for IERC20;

  // 6% fee given to the Frabric
  // Since the below code actually does 100% + 6%, this ends up as 5.66%
  // 1% is distributed per month via the timelock
  uint8 constant public override percentage = 6;

  address public override crowdfundProxy;
  address public override erc20Beacon;
  address public override threadBeacon;
  address public override auction;
  address public override timelock;

  function initialize(
    address _crowdfundProxy,
    address _erc20Beacon,
    address _threadBeacon,
    address _auction,
    address _timelock
  ) external override initializer {
    // Intended to be owned by the Frabric
    __Ownable_init();

    __Composable_init("ThreadDeployer", false);
    supportsInterface[type(OwnableUpgradeable).interfaceId] = true;
    supportsInterface[type(IThreadDeployer).interfaceId] = true;

    if (
      (!_crowdfundProxy.supportsInterface(type(IFrabricBeacon).interfaceId)) ||
      (IFrabricBeacon(_crowdfundProxy).beaconName() != keccak256("Crowdfund"))
    ) {
      revert errors.UnsupportedInterface(_crowdfundProxy, type(IFrabricBeacon).interfaceId);
    }

    if (
      (!_erc20Beacon.supportsInterface(type(IFrabricBeacon).interfaceId)) ||
      (IFrabricBeacon(_erc20Beacon).beaconName() != keccak256("FrabricERC20"))
    ) {
      revert errors.UnsupportedInterface(_erc20Beacon, type(IFrabricBeacon).interfaceId);
    }

    if (
      (!_threadBeacon.supportsInterface(type(IFrabricBeacon).interfaceId)) ||
      (IFrabricBeacon(_threadBeacon).beaconName() != keccak256("Thread"))
    ) {
      revert errors.UnsupportedInterface(_threadBeacon, type(IFrabricBeacon).interfaceId);
    }

    // This is technically a beacon to keep things consistent
    // That said, it can't actually upgrade itself and has no owner to upgrade it
    // Because of that, it's called a proxy instead of a beacon
    crowdfundProxy = _crowdfundProxy;
    // Beacons which allow code to be changed by the contract itself or its owner
    // Allows Threads upgrading individually
    erc20Beacon = _erc20Beacon;
    threadBeacon = _threadBeacon;

    if (!_auction.supportsInterface(type(IAuctionCore).interfaceId)) {
      revert errors.UnsupportedInterface(_auction, type(IAuctionCore).interfaceId);
    }

    if (!_timelock.supportsInterface(type(ITimelock).interfaceId)) {
      revert errors.UnsupportedInterface(_timelock, type(ITimelock).interfaceId);
    }

    auction = _auction;
    timelock = _timelock;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() Composable("ThreadDeployer") initializer {}

  // Validates a variant and byte data
  function validate(uint8 variant, bytes calldata data) external override view {
    // CrowdfundedThread variant. To be converted to an enum later
    if (variant == 0) {
      if (data.length != 64) {
        revert DifferentLengths(data.length, 64);
      }
      (address tradeToken, ) = abi.decode(data, (address, uint112));
      if (IERC20(tradeToken).totalSupply() < 2) {
        revert errors.UnsupportedInterface(tradeToken, type(IERC20).interfaceId);
      }
    } else {
      revert UnknownVariant(variant);
    }
  }

  // Dedicated function to resolve stack depth errors
  function deployThread(
    string memory name,
    address erc20,
    bytes32 descriptor,
    address governor,
    address crowdfund
  ) private returns (address) {
    // Prevent participant removals against the following
    address[] memory irremovable = new address[](3);
    irremovable[0] = msg.sender;
    irremovable[1] = timelock;
    irremovable[2] = crowdfund;
    // We could also include the Auction contract here, or an eventual Uniswap pair
    // The first can't be done, as it'll be removed and then transferred its own tokens
    // to be put up for Auction, which will error. The latter isn't present here
    // and may never exist. Beyond the stupidity of attacking core infrastructure,
    // there's no successful game theory incentives to doing it, hence why it's just these

    return address(new BeaconProxy(
      threadBeacon,
      abi.encodeWithSelector(
        IThreadInitializable.initialize.selector,
        name,
        erc20,
        descriptor,
        msg.sender,
        governor,
        irremovable
      )
    ));
  }

  function initERC20(
    address erc20,
    string memory name,
    string memory symbol,
    uint256 threadBaseTokenSupply,
    address parent,
    address tradeToken
  ) private returns (uint256) {
    // Since the Crowdfund needs the decimals of both tokens (raise and Thread),
    // yet the ERC20 isn't initialized yet, ensure the decimals are static
    // Prevents anyone from editing the FrabricERC20 and this initialize call
    // without hitting actual errors during testing
    // Thoroughly documented in Crowdfund
    uint8 decimals = IERC20Metadata(erc20).decimals();

    // Add 6% on top for the Frabric
    uint256 threadTokenSupply = threadBaseTokenSupply * (100 + uint256(percentage)) / 100;

    IFrabricERC20Initializable(erc20).initialize(
      name,
      symbol,
      threadTokenSupply,
      parent,
      tradeToken,
      auction
    );

    if (decimals != IERC20Metadata(erc20).decimals()) {
      revert NonStaticDecimals(decimals, IERC20Metadata(erc20).decimals());
    }

    return threadTokenSupply - threadBaseTokenSupply;
  }

  // onlyOwner to ensure all Thread events represent Frabric Threads
  // Takes in a variant in order to support multiple variations easily in the future
  // This could be anything from different Thread architectures to different lockup schemes
  function deploy(
    // Not an enum so the ThreadDeployer can be upgraded with more without requiring
    // the Frabric to also be upgraded
    // Is an uint8 so this contract can use it as an enum if desired in the future
    uint8 _variant,
    string memory _name,
    string memory _symbol,
    bytes32 _descriptor,
    address _governor,
    bytes calldata data
  ) external override onlyOwner {
    // Fixes stack too deep errors
    uint8 variant = _variant;
    string memory name = _name;
    string memory symbol = _symbol;
    bytes32 descriptor = _descriptor;
    address governor = _governor;

    // CrowdfundedThread variant. To be converted to an enum later
    if (variant != 0) {
      revert UnknownVariant(variant);
    }

    (address tradeToken, uint112 target) = abi.decode(data, (address, uint112));

    // Don't initialize the ERC20/Crowdfund yet
    // It may be advantageous to utilize CREATE2 here, yet probably doesn't matter
    address erc20 = address(new BeaconProxy(erc20Beacon, bytes("")));
    address crowdfund = address(new BeaconProxy(crowdfundProxy, bytes("")));

    // Deploy and initialize the Thread
    address thread = deployThread(name, erc20, descriptor, governor, crowdfund);

    address parent = IDAOCore(msg.sender).erc20();

    // Initialize the Crowdfund
    uint256 threadBaseTokenSupply = ICrowdfundInitializable(crowdfund).initialize(
      name,
      symbol,
      parent,
      governor,
      thread,
      tradeToken,
      target
    );

    // Initialize the ERC20 now that we can call the Crowdfund contract for decimals
    uint256 frabricShare = initERC20(
      erc20,
      name,
      symbol,
      threadBaseTokenSupply,
      parent,
      tradeToken
    );

    // Whitelist the Crowdfund and transfer the Thread tokens to it
    IFrabricWhitelistCore(erc20).whitelist(crowdfund);
    IERC20(erc20).safeTransfer(crowdfund, threadBaseTokenSupply);

    // Whitelist Timelock to hold the additional tokens
    // This could be done at a global level given how all Thread tokens sync with this contract
    // That said, not whitelisting it globally avoids FRBC from being sent here accidentally
    IFrabricWhitelistCore(erc20).whitelist(timelock);

    // Create the lock and transfer the additional tokens to it
    // Schedule it to release at 1% per month
    ITimelock(timelock).lock(erc20, percentage);
    IERC20(erc20).safeTransfer(timelock, frabricShare);

    // Remove ourself from the token's whitelist
    IFrabricERC20(erc20).remove(address(this), 0);

    // Transfer token ownership to the Thread
    OwnableUpgradeable(erc20).transferOwnership(thread);

    // Doesn't include name/symbol due to stack depth issues
    // descriptor is sufficient to confirm which of the Frabric's events this lines up with,
    // assuming it's unique, which it always should be (though this isn't explicitly confirmed on chain)
    emit Thread(thread, variant, governor, erc20, descriptor);
    emit CrowdfundedThread(thread, tradeToken, crowdfund, target);
  }

  // Recover tokens sent here
  function recover(address erc20) public override {
    IERC20(erc20).safeTransfer(owner(), IERC20(erc20).balanceOf(address(this)));
  }

  // Claim a timelock (which sends tokens here) and forward them to the Frabric
  // Purely a helper function
  function claimTimelock(address erc20) external override {
    ITimelock(timelock).claim(erc20);
    recover(erc20);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165CheckerUpgradeable {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165Upgradeable).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165Upgradeable.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/BeaconProxy.sol)

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../Proxy.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from a {UpgradeableBeacon}.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */
contract BeaconProxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializating the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    constructor(address beacon, bytes memory data) payable {
        assert(_BEACON_SLOT == bytes32(uint256(keccak256("eip1967.proxy.beacon")) - 1));
        _upgradeBeaconToAndCall(beacon, data, false);
    }

    /**
     * @dev Returns the current beacon address.
     */
    function _beacon() internal view virtual returns (address) {
        return _getBeacon();
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation() internal view virtual override returns (address) {
        return IBeacon(_getBeacon()).implementation();
    }

    /**
     * @dev Changes the proxy to use a new beacon. Deprecated: see {_upgradeBeaconToAndCall}.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon.
     *
     * Requirements:
     *
     * - `beacon` must be a contract.
     * - The implementation returned by `beacon` must be a contract.
     */
    function _setBeacon(address beacon, bytes memory data) internal virtual {
        _upgradeBeaconToAndCall(beacon, data, false);
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.9;

import "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";

import "../common/IComposable.sol";

interface IFrabricBeacon is IBeacon, IComposable {
  event Upgrade(address indexed instance, uint256 indexed version, address indexed code, bytes data);
  event Upgraded(address indexed instance, uint256 indexed version);

  // Name of the contract this beacon points to
  function beaconName() external view returns (bytes32);

  // Amount of release channels
  function releaseChannels() external view returns (uint8);

  // Raw address mapping. This does not perform resolution
  function implementations(address code) external view returns (address);

  // Raw upgrade data mapping. This does not perform resolution
  function upgradeDatas(address instance, uint256 version) external view returns (bytes memory);

  // Implementation resolver for a given instance
  // IBeacon has an implementation function defined yet it doesn't take an argument
  // as OZ beacons only expect to handle a single implementation address
  function implementation(address instance) external view returns (address);

  // Upgrade data resolution for a given instance
  function upgradeData(address instance, uint256 version) external view returns (bytes memory);

  // Upgrade to different code/forward to a different beacon
  function upgrade(address instance, uint256 version, address code, bytes calldata data) external;

  // Trigger an upgrade for the specified contract
  function triggerUpgrade(address instance, uint256 version) external;
}

// Errors used by Beacon
error InvalidCode(address code);
// Caller may be a bit extra, yet these only cost gas when executed
// The fact wallets try execution before sending transactions should mean this is a non-issue
error NotOwner(address caller, address owner);
error NotUpgradeAuthority(address caller, address instance);
error DifferentContract(bytes32 oldName, bytes32 newName);
error InvalidVersion(uint256 version, uint256 expectedVersion);
error NotUpgrade(address code);
error UpgradeDataForInitial(address instance);

// Errors used by SingleBeacon
// SingleBeacons only allow its singular release channel to be upgraded
error UpgradingInstance(address instance);

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.9;

import {errors} from "../common/Errors.sol";
import "../common/IComposable.sol";

// When someone is removed, each FrabricERC20 will list the removed party's tokens
// for auction. This is done with the following listing API which is separated out
// for greater flexibility in the future
interface IAuctionCore is IComposable {
  // Indexes the ID as expected, the seller so people can find their own auctions
  // which they need to complete, and the token so people can find auctions by the token being sold
  event Auctions(
    uint256 indexed startID,
    address indexed seller,
    address indexed token,
    address traded,
    uint256 total,
    uint8 quantity,
    uint64 start,
    uint32 length
  );

  function list(
    address seller,
    address token,
    address traded,
    uint256 amount,
    uint8 batches,
    uint64 start,
    uint32 length
  ) external returns (uint256 id);
}

interface IAuction is IAuctionCore {
  event Bid(uint256 indexed id, address bidder, uint256 amount);
  event AuctionComplete(uint256 indexed id);
  event BurnFailed(address indexed token, uint256 amount);

  function balances(address token, address amount) external returns (uint256);

  function bid(uint256 id, uint256 amount) external;
  function complete(uint256 id) external;
  function withdraw(address token, address trader) external;

  function active(uint256 id) external view returns (bool);
  // Will only work for auctions which have yet to complete
  function token(uint256 id) external view returns (address);
  function traded(uint256 id) external view returns (address);
  function amount(uint256 id) external view returns (uint256);
  function highBidder(uint256 id) external view returns (address);
  function highBid(uint256 id) external view returns (uint256);
  function end(uint256 id) external view returns (uint64);
}

interface IAuctionInitializable is IAuction {
  function initialize() external;
}

error AuctionPending(uint256 time, uint256 start);
error AuctionOver(uint256 time, uint256 end);
error BidTooLow(uint256 bid, uint256 currentBid);
error HighBidder(address bidder);
error AuctionActive(uint256 time, uint256 end);

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.9;

import "./IDistributionERC20.sol";
import "./IFrabricWhitelist.sol";
import "./IIntegratedLimitOrderDEX.sol";

interface IRemovalFee {
  function removalFee(address person) external view returns (uint8);
}

interface IFreeze {
  event Freeze(address indexed person, uint64 until);

  function frozenUntil(address person) external view returns (uint64);
  function frozen(address person) external returns (bool);

  function freeze(address person, uint64 until) external;
  function triggerFreeze(address person) external;
}

interface IFrabricERC20 is IDistributionERC20, IFrabricWhitelist, IRemovalFee, IFreeze, IIntegratedLimitOrderDEX {
  event Removal(address indexed person, uint256 balance);

  function auction() external view returns (address);

  function mint(address to, uint256 amount) external;
  function burn(uint256 amount) external;

  function remove(address participant, uint8 fee) external;
  function triggerRemoval(address person) external;

  function paused() external view returns (bool);
  function pause() external;
}

interface IFrabricERC20Initializable is IFrabricERC20 {
  function initialize(
    string memory name,
    string memory symbol,
    uint256 supply,
    address parent,
    address tradeToken,
    address auction
  ) external;
}

error SupplyExceedsInt112(uint256 supply, int112 max);
error Frozen(address person);
error NothingToRemove(address person);
// Not Paused due to an overlap with the event
error CurrentlyPaused();
error Locked(address person, uint256 balanceAfterTransfer, uint256 lockedBalance);

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.9;

import "../dao/IFrabricDAO.sol";

interface IThreadTimelock {
  function upgradesEnabled() external view returns (uint256);
}

interface IThread is IFrabricDAO, IThreadTimelock {
  event DescriptorChangeProposal(uint256 id, bytes32 indexed descriptor);
  event FrabricChangeProposal(uint256 indexed id, address indexed frabric, address indexed governor);
  event GovernorChangeProposal(uint256 indexed id, address indexed governor);
  event EcosystemLeaveWithUpgradesProposal(uint256 indexed id, address indexed frabric, address indexed governor);
  event DissolutionProposal(uint256 indexed id, address indexed token, uint256 price);

  event DescriptorChange(bytes32 indexed oldDescriptor, bytes32 indexed newDescriptor);
  event FrabricChange(address indexed oldFrabric, address indexed newFrabric);
  event GovernorChange(address indexed oldGovernor, address indexed newGovernor);

  enum ThreadProposalType {
    DescriptorChange,
    FrabricChange,
    GovernorChange,
    EcosystemLeaveWithUpgrades,
    Dissolution
  }

  function descriptor() external view returns (bytes32);
  function governor() external view returns (address);
  function frabric() external view returns (address);
  function irremovable(address participant) external view returns (bool);

  function proposeDescriptorChange(
    bytes32 _descriptor,
    bytes32 info
  ) external returns (uint256);
  function proposeFrabricChange(
    address _frabric,
    address _governor,
    bytes32 info
  ) external returns (uint256);
  function proposeGovernorChange(
    address _governor,
    bytes32 info
  ) external returns (uint256);
  function proposeEcosystemLeaveWithUpgrades(
    address newFrabric,
    address newGovernor,
    bytes32 info
  ) external returns (uint256);
  function proposeDissolution(
    address token,
    uint112 price,
    bytes32 info
  ) external returns (uint256);
}

interface IThreadInitializable is IThread {
  function initialize(
    string memory name,
    address erc20,
    bytes32 descriptor,
    address frabric,
    address governor,
    address[] calldata irremovable
  ) external;
}

error NotGovernor(address caller, address governor);
error ProposingUpgrade(address beacon, address instance, address code);
error NotLeaving(address frabric, address newFrabric);

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.9;

// Imports the ILO DEX interface due to shared errors
import "../erc20/IIntegratedLimitOrderDEX.sol";

import "../erc20/IDistributionERC20.sol";

interface ICrowdfund is IDistributionERC20 {
  enum State {
    Active,
    Executing,
    Refunding,
    Finished
  }

  event StateChange(State indexed state);
  event Deposit(address indexed depositor, uint112 amount);
  event Withdraw(address indexed depositor, uint112 amount);
  event Refund(address indexed depositor, uint112 refundAmount);

  function whitelist() external view returns (address);

  function governor() external view returns (address);
  function thread() external view returns (address);

  function token() external view returns (address);
  function target() external view returns (uint112);
  function outstanding() external view returns (uint112);
  function lastDepositTime() external view returns (uint64);

  function state() external view returns (State);

  function normalizeRaiseToThread(uint256 amount) external returns (uint256);

  function deposit(uint112 amount) external returns (uint112);
  function withdraw(uint112 amount) external;
  function cancel() external;
  function execute() external;
  function refund(uint112 amount) external;
  function finish() external;
  function redeem(address depositor) external;
}

interface ICrowdfundInitializable is ICrowdfund {
  function initialize(
    string memory name,
    string memory symbol,
    address _whitelist,
    address _governor,
    address _thread,
    address _token,
    uint112 _target
  ) external returns (uint256);
}

error CrowdfundTransfer();
error InvalidState(ICrowdfund.State current, ICrowdfund.State expected);
error CrowdfundReached();
error CrowdfundNotReached();

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.9;

import "../common/IComposable.sol";

interface ITimelock is IComposable {
  event Lock(address indexed token, uint8 indexed months);
  event Claim(address indexed token, uint256 amount);

  function lock(address token, uint8 months) external;
  function claim(address token) external;

  function nextLockTime(address token) external view returns (uint64);
  function remainingMonths(address token) external view returns (uint8);
}

error AlreadyLocked(address token);
error Locked(address token, uint256 time, uint256 nextTime);

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.9;

import "../interfaces/common/IComposable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract Composable is Initializable, IComposable {
  // Doesn't use "name" due to IERC20 using "name"
  bytes32 public override contractName;
  // Version is global, and not per-interface, as interfaces aren't "DAO" and "FrabricDAO"
  // Any version which changes the API would change the interface ID, so checking
  // for supported functionality should be via supportsInterface, not version
  uint256 public override version;
  mapping(bytes4 => bool) public override supportsInterface;

  // While this could probably get away with 5 variables, and other contracts
  // with 20, the fact this is free (and a permanent decision) leads to using
  // these large gaps
  uint256[100] private __gap;

  // Code should set its name so Beacons can identify code
  // That said, code shouldn't declare support for interfaces or have any version
  // Hence this
  // Due to solidity requirements, final constracts (non-proxied) which call init
  // yet still use constructors will have to call this AND init. It's a minor
  // gas inefficiency not worth optimizing around
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor(string memory name) {
    contractName = keccak256(bytes(name));

    supportsInterface[type(IERC165Upgradeable).interfaceId] = true;
    supportsInterface[type(IComposable).interfaceId] = true;
  }

  function __Composable_init(string memory name, bool finalized) internal onlyInitializing {
    contractName = keccak256(bytes(name));
    if (!finalized) {
      version = 1;
    } else {
      version = type(uint256).max;
    }

    supportsInterface[type(IERC165Upgradeable).interfaceId] = true;
    supportsInterface[type(IComposable).interfaceId] = true;
  }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.9;

import "../common/IComposable.sol";

interface IThreadDeployer is IComposable {
  event Thread(
    address indexed thread,
    uint8 indexed variant,
    address indexed governor,
    address erc20,
    bytes32 descriptor
  );

  event CrowdfundedThread(address indexed thread, address indexed token, address indexed crowdfund, uint112 target);

  function percentage() external view returns (uint8);
  function crowdfundProxy() external view returns (address);
  function erc20Beacon() external view returns (address);
  function threadBeacon() external view returns (address);
  function auction() external view returns (address);
  function timelock() external view returns (address);

  function validate(uint8 variant, bytes calldata data) external view;

  function deploy(
    uint8 variant,
    string memory name,
    string memory symbol,
    bytes32 descriptor,
    address governor,
    bytes calldata data
  ) external;

  function recover(address erc20) external;
  function claimTimelock(address erc20) external;
}

interface IThreadDeployerInitializable is IThreadDeployer {
  function initialize(
    address crowdfundProxy,
    address erc20Beacon,
    address threadBeacon,
    address auction,
    address timelock
  ) external;
}

error UnknownVariant(uint8 id);
error NonStaticDecimals(uint8 beforeDecimals, uint8 afterDecimals);

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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
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

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

interface IComposable is IERC165Upgradeable {
  function contractName() external returns (bytes32);
  // Returns uint256 max if not upgradeable
  function version() external returns (uint256);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.9;

library errors {
    error UnhandledEnumCase(string label, uint256 enumValue);
    error ZeroPrice();
    error ZeroAmount();

    error UnsupportedInterface(address contractAddress, bytes4 interfaceID);

    error ExternalCallFailed(address called, bytes4 selector, bytes error);

    error Unauthorized(address caller, address user);
    error Replay(uint256 nonce, uint256 expected);

}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.9;

import { IERC20Upgradeable as IERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/utils/IVotesUpgradeable.sol";

import { errors} from "../common/Errors.sol";
import "../common/IComposable.sol";

interface IDistributionERC20 is IVotesUpgradeable, IERC20, IComposable {
  event Distribution(uint256 indexed id, address indexed token, uint112 amount);
  event Claim(uint256 indexed id, address indexed person, uint112 amount);

  function claimed(uint256 id, address person) external view returns (bool);

  function distribute(address token, uint112 amount) external returns (uint256 id);
  function claim(uint256 id, address person) external;
}

error Delegation();
error FeeOnTransfer(address token);
error AlreadyClaimed(uint256 id, address person);

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.9;

import {errors} from "../common/Errors.sol";
import "../common/IComposable.sol";

interface IFrabricWhitelistCore is IComposable {
  event Whitelisted(address indexed person, bool indexed whitelisted);

  // The ordinal value of the enum increases with accreditation
  enum Status {
    Null,
    Removed,
    Whitelisted,
    KYC
  }

  function parent() external view returns (address);

  function setParent(address parent) external;
  function whitelist(address person) external;
  function setKYC(address person, bytes32 hash, uint256 nonce) external;

  function whitelisted(address person) external view returns (bool);
  function hasKYC(address person) external view returns (bool);
  function removed(address person) external view returns (bool);
  function status(address person) external view returns (Status);
}

interface IFrabricWhitelist is IFrabricWhitelistCore {
  event ParentChange(address oldParent, address newParent);
  // Info shouldn't be indexed when you consider it's unique per-person
  // Indexing it does allow retrieving the address of a person by their KYC however
  // It's also just 750 gas on an infrequent operation
  event KYCUpdate(address indexed person, bytes32 indexed oldInfo, bytes32 indexed newInfo, uint256 nonce);
  event GlobalAcceptance();

  function global() external view returns (bool);

  function kyc(address person) external view returns (bytes32);
  function kycNonces(address person) external view returns (uint256);
  function explicitlyWhitelisted(address person) external view returns (bool);
  function removedAt(address person) external view returns (uint256);
}

error AlreadyWhitelisted(address person);
error Removed(address person);
error NotWhitelisted(address person);
error NotRemoved(address person);
error NotKYC(address person);

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.9;

import {errors} from "../common/Errors.sol";
import "../common/IComposable.sol";

interface IIntegratedLimitOrderDEXCore {
  enum OrderType { Null, Buy, Sell }

  event Order(OrderType indexed orderType, uint256 indexed price);
  event OrderIncrease(address indexed trader, uint256 indexed price, uint256 amount);
  event OrderFill(address indexed orderer, uint256 indexed price, address indexed executor, uint256 amount);
  event OrderCancelling(address indexed trader, uint256 indexed price);
  event OrderCancellation(address indexed trader, uint256 indexed price, uint256 amount);

  // Part of core to symbolize amount should always be whole while price is atomic
  function atomic(uint256 amount) external view returns (uint256);

  function tradeToken() external view returns (address);

  // sell is here as the FrabricDAO has the ability to sell tokens on their integrated DEX
  // That means this function API can't change (along with cancelOrder which FrabricDAO also uses)
  // buy is meant to be used by users, offering greater flexibility, especially as it has a router for a frontend
  function sell(uint256 price, uint256 amount) external returns (uint256);
  function cancelOrder(uint256 price, uint256 i) external returns (bool);
}

interface IIntegratedLimitOrderDEX is IComposable, IIntegratedLimitOrderDEXCore {
  function tradeTokenBalance() external view returns (uint256);
  function tradeTokenBalances(address trader) external view returns (uint256);
  function locked(address trader) external view returns (uint256);

  function withdrawTradeToken(address trader) external;

  function buy(
    address trader,
    uint256 price,
    uint256 minimumAmount
  ) external returns (uint256);

  function pointType(uint256 price) external view returns (IIntegratedLimitOrderDEXCore.OrderType);
  function orderQuantity(uint256 price) external view returns (uint256);
  function orderTrader(uint256 price, uint256 i) external view returns (address);
  function orderAmount(uint256 price, uint256 i) external view returns (uint256);
}

error LessThanMinimumAmount(uint256 amount, uint256 minimumAmount);
error NotEnoughFunds(uint256 required, uint256 balance);
error NotOrderTrader(address caller, address trader);

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (governance/utils/IVotes.sol)
pragma solidity ^0.8.0;

/**
 * @dev Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.
 *
 * _Available since v4.5._
 */
interface IVotesUpgradeable {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     */
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`).
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) external view returns (address);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) external;

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.9;

import "./IDAO.sol";

interface IFrabricDAO is IDAO {
  enum CommonProposalType {
    Paper,
    Upgrade,
    TokenAction,
    ParticipantRemoval
  }

  event UpgradeProposal(
    uint256 indexed id,
    address indexed beacon,
    address indexed instance,
    uint256 version,
    address code,
    bytes data
  );
  event TokenActionProposal(
    uint256 indexed id,
    address indexed token,
    address indexed target,
    bool mint,
    uint256 price,
    uint256 amount
  );
  event ParticipantRemovalProposal(uint256 indexed id, address participant, uint8 fee);

  function commonProposalBit() external view returns (uint16);
  function maxRemovalFee() external view returns (uint8);

  function proposePaper(bool supermajority, bytes32 info) external returns (uint256);
  function proposeUpgrade(
    address beacon,
    address instance,
    uint256 version,
    address code,
    bytes calldata data,
    bytes32 info
  ) external returns (uint256);
  function proposeTokenAction(
    address token,
    address target,
    bool mint,
    uint256 price,
    uint256 amount,
    bytes32 info
  ) external returns (uint256);
  function proposeParticipantRemoval(
    address participant,
    uint8 removalFee,
    bytes[] calldata signatures,
    bytes32 info
  ) external returns (uint256);
}

error Irremovable(address participant);
error InvalidRemovalFee(uint8 fee, uint8 max);
error Minting();
error MintingDifferentToken(address specified, address token);
error TargetMalleability(address target, address expected);
error NotRoundAmount(uint256 amount);

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.9;

import {errors} from "../common/Errors.sol";
import "../common/IComposable.sol";

// Only commit to a fraction of the DAO API at this time
// Voting/cancellation/queueing may undergo significant changes in the future
interface IDAOCore is IComposable {
  enum ProposalState {
    Null,
    Active,
    Queued,
    Executed,
    Cancelled
  }

  event Proposal(
    uint256 indexed id,
    uint256 indexed proposalType,
    address indexed creator,
    bool supermajority,
    bytes32 info
  );
  event ProposalStateChange(uint256 indexed id, ProposalState indexed state);

  function erc20() external view returns (address);
  function votingPeriod() external view returns (uint64);
  function passed(uint256 id) external view returns (bool);

  function canPropose(address proposer) external view returns (bool);
  function proposalActive(uint256 id) external view returns (bool);

  function completeProposal(uint256 id, bytes calldata data) external;
  function withdrawProposal(uint256 id) external;
}

interface IDAO is IDAOCore {
  // Solely used to provide indexing based on how people voted
  // Actual voting uses a signed integer at this time
  enum VoteDirection {
    Abstain,
    Yes,
    No
  }

  event Vote(uint256 indexed id, VoteDirection indexed direction, address indexed voter, uint112 votes);

  function queuePeriod() external view returns (uint64);
  function lapsePeriod() external view returns (uint64);
  function requiredParticipation() external view returns (uint112);

  function vote(uint256[] calldata id, int112[] calldata votes) external;
  function queueProposal(uint256 id) external;
  function cancelProposal(uint256 id, address[] calldata voters) external;

  function nextProposalID() external view returns (uint256);

  // Will only work for proposals pre-finalization
  function supermajorityRequired(uint256 id) external view returns (bool);
  function voteBlock(uint256 id) external view returns (uint32);
  function netVotes(uint256 id) external view returns (int112);
  function totalVotes(uint256 id) external view returns (uint112);

  // Will work even with finalized proposals (cancelled/completed)
  function voteRecord(uint256 id, address voter) external view returns (int112);
}

error DifferentLengths(uint256 lengthA, uint256 lengthB);
error InactiveProposal(uint256 id);
error ActiveProposal(uint256 id, uint256 time, uint256 endTime);
error ProposalFailed(uint256 id, int256 votes);
error NotEnoughParticipation(uint256 id, uint256 totalVotes, uint256 required);
error NotQueued(uint256 id, IDAO.ProposalState state);
// Doesn't include what they did vote as it's irrelevant
error NotYesVote(uint256 id, address voter);
error UnsortedVoter(address voter);
error ProposalPassed(uint256 id, int256 votes);
error StillQueued(uint256 id, uint256 time, uint256 queuedUntil);