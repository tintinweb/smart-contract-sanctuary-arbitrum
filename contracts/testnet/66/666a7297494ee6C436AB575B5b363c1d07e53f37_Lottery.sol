// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./Pool/Pool.sol";
import "./Period.sol";

contract Lottery is Pool, Period, Pausable, ReentrancyGuard {
  /*==================================================== Modifiers ====================================================*/

  modifier whenNotClaimed(uint256 _ticketId) {
    require(!withdrawnTicketIds[_ticketId], "LOT: Already claimed");
    withdrawnTicketIds[_ticketId] = true;
    _;
  }
  
  /*==================================================== State Variables ====================================================*/

  /// @notice withdrawn ticket ids to check on claim
  mapping(uint256 => bool) public withdrawnTicketIds;

  /*==================================================== Functions ====================================================*/

  constructor(IRandomizerRouter _router) Period(_router) {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  /// @notice returns winning numbers of period
  /// @param _periodId id for period
  function getNumbers(uint256 _periodId) public view returns (uint256[6] memory numbers_) {
    numbers_ = periods[_periodId].numbers;
  }

  /// @notice returns encoded winning numbers of period
  /// @param _periodId id for period
  function getNumbersEncoded(uint256 _periodId) public view returns (bytes[6] memory encodedNumbers_) {
    encodedNumbers_ = encode(getNumbers(_periodId));
  }

  /// @notice used to buy tickets
  /// @param _input token address which wants to pay in
  function buyTickets(address _input, uint256[6][] memory _numbers) external whenNotPaused {
    _saveTicketBatch(_msgSender(), periodId, _numbers);
    _payin(_msgSender(), periodId, _input, uint8(_numbers.length));
  }

  /// @notice claim reward by ticket id
  /// @param _output token address to get payment in the currency or wlp address 
  /// @param _periodId which is ticket id's connected
  /// @param _ticketId winning ticket id
  function claim(address _output, uint256 _periodId, uint256 _ticketId) external nonReentrant whenNotClaimed(_ticketId) {
    bytes[6] memory encodedWinningNumbers_ = encode(periods[_periodId].numbers);
    uint256 reward_ = _payout(_output, _periodId, _ticketId, encodedWinningNumbers_);

    periods[_periodId].claimedAmount += reward_;
  }

    /// @notice calling by period while finalizing the period
    /// @param _periodId period's id
    /// @param _encodedWinningNumbers encoded result
   function _onPeriodFulfilled(uint256 _periodId, bytes[6] memory _encodedWinningNumbers) internal override {
    _distributeRewards(_periodId, _encodedWinningNumbers);
  }

  function pause() external onlyTeam {
    _pause();
  }

  function unpause() external onlyTeam {
    _unpause();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../helpers/Number.sol";
import "../../helpers/Access.sol";
import "../../helpers/RandomizerConsumer.sol";
import "./Helper.sol";

abstract contract Period is Access, RandomizerConsumer, NumberHelper, Helper {
  /*==================================================== Events =============================================================*/

  event Fulfilled(uint256 period, uint256[6] numbers);
  event DurationUpdated(uint32 duration);
  event MaxSelectableNumberUpdated(uint32 maxSelectableNumber);

  /*==================================================== Modifiers ====================================================*/

  modifier whenNotFulfilled(uint256 _requestId) {
    uint256 _period = randomRequests[_requestId];
    require(periods[_period].status != Status.FULFILLED, "Call finalize");
    periods[_period].status = Status.FULFILLED;
    _;
  }

  /*==================================================== State Variables ====================================================*/

  enum Status {
    ACTIVE,
    FULFILLED
  }

  struct LotteryPeriod {
    uint256 requestId;
    uint256 claimedAmount;
    uint256 finishDate;
    uint256[6] numbers;
    Status status;
  }

  /// @notice incremental period id
  uint256 public periodId;
  /// @notice duration of a period
  uint32 public duration = 5 minutes;
  /// @notice period data
  mapping(uint256 => LotteryPeriod) public periods;
  /// @notice scheduled random request -> period pair
  mapping(uint256 => uint256) public randomRequests;
  /// @notice max selectable number 0-9
  uint32 public maxSelectableNumber = 9;

  /*==================================================== Functions ===========================================================*/

  constructor(IRandomizerRouter _router) RandomizerConsumer(_router) {}

  /// @notice updates duration a period 
  /// @param _duration default 1 day
  function updateDuration(uint32 _duration) external onlyGovernance {
    duration = _duration;

    emit DurationUpdated(_duration);
  }

  /// @notice updates max selectable number for every digit
  /// @param _maxSelectableNumber default 0-9
  function updateMaxSelectableNumber(uint32 _maxSelectableNumber) external onlyGovernance {
    maxSelectableNumber = _maxSelectableNumber;

    emit MaxSelectableNumberUpdated(_maxSelectableNumber);
  }

  /// @notice initializa first period
  function initialize() external onlyGovernance {
    _createPeriod();
  }

  /// @notice increment period and creates new
  function _next() internal {
    periodId++;
    _createPeriod();
  }

  /// @notice used to create new period and requests random
  function _createPeriod() internal {
    uint256[6] memory numbers;
    uint256 requestId_ = _requestScheduledRandom(6, block.timestamp + duration);
    randomRequests[requestId_] = periodId;

    periods[periodId] = LotteryPeriod(requestId_, 0, block.timestamp + duration, numbers, Status.ACTIVE);
  }

  /// @notice mods the raw random numbers and sets to period
  /// @param _periodId period's id
  /// @param _randomNumbers raw random numbers
  function _setRandomNumbers(
    uint256 _periodId,
    uint256[] memory _randomNumbers
  ) internal returns (uint256[6] memory) {
    for (uint8 i = 0; i < 6; i ++) {
      periods[_periodId].numbers[i] = modNumber(_randomNumbers[i], maxSelectableNumber);
    }

    return periods[_periodId].numbers;
  }

  /// @notice mods the raw random numbers and sets to period
  /// @param _periodId period's id
  /// @param _encodedWinningNumbers encoded result
  function _onPeriodFulfilled(uint256 _periodId, bytes[6] memory _encodedWinningNumbers) internal virtual;

  /// @notice used to finalize the period and emit
  /// @param _requestId scheduled random request id
  /// @param _randomNumbers raw random numbers
  function randomizerFulfill(uint256 _requestId, uint256[] calldata _randomNumbers) internal override whenNotFulfilled(_requestId) {
    _next();

    uint256 _period = randomRequests[_requestId];
    uint256[6] memory numbers = _setRandomNumbers(_period, _randomNumbers);
    bytes[6] memory numbersEncoded = encode(numbers);

    _onPeriodFulfilled(_period, numbersEncoded);

    emit Fulfilled(_period, numbers);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../../../interfaces/vault/IWlpManager.sol";
import "../../../../interfaces/core/IVaultManager.sol";
import "./Ticket.sol";

abstract contract Pool is Ticket {
  /*==================================================== Events =============================================================*/

  event Payin(address indexed payer, uint256 wlp);
  event Payout(address indexed recipient, uint256 ticketId, uint256 digits, uint256 reward);
  event VaultManagerChange(address vaultManager);
  event WlpManagerChange(address wlpManager);
  event TicketPriceUpdated(uint256 price);
  event PlatformFeeRatioUpdated(uint256 ratio);
  event WinningRatiosUpdated(uint256[6] ratios);

  /*==================================================== State Variables ====================================================*/
  
  /// @notice ticket price in dollar
  uint256 public ticketPrice = 10e30;
  /// @notice used to calculate platform fee
  uint256 public platformFeeRatio = 2e17;
  /// @notice the idle amount from the prev period
  uint256 public transferrorAmount;
  /// @notice vault manager
  IVaultManager public vaultManager;
  /// @notice vault manager
  IWlpManager public wlpManager;
  /// @notice used to calculate precise decimals
  uint256 public constant PRECISION = 1e18;
  /// @notice the sum of the rates should not exceed 1e18 - platformFeeRatio
  mapping(uint256 => uint256) public winningRatios;
  /// @notice periods ticket price sold
  mapping(uint256 => uint256) public totalTicketPriceSold;
  /// @notice period's reward amount for winning ratios
  mapping(uint256 => mapping(uint256 => uint256)) public periodRewards;

  /*==================================================== Functions ===========================================================*/

  /// @notice gets vault instance from manager
  function getVault() internal view returns (IVault) {
    return vaultManager.vault();
  }

  /// @notice set vault manager 
  function setVaultManager(IVaultManager _vaultManager) external onlyGovernance {
    vaultManager = _vaultManager;
    emit VaultManagerChange(address(_vaultManager));
  }

  /// @notice set wlp manager 
  function setWlpManager(IWlpManager _wlpManager) external onlyGovernance {
    wlpManager = _wlpManager;
    emit WlpManagerChange(address(_wlpManager));
  }

  /// @notice ticket price should be in dollar
  /// @param _ticketPrice dollar price of ticket
  function updateTicketPrice(uint256 _ticketPrice) external onlyGovernance {
    ticketPrice = _ticketPrice;
    emit TicketPriceUpdated(_ticketPrice);
  }

  /// @notice used to calculate the payout amount the platform will receive.
  /// @param _ratio default 0.2 max 1e18
  function updatePlatformFeeRatio(uint256 _ratio) external onlyGovernance {
    platformFeeRatio = _ratio;
    emit PlatformFeeRatioUpdated(_ratio);
  }

  /// @notice used to calculate the reward amounts
  /// @param _winningRatios the sum of the rates should not exceed 1e18 - platformFeeRatio
  function updateWinningRatios(uint256[6] memory _winningRatios) external onlyGovernance {
    winningRatios[6] = _winningRatios[5];
    winningRatios[5] = _winningRatios[4];
    winningRatios[4] = _winningRatios[3];
    winningRatios[3] = _winningRatios[2];
    winningRatios[2] = _winningRatios[1];
    winningRatios[1] = _winningRatios[0];

    emit WinningRatiosUpdated(_winningRatios);
  }

  /// @notice calculates ticket price for given currency
  /// @param _token currency
  function getTicketPrice(address _token) public view returns (uint256 convertedPrice_) {
    convertedPrice_ = (ticketPrice * PRECISION) / vaultManager.getPrice(_token);
  }

  /// @notice used to collect winning ticket counts
  /// @param _period id
  /// @param _encodedNumbers encoded winning numbers of given period
  function getWinningTicketCounts(uint256 _period, bytes[6] memory _encodedNumbers) public view returns (uint256[7] memory counts) {
    uint32 total;

    for (uint8 i = 6; i >= 1; i--) {
      counts[i] = ticketNumberDataPair[_period][_encodedNumbers[i - 1]].length - total;
      total += uint32(counts[i]);
    }
  }

  /// @notice calculates total reward of givem period
  /// @param _period id
  function getTotalReward(uint256 _period) public view returns (uint256 amount) {
    amount = totalTicketPriceSold[_period] + transferrorAmount;
  }

  /// @notice calculates total reward of givem period
  /// @param _period id
  function _setPeriodRewards(uint256 _period) internal {
    uint256 totalReward = getTotalReward(_period);

    for (uint8 i = 6; i >= 1; i--) {
      // Sets reward for digits
      periodRewards[_period][i] = (totalReward * winningRatios[i]) / PRECISION;
    }
  }

  /// @notice used to transfer platform fee to collector
  /// @param _period id
  function _transferPlatformFee(uint256 _period) internal {
    uint256 totalReward_ = getTotalReward(_period);
   
    if (totalReward_ > 0) {
      uint256 fee_ = (totalReward_ * platformFeeRatio) / PRECISION;

      if (fee_ > 0) {
        IERC20 wlp_ = IERC20(wlpManager.wlp());
        wlp_.transfer(address(vaultManager.feeCollector()), fee_);
      }
    }
  }

  /// @notice transfers the idle amount to the next period
  /// @param _period id
  /// @param _winningTicketCounts ticket counts of winning numbers
  function _setTransferrorAmount(uint256 _period, uint256[7] memory _winningTicketCounts) internal {
    transferrorAmount = 0;

    for (uint8 i = 6; i >= 1; i--) {
      if (_winningTicketCounts[i] == 0) {
        transferrorAmount += periodRewards[_period][i];
      }
    }
  }

  /// @notice distributes the rewards
  /// @param _period id
  /// @param _encodedNumbers encoded choisen ticket numbers
  function _distributeRewards(uint256 _period, bytes[6] memory _encodedNumbers) internal {
    uint256[7] memory counts_ = getWinningTicketCounts(_period, _encodedNumbers);

    _setPeriodRewards(_period);
    _transferPlatformFee(_period);
    _setTransferrorAmount(_period, counts_);
  }

  /// @notice deposit amount to wlp and add to ticketPrices as WLP
  /// @param _payer address of ticket's owner
  /// @param _period id
  /// @param _input currency of amount
  /// @param _ticketCount purchasing ticket count
  function _payin(address _payer, uint256 _period, address _input, uint8 _ticketCount) internal {
    uint256 ticketPriceInCurrency_ = getTicketPrice(_input);
    uint256 totalPrice_ = ticketPriceInCurrency_ * _ticketCount;

    IERC20 wlp_ = IERC20(wlpManager.wlp());

    uint256 wlpAmount_ = wlpManager.addLiquidityForAccount(_payer, address(this), _input, totalPrice_, 0, 0);
    vaultManager.mintVestedWINR(_input, totalPrice_, _payer);
    totalTicketPriceSold[_period] += wlpAmount_;

    emit Payin(_payer, wlpAmount_);
  }

  /// @notice calculates the reward of ticket
  /// @param _period id
  /// @param _digits winning digit count
  /// @param _encodedWinningNumbers encoded winning numbers
  function calcReward(
    uint256 _period, 
    uint256 _digits, 
    bytes[6] memory _encodedWinningNumbers
  ) internal view returns (uint256 reward_) {
    uint256[7] memory winnerCounts = getWinningTicketCounts(_period, _encodedWinningNumbers);
    reward_ = periodRewards[_period][_digits] / winnerCounts[_digits];
  }

  /// @notice withdraw rewards from pool
  /// @param _output currency of amount
  /// @param _period id
  /// @param _ticketId winning ticket id
  /// @param _encodedWinningNumbers encoded winning numbers
  function _payout(
    address _output, 
    uint256 _period, 
    uint256 _ticketId, 
    bytes[6] memory _encodedWinningNumbers
  ) internal isSenderOwnerOfTicket(_ticketId) returns (uint256 reward_) {
    IVault vault_ = getVault();
    (TicketData memory data, uint32 digits_) = getTicketById(_ticketId, _period, _encodedWinningNumbers);
    reward_ = calcReward(_period, digits_, _encodedWinningNumbers); 
    IERC20 wlp_ = IERC20(wlpManager.wlp());

    if (_output != address(vault_)) {
      wlp_.transfer(address(vault_), reward_);
      vault_.withdraw(_output, msg.sender);
    } else {
      wlp_.transfer(data.owner, reward_);
    }

    emit Payout(_msgSender(), _ticketId, digits_, reward_);
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
pragma solidity 0.8.17;

contract NumberHelper {
  function modNumber(uint256 _number, uint32 _mod) internal pure returns (uint256) {
    return _mod > 0 ? _number % _mod : _number;
  }

  function modNumbers(uint256[] memory _numbers, uint32 _mod) internal pure returns (uint256[] memory) {
    uint256[] memory modNumbers_ = new uint[](_numbers.length);

    for (uint256 i = 0; i < _numbers.length; i++) {
      modNumbers_[i] = modNumber(_numbers[i], _mod);
    }

    return modNumbers_;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract Access is AccessControl {
  /*==================================================== Modifiers ==========================================================*/

  modifier onlyGovernance() virtual {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ACC: Not governance");
    _;
  }

  modifier onlyTeam() virtual {
    require(hasRole(TEAM_ROLE, _msgSender()), "GAME: Not team");
    _;
  }

  /*==================================================== State Variables ====================================================*/

  bytes32 public constant TEAM_ROLE = bytes32(keccak256("TEAM"));

  /*==================================================== Functions ===========================================================*/

  constructor()  {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Access.sol";
import "../../interfaces/randomizer/providers/supra/ISupraRouter.sol";
import "../../interfaces/randomizer/IRandomizerRouter.sol";
import "../../interfaces/randomizer/IRandomizerConsumer.sol";
import "./Number.sol";

abstract contract RandomizerConsumer is Access, IRandomizerConsumer {
  /*==================================================== Modifiers ===========================================================*/

  modifier onlyRandomizer() {
    require(hasRole(RANDOMIZER_ROLE, _msgSender()), "RC: Not randomizer");
    _;
  }

  /*==================================================== State Variables ====================================================*/

  /// @notice minimum confirmation blocks
  uint256 public minConfirmations = 3;
  /// @notice router address
  IRandomizerRouter public randomizerRouter;
  /// @notice Randomizer ROLE as Bytes32
  bytes32 public constant RANDOMIZER_ROLE = bytes32(keccak256("RANDOMIZER"));

  /*==================================================== FUNCTIONS ===========================================================*/

  constructor(IRandomizerRouter _randomizerRouter) {
    changeRandomizerRouter(_randomizerRouter);
  }

  /*==================================================== Configuration Functions ====================================================*/

  function changeRandomizerRouter(IRandomizerRouter _randomizerRouter) public onlyGovernance {
    randomizerRouter = _randomizerRouter;
    grantRole(RANDOMIZER_ROLE, address(_randomizerRouter));
  }


  function setMinConfirmations(uint16 _minConfirmations) external onlyGovernance {
    minConfirmations = _minConfirmations;
  }

  /*==================================================== Randomizer Functions ====================================================*/

  function randomizerFulfill(uint256 _requestId, uint256[] calldata _rngList) internal virtual;

  function randomizerCallback(uint256 _requestId, uint256[] calldata _rngList) external onlyRandomizer {
    randomizerFulfill(_requestId, _rngList);
  }

  function _requestRandom(uint8 _count) internal returns (uint256 requestId_) {
    requestId_ = randomizerRouter.request(_count, minConfirmations);
  }

  function _requestScheduledRandom(uint8 _count, uint256 targetTime) internal returns (uint256 requestId_) {
    requestId_ = randomizerRouter.scheduledRequest(_count, targetTime);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

abstract contract Helper {
  function encode(uint256[6] memory _numbers) public pure returns (bytes[6] memory encodedNumbers_) {
    encodedNumbers_[0] = abi.encodePacked(_numbers[0]);
    encodedNumbers_[1] = abi.encodePacked(_numbers[0], _numbers[1]);
    encodedNumbers_[2] = abi.encodePacked(_numbers[0], _numbers[1], _numbers[2]);
    encodedNumbers_[3] = abi.encodePacked(_numbers[0], _numbers[1], _numbers[2], _numbers[3]);
    encodedNumbers_[4] = abi.encodePacked(_numbers[0], _numbers[1], _numbers[2], _numbers[3], _numbers[4]);
    encodedNumbers_[5] = abi.encodePacked(_numbers[0], _numbers[1], _numbers[2], _numbers[3], _numbers[4], _numbers[5]);
  }
}

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
pragma solidity 0.8.17;

interface IRandomizerConsumer {
  function randomizerCallback(uint256 _requestId, uint256[] calldata _rngList) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IRandomizerRouter {
  function request(uint32 count, uint256 _minConfirmations) external returns (uint256);
  function scheduledRequest(uint32 _count, uint256 targetTime) external returns (uint256);
  function response(uint256 _requestId, uint256[] calldata _rngList) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.5 <0.9.0;

// interface ISupraRouter { 
// 	function generateRequest(string memory _functionSig, uint8 _rngCount, uint256 _numConfirmations, address _clientWalletAddress) external returns(uint256);
//     function generateRequest(string memory _functionSig, uint8 _rngCount, uint256 _numConfirmations, uint256 _clientSeed, address _clientWalletAddress) external returns(uint256);
// }
interface ISupraRouter { 
    function generateRequest(string memory _functionSig , uint8 _rngCount, uint256 _numConfirmations) external returns(uint256); 
    function generateRequest(string memory _functionSig , uint8 _rngCount, uint256 _numConfirmations, uint256 _clientSeed) external returns(uint256); 
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IWlpManager {
    function wlp() external view returns (address);
    // function usdw() external view returns (address);
    // function vault() external view returns (IVault);
    // function cooldownDuration() external returns (uint256);
    // function getAumInUsdw(bool maximise) external view returns (uint256);
    // function lastAddedAt(address _account) external returns (uint256);
    function addLiquidity(address _token, uint256 _amount, uint256 _minUsdw, uint256 _minWlp) external returns (uint256);
    function addLiquidityForAccount(address _fundingAccount, address _account, address _token, uint256 _amount, uint256 _minUsdw, uint256 _minWlp) external returns (uint256);
    // function removeLiquidity(address _tokenOut, uint256 _wlpAmount, uint256 _minOut, address _receiver) external returns (uint256);
    // function removeLiquidityForAccount(address _account, address _tokenOut, uint256 _wlpAmount, uint256 _minOut, address _receiver) external returns (uint256);
    // function setCooldownDuration(uint256 _cooldownDuration) external;
    // function getAum(bool _maximise) external view returns(uint256);
    // function getPriceWlp(bool _maximise) external view returns(uint256);
    // function getPriceWLPInUsdw(bool _maximise) external view returns(uint256);
    // function circuitBreakerTrigger(address _token) external;
    // function aumDeduction() external view returns(uint256);
    // function reserveDeduction() external view returns(uint256);

    // function maxPercentageOfWagerFee() external view returns(uint256);
    // function addLiquidityFeeCollector(
    //     address _token, 
    //     uint256 _amount, 
    //     uint256 _minUsdw, 
    //     uint256 _minWlp) external returns (uint256 wlpAmount_);


    // /*==================== Events *====================*/
    // event AddLiquidity(
    //     address account,
    //     address token,
    //     uint256 amount,
    //     uint256 aumInUsdw,
    //     uint256 wlpSupply,
    //     uint256 usdwAmount,
    //     uint256 mintAmount
    // );

    // event RemoveLiquidity(
    //     address account,
    //     address token,
    //     uint256 wlpAmount,
    //     uint256 aumInUsdw,
    //     uint256 wlpSupply,
    //     uint256 usdwAmount,
    //     uint256 amountOut
    // );

    // event PrivateModeSet(
    //     bool inPrivateMode
    // );

    // event HandlerEnabling(
    //     bool setting
    // );

    // event HandlerSet(
    //     address handlerAddress,
    //     bool isActive
    // );

    // event CoolDownDurationSet(
    //     uint256 cooldownDuration
    // );

    // event AumAdjustmentSet(
    //     uint256 aumAddition,
    //     uint256 aumDeduction
    // );

    // event MaxPercentageOfWagerFeeSet(
    //     uint256 maxPercentageOfWagerFee
    // );

    // event CircuitBreakerTriggered(
    //     address forToken,
    //     bool pausePayoutsOnCB,
    //     bool pauseSwapOnCB,
    //     uint256 reserveDeductionOnCB
    // );

    // event CircuitBreakerPolicy(
    //     bool pausePayoutsOnCB,
    //     bool pauseSwapOnCB,
    //     uint256 reserveDeductionOnCB
    // );

    // event CircuitBreakerReset(
    //     bool pausePayoutsOnCB,
    //     bool pauseSwapOnCB,
    //     uint256 reserveDeductionOnCB
    // );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/vault/IFeeCollector.sol";
import "../../interfaces/vault/IVault.sol";

/// @dev This contract designed to easing token transfers broadcasting information between contracts
interface IVaultManager {
  function vault() external view returns (IVault);

  function wlp() external view returns (IERC20);

  function feeCollector() external view returns (IFeeCollector);

  function getMaxWager() external view returns (uint256);

  function getMinWager(address _game) external view returns (uint256);

  function getWhitelistedTokens() external view returns (address[] memory whitelistedTokenList_);

  function refund(address _token, uint256 _amount, uint256 _vWINRAmount, address _player) external;

  /// @notice escrow tokens into the manager
  /// @param _token one of the whitelisted tokens which is collected in settings
  /// @param _sender holder of tokens
  /// @param _amount the amount of token
  function escrow(address _token, address _sender, uint256 _amount) external;

  /// @notice function that assign reward of referral
  /// @param _token one of the whitelisted tokens which is collected in settings
  /// @param _player holder of tokens
  /// @param _amount the amount of token
  /// @param _houseEdge edge percent of game eg. 1000 = 10.00
  function setReferralReward(
    address _token,
    address _player,
    uint256 _amount,
    uint64 _houseEdge
  ) external returns (uint256 referralReward_);

  /// @notice function that remove reward of referral
  /// @param _token one of the whitelisted tokens which is collected in settings
  /// @param _player holder of tokens
  /// @param _amount the amount of token
  function removeReferralReward(address _token, address _player, uint256 _amount) external;

  /// @notice release some amount of escrowed tokens
  /// @param _token one of the whitelisted tokens which is collected in settings
  /// @param _recipient holder of tokens
  /// @param _amount the amount of token
  function payback(address _token, address _recipient, uint256 _amount) external;

  /// @notice lets vault get wager amount from escrowed tokens
  /// @param _token one of the whitelisted tokens which is collected in settings
  /// @param _amount the amount of token
  function getEscrowedTokens(address _token, uint256 _amount) external;

  /// @notice lets vault get wager amount from escrowed tokens
  function payout(
    address[2] memory _tokens,
    address _recipient,
    uint256 _escrowAmount,
    uint256 _totalAmount
  ) external;

  /// @notice lets vault get wager amount from escrowed tokens
  function payin(address _token, uint256 _escrowAmount) external;

  /// @notice transfers any whitelisted token into here
  /// @param _token one of the whitelisted tokens which is collected in settings
  /// @param _sender holder of tokens
  /// @param _amount the amount of token
  function transferIn(address _token, address _sender, uint256 _amount) external;

  /// @notice transfers any whitelisted token to recipient
  /// @param _token one of the whitelisted tokens which is collected in settings
  /// @param _recipient of tokens
  /// @param _amount the amount of token
  function transferOut(address _token, address _recipient, uint256 _amount) external;

  /// @notice used to mint vWINR to recipient
  /// @param _input currency of payment
  /// @param _amount of wager
  /// @param _recipient recipient of vWINR
  function mintVestedWINR(
    address _input,
    uint256 _amount,
    address _recipient
  ) external returns (uint256 vWINRAmount_);

  /// @notice used to transfer player's token to WLP
  /// @param _input currency of payment
  /// @param _amount convert token amount
  /// @param _sender sender of token
  /// @param _recipient recipient of WLP
  function deposit(
    address _input,
    uint256 _amount,
    address _sender,
    address _recipient
  ) external returns (uint256);

  function getPrice(address _token) external view returns (uint256 _price);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../Helper.sol";
import "../../../helpers/Access.sol";

abstract contract Ticket is Access, Helper {
  /*==================================================== Events =============================================================*/

  event TicketGeneratedBatch(
    address indexed to,
    uint256[] ids,
    uint256 period,
    uint256[6][] numbers
  );

  /*==================================================== Modifiers ====================================================*/

  modifier isSenderOwnerOfTicket(uint256 _ticketId) {
    TicketData memory ticket = tickets[_ticketId];
    require(ticket.owner == _msgSender(), "Not owner");
    _;
  }

  /*==================================================== State Variables ====================================================*/
  
  struct TicketData {
    uint256 id;
    uint256 period;
    address owner;
  }

  /// @notice keeps the ticket data mapped by encoded choices number
  mapping(uint256 => mapping(bytes => uint256[])) public ticketNumberDataPair;
  /// @notice ticket datas
  TicketData[] public tickets;

  /*==================================================== EXTERNAL FUNCTIONS ===========================================================*/

  function getTicketCount() public view returns (uint256) {
    return tickets.length;
  }

  /// @notice generates ticket
  /// @param _to owner address of the ticket
  /// @param _numbers choisen ticket numbers
  function _saveTicket(
    address _to,
    uint256 _period, 
    uint256[6] memory _numbers
  ) internal returns (
    uint256
  ) {
    bytes[6] memory encodedNumbers_ = encode(_numbers);
    TicketData memory prevTicket_ = getTicketOfOwner(_to, _period, encodedNumbers_);
    require(prevTicket_.owner != _to, "LOT: Already bought");
    uint256 ticketId_ = tickets.length;

    TicketData memory ticket_ = TicketData(ticketId_, _period, _to);
    tickets.push(ticket_);

    for (uint8 x = 0; x <= 5; x++) {
      ticketNumberDataPair[_period][encodedNumbers_[x]].push(ticketId_);
    }

    return ticketId_;
  }

  /// @notice generates tickets
  /// @param _to owner address of the ticket
  /// @param _numbers choisen ticket number list
  function _saveTicketBatch(
    address _to,
    uint256 _period, 
    uint256[6][] memory _numbers
  ) internal returns (
    uint256[] memory generatedTicketIds_
  ) {
    uint256 ticketCount_ = _numbers.length;
    generatedTicketIds_ = new uint256[](ticketCount_);

    for (uint8 i = 0; i < ticketCount_; i++) {
      generatedTicketIds_[i] = _saveTicket(_to, _period, _numbers[i]);
    }

    emit TicketGeneratedBatch(_to, generatedTicketIds_, _period, _numbers);
  }

  /// @notice gets ticket by owner
  /// @param _owner owner address of the ticket
  /// @param _period id
  /// @param _encodedNumbers encoded choisen ticket numbers
  function getTicketOfOwner(
    address _owner,
    uint256 _period,
    bytes[6] memory _encodedNumbers
  ) public view returns (
    TicketData memory
  ) {
    uint256[] memory _ticketIds = ticketNumberDataPair[_period][_encodedNumbers[5]];
    uint256 ticketCount_ = _ticketIds.length;
    
    if (ticketCount_ > 0) {
      TicketData memory ticket_;

      for (uint256 x = 0; x < ticketCount_; x++) {
        ticket_ = tickets[_ticketIds[x]];

        if (ticket_.owner == _owner) {
          return ticket_;
        }
      }
    }
  }

  /// @notice gets ticket by id
  /// @param _id ticket id generated while buying
  /// @param _period id
  /// @param _encodedNumbers encoded choisen ticket numbers
  function getTicketById(
    uint256 _id,
    uint256 _period,
    bytes[6] memory _encodedNumbers
  ) public view returns (
    TicketData memory,
    uint32
  ) {
    for (uint8 i = 6; i >= 1; i--) {
      uint256[] memory ticketIds_ = ticketNumberDataPair[_period][_encodedNumbers[i - 1]];

      for (uint256 x = 0; x < ticketIds_.length; x++) {
        if (ticketIds_[x] == _id) {
          return (tickets[ticketIds_[x]], i);
        }
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IVault {
  function getReserve() external view returns (uint256);

  function getWlpValue() external view returns (uint256);

  function getMinPrice(address _token) external view returns (uint256);

  function payout(
    address[2] memory _tokens,
    address _escrowAddress,
    uint256 _escrowAmount,
    address _recipient,
    uint256 _totalAmount
  ) external;

  function payin(address _inputToken, address _escrowAddress, uint256 _escrowAmount) external;

  function deposit(address _token, address _receiver) external returns (uint256);

  function withdraw(address _token, address _receiver) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IFeeCollector {
  function calcFee(uint256 _amount) external view returns (uint256);
  function onIncreaseFee(address _token) external;
  function onVolumeIncrease(uint256 amount) external;
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