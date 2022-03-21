pragma solidity ^0.5.16;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./inheritance/Governable.sol";

import "./interfaces/IController.sol";
import "./interfaces/IStrategy.sol";
import "./interfaces/IVault.sol";

import "./RewardForwarderV1.sol";


contract ControllerV1 is IController, Governable {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // ========================= Fields =========================

    // external parties
    address public targetToken;
    address public profitSharingReceiver;
    address public rewardForwarder;
    address public universalLiquidator;
    address public dolomiteYieldFarmingRouter;

    uint256 public nextImplementationDelay;

    /// 15% of fees captured go to iFARM stakers
    uint256 public profitSharingNumerator = 1500;
    uint256 public nextProfitSharingNumerator = 0;
    uint256 public nextProfitSharingNumeratorTimestamp = 0;

    /// 5% of fees captured go to strategists
    uint256 public strategistFeeNumerator = 500;
    uint256 public nextStrategistFeeNumerator = 0;
    uint256 public nextStrategistFeeNumeratorTimestamp = 0;

    /// 5% of fees captured go to the devs of the platform
    uint256 public platformFeeNumerator = 500;
    uint256 public nextPlatformFeeNumerator = 0;
    uint256 public nextPlatformFeeNumeratorTimestamp = 0;

    /// used for queuing a new delay
    uint256 public tempNextImplementationDelay = 0;
    uint256 public tempNextImplementationDelayTimestamp = 0;

    uint256 public constant FEE_DENOMINATOR = 10000;

    // [Grey list]
    // An EOA can safely interact with the system no matter what.
    // If you're using Metamask, you're using an EOA.
    // Only smart contracts may be affected by this grey list.
    //
    // This contract will not be able to ban any EOA from the system
    // even if an EOA is being added to the greyList, he/she will still be able
    // to interact with the whole system as if nothing happened.
    // Only smart contracts will be affected by being added to the greyList.
    mapping (address => bool) public greyList;

    /// @notice This mapping allows certain contracts to stake on a user's behalf
    mapping (address => bool) public stakingWhiteList;

    // All vaults that we have
    mapping (address => bool) public vaults;

    // All strategies that we have
    mapping (address => bool) public strategies;

    // All eligible hardWorkers that we have
    mapping (address => bool) public hardWorkers;

    // ========================= Modifiers =========================

    modifier validVault(address _vault){
        require(vaults[_vault], "vault does not exist");
        _;
    }

    modifier confirmSharePrice(
        address vault,
        uint256 _hint,
        uint256 _deviationNumerator,
        uint256 _deviationDenominator
    ) {
        uint256 sharePrice = IVault(vault).getPricePerFullShare();
        uint256 resolution = 1e18;
        if (sharePrice > _hint) {
            require(
                sharePrice.mul(resolution).div(_hint) <= _deviationNumerator.mul(resolution).div(_deviationDenominator),
                "share price deviation"
            );
        } else {
            require(
                _hint.mul(resolution).div(sharePrice) <= _deviationNumerator.mul(resolution).div(_deviationDenominator),
                "share price deviation"
            );
        }
        _;
    }

    modifier onlyHardWorkerOrGovernance() {
        require(hardWorkers[msg.sender] || (msg.sender == governance()),
            "only hard worker can call this");
        _;
    }

    constructor(
        address _storage,
        address _targetToken,
        address _profitSharingReceiver,
        address _rewardForwarder,
        address _universalLiquidator,
        uint _nextImplementationDelay
    )
    Governable(_storage)
    public {
        require(_targetToken != address(0), "_targetToken should not be empty");
        require(_profitSharingReceiver != address(0), "_profitSharingReceiver should not be empty");
        require(_rewardForwarder != address(0), "_rewardForwarder should not be empty");
        require(_universalLiquidator != address(0), "_universalLiquidator should not be empty");
        require(_nextImplementationDelay > 0, "_nextImplementationDelay should be gt 0");

        targetToken = _targetToken;
        profitSharingReceiver = _profitSharingReceiver;
        rewardForwarder = _rewardForwarder;
        universalLiquidator = _universalLiquidator;
        nextImplementationDelay = _nextImplementationDelay;
    }

    function hasVault(address _vault) external view returns (bool) {
        return vaults[_vault];
    }

    function hasStrategy(address _strategy) external view returns (bool) {
        return strategies[_strategy];
    }

    // Only smart contracts will be affected by the greyList.
    function addToGreyList(address _target) public onlyGovernance {
        greyList[_target] = true;
    }

    function removeFromGreyList(address _target) public onlyGovernance {
        greyList[_target] = false;
    }

    function addToStakingWhiteList(address _target) public onlyGovernance {
        require(
            !stakingWhiteList[_target],
            "_target cannot already be staking"
        );

        stakingWhiteList[_target] = true;
        emit AddedStakingContract(_target);
    }

    function removeFromStakingWhiteList(address _target) public onlyGovernance {
        require(
            stakingWhiteList[_target],
            "_target must already be staking"
        );

        stakingWhiteList[_target] = false;
        emit RemovedStakingContract(_target);
    }

    function setRewardForwarder(address _rewardForwarder) public onlyGovernance {
        require(_rewardForwarder != address(0), "new reward forwarder should not be empty");
        rewardForwarder = _rewardForwarder;
    }

    function setTargetToken(address _targetToken) public onlyGovernance {
        require(_targetToken != address(0), "new target token should not be empty");
        targetToken = _targetToken;
    }

    function setProfitSharingReceiver(address _profitSharingReceiver) public onlyGovernance {
        require(_profitSharingReceiver != address(0), "new profit sharing receiver should not be empty");
        profitSharingReceiver = _profitSharingReceiver;
    }

    function setUniversalLiquidator(address _universalLiquidator) public onlyGovernance {
        require(_universalLiquidator != address(0), "new universal liquidator should not be empty");
        universalLiquidator = _universalLiquidator;
    }

    function setDolomiteYieldFarmingRouter(address _dolomiteYieldFarmingRouter) public onlyGovernance {
        require(_dolomiteYieldFarmingRouter != address(0), "new reward forwarder should not be empty");
        dolomiteYieldFarmingRouter = _dolomiteYieldFarmingRouter;
    }

    function addVaultAndStrategy(address _vault, address _strategy) external onlyGovernance {
        _addVaultAndStrategy(_vault, _strategy);
    }

    function addVaultsAndStrategies(
        address[] calldata _vaults,
        address[] calldata _strategies
    ) external onlyGovernance {
        require(
            _vaults.length == _strategies.length,
            "invalid vaults/strategies length"
        );
        for (uint i = 0; i < _vaults.length; i++) {
            _addVaultAndStrategy(_vaults[i], _strategies[i]);
        }
    }

    function getPricePerFullShare(address _vault) public view returns (uint256) {
        return IVault(_vault).getPricePerFullShare();
    }

    function doHardWork(
        address _vault,
        uint256 _hint,
        uint256 _deviationNumerator,
        uint256 _deviationDenominator
    )
    external
    validVault(_vault)
    onlyHardWorkerOrGovernance
    confirmSharePrice(_vault, _hint, _deviationNumerator, _deviationDenominator) {
        uint256 oldSharePrice = IVault(_vault).getPricePerFullShare();
        IVault(_vault).doHardWork();
        emit SharePriceChangeLog(
            _vault,
            IVault(_vault).strategy(),
            oldSharePrice,
            IVault(_vault).getPricePerFullShare(),
            block.timestamp
        );
    }

    function addHardWorker(address _worker) public onlyGovernance {
        require(_worker != address(0), "_worker must be defined");
        hardWorkers[_worker] = true;
    }

    function removeHardWorker(address _worker) public onlyGovernance {
        require(_worker != address(0), "_worker must be defined");
        hardWorkers[_worker] = false;
    }

    function withdrawAll(
        address _vault,
        uint256 _hint,
        uint256 _deviationNumerator,
        uint256 _deviationDenominator
    )
    external
    confirmSharePrice(_vault, _hint, _deviationNumerator, _deviationDenominator)
    onlyGovernance
    validVault(_vault) {
        IVault(_vault).withdrawAll();
    }

    function setStrategy(
        address _vault,
        address _strategy,
        uint256 _hint,
        uint256 _deviationNumerator,
        uint256 _deviationDenominator
    )
    external
    confirmSharePrice(_vault, _hint, _deviationNumerator, _deviationDenominator)
    onlyGovernance
    validVault(_vault) {
        IVault(_vault).setStrategy(_strategy);
    }

    // transfers token in the controller contract to the governance
    function salvage(address _token, uint256 _amount) external onlyGovernance {
        IERC20(_token).safeTransfer(governance(), _amount);
    }

    function salvageStrategy(address _strategy, address _token, uint256 _amount) external onlyGovernance {
        // the strategy is responsible for maintaining the list of
        // salvageable tokens, to make sure that governance cannot come
        // in and take away the coins
        IStrategy(_strategy).salvageToken(governance(), _token, _amount);
    }

    function profitSharingDenominator() public view returns (uint) {
        // keep the interface for this function as a `view` for now, in case it changes in the future
        return FEE_DENOMINATOR;
    }

    function strategistFeeDenominator() public view returns (uint) {
        // keep the interface for this function as a `view` for now, in case it changes in the future
        return FEE_DENOMINATOR;
    }

    function platformFeeDenominator() public view returns (uint) {
        // keep the interface for this function as a `view` for now, in case it changes in the future
        return FEE_DENOMINATOR;
    }

    function setProfitSharingNumerator(uint _profitSharingNumerator) public onlyGovernance {
        require(
            _profitSharingNumerator + strategistFeeNumerator + platformFeeNumerator < FEE_DENOMINATOR,
            "invalid profit sharing fee numerator"
        );

        nextProfitSharingNumerator = _profitSharingNumerator;
        nextProfitSharingNumeratorTimestamp = block.timestamp + nextImplementationDelay;
        emit QueueProfitSharingNumeratorChange(nextProfitSharingNumerator, nextProfitSharingNumeratorTimestamp);
    }

    function confirmSetProfitSharingNumerator() public onlyGovernance {
        require(
            nextProfitSharingNumerator != 0
            && nextProfitSharingNumeratorTimestamp != 0
            && block.timestamp >= nextProfitSharingNumeratorTimestamp,
            "invalid timestamp or no new profit sharing numerator confirmed"
        );
        profitSharingNumerator = nextProfitSharingNumerator;
        nextProfitSharingNumerator = 0;
        nextProfitSharingNumeratorTimestamp = 0;
        emit ConfirmProfitSharingNumeratorChange(profitSharingNumerator);
    }

    function setStrategistFeeNumerator(uint _strategistFeeNumerator) public onlyGovernance {
        require(
            _strategistFeeNumerator + platformFeeNumerator + profitSharingNumerator < FEE_DENOMINATOR,
            "invalid strategist fee numerator"
        );

        nextStrategistFeeNumerator = _strategistFeeNumerator;
        nextStrategistFeeNumeratorTimestamp = block.timestamp + nextImplementationDelay;
        emit QueueStrategistFeeNumeratorChange(nextStrategistFeeNumerator, nextStrategistFeeNumeratorTimestamp);
    }

    function confirmSetStrategistFeeNumerator() public onlyGovernance {
        require(
            nextStrategistFeeNumerator != 0
            && nextStrategistFeeNumeratorTimestamp != 0
            && block.timestamp >= nextStrategistFeeNumeratorTimestamp,
            "invalid timestamp or no new strategist fee numerator confirmed"
        );
        strategistFeeNumerator = nextStrategistFeeNumerator;
        nextStrategistFeeNumerator = 0;
        nextStrategistFeeNumeratorTimestamp = 0;
        emit ConfirmStrategistFeeNumeratorChange(strategistFeeNumerator);
    }

    function setPlatformFeeNumerator(uint _platformFeeNumerator) public onlyGovernance {
        require(
            _platformFeeNumerator + strategistFeeNumerator + profitSharingNumerator < FEE_DENOMINATOR,
            "invalid platform fee numerator"
        );

        nextPlatformFeeNumerator = _platformFeeNumerator;
        nextPlatformFeeNumeratorTimestamp = block.timestamp + nextImplementationDelay;
        emit QueuePlatformFeeNumeratorChange(nextPlatformFeeNumerator, nextPlatformFeeNumeratorTimestamp);
    }

    function confirmSetPlatformFeeNumerator() public onlyGovernance {
        require(
            nextPlatformFeeNumerator != 0
            && nextPlatformFeeNumeratorTimestamp != 0
            && block.timestamp >= nextPlatformFeeNumeratorTimestamp,
            "invalid timestamp or no new platform fee numerator confirmed"
        );
        platformFeeNumerator = nextPlatformFeeNumerator;
        nextPlatformFeeNumerator = 0;
        nextPlatformFeeNumeratorTimestamp = 0;
        emit ConfirmPlatformFeeNumeratorChange(platformFeeNumerator);
    }

    function setNextImplementationDelay(uint256 _nextImplementationDelay) public onlyGovernance {
        require(
            _nextImplementationDelay > 0,
            "invalid _nextImplementationDelay"
        );

        tempNextImplementationDelay = _nextImplementationDelay;
        tempNextImplementationDelayTimestamp = block.timestamp + nextImplementationDelay;
        emit QueueNextImplementationDelay(tempNextImplementationDelay, tempNextImplementationDelayTimestamp);
    }

    function confirmNextImplementationDelay() public onlyGovernance {
        require(
            tempNextImplementationDelayTimestamp != 0 && block.timestamp >= tempNextImplementationDelayTimestamp,
            "invalid timestamp or no new implementation delay confirmed"
        );
        nextImplementationDelay = tempNextImplementationDelay;
        tempNextImplementationDelay = 0;
        tempNextImplementationDelayTimestamp = 0;
        emit ConfirmNextImplementationDelay(nextImplementationDelay);
    }

    // ========================= Internal Functions =========================

    function _addVaultAndStrategy(address _vault, address _strategy) internal {
        require(_vault != address(0), "new vault shouldn't be empty");
        require(!vaults[_vault], "vault already exists");
        require(!strategies[_strategy], "strategy already exists");
        require(_strategy != address(0), "new strategy shouldn't be empty");

        vaults[_vault] = true;
        strategies[_strategy] = true;

        // no need to protect against sandwich, because there will be no call to withdrawAll
        // as the vault and strategy is brand new
        IVault(_vault).setStrategy(_strategy);
    }
}

pragma solidity ^0.5.5;

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
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity ^0.5.16;

import "./Storage.sol";


contract Governable {

  Storage public store;

  constructor(address _store) public {
    require(_store != address(0), "new storage shouldn't be empty");
    store = Storage(_store);
  }

  modifier onlyGovernance() {
    require(store.isGovernance(msg.sender), "Not governance");
    _;
  }

  function setStorage(address _store) public onlyGovernance {
    require(_store != address(0), "new storage shouldn't be empty");
    store = Storage(_store);
  }

  function governance() public view returns (address) {
    return store.governance();
  }
}

pragma solidity ^0.5.16;

interface IController {

    // ========================= Events =========================

    event QueueProfitSharingNumeratorChange(uint profitSharingNumerator, uint validAtTimestamp);
    event ConfirmProfitSharingNumeratorChange(uint profitSharingNumerator);

    event QueueStrategistFeeNumeratorChange(uint strategistFeeNumerator, uint validAtTimestamp);
    event ConfirmStrategistFeeNumeratorChange(uint strategistFeeNumerator);

    event QueuePlatformFeeNumeratorChange(uint platformFeeNumerator, uint validAtTimestamp);
    event ConfirmPlatformFeeNumeratorChange(uint platformFeeNumerator);

    event QueueNextImplementationDelay(uint implementationDelay, uint validAtTimestamp);
    event ConfirmNextImplementationDelay(uint implementationDelay);

    event AddedStakingContract(address indexed stakingContract);
    event RemovedStakingContract(address indexed stakingContract);

    event SharePriceChangeLog(
        address indexed vault,
        address indexed strategy,
        uint256 oldSharePrice,
        uint256 newSharePrice,
        uint256 timestamp
    );

    // ==================== Functions ====================

    /**
     * An EOA can safely interact with the system no matter what. If you're using Metamask, you're using an EOA. Only
     * smart contracts may be affected by this grey list. This contract will not be able to ban any EOA from the system
     * even if an EOA is being added to the greyList, he/she will still be able to interact with the whole system as if
     * nothing happened. Only smart contracts will be affected by being added to the greyList. This grey list is only
     * used in VaultV3.sol, see the code there for reference
     */
    function greyList(address _target) external view returns (bool);

    function stakingWhiteList(address _target) external view returns (bool);

    function store() external view returns (address);

    function governance() external view returns (address);

    function hasVault(address _vault) external view returns (bool);

    function hasStrategy(address _strategy) external view returns (bool);

    function addVaultAndStrategy(address _vault, address _strategy) external;

    function addVaultsAndStrategies(address[] calldata _vaults, address[] calldata _strategies) external;

    function doHardWork(
        address _vault,
        uint256 _hint,
        uint256 _deviationNumerator,
        uint256 _deviationDenominator
    ) external;

    function addHardWorker(address _worker) external;

    function removeHardWorker(address _worker) external;

    function salvage(address _token, uint256 amount) external;

    function salvageStrategy(address _strategy, address _token, uint256 amount) external;

    /**
     * @return The targeted profit token to convert all-non-compounding rewards to. Defaults to WETH.
     */
    function targetToken() external view returns (address);

    function setTargetToken(address _targetToken) external;

    function profitSharingReceiver() external view returns (address);

    function setProfitSharingReceiver(address _profitSharingReceiver) external;

    function rewardForwarder() external view returns (address);

    function setRewardForwarder(address _rewardForwarder) external;

    function setUniversalLiquidator(address _universalLiquidator) external;

    function universalLiquidator() external view returns (address);

    function dolomiteYieldFarmingRouter() external view returns (address);

    function setDolomiteYieldFarmingRouter(address _value) external;

    function nextImplementationDelay() external view returns (uint256);

    function profitSharingNumerator() external view returns (uint256);

    function strategistFeeNumerator() external view returns (uint256);

    function platformFeeNumerator() external view returns (uint256);

    function profitSharingDenominator() external view returns (uint256);

    function strategistFeeDenominator() external view returns (uint256);

    function platformFeeDenominator() external view returns (uint256);

    function setProfitSharingNumerator(uint _profitSharingNumerator) external;

    function confirmSetProfitSharingNumerator() external;

    function setStrategistFeeNumerator(uint _strategistFeeNumerator) external;

    function confirmSetStrategistFeeNumerator() external;

    function setPlatformFeeNumerator(uint _platformFeeNumerator) external;

    function confirmSetPlatformFeeNumerator() external;

    function nextProfitSharingNumerator() external view returns (uint256);

    function nextProfitSharingNumeratorTimestamp() external view returns (uint256);

    function nextStrategistFeeNumerator() external view returns (uint256);

    function nextStrategistFeeNumeratorTimestamp() external view returns (uint256);

    function nextPlatformFeeNumerator() external view returns (uint256);

    function nextPlatformFeeNumeratorTimestamp() external view returns (uint256);

    function tempNextImplementationDelay() external view returns (uint256);

    function tempNextImplementationDelayTimestamp() external view returns (uint256);

    function setNextImplementationDelay(uint256 _nextImplementationDelay) external;

    function confirmNextImplementationDelay() external;
}

pragma solidity ^0.5.16;

import "../inheritance/ControllableInit.sol";


contract IStrategy {

    /// @notice declared as public so child contract can call it
    function isUnsalvageableToken(address token) public view returns (bool);

    function salvageToken(address recipient, address token, uint amount) external;

    function governance() external view returns (address);

    function controller() external view returns (address);

    function underlying() external view returns (address);

    function vault() external view returns (address);

    function withdrawAllToVault() external;

    function withdrawToVault(uint256 _amount) external;

    function investedUnderlyingBalance() external view returns (uint256);

    function doHardWork() external;

    function depositArbCheck() external view returns (bool);

    function strategist() external view returns (address);

    /**
     * @return  The value of any accumulated rewards that are under control by the strategy. Each index corresponds with
     *          the tokens in `rewardTokens`. This function is not a `view`, because some protocols, like Curve, need
     *          writeable functions to get the # of claimable reward tokens
     */
    function getRewardPoolValues() external returns (uint256[] memory);
}

pragma solidity ^0.5.16;

interface IVault {

    function initializeVault(
        address _storage,
        address _underlying,
        uint256 _toInvestNumerator,
        uint256 _toInvestDenominator
    ) external;

    function balanceOf(address _holder) external view returns (uint256);

    function underlyingBalanceInVault() external view returns (uint256);

    function underlyingBalanceWithInvestment() external view returns (uint256);

    function governance() external view returns (address);

    function controller() external view returns (address);

    function underlying() external view returns (address);

    function underlyingUnit() external view returns (uint);

    function strategy() external view returns (address);

    function setStrategy(address _strategy) external;

    function announceStrategyUpdate(address _strategy) external;

    function setVaultFractionToInvest(uint256 _numerator, uint256 _denominator) external;

    function deposit(uint256 _amount) external;

    function depositFor(uint256 _amount, address _holder) external;

    function withdrawAll() external;

    function withdraw(uint256 _numberOfShares) external;

    function getPricePerFullShare() external view returns (uint256);

    function underlyingBalanceWithInvestmentForHolder(address _holder) view external returns (uint256);

    /**
     * This should be callable only by the controller (by the hard worker) or by governance
     */
    function doHardWork() external;
}

pragma solidity ^0.5.16;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./inheritance/Governable.sol";
import "./interfaces/IRewardForwarder.sol";
import "./interfaces/IProfitSharingReceiver.sol";
import "./interfaces/IStrategy.sol";
import "./interfaces/IUniversalLiquidator.sol";
import "./interfaces/uniswap/IUniswapV2Router02.sol";
import "./inheritance/Controllable.sol";
import "./inheritance/Constants.sol";


/**
 * @dev This contract receives rewards from strategies and is responsible for routing the reward's liquidation into
 *      specific buyback tokens and profit tokens for the DAO.
 */
contract RewardForwarderV1 is IRewardForwarder, Controllable, Constants {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    constructor(
        address _storage
    ) public Controllable(_storage) {}

    function notifyFeeAndBuybackAmounts(
        address _token,
        uint256 _profitSharingFee,
        uint256 _strategistFee,
        uint256 _platformFee,
        address[] calldata _buybackTokens,
        uint256[] calldata _buybackAmounts
    ) external returns (uint[] memory) {
        return _notifyFeeAndBuybackAmounts(
            _token,
            _profitSharingFee,
            _strategistFee,
            _platformFee,
            _buybackTokens,
            _buybackAmounts
        );
    }

    function notifyFee(
        address _token,
        uint256 _profitSharingFee,
        uint256 _strategistFee,
        uint256 _platformFee
    ) external {
        _notifyFeeAndBuybackAmounts(
            _token,
            _profitSharingFee,
            _strategistFee,
            _platformFee,
            new address[](0),
            new uint256[](0)
        );
    }

    function _notifyFeeAndBuybackAmounts(
        address _token,
        uint256 _profitSharingFee,
        uint256 _strategistFee,
        uint256 _platformFee,
        address[] memory _buybackTokens,
        uint256[] memory _buybackAmounts
    ) internal returns (uint[] memory) {
        address _controller = controller();
        require(
            IController(_controller).hasStrategy(msg.sender),
            "msg.sender must be a strategy"
        );

        address liquidator = IController(_controller).universalLiquidator();
        {
            uint totalTransferAmount = _profitSharingFee.add(_strategistFee).add(_platformFee);
            for (uint i = 0; i < _buybackAmounts.length; i++) {
                totalTransferAmount = totalTransferAmount.add(_buybackAmounts[i]);
            }
            require(totalTransferAmount > 0, "totalTransferAmount should not be 0");
            IERC20(_token).safeTransferFrom(msg.sender, address(this), totalTransferAmount);

            IERC20(_token).safeApprove(liquidator, 0);
            IERC20(_token).safeApprove(liquidator, totalTransferAmount);
        }

        address _targetToken = IController(_controller).targetToken();
        uint amountOutMin = 1;

        if (_strategistFee > 0) {
            IUniversalLiquidator(liquidator).swapTokens(
                _token,
                _targetToken,
                _strategistFee,
                amountOutMin,
                IStrategy(msg.sender).strategist()
            );
        }
        if (_platformFee > 0) {
            IUniversalLiquidator(liquidator).swapTokens(
                _token,
                _targetToken,
                _platformFee,
                amountOutMin,
                IController(_controller).governance()
            );
        }
        if (_profitSharingFee > 0) {
            IUniversalLiquidator(liquidator).swapTokens(
                _token,
                _targetToken,
                _profitSharingFee,
                amountOutMin,
                IController(_controller).profitSharingReceiver()
            );
        }

        uint[] memory amounts = new uint[](_buybackTokens.length);
        for (uint i = 0; i < amounts.length; ++i) {
            if (_buybackAmounts[i] > 0) {
                amounts[i] = IUniversalLiquidator(liquidator).swapTokens(
                    _token,
                    _buybackTokens[i],
                    _buybackAmounts[i],
                    amountOutMin,
                    msg.sender
                );
            }
        }

        return amounts;
    }
}

pragma solidity ^0.5.16;

import "../interfaces/IController.sol";


contract Storage {

  event GovernanceChanged(address newGovernance);
  event GovernanceQueued(address newGovernance, uint implementationTimestamp);
  event ControllerChanged(address newController);
  event ControllerQueued(address newController, uint implementationTimestamp);

  address public governance;
  address public controller;

  address public nextGovernance;
  uint256 public nextGovernanceTimestamp;

  address public nextController;
  uint256 public nextControllerTimestamp;

  modifier onlyGovernance() {
    require(isGovernance(msg.sender), "Not governance");
    _;
  }

  constructor () public {
    governance = msg.sender;
    emit GovernanceChanged(msg.sender);
  }

  function setInitialController(address _controller) public onlyGovernance {
    require(
      controller == address(0),
      "controller already set"
    );
    require(
      IController(_controller).nextImplementationDelay() >= 0,
      "new controller doesn't get delay properly"
    );

    controller = _controller;
    emit ControllerChanged(_controller);
  }

  function nextImplementationDelay() public view returns (uint) {
    return IController(controller).nextImplementationDelay();
  }

  function setGovernance(address _governance) public onlyGovernance {
    require(_governance != address(0), "new governance shouldn't be empty");
    nextGovernance = _governance;
    nextGovernanceTimestamp = block.timestamp + nextImplementationDelay();
    emit GovernanceQueued(nextGovernance, nextGovernanceTimestamp);
  }

  function confirmGovernance() public onlyGovernance {
    require(
      nextGovernance != address(0) && nextGovernanceTimestamp != 0,
      "no governance queued"
    );
    require(
      block.timestamp >= nextGovernanceTimestamp,
      "governance not yet ready"
    );
    governance = nextGovernance;
    emit GovernanceChanged(governance);

    nextGovernance = address(0);
    nextGovernanceTimestamp = 0;
  }

  function setController(address _controller) public onlyGovernance {
    require(_controller != address(0), "new controller shouldn't be empty");
    require(IController(_controller).nextImplementationDelay() >= 0, "new controller doesn't get delay properly");

    nextController = _controller;
    nextControllerTimestamp = block.timestamp + nextImplementationDelay();
    emit ControllerQueued(nextController, nextControllerTimestamp);
  }

  function confirmController() public onlyGovernance {
    require(
      nextController != address(0) && nextControllerTimestamp != 0,
      "no controller queued"
    );
    require(
      block.timestamp >= nextControllerTimestamp,
      "controller not yet ready"
    );
    controller = nextController;
    emit ControllerChanged(controller);

    nextController = address(0);
    nextControllerTimestamp = 0;
  }

  function isGovernance(address account) public view returns (bool) {
    return account == governance;
  }

  function isController(address account) public view returns (bool) {
    return account == controller;
  }
}

pragma solidity ^0.5.16;

import "./GovernableInit.sol";


/**
 * A clone of Governable supporting the Initializable interface and pattern
 */
contract ControllableInit is GovernableInit {

    constructor() public {
    }

    function initialize(address _storage) public initializer {
        GovernableInit.initialize(_storage);
    }

    modifier onlyController() {
        require(Storage(_storage()).isController(msg.sender), "Not a controller");
        _;
    }

    modifier onlyControllerOrGovernance(){
        require(
          Storage(_storage()).isController(msg.sender) || Storage(_storage()).isGovernance(msg.sender),
          "The caller must be controller or governance"
        );
        _;
    }

    function controller() public view returns (address) {
        return Storage(_storage()).controller();
    }
}

pragma solidity ^0.5.16;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "../upgradability/UpgradeableReentrancyGuard.sol";
import "./Storage.sol";


/**
 * A clone of Governable supporting the Initializable interface and pattern
 */
contract GovernableInit is UpgradeableReentrancyGuard {

  bytes32 internal constant _STORAGE_SLOT = 0xa7ec62784904ff31cbcc32d09932a58e7f1e4476e1d041995b37c917990b16dc;

  modifier onlyGovernance() {
    require(Storage(_storage()).isGovernance(msg.sender), "Not governance");
    _;
  }

  constructor() public {
    assert(_STORAGE_SLOT == bytes32(uint256(keccak256("eip1967.governableInit.storage")) - 1));
  }

  function initialize(address _store) public initializer {
    UpgradeableReentrancyGuard.initialize();
    _setStorage(_store);
  }

  function _setStorage(address newStorage) private {
    bytes32 slot = _STORAGE_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, newStorage)
    }
  }

  function setStorage(address _store) public onlyGovernance {
    require(_store != address(0), "new storage shouldn't be empty");
    _setStorage(_store);
  }

  function _storage() internal view returns (address str) {
    bytes32 slot = _STORAGE_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  function governance() public view returns (address) {
    return Storage(_storage()).governance();
  }
}

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

pragma solidity >=0.5.4;

import "@openzeppelin/upgrades/contracts/Initializable.sol";


/**
 * Same old `ReentrancyGuard`, but can be used by upgradable contracts
 */
contract UpgradeableReentrancyGuard is Initializable {

    bytes32 internal constant _NOT_ENTERED_SLOT = 0x62ae7bf2df4e95c187ea09c8c47c3fc3d9abc36298f5b5b6c5e2e7b4b291fe25;

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_getNotEntered(_NOT_ENTERED_SLOT), "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _setNotEntered(_NOT_ENTERED_SLOT, false);

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _setNotEntered(_NOT_ENTERED_SLOT, true);
    }

    constructor() public {
        assert(_NOT_ENTERED_SLOT == bytes32(uint256(keccak256("eip1967.reentrancyGuard.notEntered")) - 1));
    }

    function initialize() public initializer {
        _setNotEntered(_NOT_ENTERED_SLOT, true);
    }

    function _getNotEntered(bytes32 slot) private view returns (bool) {
        uint str;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            str := sload(slot)
        }
        return str == 1;
    }

    function _setNotEntered(bytes32 slot, bool _value) private {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _value)
        }
    }

}

pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev See {ERC20-_burnFrom}.
     */
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }
}

pragma solidity ^0.5.16;


/**
 * @dev A routing contract that is responsible for taking the harvested gains and routing them into FARM and additional
 *      buyback tokens for the corresponding strategy
 */
interface IRewardForwarder {

    function store() external view returns (address);

    function governance() external view returns (address);

    /**
     * @dev This function sends converted `_buybackTokens` to `msg.sender`. The returned amounts will match the
     *      `amounts` return value. The fee amounts are converted to the profit sharing token and sent to the proper
     *      addresses (profit sharing, strategist, and governance (platform)).
     *
     * @param _token            the token that will be compounded or sold into the profit sharing token for the Harvest
     *                          collective (users that stake iFARM)
     * @param _profitSharingFee the amount of `_token` that will be sold into the profit sharing token
     * @param _strategistFee    the amount of `_token` that will be sold into the profit sharing token for the
     *                          strategist
     * @param _platformFee      the amount of `_token` that will be sold into the profit sharing token for the Harvest
     *                          treasury
     * @param _buybackTokens    the output tokens that `_buyBackAmounts` should be swapped to (outputToken)
     * @param _buybackAmounts   the amounts of `_token` that will be bought into more `_buybackTokens` token
     * @return The amounts that were purchased of _buybackTokens
     */
    function notifyFeeAndBuybackAmounts(
        address _token,
        uint256 _profitSharingFee,
        uint256 _strategistFee,
        uint256 _platformFee,
        address[] calldata _buybackTokens,
        uint256[] calldata _buybackAmounts
    ) external returns (uint[] memory amounts);

    /**
     * @dev This function converts the fee amounts to the profit sharing token and sends them to the proper addresses
     *      (profit sharing, strategist, and governance (platform)).
     *
     * @param _token            the token that will be compounded or sold into the profit sharing token for the Harvest
     *                          collective (users that stake iFARM)
     * @param _profitSharingFee the amount of `_token` that will be sold into the profit sharing token
     * @param _strategistFee    the amount of `_token` that will be sold into the profit sharing token for the
     *                          strategist
     * @param _platformFee      the amount of `_token` that will be sold into the profit sharing token for the Harvest
     *                          treasury
     * @return The amounts that were purchased of _buybackTokens
     */
    function notifyFee(
        address _token,
        uint256 _profitSharingFee,
        uint256 _strategistFee,
        uint256 _platformFee
    ) external;
}

pragma solidity ^0.5.16;


interface IProfitSharingReceiver {

    function governance() external view returns (address);

    function withdrawTokens(address[] calldata _tokens) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;


/**
 * @dev A contract that handles all liquidations from an `inputToken` to an `outputToken`. This contract simplifies
 *      all swap logic so strategies can be focused on management of funds and forwarding gains to this contract
 *      for the most efficient liquidation. If the liquidation path of an asset changes, governance needs only to
 *      create a new instance of this contract or modify the liquidation path via `configureSwap`, and all callers of
 *      the contract benefit from the change and uniformity.
 */
interface IUniversalLiquidator {

    // ==================== Events ====================

    event Swap(
        address indexed buyToken,
        address indexed sellToken,
        address indexed recipient,
        address initiator,
        uint256 amountIn,
        uint256 slippage,
        uint256 total
    );

    // ==================== Functions ====================

    function governance() external view returns (address);

    function controller() external view returns (address);

    function nextImplementation() external view returns (address);

    function scheduleUpgrade(address _nextImplementation) external;

    /**
     * Constructor replacement because this contract is meant to be upgradable
     */
    function initializeUniversalLiquidator(
        address _storage
    ) external;

    /**
     * @param _path     The path that is used for selling token at path[0] into path[path.length - 1].
     * @param _router   The router to use for this path.
     */
    function configureSwap(
        address[] calldata _path,
        address _router
    ) external;

    /**
     * @param _paths    The paths that are used for selling token at path[i][0] into path[i][path[i].length - 1].
     * @param _routers  The routers to use for each index, `i`.
     */
    function configureSwaps(
        address[][] calldata _paths,
        address[] calldata _routers
    ) external;

    /**
     * @return The router used to execute the swap from `_inputToken` to `_outputToken`
     */
    function getSwapRouter(
        address _inputToken,
        address _outputToken
    ) external view returns (address);

    function swapTokens(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _recipient
    ) external returns (uint _amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;


interface IUniswapV2Router02 {

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint[] memory amounts);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity ^0.5.16;

import "./Governable.sol";


contract Controllable is Governable {

  constructor(address _storage) Governable(_storage) public {
  }

  modifier onlyController() {
    require(store.isController(msg.sender), "Not a controller");
    _;
  }

  modifier onlyControllerOrGovernance(){
    require((store.isController(msg.sender) || store.isGovernance(msg.sender)),
      "The caller must be controller or governance");
    _;
  }

  function controller() public view returns (address) {
    return store.controller();
  }
}

pragma solidity ^0.5.16;


contract Constants {

    address constant public CRV = 0x11cDb42B0EB46D95f990BeDD4695A6e3fA034978;

    address constant public CRV_TRI_CRYPTO = 0x8e0B8c8BB9db49a46697F3a5Bb8A308e744821D2;

    address constant public CRV_TRI_CRYPTO_GAUGE = 0x97E2768e8E73511cA874545DC5Ff8067eB19B787;

    address constant public CRV_TRI_CRYPTO_POOL = 0x960ea3e3C7FB317332d990873d354E18d7645590;

    address constant public DAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;

    /// @notice Used as governance
    address constant public DEFAULT_MULTI_SIG_ADDRESS = 0xb39710a1309847363b9cBE5085E427cc2cAeE563;

    // We can set this later once we know the address
//    address constant public FARM = 0x0000000000000000000000000000000000000000;

    address constant public LINK = 0xf97f4df75117a78c1A5a0DBb814Af92458539FB4;

    address constant public ONE_INCH = 0x0000000000000000000000000000000000000000;

    address constant public ONE_INCH_CALLER = 0x0000000000000000000000000000000000000000;

    address constant public SUSHI = 0xd4d42F0b6DEF4CE0383636770eF773390d85c61A;

    address constant public SUSHI_ROUTER = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;

    address constant public UNI = 0xFa7F8980b0f1E64A2062791cc3b0871572f1F7f0;

    address constant public UNISWAP_V3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    address constant public USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;

    address constant public USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;

    address constant public WBTC = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;

    address constant public WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
}

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}