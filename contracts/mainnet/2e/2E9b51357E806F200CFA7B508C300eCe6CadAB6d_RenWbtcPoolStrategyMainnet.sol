pragma solidity ^0.5.16;

import "../../base/interfaces/IMainnetStrategy.sol";
import "./TwoPoolStrategy.sol";


contract RenWbtcPoolStrategyMainnet is TwoPoolStrategy, IMainnetStrategy {

    function initializeMainnetStrategy(
        address _storage,
        address _vault,
        address _strategist
    ) external initializer {
        address[] memory rewardTokens = new address[](1);
        rewardTokens[0] = CRV;
        CurveStrategy.initializeCurveStrategy(
            _storage,
            CRV_REN_WBTC_POOL,
            _vault,
            CRV_REN_WBTC_GAUGE,
            rewardTokens,
            _strategist,
            CRV_REN_WBTC_POOL,
            WBTC,
            /* depositArrayPosition = */ 0
        );
    }

}

pragma solidity ^0.5.16;


interface IMainnetStrategy {

    function initializeMainnetStrategy(
        address _storage,
        address _vault,
        address _strategist
    ) external;
}

pragma solidity ^0.5.16;

import "./interfaces/ITwoPool.sol";
import "./CurveStrategy.sol";


/**
 * @dev A strategy for farming CRV from [2Pool](https://arbitrum.curve.fi/2pool)
 */
contract TwoPoolStrategy is CurveStrategy {

    // ========================= Internal Functions =========================

    function _mintLiquidityTokens() internal {
        address _depositToken = depositToken();
        uint256 tokenBalance = IERC20(_depositToken).balanceOf(address(this));
        IERC20(_depositToken).safeApprove(curveDepositPool(), 0);
        IERC20(_depositToken).safeApprove(curveDepositPool(), tokenBalance);

        uint256[2] memory depositArray;
        depositArray[depositArrayPosition()] = tokenBalance;

        // we can accept 0 as minimum, this will be called only by trusted roles
        uint256 minimum = 0;
        ITwoPool(curveDepositPool()).add_liquidity(depositArray, minimum);
    }
}

pragma solidity ^0.5.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract ITwoPool is IERC20 {

    function add_liquidity(uint[2] calldata amounts, uint min_mint_amount) external;

    function coins(uint i) external view returns (address);
}

pragma solidity ^0.5.16;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "../../base/interfaces/IStrategy.sol";
import "../../base/interfaces/curve/IGauge.sol";
import "../../base/upgradability/BaseUpgradeableStrategy.sol";

import "./interfaces/ICurvePool.sol";
import "./interfaces/ITriCryptoPool.sol";


contract CurveStrategy is IStrategy, BaseUpgradeableStrategy {
    using SafeMath for uint256;

    // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
    bytes32 internal constant _DEPOSIT_TOKEN_SLOT = 0x219270253dbc530471c88a9e7c321b36afda219583431e7b6c386d2d46e70c86;
    bytes32 internal constant _DEPOSIT_ARRAY_POSITION_SLOT = 0xb7c50ef998211fff3420379d0bf5b8dfb0cee909d1b7d9e517f311c104675b09;
    bytes32 internal constant _CRV_DEPOSIT_POOL_SLOT = 0xa8dfe2f08f0de0508bc25f877914a259758f1ca3752cae910ab0fd5bf4a2f1a1;

    constructor() public BaseUpgradeableStrategy() {
        assert(_DEPOSIT_TOKEN_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.depositToken")) - 1));
        assert(_DEPOSIT_ARRAY_POSITION_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.depositArrayPosition")) - 1));
        assert(_CRV_DEPOSIT_POOL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.crvDepositPool")) - 1));
    }

    function initializeCurveStrategy(
        address _storage,
        address _underlying,
        address _vault,
        address _rewardPool,
        address[] memory _rewardTokens,
        address _strategist,
        address _crvDepositPool,
        address _crvDepositToken,
        uint256 _depositArrayPosition
    ) public initializer {
        BaseUpgradeableStrategy.initialize(
            _storage,
            _underlying,
            _vault,
            _rewardPool,
            _rewardTokens,
            _strategist
        );

        require(
            IGauge(rewardPool()).lp_token() == underlying(),
            "pool lpToken does not match underlying"
        );
        require(
            ICurvePool(_crvDepositPool).coins(_depositArrayPosition) == _crvDepositToken,
            "pool deposit token does not match _crvDepositToken"
        );

        _setCurveDepositPool(_crvDepositPool);
        _setDepositToken(_crvDepositToken);
        _setDepositArrayPosition(_depositArrayPosition);
    }

    function depositArbCheck() external view returns(bool) {
        return true;
    }

    function depositToken() public view returns (address) {
        return getAddress(_DEPOSIT_TOKEN_SLOT);
    }

    function curveDepositPool() public view returns (address) {
        return getAddress(_CRV_DEPOSIT_POOL_SLOT);
    }

    function depositArrayPosition() public view returns (uint256) {
        return getUint256(_DEPOSIT_ARRAY_POSITION_SLOT);
    }

    function getRewardPoolValues() public returns (uint256[] memory values) {
        values = new uint256[](1);
        values[0] = IGauge(rewardPool()).claimable_reward_write(address(this), rewardTokens()[0]);
    }

    // ========================= Internal Functions =========================

    function _setDepositToken(address _address) internal {
        setAddress(_DEPOSIT_TOKEN_SLOT, _address);
    }

    function _setDepositArrayPosition(uint256 _value) internal {
        setUint256(_DEPOSIT_ARRAY_POSITION_SLOT, _value);
    }

    function _setCurveDepositPool(address _address) internal {
        setAddress(_CRV_DEPOSIT_POOL_SLOT, _address);
    }

    function _finalizeUpgrade() internal {}

    function _rewardPoolBalance() internal view returns (uint256) {
        return IGauge(rewardPool()).balanceOf(address(this));
    }

    function _partialExitRewardPool(uint256 _amount) internal {
        if (_amount > 0) {
            IGauge(rewardPool()).withdraw(_amount);
        }
    }

    function _enterRewardPool() internal {
        uint256 entireBalance = IERC20(underlying()).balanceOf(address(this));
        IERC20(underlying()).safeApprove(rewardPool(), 0);
        IERC20(underlying()).safeApprove(rewardPool(), entireBalance);
        IGauge(rewardPool()).deposit(entireBalance); // deposit and stake
    }

    function _claimRewards() internal {
        IGauge(rewardPool()).claim_rewards();
    }

    function _liquidateReward() internal {
        address[] memory _rewardTokens = rewardTokens();
        for (uint i = 0; i < _rewardTokens.length; i++) {
            uint256 rewardBalance = IERC20(_rewardTokens[i]).balanceOf(address(this));
            address[] memory buybackTokens = new address[](1);
            buybackTokens[0] = depositToken();

            _notifyProfitAndBuybackInRewardToken(_rewardTokens[i], rewardBalance, buybackTokens);

            uint256 tokenBalance = IERC20(depositToken()).balanceOf(address(this));
            if (tokenBalance > 0) {
                _mintLiquidityTokens();
                _enterRewardPool();
            }
        }
    }

    function _mintLiquidityTokens() internal {
        address _depositToken = depositToken();
        uint256 tokenBalance = IERC20(_depositToken).balanceOf(address(this));
        IERC20(_depositToken).safeApprove(curveDepositPool(), 0);
        IERC20(_depositToken).safeApprove(curveDepositPool(), tokenBalance);

        uint256[3] memory depositArray;
        depositArray[depositArrayPosition()] = tokenBalance;

        // we can accept 0 as minimum, this will be called only by trusted roles
        uint256 minimum = 0;
        ITriCryptoPool(curveDepositPool()).add_liquidity(depositArray, minimum);
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

pragma solidity ^0.5.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
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

/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
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


interface IGauge {

    function lp_token() external view returns (address);

    function balanceOf(address user) external view returns (uint);

    function claimable_reward(address user, address token) external view returns (uint);

    function claimable_reward_write(address _addr, address _token) external returns (uint256);

    function deposit(uint value) external;

    function withdraw(uint value) external;

    function claim_rewards() external;
}

pragma solidity ^0.5.16;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "../inheritance/Constants.sol";
import "../inheritance/ControllableInit.sol";
import "../interfaces/IController.sol";
import "../interfaces/IVault.sol";
import "./BaseUpgradeableStrategyStorage.sol";
import "../interfaces/IStrategy.sol";


contract BaseUpgradeableStrategy is
    IStrategy,
    Initializable,
    ControllableInit,
    BaseUpgradeableStrategyStorage,
    Constants
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // ==================== Modifiers ====================

    modifier restricted() {
        require(msg.sender == vault() || msg.sender == controller() || msg.sender == governance(),
            "The sender has to be the controller, governance, or vault");
        _;
    }

    /**
     * @dev This is only used in `investAllUnderlying()`. The user can still freely withdraw from the strategy
     */
    modifier onlyNotPausedInvesting() {
        require(!pausedInvesting(), "Action blocked as the strategy is in emergency state");
        _;
    }

    constructor() public BaseUpgradeableStrategyStorage() {
    }

    // ==================== Functions ====================

    function initialize(
        address _storage,
        address _underlying,
        address _vault,
        address _rewardPool,
        address[] memory _rewardTokens,
        address _strategist
    ) public initializer {
        require(
            IVault(_vault).underlying() == _underlying,
            "underlying does not match vault underlying"
        );

        ControllableInit.initialize(_storage);
        _setUnderlying(_underlying);
        _setVault(_vault);
        _setRewardPool(_rewardPool);
        _setRewardTokens(_rewardTokens);
        _setStrategist(_strategist);
        _setSell(true);
        _setSellFloor(0);
        _setPausedInvesting(false);
    }

    /**
    * Schedules an upgrade for this vault's proxy.
    */
    function scheduleUpgrade(address _nextImplementation) public onlyGovernance {
        uint nextImplementationTimestamp = block.timestamp.add(nextImplementationDelay());
        _setNextImplementation(_nextImplementation);
        _setNextImplementationTimestamp(nextImplementationTimestamp);
        emit UpgradeScheduled(_nextImplementation, nextImplementationTimestamp);
    }

    function shouldUpgrade() public view returns (bool, address) {
        return (
            nextImplementationTimestamp() != 0
            && block.timestamp > nextImplementationTimestamp()
            && nextImplementation() != address(0),
            nextImplementation()
        );
    }

    /**
     * Governance or Controller can claim coins that are somehow transferred into the contract. Note that they cannot
     * come in take away coins that are used and defined in the strategy itself. Those are protected by the
     * `isUnsalvageableToken` function. To check, see where those are being flagged.
     */
    function salvageToken(
        address _recipient,
        address _token,
        uint256 _amount
    )
    public
    onlyControllerOrGovernance
    nonReentrant {
        // To make sure that governance cannot come in and take away the coins
        require(!isUnsalvageableToken(_token), "The token must be salvageable");
        IERC20(_token).safeTransfer(_recipient, _amount);
    }

    function isUnsalvageableToken(address _token) public view returns (bool) {
        return (isRewardToken(_token) || _token == underlying());
    }

    function setStrategist(address _strategist) external {
        require(msg.sender == strategist(), "Sender must be strategist");
        require(_strategist != address(0) && _strategist != address(this), "Invalid strategist");
        _setStrategist(_strategist);
    }

    function setSell(bool _isSellAllowed) public onlyGovernance {
        _setSell(_isSellAllowed);
    }

    function setSellFloor(uint256 _sellFloor) public onlyGovernance {
        _setSellFloor(_sellFloor);
    }

    /**
     *  In case there are some issues discovered about the pool or underlying asset, Governance can exit the pool
     * quickly.
     */
    function emergencyExit() external onlyGovernance nonReentrant {
        _partialExitRewardPool(_rewardPoolBalance());
        IERC20(underlying()).safeTransfer(governance(), IERC20(underlying()).balanceOf(address(this)));
        _setPausedInvesting(true);
    }

    /**
     *   Resumes the ability to invest into the underlying reward pools
     */
    function continueInvesting() external onlyGovernance {
        _setPausedInvesting(false);
    }

    /**
     * @notice We currently do not have a mechanism here to include the amount of reward that is accrued.
     */
    function investedUnderlyingBalance() external view returns (uint256) {
        return _rewardPoolBalance().add(IERC20(underlying()).balanceOf(address(this)));
    }

    /**
     * It's not much, but it's honest work.
     */
    function doHardWork() external onlyNotPausedInvesting restricted nonReentrant {
        _claimRewards();
        _liquidateReward();
        _enterRewardPool();
    }

    function enterRewardPool() external onlyNotPausedInvesting restricted nonReentrant {
        _enterRewardPool();
    }

    /**
     * Withdraws all of the assets to the vault
     */
    function withdrawAllToVault() external restricted nonReentrant {
        if (address(rewardPool()) != address(0)) {
            _partialExitRewardPool(_rewardPoolBalance());
        }
        _liquidateReward();
        IERC20(underlying()).safeTransfer(vault(), IERC20(underlying()).balanceOf(address(this)));
    }

    /**
     * Withdraws `amount` of assets to the vault
     */
    function withdrawToVault(uint256 amount) external restricted nonReentrant {
        // Typically there wouldn't be any amount here
        // however, it is possible because of the emergencyExit
        uint256 entireBalance = IERC20(underlying()).balanceOf(address(this));

        if (amount > entireBalance) {
            // While we have the check above, we still using SafeMath below for the peace of mind (in case something
            // gets changed in between)
            uint256 needToWithdraw = amount.sub(entireBalance);
            uint256 toWithdraw = Math.min(_rewardPoolBalance(), needToWithdraw);
            _partialExitRewardPool(toWithdraw);
        }
        IERC20(underlying()).safeTransfer(vault(), amount);
    }

    function finalizeUpgrade() external onlyGovernance nonReentrant {
        _finalizeUpgradePrivate();
        _finalizeUpgrade();
    }

    // ========================= Internal & Private Functions =========================

    // ==================== Functionality ====================

    /**
     * Same as `_notifyProfitAndBuybackInRewardToken` but does not perform a compounding buyback. Just takes fees
     * instead.
     */
    function _notifyProfitInRewardToken(
        address _rewardToken,
        uint256 _rewardBalance
    ) internal {
        uint denominator = profitSharingNumerator().add(strategistFeeNumerator()).add(platformFeeNumerator());
        if (_rewardBalance > 0 && denominator > 0) {
            require(
                profitSharingDenominator() == strategistFeeDenominator(),
                "profit sharing denominator must match strategist fee denominator"
            );
            require(
                strategistFeeDenominator() == platformFeeDenominator(),
                "strategist fee denominator must match platform fee denominator"
            );

            uint256 strategistFee = _rewardBalance.mul(strategistFeeNumerator()).div(denominator);
            uint256 platformFee = _rewardBalance.mul(platformFeeNumerator()).div(denominator);
            // profitSharingFee gets what's left, so there's no dust left in the contract from truncation
            uint256 profitSharingFee = _rewardBalance.sub(strategistFee).sub(platformFee);

            address strategyFeeRecipient = strategist();
            address platformFeeRecipient = IController(controller()).governance();

            emit ProfitLogInReward(
                _rewardToken,
                _rewardBalance,
                profitSharingFee,
                block.timestamp
            );
            emit PlatformFeeLogInReward(
                platformFeeRecipient,
                _rewardToken,
                _rewardBalance,
                platformFee,
                block.timestamp
            );
            emit StrategistFeeLogInReward(
                strategyFeeRecipient,
                _rewardToken,
                _rewardBalance,
                strategistFee,
                block.timestamp
            );

            address rewardForwarder = IController(controller()).rewardForwarder();
            IERC20(_rewardToken).safeApprove(rewardForwarder, 0);
            IERC20(_rewardToken).safeApprove(rewardForwarder, _rewardBalance);

            // Distribute/send the fees
            IRewardForwarder(rewardForwarder).notifyFee(
                _rewardToken,
                profitSharingFee,
                strategistFee,
                platformFee
            );
        } else {
            emit ProfitLogInReward(_rewardToken, 0, 0, block.timestamp);
            emit PlatformFeeLogInReward(IController(controller()).governance(), _rewardToken, 0, 0, block.timestamp);
            emit StrategistFeeLogInReward(strategist(), _rewardToken, 0, 0, block.timestamp);
        }
    }

    /**
     * @return the amounts bought back of each buybackToken
     */
    function _notifyProfitAndBuybackInRewardToken(
        address _rewardToken,
        uint256 _rewardBalance,
        address[] memory _buybackTokens
    ) internal returns (uint[] memory) {
        uint[] memory weights = new uint[](_buybackTokens.length);
        for (uint i = 0; i < _buybackTokens.length; i++) {
            weights[i] = 1;
        }

        return _notifyProfitAndBuybackInRewardTokenWithWeights(_rewardToken, _rewardBalance, _buybackTokens, weights);
    }

    /**
     * @param _rewardToken      The reward token to be sold for FARM and _buybackTokens
     * @param _rewardBalance    The amount of `_rewardToken` to be sold for FARM and _buybackTokens
     * @param _buybackTokens    The tokens to be bought for reinvestment
     * @param _weights          the weights to be applied for each buybackToken. For example [100, 300] applies 25% to
     *                          buybackTokens[0] and 75% to buybackTokens[1]
     */
    function _notifyProfitAndBuybackInRewardTokenWithWeights(
        address _rewardToken,
        uint256 _rewardBalance,
        address[] memory _buybackTokens,
        uint[] memory _weights
    ) internal returns (uint[] memory) {
        address governance = IController(controller()).governance();

        if (_rewardBalance > 0 && _buybackTokens.length > 0) {
            uint256 profitSharingFee = _rewardBalance.mul(profitSharingNumerator()).div(profitSharingDenominator());
            uint256 strategistFee = _rewardBalance.mul(strategistFeeNumerator()).div(strategistFeeDenominator());
            uint256 platformFee = _rewardBalance.mul(platformFeeNumerator()).div(platformFeeDenominator());
            // buybackAmount is set to what's left, which results in leaving no dust in this contract
            uint256 buybackAmount = _rewardBalance.sub(profitSharingFee).sub(strategistFee).sub(platformFee);

            uint[] memory buybackAmounts = new uint[](_buybackTokens.length);
            {
                uint totalWeight = 0;
                for (uint i = 0; i < _weights.length; i++) {
                    totalWeight += _weights[i];
                }
                require(
                    totalWeight > 0,
                    "totalWeight must be greater than zero"
                );
                for (uint i = 0; i < buybackAmounts.length; i++) {
                    buybackAmounts[i] = buybackAmount.mul(_weights[i]).div(totalWeight);
                }
            }

            emit ProfitAndBuybackLog(
                _rewardToken,
                _rewardBalance,
                profitSharingFee,
                block.timestamp
            );
            emit PlatformFeeLogInReward(
                governance,
                _rewardToken,
                _rewardBalance,
                platformFee,
                block.timestamp
            );
            emit StrategistFeeLogInReward(
                strategist(),
                _rewardToken,
                _rewardBalance,
                strategistFee,
                block.timestamp
            );

            address rewardForwarder = IController(controller()).rewardForwarder();
            IERC20(_rewardToken).safeApprove(rewardForwarder, 0);
            IERC20(_rewardToken).safeApprove(rewardForwarder, _rewardBalance);

            // Send and distribute the fees
            return IRewardForwarder(rewardForwarder).notifyFeeAndBuybackAmounts(
                _rewardToken,
                profitSharingFee,
                strategistFee,
                platformFee,
                _buybackTokens,
                buybackAmounts
            );
        } else {
            emit ProfitAndBuybackLog(_rewardToken, 0, 0, block.timestamp);
            emit PlatformFeeLogInReward(governance, _rewardToken, 0, 0, block.timestamp);
            emit StrategistFeeLogInReward(strategist(), _rewardToken, 0, 0, block.timestamp);
            return new uint[](_buybackTokens.length);
        }
    }

    function _finalizeUpgradePrivate() private {
        _setNextImplementation(address(0));
        _setNextImplementationTimestamp(0);
    }

    // ========================= Abstract Internal Functions =========================

    /**
     * @dev Called after the upgrade is finalized and `nextImplementation` is set back to null. This function is called
     *      for the sake of clean up, so any new state that needs to be set can be done.
     */
    function _finalizeUpgrade() internal;

    /**
     * @dev Withdraws all earned rewards from the reward pool(s)
     */
    function _claimRewards() internal;

    /**
     * @return The balance of `underlying()` in `rewardPool()`
     */
    function _rewardPoolBalance() internal view returns (uint);

    /**
     * @dev Liquidates reward tokens for `underlying`
     */
    function _liquidateReward() internal;

    /**
     * @dev Withdraws `_amount` of `underlying()` from the `rewardPool()` to this contract. Does not attempt to claim
     *      any rewards
     */
    function _partialExitRewardPool(uint256 _amount) internal;

    /**
     * @dev Deposits underlying token into the yield-earning contract.
     */
    function _enterRewardPool() internal;
}

pragma solidity ^0.5.4;


interface ICurvePool {

    function coins(uint i) external view returns (address);
}

pragma solidity ^0.5.4;


interface ITriCryptoPool {

    function add_liquidity(uint[3] calldata amounts, uint min_mint_amount) external;

    function D() external view returns (uint256);

    function coins(uint i) external view returns (address);
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

pragma solidity ^0.5.16;


contract Constants {

    // ========================= Pools / Protocols =========================

    address constant internal CRV_EURS_USD_TOKEN = 0x3dFe1324A0ee9d86337d06aEB829dEb4528DB9CA;

    address constant internal CRV_EURS_USD_POOL = 0xA827a652Ead76c6B0b3D19dba05452E06e25c27e;

    address constant internal CRV_EURS_USD_GAUGE = 0x37C7ef6B0E23C9bd9B620A6daBbFEC13CE30D824;

    address constant internal CRV_REN_WBTC_POOL = 0x3E01dD8a5E1fb3481F0F589056b428Fc308AF0Fb;

    address constant internal CRV_REN_WBTC_GAUGE = 0xC2b1DF84112619D190193E48148000e3990Bf627;

    address constant internal CRV_TRI_CRYPTO_TOKEN = 0x8e0B8c8BB9db49a46697F3a5Bb8A308e744821D2;

    address constant internal CRV_TRI_CRYPTO_GAUGE = 0x97E2768e8E73511cA874545DC5Ff8067eB19B787;

    address constant internal CRV_TRI_CRYPTO_POOL = 0x960ea3e3C7FB317332d990873d354E18d7645590;

    address constant internal CRV_TWO_POOL = 0x7f90122BF0700F9E7e1F688fe926940E8839F353;

    address constant internal CRV_TWO_POOL_GAUGE = 0xbF7E49483881C76487b0989CD7d9A8239B20CA41;

    /// @notice Used as governance
    address constant public DEFAULT_MULTI_SIG_ADDRESS = 0xb39710a1309847363b9cBE5085E427cc2cAeE563;

    address constant public SUSHI_ROUTER = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;

    address constant public UNISWAP_V3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    // ========================= Tokens =========================

    address constant public CRV = 0x11cDb42B0EB46D95f990BeDD4695A6e3fA034978;

    address constant public DAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;

    // We can set this later once we know the address
//    address constant public FARM = 0x0000000000000000000000000000000000000000;

    address constant public LINK = 0xf97f4df75117a78c1A5a0DBb814Af92458539FB4;

    address constant public ONE_INCH = 0x0000000000000000000000000000000000000000;

    address constant public SUSHI = 0xd4d42F0b6DEF4CE0383636770eF773390d85c61A;

    address constant public UNI = 0xFa7F8980b0f1E64A2062791cc3b0871572f1F7f0;

    address constant public USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;

    address constant public USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;

    address constant public WBTC = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;

    address constant public WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
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

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";

import "../inheritance/ControllableInit.sol";

import "../interfaces/IController.sol";
import "../interfaces/IRewardForwarder.sol";
import "../interfaces/IUpgradeSource.sol";


contract BaseUpgradeableStrategyStorage is IUpgradeSource, ControllableInit {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // ==================== Events ====================

    event ProfitsNotCollected(
        address indexed rewardToken,
        bool sell,
        bool floor
    );
    event ProfitLogInReward(
        address indexed rewardToken,
        uint256 profitAmount,
        uint256 feeAmount,
        uint256 timestamp
    );
    event ProfitAndBuybackLog(
        address indexed rewardToken,
        uint256 profitAmount,
        uint256 feeAmount,
        uint256 timestamp
    );
    event PlatformFeeLogInReward(
        address indexed treasury,
        address indexed rewardToken,
        uint256 profitAmount,
        uint256 feeAmount,
        uint256 timestamp
    );
    event StrategistFeeLogInReward(
        address indexed strategist,
        address indexed rewardToken,
        uint256 profitAmount,
        uint256 feeAmount,
        uint256 timestamp
    );

    event UnderlyingSet(address underlying);
    event RewardPoolSet(address rewardPool);
    event RewardTokensSet(address[] rewardTokens);
    event VaultSet(address vault);
    event StrategistSet(address strategist);
    event SellSet(bool shouldSell);
    event PausedInvestingSet(bool isInvestingPaused);
    event SellFloorSet(uint sellFloor);
    event UpgradeScheduled(address newImplementation, uint readyAtTimestamp);

    // ==================== Internal Constants ====================

    bytes32 internal constant _UNDERLYING_SLOT = 0xa1709211eeccf8f4ad5b6700d52a1a9525b5f5ae1e9e5f9e5a0c2fc23c86e530;
    bytes32 internal constant _VAULT_SLOT = 0xefd7c7d9ef1040fc87e7ad11fe15f86e1d11e1df03c6d7c87f7e1f4041f08d41;

    bytes32 internal constant _REWARD_TOKENS_SLOT = 0x45418d9b5c2787ae64acbffccad43f2b487c1a16e24385aa9d2b059f9d1d163c;
    bytes32 internal constant _REWARD_POOL_SLOT = 0x3d9bb16e77837e25cada0cf894835418b38e8e18fbec6cfd192eb344bebfa6b8;
    bytes32 internal constant _SELL_FLOOR_SLOT = 0xc403216a7704d160f6a3b5c3b149a1226a6080f0a5dd27b27d9ba9c022fa0afc;
    bytes32 internal constant _SELL_SLOT = 0x656de32df98753b07482576beb0d00a6b949ebf84c066c765f54f26725221bb6;
    bytes32 internal constant _PAUSED_INVESTING_SLOT = 0xa07a20a2d463a602c2b891eb35f244624d9068572811f63d0e094072fb54591a;

    bytes32 internal constant _PROFIT_SHARING_NUMERATOR_SLOT = 0xe3ee74fb7893020b457d8071ed1ef76ace2bf4903abd7b24d3ce312e9c72c029;
    bytes32 internal constant _PROFIT_SHARING_DENOMINATOR_SLOT = 0x0286fd414602b432a8c80a0125e9a25de9bba96da9d5068c832ff73f09208a3b;

    bytes32 internal constant _NEXT_IMPLEMENTATION_SLOT = 0x29f7fcd4fe2517c1963807a1ec27b0e45e67c60a874d5eeac7a0b1ab1bb84447;
    bytes32 internal constant _NEXT_IMPLEMENTATION_TIMESTAMP_SLOT = 0x414c5263b05428f1be1bfa98e25407cc78dd031d0d3cd2a2e3d63b488804f22e;
    bytes32 internal constant _NEXT_IMPLEMENTATION_DELAY_SLOT = 0x82b330ca72bcd6db11a26f10ce47ebcfe574a9c646bccbc6f1cd4478eae16b31;

    bytes32 internal constant _STRATEGIST_SLOT = 0x6a7b588c950d46e2de3db2f157e5e0e4f29054c8d60f17bf0c30352e223a458d;

    constructor() public {
        assert(_UNDERLYING_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.underlying")) - 1));
        assert(_VAULT_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.vault")) - 1));
        assert(_REWARD_TOKENS_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.rewardTokens")) - 1));
        assert(_REWARD_POOL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.rewardPool")) - 1));
        assert(_SELL_FLOOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.sellFloor")) - 1));
        assert(_SELL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.sell")) - 1));
        assert(_PAUSED_INVESTING_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.pausedInvesting")) - 1));

        assert(_PROFIT_SHARING_NUMERATOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.profitSharingNumerator")) - 1));
        assert(_PROFIT_SHARING_DENOMINATOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.profitSharingDenominator")) - 1));

        assert(_NEXT_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.nextImplementation")) - 1));
        assert(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.nextImplementationTimestamp")) - 1));
        assert(_NEXT_IMPLEMENTATION_DELAY_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.nextImplementationDelay")) - 1));

        assert(_STRATEGIST_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.strategist")) - 1));
    }

    // ==================== Internal Functions ====================

    function _setUnderlying(address _underlying) internal {
        setAddress(_UNDERLYING_SLOT, _underlying);
        emit UnderlyingSet(_underlying);
    }

    function underlying() public view returns (address) {
        return getAddress(_UNDERLYING_SLOT);
    }

    function _setRewardPool(address _rewardPool) internal {
        setAddress(_REWARD_POOL_SLOT, _rewardPool);
        emit RewardPoolSet(_rewardPool);
    }

    function rewardPool() public view returns (address) {
        return getAddress(_REWARD_POOL_SLOT);
    }

    function _setRewardTokens(address[] memory _rewardTokens) internal {
        setAddressArray(_REWARD_TOKENS_SLOT, _rewardTokens);
        emit RewardTokensSet(_rewardTokens);
    }

    function isRewardToken(address _token) public view returns (bool) {
        return _isAddressInList(_token, rewardTokens());
    }

    function rewardTokens() public view returns (address[] memory) {
        return getAddressArray(_REWARD_TOKENS_SLOT);
    }

    function _isAddressInList(address _searchValue, address[] memory _list) internal pure returns (bool) {
        for (uint i = 0; i < _list.length; i++) {
            if (_list[i] == _searchValue) {
                return true;
            }
        }
        return false;
    }

    function _setVault(address _vault) internal {
        setAddress(_VAULT_SLOT, _vault);
        emit VaultSet(_vault);
    }

    function vault() public view returns (address) {
        return getAddress(_VAULT_SLOT);
    }

    function _setStrategist(address _strategist) internal {
        setAddress(_STRATEGIST_SLOT, _strategist);
        emit StrategistSet(_strategist);
    }

    function strategist() public view returns (address) {
        return getAddress(_STRATEGIST_SLOT);
    }

    /**
     * @dev a flag for disabling selling for simplified emergency exit
     */
    function _setSell(bool _shouldSell) internal {
        setBoolean(_SELL_SLOT, _shouldSell);
        emit SellSet(_shouldSell);
    }

    function sell() public view returns (bool) {
        return getBoolean(_SELL_SLOT);
    }

    function _setPausedInvesting(bool _isInvestingPaused) internal {
        setBoolean(_PAUSED_INVESTING_SLOT, _isInvestingPaused);
        emit PausedInvestingSet(_isInvestingPaused);
    }

    function pausedInvesting() public view returns (bool) {
        return getBoolean(_PAUSED_INVESTING_SLOT);
    }

    function _setSellFloor(uint256 _value) internal {
        setUint256(_SELL_FLOOR_SLOT, _value);
        emit SellFloorSet(_value);
    }

    function sellFloor() public view returns (uint256) {
        return getUint256(_SELL_FLOOR_SLOT);
    }

    function profitSharingNumerator() public view returns (uint256) {
        return IController(controller()).profitSharingNumerator();
    }

    function profitSharingDenominator() public view returns (uint256) {
        return IController(controller()).profitSharingDenominator();
    }

    function strategistFeeNumerator() public view returns (uint256) {
        return IController(controller()).strategistFeeNumerator();
    }

    function strategistFeeDenominator() public view returns (uint256) {
        return IController(controller()).strategistFeeDenominator();
    }

    function platformFeeNumerator() public view returns (uint256) {
        return IController(controller()).platformFeeNumerator();
    }

    function platformFeeDenominator() public view returns (uint256) {
        return IController(controller()).platformFeeDenominator();
    }

    // ========================= Internal Functions for Upgradability =========================

    function _setNextImplementation(address _address) internal {
        // event is emitted in caller in subclass
        setAddress(_NEXT_IMPLEMENTATION_SLOT, _address);
    }

    function nextImplementation() public view returns (address) {
        return getAddress(_NEXT_IMPLEMENTATION_SLOT);
    }

    function _setNextImplementationTimestamp(uint256 _value) internal {
        // event is emitted in caller in subclass
        setUint256(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT, _value);
    }

    function nextImplementationTimestamp() public view returns (uint256) {
        return getUint256(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT);
    }

    function nextImplementationDelay() public view returns (uint256) {
        return IController(controller()).nextImplementationDelay();
    }

    // ========================= Internal Functions for Primitives =========================

    function setBoolean(bytes32 slot, bool _value) internal {
        setUint256(slot, _value ? 1 : 0);
    }

    function getBoolean(bytes32 slot) internal view returns (bool) {
        return (getUint256(slot) == 1);
    }

    function setAddress(bytes32 slot, address _address) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _address)
        }
    }

    function setUint256(bytes32 slot, uint256 _value) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _value)
        }
    }

    function setUint256Array(bytes32 slot, uint256[] memory _values) internal {
        // solhint-disable-next-line no-inline-assembly
        setUint256(slot, _values.length);
        for (uint i = 0; i < _values.length; i++) {
            setUint256(bytes32(uint(slot) + 1 + i), _values[i]);
        }
    }

    function setAddressArray(bytes32 slot, address[] memory _values) internal {
        // solhint-disable-next-line no-inline-assembly
        setUint256(slot, _values.length);
        for (uint i = 0; i < _values.length; i++) {
            setAddress(bytes32(uint(slot) + 1 + i), _values[i]);
        }
    }

    function getUint256Array(bytes32 slot) internal view returns (uint[] memory values) {
        // solhint-disable-next-line no-inline-assembly
        values = new uint[](getUint256(slot));
        for (uint i = 0; i < values.length; i++) {
            values[i] = getUint256(bytes32(uint(slot) + 1 + i));
        }
    }

    function getAddressArray(bytes32 slot) internal view returns (address[] memory values) {
        // solhint-disable-next-line no-inline-assembly
        values = new address[](getUint256(slot));
        for (uint i = 0; i < values.length; i++) {
            values[i] = getAddress(bytes32(uint(slot) + 1 + i));
        }
    }

    function getAddress(bytes32 slot) internal view returns (address str) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            str := sload(slot)
        }
    }

    function getUint256(bytes32 slot) internal view returns (uint256 str) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            str := sload(slot)
        }
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


interface IUpgradeSource {

  function shouldUpgrade() external view returns (bool, address);

  function finalizeUpgrade() external;
}