/**
 *Submitted for verification at Arbiscan on 2023-03-01
*/

// Sources flattened with hardhat v2.10.1-gzeon-c8fe47dd4 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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

// File @openzeppelin/contracts/access/[email protected]
pragma solidity ^0.8.0;

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
    require(owner() == _msgSender(), 'Ownable: caller is not the owner');
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
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
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

// File @openzeppelin/contracts/utils/[email protected]
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
    require(address(this).balance >= amount, 'Address: insufficient balance');

    (bool success, ) = recipient.call{ value: amount }('');
    require(success, 'Address: unable to send value, recipient may have reverted');
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
    return functionCall(target, data, 'Address: low-level call failed');
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
    return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
    require(address(this).balance >= value, 'Address: insufficient balance for call');
    require(isContract(target), 'Address: call to non-contract');

    (bool success, bytes memory returndata) = target.call{ value: value }(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
    return functionStaticCall(target, data, 'Address: low-level static call failed');
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
    require(isContract(target), 'Address: static call to non-contract');

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
    return functionDelegateCall(target, data, 'Address: low-level delegate call failed');
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
    require(isContract(target), 'Address: delegate call to non-contract');

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

// File @openzeppelin/contracts/token/ERC20/[email protected]0
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

// File contracts/plsSPA/GaugeInterfaces.sol
pragma solidity 0.8.9;

interface IGaugeController {
  function voteForGaugeWeight(address _gAddr, uint256 _userWeight) external;

  function timeTotal() external view returns (uint256);

  function getGaugeList() external view returns (address[] memory);

  function getUserVotesWtForGauge(address _gAddr, uint256 _time) external view returns (uint256);

  function getGaugeWeight(address _gAddr) external view returns (uint256);

  function getGaugeWeight(address _gAddr, uint256 _time) external view returns (uint256);

  function gaugeRelativeWeight(address _gAddr) external view returns (uint256);

  function gaugeRelativeWeight(address _gAddr, uint256 _time) external view returns (uint256);

  function getTotalWeight() external view returns (uint256);

  function getTypeWeight(uint128 _gType) external view returns (uint256);

  function getWeightsSumPerType(uint128 _gType) external view returns (uint256);

  function gaugeType(address _gAddr) external view returns (uint128);

  function gaugeBribe(address _gAddr) external view returns (address);

  function userVotePower(address _user) external view returns (uint256);

  function userVoteData(address _user, address _gAddr)
    external
    view
    returns (
      uint256 slope,
      uint256 power,
      uint256 end,
      uint256 voteTime
    );
}

interface IBribe {
  function claimRewards(address _user) external;

  function getAllBribeTokens() external view returns (address[] memory);

  function computeRewards(address _user) external view returns (uint256[] memory);
}

interface ISpaStakerGaugeHandler {
  function voteForGaugeWeight(address _gAddr, uint256 _userWeight) external;

  function transferReward(address _token, address _to) external;
}

// File contracts/plsSPA/interfaces.sol
pragma solidity 0.8.9;

interface IveSPA {
  function getLastUserSlope(address addr) external view returns (int128);

  function getUserPointHistoryTS(address addr, uint256 idx) external view returns (uint256);

  function userPointEpoch(address addr) external view returns (uint256);

  function checkpoint() external;

  function lockedEnd(address addr) external view returns (uint256);

  function depositFor(address addr, uint128 value) external;

  function createLock(
    uint128 value,
    uint256 unlockTime,
    bool autoCooldown
  ) external;

  function increaseAmount(uint128 value) external;

  function increaseUnlockTime(uint256 unlockTime) external;

  function initiateCooldown() external;

  function withdraw() external;

  function balanceOf(address addr, uint256 ts) external view returns (uint256);

  function balanceOf(address addr) external view returns (uint256);

  function balanceOfAt(address, uint256 blockNumber) external view returns (uint256);

  function totalSupply(uint256 ts) external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function totalSupplyAt(uint256 blockNumber) external view returns (uint256);
}

interface IRewardDistributor_v2 {
  function checkpointReward() external;

  function computeRewards(address addr)
    external
    view
    returns (
      uint256, // total rewards earned by user
      uint256, // lastRewardCollectionTime
      uint256 // rewardsTill
    );

  function claim(bool restake) external returns (uint256);
}

interface IStaker {
  function stake(uint256) external;

  function release() external;

  function claimFees(
    address _distroContract,
    address _token,
    address _claimTo
  ) external returns (uint256);
}

interface IFeeClaimer {
  function pendingRewards() external view returns (uint256 pendingRewardsLessFee, uint256 protocolFee);

  function harvest() external;
}

// File contracts/plsSPA/PlsSpaVoter.sol
pragma solidity 0.8.9;

interface IPlsSpaVoter {
  struct RewardInfo {
    address gauge;
    address bribe;
    address[] tokens;
    uint256[] rewards;
  }

  struct VoteInfo {
    address gauge;
    uint256 weight;
    uint256 power;
    uint256 userWeight;
  }

  error FAILED(string);
}

contract PlsSpaVoter is IPlsSpaVoter, Ownable {
  ISpaStakerGaugeHandler public constant SPA_STAKER =
    ISpaStakerGaugeHandler(0x46ac70bf830896EEB2a2e4CBe29cD05628824928);
  IGaugeController public constant GAUGE_CONTROLLER = IGaugeController(0x895D0A8A439616e737Dcfb3BD59C552CBA05251c);
  IveSPA public constant VESPA = IveSPA(0x2e2071180682Ce6C247B1eF93d382D509F5F6A17);
  address public bribeDistro;

  /** VIEW FUNCTIONS */
  function voteStats(address _user)
    external
    view
    returns (
      uint256 totalUserWeight,
      uint256 totalWeight,
      VoteInfo[] memory voteInfo
    )
  {
    totalUserWeight = VESPA.balanceOf(_user, GAUGE_CONTROLLER.timeTotal());
    totalWeight = GAUGE_CONTROLLER.getTotalWeight();

    address[] memory gaugeList = GAUGE_CONTROLLER.getGaugeList();
    voteInfo = new VoteInfo[](gaugeList.length);

    for (uint256 i; i < gaugeList.length; i = _unsafeInc(i)) {
      (, uint256 power, , ) = GAUGE_CONTROLLER.userVoteData(_user, gaugeList[i]);
      uint256 weight = GAUGE_CONTROLLER.getGaugeWeight(gaugeList[i]);

      unchecked {
        voteInfo[i] = VoteInfo({
          gauge: gaugeList[i],
          power: power,
          weight: weight,
          userWeight: (power * totalUserWeight) / 1e4
        });
      }
    }
  }

  function pendingRewards(address _user) external view returns (RewardInfo[] memory rewardInfo) {
    address[] memory gaugeList = GAUGE_CONTROLLER.getGaugeList();
    rewardInfo = new RewardInfo[](gaugeList.length);

    for (uint256 i; i < gaugeList.length; i = _unsafeInc(i)) {
      address bribe = GAUGE_CONTROLLER.gaugeBribe(gaugeList[i]);

      rewardInfo[i] = RewardInfo({
        gauge: gaugeList[i],
        bribe: bribe,
        tokens: IBribe(bribe).getAllBribeTokens(),
        rewards: IBribe(bribe).computeRewards(_user)
      });
    }
  }

  function _unsafeInc(uint256 x) private pure returns (uint256) {
    unchecked {
      return x + 1;
    }
  }

  /** OWNER FUNCTIONS */
  /**
    Retrieve stuck funds
   */
  function retrieve(IERC20 _erc20) external onlyOwner {
    if ((address(this).balance) != 0) {
      Address.sendValue(payable(owner()), address(this).balance);
    }

    _erc20.transfer(owner(), _erc20.balanceOf(address(this)));
  }

  function voteForGaugeWeight(address _gAddr, uint256 _userWeight) external onlyOwner {
    ISpaStakerGaugeHandler(SPA_STAKER).voteForGaugeWeight(_gAddr, _userWeight);
  }

  ///@dev Must have already claimed reward by calling bribe.claimRewards()
  function transferReward(address _token) external onlyOwner {
    if (bribeDistro == address(0)) revert FAILED('!addr');
    ISpaStakerGaugeHandler(SPA_STAKER).transferReward(_token, bribeDistro);
  }

  function setBribeDistro(address _bribeDistro) external onlyOwner {
    bribeDistro = _bribeDistro;
  }
}