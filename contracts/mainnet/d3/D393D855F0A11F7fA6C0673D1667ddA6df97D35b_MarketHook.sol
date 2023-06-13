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
interface IERC20PermitUpgradeable {
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
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

import {IHook} from "./IHook.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IERC20PermitUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";

interface ICollateral is IERC20Upgradeable, IERC20PermitUpgradeable {
  event Deposit(
    address indexed funder,
    address indexed recipient,
    uint256 amountAfterFee,
    uint256 fee
  );
  event DepositFeePercentChange(uint256 percent);
  event DepositHookChange(address hook);
  event Withdraw(
    address indexed funder,
    address indexed recipient,
    uint256 amountAfterFee,
    uint256 fee
  );
  event WithdrawFeePercentChange(uint256 percent);
  event WithdrawHookChange(address hook);

  function deposit(
    address recipient,
    uint256 baseTokenAmount,
    bytes calldata data
  ) external returns (uint256 collateralMintAmount);

  function deposit(address recipient, uint256 baseTokenAmount)
    external
    returns (uint256 collateralMintAmount);

  function withdraw(
    address recipient,
    uint256 collateralAmount,
    bytes calldata data
  ) external returns (uint256 baseTokenAmountAfterFee);

  function withdraw(address recipient, uint256 collateralAmount)
    external
    returns (uint256 baseTokenAmountAfterFee);

  function setDepositFeePercent(uint256 depositFeePercent) external;

  function setWithdrawFeePercent(uint256 withdrawFeePercent) external;

  function setDepositHook(IHook hook) external;

  function setWithdrawHook(IHook hook) external;

  function getBaseToken() external view returns (IERC20);

  function getDepositFeePercent() external view returns (uint256);

  function getWithdrawFeePercent() external view returns (uint256);

  function getDepositHook() external view returns (IHook);

  function getWithdrawHook() external view returns (IHook);

  function getBaseTokenBalance() external view returns (uint256);

  function PERCENT_UNIT() external view returns (uint256);

  function FEE_LIMIT() external view returns (uint256);

  function SET_DEPOSIT_FEE_PERCENT_ROLE() external view returns (bytes32);

  function SET_WITHDRAW_FEE_PERCENT_ROLE() external view returns (bytes32);

  function SET_DEPOSIT_HOOK_ROLE() external view returns (bytes32);

  function SET_WITHDRAW_HOOK_ROLE() external view returns (bytes32);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

interface IHook {
  function hook(
    address funder,
    address recipient,
    uint256 amountBeforeFee,
    uint256 amountAfterFee,
    bytes calldata data
  ) external;

  function hook(
    address funder,
    address recipient,
    uint256 amountBeforeFee,
    uint256 amountAfterFee
  ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.7;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILongShortToken is IERC20 {
  function owner() external returns (address);

  function mint(address recipient, uint256 amount) external;

  function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.7;

import {ICollateral} from "./ICollateral.sol";
import {IERC20, ILongShortToken} from "./ILongShortToken.sol";
import {IAddressBeacon} from "prepo-shared-contracts/contracts/interfaces/IAddressBeacon.sol";
import {IUintBeacon} from "prepo-shared-contracts/contracts/interfaces/IUintBeacon.sol";

interface IPrePOMarket {
  struct MarketParameters {
    address collateral;
    uint256 floorLongPayout;
    uint256 ceilingLongPayout;
    uint256 expiryLongPayout;
    uint256 floorValuation;
    uint256 ceilingValuation;
    uint256 expiryTime;
  }

  struct Permit {
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  event AddressBeaconChange(address beacon);
  event FinalLongPayoutSet(uint256 payout);
  event Mint(
    address indexed funder,
    address indexed recipient,
    uint256 amountAfterFee,
    uint256 fee
  );
  event Redemption(
    address indexed funder,
    address indexed recipient,
    uint256 amountAfterFee,
    uint256 fee
  );
  event UintBeaconChange(address beacon);

  error CeilingNotAboveFloor();
  error CeilingTooHigh();
  error ExpiryInPast();
  error ExpiryNotPassed();
  error FeePercentTooHigh();
  error FeeRoundsToZero();
  error FinalPayoutTooHigh();
  error FinalPayoutTooLow();
  error InsufficientCollateral();
  error InsufficientLongToken();
  error InsufficientShortToken();
  error MarketEnded();
  error UnequalRedemption();
  error ZeroCollateralAmount();

  function mint(
    uint256 amount,
    address recipient,
    bytes calldata data
  ) external returns (uint256);

  function permitAndMint(
    Permit calldata permit,
    uint256 collateralAmount,
    address recipient,
    bytes calldata data
  ) external returns (uint256);

  function redeem(
    uint256 longAmount,
    uint256 shortAmount,
    address recipient,
    bytes calldata data
  ) external;

  function setFinalLongPayout(uint256 finalLongPayout) external;

  function setFinalLongPayoutAfterExpiry() external;

  function getLongToken() external view returns (ILongShortToken);

  function getShortToken() external view returns (ILongShortToken);

  function getAddressBeacon() external view returns (IAddressBeacon);

  function getUintBeacon() external view returns (IUintBeacon);

  function getCollateral() external view returns (ICollateral);

  function getFloorLongPayout() external view returns (uint256);

  function getCeilingLongPayout() external view returns (uint256);

  function getExpiryLongPayout() external view returns (uint256);

  function getFinalLongPayout() external view returns (uint256);

  function getFloorValuation() external view returns (uint256);

  function getCeilingValuation() external view returns (uint256);

  function getExpiryTime() external view returns (uint256);

  function getFeePercent(bytes32 feeKey) external view returns (uint256);

  function PERCENT_UNIT() external view returns (uint256);

  function FEE_LIMIT() external view returns (uint256);

  function SET_FINAL_LONG_PAYOUT_ROLE() external view returns (bytes32);

  function MINT_HOOK_KEY() external view returns (bytes32);

  function REDEEM_HOOK_KEY() external view returns (bytes32);

  function MINT_FEE_PERCENT_KEY() external view returns (bytes32);

  function REDEEM_FEE_PERCENT_KEY() external view returns (bytes32);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

import {IHook} from "./interfaces/IHook.sol";
import {IPrePOMarket} from "./interfaces/IPrePOMarket.sol";
import {IAccountList, AccountListCaller} from "prepo-shared-contracts/contracts/AccountListCaller.sol";
import {AllowedMsgSenders} from "prepo-shared-contracts/contracts/AllowedMsgSenders.sol";
import {SafeOwnable} from "prepo-shared-contracts/contracts/SafeOwnable.sol";
import {ITokenSender, TokenSenderCaller} from "prepo-shared-contracts/contracts/TokenSenderCaller.sol";
import {TreasuryCaller} from "prepo-shared-contracts/contracts/TreasuryCaller.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MarketHook is
  IHook,
  AccountListCaller,
  ReentrancyGuard,
  SafeOwnable,
  TokenSenderCaller,
  TreasuryCaller
{
  function hook(
    address funder,
    address recipient,
    uint256 amountBeforeFee,
    uint256 amountAfterFee,
    bytes calldata
  ) external virtual override nonReentrant {
    if (address(_accountList) != address(0) && _accountList.isIncluded(funder))
      return;
    uint256 fee = amountBeforeFee - amountAfterFee;
    if (fee == 0) return;
    IPrePOMarket(msg.sender).getCollateral().transferFrom(
      msg.sender,
      _treasury,
      fee
    );
    if (address(_tokenSender) == address(0)) return;
    uint256 scaledFee = (fee * _accountToAmountMultiplier[msg.sender]) /
      PERCENT_UNIT;
    if (scaledFee == 0) return;
    _tokenSender.send(recipient, scaledFee);
  }

  function hook(
    address funder,
    address recipient,
    uint256 amountBeforeFee,
    uint256 amountAfterFee
  ) external virtual override nonReentrant {
    if (address(_accountList) != address(0) && _accountList.isIncluded(funder))
      return;
    uint256 fee = amountBeforeFee - amountAfterFee;
    if (fee == 0) return;
    IPrePOMarket(msg.sender).getCollateral().transferFrom(
      msg.sender,
      _treasury,
      fee
    );
    if (address(_tokenSender) == address(0)) return;
    uint256 scaledFee = (fee * _accountToAmountMultiplier[msg.sender]) /
      PERCENT_UNIT;
    if (scaledFee == 0) return;
    _tokenSender.send(recipient, scaledFee);
  }

  function setAccountList(IAccountList accountList)
    public
    virtual
    override
    onlyOwner
  {
    super.setAccountList(accountList);
  }

  function setTreasury(address _treasury) public override onlyOwner {
    super.setTreasury(_treasury);
  }

  function setAmountMultiplier(address account, uint256 amountMultiplier)
    public
    override
    onlyOwner
  {
    super.setAmountMultiplier(account, amountMultiplier);
  }

  function setTokenSender(ITokenSender tokenSender) public override onlyOwner {
    super.setTokenSender(tokenSender);
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

import {IAccountList, IAccountListCaller} from "./interfaces/IAccountListCaller.sol";

contract AccountListCaller is IAccountListCaller {
  IAccountList internal _accountList;

  function setAccountList(IAccountList accountList) public virtual override {
    _accountList = accountList;
    emit AccountListChange(accountList);
  }

  function getAccountList() external view override returns (IAccountList) {
    return _accountList;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

import {IAccountList, IAllowedMsgSenders} from "./interfaces/IAllowedMsgSenders.sol";

contract AllowedMsgSenders is IAllowedMsgSenders {
  IAccountList private _allowedMsgSenders;

  modifier onlyAllowedMsgSenders() {
    if (!_allowedMsgSenders.isIncluded(msg.sender))
      revert MsgSenderNotAllowed();
    _;
  }

  function setAllowedMsgSenders(IAccountList allowedMsgSenders)
    public
    virtual
    override
  {
    _allowedMsgSenders = allowedMsgSenders;
    emit AllowedMsgSendersChange(allowedMsgSenders);
  }

  function getAllowedMsgSenders()
    external
    view
    virtual
    override
    returns (IAccountList)
  {
    return _allowedMsgSenders;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

/**
 * @notice Stores whether an address is included in a set.
 */
interface IAccountList {
  event AccountListChange(address[] accounts, bool[] included);
  event AccountListReset();

  error ArrayLengthMismatch();

  /**
   * @notice Sets whether an address in `accounts` is included.
   * @dev Whether an account is included is based on the boolean value at its
   * respective index in `included`. This function will only edit the
   * inclusion of addresses in `accounts`.
   *
   * The length of `accounts` and `included` must match.
   *
   * Only callable by `owner()`.
   * @param accounts Addresses to change inclusion for
   * @param included Whether to include corresponding address in `accounts`
   */
  function set(address[] calldata accounts, bool[] calldata included) external;

  /**
   * @notice Removes every address from the set.
   * @dev Only callable by `owner()`.
   */
  function reset() external;

  /**
   * @param account Address to check inclusion for
   * @return Whether `account` is included
   */
  function isIncluded(address account) external view returns (bool);

  function getAccountAndInclusion(uint256 index)
    external
    view
    returns (address account, bool included);

  function getAccountListLength() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

import {IAccountList} from "./IAccountList.sol";

interface IAccountListCaller {
  event AccountListChange(IAccountList accountList);

  function setAccountList(IAccountList accountList) external;

  function getAccountList() external view returns (IAccountList);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

interface IAddressBeacon {
  event AddressChange(bytes32 key, address addr);

  function set(bytes32 key, address addr) external;

  function get(bytes32 key) external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

import {IAccountList} from "./IAccountList.sol";

interface IAllowedMsgSenders {
  event AllowedMsgSendersChange(IAccountList allowedMsgSenders);
  error MsgSenderNotAllowed();

  function setAllowedMsgSenders(IAccountList allowedMsgSenders) external;

  function getAllowedMsgSenders() external view returns (IAccountList);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

/**
 * @notice An extension of OpenZeppelin's `Ownable.sol` contract that requires
 * an address to be nominated, and then accept that nomination, before
 * ownership is transferred.
 */
interface ISafeOwnable {
  /**
   * @dev Emitted via `transferOwnership()`.
   * @param previousNominee The previous nominee
   * @param newNominee The new nominee
   */
  event NomineeUpdate(
    address indexed previousNominee,
    address indexed newNominee
  );

  /**
   * @notice Nominates an address to be owner of the contract.
   * @dev Only callable by `owner()`.
   * @param nominee The address that will be nominated
   */
  function transferOwnership(address nominee) external;

  /**
   * @notice Renounces ownership of contract and leaves the contract
   * without any owner.
   * @dev Only callable by `owner()`.
   * Sets nominee back to zero address.
   * It will not be possible to call `onlyOwner` functions anymore.
   */
  function renounceOwnership() external;

  /**
   * @notice Accepts ownership nomination.
   * @dev Only callable by the current nominee. Sets nominee back to zero
   * address.
   */
  function acceptOwnership() external;

  /// @return The current nominee
  function getNominee() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

import {IUintValue} from "./IUintValue.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITokenSender {
  event PriceLowerBoundChange(uint256 price);
  event PriceOracleChange(IUintValue oracle);

  function send(address recipient, uint256 inputAmount) external;

  function setPriceOracle(IUintValue priceOracle) external;

  function setPriceLowerBound(uint256 priceLowerBound) external;

  function getOutputToken() external view returns (IERC20);

  function getPriceOracle() external view returns (IUintValue);

  function getPriceLowerBound() external view returns (uint256);

  function SET_PRICE_ORACLE_ROLE() external view returns (bytes32);

  function SET_PRICE_LOWER_BOUND_ROLE() external view returns (bytes32);

  function SET_ALLOWED_MSG_SENDERS_ROLE() external view returns (bytes32);

  function SET_ACCOUNT_LIMIT_RESET_PERIOD_ROLE()
    external
    view
    returns (bytes32);

  function SET_ACCOUNT_LIMIT_PER_PERIOD_ROLE() external view returns (bytes32);

  function WITHDRAW_ERC20_ROLE() external view returns (bytes32);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

import {ITokenSender} from "./ITokenSender.sol";

interface ITokenSenderCaller {
  event AmountMultiplierChange(address account, uint256 multiplier);
  event TokenSenderChange(address sender);

  error InvalidAccount();

  function setTokenSender(ITokenSender tokenSender) external;

  function setAmountMultiplier(address account, uint256 amountMultiplier)
    external;

  function getTokenSender() external view returns (ITokenSender);

  function getAmountMultiplier(address account)
    external
    view
    returns (uint256);

  function PERCENT_UNIT() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

interface ITreasuryCaller {
  event TreasuryChange(address treasury);

  function setTreasury(address treasury) external;

  function getTreasury() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

interface IUintBeacon {
  event UintChange(bytes32 key, uint256 value);

  function set(bytes32 key, uint256 value) external;

  function get(bytes32 key) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

interface IUintValue {
  function get() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ISafeOwnable} from "./interfaces/ISafeOwnable.sol";

contract SafeOwnable is ISafeOwnable, Ownable {
  address private _nominee;

  modifier onlyNominee() {
    require(_msgSender() == _nominee, "msg.sender != nominee");
    _;
  }

  function transferOwnership(address nominee)
    public
    virtual
    override(ISafeOwnable, Ownable)
    onlyOwner
  {
    _setNominee(nominee);
  }

  function acceptOwnership() public virtual override onlyNominee {
    _transferOwnership(_nominee);
    _setNominee(address(0));
  }

  function renounceOwnership()
    public
    virtual
    override(ISafeOwnable, Ownable)
    onlyOwner
  {
    super.renounceOwnership();
    _setNominee(address(0));
  }

  function getNominee() public view virtual override returns (address) {
    return _nominee;
  }

  function _setNominee(address nominee) internal virtual {
    address _oldNominee = _nominee;
    _nominee = nominee;
    emit NomineeUpdate(_oldNominee, nominee);
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

import {ITokenSender, ITokenSenderCaller} from "./interfaces/ITokenSenderCaller.sol";

contract TokenSenderCaller is ITokenSenderCaller {
  mapping(address => uint256) internal _accountToAmountMultiplier;
  ITokenSender internal _tokenSender;

  uint256 public constant override PERCENT_UNIT = 1000000;

  function setAmountMultiplier(address account, uint256 amountMultiplier)
    public
    virtual
    override
  {
    _accountToAmountMultiplier[account] = amountMultiplier;
    emit AmountMultiplierChange(account, amountMultiplier);
  }

  function setTokenSender(ITokenSender tokenSender) public virtual override {
    _tokenSender = tokenSender;
    emit TokenSenderChange(address(tokenSender));
  }

  function getAmountMultiplier(address account)
    external
    view
    override
    returns (uint256)
  {
    return _accountToAmountMultiplier[account];
  }

  function getTokenSender() external view override returns (ITokenSender) {
    return _tokenSender;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

import {ITreasuryCaller} from "./interfaces/ITreasuryCaller.sol";

contract TreasuryCaller is ITreasuryCaller {
  address internal _treasury;

  function setTreasury(address treasury) public virtual override {
    _treasury = treasury;
    emit TreasuryChange(treasury);
  }

  function getTreasury() external view override returns (address) {
    return _treasury;
  }
}