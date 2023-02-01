// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "../periphery/interfaces/IVoter.sol";
import "../periphery/interfaces/IMinter.sol";
import "../periphery/interfaces/IGauge.sol";
import "../periphery/interfaces/IVotingEscrow.sol";
import "../periphery/interfaces/IVotingDist.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct NextEpochData {
   uint256 boostedDistAmount;
   address[] gauges;
   uint256[] boostedAmounts;
}

contract EpochFlipper {
   uint internal constant DURATION = 7 days;
   uint256 internal constant MAX_INT = 2 ** 256 - 1;

   IVoter private immutable voter;
   address private immutable votingDist;
   address private base; //XCAL token address

   //only 2 addresses that can interact w/ this contract
   address public owner;
   address public keeper;

   //Boosted emissions are distributed based on this struct
   NextEpochData internal nextEpochBoostedData;

   constructor(address _voter, address _votingDist, address _tokenAddress, address _owner) {
      voter = IVoter(_voter);
      votingDist = _votingDist;
      base = _tokenAddress;
      owner = _owner;
      nextEpochBoostedData = NextEpochData(0, new address[](0), new uint256[](0));
   }

   modifier onlyOwner() {
      require(msg.sender == owner, "only owner");
      _;
   }

   modifier onlyOwnerOrKeeper() {
      require(msg.sender == owner || msg.sender == keeper, "only owner or keeper");
      _;
   }

   //would require sending _nextEpochBoostedAmount to the contract before next epoch flip, else calling boostSelectedGauges() && veDistBoost() would fail
   function updateNextEpochData(
      uint256 _nextEpochBoostedDistAmount,
      address[] calldata _gauges,
      uint256[] calldata _amounts
   ) public onlyOwner {
      nextEpochBoostedData.boostedDistAmount = _nextEpochBoostedDistAmount;
      nextEpochBoostedData.gauges = _gauges;
      nextEpochBoostedData.boostedAmounts = _amounts;
   }

   function getNextEpochData() public view returns (NextEpochData memory) {
      return nextEpochBoostedData;
   }

   function updateKeeper(address _keeper) public onlyOwner {
      keeper = _keeper;
   }

   function updateOwner(address _owner) public onlyOwner {
      owner = _owner;
   }

   //should be called before minter.update_period()
   function veDistBoost() public onlyOwnerOrKeeper {
      require(nextEpochBoostedData.boostedDistAmount > 0);
      _safeTransfer(base, votingDist, nextEpochBoostedData.boostedDistAmount);
      nextEpochBoostedData = NextEpochData(0, nextEpochBoostedData.gauges, nextEpochBoostedData.boostedAmounts);
   }

   //should be called after minter.update_period() and voter.distro()
   function boostSelectedGauges() public onlyOwnerOrKeeper {
      _updateGaugeEmissions(nextEpochBoostedData.gauges, nextEpochBoostedData.boostedAmounts);
      nextEpochBoostedData = NextEpochData(nextEpochBoostedData.boostedDistAmount, new address[](0), new uint256[](0));
   }

   function withdrawAll() public onlyOwner {
      withdrawAmount(IERC20(base).balanceOf(address(this)));
   }

   function withdrawAmount(uint256 amount) public onlyOwner {
      _safeTransfer(base, owner, amount);
   }

   function _updateGaugeEmissions(address[] memory gauges, uint256[] memory boostedAmounts) internal {
      require(nextEpochBoostedData.gauges.length > 0, "Must have atleast 1 gauge");
      require(gauges.length == boostedAmounts.length, "Array lengths must be equal");
      for (uint256 index = 0; index < gauges.length; index++) {
         require(
            voter.isLive(gauges[index]) && voter.weights(gauges[index]) > 0,
            "Cannot boost emissions for dead gauges"
         );
         uint256 _claimable = boostedAmounts[index];
         require(
            _claimable > 0 && _claimable > IGauge(gauges[index]).left(base) && _claimable / DURATION > 0,
            "Boosted emissions must be greater than base gauge emissions"
         );
         IERC20(base).approve(gauges[index], MAX_INT);
         IGauge(gauges[index]).notifyRewardAmount(base, _claimable);
      }
   }

   function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
      require(token.code.length > 0);
      (bool success, bytes memory data) = token.call(
         abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value)
      );
      require(success && (data.length == 0 || abi.decode(data, (bool))));
   }

   function _safeTransfer(address token, address to, uint256 value) internal {
      require(token.code.length > 0);
      (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
      require(success && (data.length == 0 || abi.decode(data, (bool))));
   }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IVoter {
  function attachTokenToGauge(uint _tokenId, address account) external;

  function detachTokenFromGauge(uint _tokenId, address account) external;

  function emitDeposit(uint _tokenId, address account, uint amount) external;

  function emitWithdraw(uint _tokenId, address account, uint amount) external;

  function distribute(address _gauge) external;

  function notifyRewardAmount(uint amount) external;

  function _ve() external view returns (address);

  function createSwapGauge(address pair) external returns (address);

  function factory() external view returns (address);

  function listing_fee() external view returns (uint);

  function whitelist(address token) external;

  function isWhitelisted(address token) external view returns (bool);

  function bribeFactory() external view returns (address);

  function bribes(address gauge) external view returns (address);

  function gauges(address pair) external view returns (address);

  function isGauge(address gauge) external view returns (bool);

  function allGauges(uint index) external view returns (address);

  function vote(uint tokenId, address[] calldata gaugeVote, uint[] calldata weights) external;

  function lastVote(uint tokenId) external view returns (uint);

  function gaugeVote(uint tokenId) external view returns (address[] memory);

  function votes(uint tokenId, address gauge) external view returns (uint);

  function weights(address gauge) external view returns (uint);

  function usedWeights(uint tokenId) external view returns (uint);

  function claimable(address gauge) external view returns (uint);

  function totalWeight() external view returns (uint);

  function reset(uint tokenId) external;

  function claimFees(address[] memory bribes, address[][] memory tokens, uint tokenId) external;

  function distributeFees(address[] memory gauges) external;

  function updateGauge(address gauge) external;

  function poke(uint tokenId) external;

  function initialize(address minter) external;

  function minter() external view returns (address);

  function claimRewards(address[] memory gauges, address[][] memory rewards) external;

  function admin() external view returns (address);

  function isReward(address gauge, address token) external view returns (bool);

  function isBribe(address bribe, address token) external view returns (bool);

  function isLive(address gauge) external view returns (bool);

  function setBribe(address bribe, address token, bool status) external;

  function setReward(address gauge, address token, bool status) external;

  function killGauge(address _gauge) external;

  function reviveGauge(address _gauge) external;

  function distroFees() external;

  function distro() external;

  function updateAll() external;

  function length() external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IMinter {
  function update_period() external returns (uint);

  // function initialize(address[] memory claimants, uint[] memory amounts, uint max) external;
  function initialize() external;

  function active_period() external view returns (uint);

  function weekly_emission() external view returns (uint);

  function calculate_growth(uint _minted) external view returns (uint);

  function _token() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

struct SupplyCheckpoint {
  uint timestamp;
  uint supply;
}

struct Checkpoint {
  uint timestamp;
  uint balanceOf;
}

interface IGauge {
  function getReward(address account, address[] memory tokens) external;

  function claimFees() external returns (uint claimed0, uint claimed1);

  function left(address token) external view returns (uint);

  function deposit(uint amount, uint tokenId) external;

  function withdrawAll() external;

  function withdraw(uint amount) external;

  function totalSupply() external view returns (uint);

  function earned(address token, address account) external view returns (uint);

  function getPriorBalanceIndex(address account, uint timestamp) external view returns (uint);

  function getPriorSupplyIndex(uint timestamp) external view returns (uint);

  function getPriorRewardPerToken(address token, uint timestamp) external view returns (uint, uint);

  function batchRewardPerToken(address token, uint maxRuns) external;

  function notifyRewardAmount(address token, uint amount) external;

  function supplyNumCheckpoints() external view returns (uint);

  function supplyCheckpoints(uint i) external view returns (SupplyCheckpoint memory);

  function checkpoints(address account, uint index) external view returns (Checkpoint memory);

  function numCheckpoints(address account) external view returns (uint);

  function swapOutReward(uint i, address oldToken, address newToken) external;

  function periodFinish(address a) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IVotingEscrow {

    struct Point {
        int128 bias;
        int128 slope; // # -dweight / dt
        uint256 ts;
        uint256 blk; // block
    }

    function user_point_epoch(uint tokenId) external view returns (uint);
    function epoch() external view returns (uint);
    function user_point_history(uint tokenId, uint loc) external view returns (Point memory);
    function point_history(uint loc) external view returns (Point memory);
    function checkpoint() external;
    function deposit_for(uint tokenId, uint value) external;
    function token() external view returns (address);
    function user_point_history__ts(uint tokenId, uint idx) external view returns (uint);
    function locked__end(uint _tokenId) external view returns (uint);
    function approve(address spender, uint tokenId) external;
    function balanceOfNFT(uint) external view returns (uint);
    function isApprovedOrOwner(address, uint) external view returns (bool);
    function ownerOf(uint) external view returns (address);
    function transferFrom(address, address, uint) external;
    function totalSupply() external view returns (uint);
    function supply() external view returns (uint);
    function create_lock_for(uint, uint, address) external returns (uint);
    function attach(uint tokenId) external;
    function detach(uint tokenId) external;
    function voting(uint tokenId) external;
    function abstain(uint tokenId) external;
    function voted(uint tokenId) external view returns (bool);
    function withdraw(uint tokenId) external;
    function create_lock(uint value, uint duration) external returns (uint);
    function setVoter(address voter) external;
    function balanceOf(address owner) external view returns (uint);
    function safeTransferFrom(address from, address to, uint tokenId) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.11;

interface IVotingDist {
  function checkpoint_token() external;

  function checkpoint_total_supply() external;

  function token_last_balance() external returns (uint);

  function claimable(uint _tokenId) external view returns (uint);

  function claim(uint _tokenId) external returns (uint);
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