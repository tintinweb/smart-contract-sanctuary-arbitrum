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
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IChefIncentivesController {
  function claimAll(address _user) external;

  function allPendingRewards(address _user) external view returns (uint256 pending);
}

interface ILendingPool {
  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

  function depositWithAutoDLP(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(address asset, uint256 amount, address to) external returns (uint256);

  /**
   * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
   * corresponding debt token (StableDebtToken or VariableDebtToken)
   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   **/
  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
   * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @return The final amount repaid
   **/
  function repay(address asset, uint256 amount, uint256 rateMode, address onBehalfOf) external returns (uint256);

  /**
   * @dev Returns the user account data across all the reserves
   * @param user The address of the user
   * @return totalCollateralETH the total collateral in ETH of the user
   * @return totalDebtETH the total debt in ETH of the user
   * @return availableBorrowsETH the borrowing power left of the user
   * @return currentLiquidationThreshold the liquidation threshold of the user
   * @return ltv the loan to value of the user
   * @return healthFactor the current health factor of the user
   **/
  function getUserAccountData(
    address user
  )
    external
    view
    returns (
      uint256 totalCollateralETH,
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );
}

interface ISharedStruct {
  struct LockedBalance {
    uint256 amount;
    uint256 unlockTime;
    uint256 multiplier;
    uint256 duration;
  }
}

interface IChefIncentivesHandler is ISharedStruct {
  struct EarnedBalance {
    uint256 amount;
    uint256 unlockTime;
    uint256 penalty;
  }

  /**
   * @notice Withdraw individual unlocked balance and earnings, optionally claim pending rewards.
   */
  function individualEarlyExit(bool claimRewards, uint256 unlockTime) external;

  /**
   * @notice Withdraw tokens from earnings and unlocked.
   * @dev First withdraws unlocked tokens, then earned tokens. Withdrawing earned tokens
   *  incurs a 50% penalty which is distributed based on locked balances.
   */
  function withdraw(uint256 amount) external;

  /**
   * @notice Withdraw full unlocked balance and earnings, optionally claim pending rewards.
   */
  function exit(bool claimRewards) external;

  /**
   * @notice Earnings which is locked yet
   * @dev Earned balances may be withdrawn immediately for a 50% penalty.
   * @return total earnings
   * @return unlocked earnings
   * @return earningsData which is an array of all infos
   */

  function earnedBalances(
    address user
  ) external view returns (uint256 total, uint256 unlocked, EarnedBalance[] memory earningsData);

  /**
   * @notice Final balance received and penalty balance paid by user upon calling exit.
   * @dev This is earnings, not locks.
   */
  function withdrawableBalance(
    address user
  ) external view returns (uint256 amount, uint256 penaltyAmount, uint256 burnAmount);
}

interface IProtocolRewardsHandler is ISharedStruct {
  struct RewardData {
    address token;
    uint256 amount;
  }

  function stake(uint256 amount, address onBehalfOf, uint256 typeIndex) external;

  function setRelock(bool _status) external;

  function setDefaultRelockTypeIndex(uint256 _index) external;

  function withdrawExpiredLocksFor(address _address) external returns (uint256);

  function withdrawExpiredLocksForWithOptions(
    address _address,
    uint256 _limit,
    bool _ignoreRelock
  ) external returns (uint256);

  function getReward(address[] memory _rewardTokens) external;

  /** VIEWS */
  function claimableRewards(address account) external view returns (RewardData[] memory rewardsData);

  /**
   * @notice Returns all locks of a user.
   */
  function lockInfo(address user) external view returns (LockedBalance[] memory);

  /**
   * @notice Information on a user's lockings
   * @return total balance of locks
   * @return unlockable balance
   * @return locked balance
   * @return lockedWithMultiplier
   * @return lockData which is an array of locks
   */
  function lockedBalances(
    address user
  )
    external
    view
    returns (
      uint256 total,
      uint256 unlockable,
      uint256 locked,
      uint256 lockedWithMultiplier,
      LockedBalance[] memory lockData
    );
}

// MultiFeeDistribution does 2 things: handle protocol fee distro + handle chef rewards distro
interface IMultiFeeDistribution is IChefIncentivesHandler, IProtocolRewardsHandler {
  struct Reward {
    uint256 periodFinish;
    uint256 rewardPerSecond;
    uint256 lastUpdateTime;
    uint256 rewardPerTokenStored;
    // tracks already-added balances to handle accrued interest in aToken rewards
    // for the stakingToken this value is unused and will always be 0
    uint256 balance;
  }

  function rewardPerToken(address _rewardToken) external view returns (uint256 rptStored);

  function rewardData(address _rewardToken) external view returns (Reward memory);

  function userRewardPerTokenPaid(address _user, address _rewardToken) external view returns (uint256 _rpt);

  function rewards(address _user, address _rewardToken) external view returns (uint256 _amount);

  ///@dev BUGGY
  /**
   * @notice Total balance of an account, including unlocked, locked and earned tokens.
   */
  function totalBalance(address user) external view returns (uint256 amount);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { IProtocolRewardsHandler } from '../interfaces/Radiant.sol';

interface IPlsRdntRewardsDistro {
  function sendRewards(address _to, IProtocolRewardsHandler.RewardData[] memory _pendingRewardAmounts) external;

  function record() external returns (IProtocolRewardsHandler.RewardData[] memory _pendingRewards);

  function hasBufferedRewards() external view returns (bool);

  function pendingRewards() external view returns (IProtocolRewardsHandler.RewardData[] memory _pendingRewards);

  event FeeChanged(uint256 indexed _new, uint256 _old);
  event HandleClaim(IProtocolRewardsHandler.RewardData[] _rewardsData);

  error UNAUTHORIZED();
  error INVALID_FEE();
}

interface IPlsRdntUtils {
  function mfdClaimableRewards(
    address _account,
    address[] memory _tokens
  ) external view returns (IProtocolRewardsHandler.RewardData[] memory _rewardsData);

  function pendingRewardsLessFee(
    address _user,
    uint _feeInBp,
    bool _inUnderlyingAsset
  ) external view returns (IProtocolRewardsHandler.RewardData[] memory _pendingRewardsLessFee);
}

interface IRdntLpStaker {
  function stake(uint256) external;

  function getRewardTokens() external view returns (address[] memory);

  function getRewardTokenCount() external view returns (uint);

  function claimRadiantProtocolFees(
    address _to
  ) external returns (IProtocolRewardsHandler.RewardData[] memory _rewardsData);
}

interface IAToken is IERC20 {
  function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

interface IPlutusChef {
  function depositFor(address _user, uint96 _amount) external;
}

interface ITokenMinter {
  function mint(address, uint256) external;

  function burn(address, uint256) external;
}

interface IDelegation {
  function setDelegate(bytes32 id, address delegate) external;
}

interface IPlsRdntPlutusChef is IPlutusChef {
  error DEPOSIT_ERROR(string);
  error WITHDRAW_ERROR();
  error UNAUTHORIZED();
  error FAILED(string);

  event HandlerUpdated(address indexed _handler, bool _isActive);
  event Deposit(address indexed _user, uint256 _amount);
  event Withdraw(address indexed _user, uint256 _amount);
  event EmergencyWithdraw(address indexed _user, uint256 _amount);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable2Step.sol';
import { IPlsRdntPlutusChef, IPlsRdntRewardsDistro, IRdntLpStaker, IPlsRdntUtils, IAToken } from './Interfaces.sol';
import { IProtocolRewardsHandler } from '../interfaces/Radiant.sol';

contract PlsRdntRewardsDistro is Ownable2Step, IPlsRdntRewardsDistro {
  address public immutable CHEF;
  uint private constant FEE_DIVISOR = 1e4;
  IRdntLpStaker public constant STAKER = IRdntLpStaker(0x2A2CAFbB239af9159AEecC34AC25521DBd8B5197);
  address public constant FEE_COLLECTOR = 0x9c140CD0F95D6675540F575B2e5Da46bFffeD31E;
  IPlsRdntUtils public constant UTILS = IPlsRdntUtils(0x1f3Fa65C5A9cf4f295fc34329aeA552a528d7ac3);

  mapping(address => bool) public isHandler;
  mapping(address => uint) public rewardsBuffer; // underlyingToken -> amount
  uint32 public fee; // fee in bp
  bool public hasBufferedRewards;
  uint32 public lastHandled;

  constructor(address _chef) {
    CHEF = _chef;
    isHandler[msg.sender] = true;
    fee = 1200;
  }

  function handleClaim() external onlyHandler {
    IProtocolRewardsHandler.RewardData[] memory _rewardsData = STAKER.claimRadiantProtocolFees(address(this)); // tokens in underlying asset

    uint _fee = fee;
    for (uint i; i < _rewardsData.length; i = _unsafeInc(i)) {
      uint _amount = _rewardsData[i].amount;

      if (_amount > 0) {
        unchecked {
          uint _plutusFee = ((_amount * _fee) / FEE_DIVISOR);
          IERC20(_rewardsData[i].token).transfer(FEE_COLLECTOR, _plutusFee);
          // adjusted to account for fees
          _rewardsData[i].amount = _amount - _plutusFee;

          // write pending to rewards buffer
          rewardsBuffer[_rewardsData[i].token] += _rewardsData[i].amount;
        }
      }
    }

    hasBufferedRewards = true;
    lastHandled = uint32(block.timestamp);
    emit HandleClaim(_rewardsData);
  }

  /// @dev rewards in buffer, net of fees
  function pendingRewards() external view returns (IProtocolRewardsHandler.RewardData[] memory _pendingRewards) {
    if (lastHandled == 0) {
      return UTILS.pendingRewardsLessFee(address(STAKER), fee, true);
    }

    address[] memory _rewardTokens = STAKER.getRewardTokens();
    _pendingRewards = new IProtocolRewardsHandler.RewardData[](_rewardTokens.length);

    for (uint i; i < _rewardTokens.length; i = _unsafeInc(i)) {
      address underlyingToken = IAToken(_rewardTokens[i]).UNDERLYING_ASSET_ADDRESS();
      _pendingRewards[i] = IProtocolRewardsHandler.RewardData({
        token: underlyingToken,
        amount: rewardsBuffer[underlyingToken]
      });
    }
  }

  /// @dev flush buffer and update chef state
  function record() external returns (IProtocolRewardsHandler.RewardData[] memory _pendingRewards) {
    if (msg.sender != CHEF) revert UNAUTHORIZED();
    address[] memory _rewardTokens = STAKER.getRewardTokens();
    _pendingRewards = new IProtocolRewardsHandler.RewardData[](_rewardTokens.length);

    for (uint i; i < _rewardTokens.length; i = _unsafeInc(i)) {
      address underlyingToken = IAToken(_rewardTokens[i]).UNDERLYING_ASSET_ADDRESS();
      _pendingRewards[i] = IProtocolRewardsHandler.RewardData({
        token: underlyingToken,
        amount: rewardsBuffer[underlyingToken]
      });

      // flush buffer
      rewardsBuffer[underlyingToken] = 0;
    }

    hasBufferedRewards = false;
  }

  /// @dev transfer rewards to user
  function sendRewards(address _to, IProtocolRewardsHandler.RewardData[] memory _pendingRewardAmounts) external {
    if (msg.sender != CHEF) revert UNAUTHORIZED();
    uint _len = _pendingRewardAmounts.length;

    for (uint i; i < _len; i = _unsafeInc(i)) {
      address _rewardToken = _pendingRewardAmounts[i].token;
      uint _amount = _pendingRewardAmounts[i].amount;

      if (_amount > 0) {
        _safeTokenTransfer(IERC20(_rewardToken), _to, _amount);
      }
    }
  }

  function _unsafeInc(uint x) private pure returns (uint) {
    unchecked {
      return x + 1;
    }
  }

  function _safeTokenTransfer(IERC20 _token, address _to, uint256 _amount) private {
    uint256 bal = _token.balanceOf(address(this));

    if (_amount > bal) {
      _token.transfer(_to, bal);
    } else {
      _token.transfer(_to, _amount);
    }
  }

  modifier onlyHandler() {
    if (isHandler[msg.sender] == false) revert UNAUTHORIZED();
    _;
  }

  /** OWNER FUNCTIONS */
  function recoverErc20(IERC20 _erc20, uint _amount) external onlyOwner {
    IERC20(_erc20).transfer(owner(), _amount);
  }

  function setFee(uint32 _fee) external onlyOwner {
    if (_fee > FEE_DIVISOR) {
      revert INVALID_FEE();
    }

    emit FeeChanged(_fee, fee);
    fee = _fee;
  }

  function updateHandler(address _handler, bool _isActive) public onlyOwner {
    isHandler[_handler] = _isActive;
  }
}