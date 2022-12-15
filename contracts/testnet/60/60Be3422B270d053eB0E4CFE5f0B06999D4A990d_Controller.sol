//SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.7.6;
pragma abicoder v2;

import {Initializable} from "lib/openzeppelin-contracts/contracts/proxy/Initializable.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/math/SignedSafeMath.sol";
import "lib/v3-periphery/contracts/libraries/PoolAddress.sol";
import {TransferHelper} from "lib/v3-periphery/contracts/libraries/TransferHelper.sol";
import "lib/v3-core/contracts/interfaces/callback/IUniswapV3MintCallback.sol";
import "lib/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import "lib/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IVaultNFT} from "./interfaces/IVaultNFT.sol";
import {BaseToken} from "./libraries/BaseToken.sol";
import "./libraries/DataType.sol";
import "./libraries/VaultLib.sol";
import "./libraries/PredyMath.sol";
import "./libraries/PositionUpdater.sol";
import "./libraries/InterestCalculator.sol";
import "./libraries/PositionLib.sol";
import "./libraries/logic/LiquidationLogic.sol";
import "./libraries/logic/UpdatePositionLogic.sol";
import "./libraries/Constants.sol";

/**
 * Error Codes
 * P1: caller must be vault owner
 * P2: vault does not exists
 * P3: caller must be operator
 * P4: cannot create vault with 0 amount
 * P5: paused
 * P6: unpaused
 * P7: tx too old
 * P8: too much slippage
 * P9: invalid interest rate model
 */
contract Controller is Initializable, IUniswapV3MintCallback, IUniswapV3SwapCallback {
    using BaseToken for BaseToken.TokenState;
    using SignedSafeMath for int256;
    using VaultLib for DataType.Vault;

    uint256 public lastTouchedTimestamp;

    mapping(bytes32 => DataType.PerpStatus) internal ranges;

    mapping(uint256 => DataType.Vault) internal vaults;
    mapping(uint256 => DataType.SubVault) internal subVaults;

    DataType.Context internal context;
    InterestCalculator.IRMParams public irmParams;
    InterestCalculator.YearlyPremiumParams public ypParams;

    address public operator;

    address private vaultNFT;

    bool public isSystemPaused;

    event OperatorUpdated(address operator);
    event VaultCreated(uint256 vaultId, address owner);
    event Paused();
    event UnPaused();
    event ProtocolFeeWithdrawn(uint256 withdrawnFee0, uint256 withdrawnFee1);

    modifier notPaused() {
        require(!isSystemPaused, "P5");
        _;
    }

    modifier isPaused() {
        require(isSystemPaused, "P6");
        _;
    }

    modifier onlyOperator() {
        require(operator == msg.sender, "P3");
        _;
    }

    modifier checkVaultExists(uint256 _vaultId) {
        require(_vaultId < IVaultNFT(vaultNFT).nextId(), "P2");
        _;
    }

    modifier checkDeadline(uint256 deadline) {
        require(block.timestamp <= deadline, "P7");
        _;
    }

    constructor() {}

    /**
     * @dev Callback for Uniswap V3 pool.
     */
    function uniswapV3MintCallback(
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override {
        require(msg.sender == context.uniswapPool);
        if (amount0 > 0) TransferHelper.safeTransfer(context.token0, msg.sender, amount0);
        if (amount1 > 0) TransferHelper.safeTransfer(context.token1, msg.sender, amount1);
    }

    /**
     * @dev Callback for Uniswap V3 pool.
     */
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external override {
        require(msg.sender == context.uniswapPool);
        if (amount0Delta > 0) TransferHelper.safeTransfer(context.token0, msg.sender, uint256(amount0Delta));
        if (amount1Delta > 0) TransferHelper.safeTransfer(context.token1, msg.sender, uint256(amount1Delta));
    }

    function initialize(
        DataType.InitializationParams memory _initializationParams,
        address _factory,
        address _chainlinkPriceFeed,
        address _vaultNFT
    ) public initializer {
        require(_vaultNFT != address(0));
        context.feeTier = _initializationParams.feeTier;
        context.token0 = _initializationParams.token0;
        context.token1 = _initializationParams.token1;
        context.isMarginZero = _initializationParams.isMarginZero;
        context.chainlinkPriceFeed = _chainlinkPriceFeed;

        PoolAddress.PoolKey memory poolKey = PoolAddress.PoolKey({
            token0: context.token0,
            token1: context.token1,
            fee: context.feeTier
        });

        context.uniswapPool = PoolAddress.computeAddress(_factory, poolKey);

        vaultNFT = _vaultNFT;

        context.nextSubVaultId = 1;

        context.tokenState0.initialize();
        context.tokenState1.initialize();

        lastTouchedTimestamp = block.timestamp;

        operator = msg.sender;
    }

    /**
     * @notice Sets new operator
     * @dev Only operator can call this function.
     * @param _newOperator The address of new operator
     */
    function setOperator(address _newOperator) external onlyOperator {
        require(_newOperator != address(0));
        operator = _newOperator;

        emit OperatorUpdated(_newOperator);
    }

    /**
     * @notice Updates interest rate model parameter.
     * @dev Only operator can call this function.
     * @param _irmParams New interest rate model parameter
     */
    function updateIRMParams(InterestCalculator.IRMParams memory _irmParams) external onlyOperator {
        validateIRMParams(_irmParams);
        irmParams = _irmParams;
    }

    /**
     * @notice Updates interest rate model parameters for premium calculation.
     * @dev Only operator can call this function.
     * @param _irmParams New interest rate model parameter
     * @param _premiumParams New interest rate model parameter for variance calculation
     */
    function updateYearlyPremiumParams(
        InterestCalculator.IRMParams memory _irmParams,
        InterestCalculator.IRMParams memory _premiumParams
    ) external onlyOperator {
        validateIRMParams(_irmParams);
        validateIRMParams(_premiumParams);
        ypParams.irmParams = _irmParams;
        ypParams.premiumParams = _premiumParams;
    }

    /**
     * @notice Withdraws accumulated protocol fee.
     * @dev Only operator can call this function.
     * @param _amount0 amount of token0 to withdraw
     * @param _amount1 amount of token1 to withdraw
     */
    function withdrawProtocolFee(uint256 _amount0, uint256 _amount1) external onlyOperator {
        require(context.accumulatedProtocolFee0 >= _amount0 && context.accumulatedProtocolFee1 >= _amount1, "P8");

        context.accumulatedProtocolFee0 -= _amount0;
        context.accumulatedProtocolFee1 -= _amount1;

        if (_amount0 > 0) {
            TransferHelper.safeTransfer(context.token0, msg.sender, _amount0);
        }

        if (_amount1 > 0) {
            TransferHelper.safeTransfer(context.token1, msg.sender, _amount1);
        }

        emit ProtocolFeeWithdrawn(_amount0, _amount1);
    }

    /**
     * @notice pause the contract
     */
    function pause() external onlyOperator notPaused {
        isSystemPaused = true;

        emit Paused();
    }

    /**
     * @notice unpause the contract
     */
    function unPause() external onlyOperator isPaused {
        isSystemPaused = false;

        emit UnPaused();
    }

    // User API

    /**
     * @notice Opens new position.
     * @param _vaultId The id of the vault. 0 means that it creates new vault.
     * @param _position Position to open
     * @param _tradeOption Trade parameters
     * @param _openPositionOptions Option parameters to open position
     */
    function openPosition(
        uint256 _vaultId,
        DataType.Position memory _position,
        DataType.TradeOption memory _tradeOption,
        DataType.OpenPositionOption memory _openPositionOptions
    )
        external
        returns (
            uint256 vaultId,
            DataType.TokenAmounts memory requiredAmounts,
            DataType.TokenAmounts memory swapAmounts
        )
    {
        DataType.PositionUpdate[] memory positionUpdates = PositionLib.getPositionUpdatesToOpen(
            _position,
            _tradeOption.isQuoteZero,
            getSqrtPrice(),
            _openPositionOptions.swapRatio
        );

        (vaultId, requiredAmounts, swapAmounts) = updatePosition(
            _vaultId,
            positionUpdates,
            _tradeOption,
            _openPositionOptions
        );
    }

    function updatePosition(
        uint256 _vaultId,
        DataType.PositionUpdate[] memory positionUpdates,
        DataType.TradeOption memory _tradeOption,
        DataType.OpenPositionOption memory _openPositionOptions
    )
        public
        notPaused
        checkDeadline(_openPositionOptions.deadline)
        returns (
            uint256 vaultId,
            DataType.TokenAmounts memory requiredAmounts,
            DataType.TokenAmounts memory swapAmounts
        )
    {
        (vaultId, requiredAmounts, swapAmounts) = _updatePosition(_vaultId, positionUpdates, _tradeOption);

        _checkPrice(_openPositionOptions.lowerSqrtPrice, _openPositionOptions.upperSqrtPrice);
    }

    /**
     * @notice Closes all positions in a vault.
     * @param _vaultId The id of the vault
     * @param _tradeOption Trade parameters
     * @param _closePositionOptions Option parameters to close position
     */
    function closeVault(
        uint256 _vaultId,
        DataType.TradeOption memory _tradeOption,
        DataType.ClosePositionOption memory _closePositionOptions
    )
        external
        notPaused
        returns (DataType.TokenAmounts memory requiredAmounts, DataType.TokenAmounts memory swapAmounts)
    {
        return closePosition(_vaultId, _getPosition(_vaultId), _tradeOption, _closePositionOptions);
    }

    /**
     * @notice Closes all positions in sub-vault.
     * @param _vaultId The id of the vault
     * @param _subVaultId The id of the sub-vault
     * @param _tradeOption Trade parameters
     * @param _closePositionOptions Option parameters to close position
     */
    function closeSubVault(
        uint256 _vaultId,
        uint256 _subVaultId,
        DataType.TradeOption memory _tradeOption,
        DataType.ClosePositionOption memory _closePositionOptions
    )
        external
        notPaused
        returns (DataType.TokenAmounts memory requiredAmounts, DataType.TokenAmounts memory swapAmounts)
    {
        DataType.Position[] memory positions = new DataType.Position[](1);

        positions[0] = _getPositionOfSubVault(_subVaultId);

        return closePosition(_vaultId, positions, _tradeOption, _closePositionOptions);
    }

    /**
     * @notice Closes position partially.
     * @param _vaultId The id of the vault
     * @param _positions Positions to close
     * @param _tradeOption Trade parameters
     * @param _closePositionOptions Option parameters to close position
     */
    function closePosition(
        uint256 _vaultId,
        DataType.Position[] memory _positions,
        DataType.TradeOption memory _tradeOption,
        DataType.ClosePositionOption memory _closePositionOptions
    )
        public
        notPaused
        checkDeadline(_closePositionOptions.deadline)
        returns (DataType.TokenAmounts memory requiredAmounts, DataType.TokenAmounts memory swapAmounts)
    {
        DataType.PositionUpdate[] memory positionUpdates = PositionLib.getPositionUpdatesToClose(
            _positions,
            _tradeOption.isQuoteZero,
            getSqrtPrice(),
            _closePositionOptions.swapRatio,
            _closePositionOptions.closeRatio
        );

        (, requiredAmounts, swapAmounts) = _updatePosition(_vaultId, positionUpdates, _tradeOption);

        _checkPrice(_closePositionOptions.lowerSqrtPrice, _closePositionOptions.upperSqrtPrice);
    }

    /**
     * @notice Liquidates a vault.
     * @param _vaultId The id of the vault
     * @param _liquidationOption option parameters for liquidation call
     */
    function liquidate(uint256 _vaultId, DataType.LiquidationOption memory _liquidationOption) external notPaused {
        DataType.PositionUpdate[] memory positionUpdates = PositionLib.getPositionUpdatesToClose(
            getPosition(_vaultId),
            context.isMarginZero,
            getSqrtPrice(),
            _liquidationOption.swapRatio,
            _liquidationOption.closeRatio
        );

        _liquidate(_vaultId, positionUpdates);
    }

    /**
     * @notice Update position in a vault.
     * @param _vaultId The id of the vault. 0 means that it creates new vault.
     * @param _positionUpdates Operation list to update position
     * @param _tradeOption trade parameters
     */
    function _updatePosition(
        uint256 _vaultId,
        DataType.PositionUpdate[] memory _positionUpdates,
        DataType.TradeOption memory _tradeOption
    )
        internal
        checkVaultExists(_vaultId)
        returns (
            uint256 vaultId,
            DataType.TokenAmounts memory requiredAmounts,
            DataType.TokenAmounts memory swapAmounts
        )
    {
        applyPerpFee(_vaultId, _positionUpdates);

        DataType.Vault storage vault;
        (vaultId, vault) = createOrGetVault(_vaultId, _tradeOption.quoterMode);

        DataType.PositionUpdateResult memory positionUpdateResult = UpdatePositionLogic.updatePosition(
            vault,
            subVaults,
            context,
            ranges,
            _positionUpdates,
            _tradeOption
        );

        requiredAmounts = positionUpdateResult.requiredAmounts;
        swapAmounts = positionUpdateResult.swapAmounts;

        if (_vaultId == 0) {
            // non 0 amount of tokens required to create new vault.
            if (context.isMarginZero) {
                require(requiredAmounts.amount0 >= Constants.MIN_MARGIN_AMOUNT, "P4");
            } else {
                require(requiredAmounts.amount1 >= Constants.MIN_MARGIN_AMOUNT, "P4");
            }
        }
    }

    /**
     * @notice Anyone can liquidates the vault if its vault value is less than Min. Deposit.
     * @param _vaultId The id of the vault
     * @param _positionUpdates Operation list to update position
     */
    function _liquidate(uint256 _vaultId, DataType.PositionUpdate[] memory _positionUpdates)
        internal
        checkVaultExists(_vaultId)
    {
        require(_vaultId > 0);

        applyPerpFee(_vaultId, _positionUpdates);

        LiquidationLogic.execLiquidation(vaults[_vaultId], subVaults, _positionUpdates, context, ranges);
    }

    // Getter Functions

    function getContext()
        external
        view
        returns (
            bool,
            uint256,
            address,
            uint256,
            uint256
        )
    {
        return (
            context.isMarginZero,
            context.nextSubVaultId,
            context.uniswapPool,
            context.accumulatedProtocolFee0,
            context.accumulatedProtocolFee1
        );
    }

    /**
     * @notice Returns a Liquidity Provider Token (LPT) data
     * @param _rangeId The id of the LPT
     */
    function getRange(bytes32 _rangeId) external returns (DataType.PerpStatus memory) {
        InterestCalculator.updatePremiumGrowth(ypParams, context, ranges[_rangeId], getSqrtIndexPrice());

        InterestCalculator.updateFeeGrowthForRange(context, ranges[_rangeId]);

        return ranges[_rangeId];
    }

    /**
     * @notice Returns the utilization ratio of Liquidity Provider Token (LPT).
     * @param _rangeId The id of the LPT
     */
    function getUtilizationRatio(bytes32 _rangeId)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        if (ranges[_rangeId].lastTouchedTimestamp == 0) {
            return (0, 0, 0);
        }

        return LPTStateLib.getPerpStatus(address(this), context.uniswapPool, ranges[_rangeId]);
    }

    /**
     * @notice Returns the status of supplied tokens.
     */
    function getTokenState() external returns (BaseToken.TokenState memory, BaseToken.TokenState memory) {
        applyInterest();

        return (context.tokenState0, context.tokenState1);
    }

    /**
     * @notice Returns the flag whether a vault is safe or not.
     * @param _vaultId vault id
     * @return isSafe true if the vault is safe, false if the vault can be liquidated.
     */
    function isVaultSafe(uint256 _vaultId) external returns (bool isSafe) {
        applyPerpFee(_vaultId);

        return LiquidationLogic.isVaultSafe(vaults[_vaultId], subVaults, context, ranges);
    }

    /**
     * @notice Returns values and token amounts of the vault.
     * @param _vaultId The id of the vault
     */
    function getVaultStatus(uint256 _vaultId, uint160 _sqrtPriceX96) external returns (DataType.VaultStatus memory) {
        applyPerpFee(_vaultId);

        return vaults[_vaultId].getVaultStatus(subVaults, ranges, context, _sqrtPriceX96);
    }

    function getVaultValue(uint256 _vaultId) external view returns (int256) {
        return LiquidationLogic.getVaultValue(vaults[_vaultId], subVaults, context, ranges);
    }

    /**
     * @notice Returns a vault data
     * @param _vaultId The id of the vault
     */
    function getVault(uint256 _vaultId) external view returns (DataType.Vault memory) {
        return vaults[_vaultId];
    }

    /**
     * @notice Returns a sub-vault data
     * @param _subVaultId The id of the sub-vault
     */
    function getSubVault(uint256 _subVaultId) external view returns (DataType.SubVault memory) {
        return subVaults[_subVaultId];
    }

    function calculateLPTBorrowerAndLenderPremium(
        bytes32 _rangeId,
        uint256 _perpUr,
        uint256 _elapsed
    )
        external
        view
        returns (
            uint256 premiumGrowthForBorrower,
            uint256 premiumGrowthForLender,
            uint256 protocolFeePerLiquidity
        )
    {
        return
            InterestCalculator.calculateLPTBorrowerAndLenderPremium(
                ypParams,
                context,
                ranges[_rangeId],
                getSqrtIndexPrice(),
                _perpUr,
                _elapsed
            );
    }

    // Private Functions

    function validateIRMParams(InterestCalculator.IRMParams memory _irmParams) internal pure {
        require(
            _irmParams.baseRate <= 1e18 &&
                _irmParams.kinkRate <= 1e18 &&
                _irmParams.slope1 <= 1e18 &&
                _irmParams.slope2 <= 10 * 1e18,
            "P9"
        );
    }

    function createOrGetVault(uint256 _vaultId, bool _quoterMode)
        internal
        returns (uint256 vaultId, DataType.Vault storage)
    {
        if (_vaultId == 0) {
            vaultId = IVaultNFT(vaultNFT).mintNFT(msg.sender);

            vaults[vaultId].vaultId = vaultId;

            emit VaultCreated(vaultId, msg.sender);
        } else {
            vaultId = _vaultId;

            require(IVaultNFT(vaultNFT).ownerOf(vaultId) == msg.sender || _quoterMode, "P1");
        }

        return (vaultId, vaults[vaultId]);
    }

    /**
     * @notice apply interest, premium and trade fee for ranges that the vault has.
     */
    function applyPerpFee(uint256 _vaultId) internal {
        applyPerpFee(_vaultId, new DataType.PositionUpdate[](0));
    }

    /**
     * @notice apply interest, premium and trade fee for ranges that the vault and positionUpdates have.
     */
    function applyPerpFee(uint256 _vaultId, DataType.PositionUpdate[] memory _positionUpdates) internal {
        applyInterest();

        DataType.Vault memory vault = vaults[_vaultId];

        InterestCalculator.updatePremiumGrowthForVault(
            vault,
            subVaults,
            ranges,
            context,
            _positionUpdates,
            ypParams,
            getSqrtIndexPrice()
        );

        InterestCalculator.updateFeeGrowth(context, vault, subVaults, ranges, _positionUpdates);
    }

    function applyInterest() internal {
        lastTouchedTimestamp = InterestCalculator.applyInterest(context, irmParams, lastTouchedTimestamp);
    }

    function _checkPrice(uint256 _lowerSqrtPrice, uint256 _upperSqrtPrice) internal view {
        uint256 sqrtPrice = getSqrtPrice();

        require(_lowerSqrtPrice <= sqrtPrice && sqrtPrice <= _upperSqrtPrice, "P8");
    }

    /**
     * Gets square root of current underlying token price by quote token.
     */
    function getSqrtPrice() public view returns (uint160 sqrtPriceX96) {
        return UniHelper.getSqrtPrice(context.uniswapPool);
    }

    function getSqrtIndexPrice() public view returns (uint160) {
        return LiquidationLogic.getSqrtIndexPrice(context);
    }

    function getPosition(uint256 _vaultId) public view returns (DataType.Position[] memory) {
        return _getPosition(_vaultId);
    }

    function _getPosition(uint256 _vaultId) internal view returns (DataType.Position[] memory) {
        DataType.Vault memory vault = vaults[_vaultId];

        return vault.getPositions(subVaults, ranges, context);
    }

    function getPositionCalculatorParams(uint256 _vaultId)
        public
        view
        returns (PositionCalculator.PositionCalculatorParams memory)
    {
        DataType.Vault memory vault = vaults[_vaultId];

        return vault.getPositionCalculatorParams(subVaults, ranges, context);
    }

    function _getPositionOfSubVault(uint256 _subVaultId) internal view returns (DataType.Position memory) {
        return VaultLib.getPositionOfSubVault(subVaults[_subVaultId], ranges, context);
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
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

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

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
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        factory,
                        keccak256(abi.encode(key.token0, key.token1, key.fee)),
                        POOL_INIT_CODE_HASH
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#mint
/// @notice Any contract that calls IUniswapV3PoolActions#mint must implement this interface
interface IUniswapV3MintCallback {
    /// @notice Called to `msg.sender` after minting liquidity to a position from IUniswapV3Pool#mint.
    /// @dev In the implementation you must pay the pool tokens owed for the minted liquidity.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// @param amount0Owed The amount of token0 due to the pool for the minted liquidity
    /// @param amount1Owed The amount of token1 due to the pool for the minted liquidity
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#mint call
    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.7.6;

import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

interface IVaultNFT is IERC721 {
    function nextId() external returns (uint256);

    function mintNFT(address _recipient) external returns (uint256 tokenId);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

import "lib/openzeppelin-contracts/contracts/math/SafeMath.sol";
import "./PredyMath.sol";
import "./Constants.sol";

library BaseToken {
    using SafeMath for uint256;

    enum InterestType {
        EMPTY,
        COMPOUND,
        NORMAL
    }

    struct TokenState {
        uint256 totalCompoundDeposited;
        uint256 totalCompoundBorrowed;
        uint256 totalNormalDeposited;
        uint256 totalNormalBorrowed;
        uint256 assetScaler;
        uint256 debtScaler;
        uint256 assetGrowth;
        uint256 debtGrowth;
    }

    struct AccountState {
        InterestType interestType;
        uint256 assetAmount;
        uint256 debtAmount;
        uint256 lastAssetGrowth;
        uint256 lastDebtGrowth;
    }

    function initialize(TokenState storage tokenState) internal {
        tokenState.assetScaler = Constants.ONE;
        tokenState.debtScaler = Constants.ONE;
    }

    function addAsset(
        TokenState storage tokenState,
        AccountState storage accountState,
        uint256 _amount,
        bool _isCompound
    ) internal returns (uint256 mintAmount) {
        if (_amount == 0) {
            return 0;
        }

        if (_isCompound) {
            require(accountState.interestType != InterestType.NORMAL, "B1");
            mintAmount = PredyMath.mulDiv(_amount, Constants.ONE, tokenState.assetScaler);

            accountState.assetAmount = accountState.assetAmount.add(mintAmount);
            tokenState.totalCompoundDeposited = tokenState.totalCompoundDeposited.add(mintAmount);

            accountState.interestType = InterestType.COMPOUND;
        } else {
            require(accountState.interestType != InterestType.COMPOUND, "B2");

            accountState.lastAssetGrowth = tokenState.assetGrowth;

            accountState.assetAmount = accountState.assetAmount.add(_amount);
            tokenState.totalNormalDeposited = tokenState.totalNormalDeposited.add(_amount);

            accountState.interestType = InterestType.NORMAL;
        }
    }

    function addDebt(
        TokenState storage tokenState,
        AccountState storage accountState,
        uint256 _amount,
        bool _isCompound
    ) internal returns (uint256 mintAmount) {
        if (_amount == 0) {
            return 0;
        }

        require(getAvailableCollateralValue(tokenState) >= _amount, "B0");

        if (_isCompound) {
            require(accountState.interestType != InterestType.NORMAL, "B1");
            mintAmount = PredyMath.mulDiv(_amount, Constants.ONE, tokenState.debtScaler);

            accountState.debtAmount = accountState.debtAmount.add(mintAmount);
            tokenState.totalCompoundBorrowed = tokenState.totalCompoundBorrowed.add(mintAmount);

            accountState.interestType = InterestType.COMPOUND;
        } else {
            require(accountState.interestType != InterestType.COMPOUND, "B2");

            accountState.lastDebtGrowth = tokenState.debtGrowth;

            accountState.debtAmount = accountState.debtAmount.add(_amount);
            tokenState.totalNormalBorrowed = tokenState.totalNormalBorrowed.add(_amount);

            accountState.interestType = InterestType.NORMAL;
        }
    }

    function removeAsset(
        TokenState storage tokenState,
        AccountState storage accountState,
        uint256 _amount
    ) internal returns (uint256 finalBurnAmount) {
        if (_amount == 0) {
            return 0;
        }

        if (accountState.interestType == InterestType.COMPOUND) {
            uint256 burnAmount = PredyMath.mulDiv(_amount, Constants.ONE, tokenState.assetScaler);

            if (accountState.assetAmount < burnAmount) {
                finalBurnAmount = accountState.assetAmount;
                accountState.assetAmount = 0;
            } else {
                finalBurnAmount = burnAmount;
                accountState.assetAmount = accountState.assetAmount.sub(burnAmount);
            }

            tokenState.totalCompoundDeposited = tokenState.totalCompoundDeposited.sub(finalBurnAmount);

            finalBurnAmount = PredyMath.mulDiv(finalBurnAmount, tokenState.assetScaler, Constants.ONE);
        } else {
            if (accountState.assetAmount < _amount) {
                finalBurnAmount = accountState.assetAmount;
                accountState.assetAmount = 0;
            } else {
                finalBurnAmount = _amount;
                accountState.assetAmount = accountState.assetAmount.sub(_amount);
            }

            tokenState.totalNormalDeposited = tokenState.totalNormalDeposited.sub(finalBurnAmount);
        }
    }

    function removeDebt(
        TokenState storage tokenState,
        AccountState storage accountState,
        uint256 _amount
    ) internal returns (uint256 finalBurnAmount) {
        if (_amount == 0) {
            return 0;
        }

        if (accountState.interestType == InterestType.COMPOUND) {
            uint256 burnAmount = PredyMath.mulDiv(_amount, Constants.ONE, tokenState.debtScaler);

            if (accountState.debtAmount < burnAmount) {
                finalBurnAmount = accountState.debtAmount;
                accountState.debtAmount = 0;
            } else {
                finalBurnAmount = burnAmount;
                accountState.debtAmount = accountState.debtAmount.sub(burnAmount);
            }

            tokenState.totalCompoundBorrowed = tokenState.totalCompoundBorrowed.sub(finalBurnAmount);

            finalBurnAmount = PredyMath.mulDiv(finalBurnAmount, tokenState.debtScaler, Constants.ONE);
        } else {
            if (accountState.debtAmount < _amount) {
                finalBurnAmount = accountState.debtAmount;
                accountState.debtAmount = 0;
            } else {
                finalBurnAmount = _amount;
                accountState.debtAmount = accountState.debtAmount.sub(_amount);
            }

            tokenState.totalNormalBorrowed = tokenState.totalNormalBorrowed.sub(finalBurnAmount);
        }
    }

    function refreshFee(TokenState memory tokenState, AccountState storage accountState) internal {
        accountState.lastAssetGrowth = tokenState.assetGrowth;
        accountState.lastDebtGrowth = tokenState.debtGrowth;
    }

    function getAssetFee(TokenState memory tokenState, AccountState memory accountState)
        internal
        pure
        returns (uint256)
    {
        if (accountState.interestType != InterestType.NORMAL) {
            return 0;
        }

        return
            PredyMath.mulDiv(
                tokenState.assetGrowth.sub(accountState.lastAssetGrowth),
                accountState.assetAmount,
                Constants.ONE
            );
    }

    function getDebtFee(TokenState memory tokenState, AccountState memory accountState)
        internal
        pure
        returns (uint256)
    {
        if (accountState.interestType != InterestType.NORMAL) {
            return 0;
        }

        return
            PredyMath.mulDiv(
                tokenState.debtGrowth.sub(accountState.lastDebtGrowth),
                accountState.debtAmount,
                Constants.ONE
            );
    }

    // get collateral value
    function getAssetValue(TokenState memory tokenState, AccountState memory accountState)
        internal
        pure
        returns (uint256)
    {
        if (accountState.interestType == InterestType.COMPOUND) {
            return PredyMath.mulDiv(accountState.assetAmount, tokenState.assetScaler, Constants.ONE);
        } else {
            return accountState.assetAmount;
        }
    }

    // get debt value
    function getDebtValue(TokenState memory tokenState, AccountState memory accountState)
        internal
        pure
        returns (uint256)
    {
        if (accountState.interestType == InterestType.COMPOUND) {
            return PredyMath.mulDiv(accountState.debtAmount, tokenState.debtScaler, Constants.ONE);
        } else {
            return accountState.debtAmount;
        }
    }

    // update scaler
    function updateScaler(TokenState storage tokenState, uint256 _interestRate) internal returns (uint256) {
        if (tokenState.totalCompoundDeposited == 0 && tokenState.totalNormalDeposited == 0) {
            return 0;
        }

        uint256 protocolFee = PredyMath.mulDiv(
            PredyMath.mulDiv(_interestRate, getTotalDebtValue(tokenState), Constants.ONE),
            Constants.RESERVE_FACTOR,
            Constants.ONE
        );

        // supply interest rate is InterestRate * Utilization * (1 - ReserveFactor)
        uint256 supplyInterestRate = PredyMath.mulDiv(
            PredyMath.mulDiv(_interestRate, getTotalDebtValue(tokenState), getTotalCollateralValue(tokenState)),
            Constants.ONE - Constants.RESERVE_FACTOR,
            Constants.ONE
        );

        // round up
        tokenState.debtScaler = PredyMath.mulDivUp(
            tokenState.debtScaler,
            (Constants.ONE.add(_interestRate)),
            Constants.ONE
        );
        tokenState.debtGrowth = tokenState.debtGrowth.add(_interestRate);
        tokenState.assetScaler = PredyMath.mulDiv(
            tokenState.assetScaler,
            Constants.ONE + supplyInterestRate,
            Constants.ONE
        );
        tokenState.assetGrowth = tokenState.assetGrowth.add(supplyInterestRate);

        return protocolFee;
    }

    function getTotalCollateralValue(TokenState memory tokenState) internal pure returns (uint256) {
        return
            PredyMath.mulDiv(tokenState.totalCompoundDeposited, tokenState.assetScaler, Constants.ONE).add(
                tokenState.totalNormalDeposited
            );
    }

    function getTotalDebtValue(TokenState memory tokenState) internal pure returns (uint256) {
        return
            PredyMath.mulDiv(tokenState.totalCompoundBorrowed, tokenState.debtScaler, Constants.ONE).add(
                tokenState.totalNormalBorrowed
            );
    }

    function getAvailableCollateralValue(TokenState memory tokenState) internal pure returns (uint256) {
        return getTotalCollateralValue(tokenState).sub(getTotalDebtValue(tokenState));
    }

    function getUtilizationRatio(TokenState memory tokenState) internal pure returns (uint256) {
        if (tokenState.totalCompoundDeposited == 0 && tokenState.totalNormalBorrowed == 0) {
            return Constants.ONE;
        }

        return PredyMath.mulDiv(getTotalDebtValue(tokenState), Constants.ONE, getTotalCollateralValue(tokenState));
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

import "./PredyMath.sol";
import "./BaseToken.sol";

library DataType {
    // Storage Data Type
    struct PerpStatus {
        int24 lowerTick;
        int24 upperTick;
        uint128 borrowedLiquidity;
        uint256 premiumGrowthForBorrower;
        uint256 premiumGrowthForLender;
        uint256 fee0Growth;
        uint256 fee1Growth;
        uint256 lastTouchedTimestamp;
    }

    struct LPTState {
        bool isCollateral;
        bytes32 rangeId;
        uint128 liquidityAmount;
        uint256 premiumGrowthLast;
        uint256 fee0Last;
        uint256 fee1Last;
    }

    struct SubVault {
        uint256 id;
        BaseToken.AccountState balance0;
        BaseToken.AccountState balance1;
        LPTState[] lpts;
    }

    struct Vault {
        uint256 vaultId;
        int256 marginAmount0;
        int256 marginAmount1;
        uint256[] subVaults;
    }

    struct Context {
        address token0;
        address token1;
        uint24 feeTier;
        address swapRouter;
        address uniswapPool;
        address chainlinkPriceFeed;
        bool isMarginZero;
        uint256 nextSubVaultId;
        BaseToken.TokenState tokenState0;
        BaseToken.TokenState tokenState1;
        uint256 accumulatedProtocolFee0;
        uint256 accumulatedProtocolFee1;
    }

    // Parameters

    struct InitializationParams {
        uint24 feeTier;
        address token0;
        address token1;
        bool isMarginZero;
    }

    struct LPT {
        bool isCollateral;
        uint128 liquidity;
        int24 lowerTick;
        int24 upperTick;
    }

    struct Position {
        uint256 subVaultId;
        uint256 asset0;
        uint256 asset1;
        uint256 debt0;
        uint256 debt1;
        LPT[] lpts;
    }

    enum PositionUpdateType {
        NOOP,
        DEPOSIT_TOKEN,
        WITHDRAW_TOKEN,
        BORROW_TOKEN,
        REPAY_TOKEN,
        DEPOSIT_LPT,
        WITHDRAW_LPT,
        BORROW_LPT,
        REPAY_LPT,
        SWAP_EXACT_IN,
        SWAP_EXACT_OUT
    }

    struct PositionUpdate {
        PositionUpdateType positionUpdateType;
        uint256 subVaultId;
        bool zeroForOne;
        uint128 liquidity;
        int24 lowerTick;
        int24 upperTick;
        uint256 param0;
        uint256 param1;
    }

    struct TradeOption {
        bool isLiquidationCall;
        bool swapAnyway;
        bool quoterMode;
        bool isQuoteZero;
        uint8 marginMode0;
        uint8 marginMode1;
        int256 deltaMarginAmount0;
        int256 deltaMarginAmount1;
        bytes metadata;
    }

    struct OpenPositionOption {
        uint256 lowerSqrtPrice;
        uint256 upperSqrtPrice;
        uint256 swapRatio;
        uint256 deadline;
    }

    struct ClosePositionOption {
        uint256 lowerSqrtPrice;
        uint256 upperSqrtPrice;
        uint256 swapRatio;
        uint256 closeRatio;
        uint256 deadline;
    }

    struct LiquidationOption {
        uint256 swapRatio;
        uint256 closeRatio;
    }

    struct SubVaultValue {
        uint256 assetValue;
        uint256 debtValue;
        int256 premiumValue;
    }

    struct SubVaultAmount {
        uint256 assetAmount0;
        uint256 assetAmount1;
        uint256 debtAmount0;
        uint256 debtAmount1;
    }

    struct SubVaultInterest {
        int256 assetFee0;
        int256 assetFee1;
        int256 debtFee0;
        int256 debtFee1;
    }

    struct SubVaultPremium {
        uint256 receivedTradeAmount0;
        uint256 receivedTradeAmount1;
        uint256 receivedPremium;
        uint256 paidPremium;
    }

    struct SubVaultStatus {
        SubVaultValue values;
        SubVaultAmount amount;
        SubVaultInterest interest;
        SubVaultPremium premium;
    }

    struct VaultStatus {
        int256 positionValue;
        int256 marginValue;
        int256 minCollateral;
        SubVaultStatus[] subVaults;
    }

    struct TokenAmounts {
        int256 amount0;
        int256 amount1;
    }

    struct SubVaultTokenAmounts {
        uint256 subVaultId;
        int256 amount0;
        int256 amount1;
    }

    struct PositionUpdateResult {
        TokenAmounts requiredAmounts;
        TokenAmounts feeAmounts;
        TokenAmounts positionAmounts;
        TokenAmounts swapAmounts;
        SubVaultTokenAmounts[] subVaultsFeeAmounts;
        SubVaultTokenAmounts[] subVaultsPositionAmounts;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;
pragma abicoder v2;

import "lib/openzeppelin-contracts/contracts/math/SafeMath.sol";
import "lib/openzeppelin-contracts/contracts/math/SignedSafeMath.sol";
import "lib/openzeppelin-contracts/contracts/utils/SafeCast.sol";
import "./PredyMath.sol";
import "./Constants.sol";
import "./PriceHelper.sol";
import "./BaseToken.sol";
import "./DataType.sol";
import "./PositionCalculator.sol";
import "./PositionLib.sol";

/**
 * Error Codes
 * V0: sub-vault not found
 * V1: Exceeds max num of sub-vaults
 */
library VaultLib {
    using SafeMath for uint256;
    using SafeMath for uint128;
    using SignedSafeMath for int256;
    using SafeCast for uint256;
    using BaseToken for BaseToken.TokenState;

    event SubVaultCreated(uint256 indexed vaultId, uint256 subVaultIndex, uint256 subVaultId);
    event SubVaultRemoved(uint256 indexed vaultId, uint256 subVaultIndex, uint256 subVaultId);

    /**
     * @notice add sub-vault to the vault
     * @param _vault vault object
     * @param _subVaults sub-vaults map
     * @param _context context object
     * @param _subVaultId index of sub-vault in the vault to add
     */
    function addSubVault(
        DataType.Vault storage _vault,
        mapping(uint256 => DataType.SubVault) storage _subVaults,
        DataType.Context storage _context,
        uint256 _subVaultId
    ) internal returns (DataType.SubVault storage subVault, uint256 subVaultIndex) {
        if (_subVaultId == 0) {
            require(_vault.subVaults.length < Constants.MAX_NUM_OF_SUBVAULTS, "V1");

            uint256 subVaultId = _context.nextSubVaultId;

            _context.nextSubVaultId += 1;

            subVaultIndex = _vault.subVaults.length;

            _vault.subVaults.push(subVaultId);

            emit SubVaultCreated(_vault.vaultId, subVaultIndex, subVaultId);

            _subVaults[subVaultId].id = subVaultId;

            subVault = _subVaults[subVaultId];
        } else {
            subVaultIndex = getSubVaultIndex(_vault, _subVaultId);

            uint256 subVaultId = _vault.subVaults[subVaultIndex];

            subVault = _subVaults[subVaultId];
        }
    }

    /**
     * @notice remove sub-vault from the vault
     * @param _vault vault object
     * @param _subVaultIndex index of sub-vault in the vault to remove
     */
    function removeSubVault(DataType.Vault storage _vault, uint256 _subVaultIndex) internal {
        require(_subVaultIndex < _vault.subVaults.length, "V0");

        uint256 subVaultId = _vault.subVaults[_subVaultIndex];

        _vault.subVaults[_subVaultIndex] = _vault.subVaults[_vault.subVaults.length - 1];
        _vault.subVaults.pop();

        emit SubVaultRemoved(_vault.vaultId, _subVaultIndex, subVaultId);
    }

    function getSubVaultIndex(DataType.Vault memory _vault, uint256 _subVaultId) internal pure returns (uint256) {
        uint256 subVaultIndex = type(uint256).max;

        for (uint256 i = 0; i < _vault.subVaults.length; i++) {
            if (_vault.subVaults[i] == _subVaultId) {
                subVaultIndex = i;
                break;
            }
        }

        require(subVaultIndex <= Constants.MAX_NUM_OF_SUBVAULTS, "V0");

        return subVaultIndex;
    }

    function depositLPT(
        DataType.SubVault storage _subVault,
        DataType.PerpStatus memory _range,
        bytes32 _rangeId,
        uint128 _liquidityAmount
    ) internal {
        for (uint256 i = 0; i < _subVault.lpts.length; i++) {
            DataType.LPTState storage lpt = _subVault.lpts[i];

            if (lpt.rangeId == _rangeId && lpt.isCollateral) {
                lpt.premiumGrowthLast = _range.premiumGrowthForLender;

                lpt.fee0Last = _range.fee0Growth;
                lpt.fee1Last = _range.fee1Growth;

                lpt.liquidityAmount = lpt.liquidityAmount.add(_liquidityAmount).toUint128();

                return;
            }
        }

        _subVault.lpts.push(
            DataType.LPTState(
                true,
                _rangeId,
                _liquidityAmount,
                _range.premiumGrowthForLender,
                _range.fee0Growth,
                _range.fee1Growth
            )
        );
    }

    function withdrawLPT(
        DataType.SubVault storage _subVault,
        bytes32 _rangeId,
        uint128 _liquidityAmount
    ) internal returns (uint128 liquidityAmount) {
        for (uint256 i = 0; i < _subVault.lpts.length; i++) {
            DataType.LPTState storage lpt = _subVault.lpts[i];

            if (lpt.rangeId == _rangeId && lpt.isCollateral) {
                liquidityAmount = _liquidityAmount;

                if (_liquidityAmount > lpt.liquidityAmount) {
                    liquidityAmount = lpt.liquidityAmount;
                }

                lpt.liquidityAmount = lpt.liquidityAmount.sub(liquidityAmount).toUint128();

                if (lpt.liquidityAmount == 0) {
                    _subVault.lpts[i] = _subVault.lpts[_subVault.lpts.length - 1];
                    _subVault.lpts.pop();
                }

                return liquidityAmount;
            }
        }
    }

    function borrowLPT(
        DataType.SubVault storage _subVault,
        DataType.PerpStatus memory _range,
        bytes32 _rangeId,
        uint128 _liquidityAmount
    ) internal {
        for (uint256 i = 0; i < _subVault.lpts.length; i++) {
            DataType.LPTState storage lpt = _subVault.lpts[i];

            if (lpt.rangeId == _rangeId && !lpt.isCollateral) {
                lpt.premiumGrowthLast = _range.premiumGrowthForBorrower;

                lpt.liquidityAmount = lpt.liquidityAmount.add(_liquidityAmount).toUint128();

                return;
            }
        }

        _subVault.lpts.push(
            DataType.LPTState(false, _rangeId, _liquidityAmount, _range.premiumGrowthForBorrower, 0, 0)
        );
    }

    function repayLPT(
        DataType.SubVault storage _subVault,
        bytes32 _rangeId,
        uint128 _liquidityAmount
    ) internal returns (uint128 liquidityAmount) {
        for (uint256 i = 0; i < _subVault.lpts.length; i++) {
            DataType.LPTState storage lpt = _subVault.lpts[i];

            if (lpt.rangeId == _rangeId && !lpt.isCollateral) {
                liquidityAmount = _liquidityAmount;

                if (_liquidityAmount > lpt.liquidityAmount) {
                    liquidityAmount = lpt.liquidityAmount;
                }

                lpt.liquidityAmount = lpt.liquidityAmount.sub(liquidityAmount).toUint128();

                if (lpt.liquidityAmount == 0) {
                    _subVault.lpts[i] = _subVault.lpts[_subVault.lpts.length - 1];
                    _subVault.lpts.pop();
                }

                return liquidityAmount;
            }
        }
    }

    function updateEntryPrice(
        uint256 _entryPrice,
        uint256 _position,
        uint256 _tradePrice,
        uint256 _positionTrade
    ) internal pure returns (uint256 newEntryPrice) {
        newEntryPrice = (_entryPrice.mul(_position).add(_tradePrice.mul(_positionTrade))).div(
            _position.add(_positionTrade)
        );
    }

    function calculateProfit(
        uint256 _entryPrice,
        uint256 _tradePrice,
        uint256 _positionTrade,
        uint256 _denominator
    ) internal pure returns (uint256 profit) {
        return _tradePrice.sub(_entryPrice).mul(_positionTrade).div(_denominator);
    }

    function getVaultStatus(
        DataType.Vault memory _vault,
        mapping(uint256 => DataType.SubVault) storage _subVaults,
        mapping(bytes32 => DataType.PerpStatus) storage _ranges,
        DataType.Context memory _context,
        uint160 _sqrtPrice
    ) external view returns (DataType.VaultStatus memory) {
        DataType.SubVaultStatus[] memory subVaultsStatus = new DataType.SubVaultStatus[](_vault.subVaults.length);

        for (uint256 i = 0; i < _vault.subVaults.length; i++) {
            DataType.SubVaultAmount memory statusAmount = getVaultStatusAmount(
                _subVaults[_vault.subVaults[i]],
                _ranges,
                _context,
                _sqrtPrice
            );

            DataType.SubVaultPremium memory subVaultPremium = getVaultStatusPremium(
                _subVaults[_vault.subVaults[i]],
                _ranges
            );

            DataType.SubVaultInterest memory statusInterest = getVaultStatusInterest(
                _subVaults[_vault.subVaults[i]],
                _context
            );

            subVaultsStatus[i] = DataType.SubVaultStatus(
                getVaultStatusValue(statusAmount, statusInterest, subVaultPremium, _sqrtPrice, _context.isMarginZero),
                statusAmount,
                statusInterest,
                subVaultPremium
            );
        }

        PositionCalculator.PositionCalculatorParams memory params = getPositionCalculatorParams(
            _vault,
            _subVaults,
            _ranges,
            _context
        );

        (int256 marginValue, uint256 assetValue, uint256 debtValue) = PositionCalculator
            .calculateCollateralAndDebtValue(params, _sqrtPrice, _context.isMarginZero, false);

        return
            DataType.VaultStatus(
                int256(assetValue).sub(int256(debtValue)),
                marginValue,
                PositionCalculator.calculateMinDeposit(params, _sqrtPrice, _context.isMarginZero),
                subVaultsStatus
            );
    }

    function getMarginAmount(
        DataType.Vault memory _vault,
        mapping(uint256 => DataType.SubVault) storage _subVaults,
        mapping(bytes32 => DataType.PerpStatus) storage _ranges,
        DataType.Context memory _context
    ) internal view returns (int256 marginAmount0, int256 marginAmount1) {
        (int256 fee0, int256 fee1) = getPremiumAndFee(_vault, _subVaults, _ranges, _context);

        marginAmount0 = int256(_vault.marginAmount0).add(fee0);
        marginAmount1 = int256(_vault.marginAmount1).add(fee1);
    }

    function getVaultValue(
        DataType.Context memory _context,
        PositionCalculator.PositionCalculatorParams memory _params,
        uint160 _sqrtPrice
    ) internal pure returns (int256) {
        return PositionCalculator.calculateValue(_params, _sqrtPrice, _context.isMarginZero, false);
    }

    function getVaultStatusValue(
        DataType.SubVaultAmount memory statusAmount,
        DataType.SubVaultInterest memory statusInterest,
        DataType.SubVaultPremium memory statusPremium,
        uint160 _sqrtPrice,
        bool _isMarginZero
    ) internal pure returns (DataType.SubVaultValue memory) {
        int256 fee0 = statusInterest.assetFee0.sub(statusInterest.debtFee0);
        int256 fee1 = statusInterest.assetFee1.sub(statusInterest.debtFee1);

        fee0 = fee0.add(int256(statusPremium.receivedTradeAmount0));
        fee1 = fee1.add(int256(statusPremium.receivedTradeAmount1));

        int256 premium = int256(statusPremium.receivedPremium).sub(int256(statusPremium.paidPremium));

        return
            DataType.SubVaultValue(
                uint256(
                    PriceHelper.getValue(
                        _isMarginZero,
                        _sqrtPrice,
                        int256(statusAmount.assetAmount0),
                        int256(statusAmount.assetAmount1)
                    )
                ),
                uint256(
                    PriceHelper.getValue(
                        _isMarginZero,
                        _sqrtPrice,
                        int256(statusAmount.debtAmount0),
                        int256(statusAmount.debtAmount1)
                    )
                ),
                PriceHelper.getValue(_isMarginZero, _sqrtPrice, fee0, fee1).add(premium)
            );
    }

    function getVaultStatusAmount(
        DataType.SubVault memory _subVault,
        mapping(bytes32 => DataType.PerpStatus) storage _ranges,
        DataType.Context memory _context,
        uint160 _sqrtPrice
    ) internal view returns (DataType.SubVaultAmount memory) {
        (uint256 assetAmount0, uint256 assetAmount1) = getAssetPositionAmounts(
            _subVault,
            _ranges,
            _context,
            _sqrtPrice
        );
        (uint256 debtAmount0, uint256 debtAmount1) = getDebtPositionAmounts(_subVault, _ranges, _context, _sqrtPrice);

        return DataType.SubVaultAmount(assetAmount0, assetAmount1, debtAmount0, debtAmount1);
    }

    function getVaultStatusPremium(
        DataType.SubVault memory _subVault,
        mapping(bytes32 => DataType.PerpStatus) storage _ranges
    ) internal view returns (DataType.SubVaultPremium memory) {
        (uint256 fee0, uint256 fee1) = getEarnedTradeFee(_subVault, _ranges);

        return
            DataType.SubVaultPremium(
                fee0,
                fee1,
                getEarnedDailyPremium(_subVault, _ranges),
                getPaidDailyPremium(_subVault, _ranges)
            );
    }

    function getVaultStatusInterest(DataType.SubVault memory _subVault, DataType.Context memory _context)
        internal
        pure
        returns (DataType.SubVaultInterest memory)
    {
        (int256 assetFee0, int256 assetFee1, int256 debtFee0, int256 debtFee1) = getTokenInterestOfSubVault(
            _subVault,
            _context
        );

        return DataType.SubVaultInterest(assetFee0, assetFee1, debtFee0, debtFee1);
    }

    /**
     * @notice latest asset amounts
     */
    function getAssetPositionAmounts(
        DataType.SubVault memory _subVault,
        mapping(bytes32 => DataType.PerpStatus) storage _ranges,
        DataType.Context memory _context,
        uint160 _sqrtPrice
    ) internal view returns (uint256 totalAmount0, uint256 totalAmount1) {
        totalAmount0 = totalAmount0.add(_context.tokenState0.getAssetValue(_subVault.balance0));
        totalAmount1 = totalAmount1.add(_context.tokenState1.getAssetValue(_subVault.balance1));

        {
            (uint256 amount0, uint256 amount1) = getLPTPositionAmounts(_subVault, _ranges, _sqrtPrice, true);

            totalAmount0 = totalAmount0.add(amount0);
            totalAmount1 = totalAmount1.add(amount1);
        }
    }

    function getDebtPositionAmounts(
        DataType.SubVault memory _subVault,
        mapping(bytes32 => DataType.PerpStatus) storage _ranges,
        DataType.Context memory _context,
        uint160 _sqrtPrice
    ) internal view returns (uint256 totalAmount0, uint256 totalAmount1) {
        totalAmount0 = totalAmount0.add(_context.tokenState0.getDebtValue(_subVault.balance0));
        totalAmount1 = totalAmount1.add(_context.tokenState1.getDebtValue(_subVault.balance1));

        {
            (uint256 amount0, uint256 amount1) = getLPTPositionAmounts(_subVault, _ranges, _sqrtPrice, false);

            totalAmount0 = totalAmount0.add(amount0);
            totalAmount1 = totalAmount1.add(amount1);
        }
    }

    function getLPTPositionAmounts(
        DataType.SubVault memory _subVault,
        mapping(bytes32 => DataType.PerpStatus) storage _ranges,
        uint160 _sqrtPrice,
        bool _isCollateral
    ) internal view returns (uint256 totalAmount0, uint256 totalAmount1) {
        for (uint256 i = 0; i < _subVault.lpts.length; i++) {
            DataType.LPTState memory lpt = _subVault.lpts[i];

            if (_isCollateral != lpt.isCollateral) {
                continue;
            }

            (uint256 amount0, uint256 amount1) = LiquidityAmounts.getAmountsForLiquidity(
                _sqrtPrice,
                TickMath.getSqrtRatioAtTick(_ranges[lpt.rangeId].lowerTick),
                TickMath.getSqrtRatioAtTick(_ranges[lpt.rangeId].upperTick),
                lpt.liquidityAmount
            );

            totalAmount0 = totalAmount0.add(amount0);
            totalAmount1 = totalAmount1.add(amount1);
        }
    }

    function getEarnedTradeFeeForRange(DataType.LPTState memory _lpt, DataType.PerpStatus memory _range)
        internal
        pure
        returns (uint256 totalAmount0, uint256 totalAmount1)
    {
        if (_lpt.isCollateral) {
            totalAmount0 = PredyMath.mulDiv(_range.fee0Growth.sub(_lpt.fee0Last), _lpt.liquidityAmount, Constants.ONE);
            totalAmount1 = PredyMath.mulDiv(_range.fee1Growth.sub(_lpt.fee1Last), _lpt.liquidityAmount, Constants.ONE);
        }
    }

    function getEarnedTradeFee(
        DataType.SubVault memory _subVault,
        mapping(bytes32 => DataType.PerpStatus) storage ranges
    ) public view returns (uint256 totalFeeAmount0, uint256 totalFeeAmount1) {
        for (uint256 i = 0; i < _subVault.lpts.length; i++) {
            bytes32 rangeId = _subVault.lpts[i].rangeId;

            (uint256 tradeFee0, uint256 tradeFee1) = getEarnedTradeFeeForRange(_subVault.lpts[i], ranges[rangeId]);

            totalFeeAmount0 = totalFeeAmount0.add(tradeFee0);
            totalFeeAmount1 = totalFeeAmount1.add(tradeFee1);
        }
    }

    function getEarnedDailyPremium(
        DataType.SubVault memory _subVault,
        mapping(bytes32 => DataType.PerpStatus) storage ranges
    ) public view returns (uint256 marginValue) {
        for (uint256 i = 0; i < _subVault.lpts.length; i++) {
            bytes32 rangeId = _subVault.lpts[i].rangeId;
            DataType.PerpStatus memory perpStatus = ranges[rangeId];

            if (!_subVault.lpts[i].isCollateral) {
                continue;
            }

            marginValue = marginValue.add(
                PredyMath.mulDiv(
                    perpStatus.premiumGrowthForLender.sub(_subVault.lpts[i].premiumGrowthLast),
                    _subVault.lpts[i].liquidityAmount,
                    Constants.ONE
                )
            );
        }
    }

    function getPaidDailyPremium(
        DataType.SubVault memory _subVault,
        mapping(bytes32 => DataType.PerpStatus) storage ranges
    ) public view returns (uint256 marginValue) {
        for (uint256 i = 0; i < _subVault.lpts.length; i++) {
            bytes32 rangeId = _subVault.lpts[i].rangeId;
            DataType.PerpStatus memory perpStatus = ranges[rangeId];

            if (_subVault.lpts[i].isCollateral) {
                continue;
            }

            marginValue = marginValue.add(
                PredyMath.mulDiv(
                    perpStatus.premiumGrowthForBorrower.sub(_subVault.lpts[i].premiumGrowthLast),
                    _subVault.lpts[i].liquidityAmount,
                    Constants.ONE
                )
            );
        }
    }

    function getPremiumAndFee(
        DataType.Vault memory _vault,
        mapping(uint256 => DataType.SubVault) storage _subVaults,
        mapping(bytes32 => DataType.PerpStatus) storage _ranges,
        DataType.Context memory _context
    ) internal view returns (int256 totalFee0, int256 totalFee1) {
        for (uint256 i = 0; i < _vault.subVaults.length; i++) {
            DataType.SubVault memory subVault = _subVaults[_vault.subVaults[i]];

            (int256 fee0, int256 fee1) = getPremiumAndFeeOfSubVault(subVault, _ranges, _context);
            (int256 assetFee0, int256 assetFee1, int256 debtFee0, int256 debtFee1) = getTokenInterestOfSubVault(
                subVault,
                _context
            );

            totalFee0 = totalFee0.add(fee0.add(assetFee0).sub(debtFee0));
            totalFee1 = totalFee1.add(fee1.add(assetFee1).sub(debtFee1));
        }
    }

    function getPremiumAndFeeOfSubVault(
        DataType.SubVault memory _subVault,
        mapping(bytes32 => DataType.PerpStatus) storage _ranges,
        DataType.Context memory _context
    ) internal view returns (int256 totalFee0, int256 totalFee1) {
        (uint256 fee0, uint256 fee1) = getEarnedTradeFee(_subVault, _ranges);

        totalFee0 = totalFee0.add(int256(fee0));
        totalFee1 = totalFee1.add(int256(fee1));

        if (_context.isMarginZero) {
            totalFee0 = totalFee0.add(int256(getEarnedDailyPremium(_subVault, _ranges)));
            totalFee0 = totalFee0.sub(int256(getPaidDailyPremium(_subVault, _ranges)));
        } else {
            totalFee1 = totalFee1.add(int256(getEarnedDailyPremium(_subVault, _ranges)));
            totalFee1 = totalFee1.sub(int256(getPaidDailyPremium(_subVault, _ranges)));
        }
    }

    function getTokenInterestOfSubVault(DataType.SubVault memory _subVault, DataType.Context memory _context)
        internal
        pure
        returns (
            int256 assetFee0,
            int256 assetFee1,
            int256 debtFee0,
            int256 debtFee1
        )
    {
        assetFee0 = int256(_context.tokenState0.getAssetFee(_subVault.balance0));
        assetFee1 = int256(_context.tokenState1.getAssetFee(_subVault.balance1));
        debtFee0 = int256(_context.tokenState0.getDebtFee(_subVault.balance0));
        debtFee1 = int256(_context.tokenState1.getDebtFee(_subVault.balance1));
    }

    function getPositionOfSubVault(
        DataType.SubVault memory _subVault,
        mapping(bytes32 => DataType.PerpStatus) storage _ranges,
        DataType.Context memory _context
    ) internal view returns (DataType.Position memory position) {
        DataType.LPT[] memory lpts = new DataType.LPT[](_subVault.lpts.length);

        for (uint256 i = 0; i < _subVault.lpts.length; i++) {
            bytes32 rangeId = _subVault.lpts[i].rangeId;
            DataType.PerpStatus memory range = _ranges[rangeId];
            lpts[i] = DataType.LPT(
                _subVault.lpts[i].isCollateral,
                _subVault.lpts[i].liquidityAmount,
                range.lowerTick,
                range.upperTick
            );
        }

        position = DataType.Position(
            _subVault.id,
            _context.tokenState0.getAssetValue(_subVault.balance0),
            _context.tokenState1.getAssetValue(_subVault.balance1),
            _context.tokenState0.getDebtValue(_subVault.balance0),
            _context.tokenState1.getDebtValue(_subVault.balance1),
            lpts
        );
    }

    function getPositions(
        DataType.Vault memory _vault,
        mapping(uint256 => DataType.SubVault) storage _subVaults,
        mapping(bytes32 => DataType.PerpStatus) storage _ranges,
        DataType.Context memory _context
    ) internal view returns (DataType.Position[] memory positions) {
        positions = new DataType.Position[](_vault.subVaults.length);

        for (uint256 i = 0; i < _vault.subVaults.length; i++) {
            positions[i] = getPositionOfSubVault(_subVaults[_vault.subVaults[i]], _ranges, _context);
        }
    }

    function getPosition(
        DataType.Vault memory _vault,
        mapping(uint256 => DataType.SubVault) storage _subVaults,
        mapping(bytes32 => DataType.PerpStatus) storage _ranges,
        DataType.Context memory _context
    ) internal view returns (DataType.Position memory position) {
        return PositionLib.concat(VaultLib.getPositions(_vault, _subVaults, _ranges, _context));
    }

    function getPositionCalculatorParams(
        DataType.Vault memory _vault,
        mapping(uint256 => DataType.SubVault) storage _subVaults,
        mapping(bytes32 => DataType.PerpStatus) storage _ranges,
        DataType.Context memory _context
    ) public view returns (PositionCalculator.PositionCalculatorParams memory params) {
        {
            DataType.Position memory position = getPosition(_vault, _subVaults, _ranges, _context);
            params.asset0 = position.asset0;
            params.asset1 = position.asset1;
            params.debt0 = position.debt0;
            params.debt1 = position.debt1;
            params.lpts = position.lpts;
        }

        (params.marginAmount0, params.marginAmount1) = getMarginAmount(_vault, _subVaults, _ranges, _context);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.4.0 <0.8.0;

import "lib/openzeppelin-contracts/contracts/math/SafeMath.sol";

library PredyMath {
    using SafeMath for uint256;

    /**
     * @dev https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    /**
     * @dev https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol
     */
    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    /**
     * @dev https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol
     */
    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? b : a;
    }

    function subReward(int256 a, uint256 b) internal pure returns (int256, uint256) {
        if (a >= int256(b)) {
            return (a - int256(b), b);
        } else if (a >= 0) {
            return (0, uint256(a));
        } else {
            return (a, 0);
        }
    }

    function addDelta(uint256 x, int256 y) internal pure returns (uint256 z) {
        if (y < 0) {
            require((z = x - uint256(-y)) < x, "LS");
        } else {
            require((z = x + uint256(y)) >= x, "LA");
        }
    }

    function abs(int256 x) internal pure returns (uint256) {
        return uint256(x >= 0 ? x : -x);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma abicoder v2;

import "lib/openzeppelin-contracts/contracts/math/SafeMath.sol";
import "lib/openzeppelin-contracts/contracts/math/SignedSafeMath.sol";
import "lib/openzeppelin-contracts/contracts/utils/SafeCast.sol";
import "lib/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "lib/v3-periphery/contracts/libraries/PositionKey.sol";
import "./BaseToken.sol";
import "./Constants.sol";
import "./DataType.sol";
import "./VaultLib.sol";
import "./InterestCalculator.sol";
import "./LPTStateLib.sol";
import "./UniHelper.sol";

/*
 * Error Codes
 * PU1: reduce only
 * PU2: margin must not be negative
 * PU3: amount must not be 0
 */
library PositionUpdater {
    using SafeMath for uint256;
    using SafeMath for uint128;
    using SignedSafeMath for int256;
    using SafeCast for uint256;
    using SafeCast for uint128;
    using SafeCast for int256;
    using BaseToken for BaseToken.TokenState;
    using VaultLib for DataType.Vault;
    using VaultLib for DataType.SubVault;
    using LPTStateLib for DataType.PerpStatus;

    event TokenDeposited(uint256 indexed subVaultId, uint256 amount0, uint256 amount1);
    event TokenWithdrawn(uint256 indexed subVaultId, uint256 amount0, uint256 amount1);
    event TokenBorrowed(uint256 indexed subVaultId, uint256 amount0, uint256 amount1);
    event TokenRepaid(uint256 indexed subVaultId, uint256 amount0, uint256 amount1);
    event LPTDeposited(
        uint256 indexed subVaultId,
        bytes32 rangeId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );
    event LPTWithdrawn(
        uint256 indexed subVaultId,
        bytes32 rangeId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );
    event LPTBorrowed(uint256 indexed subVaultId, bytes32 rangeId, uint128 liquidity, uint256 amount0, uint256 amount1);
    event LPTRepaid(uint256 indexed subVaultId, bytes32 rangeId, uint128 liquidity, uint256 amount0, uint256 amount1);
    event FeeUpdated(uint256 indexed subVaultId, int256 fee0, int256 fee1);
    event TokenSwap(
        uint256 indexed vaultId,
        uint256 subVaultId,
        bool zeroForOne,
        uint256 srcAmount,
        uint256 destAmount
    );
    event MarginUpdated(uint256 indexed vaultId, int256 marginAmount0, int256 marginAmount1);
    event PositionUpdated(uint256 vaultId, DataType.PositionUpdateResult positionUpdateResult, bytes metadata);

    /**
     * @notice update position and return required token amounts.
     */
    function updatePosition(
        DataType.Vault storage _vault,
        mapping(uint256 => DataType.SubVault) storage _subVaults,
        DataType.Context storage _context,
        mapping(bytes32 => DataType.PerpStatus) storage _ranges,
        DataType.PositionUpdate[] memory _positionUpdates,
        DataType.TradeOption memory _tradeOption
    ) external returns (DataType.PositionUpdateResult memory result) {
        (result.feeAmounts, result.subVaultsFeeAmounts) = collectFee(_context, _vault, _subVaults, _ranges);

        (result.positionAmounts, result.swapAmounts, result.subVaultsPositionAmounts) = updateVaultPosition(
            _vault,
            _subVaults,
            _context,
            _ranges,
            _positionUpdates,
            _tradeOption
        );

        if ((result.swapAmounts.amount0 != 0 || result.swapAmounts.amount1 != 0)) {
            _tradeOption.swapAnyway = true;
        }

        if (_tradeOption.swapAnyway) {
            result.requiredAmounts.amount0 = result.feeAmounts.amount0.add(result.positionAmounts.amount0).add(
                result.swapAmounts.amount0
            );
            result.requiredAmounts.amount1 = result.feeAmounts.amount1.add(result.positionAmounts.amount1).add(
                result.swapAmounts.amount1
            );

            DataType.PositionUpdate memory positionUpdate = swapAnyway(
                result.requiredAmounts.amount0,
                result.requiredAmounts.amount1,
                _tradeOption.isQuoteZero,
                _context.feeTier
            );
            int256 amount0;
            int256 amount1;

            if (positionUpdate.positionUpdateType == DataType.PositionUpdateType.SWAP_EXACT_IN) {
                (amount0, amount1) = swapExactIn(_vault, _context, positionUpdate);
            } else if (positionUpdate.positionUpdateType == DataType.PositionUpdateType.SWAP_EXACT_OUT) {
                (amount0, amount1) = swapExactOut(_vault, _context, positionUpdate);
            }

            result.swapAmounts.amount0 = result.swapAmounts.amount0.add(amount0);
            result.swapAmounts.amount1 = result.swapAmounts.amount1.add(amount1);
        }

        {
            result.feeAmounts.amount0 = 0;
            result.feeAmounts.amount1 = 0;
            result.positionAmounts.amount0 = 0;
            result.positionAmounts.amount1 = 0;

            (result.feeAmounts, result.subVaultsFeeAmounts) = recomputeAmounts(
                _context,
                result.subVaultsFeeAmounts,
                result.swapAmounts,
                _tradeOption.isQuoteZero
            );

            (result.positionAmounts, result.subVaultsPositionAmounts) = recomputeAmounts(
                _context,
                result.subVaultsPositionAmounts,
                result.swapAmounts,
                _tradeOption.isQuoteZero
            );
        }

        result.requiredAmounts.amount0 = result.feeAmounts.amount0.add(result.positionAmounts.amount0);
        result.requiredAmounts.amount1 = result.feeAmounts.amount1.add(result.positionAmounts.amount1);

        (result.requiredAmounts.amount0, result.requiredAmounts.amount1) = updateMargin(
            _vault,
            _tradeOption,
            result.requiredAmounts
        );

        if (!_tradeOption.isLiquidationCall) {
            require(_vault.marginAmount0 >= 0 && _vault.marginAmount1 >= 0, "PU2");
        }

        // remove empty sub-vaults
        if (_vault.subVaults.length > 0) {
            uint256 length = _vault.subVaults.length;
            for (uint256 i = 0; i < length; i++) {
                uint256 index = length - i - 1;
                DataType.SubVault memory subVault = _subVaults[_vault.subVaults[index]];

                if (
                    subVault.balance0.assetAmount == 0 &&
                    subVault.balance0.debtAmount == 0 &&
                    subVault.balance1.assetAmount == 0 &&
                    subVault.balance1.debtAmount == 0 &&
                    subVault.lpts.length == 0
                ) {
                    _vault.removeSubVault(index);
                }
            }
        }

        emit PositionUpdated(_vault.vaultId, result, _tradeOption.metadata);
    }

    function recomputeAmounts(
        DataType.Context storage _context,
        DataType.SubVaultTokenAmounts[] memory amounts,
        DataType.TokenAmounts memory _swapAmount,
        bool _isQuoteZero
    )
        internal
        returns (DataType.TokenAmounts memory totalAmount, DataType.SubVaultTokenAmounts[] memory resultAmounts)
    {
        resultAmounts = new DataType.SubVaultTokenAmounts[](amounts.length);

        for (uint256 i = 0; i < amounts.length; i++) {
            DataType.SubVaultTokenAmounts memory amount = amounts[i];

            if (_isQuoteZero && _swapAmount.amount1 != 0) {
                amount.amount0 = amount.amount0.add(
                    _swapAmount.amount0.mul(-1).mul(amount.amount1).div(_swapAmount.amount1)
                );
                amount.amount1 = 0;
            } else if (!_isQuoteZero && _swapAmount.amount0 != 0) {
                amount.amount1 = amount.amount1.add(
                    _swapAmount.amount1.mul(-1).mul(amount.amount0).div(_swapAmount.amount0)
                );
                amount.amount0 = 0;
            }

            if (_context.isMarginZero) {
                int256 roundedAmount = roundMargin(amount.amount0, Constants.MARGIN_ROUNDED_DECIMALS);
                if (roundedAmount > amount.amount0) {
                    _context.accumulatedProtocolFee0 = _context.accumulatedProtocolFee0.add(
                        (roundedAmount - amount.amount0).toUint256()
                    );
                }
                amount.amount0 = roundedAmount;
            } else {
                int256 roundedAmount = roundMargin(amount.amount1, Constants.MARGIN_ROUNDED_DECIMALS);
                if (roundedAmount > amount.amount1) {
                    _context.accumulatedProtocolFee1 = _context.accumulatedProtocolFee1.add(
                        (roundedAmount - amount.amount1).toUint256()
                    );
                }
                amount.amount1 = roundedAmount;
            }

            resultAmounts[i] = amount;

            totalAmount.amount0 = totalAmount.amount0.add(amount.amount0);
            totalAmount.amount1 = totalAmount.amount1.add(amount.amount1);
        }
    }

    function roundMargin(int256 _amount, uint256 _roundedDecimals) internal pure returns (int256) {
        if (_amount > 0) {
            return int256(PredyMath.mulDivUp(uint256(_amount), 1, _roundedDecimals).mul(_roundedDecimals));
        } else {
            return -int256(PredyMath.mulDiv(uint256(-_amount), 1, _roundedDecimals).mul(_roundedDecimals));
        }
    }

    function updateVaultPosition(
        DataType.Vault storage _vault,
        mapping(uint256 => DataType.SubVault) storage _subVaults,
        DataType.Context storage _context,
        mapping(bytes32 => DataType.PerpStatus) storage _ranges,
        DataType.PositionUpdate[] memory _positionUpdates,
        DataType.TradeOption memory _tradeOption
    )
        internal
        returns (
            DataType.TokenAmounts memory totalPositionAmounts,
            DataType.TokenAmounts memory totalSwapAmount,
            DataType.SubVaultTokenAmounts[] memory positionAmounts
        )
    {
        // reserve space for new sub-vault index
        positionAmounts = new DataType.SubVaultTokenAmounts[](_vault.subVaults.length + 1);

        uint256 newSubVaultId = 0;

        for (uint256 i = 0; i < _positionUpdates.length; i++) {
            DataType.SubVault storage subVault;
            uint256 subVaultIndex;

            // create new sub-vault if needed
            (subVault, subVaultIndex, newSubVaultId) = createOrGetSubVault(
                _vault,
                _subVaults,
                _context,
                _positionUpdates[i].subVaultId,
                newSubVaultId
            );

            (DataType.TokenAmounts memory positionAmount, DataType.TokenAmounts memory swapAmount) = updateSubVault(
                _vault,
                subVault,
                _context,
                _ranges,
                _positionUpdates[i],
                _tradeOption
            );

            positionAmounts[subVaultIndex].subVaultId = subVault.id;
            positionAmounts[subVaultIndex].amount0 = positionAmounts[subVaultIndex].amount0.add(positionAmount.amount0);
            positionAmounts[subVaultIndex].amount1 = positionAmounts[subVaultIndex].amount1.add(positionAmount.amount1);

            totalPositionAmounts.amount0 = totalPositionAmounts.amount0.add(positionAmount.amount0);
            totalPositionAmounts.amount1 = totalPositionAmounts.amount1.add(positionAmount.amount1);

            totalSwapAmount.amount0 = totalSwapAmount.amount0.add(swapAmount.amount0);
            totalSwapAmount.amount1 = totalSwapAmount.amount1.add(swapAmount.amount1);
        }
    }

    function createOrGetSubVault(
        DataType.Vault storage _vault,
        mapping(uint256 => DataType.SubVault) storage _subVaults,
        DataType.Context storage _context,
        uint256 _subVaultId,
        uint256 _newSubVaultId
    )
        internal
        returns (
            DataType.SubVault storage subVault,
            uint256 subVaultIndex,
            uint256 newSubVaultId
        )
    {
        (subVault, subVaultIndex) = _vault.addSubVault(
            _subVaults,
            _context,
            _subVaultId > 0 ? _subVaultId : _newSubVaultId
        );

        if (_newSubVaultId == 0 && _subVaultId == 0) {
            newSubVaultId = subVault.id;
        } else {
            newSubVaultId = _newSubVaultId;
        }
    }

    function updateSubVault(
        DataType.Vault storage _vault,
        DataType.SubVault storage _subVault,
        DataType.Context storage _context,
        mapping(bytes32 => DataType.PerpStatus) storage _ranges,
        DataType.PositionUpdate memory positionUpdate,
        DataType.TradeOption memory _tradeOption
    ) internal returns (DataType.TokenAmounts memory positionAmounts, DataType.TokenAmounts memory swapAmounts) {
        if (positionUpdate.positionUpdateType == DataType.PositionUpdateType.DEPOSIT_TOKEN) {
            require(!_tradeOption.isLiquidationCall, "PU1");

            depositTokens(_subVault, _context, positionUpdate);

            positionAmounts.amount0 = positionAmounts.amount0.add(int256(positionUpdate.param0));
            positionAmounts.amount1 = positionAmounts.amount1.add(int256(positionUpdate.param1));
        } else if (positionUpdate.positionUpdateType == DataType.PositionUpdateType.WITHDRAW_TOKEN) {
            (uint256 amount0, uint256 amount1) = withdrawTokens(_subVault, _context, positionUpdate);

            positionAmounts.amount0 = positionAmounts.amount0.sub(int256(amount0));
            positionAmounts.amount1 = positionAmounts.amount1.sub(int256(amount1));
        } else if (positionUpdate.positionUpdateType == DataType.PositionUpdateType.BORROW_TOKEN) {
            require(!_tradeOption.isLiquidationCall, "PU1");

            borrowTokens(_subVault, _context, positionUpdate);

            positionAmounts.amount0 = positionAmounts.amount0.sub(int256(positionUpdate.param0));
            positionAmounts.amount1 = positionAmounts.amount1.sub(int256(positionUpdate.param1));
        } else if (positionUpdate.positionUpdateType == DataType.PositionUpdateType.REPAY_TOKEN) {
            (uint256 amount0, uint256 amount1) = repayTokens(_subVault, _context, positionUpdate);

            positionAmounts.amount0 = positionAmounts.amount0.add(int256(amount0));
            positionAmounts.amount1 = positionAmounts.amount1.add(int256(amount1));
        } else if (positionUpdate.positionUpdateType == DataType.PositionUpdateType.DEPOSIT_LPT) {
            require(!_tradeOption.isLiquidationCall, "PU1");

            (uint256 amount0, uint256 amount1) = depositLPT(_subVault, _context, _ranges, positionUpdate);

            positionAmounts.amount0 = positionAmounts.amount0.add(int256(amount0));
            positionAmounts.amount1 = positionAmounts.amount1.add(int256(amount1));
        } else if (positionUpdate.positionUpdateType == DataType.PositionUpdateType.WITHDRAW_LPT) {
            (uint256 amount0, uint256 amount1) = withdrawLPT(_subVault, _context, _ranges, positionUpdate);

            positionAmounts.amount0 = positionAmounts.amount0.sub(int256(amount0));
            positionAmounts.amount1 = positionAmounts.amount1.sub(int256(amount1));
        } else if (positionUpdate.positionUpdateType == DataType.PositionUpdateType.BORROW_LPT) {
            require(!_tradeOption.isLiquidationCall, "PU1");

            (uint256 amount0, uint256 amount1) = borrowLPT(_subVault, _context, _ranges, positionUpdate);

            positionAmounts.amount0 = positionAmounts.amount0.sub(int256(amount0));
            positionAmounts.amount1 = positionAmounts.amount1.sub(int256(amount1));
        } else if (positionUpdate.positionUpdateType == DataType.PositionUpdateType.REPAY_LPT) {
            (uint256 amount0, uint256 amount1) = repayLPT(_subVault, _context, _ranges, positionUpdate);

            positionAmounts.amount0 = positionAmounts.amount0.add(int256(amount0));
            positionAmounts.amount1 = positionAmounts.amount1.add(int256(amount1));
        } else if (positionUpdate.positionUpdateType == DataType.PositionUpdateType.SWAP_EXACT_IN) {
            (int256 amount0, int256 amount1) = swapExactIn(_vault, _context, positionUpdate);

            swapAmounts.amount0 = swapAmounts.amount0.add(amount0);
            swapAmounts.amount1 = swapAmounts.amount1.add(amount1);
        } else if (positionUpdate.positionUpdateType == DataType.PositionUpdateType.SWAP_EXACT_OUT) {
            (int256 amount0, int256 amount1) = swapExactOut(_vault, _context, positionUpdate);

            swapAmounts.amount0 = swapAmounts.amount0.add(amount0);
            swapAmounts.amount1 = swapAmounts.amount1.add(amount1);
        }
    }

    function swapAnyway(
        int256 requiredAmount0,
        int256 requiredAmount1,
        bool _isQuoteZero,
        uint24 _feeTier
    ) internal pure returns (DataType.PositionUpdate memory) {
        bool zeroForOne;
        bool isExactIn;
        uint256 amountIn;
        uint256 amountOut;

        if (_isQuoteZero) {
            if (requiredAmount1 > 0) {
                zeroForOne = true;
                isExactIn = false;
                amountOut = uint256(requiredAmount1);
            } else if (requiredAmount1 < 0) {
                zeroForOne = false;
                isExactIn = true;
                amountIn = uint256(-requiredAmount1);
            }
        } else {
            if (requiredAmount0 > 0) {
                zeroForOne = false;
                isExactIn = false;
                amountOut = uint256(requiredAmount0);
            } else if (requiredAmount0 < 0) {
                zeroForOne = true;
                isExactIn = true;
                amountIn = uint256(-requiredAmount0);
            }
        }

        if (isExactIn && amountIn > 0) {
            return
                DataType.PositionUpdate(
                    DataType.PositionUpdateType.SWAP_EXACT_IN,
                    0,
                    zeroForOne,
                    _feeTier,
                    0,
                    0,
                    amountIn,
                    0
                );
        } else if (!isExactIn && amountOut > 0) {
            return
                DataType.PositionUpdate(
                    DataType.PositionUpdateType.SWAP_EXACT_OUT,
                    0,
                    zeroForOne,
                    _feeTier,
                    0,
                    0,
                    amountOut,
                    0
                );
        } else {
            return DataType.PositionUpdate(DataType.PositionUpdateType.NOOP, 0, false, 0, 0, 0, 0, 0);
        }
    }

    /**
     * @notice Updates margin amounts to open position, close position, deposit and withdraw.
     * If isLiquidationCall is true, margin amounts can be negative value.
     * margin mode:
     * - MARGIN_USE means margin amount will be updated.
     * - MARGIN_STAY means margin amount will be never updated.
     */
    function updateMargin(
        DataType.Vault storage _vault,
        DataType.TradeOption memory _tradeOption,
        DataType.TokenAmounts memory _requiredAmounts
    ) internal returns (int256 newRequiredAmount0, int256 newRequiredAmount1) {
        int256 deltaMarginAmount0;
        int256 deltaMarginAmount1;

        if (_tradeOption.marginMode0 == Constants.MARGIN_USE) {
            deltaMarginAmount0 = _tradeOption.deltaMarginAmount0.sub(_requiredAmounts.amount0);

            if (!_tradeOption.isLiquidationCall && _vault.marginAmount0.add(deltaMarginAmount0) < 0) {
                deltaMarginAmount0 = _vault.marginAmount0.mul(-1);
            }

            _vault.marginAmount0 = _vault.marginAmount0.add(deltaMarginAmount0);

            newRequiredAmount0 = deltaMarginAmount0.add(_requiredAmounts.amount0);

            require(_tradeOption.deltaMarginAmount0 != 0 || newRequiredAmount0 == 0, "PU2");
        } else {
            newRequiredAmount0 = _requiredAmounts.amount0;
        }

        if (_tradeOption.marginMode1 == Constants.MARGIN_USE) {
            deltaMarginAmount1 = _tradeOption.deltaMarginAmount1.sub(_requiredAmounts.amount1);

            if (!_tradeOption.isLiquidationCall && _vault.marginAmount1.add(deltaMarginAmount1) < 0) {
                deltaMarginAmount1 = _vault.marginAmount1.mul(-1);
            }

            _vault.marginAmount1 = _vault.marginAmount1.add(deltaMarginAmount1);

            newRequiredAmount1 = deltaMarginAmount1.add(_requiredAmounts.amount1);

            require(_tradeOption.deltaMarginAmount1 != 0 || newRequiredAmount1 == 0, "PU2");
        } else {
            newRequiredAmount1 = _requiredAmounts.amount1;
        }

        // emit event if needed
        if (deltaMarginAmount0 != 0 || deltaMarginAmount1 != 0) {
            emit MarginUpdated(_vault.vaultId, deltaMarginAmount0, deltaMarginAmount1);
        }
    }

    function depositTokens(
        DataType.SubVault storage _subVault,
        DataType.Context storage _context,
        DataType.PositionUpdate memory _positionUpdate
    ) internal {
        require(_positionUpdate.param0 > 0 || _positionUpdate.param1 > 0);
        _context.tokenState0.addAsset(_subVault.balance0, _positionUpdate.param0, _positionUpdate.zeroForOne);
        _context.tokenState1.addAsset(_subVault.balance1, _positionUpdate.param1, _positionUpdate.zeroForOne);

        emit TokenDeposited(_subVault.id, _positionUpdate.param0, _positionUpdate.param1);
    }

    function withdrawTokens(
        DataType.SubVault storage _subVault,
        DataType.Context storage _context,
        DataType.PositionUpdate memory _positionUpdate
    ) internal returns (uint256 withdrawAmount0, uint256 withdrawAmount1) {
        require(_positionUpdate.param0 > 0 || _positionUpdate.param1 > 0);

        withdrawAmount0 = _context.tokenState0.removeAsset(_subVault.balance0, _positionUpdate.param0);
        withdrawAmount1 = _context.tokenState1.removeAsset(_subVault.balance1, _positionUpdate.param1);

        emit TokenWithdrawn(_subVault.id, withdrawAmount0, withdrawAmount1);
    }

    function borrowTokens(
        DataType.SubVault storage _subVault,
        DataType.Context storage _context,
        DataType.PositionUpdate memory _positionUpdate
    ) internal {
        require(_positionUpdate.param0 > 0 || _positionUpdate.param1 > 0);

        _context.tokenState0.addDebt(_subVault.balance0, _positionUpdate.param0, _positionUpdate.zeroForOne);
        _context.tokenState1.addDebt(_subVault.balance1, _positionUpdate.param1, _positionUpdate.zeroForOne);

        emit TokenBorrowed(_subVault.id, _positionUpdate.param0, _positionUpdate.param1);
    }

    function repayTokens(
        DataType.SubVault storage _subVault,
        DataType.Context storage _context,
        DataType.PositionUpdate memory _positionUpdate
    ) internal returns (uint256 requiredAmount0, uint256 requiredAmount1) {
        require(_positionUpdate.param0 > 0 || _positionUpdate.param1 > 0);

        requiredAmount0 = _context.tokenState0.removeDebt(_subVault.balance0, _positionUpdate.param0);
        requiredAmount1 = _context.tokenState1.removeDebt(_subVault.balance1, _positionUpdate.param1);

        emit TokenRepaid(_subVault.id, requiredAmount0, requiredAmount1);
    }

    function depositLPT(
        DataType.SubVault storage _subVault,
        DataType.Context memory _context,
        mapping(bytes32 => DataType.PerpStatus) storage _ranges,
        DataType.PositionUpdate memory _positionUpdate
    ) internal returns (uint256 requiredAmount0, uint256 requiredAmount1) {
        bytes32 rangeId = LPTStateLib.getRangeKey(_positionUpdate.lowerTick, _positionUpdate.upperTick);

        require(_positionUpdate.liquidity > 0, "PU3");

        (requiredAmount0, requiredAmount1) = IUniswapV3Pool(_context.uniswapPool).mint(
            address(this),
            _positionUpdate.lowerTick,
            _positionUpdate.upperTick,
            _positionUpdate.liquidity,
            ""
        );

        if (_ranges[rangeId].lastTouchedTimestamp == 0) {
            _ranges[rangeId].registerNewLPTState(_positionUpdate.lowerTick, _positionUpdate.upperTick);
        }

        _subVault.depositLPT(_ranges[rangeId], rangeId, _positionUpdate.liquidity);

        emit LPTDeposited(_subVault.id, rangeId, _positionUpdate.liquidity, requiredAmount0, requiredAmount1);
    }

    function withdrawLPT(
        DataType.SubVault storage _subVault,
        DataType.Context memory _context,
        mapping(bytes32 => DataType.PerpStatus) storage _ranges,
        DataType.PositionUpdate memory _positionUpdate
    ) internal returns (uint256 withdrawnAmount0, uint256 withdrawnAmount1) {
        bytes32 rangeId = LPTStateLib.getRangeKey(_positionUpdate.lowerTick, _positionUpdate.upperTick);

        uint128 liquidityAmount = _subVault.withdrawLPT(rangeId, _positionUpdate.liquidity);

        (withdrawnAmount0, withdrawnAmount1) = decreaseLiquidityFromUni(_context, _ranges[rangeId], liquidityAmount);

        emit LPTWithdrawn(_subVault.id, rangeId, liquidityAmount, withdrawnAmount0, withdrawnAmount1);
    }

    function borrowLPT(
        DataType.SubVault storage _subVault,
        DataType.Context memory _context,
        mapping(bytes32 => DataType.PerpStatus) storage _ranges,
        DataType.PositionUpdate memory _positionUpdate
    ) internal returns (uint256 borrowedAmount0, uint256 borrowedAmount1) {
        bytes32 rangeId = LPTStateLib.getRangeKey(_positionUpdate.lowerTick, _positionUpdate.upperTick);

        (borrowedAmount0, borrowedAmount1) = decreaseLiquidityFromUni(
            _context,
            _ranges[rangeId],
            _positionUpdate.liquidity
        );

        _ranges[rangeId].borrowedLiquidity = _ranges[rangeId]
            .borrowedLiquidity
            .add(_positionUpdate.liquidity)
            .toUint128();

        _subVault.borrowLPT(_ranges[rangeId], rangeId, _positionUpdate.liquidity);

        emit LPTBorrowed(_subVault.id, rangeId, _positionUpdate.liquidity, borrowedAmount0, borrowedAmount1);
    }

    function repayLPT(
        DataType.SubVault storage _subVault,
        DataType.Context memory _context,
        mapping(bytes32 => DataType.PerpStatus) storage _ranges,
        DataType.PositionUpdate memory _positionUpdate
    ) internal returns (uint256 requiredAmount0, uint256 requiredAmount1) {
        bytes32 rangeId = LPTStateLib.getRangeKey(_positionUpdate.lowerTick, _positionUpdate.upperTick);

        uint128 liquidity = _subVault.repayLPT(rangeId, _positionUpdate.liquidity);

        require(liquidity > 0, "PU3");

        (requiredAmount0, requiredAmount1) = IUniswapV3Pool(_context.uniswapPool).mint(
            address(this),
            _positionUpdate.lowerTick,
            _positionUpdate.upperTick,
            liquidity,
            ""
        );

        _ranges[rangeId].borrowedLiquidity = _ranges[rangeId].borrowedLiquidity.toUint256().sub(liquidity).toUint128();

        emit LPTRepaid(_subVault.id, rangeId, liquidity, requiredAmount0, requiredAmount1);
    }

    function swapExactIn(
        DataType.Vault storage _vault,
        DataType.Context memory _context,
        DataType.PositionUpdate memory _positionUpdate
    ) internal returns (int256 requiredAmount0, int256 requiredAmount1) {
        uint256 amountOut;

        {
            (int256 amount0, int256 amount1) = IUniswapV3Pool(_context.uniswapPool).swap(
                address(this),
                _positionUpdate.zeroForOne,
                int256(_positionUpdate.param0),
                (_positionUpdate.zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1),
                ""
            );

            if (_positionUpdate.zeroForOne) {
                amountOut = (-amount1).toUint256();
            } else {
                amountOut = (-amount0).toUint256();
            }
        }

        emit TokenSwap(_vault.vaultId, 0, _positionUpdate.zeroForOne, _positionUpdate.param0, amountOut);

        if (_positionUpdate.zeroForOne) {
            return (int256(_positionUpdate.param0), -int256(amountOut));
        } else {
            return (-int256(amountOut), int256(_positionUpdate.param0));
        }
    }

    function swapExactOut(
        DataType.Vault storage _vault,
        DataType.Context memory _context,
        DataType.PositionUpdate memory _positionUpdate
    ) internal returns (int256 requiredAmount0, int256 requiredAmount1) {
        uint256 amountIn;

        {
            (int256 amount0, int256 amount1) = IUniswapV3Pool(_context.uniswapPool).swap(
                address(this),
                _positionUpdate.zeroForOne,
                -int256(_positionUpdate.param0),
                (_positionUpdate.zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1),
                ""
            );

            if (_positionUpdate.zeroForOne) {
                amountIn = amount0.toUint256();
            } else {
                amountIn = amount1.toUint256();
            }
        }

        emit TokenSwap(_vault.vaultId, 0, _positionUpdate.zeroForOne, amountIn, _positionUpdate.param0);

        if (_positionUpdate.zeroForOne) {
            return (int256(amountIn), -int256(_positionUpdate.param0));
        } else {
            return (-int256(_positionUpdate.param0), int256(amountIn));
        }
    }

    /**
     * @notice Decreases liquidity from Uniswap pool.
     */
    function decreaseLiquidityFromUni(
        DataType.Context memory _context,
        DataType.PerpStatus storage _range,
        uint128 _liquidity
    ) internal returns (uint256 amount0, uint256 amount1) {
        require(_liquidity > 0, "PU3");
        (amount0, amount1) = IUniswapV3Pool(_context.uniswapPool).burn(_range.lowerTick, _range.upperTick, _liquidity);

        // collect burned token amounts
        IUniswapV3Pool(_context.uniswapPool).collect(
            address(this),
            _range.lowerTick,
            _range.upperTick,
            amount0.toUint128(),
            amount1.toUint128()
        );
    }

    function collectFee(
        DataType.Context memory _context,
        DataType.Vault memory _vault,
        mapping(uint256 => DataType.SubVault) storage _subVaults,
        mapping(bytes32 => DataType.PerpStatus) storage _ranges
    )
        internal
        returns (DataType.TokenAmounts memory totalFeeAmounts, DataType.SubVaultTokenAmounts[] memory feeAmounts)
    {
        feeAmounts = new DataType.SubVaultTokenAmounts[](_vault.subVaults.length);

        for (uint256 i = 0; i < _vault.subVaults.length; i++) {
            DataType.SubVault storage subVault = _subVaults[_vault.subVaults[i]];

            (int256 feeAmount0, int256 feeAmount1) = collectFeeOfSubVault(_context, subVault, _ranges);

            feeAmounts[i].subVaultId = _vault.subVaults[i];
            feeAmounts[i].amount0 = feeAmount0;
            feeAmounts[i].amount1 = feeAmount1;
            totalFeeAmounts.amount0 = totalFeeAmounts.amount0.add(feeAmount0);
            totalFeeAmounts.amount1 = totalFeeAmounts.amount1.add(feeAmount1);
        }
    }

    function collectFeeOfSubVault(
        DataType.Context memory _context,
        DataType.SubVault storage _subVault,
        mapping(bytes32 => DataType.PerpStatus) storage _ranges
    ) internal returns (int256 requiredAmount0, int256 requiredAmount1) {
        int256 totalFee0;
        int256 totalFee1;

        {
            (int256 fee0, int256 fee1) = VaultLib.getPremiumAndFeeOfSubVault(_subVault, _ranges, _context);
            (int256 assetFee0, int256 assetFee1, int256 debtFee0, int256 debtFee1) = VaultLib
                .getTokenInterestOfSubVault(_subVault, _context);

            totalFee0 = fee0.add(assetFee0).sub(debtFee0);
            totalFee1 = fee1.add(assetFee1).sub(debtFee1);
        }

        _context.tokenState0.refreshFee(_subVault.balance0);
        _context.tokenState1.refreshFee(_subVault.balance1);

        for (uint256 i = 0; i < _subVault.lpts.length; i++) {
            DataType.LPTState storage lpt = _subVault.lpts[i];

            if (lpt.isCollateral) {
                lpt.premiumGrowthLast = _ranges[lpt.rangeId].premiumGrowthForLender;
                lpt.fee0Last = _ranges[lpt.rangeId].fee0Growth;
                lpt.fee1Last = _ranges[lpt.rangeId].fee1Growth;
            } else {
                lpt.premiumGrowthLast = _ranges[lpt.rangeId].premiumGrowthForBorrower;
            }
        }

        requiredAmount0 = totalFee0.mul(-1);
        requiredAmount1 = totalFee1.mul(-1);

        emit FeeUpdated(_subVault.id, totalFee0, totalFee1);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;
pragma abicoder v2;

import "lib/openzeppelin-contracts/contracts/math/SafeMath.sol";
import "lib/openzeppelin-contracts/contracts/utils/SafeCast.sol";
import "lib/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "lib/v3-core/contracts/libraries/TickMath.sol";
import "lib/v3-periphery/contracts/libraries/LiquidityAmounts.sol";

import "./DataType.sol";
import "./BaseToken.sol";
import "./PriceHelper.sol";
import "./LPTStateLib.sol";
import "./Constants.sol";

/**
 * @title InterestCalculator library
 * @notice Implements the base logic calculating interest rate and premium.
 */
library InterestCalculator {
    using SafeMath for uint256;
    using SafeCast for uint256;
    using BaseToken for BaseToken.TokenState;

    event InterestScalerUpdated(uint256 assetGrowth0, uint256 debtGrowth0, uint256 assetGrowth1, uint256 debtGrowth1);
    event PremiumGrowthUpdated(
        int24 lowerTick,
        int24 upperTick,
        uint256 premiumGrowthForBorrower,
        uint256 premiumGrowthForLender
    );
    event FeeGrowthUpdated(int24 lowerTick, int24 upperTick, uint256 fee0Growth, uint256 fee1Growth);

    struct TickSnapshot {
        uint256 lastSecondsPerLiquidityInside;
        uint256 lastSecondsPerLiquidity;
    }

    struct TickInfo {
        uint256 feeGrowthOutside0X128;
        uint256 feeGrowthOutside1X128;
    }

    struct YearlyPremiumParams {
        IRMParams premiumParams;
        IRMParams irmParams;
        mapping(bytes32 => TickSnapshot) snapshots;
    }

    struct IRMParams {
        uint256 baseRate;
        uint256 kinkRate;
        uint256 slope1;
        uint256 slope2;
    }

    // update premium growth
    function updatePremiumGrowthForVault(
        DataType.Vault memory _vault,
        mapping(uint256 => DataType.SubVault) storage _subVaults,
        mapping(bytes32 => DataType.PerpStatus) storage _ranges,
        DataType.Context storage _context,
        DataType.PositionUpdate[] memory _positionUpdates,
        YearlyPremiumParams storage _dpmParams,
        uint160 _sqrtPrice
    ) external {
        // calculate fee for ranges that the vault has.
        for (uint256 i = 0; i < _vault.subVaults.length; i++) {
            DataType.SubVault memory subVault = _subVaults[_vault.subVaults[i]];

            for (uint256 j = 0; j < subVault.lpts.length; j++) {
                updatePremiumGrowth(_dpmParams, _context, _ranges[subVault.lpts[j].rangeId], _sqrtPrice);
            }
        }

        // calculate fee for ranges that positionUpdates have.
        for (uint256 i = 0; i < _positionUpdates.length; i++) {
            bytes32 rangeId = LPTStateLib.getRangeKey(_positionUpdates[i].lowerTick, _positionUpdates[i].upperTick);

            // if range is not initialized, skip calculation.
            if (_ranges[rangeId].lastTouchedTimestamp == 0) {
                continue;
            }

            updatePremiumGrowth(_dpmParams, _context, _ranges[rangeId], _sqrtPrice);
        }
    }

    // update scaler for reserves
    function applyInterest(
        DataType.Context storage _context,
        IRMParams memory _irmParams,
        uint256 lastTouchedTimestamp
    ) external returns (uint256) {
        if (block.timestamp <= lastTouchedTimestamp) {
            return lastTouchedTimestamp;
        }

        // calculate interest for tokens
        uint256 interest0 = PredyMath.mulDiv(
            block.timestamp - lastTouchedTimestamp,
            calculateInterestRate(_irmParams, BaseToken.getUtilizationRatio(_context.tokenState0)),
            365 days
        );

        uint256 interest1 = PredyMath.mulDiv(
            block.timestamp - lastTouchedTimestamp,
            calculateInterestRate(_irmParams, BaseToken.getUtilizationRatio(_context.tokenState1)),
            365 days
        );

        _context.accumulatedProtocolFee0 = _context.accumulatedProtocolFee0.add(
            _context.tokenState0.updateScaler(interest0)
        );
        _context.accumulatedProtocolFee1 = _context.accumulatedProtocolFee1.add(
            _context.tokenState1.updateScaler(interest1)
        );

        emit InterestScalerUpdated(
            _context.tokenState0.assetGrowth,
            _context.tokenState0.debtGrowth,
            _context.tokenState1.assetGrowth,
            _context.tokenState1.debtGrowth
        );

        return block.timestamp;
    }

    function updatePremiumGrowth(
        YearlyPremiumParams storage _params,
        DataType.Context storage _context,
        DataType.PerpStatus storage _perpState,
        uint160 _sqrtPrice
    ) public {
        if (block.timestamp <= _perpState.lastTouchedTimestamp) {
            return;
        }

        if (_perpState.borrowedLiquidity > 0) {
            uint256 perpUr = LPTStateLib.getPerpUR(address(this), _context.uniswapPool, _perpState);

            (
                uint256 premiumGrowthForBorrower,
                uint256 premiumGrowthForLender,
                uint256 protocolFeePerLiquidity
            ) = calculateLPTBorrowerAndLenderPremium(
                    _params,
                    _context,
                    _perpState,
                    _sqrtPrice,
                    perpUr,
                    (block.timestamp - _perpState.lastTouchedTimestamp)
                );

            _perpState.premiumGrowthForBorrower = _perpState.premiumGrowthForBorrower.add(premiumGrowthForBorrower);

            _perpState.premiumGrowthForLender = _perpState.premiumGrowthForLender.add(premiumGrowthForLender);

            // accumulate protocol fee
            {
                uint256 protocolFee = PredyMath.mulDiv(
                    protocolFeePerLiquidity,
                    _perpState.borrowedLiquidity,
                    Constants.ONE
                );

                if (_context.isMarginZero) {
                    _context.accumulatedProtocolFee0 = _context.accumulatedProtocolFee0.add(protocolFee);
                } else {
                    _context.accumulatedProtocolFee1 = _context.accumulatedProtocolFee1.add(protocolFee);
                }
            }
        }

        takeSnapshot(_params, IUniswapV3Pool(_context.uniswapPool), _perpState.lowerTick, _perpState.upperTick);

        _perpState.lastTouchedTimestamp = block.timestamp;

        emitPremiumGrowthUpdatedEvent(_perpState);
    }

    function emitPremiumGrowthUpdatedEvent(DataType.PerpStatus memory _perpState) internal {
        emit PremiumGrowthUpdated(
            _perpState.lowerTick,
            _perpState.upperTick,
            _perpState.premiumGrowthForBorrower,
            _perpState.premiumGrowthForLender
        );
    }

    /**
     * @notice Collects trade fee and updates fee growth.
     */
    function updateFeeGrowth(
        DataType.Context memory _context,
        DataType.Vault memory _vault,
        mapping(uint256 => DataType.SubVault) storage _subVaults,
        mapping(bytes32 => DataType.PerpStatus) storage _ranges,
        DataType.PositionUpdate[] memory _positionUpdates
    ) external {
        // calculate trade fee for ranges that the vault has
        for (uint256 i = 0; i < _vault.subVaults.length; i++) {
            DataType.SubVault memory subVault = _subVaults[_vault.subVaults[i]];

            for (uint256 j = 0; j < subVault.lpts.length; j++) {
                updateFeeGrowthForRange(_context, _ranges[subVault.lpts[j].rangeId]);
            }
        }

        // calculate trade fee for ranges that trader would open
        for (uint256 i = 0; i < _positionUpdates.length; i++) {
            bytes32 rangeId = LPTStateLib.getRangeKey(_positionUpdates[i].lowerTick, _positionUpdates[i].upperTick);

            updateFeeGrowthForRange(_context, _ranges[rangeId]);
        }
    }

    function updateFeeGrowthForRange(DataType.Context memory _context, DataType.PerpStatus storage _range) public {
        if (_range.lastTouchedTimestamp == 0) {
            return;
        }

        uint256 totalLiquidity = LPTStateLib.getTotalLiquidityAmount(address(this), _context.uniswapPool, _range);

        if (totalLiquidity == 0) {
            emit FeeGrowthUpdated(_range.lowerTick, _range.upperTick, _range.fee0Growth, _range.fee1Growth);

            return;
        }

        {
            // Skip fee collection if utilization ratio is 100%
            uint256 availableLiquidity = LPTStateLib.getAvailableLiquidityAmount(
                address(this),
                _context.uniswapPool,
                _range
            );

            if (availableLiquidity == 0) {
                return;
            }
        }

        // burn 0 amount of LPT to collect trade fee from Uniswap pool.
        IUniswapV3Pool(_context.uniswapPool).burn(_range.lowerTick, _range.upperTick, 0);

        // collect trade fee
        (uint256 collect0, uint256 collect1) = IUniswapV3Pool(_context.uniswapPool).collect(
            address(this),
            _range.lowerTick,
            _range.upperTick,
            type(uint128).max,
            type(uint128).max
        );

        _range.fee0Growth = _range.fee0Growth.add(PredyMath.mulDiv(collect0, Constants.ONE, totalLiquidity));
        _range.fee1Growth = _range.fee1Growth.add(PredyMath.mulDiv(collect1, Constants.ONE, totalLiquidity));

        emit FeeGrowthUpdated(_range.lowerTick, _range.upperTick, _range.fee0Growth, _range.fee1Growth);
    }

    function calculateLPTBorrowerAndLenderPremium(
        YearlyPremiumParams storage _params,
        DataType.Context memory _context,
        DataType.PerpStatus memory _perpState,
        uint160 _sqrtPrice,
        uint256 _perpUr,
        uint256 _elapsed
    )
        public
        view
        returns (
            uint256 premiumGrowthForBorrower,
            uint256 premiumGrowthForLender,
            uint256 protocolFeePerLiquidity
        )
    {
        premiumGrowthForBorrower = PredyMath.mulDiv(
            _elapsed,
            calculateYearlyPremium(_params, _context, _perpState, _sqrtPrice, _perpUr),
            365 days
        );

        protocolFeePerLiquidity = PredyMath.mulDiv(
            premiumGrowthForBorrower,
            Constants.LPT_RESERVE_FACTOR,
            Constants.ONE
        );

        premiumGrowthForLender = PredyMath.mulDiv(
            premiumGrowthForBorrower.sub(protocolFeePerLiquidity),
            _perpUr,
            Constants.ONE
        );
    }

    function calculateYearlyPremium(
        YearlyPremiumParams storage _params,
        DataType.Context memory _context,
        DataType.PerpStatus memory _perpState,
        uint160 _sqrtPrice,
        uint256 _perpUr
    ) internal view returns (uint256) {
        return
            calculateValueByStableToken(
                _context.isMarginZero,
                calculateRangeVariance(_params, IUniswapV3Pool(_context.uniswapPool), _perpState, _perpUr),
                calculateInterestRate(_params.irmParams, _perpUr),
                _sqrtPrice,
                _perpState.lowerTick,
                _perpState.upperTick
            );
    }

    function calculateValueByStableToken(
        bool _isMarginZero,
        uint256 _variance,
        uint256 _interestRate,
        uint160 _sqrtPrice,
        int24 _lowerTick,
        int24 _upperTick
    ) internal pure returns (uint256 value) {
        (uint256 amount0, uint256 amount1) = LiquidityAmounts.getAmountsForLiquidity(
            _sqrtPrice,
            TickMath.getSqrtRatioAtTick(_lowerTick),
            TickMath.getSqrtRatioAtTick(_upperTick),
            1e18
        );

        value = uint256(PriceHelper.getValue(_isMarginZero, _sqrtPrice, int256(amount0), int256(amount1)));

        // value (usd/liquidity)
        value = value.mul(_interestRate).div(1e18);

        // premium = (value of virtual liquidity) * variance / L
        // where `(value of virtual liquidity) = 2 * L * sqrt{price}` and `L = 1e18`.
        // value per 1 underlying token is `2 * sqrt{price/1e18}`
        // so value for `L=1e18` is `2 * sqrt{price/1e18} * L`
        // then
        // `(value of virtual liquidity) = 2 * sqrt{price/1e18}*1e18 = 2 * sqrt{price * 1e18 / PRICE_SCALER}`
        // Since variance is multiplied by 2 in advance, final formula is below.

        uint256 price = PriceHelper.decodeSqrtPriceX96(_isMarginZero, _sqrtPrice);

        value = value.add((PredyMath.sqrt(price.mul(1e18 / PriceHelper.PRICE_SCALER)).mul(_variance)).div(1e18));
    }

    function calculateRangeVariance(
        YearlyPremiumParams storage _params,
        IUniswapV3Pool uniPool,
        DataType.PerpStatus memory _perpState,
        uint256 _utilizationRatio
    ) internal view returns (uint256) {
        uint256 activeRatio = getRangeActiveRatio(_params, uniPool, _perpState.lowerTick, _perpState.upperTick);

        return calculateInterestRate(_params.premiumParams, _utilizationRatio).mul(activeRatio) / Constants.ONE;
    }

    function getRangeActiveRatio(
        YearlyPremiumParams storage _params,
        IUniswapV3Pool _uniPool,
        int24 _lowerTick,
        int24 _upperTick
    ) internal view returns (uint256) {
        (uint256 secondsPerLiquidityInside, uint256 secondsPerLiquidity) = getSecondsPerLiquidity(
            _uniPool,
            _lowerTick,
            _upperTick
        );

        bytes32 key = keccak256(abi.encodePacked(_lowerTick, _upperTick));

        if (
            secondsPerLiquidityInside <= _params.snapshots[key].lastSecondsPerLiquidityInside ||
            secondsPerLiquidity <= _params.snapshots[key].lastSecondsPerLiquidity
        ) {
            return 0;
        }

        uint256 activeRatio = (secondsPerLiquidityInside - _params.snapshots[key].lastSecondsPerLiquidityInside).mul(
            Constants.ONE
        ) / (secondsPerLiquidity - _params.snapshots[key].lastSecondsPerLiquidity);

        if (activeRatio >= Constants.ONE) {
            return Constants.ONE;
        }

        return activeRatio;
    }

    function takeSnapshot(
        YearlyPremiumParams storage _params,
        IUniswapV3Pool _uniPool,
        int24 _lowerTick,
        int24 _upperTick
    ) internal {
        (uint256 secondsPerLiquidityInside, uint256 secondsPerLiquidity) = getSecondsPerLiquidity(
            _uniPool,
            _lowerTick,
            _upperTick
        );

        bytes32 key = keccak256(abi.encodePacked(_lowerTick, _upperTick));

        _params.snapshots[key].lastSecondsPerLiquidityInside = secondsPerLiquidityInside;
        _params.snapshots[key].lastSecondsPerLiquidity = secondsPerLiquidity;
    }

    function getSecondsPerLiquidity(
        IUniswapV3Pool uniPool,
        int24 _lowerTick,
        int24 _upperTick
    ) internal view returns (uint256 secondsPerLiquidityInside, uint256 secondsPerLiquidity) {
        uint32[] memory secondsAgos = new uint32[](1);

        (, uint160[] memory secondsPerLiquidityCumulativeX128s) = uniPool.observe(secondsAgos);

        secondsPerLiquidity = secondsPerLiquidityCumulativeX128s[0];

        (, , , , , , , bool initializedLower) = uniPool.ticks(_lowerTick);
        (, , , , , , , bool initializedUpper) = uniPool.ticks(_upperTick);

        if (initializedLower && initializedUpper) {
            (, secondsPerLiquidityInside, ) = uniPool.snapshotCumulativesInside(_lowerTick, _upperTick);
        }
    }

    function calculateInterestRate(IRMParams memory _irmParams, uint256 _utilizationRatio)
        internal
        pure
        returns (uint256)
    {
        uint256 ir = _irmParams.baseRate;

        if (_utilizationRatio <= _irmParams.kinkRate) {
            ir += (_utilizationRatio * _irmParams.slope1) / Constants.ONE;
        } else {
            ir += (_irmParams.kinkRate * _irmParams.slope1) / Constants.ONE;
            ir += (_irmParams.slope2 * (_utilizationRatio - _irmParams.kinkRate)) / Constants.ONE;
        }

        return ir;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;
pragma abicoder v2;

import "lib/openzeppelin-contracts/contracts/math/SafeMath.sol";
import "lib/openzeppelin-contracts/contracts/math/SignedSafeMath.sol";
import "lib/openzeppelin-contracts/contracts/utils/SafeCast.sol";
import "lib/v3-periphery/contracts/libraries/LiquidityAmounts.sol";
import "lib/v3-core/contracts/libraries/TickMath.sol";
import "./DataType.sol";

library PositionLib {
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using SafeCast for uint256;

    function getPositionUpdatesToOpen(
        DataType.Position memory _position,
        bool _isQuoteZero,
        uint160 _sqrtPrice,
        uint256 _swapRatio
    ) external pure returns (DataType.PositionUpdate[] memory positionUpdates) {
        require(_swapRatio <= 100, "ISR");
        uint256 swapIndex;

        (positionUpdates, swapIndex) = calculatePositionUpdatesToOpen(_position);

        (int256 requiredAmount0, int256 requiredAmount1) = getRequiredTokenAmountsToOpen(_position, _sqrtPrice);

        if (_swapRatio == 0) {
            return positionUpdates;
        }

        if (_isQuoteZero) {
            if (requiredAmount1 > 0) {
                positionUpdates[swapIndex] = DataType.PositionUpdate(
                    DataType.PositionUpdateType.SWAP_EXACT_OUT,
                    0,
                    true,
                    0,
                    0,
                    0,
                    uint256(requiredAmount1),
                    0
                );
            } else if (requiredAmount1 < 0) {
                positionUpdates[swapIndex] = DataType.PositionUpdate(
                    DataType.PositionUpdateType.SWAP_EXACT_IN,
                    0,
                    false,
                    0,
                    0,
                    0,
                    uint256(-requiredAmount1),
                    0
                );
            }
        } else {
            if (requiredAmount0 > 0) {
                positionUpdates[swapIndex] = DataType.PositionUpdate(
                    DataType.PositionUpdateType.SWAP_EXACT_OUT,
                    0,
                    false,
                    0,
                    0,
                    0,
                    uint256(requiredAmount0),
                    0
                );
            } else if (requiredAmount0 < 0) {
                positionUpdates[swapIndex] = DataType.PositionUpdate(
                    DataType.PositionUpdateType.SWAP_EXACT_IN,
                    0,
                    true,
                    0,
                    0,
                    0,
                    uint256(-requiredAmount0),
                    0
                );
            }
        }
    }

    function getPositionUpdatesToClose(
        DataType.Position[] memory _positions,
        bool _isQuoteZero,
        uint160 _sqrtPrice,
        uint256 _swapRatio,
        uint256 _closeRatio
    ) external pure returns (DataType.PositionUpdate[] memory positionUpdates) {
        require(_swapRatio <= 100, "ISR");
        require(_closeRatio <= 1e4, "ICR");

        uint256 swapIndex;

        (positionUpdates, swapIndex) = calculatePositionUpdatesToClose(_positions, _closeRatio);

        (int256 requiredAmount0, int256 requiredAmount1) = getRequiredTokenAmountsToClose(_positions, _sqrtPrice);

        if (_swapRatio == 0) {
            return positionUpdates;
        }

        if (!_isQuoteZero && requiredAmount0 < 0) {
            positionUpdates[swapIndex] = DataType.PositionUpdate(
                DataType.PositionUpdateType.SWAP_EXACT_IN,
                0,
                true,
                0,
                0,
                0,
                (uint256(-requiredAmount0) * _swapRatio) / 100,
                0
            );
        } else if (_isQuoteZero && requiredAmount1 < 0) {
            positionUpdates[swapIndex] = DataType.PositionUpdate(
                DataType.PositionUpdateType.SWAP_EXACT_IN,
                0,
                false,
                0,
                0,
                0,
                (uint256(-requiredAmount1) * _swapRatio) / 100,
                0
            );
        }
    }

    function concat(DataType.Position[] memory _positions, DataType.Position memory _position)
        internal
        pure
        returns (DataType.Position memory)
    {
        DataType.Position[] memory positions = new DataType.Position[](_positions.length + 1);
        for (uint256 i = 0; i < _positions.length; i++) {
            positions[i] = _positions[i];
        }

        positions[_positions.length] = _position;

        return concat(positions);
    }

    function concat(DataType.Position[] memory _positions) internal pure returns (DataType.Position memory _position) {
        uint256 numLPTs;
        for (uint256 i = 0; i < _positions.length; i++) {
            numLPTs += _positions[i].lpts.length;
        }

        DataType.LPT[] memory lpts = new DataType.LPT[](numLPTs);

        _position = DataType.Position(0, 0, 0, 0, 0, lpts);

        uint256 k;

        for (uint256 i = 0; i < _positions.length; i++) {
            _position.asset0 += _positions[i].asset0;
            _position.asset1 += _positions[i].asset1;
            _position.debt0 += _positions[i].debt0;
            _position.debt1 += _positions[i].debt1;

            for (uint256 j = 0; j < _positions[i].lpts.length; j++) {
                _position.lpts[k] = _positions[i].lpts[j];
                k++;
            }
        }
    }

    function emptyPosition() internal pure returns (DataType.Position memory) {
        DataType.LPT[] memory lpts = new DataType.LPT[](0);
        return DataType.Position(0, 0, 0, 0, 0, lpts);
    }

    /**
     * @notice Calculates required token amounts to open position.
     * @param _destPosition position to open
     * @param _sqrtPrice square root price to calculate
     */
    function getRequiredTokenAmountsToOpen(DataType.Position memory _destPosition, uint160 _sqrtPrice)
        internal
        pure
        returns (int256, int256)
    {
        return getRequiredTokenAmounts(emptyPosition(), _destPosition, _sqrtPrice);
    }

    /**
     * @notice Calculates required token amounts to close position.
     * @param _srcPosition position to close
     * @param _sqrtPrice square root price to calculate
     */
    function getRequiredTokenAmountsToClose(DataType.Position memory _srcPosition, uint160 _sqrtPrice)
        internal
        pure
        returns (int256, int256)
    {
        return getRequiredTokenAmounts(_srcPosition, emptyPosition(), _sqrtPrice);
    }

    function getRequiredTokenAmountsToClose(DataType.Position[] memory _srcPositions, uint160 _sqrtPrice)
        internal
        pure
        returns (int256 requiredAmount0, int256 requiredAmount1)
    {
        for (uint256 i = 0; i < _srcPositions.length; i++) {
            (int256 a0, int256 a1) = getRequiredTokenAmounts(_srcPositions[i], emptyPosition(), _sqrtPrice);
            requiredAmount0 += a0;
            requiredAmount1 += a1;
        }
    }

    /**
     * @notice Calculates required token amounts to update position.
     * @param _srcPosition position to update
     * @param _destPosition desired position
     * @param _sqrtPrice square root price to calculate
     */
    function getRequiredTokenAmounts(
        DataType.Position memory _srcPosition,
        DataType.Position memory _destPosition,
        uint160 _sqrtPrice
    ) internal pure returns (int256 requiredAmount0, int256 requiredAmount1) {
        requiredAmount0 = requiredAmount0.sub(int256(_srcPosition.asset0));
        requiredAmount1 = requiredAmount1.sub(int256(_srcPosition.asset1));
        requiredAmount0 = requiredAmount0.add(int256(_srcPosition.debt0));
        requiredAmount1 = requiredAmount1.add(int256(_srcPosition.debt1));

        requiredAmount0 = requiredAmount0.add(int256(_destPosition.asset0));
        requiredAmount1 = requiredAmount1.add(int256(_destPosition.asset1));
        requiredAmount0 = requiredAmount0.sub(int256(_destPosition.debt0));
        requiredAmount1 = requiredAmount1.sub(int256(_destPosition.debt1));

        for (uint256 i = 0; i < _srcPosition.lpts.length; i++) {
            DataType.LPT memory lpt = _srcPosition.lpts[i];

            (uint256 amount0, uint256 amount1) = LiquidityAmounts.getAmountsForLiquidity(
                _sqrtPrice,
                TickMath.getSqrtRatioAtTick(lpt.lowerTick),
                TickMath.getSqrtRatioAtTick(lpt.upperTick),
                lpt.liquidity
            );

            if (lpt.isCollateral) {
                requiredAmount0 = requiredAmount0.sub(int256(amount0));
                requiredAmount1 = requiredAmount1.sub(int256(amount1));
            } else {
                requiredAmount0 = requiredAmount0.add(int256(amount0));
                requiredAmount1 = requiredAmount1.add(int256(amount1));
            }
        }

        for (uint256 i = 0; i < _destPosition.lpts.length; i++) {
            DataType.LPT memory lpt = _destPosition.lpts[i];

            (uint256 amount0, uint256 amount1) = LiquidityAmounts.getAmountsForLiquidity(
                _sqrtPrice,
                TickMath.getSqrtRatioAtTick(lpt.lowerTick),
                TickMath.getSqrtRatioAtTick(lpt.upperTick),
                lpt.liquidity
            );

            if (lpt.isCollateral) {
                requiredAmount0 = requiredAmount0.add(int256(amount0));
                requiredAmount1 = requiredAmount1.add(int256(amount1));
            } else {
                requiredAmount0 = requiredAmount0.sub(int256(amount0));
                requiredAmount1 = requiredAmount1.sub(int256(amount1));
            }
        }
    }

    function calculateLengthOfPositionUpdates(DataType.Position[] memory _positions)
        internal
        pure
        returns (uint256 length)
    {
        for (uint256 i = 0; i < _positions.length; i++) {
            length += calculateLengthOfPositionUpdates(_positions[i]);
        }
    }

    function calculateLengthOfPositionUpdates(DataType.Position memory _position)
        internal
        pure
        returns (uint256 length)
    {
        length = _position.lpts.length;

        if (_position.asset0 > 0 || _position.asset1 > 0) {
            length += 1;
        }

        if (_position.debt0 > 0 || _position.debt1 > 0) {
            length += 1;
        }
    }

    function calculatePositionUpdatesToOpen(DataType.Position memory _position)
        internal
        pure
        returns (DataType.PositionUpdate[] memory positionUpdates, uint256 swapIndex)
    {
        positionUpdates = new DataType.PositionUpdate[](calculateLengthOfPositionUpdates(_position) + 1);

        uint256 index = 0;

        for (uint256 i = 0; i < _position.lpts.length; i++) {
            DataType.LPT memory lpt = _position.lpts[i];
            if (!lpt.isCollateral) {
                positionUpdates[index] = DataType.PositionUpdate(
                    DataType.PositionUpdateType.BORROW_LPT,
                    _position.subVaultId,
                    false,
                    lpt.liquidity,
                    lpt.lowerTick,
                    lpt.upperTick,
                    0,
                    0
                );
                index++;
            }
        }

        if (_position.asset0 > 0 || _position.asset1 > 0) {
            positionUpdates[index] = DataType.PositionUpdate(
                DataType.PositionUpdateType.DEPOSIT_TOKEN,
                _position.subVaultId,
                false,
                0,
                0,
                0,
                _position.asset0,
                _position.asset1
            );
            index++;
        }

        if (_position.debt0 > 0 || _position.debt1 > 0) {
            positionUpdates[index] = DataType.PositionUpdate(
                DataType.PositionUpdateType.BORROW_TOKEN,
                _position.subVaultId,
                false,
                0,
                0,
                0,
                _position.debt0,
                _position.debt1
            );
            index++;
        }

        swapIndex = index;
        index++;

        for (uint256 i; i < _position.lpts.length; i++) {
            DataType.LPT memory lpt = _position.lpts[i];
            if (lpt.isCollateral) {
                positionUpdates[index] = DataType.PositionUpdate(
                    DataType.PositionUpdateType.DEPOSIT_LPT,
                    _position.subVaultId,
                    false,
                    lpt.liquidity,
                    lpt.lowerTick,
                    lpt.upperTick,
                    0,
                    0
                );
                index++;
            }
        }
    }

    function calculatePositionUpdatesToClose(DataType.Position[] memory _positions, uint256 _closeRatio)
        internal
        pure
        returns (DataType.PositionUpdate[] memory positionUpdates, uint256 swapIndex)
    {
        positionUpdates = new DataType.PositionUpdate[](calculateLengthOfPositionUpdates(_positions) + 1);

        uint256 index = 0;

        for (uint256 i = 0; i < _positions.length; i++) {
            for (uint256 j = 0; j < _positions[i].lpts.length; j++) {
                DataType.LPT memory lpt = _positions[i].lpts[j];
                if (lpt.isCollateral) {
                    positionUpdates[index] = DataType.PositionUpdate(
                        DataType.PositionUpdateType.WITHDRAW_LPT,
                        _positions[i].subVaultId,
                        false,
                        uint256(lpt.liquidity).mul(_closeRatio).div(1e4).toUint128(),
                        lpt.lowerTick,
                        lpt.upperTick,
                        0,
                        0
                    );
                    index++;
                }
            }
        }

        swapIndex = index;
        index++;

        for (uint256 i = 0; i < _positions.length; i++) {
            for (uint256 j = 0; j < _positions[i].lpts.length; j++) {
                DataType.LPT memory lpt = _positions[i].lpts[j];
                if (!lpt.isCollateral) {
                    positionUpdates[index] = DataType.PositionUpdate(
                        DataType.PositionUpdateType.REPAY_LPT,
                        _positions[i].subVaultId,
                        false,
                        uint256(lpt.liquidity).mul(_closeRatio).div(1e4).toUint128(),
                        lpt.lowerTick,
                        lpt.upperTick,
                        0,
                        0
                    );
                    index++;
                }
            }
        }

        for (uint256 i = 0; i < _positions.length; i++) {
            if (_positions[i].asset0 > 0 || _positions[i].asset1 > 0) {
                positionUpdates[index] = DataType.PositionUpdate(
                    DataType.PositionUpdateType.WITHDRAW_TOKEN,
                    _positions[i].subVaultId,
                    false,
                    0,
                    0,
                    0,
                    _closeRatio == 1e4 ? type(uint256).max : _positions[i].asset0.mul(_closeRatio).div(1e4),
                    _closeRatio == 1e4 ? type(uint256).max : _positions[i].asset1.mul(_closeRatio).div(1e4)
                );
                index++;
            }
        }

        for (uint256 i = 0; i < _positions.length; i++) {
            if (_positions[i].debt0 > 0 || _positions[i].debt1 > 0) {
                positionUpdates[index] = DataType.PositionUpdate(
                    DataType.PositionUpdateType.REPAY_TOKEN,
                    _positions[i].subVaultId,
                    false,
                    0,
                    0,
                    0,
                    _closeRatio == 1e4 ? type(uint256).max : _positions[i].debt0.mul(_closeRatio).div(1e4),
                    _closeRatio == 1e4 ? type(uint256).max : _positions[i].debt1.mul(_closeRatio).div(1e4)
                );
                index++;
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;
pragma abicoder v2;

import "lib/openzeppelin-contracts/contracts/math/SafeMath.sol";
import "lib/openzeppelin-contracts/contracts/math/SignedSafeMath.sol";
import "lib/v3-periphery/contracts/libraries/LiquidityAmounts.sol";
import "lib/v3-core/contracts/libraries/TickMath.sol";
import "lib/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {TransferHelper} from "lib/v3-periphery/contracts/libraries/TransferHelper.sol";
import "../DataType.sol";
import "../PositionLib.sol";
import "../PositionCalculator.sol";
import "../PositionUpdater.sol";
import "../PriceHelper.sol";

/**
 * @title LiquidationLogic library
 * @notice Implements the base logic for all the actions related to liquidation call.
 */
library LiquidationLogic {
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    event Liquidated(uint256 indexed vaultId, address liquidator, uint256 penaltyAmount);

    /**
     * @notice Anyone can liquidates the vault if its vault value is less than Min. Deposit.
     * Up to 100% of debt is repaid.
     * @param _vault vault
     * @param _positionUpdates parameters to update position
     */
    function execLiquidation(
        DataType.Vault storage _vault,
        mapping(uint256 => DataType.SubVault) storage _subVaults,
        DataType.PositionUpdate[] memory _positionUpdates,
        DataType.Context storage _context,
        mapping(bytes32 => DataType.PerpStatus) storage _ranges
    ) external {
        uint160 sqrtTwap = PriceHelper.getSqrtIndexPrice(_context);

        PositionCalculator.PositionCalculatorParams memory _params = VaultLib.getPositionCalculatorParams(
            _vault,
            _subVaults,
            _ranges,
            _context
        );

        // check that the vault is not safe
        require(!_isVaultSafe(_context.isMarginZero, _params, sqrtTwap), "L0");

        // calculate debt value to calculate penalty amount
        (, , uint256 debtValue) = PositionCalculator.calculateCollateralAndDebtValue(
            _params,
            sqrtTwap,
            _context.isMarginZero,
            false
        );

        // close all positions in the vault
        uint256 penaltyAmount = reducePosition(
            _vault,
            _subVaults,
            _context,
            _ranges,
            _positionUpdates,
            calculatePenaltyAmount(debtValue)
        );

        sendReward(_context, msg.sender, penaltyAmount);

        {
            // reverts if price is out of slippage threshold
            uint256 sqrtPrice = UniHelper.getSqrtPrice(_context.uniswapPool);

            uint256 liquidationSlippageSqrtTolerance = calculateLiquidationSlippageTolerance(debtValue);

            require(
                uint256(sqrtTwap).mul(1e6).div(1e6 + liquidationSlippageSqrtTolerance) <= sqrtPrice &&
                    sqrtPrice <= uint256(sqrtTwap).mul(1e6 + liquidationSlippageSqrtTolerance).div(1e6),
                "L4"
            );
        }

        emit Liquidated(_vault.vaultId, msg.sender, penaltyAmount);
    }

    function calculateLiquidationSlippageTolerance(uint256 _debtValue) internal pure returns (uint256) {
        uint256 liquidationSlippageSqrtTolerance = PredyMath.max(
            Constants.LIQ_SLIPPAGE_SQRT_SLOPE.mul(PredyMath.sqrt(_debtValue.mul(1e6))) /
                1e6 +
                Constants.LIQ_SLIPPAGE_SQRT_BASE,
            Constants.BASE_LIQ_SLIPPAGE_SQRT_TOLERANCE
        );

        if (liquidationSlippageSqrtTolerance > 1e6) {
            return 1e6;
        }

        return liquidationSlippageSqrtTolerance;
    }

    function calculatePenaltyAmount(uint256 _debtValue) internal pure returns (uint256) {
        // penalty amount is 0.4% of debt value
        return
            PredyMath.max(
                ((_debtValue / 250) / Constants.MARGIN_ROUNDED_DECIMALS).mul(Constants.MARGIN_ROUNDED_DECIMALS),
                Constants.MIN_PENALTY
            );
    }

    /**
     * @notice Checks the vault is safe or not.
     * if the vault value is greater than Min. Deposit, then return true.
     * otherwise return false.
     */
    function isVaultSafe(
        DataType.Vault memory _vault,
        mapping(uint256 => DataType.SubVault) storage _subVaults,
        DataType.Context memory _context,
        mapping(bytes32 => DataType.PerpStatus) storage _ranges
    ) public view returns (bool) {
        uint160 sqrtPrice = PriceHelper.getSqrtIndexPrice(_context);

        PositionCalculator.PositionCalculatorParams memory _params = VaultLib.getPositionCalculatorParams(
            _vault,
            _subVaults,
            _ranges,
            _context
        );

        return _isVaultSafe(_context.isMarginZero, _params, sqrtPrice);
    }

    function getVaultValue(
        DataType.Vault memory _vault,
        mapping(uint256 => DataType.SubVault) storage _subVaults,
        DataType.Context memory _context,
        mapping(bytes32 => DataType.PerpStatus) storage _ranges
    ) external view returns (int256) {
        uint160 sqrtPrice = PriceHelper.getSqrtIndexPrice(_context);

        PositionCalculator.PositionCalculatorParams memory _params = VaultLib.getPositionCalculatorParams(
            _vault,
            _subVaults,
            _ranges,
            _context
        );

        return VaultLib.getVaultValue(_context, _params, sqrtPrice);
    }

    function _isVaultSafe(
        bool isMarginZero,
        PositionCalculator.PositionCalculatorParams memory _params,
        uint160 sqrtPrice
    ) internal pure returns (bool) {
        // calculate Min. Deposit by using TWAP.
        int256 minDeposit = PositionCalculator.calculateMinDeposit(_params, sqrtPrice, isMarginZero);

        int256 vaultValue;
        int256 marginValue;
        {
            uint256 assetValue;
            uint256 debtValue;

            (marginValue, assetValue, debtValue) = PositionCalculator.calculateCollateralAndDebtValue(
                _params,
                sqrtPrice,
                isMarginZero,
                false
            );

            vaultValue = marginValue.add(int256(assetValue)).sub(int256(debtValue));

            if (debtValue == 0) {
                // if debt value is 0 then vault is safe.
                return true;
            }
        }

        return minDeposit <= vaultValue && marginValue >= 0;
    }

    function reducePosition(
        DataType.Vault storage _vault,
        mapping(uint256 => DataType.SubVault) storage _subVaults,
        DataType.Context storage _context,
        mapping(bytes32 => DataType.PerpStatus) storage _ranges,
        DataType.PositionUpdate[] memory _positionUpdates,
        uint256 _penaltyAmount
    ) public returns (uint256 penaltyAmount) {
        // reduce position
        DataType.PositionUpdateResult memory positionUpdateResult = PositionUpdater.updatePosition(
            _vault,
            _subVaults,
            _context,
            _ranges,
            _positionUpdates,
            // reduce only
            DataType.TradeOption(
                true,
                true,
                false,
                _context.isMarginZero,
                Constants.MARGIN_USE,
                Constants.MARGIN_USE,
                0,
                0,
                bytes("")
            )
        );

        require(0 == positionUpdateResult.requiredAmounts.amount0, "L2");
        require(0 == positionUpdateResult.requiredAmounts.amount1, "L3");

        {
            if (_context.isMarginZero) {
                (_vault.marginAmount0, penaltyAmount) = PredyMath.subReward(_vault.marginAmount0, _penaltyAmount);
            } else {
                (_vault.marginAmount1, penaltyAmount) = PredyMath.subReward(_vault.marginAmount1, _penaltyAmount);
            }
        }
    }

    function sendReward(
        DataType.Context memory _context,
        address _liquidator,
        uint256 _reward
    ) internal {
        TransferHelper.safeTransfer(_context.isMarginZero ? _context.token0 : _context.token1, _liquidator, _reward);
    }

    function getSqrtIndexPrice(DataType.Context memory _context) external view returns (uint160) {
        return PriceHelper.getSqrtIndexPrice(_context);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;
pragma abicoder v2;

import "lib/openzeppelin-contracts/contracts/math/SafeMath.sol";
import "lib/v3-periphery/contracts/libraries/LiquidityAmounts.sol";
import "lib/v3-core/contracts/libraries/TickMath.sol";
import "lib/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {TransferHelper} from "lib/v3-periphery/contracts/libraries/TransferHelper.sol";
import {IVaultNFT} from "../../interfaces/IVaultNFT.sol";
import "./LiquidationLogic.sol";
import "../DataType.sol";
import "../PositionLib.sol";
import "../PositionCalculator.sol";
import "../PositionUpdater.sol";
import "../PriceHelper.sol";

/**
 * @title UpdatePositionLogic library
 * @notice Implements the base logic for all the actions related to update position.
 * Error Codes
 * UPL0: vault must be safe
 */
library UpdatePositionLogic {
    using SafeMath for uint256;

    function updatePosition(
        DataType.Vault storage _vault,
        mapping(uint256 => DataType.SubVault) storage _subVaults,
        DataType.Context storage _context,
        mapping(bytes32 => DataType.PerpStatus) storage _ranges,
        DataType.PositionUpdate[] memory _positionUpdates,
        DataType.TradeOption memory _tradeOption
    ) external returns (DataType.PositionUpdateResult memory positionUpdateResult) {
        require(!_tradeOption.isLiquidationCall);

        // update position in the vault
        positionUpdateResult = PositionUpdater.updatePosition(
            _vault,
            _subVaults,
            _context,
            _ranges,
            _positionUpdates,
            _tradeOption
        );

        if (_tradeOption.quoterMode) {
            revertRequiredAmounts(positionUpdateResult);
        }

        // check the vault is safe
        require(LiquidationLogic.isVaultSafe(_vault, _subVaults, _context, _ranges), "UPL0");

        if (positionUpdateResult.requiredAmounts.amount0 > 0) {
            TransferHelper.safeTransferFrom(
                _context.token0,
                msg.sender,
                address(this),
                uint256(positionUpdateResult.requiredAmounts.amount0)
            );
        } else if (positionUpdateResult.requiredAmounts.amount0 < 0) {
            TransferHelper.safeTransfer(
                _context.token0,
                msg.sender,
                uint256(-positionUpdateResult.requiredAmounts.amount0)
            );
        }

        if (positionUpdateResult.requiredAmounts.amount1 > 0) {
            TransferHelper.safeTransferFrom(
                _context.token1,
                msg.sender,
                address(this),
                uint256(positionUpdateResult.requiredAmounts.amount1)
            );
        } else if (positionUpdateResult.requiredAmounts.amount1 < 0) {
            TransferHelper.safeTransfer(
                _context.token1,
                msg.sender,
                uint256(-positionUpdateResult.requiredAmounts.amount1)
            );
        }
    }

    function revertRequiredAmounts(DataType.PositionUpdateResult memory positionUpdateResult) internal pure {
        int256 r0 = positionUpdateResult.requiredAmounts.amount0;
        int256 r1 = positionUpdateResult.requiredAmounts.amount1;
        int256 f0 = positionUpdateResult.feeAmounts.amount0;
        int256 f1 = positionUpdateResult.feeAmounts.amount1;
        int256 p0 = positionUpdateResult.positionAmounts.amount0;
        int256 p1 = positionUpdateResult.positionAmounts.amount1;
        int256 s0 = positionUpdateResult.swapAmounts.amount0;
        int256 s1 = positionUpdateResult.swapAmounts.amount1;

        assembly {
            let ptr := mload(0x20)
            mstore(ptr, r0)
            mstore(add(ptr, 0x20), r1)
            mstore(add(ptr, 0x40), f0)
            mstore(add(ptr, 0x60), f1)
            mstore(add(ptr, 0x80), p0)
            mstore(add(ptr, 0xA0), p1)
            mstore(add(ptr, 0xC0), s0)
            mstore(add(ptr, 0xE0), s1)
            revert(ptr, 256)
        }
    }
}

//SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.7.6;

library Constants {
    uint256 internal constant ONE = 1e18;

    // Reserve factor is 10%
    uint256 internal constant RESERVE_FACTOR = 10 * 1e16;

    // Reserve factor of LPToken is 5%
    uint256 internal constant LPT_RESERVE_FACTOR = 5 * 1e16;

    // Margin option
    uint8 internal constant MARGIN_STAY = 1;
    uint8 internal constant MARGIN_USE = 2;
    int256 internal constant FULL_WITHDRAWAL = type(int128).min;

    uint256 internal constant MAX_MARGIN_AMOUNT = 1e32;
    int256 internal constant MIN_MARGIN_AMOUNT = 1e6;
    uint256 internal constant MARGIN_ROUNDED_DECIMALS = 1e4;

    uint256 internal constant MIN_PENALTY = 2 * 1e5;

    uint256 internal constant MIN_SQRT_PRICE = 79228162514264337593;
    uint256 internal constant MAX_SQRT_PRICE = 79228162514264337593543950336000000000;

    uint256 internal constant MAX_NUM_OF_SUBVAULTS = 32;

    uint256 internal constant Q96 = 0x1000000000000000000000000;

    // 2%
    uint256 internal constant BASE_MIN_COLLATERAL_WITH_DEBT = 20000;
    // 0.00005
    uint256 internal constant MIN_COLLATERAL_WITH_DEBT_SLOPE = 50;
    // 2.5% scaled by 1e6
    uint256 internal constant BASE_LIQ_SLIPPAGE_SQRT_TOLERANCE = 12422;
    // 0.000022
    uint256 internal constant LIQ_SLIPPAGE_SQRT_SLOPE = 22;
    // 0.001
    uint256 internal constant LIQ_SLIPPAGE_SQRT_BASE = 1000;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

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
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;


/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

import "lib/chainlink/contracts/src/v0.7/interfaces/AggregatorV3Interface.sol";
import "./DataType.sol";
import "./UniHelper.sol";

library PriceHelper {
    // assuming USDC
    uint256 internal constant MARGIN_SCALER = 1e6;

    // assuming ETH, BTC
    uint256 internal constant UNDERLYING_SCALER = 1e18;

    uint256 internal constant PRICE_SCALER = 1e2;

    uint256 internal constant MAX_PRICE = PRICE_SCALER * 1e36;

    /**
     * @notice Gets the square root of underlying index price.
     * If the chainlink price feed address is set, use Chainlink price, otherwise use Uniswap TWAP.
     * @param _context Predy pool's context object
     * @return price The square root of underlying index price.
     */
    function getSqrtIndexPrice(DataType.Context memory _context) internal view returns (uint160) {
        if (_context.chainlinkPriceFeed == address(0)) {
            return uint160(UniHelper.getSqrtTWAP(_context.uniswapPool));
        } else {
            return
                uint160(
                    encodeSqrtPriceX96(_context.isMarginZero, getChainlinkLatestAnswer(_context.chainlinkPriceFeed))
                );
        }
    }

    /**
     * @notice Gets underlying price scaled by 1e18
     * @param _priceFeedAddress Chainlink's price feed address
     * @return price underlying price scaled by 1e18
     */
    function getChainlinkLatestAnswer(address _priceFeedAddress) internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(_priceFeedAddress);

        (, int256 answer, , , ) = priceFeed.latestRoundData();

        require(answer > 0, "PH0");

        return (uint256(answer) * MARGIN_SCALER * PRICE_SCALER) / 1e8;
    }

    /**
     * @notice Calculates sqrtPrice from the price.
     * @param _isMarginZero true if token0 is margin asset, false if token 1 is margin asset.
     * @param _price price scaled by (MARGIN_SCALER + PRICE_SCALER)
     * @return sqrtPriceX96 Uniswap pool's sqrt price.
     */
    function encodeSqrtPriceX96(bool _isMarginZero, uint256 _price) internal pure returns (uint256 sqrtPriceX96) {
        if (_isMarginZero) {
            _price = MAX_PRICE / _price;

            return PredyMath.sqrt(FullMath.mulDiv(_price, uint256(2**(96 * 2)), UNDERLYING_SCALER));
        } else {
            return
                PredyMath.sqrt(
                    (FullMath.mulDiv(_price, uint256(2**96) * uint256(2**96), UNDERLYING_SCALER * PRICE_SCALER))
                );
        }
    }

    /**
     * @notice Calculates position value at sqrtPrice by margin token.
     * @param _isMarginZero true if token0 is margin asset, false if token 1 is margin asset.
     * @param _sqrtPriceX96 Uniswap pool's sqrt price.
     * @param _amount0 The amount of token0
     * @param _amount1 The amount of token1
     * @return value of token0 and token1 scaled by MARGIN_SCALER
     */
    function getValue(
        bool _isMarginZero,
        uint256 _sqrtPriceX96,
        int256 _amount0,
        int256 _amount1
    ) internal pure returns (int256) {
        uint256 price;

        if (_isMarginZero) {
            price = FullMath.mulDiv(_sqrtPriceX96, _sqrtPriceX96, uint256(2**(96 * 2)) / UNDERLYING_SCALER);

            if (price == 0) {
                price = 1;
            }

            return _amount0 + (_amount1 * 1e18) / int256(price);
        } else {
            price = FullMath.mulDiv(_sqrtPriceX96, _sqrtPriceX96, uint256(2**96));

            return (_amount0 * int256(price)) / int256(2**96) + _amount1;
        }
    }

    /**
     * if isMarginZero is true, calculates token1 price by token0.
     * if isMarginZero is false, calculates token0 price by token1.
     * @dev underlying token's decimal must be 1e18.
     * @param _isMarginZero true if token0 is margin asset, false if token 1 is margin asset.
     * @param _sqrtPriceX96 Uniswap pool's sqrt price.
     * @return price The price scaled by (MARGIN_SCALER + PRICE_SCALER)
     */
    function decodeSqrtPriceX96(bool _isMarginZero, uint256 _sqrtPriceX96) internal pure returns (uint256 price) {
        if (_isMarginZero) {
            price = FullMath.mulDiv(_sqrtPriceX96, _sqrtPriceX96, uint256(2**(96 * 2)) / UNDERLYING_SCALER);
            if (price == 0) return MAX_PRICE;
            price = MAX_PRICE / price;
        } else {
            price =
                (FullMath.mulDiv(_sqrtPriceX96, _sqrtPriceX96, uint256(2**96)) * UNDERLYING_SCALER * PRICE_SCALER) /
                uint256(2**96);
        }

        if (price > MAX_PRICE) price = MAX_PRICE;
        else if (price == 0) price = 1;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;
pragma abicoder v2;

import "lib/openzeppelin-contracts/contracts/math/SafeMath.sol";
import "lib/openzeppelin-contracts/contracts/math/SignedSafeMath.sol";
import "lib/v3-periphery/contracts/libraries/LiquidityAmounts.sol";
import "lib/v3-core/contracts/libraries/TickMath.sol";
import "./DataType.sol";
import "./PriceHelper.sol";

/**
 * @title PositionCalculator library
 * @notice Implements the base logic calculating Min. Deposit and value of positions.
 */
library PositionCalculator {
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    uint256 internal constant Q96 = 0x1000000000000000000000000;
    // sqrt{1.18} = 1.08627804912
    uint160 internal constant UPPER_E8 = 108627805;
    // sqrt{1/1.18} = 0.92057461789
    uint160 internal constant LOWER_E8 = 92057462;

    uint256 internal constant MAX_NUM_OF_LPTS = 16;

    struct PositionCalculatorParams {
        int256 marginAmount0;
        int256 marginAmount1;
        uint256 asset0;
        uint256 asset1;
        uint256 debt0;
        uint256 debt1;
        DataType.LPT[] lpts;
    }

    /**
     * @notice Calculates Min. Deposit for a vault.
     * MinDeposit = vaultPositionValue - minValue + Max{0.00006 * Sqrt{DebtValue}, 0.02} * DebtValue
     * @param _params position object
     * @param _sqrtPrice square root price to calculate
     * @param _isMarginZero whether the stable token is token0 or token1
     */
    function calculateMinDeposit(
        PositionCalculatorParams memory _params,
        uint160 _sqrtPrice,
        bool _isMarginZero
    ) internal pure returns (int256 minDeposit) {
        require(
            Constants.MIN_SQRT_PRICE <= _sqrtPrice && _sqrtPrice <= Constants.MAX_SQRT_PRICE,
            "Out of sqrtprice range"
        );

        require(_params.lpts.length <= MAX_NUM_OF_LPTS, "Exceeds max num of LPTs");

        int256 vaultPositionValue = calculateValue(_params, _sqrtPrice, _isMarginZero);

        int256 minValue = calculateMinValue(_params, _sqrtPrice, _isMarginZero);

        (, , uint256 debtValue) = calculateCollateralAndDebtValue(_params, _sqrtPrice, _isMarginZero, false);

        minDeposit = int256(calculateRequiredCollateralWithDebt(debtValue).mul(debtValue).div(1e6))
            .add(vaultPositionValue)
            .sub(minValue);

        if (minDeposit < Constants.MIN_MARGIN_AMOUNT && debtValue > 0) {
            minDeposit = Constants.MIN_MARGIN_AMOUNT;
        }
    }

    function calculateRequiredCollateralWithDebt(uint256 _debtValue) internal pure returns (uint256) {
        return
            PredyMath.max(
                Constants.MIN_COLLATERAL_WITH_DEBT_SLOPE.mul(PredyMath.sqrt(_debtValue * 1e6)).div(1e6),
                Constants.BASE_MIN_COLLATERAL_WITH_DEBT
            );
    }

    /**
     * @notice Calculates square root of min price (a * b)^(1/4)
     * P_{min}^(1/2) = (a * b)^(1/4)
     */
    function calculateMinSqrtPrice(int24 _lowerTick, int24 _upperTick) internal pure returns (uint160) {
        return uint160(TickMath.getSqrtRatioAtTick((_lowerTick + _upperTick) / 2));
    }

    /**
     * @notice Calculates minValue.
     * MinValue is minimal value of following values.
     * 1. value of at P*1.18
     * 2. value of at P/1.18
     * 3. values of at P_{min} of LPTs
     */
    function calculateMinValue(
        PositionCalculatorParams memory _position,
        uint160 _sqrtPrice,
        bool _isMarginZero
    ) internal pure returns (int256 minValue) {
        minValue = type(int256).max;
        uint256 sqrtPriceLower = uint256(LOWER_E8).mul(_sqrtPrice) / 1e8;
        uint256 sqrtPriceUpper = uint256(UPPER_E8).mul(_sqrtPrice) / 1e8;

        require(sqrtPriceLower < type(uint160).max);
        require(sqrtPriceUpper < type(uint160).max);

        require(TickMath.MIN_SQRT_RATIO < _sqrtPrice && _sqrtPrice < TickMath.MAX_SQRT_RATIO, "Out of sqrtprice range");

        if (sqrtPriceLower < TickMath.MIN_SQRT_RATIO) {
            sqrtPriceLower = TickMath.MIN_SQRT_RATIO;
        }

        if (sqrtPriceUpper > TickMath.MAX_SQRT_RATIO) {
            sqrtPriceUpper = TickMath.MAX_SQRT_RATIO;
        }

        {
            // 1. check value of at P*1.18
            int256 value = calculateValue(_position, uint160(sqrtPriceUpper), _isMarginZero);
            if (minValue > value) {
                minValue = value;
            }
        }

        {
            // 2. check value of at P/1.18
            int256 value = calculateValue(_position, uint160(sqrtPriceLower), _isMarginZero);
            if (minValue > value) {
                minValue = value;
            }
        }

        // 3. check values of at P_{min} of LPTs
        for (uint256 i = 0; i < _position.lpts.length; i++) {
            DataType.LPT memory lpt = _position.lpts[i];

            if (!lpt.isCollateral) {
                uint160 minSqrtPrice = calculateMinSqrtPrice(lpt.upperTick, lpt.lowerTick);

                if (minSqrtPrice < sqrtPriceLower || sqrtPriceUpper < minSqrtPrice) {
                    continue;
                }

                int256 value = calculateValue(_position, minSqrtPrice, _isMarginZero, true);

                if (minValue > value) {
                    minValue = value;
                }
            }
        }
    }

    function calculateValue(
        PositionCalculatorParams memory _position,
        uint160 _sqrtPrice,
        bool _isMarginZero
    ) internal pure returns (int256 value) {
        return calculateValue(_position, _sqrtPrice, _isMarginZero, false);
    }

    function calculateValue(
        PositionCalculatorParams memory _position,
        uint160 _sqrtPrice,
        bool isMarginZero,
        bool _isMinPrice
    ) internal pure returns (int256 value) {
        (int256 marginValue, uint256 assetValue, uint256 debtValue) = calculateCollateralAndDebtValue(
            _position,
            _sqrtPrice,
            isMarginZero,
            _isMinPrice
        );

        return marginValue + int256(assetValue) - int256(debtValue);
    }

    function calculateCollateralAndDebtValue(
        PositionCalculatorParams memory _position,
        uint160 _sqrtPrice,
        bool _isMarginZero,
        bool _isMinPrice
    )
        internal
        pure
        returns (
            int256 marginValue,
            uint256 assetValue,
            uint256 debtValue
        )
    {
        marginValue = PriceHelper.getValue(_isMarginZero, _sqrtPrice, _position.marginAmount0, _position.marginAmount1);

        (
            uint256 assetAmount0,
            uint256 assetAmount1,
            uint256 debtAmount0,
            uint256 debtAmount1
        ) = calculateCollateralAndDebtAmount(_position, _sqrtPrice, _isMinPrice);

        assetValue = uint256(
            PriceHelper.getValue(_isMarginZero, _sqrtPrice, int256(assetAmount0), int256(assetAmount1))
        );

        debtValue = uint256(PriceHelper.getValue(_isMarginZero, _sqrtPrice, int256(debtAmount0), int256(debtAmount1)));
    }

    function calculateCollateralAndDebtAmount(
        PositionCalculatorParams memory _position,
        uint160 _sqrtPrice,
        bool _isMinPrice
    )
        internal
        pure
        returns (
            uint256 assetAmount0,
            uint256 assetAmount1,
            uint256 debtAmount0,
            uint256 debtAmount1
        )
    {
        assetAmount0 = _position.asset0;
        assetAmount1 = _position.asset1;
        debtAmount0 = _position.debt0;
        debtAmount1 = _position.debt1;

        for (uint256 i = 0; i < _position.lpts.length; i++) {
            DataType.LPT memory lpt = _position.lpts[i];

            uint160 sqrtLowerPrice = TickMath.getSqrtRatioAtTick(lpt.lowerTick);
            uint160 sqrtUpperPrice = TickMath.getSqrtRatioAtTick(lpt.upperTick);

            if (_isMinPrice && !lpt.isCollateral && sqrtLowerPrice <= _sqrtPrice && _sqrtPrice <= sqrtUpperPrice) {
                debtAmount1 = debtAmount1.add(
                    (
                        uint256(lpt.liquidity).mul(
                            uint256(TickMath.getSqrtRatioAtTick(lpt.upperTick)).sub(
                                TickMath.getSqrtRatioAtTick(lpt.lowerTick)
                            )
                        )
                    ).div(Q96)
                );
                continue;
            }

            (uint256 amount0, uint256 amount1) = LiquidityAmounts.getAmountsForLiquidity(
                _sqrtPrice,
                sqrtLowerPrice,
                sqrtUpperPrice,
                lpt.liquidity
            );

            if (lpt.isCollateral) {
                assetAmount0 = assetAmount0.add(amount0);
                assetAmount1 = assetAmount1.add(amount1);
            } else {
                debtAmount0 = debtAmount0.add(amount0);
                debtAmount1 = debtAmount1.add(amount1);
            }
        }
    }

    function add(PositionCalculatorParams memory _params, DataType.Position memory _position)
        internal
        pure
        returns (PositionCalculatorParams memory _newParams)
    {
        uint256 numLPTs = _params.lpts.length + _position.lpts.length;

        DataType.LPT[] memory lpts = new DataType.LPT[](numLPTs);

        _newParams = PositionCalculatorParams(
            _params.marginAmount0,
            _params.marginAmount1,
            _params.asset0,
            _params.asset1,
            _params.debt0,
            _params.debt1,
            lpts
        );

        _newParams.asset0 = _newParams.asset0.add(_position.asset0);
        _newParams.asset1 = _newParams.asset1.add(_position.asset1);
        _newParams.debt0 = _newParams.debt0.add(_position.debt0);
        _newParams.debt1 = _newParams.debt1.add(_position.debt1);

        uint256 k;

        for (uint256 j = 0; j < _params.lpts.length; j++) {
            _newParams.lpts[k] = _params.lpts[j];
            k++;
        }
        for (uint256 j = 0; j < _position.lpts.length; j++) {
            _newParams.lpts[k] = _position.lpts[j];
            k++;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;
pragma abicoder v2;

import "lib/v3-periphery/contracts/libraries/LiquidityAmounts.sol";
import "lib/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "lib/v3-core/contracts/libraries/TickMath.sol";
import "../vendors/IUniswapV3PoolOracle.sol";
import "./DataType.sol";

library UniHelper {
    uint256 internal constant ORACLE_PERIOD = 30 minutes;

    function getSqrtPrice(address _uniswapPool) internal view returns (uint160 sqrtPriceX96) {
        (sqrtPriceX96, , , , , , ) = IUniswapV3Pool(_uniswapPool).slot0();
    }

    /**
     * Gets square root of time weighted average price.
     */
    function getSqrtTWAP(address _uniswapPool) internal view returns (uint160 sqrtTwapX96) {
        (sqrtTwapX96, ) = callUniswapObserve(IUniswapV3Pool(_uniswapPool), ORACLE_PERIOD);
    }

    function callUniswapObserve(IUniswapV3Pool uniswapPool, uint256 ago) internal view returns (uint160, uint256) {
        uint32[] memory secondsAgos = new uint32[](2);

        secondsAgos[0] = uint32(ago);
        secondsAgos[1] = 0;

        (bool success, bytes memory data) = address(uniswapPool).staticcall(
            abi.encodeWithSelector(IUniswapV3PoolOracle.observe.selector, secondsAgos)
        );

        if (!success) {
            if (keccak256(data) != keccak256(abi.encodeWithSignature("Error(string)", "OLD"))) revertBytes(data);

            (, , uint16 index, uint16 cardinality, , , ) = uniswapPool.slot0();

            (uint32 oldestAvailableAge, , , bool initialized) = uniswapPool.observations((index + 1) % cardinality);

            if (!initialized) (oldestAvailableAge, , , ) = uniswapPool.observations(0);

            ago = block.timestamp - oldestAvailableAge;
            secondsAgos[0] = uint32(ago);

            (success, data) = address(uniswapPool).staticcall(
                abi.encodeWithSelector(IUniswapV3PoolOracle.observe.selector, secondsAgos)
            );
            if (!success) revertBytes(data);
        }

        int56[] memory tickCumulatives = abi.decode(data, (int56[]));

        int24 tick = int24((tickCumulatives[1] - tickCumulatives[0]) / int56(int256(ago)));

        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(tick);

        return (sqrtPriceX96, ago);
    }

    function revertBytes(bytes memory errMsg) internal pure {
        if (errMsg.length > 0) {
            assembly {
                revert(add(32, errMsg), mload(errMsg))
            }
        }

        revert("e/empty-error");
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import '@uniswap/v3-core/contracts/libraries/FullMath.sol';
import '@uniswap/v3-core/contracts/libraries/FixedPoint96.sol';

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityAmounts {
    /// @notice Downcasts uint256 to uint128
    /// @param x The uint258 to be downcasted
    /// @return y The passed value, downcasted to uint128
    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        return toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        return toUint128(FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount of token0 being sent in
    /// @param amount1 The amount of token1 being sent in
    /// @return liquidity The maximum amount of liquidity received
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 = getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
        }
    }

    /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    function getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
            FullMath.mulDiv(
                uint256(liquidity) << FixedPoint96.RESOLUTION,
                sqrtRatioBX96 - sqrtRatioAX96,
                sqrtRatioBX96
            ) / sqrtRatioAX96;
    }

    /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount1 The amount of token1
    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
    }

    /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
        } else {
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(MAX_TICK), 'T');

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface IUniswapV3PoolOracle {
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    function liquidity() external view returns (uint128);

    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory liquidityCumulatives);

    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 liquidityCumulative,
            bool initialized
        );

    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0 <0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = -denominator & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

library PositionKey {
    /// @dev Returns the key of the position in the core library
    function compute(
        address owner,
        int24 tickLower,
        int24 tickUpper
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(owner, tickLower, tickUpper));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;
pragma abicoder v2;

import "lib/v3-periphery/contracts/libraries/PositionKey.sol";
import "lib/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "./DataType.sol";

library LPTStateLib {
    using SafeMath for uint256;

    /**
     * @notice register new LPT
     */
    function registerNewLPTState(
        DataType.PerpStatus storage _range,
        int24 _lowerTick,
        int24 _upperTick
    ) internal {
        _range.lowerTick = _lowerTick;
        _range.upperTick = _upperTick;
        _range.lastTouchedTimestamp = block.timestamp;
    }

    function getRangeKey(int24 _lower, int24 _upper) internal pure returns (bytes32) {
        return keccak256(abi.encode(_lower, _upper));
    }

    function getPerpStatus(
        address _controllerAddress,
        address _uniswapPool,
        DataType.PerpStatus memory _perpState
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (
            getTotalLiquidityAmount(_controllerAddress, _uniswapPool, _perpState),
            _perpState.borrowedLiquidity,
            getPerpUR(_controllerAddress, _uniswapPool, _perpState)
        );
    }

    function getPerpUR(
        address _controllerAddress,
        address _uniswapPool,
        DataType.PerpStatus memory _perpState
    ) internal view returns (uint256) {
        return
            PredyMath.mulDiv(
                _perpState.borrowedLiquidity,
                1e18,
                getTotalLiquidityAmount(_controllerAddress, _uniswapPool, _perpState)
            );
    }

    function getAvailableLiquidityAmount(
        address _controllerAddress,
        address _uniswapPool,
        DataType.PerpStatus memory _perpState
    ) internal view returns (uint256) {
        bytes32 positionKey = PositionKey.compute(_controllerAddress, _perpState.lowerTick, _perpState.upperTick);

        (uint128 liquidity, , , , ) = IUniswapV3Pool(_uniswapPool).positions(positionKey);

        return liquidity;
    }

    function getTotalLiquidityAmount(
        address _controllerAddress,
        address _uniswapPool,
        DataType.PerpStatus memory _perpState
    ) internal view returns (uint256) {
        return getAvailableLiquidityAmount(_controllerAddress, _uniswapPool, _perpState) + _perpState.borrowedLiquidity;
    }
}

//SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.7.6;
pragma abicoder v2;

import "lib/openzeppelin-contracts/contracts/math/SafeMath.sol";
import "./Controller.sol";
import "./libraries/BaseToken.sol";
import "./libraries/PriceHelper.sol";
import "./libraries/PositionCalculator.sol";
import "./libraries/UniHelper.sol";

/**
 * @title Reader contract
 * @notice Reader contract with an controller
 **/
contract Reader {
    using SafeMath for uint256;

    Controller public controller;
    bool public isMarginZero;
    address public uniswapPool;

    /**
     * @notice Reader constructor
     * @param _controller controller address
     */
    constructor(Controller _controller) {
        controller = _controller;

        (isMarginZero, , uniswapPool, , ) = controller.getContext();
    }

    /**
     * @notice Gets current underlying asset price.
     * @return price
     **/
    function getPrice() public view returns (uint256) {
        return PriceHelper.decodeSqrtPriceX96(isMarginZero, controller.getSqrtPrice());
    }

    /**
     * @notice Gets index price.
     * @return indexPrice
     **/
    function getIndexPrice() external view returns (uint256) {
        return PriceHelper.decodeSqrtPriceX96(isMarginZero, controller.getSqrtIndexPrice());
    }

    /**
     * @notice Gets asset status
     **/
    function getAssetStatus(BaseToken.TokenState memory _tokenState0, BaseToken.TokenState memory _tokenState1)
        external
        pure
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            BaseToken.getTotalCollateralValue(_tokenState0),
            BaseToken.getTotalDebtValue(_tokenState0),
            BaseToken.getUtilizationRatio(_tokenState0),
            BaseToken.getTotalCollateralValue(_tokenState1),
            BaseToken.getTotalDebtValue(_tokenState1),
            BaseToken.getUtilizationRatio(_tokenState1)
        );
    }

    function calculateLPTPremium(
        bytes32 _rangeId,
        bool _isBorrow,
        uint256 _deltaLiquidity,
        uint256 _elapsed,
        uint256 _baseTradeFeePerLiquidity
    )
        external
        view
        returns (
            uint256 premiumGrowthForBorrower,
            uint256 premiumGrowthForLender,
            uint256 protocolFeePerLiquidity,
            uint256 tradeFeePerLiquidity
        )
    {
        (uint256 supply, uint256 borrow, ) = controller.getUtilizationRatio(_rangeId);

        if (supply == 0) {
            return (0, 0, 0, _baseTradeFeePerLiquidity);
        }

        uint256 afterUr = _isBorrow
            ? borrow.add(_deltaLiquidity).mul(1e18).div(supply)
            : borrow.mul(1e18).div(supply.add(_deltaLiquidity));

        (premiumGrowthForBorrower, , protocolFeePerLiquidity) = controller.calculateLPTBorrowerAndLenderPremium(
            _rangeId,
            afterUr,
            _elapsed
        );

        premiumGrowthForLender = premiumGrowthForBorrower.sub(protocolFeePerLiquidity).mul(afterUr).div(1e18);

        tradeFeePerLiquidity = _baseTradeFeePerLiquidity.mul(uint256(1e18).sub(afterUr)).div(1e18);
    }

    /**
     * @notice Calculates Min. Deposit of the vault.
     * @param _vaultId vault id
     * @param _position position you wanna add to the vault
     * @return minDeposit minimal amount of deposit to keep positions.
     */
    function calculateMinDeposit(uint256 _vaultId, DataType.Position memory _position) external view returns (int256) {
        return
            PositionCalculator.calculateMinDeposit(
                PositionCalculator.add(controller.getPositionCalculatorParams(_vaultId), _position),
                controller.getSqrtPrice(),
                isMarginZero
            );
    }

    function quoteOpenPosition(
        uint256 _vaultId,
        DataType.Position memory _position,
        DataType.TradeOption memory _tradeOption,
        DataType.OpenPositionOption memory _openPositionOptions
    ) external returns (DataType.PositionUpdateResult memory result) {
        require(_vaultId > 0);
        require(_tradeOption.quoterMode);
        try controller.openPosition(_vaultId, _position, _tradeOption, _openPositionOptions) {} catch (
            bytes memory reason
        ) {
            return handleRevert(reason);
        }
    }

    function quoteCloseSubVault(
        uint256 _vaultId,
        uint256 _subVaultId,
        DataType.TradeOption memory _tradeOption,
        DataType.ClosePositionOption memory _closePositionOptions
    ) external returns (DataType.PositionUpdateResult memory result) {
        require(_vaultId > 0);
        require(_tradeOption.quoterMode);
        try controller.closeSubVault(_vaultId, _subVaultId, _tradeOption, _closePositionOptions) {} catch (
            bytes memory reason
        ) {
            return handleRevert(reason);
        }
    }

    function parseRevertReason(bytes memory reason)
        private
        pure
        returns (
            int256,
            int256,
            int256,
            int256,
            int256,
            int256,
            int256,
            int256
        )
    {
        if (reason.length != 256) {
            if (reason.length < 68) revert("Unexpected error");
            assembly {
                reason := add(reason, 0x04)
            }
            revert(abi.decode(reason, (string)));
        }
        return abi.decode(reason, (int256, int256, int256, int256, int256, int256, int256, int256));
    }

    function handleRevert(bytes memory reason) internal pure returns (DataType.PositionUpdateResult memory result) {
        (
            result.requiredAmounts.amount0,
            result.requiredAmounts.amount1,
            result.feeAmounts.amount0,
            result.feeAmounts.amount1,
            result.positionAmounts.amount0,
            result.positionAmounts.amount1,
            result.swapAmounts.amount0,
            result.swapAmounts.amount1
        ) = parseRevertReason(reason);
    }
}

//SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.7.6;
pragma abicoder v2;

import "lib/openzeppelin-contracts/contracts/math/SafeMath.sol";
import "lib/openzeppelin-contracts/contracts/math/SignedSafeMath.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import {TransferHelper} from "lib/v3-periphery/contracts/libraries/TransferHelper.sol";
import "../interfaces/IController.sol";
import "../interfaces/IReader.sol";
import "../libraries/PriceHelper.sol";
import "../libraries/Constants.sol";
import "./BlackScholes.sol";
import "./SateliteLib.sol";

/**
 * OM0: caller is not option holder
 * OM1: board has not been expired
 * OM2: board has not been exercised
 */
contract OptionMarket is ERC20, IERC721Receiver, Ownable {
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    IController internal controller;

    IReader internal reader;

    address internal usdc;

    struct Strike {
        uint256 id;
        uint256 strikePrice;
        uint128 liquidity;
        int24 lowerTick;
        int24 upperTick;
        int256 callPositionAmount;
        int256 putPositionAmount;
        uint256 boardId;
    }

    struct Board {
        uint256 id;
        uint256 expiration;
        uint256 indexPrice;
        bool isExpired;
        int256 unrealizedProfit;
        uint256[] strikeIds;
    }

    struct OptionPosition {
        uint256 id;
        uint256 strikeId;
        int256 amount;
        bool isPut;
        address owner;
        uint256 premium;
        uint256 collateralAmount;
    }

    struct OptionTradeParams {
        bool isPut;
        bool isLong;
        bool isOpen;
    }

    uint256 public vaultId;

    uint256 public subVaultId;

    uint256 private strikeCount;

    uint256 private boardCount;

    uint256 private optionPositionCount;

    mapping(uint256 => Strike) internal strikes;

    mapping(uint256 => Board) internal boards;

    mapping(uint256 => OptionPosition) internal optionPositions;

    uint256 private totalLiquidityAmount;

    constructor(
        address _controller,
        address _reader,
        address _usdc
    ) ERC20("", "") {
        controller = IController(_controller);
        reader = IReader(_reader);
        usdc = _usdc;

        ERC20(usdc).approve(address(controller), type(uint256).max);

        strikeCount = 1;
        boardCount = 1;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @notice Creates new option board.
     * @param _expiration The timestamp when the board expires.
     * @param _lowerTicks The array of lower ticks indicates strike prices.
     * @param _upperTicks The array of upper ticks indicates strike prices.
     */
    function createBoard(
        uint256 _expiration,
        int24[] memory _lowerTicks,
        int24[] memory _upperTicks
    ) external onlyOwner returns (uint256) {
        uint256 id = boardCount;

        uint256[] memory strikeIds = new uint256[](_lowerTicks.length);

        for (uint256 i = 0; i < _lowerTicks.length; i++) {
            strikeIds[i] = createStrike(id, _lowerTicks[i], _upperTicks[i]);
        }

        boards[id] = Board(id, _expiration, 0, false, 0, strikeIds);

        boardCount += 1;

        return id;
    }

    function createStrike(
        uint256 _boardId,
        int24 _lowerTick,
        int24 _upperTick
    ) internal returns (uint256) {
        uint256 id = strikeCount;

        uint128 liquidity = SateliteLib.getBaseLiquidity(reader.isMarginZero(), _lowerTick, _upperTick);

        strikes[id] = Strike(
            id,
            calculateStrikePrice(_lowerTick, _upperTick),
            liquidity,
            _lowerTick,
            _upperTick,
            0,
            0,
            _boardId
        );

        strikeCount += 1;

        return id;
    }

    function getLPTokenPrice() external view returns (uint256) {
        return (Constants.ONE * totalLiquidityAmount) / totalSupply();
    }

    function deposit(uint256 _amount) external returns (uint256 mintAmount) {
        if (totalLiquidityAmount == 0) {
            mintAmount = _amount;
        } else {
            mintAmount = (_amount * totalSupply()) / totalLiquidityAmount;
        }

        totalLiquidityAmount += _amount;

        TransferHelper.safeTransferFrom(usdc, msg.sender, address(this), _amount);

        _mint(msg.sender, mintAmount);
    }

    function withdraw(uint256 _amount) external returns (uint256 burnAmount) {
        burnAmount = (_amount * totalSupply()) / totalLiquidityAmount;

        totalLiquidityAmount = totalLiquidityAmount.sub(_amount);

        TransferHelper.safeTransfer(usdc, msg.sender, _amount);

        _burn(msg.sender, burnAmount);
    }

    /**
     * @notice Opens new position
     * @param _strikeId The id of the option series
     * @param _amount amount of options
     * @param _isPut is put option or call option
     * @param _collateralAmount amount of collateral
     */
    function openPosition(
        uint256 _strikeId,
        int256 _amount,
        bool _isPut,
        uint256 _collateralAmount
    ) external returns (uint256 optionId) {
        uint256 marginValue = getMarginValue(strikes[_strikeId], _amount, _isPut);

        int256 vaultValue = controller.getVaultValue(vaultId);

        DataType.TradeOption memory tradeOption = DataType.TradeOption(
            false,
            true,
            false,
            true,
            Constants.MARGIN_USE,
            Constants.MARGIN_STAY,
            int256(marginValue) - vaultValue,
            0,
            bytes("")
        );

        // cover
        (uint256 premium, int256 requiredAmount) = _trade(_strikeId, _amount, tradeOption, _isPut);

        if (_isPut) {
            strikes[_strikeId].putPositionAmount += _amount;
        } else {
            strikes[_strikeId].callPositionAmount += _amount;
        }

        boards[strikes[_strikeId].boardId].unrealizedProfit += int256(premium).sub(requiredAmount);

        optionId = createOptionPosition(_strikeId, _amount, _isPut, premium, _collateralAmount);

        require(isVaultSafe(optionPositions[optionId]), "OM8");

        if (_amount > 0) {
            TransferHelper.safeTransferFrom(usdc, msg.sender, address(this), premium);
        } else if (_amount < 0) {
            // TODO: optimize
            TransferHelper.safeTransferFrom(usdc, msg.sender, address(this), _collateralAmount);
            TransferHelper.safeTransfer(usdc, msg.sender, premium);
        }
    }

    // close position
    function closePosition(uint256 _positionId, uint256 _amount) external {
        OptionPosition storage optionPosition = optionPositions[_positionId];

        require(optionPosition.owner == msg.sender, "OM0");

        DataType.TradeOption memory tradeOption = DataType.TradeOption(
            false,
            true,
            false,
            true,
            Constants.MARGIN_STAY,
            Constants.MARGIN_STAY,
            0,
            0,
            bytes("")
        );

        int256 tradeAmount;

        if (optionPosition.amount > 0) {
            tradeAmount = -int256(_amount);

            require(optionPosition.amount >= -tradeAmount, "OM4");
        } else if (optionPosition.amount < 0) {
            tradeAmount = int256(_amount);

            require(-optionPosition.amount >= tradeAmount, "OM4");
        } else {
            revert("OM5");
        }

        // cover
        (uint256 premium, int256 requiredAmount) = _trade(
            optionPosition.strikeId,
            tradeAmount,
            tradeOption,
            optionPosition.isPut
        );

        if (optionPosition.isPut) {
            strikes[optionPosition.strikeId].putPositionAmount -= int256(_amount);
        } else {
            strikes[optionPosition.strikeId].callPositionAmount -= int256(_amount);
        }

        optionPosition.amount += tradeAmount;

        boards[strikes[optionPosition.strikeId].boardId].unrealizedProfit -= int256(premium) - requiredAmount;

        if (tradeAmount > 0) {
            TransferHelper.safeTransfer(usdc, msg.sender, optionPosition.collateralAmount - premium);
        } else if (tradeAmount < 0) {
            TransferHelper.safeTransfer(usdc, msg.sender, premium);
        }
    }

    /**
     * @notice Anyone can liquidate an unsafe short position.
     * @param _positionId The id of the position.
     */
    function liquidationCall(uint256 _positionId) external {
        OptionPosition storage optionPosition = optionPositions[_positionId];

        require(!isVaultSafe(optionPosition), "OM6");

        DataType.TradeOption memory tradeOption = DataType.TradeOption(
            false,
            true,
            false,
            true,
            Constants.MARGIN_STAY,
            Constants.MARGIN_STAY,
            0,
            0,
            bytes("")
        );

        int256 tradeAmount = -optionPosition.amount;

        (uint256 premium, int256 requiredAmount) = _trade(
            optionPosition.strikeId,
            tradeAmount,
            tradeOption,
            optionPosition.isPut
        );

        if (optionPosition.isPut) {
            strikes[optionPosition.strikeId].putPositionAmount += tradeAmount;
        } else {
            strikes[optionPosition.strikeId].callPositionAmount += tradeAmount;
        }

        optionPosition.amount = 0;

        boards[strikes[optionPosition.strikeId].boardId].unrealizedProfit -= int256(premium) - requiredAmount;

        // TODO: safeMath
        if (optionPosition.collateralAmount >= premium) {
            TransferHelper.safeTransfer(usdc, optionPosition.owner, optionPosition.collateralAmount - premium);
        }

        // TODO: liquidation reward
    }

    function isVaultSafe(OptionPosition memory _optionPosition) internal view returns (bool) {
        if (_optionPosition.amount >= 0) {
            return true;
        }

        uint256 twap = reader.getIndexPrice() / PriceHelper.PRICE_SCALER;

        Strike memory strike = strikes[_optionPosition.strikeId];

        uint256 timeToMaturity = boards[strike.boardId].expiration - block.timestamp;

        uint256 premium = BlackScholes.calculatePrice(
            twap,
            strike.strikePrice,
            timeToMaturity,
            getIV(_optionPosition.isPut ? strike.putPositionAmount : strike.callPositionAmount),
            _optionPosition.isPut
        );

        return (premium * 3) / 2 < _optionPosition.collateralAmount;
    }

    /**
     * @notice Exercise option board
     * anyone can exercise option board after expiration.
     * @param _boardId The id of the option board
     * @param _swapRatio todo
     */
    function exercise(uint256 _boardId, uint256 _swapRatio) external {
        require(boards[_boardId].expiration <= block.timestamp, "OM1");

        DataType.TradeOption memory tradeOption = DataType.TradeOption(
            false,
            true,
            false,
            true,
            Constants.MARGIN_USE,
            Constants.MARGIN_USE,
            Constants.FULL_WITHDRAWAL,
            Constants.FULL_WITHDRAWAL,
            bytes("")
        );

        DataType.ClosePositionOption memory closePositionOption = DataType.ClosePositionOption(
            0,
            type(uint256).max,
            _swapRatio,
            1e4,
            block.timestamp
        );

        {
            (uint256 indexPrice, int256 requiredAmount) = _exercise(tradeOption, closePositionOption);

            boards[_boardId].indexPrice = indexPrice;

            int256 totalProfit;

            for (uint256 i = 0; i < boards[_boardId].strikeIds.length; i++) {
                uint256 strikeId = boards[_boardId].strikeIds[i];

                totalProfit += SateliteLib.getProfit(
                    indexPrice,
                    strikes[strikeId].strikePrice,
                    strikes[strikeId].callPositionAmount,
                    false
                );

                totalProfit += SateliteLib.getProfit(
                    indexPrice,
                    strikes[strikeId].strikePrice,
                    strikes[strikeId].putPositionAmount,
                    true
                );
            }

            boards[_boardId].unrealizedProfit -= totalProfit + requiredAmount;
        }

        totalLiquidityAmount = PredyMath.addDelta(totalLiquidityAmount, boards[_boardId].unrealizedProfit);

        boards[_boardId].isExpired = true;
    }

    function claimProfit(uint256 _positionId) external {
        OptionPosition storage optionPosition = optionPositions[_positionId];
        Board memory board = boards[strikes[optionPosition.strikeId].boardId];

        require(optionPosition.owner == msg.sender, "OM0");
        require(board.isExpired, "OM2");

        int256 profit = SateliteLib.getProfit(
            board.indexPrice,
            strikes[optionPosition.strikeId].strikePrice,
            optionPosition.amount,
            optionPosition.isPut
        );

        uint256 collateralAmount = optionPosition.collateralAmount;

        optionPosition.amount = 0;
        optionPosition.collateralAmount = 0;

        // TODO: SafeMath
        TransferHelper.safeTransfer(usdc, msg.sender, uint256(int256(collateralAmount) + profit));
    }

    function _trade(
        uint256 _strikeId,
        int256 _amount,
        DataType.TradeOption memory tradeOption,
        bool _isPut
    ) internal returns (uint256 premium, int256 requiredAmount) {
        Strike memory strike = strikes[_strikeId];

        int256 poolAmount;

        if (_isPut) {
            poolAmount = strike.putPositionAmount;
        } else {
            poolAmount = strike.callPositionAmount;
        }

        uint256 beforeSqrtPrice = controller.getSqrtPrice();

        if (0 <= poolAmount && 0 < _amount) {
            requiredAmount = _addLong(_strikeId, uint256(_amount), tradeOption, _isPut);
        }
        if (0 <= poolAmount && 0 > _amount) {
            if (poolAmount < -_amount) {
                _removeLong(_strikeId, uint256(poolAmount), tradeOption, _isPut);
                requiredAmount = _addShort(_strikeId, uint256(-_amount - poolAmount), tradeOption, _isPut);
            } else {
                requiredAmount = _removeLong(_strikeId, uint256(-_amount), tradeOption, _isPut);
            }
        }

        if (0 > poolAmount && 0 > _amount) {
            requiredAmount = _addShort(_strikeId, uint256(-_amount), tradeOption, _isPut);
        }
        if (0 > poolAmount && 0 < _amount) {
            if (-poolAmount < _amount) {
                _removeShort(_strikeId, uint256(-poolAmount), tradeOption, _isPut);
                requiredAmount = _addLong(_strikeId, uint256(_amount + poolAmount), tradeOption, _isPut);
            } else {
                requiredAmount = _removeShort(_strikeId, uint256(_amount), tradeOption, _isPut);
            }
        }

        uint256 afterSqrtPrice = controller.getSqrtPrice();

        uint256 entryPrice = SateliteLib.getTradePrice(reader.isMarginZero(), beforeSqrtPrice, afterSqrtPrice);

        uint256 timeToMaturity = boards[strike.boardId].expiration - block.timestamp;

        premium = BlackScholes.calculatePrice(
            entryPrice,
            strike.strikePrice,
            timeToMaturity,
            getIV(_isPut ? strike.putPositionAmount : strike.callPositionAmount),
            _isPut
        );
    }

    function _addLong(
        uint256 _strikeId,
        uint256 _amount,
        DataType.TradeOption memory tradeOption,
        bool _isPut
    ) internal returns (int256 requiredAmount) {
        DataType.Position memory position = getPredyPosition(_strikeId, _amount, _isPut, true);

        DataType.OpenPositionOption memory openPositionOption = DataType.OpenPositionOption(
            0,
            type(uint256).max,
            100,
            block.timestamp
        );

        DataType.TokenAmounts memory requiredAmounts;

        (vaultId, requiredAmounts, ) = controller.openPosition(vaultId, position, tradeOption, openPositionOption);

        updateSubVaultId();

        if (reader.isMarginZero()) {
            return requiredAmounts.amount0;
        } else {
            return requiredAmounts.amount1;
        }
    }

    function _addShort(
        uint256 _strikeId,
        uint256 _amount,
        DataType.TradeOption memory tradeOption,
        bool _isPut
    ) internal returns (int256 requiredAmount) {
        DataType.Position memory position = getPredyPosition(_strikeId, _amount, _isPut, false);

        DataType.OpenPositionOption memory openPositionOption = DataType.OpenPositionOption(
            0,
            type(uint256).max,
            100,
            block.timestamp
        );

        DataType.TokenAmounts memory requiredAmounts;

        (vaultId, requiredAmounts, ) = controller.openPosition(vaultId, position, tradeOption, openPositionOption);

        updateSubVaultId();

        if (reader.isMarginZero()) {
            return requiredAmounts.amount0;
        } else {
            return requiredAmounts.amount1;
        }
    }

    function _removeLong(
        uint256 _strikeId,
        uint256 _amount,
        DataType.TradeOption memory tradeOption,
        bool _isPut
    ) internal returns (int256 requiredAmount) {
        DataType.Position[] memory positions = new DataType.Position[](1);

        positions[0] = getPredyPosition(_strikeId, _amount, _isPut, true);

        DataType.ClosePositionOption memory closePositionOption = DataType.ClosePositionOption(
            0,
            type(uint256).max,
            100,
            1e4,
            block.timestamp
        );

        DataType.TokenAmounts memory requiredAmounts;

        (requiredAmounts, ) = controller.closePosition(vaultId, positions, tradeOption, closePositionOption);

        updateSubVaultId();

        if (reader.isMarginZero()) {
            return requiredAmounts.amount0;
        } else {
            return requiredAmounts.amount1;
        }
    }

    function _removeShort(
        uint256 _strikeId,
        uint256 _amount,
        DataType.TradeOption memory tradeOption,
        bool _isPut
    ) internal returns (int256 requiredAmount) {
        DataType.Position[] memory positions = new DataType.Position[](1);

        positions[0] = getPredyPosition(_strikeId, _amount, _isPut, false);

        DataType.ClosePositionOption memory closePositionOption = DataType.ClosePositionOption(
            0,
            type(uint256).max,
            100,
            1e4,
            block.timestamp
        );

        DataType.TokenAmounts memory requiredAmounts;

        (requiredAmounts, ) = controller.closePosition(vaultId, positions, tradeOption, closePositionOption);

        updateSubVaultId();

        if (reader.isMarginZero()) {
            return requiredAmounts.amount0;
        } else {
            return requiredAmounts.amount1;
        }
    }

    function updateSubVaultId() internal {
        // Set SubVault ID
        DataType.Vault memory vault = controller.getVault(vaultId);

        if (vault.subVaults.length > 0) {
            subVaultId = vault.subVaults[0];
        } else {
            // if subVault removed
            subVaultId = 0;
        }
    }

    function _exercise(DataType.TradeOption memory tradeOption, DataType.ClosePositionOption memory closePositionOption)
        internal
        returns (uint256 indexPrice, int256 requiredAmount)
    {
        DataType.TokenAmounts memory requiredAmounts;
        DataType.TokenAmounts memory swapAmounts;

        DataType.Vault memory vault = controller.getVault(vaultId);

        (requiredAmounts, swapAmounts) = controller.closeSubVault(
            vaultId,
            vault.subVaults[0],
            tradeOption,
            closePositionOption
        );

        indexPrice = SateliteLib.getEntryPrice(reader.isMarginZero(), swapAmounts);

        if (reader.isMarginZero()) {
            requiredAmount = requiredAmounts.amount0;
        } else {
            requiredAmount = requiredAmounts.amount1;
        }
    }

    function getPredyPosition(
        uint256 _strikeId,
        uint256 _amount,
        bool _isPut,
        bool _isLong
    ) internal view returns (DataType.Position memory) {
        Strike memory strike = strikes[_strikeId];

        DataType.LPT[] memory lpts = new DataType.LPT[](1);

        uint256 baseUsdcAmount = calculateUSDValue(strike.lowerTick, strike.upperTick, strike.liquidity);

        if (_isLong) {
            lpts[0] = DataType.LPT(
                false,
                uint128((strike.liquidity * _amount) / 1e8),
                strike.lowerTick,
                strike.upperTick
            );

            if (_isPut) {
                return getPosition((baseUsdcAmount * _amount) / 1e8, 0, 0, 0, lpts);
            } else {
                return getPosition(0, (1e18 * _amount) / 1e8, 0, 0, lpts);
            }
        } else {
            lpts[0] = DataType.LPT(
                true,
                uint128((strike.liquidity * _amount) / 1e8),
                strike.lowerTick,
                strike.upperTick
            );

            if (_isPut) {
                return getPosition(0, 0, ((baseUsdcAmount * _amount) * 75) / 1e10, 0, lpts);
            } else {
                return getPosition(((baseUsdcAmount * _amount) * 25) / 1e10, 0, 0, (1e18 * _amount) / 1e8, lpts);
            }
        }
    }

    function createOptionPosition(
        uint256 _strikeId,
        int256 _amount,
        bool _isPut,
        uint256 _premium,
        uint256 _collateralAmount
    ) internal returns (uint256) {
        uint256 id = optionPositionCount;

        optionPositions[id] = OptionPosition(id, _strikeId, _amount, _isPut, msg.sender, _premium, _collateralAmount);

        optionPositionCount += 1;

        return id;
    }

    function getTradePrice(uint256 beforeSqrtPrice, uint256 afterSqrtPrice) internal pure returns (uint256) {
        uint256 entryPrice = (1e18 * Constants.Q96) / afterSqrtPrice;

        return (entryPrice * Constants.Q96) / beforeSqrtPrice;
    }

    function calculateStrikePrice(int24 _lowerTick, int24 _upperTick) internal pure returns (uint256) {
        uint160 sqrtPrice = TickMath.getSqrtRatioAtTick((_lowerTick + _upperTick) / 2);

        return PriceHelper.decodeSqrtPriceX96(true, sqrtPrice) / PriceHelper.PRICE_SCALER;
    }

    function calculateUSDValue(
        int24 _lowerTick,
        int24 _upperTick,
        uint128 _liquidity
    ) internal view returns (uint256 amount) {
        uint160 lowerSqrtPrice = TickMath.getSqrtRatioAtTick(_lowerTick);
        uint160 upperSqrtPrice = TickMath.getSqrtRatioAtTick(_upperTick);

        if (reader.isMarginZero()) {
            amount = LiquidityAmounts.getAmount0ForLiquidity(lowerSqrtPrice, upperSqrtPrice, _liquidity);
        } else {
            amount = LiquidityAmounts.getAmount1ForLiquidity(lowerSqrtPrice, upperSqrtPrice, _liquidity);
        }
    }

    function getMarginValue(
        Strike memory _strike,
        int256 _amount,
        bool _isPut
    ) internal view returns (uint256 marginValue) {
        uint256 currentPrice = reader.getPrice() / PriceHelper.PRICE_SCALER;

        uint256 instinctValue;

        if (_isPut && _strike.strikePrice > currentPrice) {
            instinctValue = _strike.strikePrice - currentPrice;
        }

        if (!_isPut && _strike.strikePrice < currentPrice) {
            instinctValue = currentPrice - _strike.strikePrice;
        }

        int256 poolAmount;

        if (_isPut) {
            poolAmount = _strike.putPositionAmount;
        } else {
            poolAmount = _strike.callPositionAmount;
        }

        marginValue = (currentPrice * PredyMath.abs(poolAmount + _amount)) / 1e8 / 2;
    }

    function getIV(int256 _poolPositionAmount) internal pure returns (uint256) {
        return 100 * 1e6;
    }

    function getPosition(
        uint256 asset0,
        uint256 asset1,
        uint256 debt0,
        uint256 debt1,
        DataType.LPT[] memory lpts
    ) internal view returns (DataType.Position memory) {
        if (reader.isMarginZero()) {
            return DataType.Position(subVaultId, asset0, asset1, debt0, debt1, lpts);
        } else {
            return DataType.Position(subVaultId, asset0, asset1, debt0, debt1, lpts);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

//SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.7.6;
pragma abicoder v2;

import "../libraries/DataType.sol";

interface IController {
    function openPosition(
        uint256 _vaultId,
        DataType.Position memory _position,
        DataType.TradeOption memory _tradeOption,
        DataType.OpenPositionOption memory _openPositionOptions
    )
        external
        returns (
            uint256 vaultId,
            DataType.TokenAmounts memory requiredAmounts,
            DataType.TokenAmounts memory swapAmounts
        );

    function updatePosition(
        uint256 _vaultId,
        DataType.PositionUpdate[] memory positionUpdates,
        DataType.TradeOption memory _tradeOption,
        DataType.OpenPositionOption memory _openPositionOptions
    )
        external
        returns (
            uint256 vaultId,
            DataType.TokenAmounts memory requiredAmounts,
            DataType.TokenAmounts memory swapAmounts
        );

    function closeSubVault(
        uint256 _vaultId,
        uint256 _subVaultIndex,
        DataType.TradeOption memory _tradeOption,
        DataType.ClosePositionOption memory _closePositionOptions
    ) external returns (DataType.TokenAmounts memory requiredAmounts, DataType.TokenAmounts memory swapAmounts);

    function closePosition(
        uint256 _vaultId,
        DataType.Position[] memory _positions,
        DataType.TradeOption memory _tradeOption,
        DataType.ClosePositionOption memory _closePositionOptions
    ) external returns (DataType.TokenAmounts memory requiredAmounts, DataType.TokenAmounts memory swapAmounts);

    function getSqrtPrice() external view returns (uint160 sqrtPriceX96);

    function getVaultValue(uint256 _vaultId) external view returns (int256);

    function getVault(uint256 _vaultId) external view returns (DataType.Vault memory);
}

//SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.7.6;

interface IReader {
    function isMarginZero() external view returns (bool);

    function getPrice() external view returns (uint256);

    function getIndexPrice() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.7.6;

import "./AdvancedMath.sol";

/**
 * @notice Option price calculator using Black-Scholes formula
 * B0: spot price must be between 0 and 10^13
 * B1: strike price must be between 0 and 10^13
 * B2: implied volatility must be between 0 and 1000%
 */
library BlackScholes {
    /// @dev sqrt(365 * 86400)
    int256 internal constant SQRT_YEAR_E8 = 5615.69229926 * 10**8;

    /**
     * @notice calculate option price at a IV point
     * @param _spot spot price scaled 1e8
     * @param _strike strike price scaled 1e8
     * @param _maturity maturity in seconds
     * @param _iv IV
     * @param _isPut option type
     * @return premium per amount
     */
    function calculatePrice(
        uint256 _spot,
        uint256 _strike,
        uint256 _maturity,
        uint256 _iv,
        bool _isPut
    ) internal pure returns (uint256 premium) {
        require(_spot > 0 && _spot < 1e13, "B0");
        require(_strike > 0 && _strike < 1e13, "B1");
        require(0 < _iv && _iv < 1000 * 1e6, "B2");

        int256 sqrtMaturity = getSqrtMaturity(_maturity);

        return uint256(calOptionPrice(int256(_spot), int256(_strike), sqrtMaturity, int256(_iv), _isPut));
    }

    function getSqrtMaturity(uint256 _maturity) public pure returns (int256) {
        require(
            _maturity > 0 && _maturity < 31536000,
            "PriceCalculator: maturity must not have expired and less than 1 year"
        );

        return (AdvancedMath.sqrt(int256(_maturity)) * 1e16) / SQRT_YEAR_E8;
    }

    function calOptionPrice(
        int256 _spot,
        int256 _strike,
        int256 _sqrtMaturity,
        int256 _volatility,
        bool _isPut
    ) internal pure returns (int256 price) {
        if (_volatility > 0) {
            int256 spotPerStrikeE4 = int256((_spot * 1e4) / _strike);
            int256 logSigE4 = AdvancedMath.logTaylor(spotPerStrikeE4);

            (int256 d1E4, int256 d2E4) = _calD1D2(logSigE4, _sqrtMaturity, _volatility);
            int256 nd1E8 = AdvancedMath.calStandardNormalCDF(d1E4);
            int256 nd2E8 = AdvancedMath.calStandardNormalCDF(d2E4);
            price = (_spot * nd1E8 - _strike * nd2E8) / 1e8;
        }

        int256 lowestPrice;
        if (_isPut) {
            price = price - _spot + _strike;

            lowestPrice = (_strike > _spot) ? _strike - _spot : int256(0);
        } else {
            lowestPrice = (_spot > _strike) ? _spot - _strike : int256(0);
        }

        if (price < lowestPrice) {
            return lowestPrice;
        }

        return price;
    }

    function _calD1D2(
        int256 _logSigE4,
        int256 _sqrtMaturity,
        int256 _volatilityE8
    ) internal pure returns (int256 d1E4, int256 d2E4) {
        int256 sigE8 = (_volatilityE8 * _sqrtMaturity) / (1e8);
        d1E4 = ((_logSigE4 * 10**8) / sigE8) + (sigE8 / (2 * 10**4));
        d2E4 = d1E4 - (sigE8 / 10**4);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.7.6;

import "lib/openzeppelin-contracts/contracts/math/SignedSafeMath.sol";
import "lib/v3-periphery/contracts/libraries/LiquidityAmounts.sol";
import "lib/v3-core/contracts/libraries/TickMath.sol";
import "../libraries/Constants.sol";
import "../libraries/PredyMath.sol";
import "../libraries/DataType.sol";

library SateliteLib {
    using SignedSafeMath for int256;

    function getProfit(
        uint256 indexPrice,
        uint256 strikePrice,
        int256 _amount,
        bool _isPut
    ) internal pure returns (int256) {
        uint256 instinctValue;

        if (_isPut && strikePrice > indexPrice) {
            instinctValue = strikePrice - indexPrice;
        }

        if (!_isPut && strikePrice < indexPrice) {
            instinctValue = indexPrice - strikePrice;
        }

        return (int256(instinctValue) * _amount) / 1e8;
    }

    function getBaseLiquidity(
        bool _isMarginZero,
        int24 _lower,
        int24 _upper
    ) internal pure returns (uint128) {
        if (_isMarginZero) {
            return
                LiquidityAmounts.getLiquidityForAmount1(
                    TickMath.getSqrtRatioAtTick(_lower),
                    TickMath.getSqrtRatioAtTick(_upper),
                    1e18
                );
        } else {
            return
                LiquidityAmounts.getLiquidityForAmount0(
                    TickMath.getSqrtRatioAtTick(_lower),
                    TickMath.getSqrtRatioAtTick(_upper),
                    1e18
                );
        }
    }

    function getTradePrice(
        bool _isMarginZero,
        uint256 beforeSqrtPrice,
        uint256 afterSqrtPrice
    ) internal pure returns (uint256) {
        if (_isMarginZero) {
            uint256 entryPrice = (1e18 * Constants.Q96) / afterSqrtPrice;

            return (entryPrice * Constants.Q96) / beforeSqrtPrice;
        } else {
            uint256 entryPrice = (afterSqrtPrice * 1e18) / Constants.Q96;

            return (entryPrice * beforeSqrtPrice) / Constants.Q96;
        }
    }

    function getEntryPrice(bool _isMarginZero, DataType.TokenAmounts memory swapAmounts)
        internal
        pure
        returns (uint256)
    {
        int256 price;

        if (_isMarginZero) {
            price = (swapAmounts.amount0 * 1e18) / swapAmounts.amount1;
        } else {
            price = (swapAmounts.amount1 * 1e18) / swapAmounts.amount0;
        }

        return PredyMath.abs(price);
    }
}

/// from https://github.com/LienFinance/bondmaker
pragma solidity ^0.7.6;

library AdvancedMath {
    /// @dev sqrt(2*PI) * 10^8
    int256 internal constant SQRT_2PI_E8 = 250662827;
    /// @dev PI * 10^8
    int256 internal constant PI_E8 = 314159265;
    /// @dev Napier's constant
    int256 internal constant E_E8 = 271828182;
    /// @dev Inverse of Napier's constant (1/e)
    int256 internal constant INV_E_E8 = 36787944;

    // for CDF
    int256 internal constant p = 23164190;
    int256 internal constant b1 = 31938153;
    int256 internal constant b2 = -35656378;
    int256 internal constant b3 = 178147793;
    int256 internal constant b4 = -182125597;
    int256 internal constant b5 = 133027442;

    /**
     * @dev Calculate an approximate value of the square root of x by Babylonian method.
     */
    function sqrt(int256 x) internal pure returns (int256 y) {
        require(x >= 0, "cannot calculate the square root of a negative number");
        int256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    /**
     * @dev Returns log(x) for any positive x.
     */
    function logTaylor(int256 inputE4) internal pure returns (int256 outputE4) {
        require(inputE4 > 1, "input should be positive number");
        int256 inputE8 = inputE4 * 1e4;
        // input x for _logTaylor1 is adjusted to 1/e < x < 1.
        while (inputE8 < INV_E_E8) {
            inputE8 = (inputE8 * E_E8) / 1e8;
            outputE4 -= 1e4;
        }
        while (inputE8 > 1e8) {
            inputE8 = (inputE8 * INV_E_E8) / 1e8;
            outputE4 += 1e4;
        }
        outputE4 += logTaylor1(inputE8 / 1e4 - 1e4);
    }

    /**
     * @notice Calculate an approximate value of the logarithm of input value by
     * Taylor expansion around 1.
     * @dev log(x + 1) = x - 1/2 x^2 + 1/3 x^3 - 1/4 x^4 + 1/5 x^5
     *                     - 1/6 x^6 + 1/7 x^7 - 1/8 x^8 + ...
     */
    function logTaylor1(int256 inputE4) internal pure returns (int256 outputE4) {
        outputE4 =
            inputE4 -
            inputE4**2 /
            (2 * 1e4) +
            inputE4**3 /
            (3 * 1e8) -
            inputE4**4 /
            (4 * 1e12) +
            inputE4**5 /
            (5 * 1e16) -
            inputE4**6 /
            (6 * 1e20) +
            inputE4**7 /
            (7 * 1e24) -
            inputE4**8 /
            (8 * 1e28);
    }

    /**
     * @notice Calculate the cumulative distribution function of standard normal
     * distribution.
     * @dev Abramowitz and Stegun, Handbook of Mathematical Functions (1964)
     * http://people.math.sfu.ca/~cbm/aands/
     * errors are less than 0.7% at -3.2
     */
    function calStandardNormalCDF(int256 inputE4) internal pure returns (int256 outputE8) {
        require(inputE4 < 440 * 1e4 && inputE4 > -440 * 1e4, "input is too large");
        int256 _inputE4 = inputE4 > 0 ? inputE4 : inputE4 * (-1);
        int256 t = 1e16 / (1e8 + (p * _inputE4) / 1e4);
        int256 X2 = (inputE4 * inputE4) / 2;
        int256 X3 = (X2 * X2) / 1e8;
        int256 X4 = (X3 * X2) / 1e8;
        int256 exp2X2 = 1e8 +
            X2 +
            (X3 / 2) +
            (X4 / 6) +
            ((X3 * X3) / (24 * 1e8)) +
            ((X2 * (X3 * X3)) / (120 * 1e16)) +
            ((X4 * X4) / (720 * 1e8)) +
            ((X2 * (X4 * X4)) / (5040 * 1e16)) +
            ((X3 * (X4 * X4)) / (40320 * 1e16)) +
            ((X4 * X4 * X4) / (362880 * 1e16)) +
            ((X2 * (X4 * X4 * X4)) / (3628800 * 1e24)) +
            ((X3 * (X4 * X4 * X4)) / (39916800 * 1e24));

        int256 Z = (1e24 / exp2X2) / SQRT_2PI_E8;
        int256 y = (b5 * t) / 1e8;
        y = ((y + b4) * t) / 1e8;
        y = ((y + b3) * t) / 1e8;
        y = ((y + b2) * t) / 1e8;
        y = 1e8 - (Z * ((y + b1) * t)) / 1e16;
        return inputE4 > 0 ? y : 1e8 - y;
    }
}

//SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.7.6;
pragma abicoder v2;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/math/SafeMath.sol";
import "lib/openzeppelin-contracts/contracts/math/SignedSafeMath.sol";
import "lib/openzeppelin-contracts/contracts/utils/SafeCast.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import {TransferHelper} from "lib/v3-periphery/contracts/libraries/TransferHelper.sol";
import "../interfaces/IController.sol";
import "../interfaces/IReader.sol";
import "../interfaces/IVaultNFT.sol";
import "../libraries/Constants.sol";
import "../libraries/PriceHelper.sol";
import "./SateliteLib.sol";
import "./FutureMarketLib.sol";

/**
 * FM0: caller is not vault owner
 * FM1: vault must be safe
 * FM2: vault must not be safe
 */
contract FutureMarket is ERC20, IERC721Receiver, Ownable {
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using SafeCast for int256;

    int256 private constant FUNDING_PERIOD = 1 days;

    IController internal immutable controller;

    IReader internal immutable reader;

    address internal immutable usdc;

    address private vaultNFT;

    uint256 public vaultId;
    uint256 public subVaultId;

    struct Range {
        uint256 id;
        uint128 liquidity;
        int24 lowerTick;
        int24 upperTick;
    }

    struct PoolPosition {
        int256 positionAmount;
        uint256 entryPrice;
        int256 entryFundingFee;
        uint256 usdcAmount;
    }

    mapping(uint256 => Range) private ranges;

    mapping(uint256 => FutureMarketLib.FutureVault) private futureVaults;

    uint256 public futureVaultCount;

    uint256 private currentRangeId;

    PoolPosition public poolPosition;

    int256 private fundingFeePerPosition;

    uint256 private lastTradeTimestamp;

    event MarginUpdated(uint256 indexed vaultId, address trader, int256 marginAmount);

    event PositionUpdated(
        uint256 indexed vaultId,
        address trader,
        int256 tradeAmount,
        uint256 tradePrice,
        int256 fundingFeePerPosition,
        int256 deltaUsdcPosition
    );

    event Liquidated(
        uint256 indexed vaultId,
        address liquidator,
        int256 tradeAmount,
        uint256 tradePrice,
        int256 fundingFeePerPosition,
        int256 deltaUsdcPosition,
        uint256 liquidationPenalty
    );

    constructor(
        address _controller,
        address _reader,
        address _usdc,
        address _vaultNFT
    ) ERC20("PredyFutureLP", "PFLP") {
        controller = IController(_controller);
        reader = IReader(_reader);
        usdc = _usdc;
        vaultNFT = _vaultNFT;

        ERC20(_usdc).approve(address(_controller), type(uint256).max);

        futureVaultCount = 1;

        lastTradeTimestamp = block.timestamp;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function setRange(
        uint256 _id,
        int24 _lowerTick,
        int24 _upperTick
    ) external onlyOwner {
        uint128 liquidity = SateliteLib.getBaseLiquidity(reader.isMarginZero(), _lowerTick, _upperTick);

        ranges[_id] = Range(_id, liquidity, _lowerTick, _upperTick);
    }

    function setCurrentRangeId(uint256 _currentRangeId) external onlyOwner {
        currentRangeId = _currentRangeId;
    }

    function getLPTokenPrice() external view returns (uint256) {
        return (Constants.ONE * getPoolValue(getIndexPrice())) / totalSupply();
    }

    function deposit(uint256 _amount) external returns (uint256 mintAmount) {
        updateFundingPaidPerPosition();

        uint256 poolValue = getPoolValue(getIndexPrice());

        if (poolValue == 0 || totalSupply() == 0) {
            mintAmount = _amount;
        } else {
            mintAmount = (_amount * totalSupply()) / poolValue;
        }

        poolPosition.usdcAmount += _amount;

        TransferHelper.safeTransferFrom(usdc, msg.sender, address(this), _amount);

        _mint(msg.sender, mintAmount);
    }

    function withdraw(uint256 _amount) external returns (uint256 burnAmount) {
        updateFundingPaidPerPosition();

        uint256 poolValue = getPoolValue(getIndexPrice());

        burnAmount = (_amount * totalSupply()) / poolValue;

        poolPosition.usdcAmount = poolPosition.usdcAmount.sub(_amount);

        TransferHelper.safeTransfer(usdc, msg.sender, _amount);

        _burn(msg.sender, burnAmount);
    }

    function getPoolValue(uint256 _price) internal view returns (uint256) {
        int256 positionValue = int256(_price)
            .sub(int256(poolPosition.entryPrice).add(fundingFeePerPosition.sub(poolPosition.entryFundingFee)))
            .mul(poolPosition.positionAmount) / 1e18;

        int256 vaultValue = controller.getVaultValue(vaultId);

        return positionValue.add(vaultValue).add(int256(poolPosition.usdcAmount)).toUint256();
    }

    function updateMargin(uint256 _vaultId, int256 _marginAmount) external returns (uint256 traderVaultId) {
        require(_marginAmount != 0);

        FutureMarketLib.FutureVault storage futureVault;

        (traderVaultId, futureVault) = _createOrGetVault(_vaultId, false);

        futureVault.marginAmount = PredyMath.addDelta(futureVault.marginAmount, _marginAmount);

        require(isVaultSafe(futureVault), "FM1");

        if (_marginAmount > 0) {
            TransferHelper.safeTransferFrom(usdc, msg.sender, address(this), uint256(_marginAmount));
        } else if (_marginAmount < 0) {
            TransferHelper.safeTransfer(usdc, msg.sender, uint256(-_marginAmount));
        }

        emit MarginUpdated(traderVaultId, msg.sender, _marginAmount);
    }

    function trade(
        uint256 _vaultId,
        int256 _amount,
        bool _quoterMode
    ) external returns (uint256 traderVaultId) {
        updateFundingPaidPerPosition();

        uint256 entryPrice = _updatePoolPosition(_amount);

        if (_quoterMode) {
            revertEntryPrice(entryPrice);
        }

        FutureMarketLib.FutureVault storage futureVault;

        (traderVaultId, futureVault) = _createOrGetVault(_vaultId, _quoterMode);

        int256 deltaUsdcPosition = _updateTraderPosition(futureVault, _amount, entryPrice);

        emit PositionUpdated(traderVaultId, msg.sender, _amount, entryPrice, fundingFeePerPosition, deltaUsdcPosition);
    }

    function liquidationCall(uint256 _vaultId) external {
        updateFundingPaidPerPosition();

        FutureMarketLib.FutureVault storage futureVault = futureVaults[_vaultId];

        require(!isVaultSafe(futureVault), "FM2");

        int256 tradeAmount = -futureVaults[_vaultId].positionAmount;

        uint256 entryPrice = _updatePoolPosition(tradeAmount);

        int256 deltaUsdcPosition = _updateTraderPosition(futureVault, tradeAmount, entryPrice);

        uint256 liquidationPenalty = _decreaesLiquidationPenalty(futureVault, tradeAmount, entryPrice);

        emit Liquidated(
            _vaultId,
            msg.sender,
            tradeAmount,
            entryPrice,
            fundingFeePerPosition,
            deltaUsdcPosition,
            liquidationPenalty
        );
    }

    function rebalance() external {
        DataType.TradeOption memory tradeOption = DataType.TradeOption(
            false,
            true,
            false,
            true,
            Constants.MARGIN_USE,
            Constants.MARGIN_STAY,
            int256(getMarginValue(0)),
            0,
            bytes("")
        );

        DataType.OpenPositionOption memory openPositionOption = DataType.OpenPositionOption(
            0,
            type(uint256).max,
            100,
            block.timestamp
        );

        DataType.PositionUpdate[] memory positionUpdates = _rebalance(
            controller.getSqrtPrice(),
            PredyMath.abs(poolPosition.positionAmount)
        );

        positionUpdates[positionUpdates.length - 1] = _cover(poolPosition.positionAmount);

        DataType.TokenAmounts memory requiredAmounts;

        (vaultId, requiredAmounts, ) = controller.updatePosition(
            vaultId,
            positionUpdates,
            tradeOption,
            openPositionOption
        );

        // Set SubVault ID
        subVaultId = controller.getVault(vaultId).subVaults[0];

        poolPosition.usdcAmount = PredyMath.addDelta(
            poolPosition.usdcAmount,
            reader.isMarginZero() ? -requiredAmounts.amount0 : -requiredAmounts.amount1
        );
    }

    function getVaultStatus(uint256 _vaultId)
        internal
        view
        returns (
            int256,
            uint256,
            uint256
        )
    {
        FutureMarketLib.FutureVault memory futureVault = futureVaults[_vaultId];

        uint256 twap = getIndexPrice();

        uint256 minCollateral = FutureMarketLib.calculateMinCollateral(futureVault, twap);

        int256 vaultValue = getVaultValue(futureVault, twap);

        return (vaultValue, futureVault.marginAmount, minCollateral);
    }

    function getMarginValue(int256 _amount) internal view returns (uint256 marginValue) {
        uint256 currentPrice = reader.getPrice() / PriceHelper.PRICE_SCALER;

        marginValue = (currentPrice * PredyMath.abs(poolPosition.positionAmount + _amount)) / 1e18 / 3;
    }

    function _updatePoolPosition(int256 _amount) internal returns (uint256 entryPrice) {
        {
            DataType.TradeOption memory tradeOption = DataType.TradeOption(
                false,
                true,
                false,
                true,
                Constants.MARGIN_USE,
                Constants.MARGIN_STAY,
                int256(getMarginValue(_amount)),
                0,
                bytes("")
            );

            entryPrice = _coverAndRebalance(poolPosition.positionAmount, _amount, tradeOption);
        }

        {
            int256 deltaMarginAmount;

            {
                (int256 newEntryPrice, int256 profitValue) = FutureMarketLib.updateEntryPrice(
                    int256(poolPosition.entryPrice),
                    poolPosition.positionAmount,
                    int256(entryPrice),
                    _amount
                );

                poolPosition.entryPrice = newEntryPrice.toUint256();
                deltaMarginAmount = deltaMarginAmount.add(profitValue);
            }

            {
                (int256 entryFundingFee, int256 profitValue) = FutureMarketLib.updateEntryPrice(
                    int256(poolPosition.entryFundingFee),
                    poolPosition.positionAmount,
                    int256(fundingFeePerPosition),
                    _amount
                );

                poolPosition.entryFundingFee = entryFundingFee;
                deltaMarginAmount = deltaMarginAmount.add(profitValue);
            }

            poolPosition.usdcAmount = PredyMath.addDelta(poolPosition.usdcAmount, deltaMarginAmount);
        }

        poolPosition.positionAmount = poolPosition.positionAmount.sub(_amount);
    }

    function _updateTraderPosition(
        FutureMarketLib.FutureVault storage _futureVault,
        int256 _amount,
        uint256 _entryPrice
    ) internal returns (int256 deltaMarginAmount) {
        {
            (int256 newEntryPrice, int256 profitValue) = FutureMarketLib.updateEntryPrice(
                int256(_futureVault.entryPrice),
                _futureVault.positionAmount,
                int256(_entryPrice),
                _amount
            );

            _futureVault.entryPrice = newEntryPrice.toUint256();
            deltaMarginAmount = deltaMarginAmount.add(profitValue);
        }

        {
            (int256 entryFundingFee, int256 profitValue) = FutureMarketLib.updateEntryPrice(
                int256(_futureVault.entryFundingFee),
                _futureVault.positionAmount,
                int256(fundingFeePerPosition),
                _amount
            );

            _futureVault.entryFundingFee = entryFundingFee;
            deltaMarginAmount = deltaMarginAmount.add(profitValue);
        }

        _futureVault.positionAmount = _futureVault.positionAmount.add(_amount);

        _futureVault.marginAmount = PredyMath.addDelta(_futureVault.marginAmount, deltaMarginAmount);

        require(isVaultSafe(_futureVault), "FM1");
    }

    function _decreaesLiquidationPenalty(
        FutureMarketLib.FutureVault storage _futureVault,
        int256 _tradeAmount,
        uint256 _entryPrice
    ) internal returns (uint256 penaltyAmount) {
        penaltyAmount = (PredyMath.abs(_tradeAmount) * _entryPrice) / (1e18 * 500);

        _futureVault.marginAmount = _futureVault.marginAmount.sub(penaltyAmount);
    }

    function isVaultSafe(FutureMarketLib.FutureVault memory _futureVault) internal view returns (bool) {
        if (_futureVault.positionAmount == 0) {
            return true;
        }

        // TODO: use chainlink
        uint256 twap = getIndexPrice();

        uint256 minCollateral = FutureMarketLib.calculateMinCollateral(_futureVault, twap);

        int256 vaultValue = getVaultValue(_futureVault, twap);

        return vaultValue > int256(minCollateral);
    }

    function getVaultValue(FutureMarketLib.FutureVault memory _futureVault, uint256 _price)
        internal
        view
        returns (int256)
    {
        int256 positionValue = int256(_price)
            .sub(int256(_futureVault.entryPrice).add(fundingFeePerPosition.sub(_futureVault.entryFundingFee)))
            .mul(_futureVault.positionAmount) / 1e18;

        return positionValue.add(int256(_futureVault.marginAmount));
    }

    function _createOrGetVault(uint256 _vaultId, bool _quoterMode)
        internal
        returns (uint256 futureVaultId, FutureMarketLib.FutureVault storage)
    {
        if (_vaultId == 0) {
            futureVaultId = IVaultNFT(vaultNFT).mintNFT(msg.sender);
        } else {
            futureVaultId = _vaultId;

            require(IVaultNFT(vaultNFT).ownerOf(futureVaultId) == msg.sender || _quoterMode, "FM0");
        }

        return (futureVaultId, futureVaults[futureVaultId]);
    }

    function _coverAndRebalance(
        int256 _poolPosition,
        int256 _amount,
        DataType.TradeOption memory tradeOption
    ) internal returns (uint256 entryPrice) {
        DataType.OpenPositionOption memory openPositionOption = DataType.OpenPositionOption(
            0,
            type(uint256).max,
            100,
            block.timestamp
        );

        DataType.PositionUpdate[] memory positionUpdates = _rebalanceUpdate(
            int256(PredyMath.abs(_poolPosition.add(_amount))).sub(int256(PredyMath.abs(_poolPosition)))
        );

        positionUpdates[positionUpdates.length - 1] = _cover(poolPosition.positionAmount);

        DataType.TokenAmounts memory requiredAmounts;
        DataType.TokenAmounts memory swapAmounts;

        (vaultId, requiredAmounts, swapAmounts) = controller.updatePosition(
            vaultId,
            positionUpdates,
            tradeOption,
            openPositionOption
        );
        // Set SubVault ID
        subVaultId = controller.getVault(vaultId).subVaults[0];

        poolPosition.usdcAmount = PredyMath.addDelta(
            poolPosition.usdcAmount,
            reader.isMarginZero() ? -requiredAmounts.amount0 : -requiredAmounts.amount1
        );

        entryPrice = SateliteLib.getEntryPrice(reader.isMarginZero(), swapAmounts);
    }

    function _cover(int256 _poolPosition) internal view returns (DataType.PositionUpdate memory) {
        uint256 delta = calculateDelta(PredyMath.abs(_poolPosition));

        int256 amount = _poolPosition.add(int256(delta));
        bool isMarginZero = reader.isMarginZero();

        if (amount > 0) {
            return
                DataType.PositionUpdate(
                    DataType.PositionUpdateType.BORROW_TOKEN,
                    subVaultId,
                    false,
                    0,
                    0,
                    0,
                    isMarginZero ? 0 : uint256(amount),
                    isMarginZero ? uint256(amount) : 0
                );
        } else if (amount < 0) {
            return
                DataType.PositionUpdate(
                    DataType.PositionUpdateType.DEPOSIT_TOKEN,
                    subVaultId,
                    false,
                    0,
                    0,
                    0,
                    isMarginZero ? 0 : uint256(-amount),
                    isMarginZero ? uint256(-amount) : 0
                );
        } else {
            return DataType.PositionUpdate(DataType.PositionUpdateType.NOOP, 0, false, 0, 0, 0, 0, 0);
        }
    }

    function _rebalance(uint160 _sqrtPrice, uint256 _poolPosition)
        internal
        view
        returns (DataType.PositionUpdate[] memory positionUpdates)
    {
        int24 currentTick = TickMath.getTickAtSqrtRatio(_sqrtPrice);

        if (ranges[currentRangeId].lowerTick > currentTick && ranges[currentRangeId - 1].liquidity > 0) {
            return _rebalanceSwitch(currentRangeId, currentRangeId - 1, _poolPosition);
        }

        if (ranges[currentRangeId].upperTick < currentTick && ranges[currentRangeId + 1].liquidity > 0) {
            return _rebalanceSwitch(currentRangeId, currentRangeId + 1, _poolPosition);
        }
    }

    function _rebalanceUpdate(int256 _amount) internal view returns (DataType.PositionUpdate[] memory positionUpdates) {
        positionUpdates = new DataType.PositionUpdate[](2);

        if (_amount > 0) {
            positionUpdates[0] = DataType.PositionUpdate(
                DataType.PositionUpdateType.DEPOSIT_LPT,
                subVaultId,
                false,
                uint128(uint256(_amount).mul(ranges[currentRangeId].liquidity) / 1e18),
                ranges[currentRangeId].lowerTick,
                ranges[currentRangeId].upperTick,
                0,
                0
            );
        } else if (_amount < 0) {
            positionUpdates[0] = DataType.PositionUpdate(
                DataType.PositionUpdateType.WITHDRAW_LPT,
                subVaultId,
                false,
                uint128(uint256(-_amount).mul(ranges[currentRangeId].liquidity) / 1e18),
                ranges[currentRangeId].lowerTick,
                ranges[currentRangeId].upperTick,
                0,
                0
            );
        }
    }

    function _rebalanceSwitch(
        uint256 _prevRangeId,
        uint256 _nextRangeId,
        uint256 _amount
    ) internal view returns (DataType.PositionUpdate[] memory positionUpdates) {
        positionUpdates = new DataType.PositionUpdate[](3);

        positionUpdates[0] = DataType.PositionUpdate(
            DataType.PositionUpdateType.WITHDRAW_LPT,
            subVaultId,
            false,
            uint128(_amount.mul(ranges[_prevRangeId].liquidity) / 1e18),
            ranges[_prevRangeId].lowerTick,
            ranges[_prevRangeId].upperTick,
            0,
            0
        );
        positionUpdates[1] = DataType.PositionUpdate(
            DataType.PositionUpdateType.DEPOSIT_LPT,
            subVaultId,
            false,
            uint128(_amount.mul(ranges[_nextRangeId].liquidity) / 1e18),
            ranges[_nextRangeId].lowerTick,
            ranges[_nextRangeId].upperTick,
            0,
            0
        );
    }

    function calculateDelta(uint256 _poolPosition) internal view returns (uint256 delta) {
        Range memory range = ranges[currentRangeId];

        (uint256 amount0, uint256 amount1) = LiquidityAmounts.getAmountsForLiquidity(
            controller.getSqrtPrice(),
            TickMath.getSqrtRatioAtTick(range.lowerTick),
            TickMath.getSqrtRatioAtTick(range.upperTick),
            uint128((range.liquidity * _poolPosition) / 1e18)
        );

        if (reader.isMarginZero()) {
            return amount1;
        } else {
            return amount0;
        }
    }

    function updateFundingPaidPerPosition() internal {
        updateFundingPaidPerPosition(getIndexPrice(), calculateFundingRate());
    }

    function updateFundingPaidPerPosition(uint256 twap, int256 fundingRate) internal {
        int256 fundingPaid = (int256(twap) * fundingRate) / 1e18;

        fundingFeePerPosition = fundingFeePerPosition.add(
            int256(block.timestamp - lastTradeTimestamp).mul(fundingPaid) / FUNDING_PERIOD
        );
        lastTradeTimestamp = block.timestamp;
    }

    function calculateFundingRate() internal view returns (int256) {
        if (poolPosition.positionAmount > 0) {
            return 1e14;
        } else {
            return -1e14;
        }
    }

    function revertEntryPrice(uint256 _entryPrice) internal pure {
        assembly {
            let ptr := mload(0x20)
            mstore(ptr, _entryPrice)
            revert(ptr, 32)
        }
    }

    function getIndexPrice() internal view returns (uint256) {
        return reader.getIndexPrice() / PriceHelper.PRICE_SCALER;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.7.6;

import "lib/openzeppelin-contracts/contracts/math/SignedSafeMath.sol";
import "lib/v3-periphery/contracts/libraries/LiquidityAmounts.sol";
import "lib/v3-core/contracts/libraries/TickMath.sol";
import "../libraries/Constants.sol";
import "../libraries/PredyMath.sol";

library FutureMarketLib {
    using SignedSafeMath for int256;

    struct FutureVault {
        uint256 id;
        address owner;
        int256 positionAmount;
        uint256 entryPrice;
        int256 entryFundingFee;
        uint256 marginAmount;
    }

    function updateEntryPrice(
        int256 _entryPrice,
        int256 _position,
        int256 _tradePrice,
        int256 _positionTrade
    ) internal pure returns (int256 newEntryPrice, int256 profitValue) {
        int256 newPosition = _position.add(_positionTrade);
        if (_position == 0 || (_position > 0 && _positionTrade > 0) || (_position < 0 && _positionTrade < 0)) {
            newEntryPrice = (
                _entryPrice.mul(int256(PredyMath.abs(_position))).add(
                    _tradePrice.mul(int256(PredyMath.abs(_positionTrade)))
                )
            ).div(int256(PredyMath.abs(_position.add(_positionTrade))));
        } else if (
            (_position > 0 && _positionTrade < 0 && newPosition > 0) ||
            (_position < 0 && _positionTrade > 0 && newPosition < 0)
        ) {
            newEntryPrice = _entryPrice;
            profitValue = (-_positionTrade).mul(_tradePrice.sub(_entryPrice)) / 1e18;
        } else {
            if (newPosition != 0) {
                newEntryPrice = _tradePrice;
            }

            profitValue = _position.mul(_tradePrice.sub(_entryPrice)) / 1e18;
        }
    }

    /**
     * @notice Calculates MinCollateral of vault positions.
     * MinCollateral := Min{Max{0.014 * Sqrt{PositionAmount}, 0.1}, 0.2} * TWAP * PositionAmount
     */
    function calculateMinCollateral(FutureVault memory _futureVault, uint256 _twap) internal pure returns (uint256) {
        uint256 positionAmount = PredyMath.abs(_futureVault.positionAmount);

        uint256 minCollateralRatio = PredyMath.min(
            PredyMath.max((14 * 1e15 * PredyMath.sqrt(positionAmount * 1e18)) / 1e18, 10 * 1e16),
            20 * 1e16
        );

        uint256 minCollateral = (_twap * positionAmount) / 1e18;

        return (minCollateral * minCollateralRatio) / 1e18;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../utils/Context.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "../../introspection/ERC165.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";
import "../../utils/EnumerableSet.sol";
import "../../utils/EnumerableMap.sol";
import "../../utils/Strings.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || ERC721.isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || ERC721.isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId); // internal owner

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own"); // internal owner
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId); // internal owner
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) return (false, 0); // Equivalent to contains(map, key)
        return (true, map._entries[keyIndex - 1]._value); // All indexes are 1-based
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, "EnumerableMap: nonexistent key"); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

//SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.7.6;

import "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Initializable} from "lib/openzeppelin-contracts/contracts/proxy/Initializable.sol";
import "./interfaces/IVaultNFT.sol";

/**
 * @notice ERC721 representing ownership of a vault
 */
contract VaultNFT is ERC721, IVaultNFT, Initializable {
    uint256 public override nextId = 1;

    address public controller;
    address private immutable deployer;

    modifier onlyController() {
        require(msg.sender == controller, "Not Controller");
        _;
    }

    /**
     * @notice Vault NFT constructor
     * @param _name token name for ERC721
     * @param _symbol token symbol for ERC721
     * @param _baseURI base URI
     */
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI
    ) ERC721(_name, _symbol) {
        deployer = msg.sender;
        _setBaseURI(_baseURI);
    }

    /**
     * @notice Initializes Vault NFT
     * @param _controller Perpetual Market address
     */
    function init(address _controller) public initializer {
        require(msg.sender == deployer, "Caller is not deployer");
        require(_controller != address(0), "Zero address");
        controller = _controller;
    }

    /**
     * @notice mint new NFT
     * @dev auto increment tokenId starts from 1
     * @param _recipient recipient address for NFT
     */
    function mintNFT(address _recipient) external override onlyController returns (uint256 tokenId) {
        _safeMint(_recipient, (tokenId = nextId++));
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/**
 * @notice Mock of ERC20 contract
 */
contract MockWETH is ERC20 {
    uint8 _decimals;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 __decimals
    ) ERC20(_name, _symbol) {
        _decimals = __decimals;
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/**
 * @notice Mock of ERC20 contract
 */
contract MockERC20 is ERC20 {
    uint8 _decimals;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 __decimals
    ) ERC20(_name, _symbol) {
        _decimals = __decimals;
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}