// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

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
   */
  function isContract(address account) internal view returns (bool) {
    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      codehash := extcodehash(account)
    }
    return (codehash != accountHash && codehash != 0x0);
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
    require(address(this).balance >= amount, 'Address: insufficient balance');

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{value: amount}('');
    require(success, 'Address: unable to send value, recipient may have reverted');
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

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
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
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

pragma solidity 0.8.10;

import './Context.sol';

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
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), 'Ownable: caller is not the owner');
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
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

/// @title Optimized overflow and underflow safe math operations
/// @notice Contains methods for doing math operations that revert on overflow or underflow for minimal gas cost
library SafeMath {
  /// @notice Returns x + y, reverts if sum overflows uint256
  /// @param x The augend
  /// @param y The addend
  /// @return z The sum of x and y
  function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
    unchecked {
      require((z = x + y) >= x);
    }
  }

  /// @notice Returns x - y, reverts if underflows
  /// @param x The minuend
  /// @param y The subtrahend
  /// @return z The difference of x and y
  function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    unchecked {
      require((z = x - y) <= x);
    }
  }

  /// @notice Returns x - y, reverts if underflows
  /// @param x The minuend
  /// @param y The subtrahend
  /// @param message The error msg
  /// @return z The difference of x and y
  function sub(
    uint256 x,
    uint256 y,
    string memory message
  ) internal pure returns (uint256 z) {
    unchecked {
      require((z = x - y) <= x, message);
    }
  }

  /// @notice Returns x * y, reverts if overflows
  /// @param x The multiplicand
  /// @param y The multiplier
  /// @return z The product of x and y
  function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    unchecked {
      require(x == 0 || (z = x * y) / x == y);
    }
  }

  /// @notice Returns x / y, reverts if overflows - no specific check, solidity reverts on division by 0
  /// @param x The numerator
  /// @param y The denominator
  /// @return z The product of x and y
  function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
    return x / y;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;
pragma experimental ABIEncoderV2;

interface IChefIncentivesController {
    /**
     * @dev Called by the corresponding asset on any update that affects the rewards distribution
     * @param user The address of the user
     * @param userBalance The balance of the user of the asset in the lending pool
     * @param totalSupply The total supply of the asset in the lending pool
     **/
    function handleAction(
        address user,
        uint256 userBalance,
        uint256 totalSupply
    ) external;

    function addPool(address _token, uint256 _allocPoint) external;

    function claim(address _user, address[] calldata _tokens) external;

    function setClaimReceiver(address _user, address _receiver) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

interface IOnwardIncentivesController {
    function handleAction(
        address _token,
        address _user,
        uint256 _balance,
        uint256 _totalSupply
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;
import "../../dependencies/openzeppelin/contracts/IERC20.sol";
import "../../dependencies/openzeppelin/contracts/SafeMath.sol";
import "../../dependencies/openzeppelin/contracts/Address.sol";

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "../../dependencies/openzeppelin/contracts/IERC20.sol";
import "../../dependencies/openzeppelin/contracts/Ownable.sol";
import "../../dependencies/openzeppelin/contracts/SafeMath.sol";
import "../libs/SafeERC20.sol";
import "../interfaces/IChefIncentivesController.sol";
import "../interfaces/IOnwardIncentivesController.sol";

/**
 * @title   GlpRewardsDistribution
 * @author  Maneki.finance
 * @notice  Used to distribute Maneki protocol claimed weth rewards to Glp AToken holders
 *          Based on MultiFeeDistribution:
 *          https://github.com/geist-finance/geist-protocol/blob/main/contracts/staking/MultiFeeDistribution.sol
 *          Functions as OnwardsIncentivesController of GlpAToken on ChefIncentivesController
 */

contract GlpRewardsDistribution is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STRUCTS ========== */

    struct Reward {
        uint256 periodFinish;
        uint256 rewardRate;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
        uint256 balance;
    }

    struct Balances {
        uint256 total;
        uint256 earned;
    }

    event GlpATokenUpdated(
        address user,
        uint256 userBalance,
        uint256 totalBalance
    );

    event RewardClaimed(address user, address rewardToken, uint256 amount);

    event Recovered(address savedToken, uint256 amount);

    event RewardNotifed(address rewardToken, uint256 newUnseenAmount);

    /* ========== STATE VARIABLES ========== */

    /* Address of ChefIncentivesController */
    address public chefIncentivesController;

    /* Address of OnwardsIncentivesController */
    IOnwardIncentivesController public onwardsIncentivesController;

    /* Address of Glp AToken*/
    IERC20 public glpAToken;

    /* Array of rewards, currently only weth */
    address[] public rewardTokens;

    /* Data of specific reward */
    mapping(address => Reward) public rewardData;

    /* Private mappings for balance data */
    mapping(address => Balances) public balances;

    mapping(address => mapping(address => uint256))
        public userRewardPerTokenPaid;
    mapping(address => mapping(address => uint256)) public rewards;

    uint256 public totalGlpAToken;

    /* Duration that rewards will stream over */
    uint256 public constant rewardsDuration = 86400; // 1 Day

    /* ========== CONSTRUCTOR ========== */

    constructor(address _chefIncentivesController) Ownable() {
        chefIncentivesController = _chefIncentivesController;
    }

    function start(address _glpAToken, address _weth) external onlyOwner {
        glpAToken = IERC20(_glpAToken);
        rewardTokens.push(_weth);
        totalGlpAToken = glpAToken.totalSupply();
        rewardData[_weth].lastUpdateTime = block.timestamp;
        rewardData[_weth].periodFinish = block.timestamp;
    }

    function handleAction(
        address _callingToken,
        address _user,
        uint256 _userBalance,
        uint256 _totalSupply
    ) external {
        require(
            msg.sender == chefIncentivesController,
            "GlpRewardsDistribution: Only ChefIncentivesController can call"
        );
        require(
            _callingToken == address(glpAToken),
            "GlpRewardsDistribution: Invalid token"
        );
        _updateReward(_user);
        _checkUnseenAndNotify();
        totalGlpAToken = _totalSupply;
        Balances storage bal = balances[_user];
        bal.total = _userBalance;

        if (
            onwardsIncentivesController !=
            IOnwardIncentivesController(address(0))
        ) {
            onwardsIncentivesController.handleAction(
                msg.sender,
                _user,
                _userBalance,
                _totalSupply
            );
        }

        emit GlpATokenUpdated(_user, _userBalance, _totalSupply);
    }

    /* Claim all pending staking rewards */
    function getReward(address[] memory _rewardTokens) public {
        _updateReward(msg.sender);
        _getReward(_rewardTokens);
    }

    function addReward(address _rewardsToken) external onlyOwner {
        require(rewardData[_rewardsToken].lastUpdateTime == 0);
        rewardTokens.push(_rewardsToken);
        rewardData[_rewardsToken].lastUpdateTime = block.timestamp;
        rewardData[_rewardsToken].periodFinish = block.timestamp;
    }

    function setOnwardIncentives(
        IOnwardIncentivesController _incentives
    ) external onlyOwner {
        onwardsIncentivesController = _incentives;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _getReward(address[] memory _rewardTokens) internal {
        uint256 length = _rewardTokens.length;
        for (uint i; i < length; i++) {
            address token = _rewardTokens[i];
            uint256 reward = rewards[msg.sender][token].div(1e12);
            Reward storage r = rewardData[token];
            uint256 periodFinish = r.periodFinish;
            require(periodFinish > 0, "Unknown reward token");
            uint256 balance = r.balance;
            if (periodFinish < block.timestamp.add(rewardsDuration - 43200)) {
                uint256 unseen = IERC20(token).balanceOf(address(this)).sub(
                    balance
                );
                if (unseen > 0) {
                    _notifyReward(token, unseen);
                    balance = balance.add(unseen);
                }
            }
            r.balance = balance.sub(reward);
            if (reward == 0) continue;
            rewards[msg.sender][token] = 0;
            IERC20(token).safeTransfer(msg.sender, reward);
            emit RewardClaimed(msg.sender, token, reward);
        }
    }

    function _checkUnseenAndNotify() internal {
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            address token = rewardTokens[i];
            Reward storage r = rewardData[token];
            uint256 periodFinish = r.periodFinish;
            require(periodFinish > 0, "Unknown reward token");
            uint256 balance = r.balance;
            if (periodFinish < block.timestamp.add(rewardsDuration - 43200)) {
                uint256 unseen = IERC20(token).balanceOf(address(this)).sub(
                    balance
                );
                if (unseen > 0) {
                    _notifyReward(token, unseen);
                    balance = balance.add(unseen);
                }
            }
            r.balance = balance;
        }
    }

    function _notifyReward(address _rewardsToken, uint256 reward) internal {
        Reward storage r = rewardData[_rewardsToken];
        if (block.timestamp >= r.periodFinish) {
            r.rewardRate = reward.mul(1e12).div(rewardsDuration);
        } else {
            uint256 remaining = r.periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(r.rewardRate).div(1e12);
            r.rewardRate = reward.add(leftover).mul(1e12).div(rewardsDuration);
        }

        r.lastUpdateTime = block.timestamp;
        r.periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardNotifed(_rewardsToken, reward);
    }

    function _updateReward(address _account) internal {
        address token = address(glpAToken);
        uint256 balance;
        Reward storage r;
        uint256 rpt;
        uint256 supply = glpAToken.totalSupply();
        for (uint i = 0; i < rewardTokens.length; i++) {
            token = rewardTokens[i];
            r = rewardData[token];
            rpt = _rewardPerToken(token, supply);
            r.rewardPerTokenStored = rpt;
            r.lastUpdateTime = lastTimeRewardApplicable(token);
            if (_account != address(this)) {
                rewards[_account][token] = _earned(
                    _account,
                    token,
                    balance,
                    rpt
                );
                userRewardPerTokenPaid[_account][token] = rpt;
            }
        }
    }

    function _rewardPerToken(
        address _rewardsToken,
        uint256 _supply
    ) internal view returns (uint256) {
        if (_supply == 0) {
            return rewardData[_rewardsToken].rewardPerTokenStored;
        }
        return
            rewardData[_rewardsToken].rewardPerTokenStored.add(
                lastTimeRewardApplicable(_rewardsToken)
                    .sub(rewardData[_rewardsToken].lastUpdateTime)
                    .mul(rewardData[_rewardsToken].rewardRate)
                    .mul(1e18)
                    .div(_supply)
            );
    }

    function lastTimeRewardApplicable(
        address _rewardsToken
    ) public view returns (uint256) {
        uint periodFinish = rewardData[_rewardsToken].periodFinish;
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function _earned(
        address _user,
        address _rewardsToken,
        uint256 _balance,
        uint256 _currentRewardPerToken
    ) internal view returns (uint256) {
        return
            _balance
                .mul(
                    _currentRewardPerToken.sub(
                        userRewardPerTokenPaid[_user][_rewardsToken]
                    )
                )
                .div(1e18)
                .add(rewards[_user][_rewardsToken]);
    }

    /* ========== VIEW FUNCTIONS ========== */

    function totalBalance(address user) external view returns (uint256 amount) {
        return balances[user].total;
    }

    function rewardPerToken(
        address _rewardsToken
    ) external view returns (uint256) {
        return _rewardPerToken(_rewardsToken, totalGlpAToken);
    }

    function getRewardForDuration(
        address _rewardsToken
    ) external view returns (uint256) {
        return
            rewardData[_rewardsToken].rewardRate.mul(rewardsDuration).div(1e12);
    }

    function unclaimedReward(
        address _user,
        address _rewardsToken
    ) external view returns (uint256) {
        uint256 balance = balances[_user].total;
        uint256 currentRewardPerToken = _rewardPerToken(
            _rewardsToken,
            totalGlpAToken
        );
        uint256 earned = _earned(
            _user,
            _rewardsToken,
            balance,
            currentRewardPerToken
        );
        return earned;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /* Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders */
    function recoverERC20(
        address tokenAddress,
        uint256 tokenAmount
    ) external onlyOwner {
        require(
            rewardData[tokenAddress].lastUpdateTime == 0,
            "Cannot withdraw reward token"
        );
        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    /**
     * @notice  Allows the owner to recover any ether instead of weth accidentally sent to
     *          the contract.
     */
    function recoverETH(
        address payable recipient,
        uint256 amount
    ) external onlyOwner {
        require(address(this).balance != amount, "No missent ether.");
        require(
            address(this).balance >= amount,
            "Not enough Ether available in contract."
        );
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Transfer of Ether failed.");
        emit EtherRecovered(recipient, amount);
    }

    event EtherRecovered(address indexed recipient, uint256 amount);
}