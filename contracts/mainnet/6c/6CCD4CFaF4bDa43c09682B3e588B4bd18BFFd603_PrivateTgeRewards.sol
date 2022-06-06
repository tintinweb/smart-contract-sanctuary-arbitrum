// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import { IPrivateTgeHelper } from './PrivateTgeHelper.sol';

contract PrivateTgeRewards is Ownable {
  IERC20 public immutable plsDPX; // = IERC20(0xF236ea74B515eF96a9898F5a4ed4Aa591f253Ce1);
  IERC20 public immutable plsJONES; //= IERC20(0xe7f6C3c1F0018E4C08aCC52965e5cbfF99e34A44);
  IPrivateTgeHelper public immutable helper; //= IPrivateTgeHelper(0xEC06E18b64b54470Eb423A245640600155aD3427);

  struct Reward {
    uint32 addedAtTimestamp;
    uint96 plsDpx;
    uint96 plsJones;
  }

  struct ClaimDetails {
    bool fullyClaimed;
    uint32 lastClaimedTimestamp;
    uint96 plsDpxClaimedAmt;
    uint96 plsJonesClaimedAmt;
  }

  uint32 public epoch;
  uint96 public totalPlsDpxRewards;
  uint96 public totalPlsJonesRewards;

  // Address => Epoch => Claim Details
  mapping(address => mapping(uint32 => ClaimDetails)) public claimDetails;

  // Epoch => Reward
  mapping(uint32 => Reward) public epochRewards;

  constructor(
    address _governance,
    address _plsDpx,
    address _plsJones,
    address _helper
  ) {
    transferOwnership(_governance);
    plsDPX = IERC20(_plsDpx);
    plsJONES = IERC20(_plsJones);
    helper = IPrivateTgeHelper(_helper);
  }

  function claimRewards(uint32 _epoch) public {
    ClaimDetails memory _claimDetails = claimDetails[msg.sender][_epoch];
    Reward memory rewardsForEpoch = epochRewards[_epoch];

    // User rewards for epoch
    uint256 userPlsDpxShare = helper.calculateShare(msg.sender, rewardsForEpoch.plsDpx);
    uint256 userPlsJonesShare = helper.calculateShare(msg.sender, rewardsForEpoch.plsJones);

    require(userPlsDpxShare > 0 || userPlsJonesShare > 0, 'No rewards');

    uint256 claimablePlsDpx; // user portion claimable
    uint256 claimablePlsJones; // user portion claimable

    // Claim prorated amount for current epoch
    uint256 vestedDuration;

    unchecked {
      if (_claimDetails.lastClaimedTimestamp > rewardsForEpoch.addedAtTimestamp) {
        vestedDuration = block.timestamp - _claimDetails.lastClaimedTimestamp;
      } else {
        vestedDuration = block.timestamp - rewardsForEpoch.addedAtTimestamp;
      }

      claimablePlsDpx += (userPlsDpxShare * vestedDuration) / helper.EPOCH();
      claimablePlsJones += (userPlsJonesShare * vestedDuration) / helper.EPOCH();
    }

    bool _fullyClaimed;

    if (claimablePlsDpx > userPlsDpxShare - _claimDetails.plsDpxClaimedAmt) {
      // if claimable asset calculated is > claimable amt
      claimablePlsDpx = uint96(userPlsDpxShare - _claimDetails.plsDpxClaimedAmt);
      _fullyClaimed = true;
    } else {
      claimablePlsDpx = uint96(claimablePlsDpx);
    }

    if (claimablePlsJones > userPlsJonesShare - _claimDetails.plsJonesClaimedAmt) {
      // if claimable asset calculated is > claimable amt
      claimablePlsJones = uint96(userPlsJonesShare - _claimDetails.plsJonesClaimedAmt);
    } else {
      claimablePlsJones = uint96(claimablePlsJones);
    }

    // Update user claim details
    unchecked {
      claimDetails[msg.sender][_epoch] = ClaimDetails({
        fullyClaimed: _fullyClaimed,
        plsDpxClaimedAmt: _claimDetails.plsDpxClaimedAmt + uint96(claimablePlsDpx),
        plsJonesClaimedAmt: _claimDetails.plsJonesClaimedAmt + uint96(claimablePlsJones),
        lastClaimedTimestamp: uint32(block.timestamp)
      });
    }

    plsDPX.transfer(msg.sender, claimablePlsDpx);
    plsJONES.transfer(msg.sender, claimablePlsJones);

    emit ClaimRewards(msg.sender);
  }

  function claimAll() external {
    uint32 _epoch = epoch;

    unchecked {
      for (uint32 i = 0; i <= _epoch; i++) {
        if (!claimDetails[msg.sender][i].fullyClaimed) {
          claimRewards(i);
        }
      }
    }
  }

  /** VIEWS */
  function pendingRewardsFor(uint32 _epoch) public view returns (uint256 _plsDpx, uint256 _plsJones) {
    ClaimDetails memory _claimDetails = claimDetails[msg.sender][_epoch];
    Reward memory rewardsForEpoch = epochRewards[_epoch];

    // User rewards for epoch
    uint256 userPlsDpxShare = helper.calculateShare(msg.sender, rewardsForEpoch.plsDpx);
    uint256 userPlsJonesShare = helper.calculateShare(msg.sender, rewardsForEpoch.plsJones);

    require(userPlsDpxShare > 0 || userPlsJonesShare > 0, 'No rewards');

    uint256 claimablePlsDpx; // user portion claimable
    uint256 claimablePlsJones; // user portion claimable

    // Claim prorated amount for current epoch
    uint256 vestedDuration;

    unchecked {
      if (_claimDetails.lastClaimedTimestamp > rewardsForEpoch.addedAtTimestamp) {
        vestedDuration = block.timestamp - _claimDetails.lastClaimedTimestamp;
      } else {
        vestedDuration = block.timestamp - rewardsForEpoch.addedAtTimestamp;
      }

      claimablePlsDpx += (userPlsDpxShare * vestedDuration) / helper.EPOCH();
      claimablePlsJones += (userPlsJonesShare * vestedDuration) / helper.EPOCH();
    }

    bool _fullyClaimed;

    if (claimablePlsDpx > userPlsDpxShare - _claimDetails.plsDpxClaimedAmt) {
      // if claimable asset calculated is > claimable amt
      claimablePlsDpx = uint96(userPlsDpxShare - _claimDetails.plsDpxClaimedAmt);
      _fullyClaimed = true;
    } else {
      claimablePlsDpx = uint96(claimablePlsDpx);
    }

    if (claimablePlsJones > userPlsJonesShare - _claimDetails.plsJonesClaimedAmt) {
      // if claimable asset calculated is > claimable amt
      claimablePlsJones = uint96(userPlsJonesShare - _claimDetails.plsJonesClaimedAmt);
    } else {
      claimablePlsJones = uint96(claimablePlsJones);
    }

    _plsDpx = claimablePlsDpx;
    _plsJones = claimablePlsJones;
  }

  function pendingRewards() external view returns (uint256 _pendingDpx, uint256 _pendingJones) {
    uint32 _epoch = epoch;

    for (uint32 i = 0; i <= _epoch; i++) {
      if (!claimDetails[msg.sender][i].fullyClaimed) {
        (uint256 d, uint256 j) = pendingRewardsFor(i);
        _pendingDpx += d;
        _pendingJones += j;
      }
    }
  }

  /** OWNER */
  /// @dev deposit to rewards contract
  function depositRewards(uint96 _plsDpx, uint96 _plsJones) external onlyOwner {
    if (totalPlsDpxRewards == 0 && totalPlsJonesRewards == 0) {
      // No op - Don't increment it for very first deposit
    } else {
      epoch += 1;
    }

    epochRewards[epoch] = Reward({ addedAtTimestamp: uint32(block.timestamp), plsDpx: _plsDpx, plsJones: _plsJones });
    totalPlsJonesRewards += _plsJones;
    totalPlsDpxRewards += _plsDpx;

    plsDPX.transferFrom(msg.sender, address(this), _plsDpx);
    plsJONES.transferFrom(msg.sender, address(this), _plsJones);

    emit DepositRewards(epoch);
  }

  /**
    Retrieve stuck funds or new reward tokens
   */
  function retrieve(IERC20 token) external onlyOwner {
    if ((address(this).balance) != 0) {
      payable(owner()).transfer(address(this).balance);
    }

    token.transfer(owner(), token.balanceOf(address(this)));
  }

  event DepositRewards(uint32 epoch);
  event ClaimRewards(address indexed _recipient);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import '../interfaces/IPlutusPrivateTGE.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IPrivateTgeHelper {
  function ALLOCATION() external view returns (uint256);

  function PRIVATE_TGE_TOTAL_RAISE() external view returns (uint256);

  function VESTING_STARTED_AT() external view returns (uint256);

  function EPOCH() external view returns (uint256);

  function CLIFF() external view returns (uint256);

  function VESTING_PERIOD() external view returns (uint256);

  function PRIVATE_TGE() external view returns (IPlutusPrivateTGE);

  function calculateShare(address _user, uint256 _quantity) external view returns (uint256);

  function plsClaimable(address _user) external view returns (uint256);

  function claimStartAt() external pure returns (uint256);
}

contract PrivateTgeHelper is IPrivateTgeHelper {
  uint256 public constant ALLOCATION = 4_200_000 * 1e18;
  uint256 public constant PRIVATE_TGE_TOTAL_RAISE = 284524761916000171659;
  uint256 public constant VESTING_STARTED_AT = 1_651_687_161;
  uint256 public constant EPOCH = 2_628_000 seconds;
  uint256 public constant CLIFF = EPOCH * 3;
  uint256 public constant VESTING_PERIOD = EPOCH * 3;

  IPlutusPrivateTGE public constant PRIVATE_TGE = IPlutusPrivateTGE(0x35cD01AaA22Ccae7839dFabE8C6Db2f8e5A7B2E0);

  /** VIEWS */
  /// @dev Calculate _user's share of _quantity
  function calculateShare(address _user, uint256 _quantity) external view returns (uint256) {
    return (PRIVATE_TGE.deposit(_user) * _quantity) / PRIVATE_TGE_TOTAL_RAISE;
  }

  function plsClaimable(address _user) external view returns (uint256) {
    return (PRIVATE_TGE.deposit(_user) * ALLOCATION) / PRIVATE_TGE_TOTAL_RAISE;
  }

  function claimStartAt() external pure returns (uint256) {
    unchecked {
      return VESTING_STARTED_AT + CLIFF;
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
pragma solidity 0.8.9;

interface IPlutusPrivateTGE {
  function deposit(address) external view returns (uint256);
}