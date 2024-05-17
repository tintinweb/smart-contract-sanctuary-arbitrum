// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { GMXV2GMStrategyErrors } from "./libraries/GMXV2GMStrategyErrors.sol";
import { IStrategyHelper } from "../../interfaces/dollet/IStrategyHelper.sol";
import { IStrategyV2 } from "../../interfaces/dollet/IStrategyV2.sol";
import { IGMXV2GMStrategy } from "./interfaces/IGMXV2GMStrategy.sol";
import { AddressUtils } from "../../libraries/AddressUtils.sol";
import { ERC20Lib } from "../../libraries/ERC20Lib.sol";
import { StrategyV2 } from "../StrategyV2.sol";
import {
    IExchangeRouter,
    IWithdrawal,
    IEventUtils,
    IDeposit,
    IHandler,
    IMarket,
    IReader,
    IPrice
} from "./interfaces/IGMXV2GM.sol";

/**
 * @title Dollet GMXV2GMStrategy contract
 * @author Dollet Team
 * @notice An implementation of the GMXV2GMStrategy contract.
 */
contract GMXV2GMStrategy is StrategyV2, IGMXV2GMStrategy {
    using AddressUtils for address;

    IExchangeRouter public exchangeRouter;
    IReader public reader;
    address public dataStore;
    address public longToken; // Volatile asset
    address public shortToken; // Stable asset
    address public depositHandler;
    address public withdrawalHandler;
    address public depositVault;
    address public withdrawalVault;
    uint256 public callbackGasLimit;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes this contract with initial values.
     * @param _initParams Strategy initialization parameters structure.
     */
    function initialize(InitParams calldata _initParams) external initializer {
        _setExchangeRouter(_initParams.gmxV2GmInitParams.exchangeRouter);
        _setReader(_initParams.gmxV2GmInitParams.reader);
        _setDataStore(_initParams.gmxV2GmInitParams.dataStore);
        _setDepositHandler(_initParams.gmxV2GmInitParams.depositHandler);
        _setWithdrawalHandler(_initParams.gmxV2GmInitParams.withdrawalHandler);

        IMarket.Props memory _marketInfo = IReader(_initParams.gmxV2GmInitParams.reader).getMarket(
            _initParams.gmxV2GmInitParams.dataStore, _initParams.want
        );

        longToken = _marketInfo.longToken;
        shortToken = _marketInfo.shortToken;
        callbackGasLimit = _initParams.gmxV2GmInitParams.callbackGasLimit;

        _strategyV2InitUnchained(
            _initParams.adminStructure,
            _initParams.strategyHelper,
            _initParams.feeManager,
            _initParams.weth,
            _initParams.want,
            _initParams.calculations,
            _initParams.tokensToCompound,
            _initParams.minimumsToCompound
        );
    }

    /// @inheritdoc IGMXV2GMStrategy
    function setExchangeRouter(address _newExchangeRouter) external {
        _onlySuperAdmin();
        _setExchangeRouter(_newExchangeRouter);
    }

    /// @inheritdoc IGMXV2GMStrategy
    function setReader(address _newReader) external {
        _onlySuperAdmin();
        _setReader(_newReader);
    }

    /// @inheritdoc IGMXV2GMStrategy
    function setDataStore(address _newDataStore) external {
        _onlySuperAdmin();
        _setDataStore(_newDataStore);
    }

    /// @inheritdoc IGMXV2GMStrategy
    function setDepositHandler(address _newDepositHandler) external {
        _onlySuperAdmin();
        _setDepositHandler(_newDepositHandler);
    }

    /// @inheritdoc IGMXV2GMStrategy
    function setWithdrawalHandler(address _newWithdrawalHandler) external {
        _onlySuperAdmin();
        _setWithdrawalHandler(_newWithdrawalHandler);
    }

    /// @inheritdoc IGMXV2GMStrategy
    function setCallbackGasLimit(uint256 _newCallbackGasLimit) external {
        _onlySuperAdmin();

        callbackGasLimit = _newCallbackGasLimit;
    }

    /// @inheritdoc IGMXV2GMStrategy
    function afterDepositExecution(
        bytes32 _depositKey,
        IDeposit.Props memory,
        IEventUtils.EventLogData memory
    )
        external
    {
        _onlyDepositHandler();
        _completeDeposit(_depositKey);
    }

    /// @inheritdoc IGMXV2GMStrategy
    function afterDepositCancellation(
        bytes32 _depositKey,
        IDeposit.Props memory _depositParams,
        IEventUtils.EventLogData memory
    )
        external
    {
        _onlyDepositHandler();

        IStrategyHelper _strategyHelper = strategyHelper;

        ERC20Lib.safeApprove(
            _depositParams.addresses.initialLongToken,
            address(_strategyHelper),
            _depositParams.numbers.initialLongTokenAmount
        );

        uint256 _shortTokenAmount = _strategyHelper.swap(
            _depositParams.addresses.initialLongToken,
            _depositParams.addresses.initialShortToken,
            _depositParams.numbers.initialLongTokenAmount,
            slippageTolerance,
            address(this)
        ) + _depositParams.numbers.initialShortTokenAmount;

        _cancelDeposit(_depositKey, _depositParams.addresses.initialShortToken, _shortTokenAmount);
    }

    /// @inheritdoc IGMXV2GMStrategy
    function afterWithdrawalExecution(
        bytes32 _withdrawalKey,
        IWithdrawal.Props memory,
        IEventUtils.EventLogData memory
    )
        external
    {
        _onlyWithdrawalHandler();

        address _longToken = longToken;
        address _shortToken = shortToken;
        IStrategyHelper _strategyHelper = strategyHelper;
        uint256 _longTokenBalance = _getTokenBalance(_longToken);

        ERC20Lib.safeApprove(_longToken, address(_strategyHelper), _longTokenBalance);

        _strategyHelper.swap(_longToken, _shortToken, _longTokenBalance, slippageTolerance, address(this));

        _completeWithdrawal(_withdrawalKey, _shortToken, _getTokenBalance(_shortToken));
    }

    /// @inheritdoc IGMXV2GMStrategy
    function afterWithdrawalCancellation(
        bytes32 _withdrawalKey,
        IWithdrawal.Props memory,
        IEventUtils.EventLogData memory
    )
        external
    {
        _onlyWithdrawalHandler();
        _cancelWithdrawal(_withdrawalKey);
    }

    /// @inheritdoc IStrategyV2
    function balance() public view override returns (uint256) {
        return _getTokenBalance(want);
    }

    /// @inheritdoc IGMXV2GMStrategy
    function priceToken(address _token) public view returns (IPrice.Props memory) {
        uint256 _price = strategyHelper.price(_token);

        _price = _price * (10 ** (30 - ERC20Upgradeable(_token).decimals())) / 1e18;

        return IPrice.Props({ min: _price, max: _price });
    }

    /**
     * @notice Initializes a deposit operation into GMX V2 GM pool. Swaps the user's token into a short (stable) token
     *         (if needed). Then swaps half of the short (stable) token into the long (volatile) token and creates a
     *         deposit operation using 2 tokens as input.
     * @param _token A token address that is used for the deposit operation.
     * @param _amount An amount of the token to use for deposit.
     * @param _additionalData Encoded data which will be used at the time of deposit.
     * @return A unique deposit key to match callbacks with created deposit operation later.
     */
    function _createDeposit(
        address _token,
        uint256 _amount,
        bytes calldata _additionalData
    )
        internal
        override
        returns (bytes memory)
    {
        address _longToken = longToken;
        address _shortToken = shortToken;
        IStrategyHelper _strategyHelper = strategyHelper;
        (uint16 _slippageTolerance) = abi.decode(_additionalData, (uint16));
        address _market = want;
        uint256 _minMarketTokens;
        (uint256 _longTokenAmount, uint256 _shortTokenAmount) =
            _getLongAndShortTokens(_token, _amount, _longToken, _shortToken, _strategyHelper, _slippageTolerance);

        {
            IReader _reader = reader;
            address _dataStore = dataStore;
            IMarket.Props memory _marketInfo = _reader.getMarket(_dataStore, _market);

            _minMarketTokens = _reader.getDepositAmountOut(
                _dataStore,
                _marketInfo,
                IMarket.Prices({
                    indexTokenPrice: priceToken(_marketInfo.indexToken),
                    longTokenPrice: priceToken(_marketInfo.longToken),
                    shortTokenPrice: priceToken(_marketInfo.shortToken)
                }),
                _longTokenAmount,
                _shortTokenAmount,
                address(0)
            );
        }

        IExchangeRouter _exchangeRouter = exchangeRouter;
        address _router = _exchangeRouter.router();
        bytes[] memory _data = new bytes[](4);
        address _depositVault = depositVault;
        IExchangeRouter.CreateDepositParams memory _createDepositParams = IExchangeRouter.CreateDepositParams({
            receiver: address(this),
            callbackContract: address(this),
            uiFeeReceiver: address(0),
            market: _market,
            initialLongToken: _longToken,
            initialShortToken: _shortToken,
            longTokenSwapPath: new address[](0),
            shortTokenSwapPath: new address[](0),
            minMarketTokens: _getMinimumOutputAmount(_minMarketTokens, _slippageTolerance),
            shouldUnwrapNativeToken: false,
            executionFee: msg.value,
            callbackGasLimit: callbackGasLimit
        });

        ERC20Lib.safeApprove(_longToken, _router, _longTokenAmount);
        ERC20Lib.safeApprove(_shortToken, _router, _shortTokenAmount);

        _data[0] =
            abi.encodeWithSelector(IExchangeRouter.sendWnt.selector, _depositVault, _createDepositParams.executionFee);
        _data[1] =
            abi.encodeWithSelector(IExchangeRouter.sendTokens.selector, _longToken, _depositVault, _longTokenAmount);
        _data[2] =
            abi.encodeWithSelector(IExchangeRouter.sendTokens.selector, _shortToken, _depositVault, _shortTokenAmount);
        _data[3] = abi.encodeWithSelector(IExchangeRouter.createDeposit.selector, _createDepositParams);

        bytes[] memory _results = _exchangeRouter.multicall{ value: _createDepositParams.executionFee }(_data);

        return _results[3];
    }

    /**
     * @notice Initializes a withdrawal operation from GMX V2 GM pool.
     * @param _wantToWithdraw An amount of the want tokens to use for withdrawal.
     * @param _additionalData Encoded data which will be used at the time of withdrawal.
     * @return A unique withdrawal key to match callbacks with created withdrawal operation later.
     */
    function _createWithdrawal(
        address,
        uint256 _wantToWithdraw,
        bytes calldata _additionalData
    )
        internal
        override
        returns (bytes memory)
    {
        address _market = want;
        uint256 _longTokenOut;
        uint256 _shortTokenOut;

        {
            IReader _reader = reader;
            address _dataStore = dataStore;
            IMarket.Props memory _marketInfo = _reader.getMarket(_dataStore, _market);

            (_longTokenOut, _shortTokenOut) = _reader.getWithdrawalAmountOut(
                _dataStore,
                _marketInfo,
                IMarket.Prices({
                    indexTokenPrice: priceToken(_marketInfo.indexToken),
                    longTokenPrice: priceToken(_marketInfo.longToken),
                    shortTokenPrice: priceToken(_marketInfo.shortToken)
                }),
                _wantToWithdraw,
                address(0)
            );
        }

        (uint16 _slippageTolerance) = abi.decode(_additionalData, (uint16));
        IExchangeRouter.CreateWithdrawalParams memory _createWithdrawalParams = IExchangeRouter.CreateWithdrawalParams({
            receiver: address(this),
            callbackContract: address(this),
            uiFeeReceiver: address(0),
            market: _market,
            longTokenSwapPath: new address[](0),
            shortTokenSwapPath: new address[](0),
            minLongTokenAmount: _getMinimumOutputAmount(_longTokenOut, _slippageTolerance),
            minShortTokenAmount: _getMinimumOutputAmount(_shortTokenOut, _slippageTolerance),
            shouldUnwrapNativeToken: false,
            executionFee: msg.value,
            callbackGasLimit: callbackGasLimit
        });
        IExchangeRouter _exchangeRouter = exchangeRouter;
        bytes[] memory _data = new bytes[](3);
        address _withdrawalVault = withdrawalVault;

        ERC20Lib.safeApprove(_market, _exchangeRouter.router(), _wantToWithdraw);

        _data[0] = abi.encodeWithSelector(
            IExchangeRouter.sendWnt.selector, _withdrawalVault, _createWithdrawalParams.executionFee
        );
        _data[1] =
            abi.encodeWithSelector(IExchangeRouter.sendTokens.selector, _market, _withdrawalVault, _wantToWithdraw);
        _data[2] = abi.encodeWithSelector(IExchangeRouter.createWithdrawal.selector, _createWithdrawalParams);

        bytes[] memory _results = _exchangeRouter.multicall{ value: _createWithdrawalParams.executionFee }(_data);

        return _results[2];
    }

    /**
     * @notice Compounds rewards from GMX V2 GM. Optional param: encoded data containing information about the compound
     *         operation.
     * @dev Compound operation isn't needed for this strategy.
     */
    function _compound(bytes memory) internal virtual override { }

    /**
     * @notice Sets a new GMX's ExchangeRouter contract address.
     * @param _newExchangeRouter A new GMX's ExchangeRouter contract address.
     */
    function _setExchangeRouter(address _newExchangeRouter) private {
        AddressUtils.onlyContract(_newExchangeRouter);

        exchangeRouter = IExchangeRouter(_newExchangeRouter);
    }

    /**
     * @notice Sets a new GMX's Reader contract address.
     * @param _newReader A new GMX's Reader contract address.
     */
    function _setReader(address _newReader) private {
        AddressUtils.onlyContract(_newReader);

        reader = IReader(_newReader);
    }

    /**
     * @notice Sets a new GMX's DataStore contract address.
     * @param _newDataStore A new GMX's DataStore contract address.
     */
    function _setDataStore(address _newDataStore) private {
        AddressUtils.onlyContract(_newDataStore);

        dataStore = _newDataStore;
    }

    /**
     * @notice Sets a new GMX's DepositHandler contract address.
     * @dev Automatically sets a new appropriative GMX's DepositVault contract address.
     * @param _newDepositHandler A new GMX's DepositHandler contract address.
     */
    function _setDepositHandler(address _newDepositHandler) private {
        AddressUtils.onlyContract(_newDepositHandler);

        depositHandler = _newDepositHandler;
        depositVault = IHandler(_newDepositHandler).depositVault();
    }

    /**
     * @notice Sets a new GMX's WithdrawalHandler contract address.
     * @dev Automatically sets a new appropriative GMX's WithdrawalVault contract address.
     * @param _newWithdrawalHandler A new GMX's WithdrawalHandler contract address.
     */
    function _setWithdrawalHandler(address _newWithdrawalHandler) private {
        AddressUtils.onlyContract(_newWithdrawalHandler);

        withdrawalHandler = _newWithdrawalHandler;
        withdrawalVault = IHandler(_newWithdrawalHandler).withdrawalVault();
    }

    /**
     * @notice Transforms deposit token to long (volatile) and short (stable) tokens in equal parts for the future
     *         deposit operation.
     * @param _token A token address that is used for the deposit operation.
     * @param _amount An amount of the token to use for deposit.
     * @param _longToken Long (volatile) token address.
     * @param _shortToken Short (stable) token address.
     * @param _strategyHelper StrategyHelper contract to execute swap operations there.
     * @param _slippageTolerance A slippage tolerance percentage to apply at the time of swaps.
     * @return _longTokenAmount An amount of long (volatile) tokens to deposit after all swaps.
     * @return _shortTokenAmount An amount of short (stable) tokens to deposit after all swaps.
     */
    function _getLongAndShortTokens(
        address _token,
        uint256 _amount,
        address _longToken,
        address _shortToken,
        IStrategyHelper _strategyHelper,
        uint16 _slippageTolerance
    )
        private
        returns (uint256 _longTokenAmount, uint256 _shortTokenAmount)
    {
        if (_token != _longToken && _token != _shortToken) {
            ERC20Lib.safeApprove(_token, address(_strategyHelper), _amount);

            _amount = _strategyHelper.swap(_token, _shortToken, _amount, _slippageTolerance, address(this));
            _token = _shortToken;
        }

        uint256 _half = _amount >> 1;

        if (_token == _longToken) {
            ERC20Lib.safeApprove(_longToken, address(_strategyHelper), _half);

            _longTokenAmount = _amount - _half;
            _shortTokenAmount = _strategyHelper.swap(_longToken, _shortToken, _half, _slippageTolerance, address(this));
        } else {
            ERC20Lib.safeApprove(_shortToken, address(_strategyHelper), _half);

            _longTokenAmount = _strategyHelper.swap(_shortToken, _longToken, _half, _slippageTolerance, address(this));
            _shortTokenAmount = _amount - _half;
        }
    }

    /**
     * @notice Checks if a transaction sender is GMX's DepositHandler contract.
     */
    function _onlyDepositHandler() private view {
        if (msg.sender != depositHandler) revert GMXV2GMStrategyErrors.NotDepositHandler();
    }

    /**
     * @notice Checks if a transaction sender is GMX's WithdrawalHandler contract.
     */
    function _onlyWithdrawalHandler() private view {
        if (msg.sender != withdrawalHandler) revert GMXV2GMStrategyErrors.NotWithdrawalHandler();
    }

    /**
     * @notice Calculates the minimum output amount applying a slippage tolerance percentage to the amount.
     * @param _amount The amount of tokens to use.
     * @param _minusPercentage The percentage to reduce from the amount.
     * @return The minimum output amount.
     */
    function _getMinimumOutputAmount(uint256 _amount, uint256 _minusPercentage) private pure returns (uint256) {
        return _amount - ((_amount * _minusPercentage) / ONE_HUNDRED_PERCENTS);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import {Initializable} from "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

/**
 * @title Dollet GMXV2GMStrategyErrors library
 * @author Dollet Team
 * @notice Library with all GMXV2GMStrategy errors.
 */
library GMXV2GMStrategyErrors {
    error NotWithdrawalHandler();
    error NotDepositHandler();
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import { IAdminStructure } from "./IAdminStructure.sol";

/**
 * @title Dollet IStrategyHelper
 * @author Dollet Team
 * @notice Interface for StrategyHelper contract.
 */
interface IStrategyHelper {
    /**
     * Structure for storing of swap path and the swap venue.
     */
    struct Path {
        address venue;
        bytes path;
    }

    /**
     * @notice Logs information when a new oracle was set.
     * @param _asset An asset address for which oracle was set.
     * @param _oracle A new oracle address.
     */
    event OracleSet(address indexed _asset, address indexed _oracle);

    /**
     * @notice Logs information when a new swap path was set.
     * @param _from From asset.
     * @param _to To asset.
     * @param _venue A venue which swap path was used.
     * @param _path A swap path itself.
     */
    event PathSet(address indexed _from, address indexed _to, address indexed _venue, bytes _path);

    /**
     * @notice Allows the super admin to change the admin structure contract.
     * @param _adminStructure Admin structure contract address.
     */
    function setAdminStructure(address _adminStructure) external;

    /**
     * @notice Sets a new oracle for the specified asset.
     * @param _asset An asset address for which to set an oracle.
     * @param _oracle A new oracle address.
     */
    function setOracle(address _asset, address _oracle) external;

    /**
     * @notice Sets a new swap path for two assets.
     * @param _from From asset.
     * @param _to To asset.
     * @param _venue A venue which swap path is used.
     * @param _path A swap path itself.
     */
    function setPath(address _from, address _to, address _venue, bytes calldata _path) external;

    /**
     * @notice Executes a swap of two assets.
     * @param _from From asset.
     * @param _to To asset.
     * @param _amount Amount of the first asset to swap.
     * @param _slippageTolerance Slippage tolerance percentage (with 2 decimals).
     * @param _recipient Recipient of the second asset.
     * @return _amountOut The second asset output amount.
     */
    function swap(
        address _from,
        address _to,
        uint256 _amount,
        uint16 _slippageTolerance,
        address _recipient
    )
        external
        returns (uint256 _amountOut);

    /**
     * @notice Returns an oracle address for the specified asset.
     * @param _asset An address of the asset for which to get the oracle address.
     * @return _oracle An oracle address for the specified asset.
     */
    function oracles(address _asset) external view returns (address _oracle);

    /**
     * @notice Returns the address of the venue where the swap should be executed and the swap path.
     * @param _from From asset.
     * @param _to To asset.
     * @return _venue The address of the venue where the swap should be executed.
     * @return _path The swap path.
     */
    function paths(address _from, address _to) external view returns (address _venue, bytes memory _path);

    /**
     * @notice Returns AdminStructure contract address.
     * @return _adminStructure AdminStructure contract address.
     */
    function adminStructure() external returns (IAdminStructure _adminStructure);

    /**
     * @notice Returns the price of the specified asset.
     * @param _asset The asset to get the price for.
     * @return _price The price of the specified asset.
     */
    function price(address _asset) external view returns (uint256 _price);

    /**
     * @notice Returns the value of the specified amount of the asset.
     * @param _asset The asset to value.
     * @param _amount The amount of asset to value.
     * @return _value The value of the specified amount of the asset.
     */
    function value(address _asset, uint256 _amount) external view returns (uint256 _value);

    /**
     * @notice Converts the first asset to the second asset.
     * @param _from From asset.
     * @param _to To asset.
     * @param _amount Amount of the first asset to convert.
     * @return _amountOut Amount of the second asset after the conversion.
     */
    function convert(address _from, address _to, uint256 _amount) external view returns (uint256 _amountOut);

    /**
     * @notice Returns 100.00% constant value (with to decimals).
     * @return 100.00% constant value (with to decimals).
     */
    function ONE_HUNDRED_PERCENTS() external pure returns (uint16);
}

/**
 * @title Dollet IStrategyHelperVenue
 * @author Dollet Team
 * @notice Interface for StrategyHelperVenue contracts.
 */
interface IStrategyHelperVenue {
    /**
     * @notice Executes a swap of two assets.
     * @param _asset First asset.
     * @param _path Path of the swap.
     * @param _amount Amount of the first asset to swap.
     * @param _minAmountOut Minimum output amount of the second asset.
     * @param _recipient Recipient of the second asset.
     * @param _deadline Deadline of the swap.
     */
    function swap(
        address _asset,
        bytes calldata _path,
        uint256 _amount,
        uint256 _minAmountOut,
        address _recipient,
        uint256 _deadline
    )
        external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import { IAdminStructure } from "src/interfaces/dollet/IAdminStructure.sol";
import { IStrategyHelper } from "src/interfaces/dollet/IStrategyHelper.sol";
import { IFeeManager } from "src/interfaces/dollet/IFeeManager.sol";
import { IVaultV2 } from "src/interfaces/dollet/IVaultV2.sol";
import { IWETH } from "src/interfaces/IWETH.sol";

/**
 * @title Dollet IStrategyV2
 * @author Dollet Team
 * @notice Interface with all types, events, external, and public methods for the StrategyV2 contract.
 */
interface IStrategyV2 {
    /**
     * @notice A structure to store intermediate information between deposit creation and callbacks processing.
     * @param user A user address to whom the deposit belongs.
     * @param originalToken Address of the token deposited (useful when using ETH).
     * @param token A token address that was used during deposit creation.
     * @param amount An amount of tokens that were used during deposit creation.
     * @param additionalData Additional encoded data that can be used in callbacks.
     */
    struct DepositInfo {
        address user;
        address originalToken;
        address token;
        uint256 amount;
        bytes additionalData;
    }

    /**
     * @notice A structure to store intermediate information between withdrawal creation and callbacks processing.
     * @param recipient Address of the recipient to receive the tokens.
     * @param user Address of the owner of the deposit (shares).
     * @param originalToken Address of the token deposited (useful when using ETH).
     * @param token Address of the token to withdraw in.
     * @param wantToWithdraw Amount of want tokens to withdraw from the strategy.
     * @param maxUserWant Maximum user want tokens available to withdraw.
     * @param amountShares A number of shares that were used for withdrawal. Needed to substruct them during the
     *                     withdrawal callback execution inside of the VaultV2 contract.
     * @param additionalData Additional encoded data that can be used in callbacks.
     */
    struct WithdrawalInfo {
        address recipient;
        address user;
        address originalToken;
        address token;
        uint256 wantToWithdraw;
        uint256 maxUserWant;
        uint256 amountShares;
        bytes additionalData;
    }

    /**
     * @notice A structure with token's minimum to compound information.
     * @param token Token address to compound.
     * @param minAmount A minimum amount of tokens to compound.
     */
    struct MinimumToCompound {
        address token;
        uint256 minAmount;
    }

    /**
     * @notice Logs information about deposit creation operation.
     * @param _depositKey Unique deposit key.
     * @param _user A user address who executed a deposit creation operation.
     * @param _token A token address that was used at the time of deposit creation.
     * @param _amount An amount of tokens that were deposited.
     */
    event DepositCreated(bytes indexed _depositKey, address indexed _user, address indexed _token, uint256 _amount);

    /**
     * @notice Logs information about deposit completion operation.
     * @param _depositKey Unique deposit key.
     * @param _user A user address who executed a deposit operation.
     * @param _token A token address that was used at the time of deposit.
     * @param _amount An amount of tokens that were deposited.
     * @param _depositedWant An amount of want tokens that were received from the underlying protocol.
     */
    event DepositCompleted(
        bytes indexed _depositKey,
        address indexed _user,
        address indexed _token,
        uint256 _amount,
        uint256 _depositedWant
    );

    /**
     * @notice Logs information about deposit cancellation operation.
     * @param _depositKey Unique deposit key.
     * @param _user A user address who executed a deposit operation.
     * @param _token A token address that was used at the time of deposit.
     * @param _amount An amount of tokens that were deposited.
     */
    event DepositCancelled(bytes indexed _depositKey, address indexed _user, address indexed _token, uint256 _amount);

    /**
     * @notice Logs information about withdrawal creation operation.
     * @param _withdrawalKey Unique withdrawal key.
     * @param _user A user address who executed a withdrawal creation operation.
     * @param _token A token address that will be used as output token at the time of withdrawal operation.
     * @param _wantToWithdraw An amount of want tokens that will be withdrawn from the underlying protocol.
     */
    event WithdrawalCreated(
        bytes indexed _withdrawalKey, address indexed _user, address indexed _token, uint256 _wantToWithdraw
    );

    /**
     * @notice Logs information about withdrawal completion operation.
     * @param _withdrawalKey Unique withdrawal key.
     * @param _user A user address who executed a withdrawal operation.
     * @param _token A token address that was used as output token at the time of withdrawal.
     * @param _amount An amount of tokens that were withdrawn.
     */
    event WithdrawalCompleted(
        bytes indexed _withdrawalKey, address indexed _user, address indexed _token, uint256 _amount
    );

    /**
     * @notice Logs information about withdrawal cancellation operation.
     * @param _withdrawalKey Unique withdrawal key.
     * @param _user A user address who executed a withdrawal operation.
     * @param _token A token address that was used as output token at the time of withdrawal.
     * @param _wantToWithdraw An amount of want tokens that were tried to withdraw from the underlying protocol.
     */
    event WithdrawalCanceled(
        bytes indexed _withdrawalKey, address indexed _user, address indexed _token, uint256 _wantToWithdraw
    );

    /**
     * @notice Logs information about compound operation.
     * @param _amount An amount of want tokens that were compounded and deposited in the underlying protocol.
     */
    event Compounded(uint256 _amount);

    /**
     * @notice Logs information when a new VaultV2 contract address was set.
     * @param _vault A new VaultV2 contract address.
     */
    event VaultSet(address indexed _vault);

    /**
     * @notice Logs information about the withdrawal of stuck tokens.
     * @param _caller An address of the admin who executed the withdrawal operation.
     * @param _token An address of a token that was withdrawn.
     * @param _amount An amount of tokens that were withdrawn.
     */
    event WithdrawStuckTokens(address _caller, address _token, uint256 _amount);

    /**
     * @notice Logs information about new slippage tolerance.
     * @param _slippageTolerance A new slippage tolerance that was set.
     */
    event SlippageToleranceSet(uint16 _slippageTolerance);

    /**
     * @notice Logs information when a fee is charged.
     * @param _feeType A type of fee charged.
     * @param _feeAmount An amount of fee charged.
     * @param _feeRecipient A recipient of the charged fee.
     * @param _token The addres of the token used.
     */
    event ChargedFees(IFeeManager.FeeType _feeType, uint256 _feeAmount, address _feeRecipient, address _token);

    /**
     * @notice Logs information when the minimum amount to compound is changed.
     * @param _token The address of the token.
     * @param _minimum The new minimum amount to compound.
     */
    event MinimumToCompoundChanged(address _token, uint256 _minimum);

    /**
     * @notice Creates a deposit to the strategy.
     * @param _user Address of the user providing the deposit tokens.
     * @param _originalToken Address of the token deposited (useful when using ETH).
     * @param _token Address of the token to deposit.
     * @param _amount Amount of tokens to deposit.
     * @param _additionalData Additional encoded data for the deposit.
     */
    function deposit(
        address _user,
        address _originalToken,
        address _token,
        uint256 _amount,
        bytes calldata _additionalData
    )
        external
        payable;

    /**
     * @notice Withdraw from the strategy.
     * @param _recipient Address of the recipient to receive the tokens.
     * @param _user Address of the owner of the deposit (shares).
     * @param _originalToken Address of the token deposited (useful when using ETH).
     * @param _token Address of the token to withdraw.
     * @param _wantToWithdraw Amount of want tokens to withdraw from the strategy.
     * @param _maxUserWant Maximum user want tokens available to withdraw.
     * @param _amountShares A number of shares that were used for withdrawal. Needed to substruct them during the
     *                      withdrawal callback execution inside of the VaultV2 contract.
     * @param _additionalData Additional encoded data for the withdrawal.
     */
    function withdraw(
        address _recipient,
        address _user,
        address _originalToken,
        address _token,
        uint256 _wantToWithdraw,
        uint256 _maxUserWant,
        uint256 _amountShares,
        bytes calldata _additionalData
    )
        external
        payable;

    /**
     * @notice Executes a compound on the strategy.
     * @param _data Encoded data which will be used in the time of compound.
     */
    function compound(bytes calldata _data) external;

    /**
     * @notice Allows the super admin to change the admin structure.
     * @param _adminStructure Admin structure contract address.
     */
    function setAdminStructure(address _adminStructure) external;

    /**
     * @notice Sets a VaultV2 contract address. Only super admin is able to set a new VaultV2 address.
     * @param _vault A new VaultV2 contract address.
     */
    function setVault(address _vault) external;

    /**
     * @notice Sets a new slippage tolerance by super admin.
     * @param _slippageTolerance A new slippage tolerance (with 2 decimals).
     */
    function setSlippageTolerance(uint16 _slippageTolerance) external;

    /**
     * @notice Handles the case where tokens get stuck in the contract. Allows the admin to send the tokens to the super
     *         admin.
     * @param _token The address of the stuck token.
     */
    function inCaseTokensGetStuck(address _token) external;

    /**
     * @notice Edits the minimum token compound amounts.
     * @param _tokens An array of token addresses to edit.
     * @param _minAmounts An array of minimum harvest amounts corresponding to the tokens.
     */
    function editMinimumTokenCompound(address[] calldata _tokens, uint256[] calldata _minAmounts) external;

    /**
     * @notice Returns the balance of the strategy held in the strategy or underlying protocols.
     * @return The balance of the strategy.
     */
    function balance() external view returns (uint256);

    /**
     * @notice Returns information about the deposit by its unique key.
     * @dev Information about deposit is stored only between deposit creation and callbacks execution. Before deposit
     *      creation and after callbacks execution information is unavailable, it is removed from the storage.
     * @param _depositKey A unique deposit key.
     * @return _user A user address to whom the deposit belongs.
     * @return _originalToken A token address that was used during deposit creation (useful when using ETH).
     * @return _token A token address that was used during deposit creation.
     * @return _amount An amount of tokens that were used during deposit creation.
     * @return _additionalData Additional encoded data that can be used in callbacks.
     */
    function depositsInfo(bytes memory _depositKey)
        external
        view
        returns (address _user, address _originalToken, address _token, uint256 _amount, bytes memory _additionalData);

    /**
     * @notice Returns information about the withdrawal by its unique key.
     * @dev Information about withdrawal is stored only between withdrawal creation and callbacks execution. Before
     *      withdrawal creation and after callbacks execution information is unavailable, it is removed from the
     *      storage.
     * @param _withdrawalKey A unique withdrawal key.
     * @return _recipient Address of the recipient to receive the tokens.
     * @return _user Address of the owner of the deposit (shares).
     * @return _originalToken Address of the token deposited (useful when using ETH).
     * @return _token Address of the token to withdraw in.
     * @return _wantToWithdraw Amount of want tokens to withdraw from the strategy.
     * @return _maxUserWant Maximum user want tokens available to withdraw.
     * @return _amountShares A number of shares that were used for withdrawal. Needed to substruct them during the
     *                       withdrawal callback execution inside of the VaultV2 contract.
     * @return _additionalData Additional encoded data that can be used in callbacks.
     */
    function withdrawalsInfo(bytes memory _withdrawalKey)
        external
        view
        returns (
            address _recipient,
            address _user,
            address _originalToken,
            address _token,
            uint256 _wantToWithdraw,
            uint256 _maxUserWant,
            uint256 _amountShares,
            bytes memory _additionalData
        );

    /**
     * @notice Returns the total deposited want token amount by a user.
     * @param _user A user address to get the total deposited want token amount for.
     * @return The total deposited want token amount by a user.
     */
    function userWantDeposit(address _user) external view returns (uint256);

    /**
     * @notice Returns the minimum amount required to execute reinvestment for a specific token.
     * @param _token The address of the token.
     * @return The minimum amount required for reinvestment.
     */
    function minimumToCompound(address _token) external view returns (uint256);

    /**
     * @notice Returns AdminStructure contract address.
     * @return AdminStructure contract address.
     */
    function adminStructure() external view returns (IAdminStructure);

    /**
     * @notice Returns StrategyHelper contract address.
     * @return StrategyHelper contract address.
     */
    function strategyHelper() external view returns (IStrategyHelper);

    /**
     * @notice Returns FeeManager contract address.
     * @return FeeManager contract address.
     */
    function feeManager() external view returns (IFeeManager);

    /**
     * @notice Returns VaultV2 contract address.
     * @return VaultV2 contract address.
     */
    function vault() external view returns (IVaultV2);

    /**
     * @notice Returns WETH token contract address.
     * @return WETH token contract address.
     */
    function weth() external view returns (IWETH);

    /**
     * @notice Returns total deposited want token amount.
     * @return Total deposited want token amount.
     */
    function totalWantDeposits() external view returns (uint256);

    /**
     * @notice Returns previous want token balance.
     * @dev The previous want token balance is used at the time of `_completeDeposit()` execution to calculate how many
     *      new want tokens were minted.
     * @return Previous want token balance.
     */
    function prevWantBalance() external view returns (uint256);

    /**
     * @notice Returns the token address that should be deposited in the underlying protocol.
     * @return The token address that should be deposited in the underlying protocol.
     */
    function want() external view returns (address);

    /**
     * @notice Returns a default slippage tolerance percentage (with 2 decimals).
     * @return A default slippage tolerance percentage (with 2 decimals).
     */
    function slippageTolerance() external view returns (uint16);

    /**
     * @notice Returns maximum slipage tolerance value (with two decimals).
     * @return Maximum slipage tolerance value (with two decimals).
     */
    function MAX_SLIPPAGE_TOLERANCE() external view returns (uint16);

    /**
     * @notice Returns 100% value (with two decimals).
     * @return 100% value (with two decimals).
     */
    function ONE_HUNDRED_PERCENTS() external view returns (uint16);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import { IExchangeRouter, IPrice, IReader, IDeposit, IWithdrawal, IEventUtils } from "./IGMXV2GM.sol";

/**
 * @title Dollet GMXV2GMStrategy interface
 * @author Dollet Team
 * @notice An interface of the GMXV2GMStrategy contract.
 */
interface IGMXV2GMStrategy {
    /**
     * @notice GMX V2 GM strategy initialization parameters structure.
     * @param exchangeRouter GMX's ExchangeRouter contract address.
     * @param reader GMX's Reader contract address.
     * @param dataStore GMX's DataStore contract address.
     * @param depositHandler GMX's DepositHandler contract address.
     * @param withdrawalHandler GMX's WithdrawalHandler contract address.
     * @param callbackGasLimit The gas limit to be passed to the callback (strategy) contract on deposit/withdrawal
     *                         execution/cancellation.
     */
    struct GMXV2GMInitParams {
        address exchangeRouter;
        address reader;
        address dataStore;
        address depositHandler;
        address withdrawalHandler;
        uint256 callbackGasLimit;
    }

    /**
     * @notice Strategy initialization parameters structure.
     * @param adminStructure AdminStructure contract address.
     * @param strategyHelper StrategyHelper contract address.
     * @param feeManager FeeManager contract address.
     * @param weth WETH token contract address.
     * @param want Want token contract address.
     * @param calculations Calculations contract address.
     * @param tokensToCompound An array of the tokens to set the minimum to compound.
     * @param minimumsToCompound An array of the minimum amounts to compound.
     * @param gmxV2GmInitParams GMX V2 GM initialization parameters.
     */
    struct InitParams {
        address adminStructure;
        address strategyHelper;
        address feeManager;
        address weth;
        address want;
        address calculations;
        address[] tokensToCompound;
        uint256[] minimumsToCompound;
        GMXV2GMInitParams gmxV2GmInitParams;
    }

    /**
     * @notice Sets a new GMX's ExchangeRouter contract address by a super admin.
     * @param _newExchangeRouter A new GMX's ExchangeRouter contract address.
     */
    function setExchangeRouter(address _newExchangeRouter) external;

    /**
     * @notice Sets a new GMX's Reader contract address by a super admin.
     * @param _newReader A new GMX's Reader contract address.
     */
    function setReader(address _newReader) external;

    /**
     * @notice Sets a new GMX's DataStore contract address by a super admin.
     * @param _newDataStore A new GMX's DataStore contract address.
     */
    function setDataStore(address _newDataStore) external;

    /**
     * @notice Sets a new GMX's DepositHandler contract address by a super admin.
     * @dev Automatically sets a new appropriative GMX's DepositVault contract address.
     * @param _newDepositHandler A new GMX's DepositHandler contract address.
     */
    function setDepositHandler(address _newDepositHandler) external;

    /**
     * @notice Sets a new GMX's WithdrawalHandler contract address by a super admin.
     * @dev Automatically sets a new appropriative GMX's WithdrawalVault contract address.
     * @param _newWithdrawalHandler A new GMX's WithdrawalHandler contract address.
     */
    function setWithdrawalHandler(address _newWithdrawalHandler) external;

    /**
     * @notice Sets a new callback gas limit by a super admin.
     * @param _newCallbackGasLimit A new callback gas limit.
     */
    function setCallbackGasLimit(uint256 _newCallbackGasLimit) external;

    /**
     * @notice Callback that takes place if deposit operation is successful.
     * @param _depositKey The key of the deposit.
     * @param _depositParams The information about the deposit that was executed.
     * @param _eventParams Additional information about the event that was executed.
     */
    function afterDepositExecution(
        bytes32 _depositKey,
        IDeposit.Props memory _depositParams,
        IEventUtils.EventLogData memory _eventParams
    )
        external;

    /**
     * @notice Callback that takes place if deposit operation is unsuccessful.
     * @param _depositKey The key of the deposit.
     * @param _depositParams The information about the deposit that wasn't executed.
     * @param _eventParams Additional information about the event that wasn't executed.
     */
    function afterDepositCancellation(
        bytes32 _depositKey,
        IDeposit.Props memory _depositParams,
        IEventUtils.EventLogData memory _eventParams
    )
        external;

    /**
     * @notice Callback that takes place if withdrawal operation is successful.
     * @param _withdrawalKey The key of the withdrawal.
     * @param _withdrawalParams The information about the withdrawal that was executed.
     * @param _eventParams Additional information about the event that was executed.
     */
    function afterWithdrawalExecution(
        bytes32 _withdrawalKey,
        IWithdrawal.Props memory _withdrawalParams,
        IEventUtils.EventLogData memory _eventParams
    )
        external;

    /**
     * @notice Callback that takes place if withdrawal operation is unsuccessful.
     * @param _withdrawalKey The key of the withdrawal.
     * @param _withdrawalParams The information about the withdrawal that wasn't executed.
     * @param _eventParams Additional information about the event that wasn't executed.
     */
    function afterWithdrawalCancellation(
        bytes32 _withdrawalKey,
        IWithdrawal.Props memory _withdrawalParams,
        IEventUtils.EventLogData memory _eventParams
    )
        external;

    /**
     * @notice Returns an address of the GMX's ExchangeRouter contract.
     * @return An address of the GMX's ExchangeRouter contract.
     */
    function exchangeRouter() external view returns (IExchangeRouter);

    /**
     * @notice Returns an address of the GMX's Reader contract.
     * @return An address of the GMX's Reader contract.
     */
    function reader() external view returns (IReader);

    /**
     * @notice Returns an address of the GMX's DataStore contract.
     * @return An address of the GMX's DataStore contract.
     */
    function dataStore() external view returns (address);

    /**
     * @notice Returns an address of the GM pool long (volatile) token contract.
     * @return An address of the GM pool long (volatile) token contract.
     */
    function longToken() external view returns (address);

    /**
     * @notice Returns an address of the GM pool short (stable) token contract.
     * @return An address of the GM pool short (stable) token contract.
     */
    function shortToken() external view returns (address);

    /**
     * @notice Returns an address of the GMX's DepositVault contract.
     * @return An address of the GMX's DepositVault contract.
     */
    function depositVault() external view returns (address);

    /**
     * @notice Returns an address of the GMX's WithdrawalVault contract.
     * @return An address of the GMX's WithdrawalVault contract.
     */
    function withdrawalVault() external view returns (address);

    /**
     * @notice Returns an address of the GMX's DepositHandler contract.
     * @return An address of the GMX's DepositHandler contract.
     */
    function depositHandler() external view returns (address);

    /**
     * @notice Returns an address of the GMX's WithdrawalHandler contract.
     * @return An address of the GMX's WithdrawalHandler contract.
     */
    function withdrawalHandler() external view returns (address);

    /**
     * @notice Returns the gas limit to be passed to the callback (strategy) contract on deposit/withdrawal
     *         execution/cancellation.
     * @return The gas limit to be passed to the callback (strategy) contract on deposit/withdrawal
     *         execution/cancellation.
     */
    function callbackGasLimit() external view returns (uint256);

    /**
     * @notice Calculates the price of the token and converts it into the format acceptable by GMX V2.
     * @param _token A token address for which to calculate the price.
     * @return The price of the token in the format acceptable by GMX V2.
     */
    function priceToken(address _token) external view returns (IPrice.Props memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import { AddressUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

/**
 * @title Dollet AddressUtils library
 * @author Dollet Team
 * @notice A collection of helpers related to the address type.
 */
library AddressUtils {
    using AddressUpgradeable for address;

    error NotContract(address _address);
    error ZeroAddress();

    /**
     * @notice Checks if an address is a contract.
     * @param _address An address to check.
     */
    function onlyContract(address _address) internal view {
        if (!_address.isContract()) revert NotContract(_address);
    }

    /**
     * @notice Checks if an address is not zero address.
     * @param _address An address to check.
     */
    function onlyNonZeroAddress(address _address) internal pure {
        if (_address == address(0)) revert ZeroAddress();
    }

    /**
     * @notice Checks if a token address is a contract or native token.
     * @param _address An address to check.
     */
    function onlyTokenContract(address _address) internal view {
        if (_address == address(0)) return; // ETH
        if (!_address.isContract()) revert NotContract(_address);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { IERC20PermitUpgradeable } from
    "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20PermitUpgradeable.sol";

/**
 * @notice Secp256k1 signature values.
 * @param deadline Timestamp at which the signature expires.
 * @param v `v` portion of the signature.
 * @param r `r` portion of the signature.
 * @param s `s` portion of the signature.
 */
struct Signature {
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
}

/**
 * @title Dollet ERC20Lib
 * @author Dollet Team
 * @notice Helper library that implements some additional methods for interacting with ERC-20 tokens.
 */
library ERC20Lib {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @notice Transfers specified amount of token from `_from` to `_to` using permit.
     * @param _token A token to transfer.
     * @param _from A sender of tokens.
     * @param _to A recipient of tokens.
     * @param _amount A number of tokens to transfer.
     * @param _signature A signature of the permit to use at the time of transfer.
     */
    function pullPermit(
        address _token,
        address _from,
        address _to,
        uint256 _amount,
        Signature memory _signature
    )
        external
    {
        IERC20PermitUpgradeable(_token).permit(
            _from, address(this), _amount, _signature.deadline, _signature.v, _signature.r, _signature.s
        );
        pull(_token, _from, _to, _amount);
    }

    /**
     * @notice Transfers a specified amount of ERC-20 tokens to `_to`.
     * @param _token A token to transfer.
     * @param _to A recipient of tokens.
     * @param _amount A number of tokens to transfer.
     */
    function push(address _token, address _to, uint256 _amount) external {
        IERC20Upgradeable(_token).safeTransfer(_to, _amount);
    }

    /**
     * @notice Transfers the current balance of ERC-20 tokens to `_to`.
     * @param _token A token to transfer.
     * @param _to A recipient of tokens.
     */
    function pushAll(address _token, address _to) external {
        uint256 _amount = IERC20Upgradeable(_token).balanceOf(address(this));

        IERC20Upgradeable(_token).safeTransfer(_to, _amount);
    }

    /**
     * @notice Executes a safe approval operation on a token. If the previous allowance is GT 0, it sets it to 0 and
     *         then executes a new approval.
     * @param _token A token to approve.
     * @param _spender A spender of the token to approve for.
     * @param _amount An amount of tokens to approve.
     */
    function safeApprove(address _token, address _spender, uint256 _amount) external {
        if (IERC20Upgradeable(_token).allowance(address(this), _spender) != 0) {
            IERC20Upgradeable(_token).safeApprove(_spender, 0);
        }

        IERC20Upgradeable(_token).safeApprove(_spender, _amount);
    }

    /**
     * @notice Transfers specified amount of token from `_from` to `_to`.
     * @param _token A token to transfer.
     * @param _from A sender of tokens.
     * @param _to A recipient of tokens.
     * @param _amount A number of tokens to transfer.
     */
    function pull(address _token, address _from, address _to, uint256 _amount) public {
        IERC20Upgradeable(_token).safeTransferFrom(_from, _to, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IAdminStructure } from "src/interfaces/dollet/IAdminStructure.sol";
import { IStrategyHelper } from "src/interfaces/dollet/IStrategyHelper.sol";
import { ICalculations } from "src/interfaces/dollet/ICalculations.sol";
import { IFeeManager } from "src/interfaces/dollet/IFeeManager.sol";
import { IStrategyV2 } from "src/interfaces/dollet/IStrategyV2.sol";
import { StrategyErrors } from "src/libraries/StrategyErrors.sol";
import { AddressUtils } from "src/libraries/AddressUtils.sol";
import { IVaultV2 } from "src/interfaces/dollet/IVaultV2.sol";
import { ERC20Lib } from "src/libraries/ERC20Lib.sol";
import { IWETH } from "src/interfaces/IWETH.sol";

/**
 * @title Dollet StrategyV2 contract
 * @author Dollet Team
 * @notice Abstract StrategyV2 contract. All two-step strategies should inherit from it because it contains the common
 *         logic for all two-step strategies.
 */
abstract contract StrategyV2 is Initializable, ReentrancyGuardUpgradeable, IStrategyV2 {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUtils for address;

    uint16 public constant ONE_HUNDRED_PERCENTS = 10_000; // 100.00%
    uint16 public constant MAX_SLIPPAGE_TOLERANCE = 3000; // 30.00%

    mapping(bytes depositKey => DepositInfo depositInfo) public depositsInfo;
    mapping(bytes withdrawalKey => WithdrawalInfo withdrawalInfo) public withdrawalsInfo;
    mapping(address user => uint256 amount) public userWantDeposit;
    mapping(address token => uint256 minimum) public minimumToCompound;
    IAdminStructure public adminStructure;
    IStrategyHelper public strategyHelper;
    IFeeManager public feeManager;
    IVaultV2 public vault;
    IWETH public weth;
    ICalculations public calculations;
    uint256 public totalWantDeposits;
    uint256 public prevWantBalance;
    address public want;
    uint16 public slippageTolerance;

    // Allows to receive native tokens
    receive() external payable { }

    /// @inheritdoc IStrategyV2
    function deposit(
        address _user,
        address _originalToken,
        address _token,
        uint256 _amount,
        bytes calldata _additionalData
    )
        external
        payable
    {
        _onlyVault();

        bytes memory _key = _createDeposit(_token, _amount, _additionalData);

        prevWantBalance = balance();
        depositsInfo[_key] = DepositInfo({
            user: _user,
            originalToken: _originalToken,
            token: _token,
            amount: _amount,
            additionalData: _additionalData
        });

        emit DepositCreated(_key, _user, _originalToken, _amount);
    }

    /// @inheritdoc IStrategyV2
    function withdraw(
        address _recipient,
        address _user,
        address _originalToken,
        address _token,
        uint256 _wantToWithdraw,
        uint256 _maxUserWant,
        uint256 _amountShares,
        bytes calldata _additionalData
    )
        external
        payable
    {
        _onlyVault();

        bytes memory _key = _createWithdrawal(_token, _wantToWithdraw, _additionalData);

        prevWantBalance = balance();
        withdrawalsInfo[_key] = WithdrawalInfo({
            recipient: _recipient,
            user: _user,
            originalToken: _originalToken,
            token: _token,
            wantToWithdraw: _wantToWithdraw,
            maxUserWant: _maxUserWant,
            amountShares: _amountShares,
            additionalData: _additionalData
        });

        emit WithdrawalCreated(_key, _user, _originalToken, _wantToWithdraw);
    }

    /// @inheritdoc IStrategyV2
    function compound(bytes memory _data) external nonReentrant {
        _compound(_data);
    }

    /// @inheritdoc IStrategyV2
    function setAdminStructure(address _adminStructure) external {
        _onlySuperAdmin();

        AddressUtils.onlyContract(_adminStructure);

        adminStructure = IAdminStructure(_adminStructure);
    }

    /// @inheritdoc IStrategyV2
    function setVault(address _vault) external {
        _onlySuperAdmin();

        AddressUtils.onlyContract(_vault);

        vault = IVaultV2(_vault);

        emit VaultSet(_vault);
    }

    /// @inheritdoc IStrategyV2
    function setSlippageTolerance(uint16 _slippageTolerance) external {
        _onlySuperAdmin();

        if (_slippageTolerance > MAX_SLIPPAGE_TOLERANCE) revert StrategyErrors.SlippageToleranceTooHigh();

        slippageTolerance = _slippageTolerance;

        emit SlippageToleranceSet(_slippageTolerance);
    }

    /// @inheritdoc IStrategyV2
    function inCaseTokensGetStuck(address _token) external {
        _onlyAdmin();

        if (_token == want) revert StrategyErrors.WrongStuckToken();

        uint256 _amount;

        if (_token != address(0)) {
            _amount = _getTokenBalance(_token);

            ERC20Lib.push(_token, adminStructure.superAdmin(), _amount);
        } else {
            _amount = address(this).balance;

            payable(adminStructure.superAdmin()).transfer(_amount);
        }

        emit WithdrawStuckTokens(adminStructure.superAdmin(), _token, _amount);
    }

    /// @inheritdoc IStrategyV2
    function editMinimumTokenCompound(address[] calldata _tokens, uint256[] calldata _minAmounts) external {
        _onlyAdmin();
        _editMinimumTokenCompound(_tokens, _minAmounts);
    }

    /// @inheritdoc IStrategyV2
    function balance() public view virtual returns (uint256);

    /**
     * @notice Initializes this StrategyV2 contract.
     * @param _adminStructure AdminStructure contract address.
     * @param _strategyHelper A helper contract address that is used in every strategy.
     * @param _feeManager FeeManager contract address.
     * @param _weth WETH token contract address.
     * @param _want A token address that should be deposited in the underlying protocol.
     * @param _tokensToCompound An array of the tokens to set the minimum to compound.
     * @param _minimumsToCompound An array of the minimum amounts to compound.
     */
    function _strategyV2InitUnchained(
        address _adminStructure,
        address _strategyHelper,
        address _feeManager,
        address _weth,
        address _want,
        address _calculations,
        address[] calldata _tokensToCompound,
        uint256[] calldata _minimumsToCompound
    )
        internal
        onlyInitializing
    {
        AddressUtils.onlyContract(_adminStructure);
        AddressUtils.onlyContract(_strategyHelper);
        AddressUtils.onlyContract(_feeManager);
        AddressUtils.onlyContract(_weth);
        AddressUtils.onlyContract(_want);
        AddressUtils.onlyContract(_calculations);

        adminStructure = IAdminStructure(_adminStructure);
        strategyHelper = IStrategyHelper(_strategyHelper);
        feeManager = IFeeManager(_feeManager);
        weth = IWETH(_weth);
        want = _want;
        calculations = ICalculations(_calculations);

        _editMinimumTokenCompound(_tokensToCompound, _minimumsToCompound);
    }

    /**
     * @notice Completes the deposit operation.
     * @param _depositKey A deposit key to match the deposit operation at the time of this callback execution.
     */
    function _completeDeposit(bytes32 _depositKey) internal {
        uint256 _currWantBalance = balance();
        uint256 _prevWantBalance = prevWantBalance;
        uint256 _depositedWant = _currWantBalance - _prevWantBalance;
        bytes memory _key = abi.encodePacked(_depositKey);
        DepositInfo memory _depositInfo = depositsInfo[_key];

        prevWantBalance = _currWantBalance;
        totalWantDeposits += _depositedWant;
        unchecked {
            userWantDeposit[_depositInfo.user] += _depositedWant;
        }

        vault.completeDeposit(_depositInfo.user, _depositedWant, _prevWantBalance);

        delete depositsInfo[_key];

        emit DepositCompleted(_key, _depositInfo.user, _depositInfo.originalToken, _depositInfo.amount, _depositedWant);
    }

    /**
     * @notice Cancels the deposit operation.
     * @param _depositKey A deposit key to match the deposit operation at the time of this callback execution.
     * @param _token A token address that was returned after the cancellation of the deposit.
     * @param _amount An amount of tokens that were returned.
     */
    function _cancelDeposit(bytes32 _depositKey, address _token, uint256 _amount) internal {
        bytes memory _key = abi.encodePacked(_depositKey);
        DepositInfo memory _depositInfo = depositsInfo[_key];

        if (_token != _depositInfo.token) {
            IStrategyHelper _strategyHelper = strategyHelper;

            ERC20Lib.safeApprove(_token, address(_strategyHelper), _amount);

            _amount = _strategyHelper.swap(_token, _depositInfo.token, _amount, slippageTolerance, address(this));
        }

        _pushTokens(_depositInfo.originalToken, _depositInfo.user, _amount);

        delete depositsInfo[_key];

        emit DepositCancelled(_key, _depositInfo.user, _depositInfo.originalToken, _depositInfo.amount);
    }

    /**
     * @notice Completes the withdrawal operation.
     * @param _withdrawalKey A withdrawal key to match the withdrawal operation at the time of this callback execution.
     * @param _token A token address that was returned after the withdrawal processing.
     * @param _amount An amount of tokens that were returned.
     */
    function _completeWithdrawal(bytes32 _withdrawalKey, address _token, uint256 _amount) internal {
        bytes memory _key = abi.encodePacked(_withdrawalKey);

        WithdrawalInfo memory _withdrawalInfo = withdrawalsInfo[_key];

        if (_token != _withdrawalInfo.token) {
            IStrategyHelper _strategyHelper = strategyHelper;

            ERC20Lib.safeApprove(_token, address(_strategyHelper), _amount);

            _amount = _strategyHelper.swap(_token, _withdrawalInfo.token, _amount, slippageTolerance, address(this));
            _token = _withdrawalInfo.token;
        }

        uint256 _withdrawalTokenOut = _amount;
        (uint256 _depositUsed, uint256 _rewardsUsed, uint256 _wantDepositUsed,) = calculations.calculateUsedAmounts(
            _withdrawalInfo.user, _withdrawalInfo.wantToWithdraw, _withdrawalInfo.maxUserWant, _withdrawalTokenOut
        );

        if (_wantDepositUsed != 0) {
            userWantDeposit[_withdrawalInfo.user] -= _wantDepositUsed;
            unchecked {
                totalWantDeposits -= _wantDepositUsed;
            }
        }

        _withdrawalTokenOut -= _chargeFees(IFeeManager.FeeType.MANAGEMENT, _token, _depositUsed);
        _withdrawalTokenOut -= _chargeFees(IFeeManager.FeeType.PERFORMANCE, _token, _rewardsUsed);

        _pushTokens(_withdrawalInfo.originalToken, _withdrawalInfo.recipient, _withdrawalTokenOut);

        vault.completeWithdrawal(_withdrawalInfo.user, _withdrawalInfo.amountShares);

        delete withdrawalsInfo[_key];

        emit WithdrawalCompleted(_key, _withdrawalInfo.user, _withdrawalInfo.originalToken, _withdrawalTokenOut);
    }

    /**
     * @notice Cancels the withdrawal operation.
     * @param _withdrawalKey A withdrawal key to match the withdrawal operation at the time of this callback execution.
     */
    function _cancelWithdrawal(bytes32 _withdrawalKey) internal {
        prevWantBalance = balance();

        bytes memory _key = abi.encodePacked(_withdrawalKey);
        WithdrawalInfo memory _withdrawalInfo = withdrawalsInfo[_key];

        delete withdrawalsInfo[_key];

        emit WithdrawalCanceled(
            _key, _withdrawalInfo.user, _withdrawalInfo.originalToken, _withdrawalInfo.wantToWithdraw
        );
    }

    /**
     * @notice Transfers ETH/ERC-20 tokens to the user.
     * @param _token A token address to transfer. Zero address for ETH.
     * @param _recipient A recipient of the tokens.
     * @param _amount An amount of tokens to transfer.
     */
    function _pushTokens(address _token, address _recipient, uint256 _amount) internal {
        if (_token == address(0)) {
            weth.withdraw(_amount);

            (bool _success,) = _recipient.call{ value: _amount }("");

            if (!_success) revert StrategyErrors.ETHTransferError();
        } else {
            ERC20Lib.push(_token, _recipient, _amount);
        }
    }

    /**
     * @notice Edits the minimum token compound amounts.
     * @param _tokens An array of token addresses to edit.
     * @param _minAmounts An array of minimum harvest amounts corresponding to the tokens.
     */
    function _editMinimumTokenCompound(address[] calldata _tokens, uint256[] calldata _minAmounts) internal {
        uint256 _tokensLength = _tokens.length;

        if (_tokensLength != _minAmounts.length) revert StrategyErrors.LengthsMismatch();

        for (uint256 _i; _i < _tokensLength; ++_i) {
            minimumToCompound[_tokens[_i]] = _minAmounts[_i];

            emit MinimumToCompoundChanged(_tokens[_i], _minAmounts[_i]);
        }
    }

    /**
     * @notice Prototype of the `_createDeposit()` method that should be implemented in each strategy.
     * @param _token Address of the token to deposit.
     * @param _amount Amount of the token to deposit.
     * @param _additionalData Encoded data which will be used in the time of deposit.
     * @return _depositKey Deposit identifier which will be used during callbacks processing to match the deposit with
     *                     callback.
     */
    function _createDeposit(
        address _token,
        uint256 _amount,
        bytes calldata _additionalData
    )
        internal
        virtual
        returns (bytes memory _depositKey);

    /**
     * @notice Prototype of the `_createWithdrawal()` method that should be implemented in each strategy.
     * @param _token Address of the token to withdraw in.
     * @param _wantToWithdraw The want amount to withdraw.
     * @param _additionalData Encoded data which will be used in the time of withdraw.
     * @return _withdrawalKey Withdrawal identifier which will be used during callbacks processing to match the
     *                        withdrawal with callback.
     */
    function _createWithdrawal(
        address _token,
        uint256 _wantToWithdraw,
        bytes calldata _additionalData
    )
        internal
        virtual
        returns (bytes memory _withdrawalKey);

    /**
     * @notice Prototype of the `_compound()` method that should be implemented in each strategy.
     * @param _data Encoded data to use at the time of the compound operation.
     */
    function _compound(bytes memory _data) internal virtual;

    /**
     * @notice Checks if a transaction sender is a super admin.
     */
    function _onlySuperAdmin() internal view {
        adminStructure.isValidSuperAdmin(msg.sender);
    }

    /**
     * @notice Checks if a transaction sender is an admin.
     */
    function _onlyAdmin() internal view {
        adminStructure.isValidAdmin(msg.sender);
    }

    /**
     * @notice Checks if a transaction sender is a vault contract.
     */
    function _onlyVault() internal view {
        if (msg.sender != address(vault)) revert StrategyErrors.NotVault(msg.sender);
    }

    /**
     * @notice Retrieves the balance of the specified token held by the strategy,
     * @param _token The address of the token to retrieve the balance for.
     * @return The balance of the token.
     */
    function _getTokenBalance(address _token) internal view returns (uint256) {
        return IERC20Upgradeable(_token).balanceOf(address(this));
    }

    /**
     * @notice Charges fees in the specified token.
     * @param _feeType The type of fee to charge.
     * @param _token The token in which to charge the fees.
     * @param _amount The amount of tokens to charge fees on.
     * @return The amount taken charged as fee.
     */
    function _chargeFees(IFeeManager.FeeType _feeType, address _token, uint256 _amount) private returns (uint256) {
        if (_amount == 0) return 0;

        IFeeManager _feeManager = feeManager;
        (address _feeRecipient, uint16 _fee) = _feeManager.fees(address(this), _feeType);

        if (_fee == 0) return 0;

        uint256 _feeAmount = (_amount * _fee) / ONE_HUNDRED_PERCENTS;

        IERC20Upgradeable(_token).safeTransfer(_feeRecipient, _feeAmount);

        emit ChargedFees(_feeType, _feeAmount, _feeRecipient, _token);

        return _feeAmount;
    }

    uint256[100] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

interface IExchangeRouter {
    struct CreateDepositParams {
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address initialLongToken;
        address initialShortToken;
        address[] longTokenSwapPath;
        address[] shortTokenSwapPath;
        uint256 minMarketTokens;
        bool shouldUnwrapNativeToken;
        uint256 executionFee;
        uint256 callbackGasLimit;
    }

    struct CreateWithdrawalParams {
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address[] longTokenSwapPath;
        address[] shortTokenSwapPath;
        uint256 minLongTokenAmount;
        uint256 minShortTokenAmount;
        bool shouldUnwrapNativeToken;
        uint256 executionFee;
        uint256 callbackGasLimit;
    }

    function sendWnt(address _receiver, uint256 _amount) external payable;

    function sendTokens(address _token, address _receiver, uint256 _amount) external payable;

    function createDeposit(CreateDepositParams calldata _params) external payable returns (bytes32);

    function createWithdrawal(CreateWithdrawalParams calldata _params) external payable returns (bytes32);

    function multicall(bytes[] calldata _data) external payable returns (bytes[] memory _results);

    function router() external returns (address);
}

interface IPrice {
    struct Props {
        uint256 min;
        uint256 max;
    }
}

interface IMarket {
    struct Prices {
        IPrice.Props indexTokenPrice;
        IPrice.Props longTokenPrice;
        IPrice.Props shortTokenPrice;
    }

    struct Props {
        address marketToken;
        address indexToken;
        address longToken;
        address shortToken;
    }
}

interface IMarketPoolValueInfo {
    struct Props {
        int256 poolValue;
        int256 longPnl;
        int256 shortPnl;
        int256 netPnl;
        uint256 longTokenAmount;
        uint256 shortTokenAmount;
        uint256 longTokenUsd;
        uint256 shortTokenUsd;
        uint256 totalBorrowingFees;
        uint256 borrowingFeePoolFactor;
        uint256 impactPoolAmount;
    }
}

interface IReader {
    function getMarket(address _dataStore, address _key) external view returns (IMarket.Props memory);

    function getMarketTokenPrice(
        address _dataStore,
        IMarket.Props memory _market,
        IPrice.Props memory _indexTokenPrice,
        IPrice.Props memory _longTokenPrice,
        IPrice.Props memory _shortTokenPrice,
        bytes32 _pnlFactorType,
        bool _maximize
    )
        external
        view
        returns (int256, IMarketPoolValueInfo.Props memory);

    function getDepositAmountOut(
        address _dataStore,
        IMarket.Props memory _market,
        IMarket.Prices memory _prices,
        uint256 _longTokenAmount,
        uint256 _shortTokenAmount,
        address _uiFeeReceiver
    )
        external
        view
        returns (uint256);

    function getWithdrawalAmountOut(
        address _dataStore,
        IMarket.Props memory _market,
        IMarket.Prices memory _prices,
        uint256 _marketTokenAmount,
        address _uiFeeReceiver
    )
        external
        view
        returns (uint256, uint256);
}

interface IHandler {
    function depositVault() external view returns (address);

    function withdrawalVault() external view returns (address);
}

interface IDataStore {
    function getUint(bytes32 _key) external view returns (uint256);
}

interface IDeposit {
    struct Props {
        Addresses addresses;
        Numbers numbers;
        Flags flags;
    }

    struct Addresses {
        address account;
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address initialLongToken;
        address initialShortToken;
        address[] longTokenSwapPath;
        address[] shortTokenSwapPath;
    }

    struct Numbers {
        uint256 initialLongTokenAmount;
        uint256 initialShortTokenAmount;
        uint256 minMarketTokens;
        uint256 updatedAtBlock;
        uint256 executionFee;
        uint256 callbackGasLimit;
    }

    struct Flags {
        bool shouldUnwrapNativeToken;
    }
}

interface IWithdrawal {
    struct Props {
        Addresses addresses;
        Numbers numbers;
        Flags flags;
    }

    struct Addresses {
        address account;
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address[] longTokenSwapPath;
        address[] shortTokenSwapPath;
    }

    struct Numbers {
        uint256 marketTokenAmount;
        uint256 minLongTokenAmount;
        uint256 minShortTokenAmount;
        uint256 updatedAtBlock;
        uint256 executionFee;
        uint256 callbackGasLimit;
    }

    struct Flags {
        bool shouldUnwrapNativeToken;
    }
}

interface IEventUtils {
    struct EventLogData {
        AddressItems addressItems;
        UintItems uintItems;
        IntItems intItems;
        BoolItems boolItems;
        Bytes32Items bytes32Items;
        BytesItems bytesItems;
        StringItems stringItems;
    }

    struct AddressItems {
        AddressKeyValue[] items;
        AddressArrayKeyValue[] arrayItems;
    }

    struct UintItems {
        UintKeyValue[] items;
        UintArrayKeyValue[] arrayItems;
    }

    struct IntItems {
        IntKeyValue[] items;
        IntArrayKeyValue[] arrayItems;
    }

    struct BoolItems {
        BoolKeyValue[] items;
        BoolArrayKeyValue[] arrayItems;
    }

    struct Bytes32Items {
        Bytes32KeyValue[] items;
        Bytes32ArrayKeyValue[] arrayItems;
    }

    struct BytesItems {
        BytesKeyValue[] items;
        BytesArrayKeyValue[] arrayItems;
    }

    struct StringItems {
        StringKeyValue[] items;
        StringArrayKeyValue[] arrayItems;
    }

    struct AddressKeyValue {
        string key;
        address value;
    }

    struct AddressArrayKeyValue {
        string key;
        address[] value;
    }

    struct UintKeyValue {
        string key;
        uint256 value;
    }

    struct UintArrayKeyValue {
        string key;
        uint256[] value;
    }

    struct IntKeyValue {
        string key;
        int256 value;
    }

    struct IntArrayKeyValue {
        string key;
        int256[] value;
    }

    struct BoolKeyValue {
        string key;
        bool value;
    }

    struct BoolArrayKeyValue {
        string key;
        bool[] value;
    }

    struct Bytes32KeyValue {
        string key;
        bytes32 value;
    }

    struct Bytes32ArrayKeyValue {
        string key;
        bytes32[] value;
    }

    struct BytesKeyValue {
        string key;
        bytes value;
    }

    struct BytesArrayKeyValue {
        string key;
        bytes[] value;
    }

    struct StringKeyValue {
        string key;
        string value;
    }

    struct StringArrayKeyValue {
        string key;
        string[] value;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

pragma solidity ^0.8.0;
import {Initializable} from "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

/**
 * @title Dollet ISuperAdmin
 * @author Dollet Team
 * @notice Interface for managing the super admin role.
 */
interface ISuperAdmin {
    /**
     * @notice Logs the information about nomination of a potential super admin.
     * @param _potentialSuperAdmin The address of the potential super admin.
     */
    event SuperAdminNominated(address _potentialSuperAdmin);

    /**
     * @notice Logs the information when the super admin role is transferred.
     * @param _oldSuperAdmin The address of the old super admin.
     * @param _newSuperAdmin The address of the new super admin.
     */
    event SuperAdminChanged(address _oldSuperAdmin, address _newSuperAdmin);

    /**
     * @notice Transfers the super admin role to a potential super admin address using pull-over-push pattern.
     * @param _superAdmin An address of a potential super admin.
     */
    function transferSuperAdmin(address _superAdmin) external;

    /**
     * @notice Accepts the super admin role by a potential super admin.
     */
    function acceptSuperAdmin() external;

    /**
     * @notice Returns the address of the super admin.
     * @return The address of the super admin.
     */
    function superAdmin() external view returns (address);

    /**
     * @notice Returns the address of the potential super admin.
     * @return The address of the potential super admin.
     */
    function potentialSuperAdmin() external view returns (address);

    /**
     * @notice Checks if the caller is a valid super admin.
     * @param caller The address to check.
     */
    function isValidSuperAdmin(address caller) external view;
}

/**
 * @title Dollet IAdminStructure
 * @author Dollet Team
 * @notice Interface for managing admin roles.
 */
interface IAdminStructure is ISuperAdmin {
    /**
     * @notice Logs the information when an admin is added.
     * @param admin The address of the added admin.
     */
    event AddedAdmin(address admin);

    /**
     * @notice Logs the information when an admin is removed.
     * @param admin The address of the removed admin.
     */
    event RemovedAdmin(address admin);

    /**
     * @notice Adds multiple addresses as admins.
     * @param _admins The addresses to add as admins.
     */
    function addAdmins(address[] calldata _admins) external;

    /**
     * @notice Removes multiple addresses from admins.
     * @param _admins The addresses to remove from admins.
     */
    function removeAdmins(address[] calldata _admins) external;

    /**
     * @notice Checks if the caller is a valid admin.
     * @param caller The address to check.
     */
    function isValidAdmin(address caller) external view;

    /**
     * @notice Checks if an account is an admin.
     * @param account The address to check.
     * @return A boolean indicating if the account is an admin.
     */
    function isAdmin(address account) external view returns (bool);

    /**
     * @notice Returns all the admin addresses.
     * @return An array of admin addresses.
     */
    function getAllAdmins() external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import { IAdminStructure } from "./IAdminStructure.sol";

/**
 * @title Dollet IFeeManager
 * @author Dollet Team
 * @notice Interface for FeeManager contract.
 */
interface IFeeManager {
    /**
     * @notice Fee type enumeration.
     * @param MANAGEMENT Fee type: management
     * @param PERFORMANCE Fee type: performance
     */
    enum FeeType {
        MANAGEMENT, // 0
        PERFORMANCE // 1

    }

    /**
     * @notice Fee structure.
     * @param recipient recipient of the fee.
     * @param fee The fee (as percentage with 2 decimals).
     */
    struct Fee {
        address recipient;
        uint16 fee;
    }

    /**
     * @notice Logs the information when a new fee is set.
     * @param _strategy Strategy contract address for which the fee is set.
     * @param _feeType Type of the fee.
     * @param _fee The fee structure itself.
     */
    event FeeSet(address indexed _strategy, FeeType indexed _feeType, Fee _fee);

    /**
     * @notice Allows the super admin to change the admin structure contract.
     * @param _adminStructure Admin structure contract address.
     */
    function setAdminStructure(address _adminStructure) external;

    /**
     * @notice Sets a new fee to provided strategy.
     * @param _strategy The strategy contract address to set a new fee for.
     * @param _feeType The fee type to set.
     * @param _recipient The recipient of the fee.
     * @param _fee The fee (as percentage with 2 decimals).
     */
    function setFee(address _strategy, FeeType _feeType, address _recipient, uint16 _fee) external;

    /**
     * @notice Retrieves a fee and its recipient for the provided strategy and fee type.
     * @param _strategy The strategy contract address to get the fee for.
     * @param _feeType The fee type to get the fee for.
     * @return _recipient The recipient of the fee.
     * @return _fee The fee (as percentage with 2 decimals).
     */
    function fees(address _strategy, FeeType _feeType) external view returns (address _recipient, uint16 _fee);

    /**
     * @notice Returns an address of the AdminStructure contract.
     * @return The address of the AdminStructure contract.
     */
    function adminStructure() external returns (IAdminStructure);

    /**
     * @notice Returns MAX_FEE constant value (with two decimals).
     * @return MAX_FEE constant value (with two decimals).
     */
    function MAX_FEE() external pure returns (uint16);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import { IAdminStructure } from "src/interfaces/dollet/IAdminStructure.sol";
import { ICalculations } from "src/interfaces/dollet/ICalculations.sol";
import { IStrategyV2 } from "src/interfaces/dollet/IStrategyV2.sol";
import { Signature } from "src/libraries/ERC20Lib.sol";
import { IWETH } from "src/interfaces/IWETH.sol";

/**
 * @title Dollet IVaultV2
 * @author Dollet Team
 * @notice Interface with all types, events, external, and public methods for the VaultV2 contract.
 */
interface IVaultV2 {
    /**
     * @notice Token types enumeration.
     */
    enum TokenType {
        Deposit,
        Withdrawal
    }

    /**
     * @notice Structure of the values to store the token min deposit limit.
     */
    struct DepositLimit {
        address token;
        uint256 minAmount;
    }

    /**
     * @notice Logs information when token changes its status (allowed/disallowed).
     * @param _tokenType A type of the token.
     * @param _token A token address.
     * @param _status A new status of the token.
     */
    event TokenStatusChanged(TokenType _tokenType, address _token, uint256 _status);

    /**
     * @notice Logs information when the pause status is changed.
     * @param _status The new pause status (true or false).
     */
    event PauseStatusChanged(bool _status);

    /**
     * @notice Logs information about the withdrawal of stuck tokens.
     * @param _caller An address of the admin who executed the withdrawal operation.
     * @param _token An address of a token that was withdrawn.
     * @param _amount An amount of tokens that were withdrawn.
     */
    event WithdrawStuckTokens(address _caller, address _token, uint256 _amount);

    /**
     * @notice Logs when the deposit limit of a token has been set.
     * @param _limitBefore The deposit limit before.
     * @param _limitAfter The deposit limit after.
     */
    event DepositLimitsSet(DepositLimit _limitBefore, DepositLimit _limitAfter);

    /**
     * @notice Initializes deposit to the strategy.
     * @param _user Address of the user providing the deposit tokens.
     * @param _token Address of the token to deposit.
     * @param _amount Amount of tokens to deposit.
     * @param _additionalData Additional encoded data for the deposit.
     */
    function deposit(address _user, address _token, uint256 _amount, bytes calldata _additionalData) external payable;

    /**
     * @notice Initializes deposit to the strategy using permit.
     * @param _user Address of the user providing the deposit tokens.
     * @param _token Address of the token to deposit.
     * @param _amount Amount of tokens to deposit.
     * @param _additionalData Additional encoded data for the deposit.
     * @param _signature Signature to make a deposit with permit.
     */
    function depositWithPermit(
        address _user,
        address _token,
        uint256 _amount,
        bytes calldata _additionalData,
        Signature calldata _signature
    )
        external
        payable;

    /**
     * @notice Completes a deposit operation. Only callable by the connected strategy contract.
     * @param _user A user address who made an initial deposit operation.
     * @param _depositedWant An amount of user's want tokens received as the result of a deposit.
     * @param _prevWantBalance The previous want tokens balance that was held by the strategy contract before the user's
     *                         deposit finished. Is used to calculate proper shares amount for the user.
     */
    function completeDeposit(address _user, uint256 _depositedWant, uint256 _prevWantBalance) external;

    /**
     * @notice Withdraw from the strategy.
     * @param _recipient Address of the recipient to receive the tokens.
     * @param _token Address of the token to withdraw.
     * @param _amountShares Amount of shares to withdraw from the user.
     * @param _additionalData Additional encoded data for the withdrawal.
     */
    function withdraw(
        address _recipient,
        address _token,
        uint256 _amountShares,
        bytes calldata _additionalData
    )
        external
        payable;

    /**
     * @notice Completes a withdrawal operation. Only callable by the connected strategy contract.
     * @param _user A user address who made an initial withdrawal operation.
     * @param _amountShares A number of shares that were used for withdrawal. Needed to substruct them during the
     *                     withdrawal callback execution inside of the VaultV2 contract.
     */
    function completeWithdrawal(address _user, uint256 _amountShares) external;

    /**
     * @notice Allows the super admin to change the admin structure contract address.
     * @param _adminStructure admin structure contract address.
     */
    function setAdminStructure(address _adminStructure) external;

    /**
     * @notice Edits deposit allowed tokens list.
     * @param _token An address of the token to allow/disallow.
     * @param _status A marker (true/false) that indicates if to allow/disallow a token.
     */
    function editDepositAllowedTokens(address _token, uint256 _status) external;

    /**
     * @notice Edits withdrawal allowed tokens list.
     * @param _token An address of the token to allow/disallow.
     * @param _status A marker (true/false) that indicates if to allow/disallow a token.
     */
    function editWithdrawalAllowedTokens(address _token, uint256 _status) external;

    /**
     * @notice Edits the deposit limits for specific tokens.
     * @param _depositLimits The array of DepositLimit struct to set.
     */
    function editDepositLimit(DepositLimit[] calldata _depositLimits) external;

    /**
     * @notice Pauses and unpauses the contract deposits.
     * @dev Sets the opposite of the current state of the pause.
     */
    function togglePause() external;

    /**
     * @notice Handles the case where tokens get stuck in the contract. Allows the admin to send the tokens to the super
     *         admin.
     * @param _token The address of the stuck token.
     */
    function inCaseTokensGetStuck(address _token) external;

    /**
     * @notice Returns a list of allowed tokens for a specified token type.
     * @param _tokenType A token type for which to return a list of tokens.
     * @return A list of allowed tokens for a specified token type.
     */
    function getListAllowedTokens(TokenType _tokenType) external view returns (address[] memory);

    /**
     * @notice Converts want tokens to vault shares.
     * @param _wantAmount An amount of want tokens to convert to vault shares.
     * @return An amount of vault shares in the specified want tokens amount.
     */
    function wantToShares(uint256 _wantAmount) external view returns (uint256);

    /**
     * @notice Returns the amount of the user deposit in terms of the token specified when possible, or in terms of want
     *         (to be processed off-chain).
     * @param _user The address of the user to get the deposit value for.
     * @param _token The address of the token to use.
     * @return The user deposit in the provided token.
     */
    function userDeposit(address _user, address _token) external view returns (uint256);

    /**
     * @notice Returns the amount of the total deposits in terms of the token specified when possible, or in terms of
     *         want (to be processed off-chain).
     * @param _token The address of the token to use.
     * @return The total deposit in the provided token.
     */
    function totalDeposits(address _token) external view returns (uint256);

    /**
     * @notice Returns the maximum number of want tokens that the user can withdraw.
     * @param _user A user address for whom to calculate the maximum number of want tokens that the user can withdraw.
     * @return The maximum number of want tokens that the user can withdraw.
     */
    function getUserMaxWant(address _user) external view returns (uint256);

    /**
     * @notice Helper function to calculate the required share to withdraw a specific amount of want tokens.
     * @dev The _wantToWithdraw must be taken from the function `estimateWithdrawal()`, the maximum amount is equivalent
     *      to `(_wantDepositAfterFee + _wantRewardsAfterFee)`.
     * @dev The flag `_withdrawAll` helps to avoid leaving remaining funds due to changes in the estimate since the user
     *      called `estimateWithdrawal()`.
     * @param _user The user to calculate the withdraw for.
     * @param _wantToWithdraw The amount of want tokens to withdraw (after compound and fees charging).
     * @param _slippageTolerance Slippage to use for the calculation.
     * @param _addionalData Encoded bytes with information about the reward tokens and slippage tolerance.
     * @param _withdrawAll Indicated whether to make a full withdrawal.
     * @return _sharesToWithdraw The amount of shares to withdraw for the specified amount of want tokens.
     */
    function calculateSharesToWithdraw(
        address _user,
        uint256 _wantToWithdraw,
        uint16 _slippageTolerance,
        bytes calldata _addionalData,
        bool _withdrawAll
    )
        external
        view
        returns (uint256 _sharesToWithdraw);

    /**
     * @notice Returns the deposit limit for a token.
     * @param _token The address of the token.
     * @return _limit The deposit limit for the specified token.
     */
    function getDepositLimit(address _token) external view returns (DepositLimit memory _limit);

    /**
     * @notice Estimates the deposit details for a specific token and amount.
     * @param _token The address to deposit.
     * @param _amount The amount of tokens to deposit.
     * @param _slippageTolerance The allowed slippage percentage.
     * @param _data Extra information used to estimate.
     * @param _addionalData Encoded bytes with information about the reward tokens and slippage tolerance.
     * @return _amountShares The amount of shares to receive from the vault.
     * @return _amountWant The minimum amount of LP tokens to get.
     */
    function estimateDeposit(
        address _token,
        uint256 _amount,
        uint16 _slippageTolerance,
        bytes calldata _data,
        bytes calldata _addionalData
    )
        external
        view
        returns (uint256 _amountShares, uint256 _amountWant);

    /**
     * @notice Converts vault shares to want tokens.
     * @param _sharesAmount An amount of vault shares to convert to want tokens.
     * @return An amount of want tokens in the specified vault shares amount.
     */
    function sharesToWant(uint256 _sharesAmount) external view returns (uint256);

    /**
     * @notice Shows the equivalent amount of shares converted to want tokens, considering compounding.
     * @dev Since this function uses slippage the actual result after a real compound might be slightly different.
     * @dev The result does not consider the system fees.
     * @param _sharesAmount The amount of shares.
     * @param _slippageTolerance The slippage for the compounding.
     * @param _addionalData Encoded bytes with information about the reward tokens and slippage tolerance.
     * @return The amount of want tokens equivalent to the shares considering compounding.
     */
    function sharesToWantAfterCompound(
        uint256 _sharesAmount,
        uint16 _slippageTolerance,
        bytes calldata _addionalData
    )
        external
        view
        returns (uint256);

    /**
     * @notice Shows the maximum want tokens that a user could obtain considering compounding.
     * @dev Since this function uses slippage the actual result after a real compound might be slightly different.
     * @dev The result does not consider the system fees.
     * @param _user The user to be analyzed. Use strategy address to calculate for all users.
     * @param _slippageTolerance The slippage for the compounding.
     * @param _addionalData Encoded bytes with information about the reward tokens and slippage tolerance.
     * @return The maximum amount of want tokens that the user has.
     */
    function getUserMaxWantWithCompound(
        address _user,
        uint16 _slippageTolerance,
        bytes calldata _addionalData
    )
        external
        view
        returns (uint256);

    /**
     * @notice Shows the maximum want tokens from the deposit and rewards that the user has, it estimates the want
     *         tokens that the user can withdraw after compounding and fees. Use strategy address to calculate for all
     *         users.
     * @dev Combine this function with the function `calculateSharesToWithdraw()`.
     * @dev Since this function uses slippage tolerance the actual result after a real compound might be slightly
     *      different.
     * @param _user The user to be analyzed.
     * @param _slippageTolerance The slippage tolerance for the compounding.
     * @param _addionalData Encoded bytes with information about the reward tokens and slippage tolerance.
     * @param _token The token to use for the withdrawal.
     * @return WithdrawalEstimation a struct including the data about the withdrawal:
     * wantDepositUsed Portion of the total want tokens that belongs to the deposit of the user.
     * wantRewardsUsed Portion of the total want tokens that belongs to the rewards of the user.
     * wantDepositAfterFee Portion of the total want tokens after fee that belongs to the deposit of the user.
     * wantRewardsAfterFee Portion of the total want tokens after fee that belongs to the rewards of the user.
     * depositInToken Deposit amount valued in token.
     * rewardsInToken Rewards amount valued in token.
     * depositInTokenAfterFee Deposit after fee amount valued in token.
     * rewardsInTokenAfterFee Rewards after fee amount valued in token.
     */
    function estimateWithdrawal(
        address _user,
        uint16 _slippageTolerance,
        bytes calldata _addionalData,
        address _token
    )
        external
        view
        returns (ICalculations.WithdrawalEstimation memory);

    /**
     * @notice Calculates the total balance of the want token that belong to the startegy. It takes into account the
     *         strategy contract balance and any underlying protocol that holds the want tokens.
     * @return The total balance of the want token.
     */
    function balance() external view returns (uint256);

    /**
     * @notice Mapping to track the amount of shares owned by each user.
     * @return An amount of shares dedicated for a user.
     */
    function userShares(address user) external view returns (uint256);

    /**
     * @notice Mapping to check if a token is allowed for deposit (1 - allowed, 2 - not allowed).
     * @return A flag that indicates if the token is allowed for deposits or not.
     */
    function depositAllowedTokens(address token) external view returns (uint256);

    /**
     * @notice Mapping to check if a token is allowed for withdrawal (1 - allowed, 2 - not allowed).
     * @return A flag that indicates if the token is allowed for withdrawals or not.
     */
    function withdrawalAllowedTokens(address token) external view returns (uint256);

    /**
     * @notice Returns a list of tokens allowed for deposit.
     * @return A list of tokens allowed for deposit.
     */
    function listDepositAllowedTokens(uint256 index) external view returns (address);

    /**
     * @notice Returns a list of tokens allowed for withdrawal.
     * @return A list of tokens allowed for withdrawal.
     */
    function listWithdrawalAllowedTokens(uint256 index) external view returns (address);

    /**
     * @notice Returns an address of the AdminStructure contract.
     * @return An address of the AdminStructure contract.
     */
    function adminStructure() external view returns (IAdminStructure);

    /**
     * @notice Returns an address of the StrategyV2 contract.
     * @return An address of the StrategyV2 contract.
     */
    function strategy() external view returns (IStrategyV2);

    /**
     * @notice Returns an address of the WETH token contract.
     * @return An address of the WETH token contract.
     */
    function weth() external view returns (IWETH);

    /**
     * @notice Returns total number of shares across all users.
     * @return Total number of shares across all users.
     */
    function totalShares() external view returns (uint256);

    /**
     * @notice Returns calculation contract.
     * @return An address of the calculations contract.
     */
    function calculations() external view returns (ICalculations);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import { IERC20 } from "./IERC20.sol";

/**
 * @title Dollet IWETH
 * @author Dollet Team
 * @notice Wrapped Ether (WETH) Interface. This interface defines the functions for interacting with the Wrapped Ether
 *         (WETH) contract.
 */
interface IWETH is IERC20 {
    /**
     * @notice Deposits ETH to mint WETH tokens. This function is payable, and the amount of ETH sent will be converted
     *         to WETH.
     */
    function deposit() external payable;

    /**
     * @notice Withdraws WETH and receives ETH.
     * @param _amount The amount of WETH to burn, represented in wei.
     */
    function withdraw(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20Upgradeable token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && AddressUpgradeable.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
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
     *
     * CAUTION: See Security Considerations above.
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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import {Initializable} from "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import { IAdminStructure } from "./IAdminStructure.sol";
import { IStrategyHelper } from "./IStrategyHelper.sol";

/**
 * @title Dollet ICalculations
 * @author Dollet Team
 * @notice Interface for Calculations contract.
 */
interface ICalculations {
    /**
     * @param wantDeposit Portion of the total want tokens that belongs to the deposit of the user.
     * @param wantRewards Portion of the total want tokens that belongs to the rewards of the user.
     * @param wantDepositAfterFee Portion of the total want tokens after fee that belongs to the deposit of the user.
     * @param wantRewardsAfterFee Portion of the total want tokens after fee that belongs to the rewards of the user.
     * @param depositInToken Deposit amount valued in token.
     * @param rewardsInToken Rewards amount valued in token.
     * @param depositInTokenAfterFee Deposit after fee amount valued in token.
     * @param rewardsInTokenAfterFee Rewards after fee amount valued in token.
     */
    struct WithdrawalEstimation {
        uint256 wantDeposit;
        uint256 wantRewards;
        uint256 wantDepositAfterFee;
        uint256 wantRewardsAfterFee;
        uint256 depositInToken;
        uint256 rewardsInToken;
        uint256 depositInTokenAfterFee;
        uint256 rewardsInTokenAfterFee;
    }

    /**
     * @notice Logs information when a Strategy contract is set.
     * @param _strategy Strategy contract address.
     */
    event StrategySet(address _strategy);

    /**
     * @notice Logs information when a StrategyHelper contract is set.
     * @param _strategyHelper StrategyHelper contract address.
     */
    event StrategyHelperSet(address _strategyHelper);

    /**
     * @notice Allows the super admin to set the strategy values (Strategy and StrategyHelper contracts' addresses).
     * @param _strategy Address of the Strategy contract.
     */
    function setStrategyValues(address _strategy) external;

    /**
     * @notice Returns the value of 100% with 2 decimals.
     * @return The value of 100% with 2 decimals.
     */
    function ONE_HUNDRED_PERCENTS() external view returns (uint16);

    /**
     * @notice Returns AdminStructure contract address.
     * @return AdminStructure contract address.
     */
    function adminStructure() external view returns (IAdminStructure);

    /**
     * @notice Returns StrategyHelper contract address.
     * @return StrategyHelper contract address.
     */
    function strategyHelper() external view returns (IStrategyHelper);

    /**
     * @notice Returns the Strategy contract address.
     * @return Strategy contract address.
     */
    function strategy() external view returns (address payable);

    /**
     * @notice Returns the amount of the user deposit in terms of the token specified.
     * @param _user The address of the user to get the deposit value for.
     * @param _token The address of the token to use.
     * @return The estimated user deposit in the specified token.
     */
    function userDeposit(address _user, address _token) external view returns (uint256);

    /**
     * @notice Returns the amount of the total deposits in terms of the token specified.
     * @param _token The address of the token to use.
     * @return The amount of total deposit in the specified token.
     */
    function totalDeposits(address _token) external view returns (uint256);

    /**
     * @notice Returns the balance of the want token of the strategy after making a compound.
     * @param _slippageTolerance Slippage to use for the calculation.
     * @param _rewardData Encoded bytes with information about the reward tokens.
     * @return The want token balance after a compound.
     */
    function estimateWantAfterCompound(
        uint16 _slippageTolerance,
        bytes calldata _rewardData
    )
        external
        view
        returns (uint256);

    /**
     * @notice Returns the expected amount of want tokens to be obtained from a deposit.
     * @param _token The token to be used for deposit.
     * @param _amount The amount of tokens to be deposited.
     * @param _slippageTolerance The slippage tolerance for the deposit.
     * @param _data Extra information used to estimate.
     * @return The minimum want tokens expected to be obtained from the deposit.
     */
    function estimateDeposit(
        address _token,
        uint256 _amount,
        uint256 _slippageTolerance,
        bytes calldata _data
    )
        external
        view
        returns (uint256);

    /**
     * @notice Estimates the price of an amount of want tokens in the specified token.
     * @param _token The address of the token.
     * @param _amount The amount of want tokens.
     * @param _slippageTolerance The allowed slippage percentage.
     * @return _amountInToken The minimum amount of tokens to get from the want amount.
     */
    function estimateWantToToken(
        address _token,
        uint256 _amount,
        uint16 _slippageTolerance
    )
        external
        view
        returns (uint256 _amountInToken);

    /**
     * @notice Calculates the withdrawable amount of a user.
     * @param _user The address of the user to get the withdrawable amount. (Use strategy address to calculate for all
     *              users).
     * @param _wantToWithdraw The amount of want to withdraw.
     * @param _maxUserWant The maximum amount of want that the user can withdraw.
     * @param _token Address of the to use for the calculation.
     * @param _slippageTolerance Slippage to use for the calculation.
     * @return _estimation WithdrawalEstimation struct including the data about the withdrawal:
     *         wantDepositUsed Portion of the total want tokens that belongs to the deposit of the user.
     *         wantRewardsUsed Portion of the total want tokens that belongs to the rewards of the user.
     *         wantDepositAfterFee Portion of the total want tokens after fee that belongs to the deposit of the user.
     *         wantRewardsAfterFee Portion of the total want tokens after fee that belongs to the rewards of the user.
     *         depositInToken Deposit amount valued in token.
     *         rewardsInToken Rewards amount valued in token.
     *         depositInTokenAfterFee Deposit after fee amount valued in token.
     *         rewardsInTokenAfterFee Rewards after fee amount valued in token.
     */
    function getWithdrawableAmount(
        address _user,
        uint256 _wantToWithdraw,
        uint256 _maxUserWant,
        address _token,
        uint16 _slippageTolerance
    )
        external
        view
        returns (WithdrawalEstimation memory _estimation);

    /**
     * @notice Calculates the used amounts from a given token amount on a withdrawal.
     * @param _user User to read the information from. (Use strategy address to calculate for all users).
     * @param _wantToWithdraw Amount from the total want tokens of the user wants to withdraw.
     * @param _maxUserWant The maximum user want to withdraw.
     * @param _withdrawalTokenOut The expected amount of tokens for the want tokens withdrawn.
     * @return _depositUsed Distibution of the token out amount that belongs to the deposit.
     * @return _rewardsUsed Distibution of the token out amount that belongs to the rewards.
     * @return _wantDepositUsed Portion the total want tokens that belongs to the deposit of the user.
     * @return _wantRewardsUsed Portion the total want tokens that belongs to the rewards of the user.
     */
    function calculateUsedAmounts(
        address _user,
        uint256 _wantToWithdraw,
        uint256 _maxUserWant,
        uint256 _withdrawalTokenOut
    )
        external
        view
        returns (uint256 _depositUsed, uint256 _rewardsUsed, uint256 _wantDepositUsed, uint256 _wantRewardsUsed);

    /**
     * @notice Calculates the withdrawable distribution of a user.
     * @param _user A user to read the proportional distribution. (Use strategy address to calculate for all users).
     * @param _wantToWithdraw Amount from the total want tokens of the user wants to withdraw.
     * @param _maxUserWant The maximum user want to withdraw.
     * @return _wantDepositUsed Portion the total want tokens that belongs to the deposit of the user.
     * @return _wantRewardsUsed Portion the total want tokens that belongs to the rewards of the user.
     */
    function calculateWithdrawalDistribution(
        address _user,
        uint256 _wantToWithdraw,
        uint256 _maxUserWant
    )
        external
        view
        returns (uint256 _wantDepositUsed, uint256 _wantRewardsUsed);

    /**
     * @notice Calculates the minimum output amount applying a slippage tolerance percentage to the amount.
     * @param _amount The amount of tokens to use.
     * @param _minusPercentage The percentage to reduce from the amount.
     * @return _result The minimum output amount.
     */
    function getMinimumOutputAmount(
        uint256 _amount,
        uint256 _minusPercentage
    )
        external
        pure
        returns (uint256 _result);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

/**
 * @title Dollet StrategyErrors library
 * @author Dollet Team
 * @notice Library with all Strategy errors.
 */
library StrategyErrors {
    error InsufficientWithdrawalTokenOut();
    error InsufficientDepositTokenOut();
    error SlippageToleranceTooHigh();
    error NotVault(address _caller);
    error ETHTransferError();
    error WrongStuckToken();
    error LengthsMismatch();
    error UseWantToken();
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @title Dollet IERC20
 * @author Dollet Team
 * @notice Default IERC20 interface with additional view methods.
 */
interface IERC20 is IERC20Upgradeable {
    /**
     * @notice Returns the number of decimals used by the token.
     * @return The number of decimals used by the token.
     */
    function decimals() external view returns (uint8);

    /**
     * @notice Returns the name of the token.
     * @return A string representing the token name.
     */
    function name() external view returns (string memory);

    /**
     * @notice Returns the symbol of the token.
     * @return A string representing the token symbol.
     */
    function symbol() external view returns (string memory);
}