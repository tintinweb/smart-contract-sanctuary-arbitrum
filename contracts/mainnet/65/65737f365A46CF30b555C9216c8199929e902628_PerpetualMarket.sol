//SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IFeePool.sol";
import "./interfaces/IPerpetualMarketCore.sol";
import "./interfaces/IPerpetualMarket.sol";
import "./base/BaseLiquidityPool.sol";
import "./lib/TraderVaultLib.sol";
import "./interfaces/IVaultNFT.sol";

/**
 * @title Perpetual Market
 * @notice Perpetual Market Contract is entry point of traders and liquidity providers.
 * It manages traders' vault storage and holds funds from traders and liquidity providers.
 *
 * Error Codes
 * PM0: tx exceed deadline
 * PM1: limit price
 * PM2: caller is not vault owner
 */
contract PerpetualMarket is IPerpetualMarket, BaseLiquidityPool, Ownable {
    using SafeERC20 for IERC20;
    using SafeCast for int256;
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using SignedSafeMath for int128;
    using TraderVaultLib for TraderVaultLib.TraderVault;

    uint256 private constant MAX_PRODUCT_ID = 2;

    /// @dev liquidation fee is 20%
    int256 private constant LIQUIDATION_FEE = 2000;

    IPerpetualMarketCore private immutable perpetualMarketCore;

    // Fee recepient address
    IFeePool public feeRecepient;

    address private vaultNFT;

    // trader's vaults storage
    mapping(uint256 => TraderVaultLib.TraderVault) private traderVaults;

    event Deposited(address indexed account, uint256 issued, uint256 amount);

    event Withdrawn(address indexed account, uint256 burned, uint256 amount);

    event PositionUpdated(
        address indexed trader,
        uint256 vaultId,
        uint256 subVaultIndex,
        uint256 productId,
        int256 tradeAmount,
        uint256 tradePrice,
        int256 fundingFeePerPosition,
        int256 deltaUsdcPosition,
        bytes metadata
    );
    event DepositedToVault(address indexed trader, uint256 vaultId, uint256 amount);
    event WithdrawnFromVault(address indexed trader, uint256 vaultId, uint256 amount);
    event Liquidated(address liquidator, uint256 indexed vaultId, uint256 reward);

    event Hedged(address hedger, bool isBuyingUnderlying, uint256 usdcAmount, uint256 underlyingAmount);

    event SetFeeRecepient(address feeRecepient);

    /**
     * @notice Constructor of Perpetual Market contract
     */
    constructor(
        address _perpetualMarketCoreAddress,
        address _quoteAsset,
        address _underlyingAsset,
        address _feeRecepient,
        address _vaultNFT
    ) BaseLiquidityPool(_quoteAsset, _underlyingAsset) {
        require(_feeRecepient != address(0));

        perpetualMarketCore = IPerpetualMarketCore(_perpetualMarketCoreAddress);
        feeRecepient = IFeePool(_feeRecepient);
        vaultNFT = _vaultNFT;
    }

    /**
     * @notice Initializes Perpetual Pool
     * @param _depositAmount deposit amount
     * @param _initialFundingRate initial funding rate
     */
    function initialize(uint256 _depositAmount, int256 _initialFundingRate) external override {
        require(_depositAmount > 0 && _initialFundingRate > 0);

        uint256 lpTokenAmount = perpetualMarketCore.initialize(msg.sender, _depositAmount * 1e2, _initialFundingRate);

        IERC20(quoteAsset).safeTransferFrom(msg.sender, address(this), _depositAmount);

        emit Deposited(msg.sender, lpTokenAmount, _depositAmount);
    }

    /**
     * @notice Provides liquidity to the pool and mints LP tokens
     */
    function deposit(uint256 _depositAmount) external override {
        require(_depositAmount > 0);

        // Funding payment should be proceeded before deposit
        perpetualMarketCore.executeFundingPayment();

        uint256 lpTokenAmount = perpetualMarketCore.deposit(msg.sender, _depositAmount * 1e2);

        IERC20(quoteAsset).safeTransferFrom(msg.sender, address(this), _depositAmount);

        emit Deposited(msg.sender, lpTokenAmount, _depositAmount);
    }

    /**
     * @notice Withdraws liquidity from the pool and burn LP tokens
     */
    function withdraw(uint128 _withdrawnAmount) external override {
        require(_withdrawnAmount > 0);

        // Funding payment should be proceeded before withdrawal
        perpetualMarketCore.executeFundingPayment();

        uint256 lpTokenAmount = perpetualMarketCore.withdraw(msg.sender, _withdrawnAmount * 1e2);

        // Send liquidity to msg.sender
        sendLiquidity(msg.sender, _withdrawnAmount);

        emit Withdrawn(msg.sender, lpTokenAmount, _withdrawnAmount);
    }

    /**
     * @notice Opens new positions or closes hold position of the perpetual contracts
     * and manage margin in the vault at the same time.
     * @param _tradeParams trade parameters
     */
    function trade(MultiTradeParams memory _tradeParams) external override {
        // check the transaction not exceed deadline
        require(_tradeParams.deadline == 0 || _tradeParams.deadline >= block.number, "PM0");

        if (_tradeParams.vaultId == 0) {
            // open new vault
            _tradeParams.vaultId = IVaultNFT(vaultNFT).mintNFT(msg.sender);
        } else {
            // check caller is vault owner
            require(IVaultNFT(vaultNFT).ownerOf(_tradeParams.vaultId) == msg.sender, "PM2");
        }

        // funding payment should bee proceeded before trade
        perpetualMarketCore.executeFundingPayment();

        uint256 totalProtocolFee;

        for (uint256 i = 0; i < _tradeParams.trades.length; i++) {
            totalProtocolFee = totalProtocolFee.add(
                updatePosition(
                    traderVaults[_tradeParams.vaultId],
                    _tradeParams.trades[i].productId,
                    _tradeParams.vaultId,
                    _tradeParams.trades[i].subVaultIndex,
                    _tradeParams.trades[i].tradeAmount,
                    _tradeParams.trades[i].limitPrice,
                    _tradeParams.trades[i].metadata
                )
            );
        }

        // Add protocol fee
        if (totalProtocolFee > 0) {
            IERC20(quoteAsset).approve(address(feeRecepient), totalProtocolFee);
            feeRecepient.sendProfitERC20(address(this), totalProtocolFee);
        }

        int256 finalDepositOrWithdrawAmount;

        finalDepositOrWithdrawAmount = traderVaults[_tradeParams.vaultId].updateUsdcPosition(
            _tradeParams.marginAmount.mul(1e2),
            perpetualMarketCore.getTradePriceInfo(traderVaults[_tradeParams.vaultId].getPositionPerpetuals())
        );

        // Try to update variance after trade
        perpetualMarketCore.updatePoolSnapshot();

        if (finalDepositOrWithdrawAmount > 0) {
            uint256 depositAmount = uint256(finalDepositOrWithdrawAmount / 1e2);
            IERC20(quoteAsset).safeTransferFrom(msg.sender, address(this), depositAmount);
            emit DepositedToVault(msg.sender, _tradeParams.vaultId, depositAmount);
        } else if (finalDepositOrWithdrawAmount < 0) {
            uint256 withdrawAmount = uint256(-finalDepositOrWithdrawAmount) / 1e2;
            sendLiquidity(msg.sender, withdrawAmount);
            emit WithdrawnFromVault(msg.sender, _tradeParams.vaultId, withdrawAmount);
        }
    }

    /**
     * @notice Liquidates a vault by Pool
     * Anyone can liquidate a vault whose PositionValue is less than MinCollateral.
     * The caller gets a portion of the margin as reward.
     * @param _vaultId The id of target vault
     */
    function liquidateByPool(uint256 _vaultId) external override {
        // funding payment should bee proceeded before liquidation
        perpetualMarketCore.executeFundingPayment();

        TraderVaultLib.TraderVault storage traderVault = traderVaults[_vaultId];

        IPerpetualMarketCore.TradePriceInfo memory tradePriceInfo = perpetualMarketCore.getTradePriceInfo(
            traderVault.getPositionPerpetuals()
        );

        // Check if PositionValue is less than MinCollateral or not
        require(traderVault.checkVaultIsLiquidatable(tradePriceInfo), "vault is not danger");

        int256 minCollateral = traderVault.getMinCollateral(tradePriceInfo);

        // Close all positions in the vault
        uint256 totalProtocolFee;
        for (uint256 subVaultIndex = 0; subVaultIndex < traderVault.subVaults.length; subVaultIndex++) {
            for (uint256 productId = 0; productId < MAX_PRODUCT_ID; productId++) {
                int128 amountAssetInVault = traderVault.subVaults[subVaultIndex].positionPerpetuals[productId];

                totalProtocolFee = totalProtocolFee.add(
                    updatePosition(traderVault, productId, _vaultId, subVaultIndex, -amountAssetInVault, 0, "")
                );
            }
        }

        traderVault.setInsolvencyFlagIfNeeded();

        uint256 reward = traderVault.decreaseLiquidationReward(minCollateral, LIQUIDATION_FEE);

        // Sends a half of reward to the pool
        perpetualMarketCore.addLiquidity(reward / 2);

        // Sends a half of reward to the liquidator
        sendLiquidity(msg.sender, reward / (2 * 1e2));

        // Try to update variance after liquidation
        perpetualMarketCore.updatePoolSnapshot();

        // Sends protocol fee
        if (totalProtocolFee > 0) {
            IERC20(quoteAsset).approve(address(feeRecepient), totalProtocolFee);
            feeRecepient.sendProfitERC20(address(this), totalProtocolFee);
        }

        emit Liquidated(msg.sender, _vaultId, reward);
    }

    function updatePosition(
        TraderVaultLib.TraderVault storage _traderVault,
        uint256 _productId,
        uint256 _vaultId,
        uint256 _subVaultIndex,
        int128 _tradeAmount,
        uint256 _limitPrice,
        bytes memory _metadata
    ) internal returns (uint256) {
        if (_tradeAmount != 0) {
            (uint256 tradePrice, int256 fundingFeePerPosition, uint256 protocolFee) = perpetualMarketCore
                .updatePoolPosition(_productId, _tradeAmount);

            require(checkPrice(_tradeAmount > 0, tradePrice, _limitPrice), "PM1");

            int256 deltaUsdcPosition = _traderVault.updateVault(
                _subVaultIndex,
                _productId,
                _tradeAmount,
                tradePrice,
                fundingFeePerPosition
            );

            emit PositionUpdated(
                msg.sender,
                _vaultId,
                _subVaultIndex,
                _productId,
                _tradeAmount,
                tradePrice,
                fundingFeePerPosition,
                deltaUsdcPosition,
                _metadata
            );

            return protocolFee / 1e2;
        }
        return 0;
    }

    /**
     * @notice Gets token amount for hedging
     * @return Amount of USDC and underlying reqired for hedging
     */
    function getTokenAmountForHedging()
        external
        view
        override
        returns (
            bool,
            uint256,
            uint256
        )
    {
        NettingLib.CompleteParams memory completeParams = perpetualMarketCore.getTokenAmountForHedging();

        return (
            completeParams.isLong,
            completeParams.amountUsdc / 1e2,
            Math.scale(completeParams.amountUnderlying, 8, ERC20(underlyingAsset).decimals())
        );
    }

    /**
     * @notice Executes hedging
     */
    function execHedge() external override returns (uint256 amountUsdc, uint256 amountUnderlying) {
        // execute funding payment
        perpetualMarketCore.executeFundingPayment();

        // Try to update variance after funding payment
        perpetualMarketCore.updatePoolSnapshot();

        // rebalance
        perpetualMarketCore.rebalance();

        NettingLib.CompleteParams memory completeParams = perpetualMarketCore.getTokenAmountForHedging();

        perpetualMarketCore.completeHedgingProcedure(completeParams);

        amountUsdc = completeParams.amountUsdc / 1e2;
        amountUnderlying = Math.scale(completeParams.amountUnderlying, 8, ERC20(underlyingAsset).decimals());

        if (completeParams.isLong) {
            IERC20(underlyingAsset).safeTransferFrom(msg.sender, address(this), amountUnderlying);
            sendLiquidity(msg.sender, amountUsdc);
        } else {
            IERC20(quoteAsset).safeTransferFrom(msg.sender, address(this), amountUsdc);
            sendUndrlying(msg.sender, amountUnderlying);
        }

        emit Hedged(msg.sender, completeParams.isLong, amountUsdc, amountUnderlying);
    }

    /**
     * @notice Compares trade price and limit price
     * For long, if trade price is less than limit price then return true.
     * For short, if trade price is greater than limit price then return true.
     * if limit price is 0 then always return true.
     * @param _isLong true if the trade is long and false if the trade is short
     * @param _tradePrice trade price per trade amount
     * @param _limitPrice the worst price the trader accept
     */
    function checkPrice(
        bool _isLong,
        uint256 _tradePrice,
        uint256 _limitPrice
    ) internal pure returns (bool) {
        if (_limitPrice == 0) {
            return true;
        }
        if (_isLong) {
            return _tradePrice <= _limitPrice;
        } else {
            return _tradePrice >= _limitPrice;
        }
    }

    /**
     * @notice Gets current LP token price
     * @param _deltaLiquidityAmount difference of liquidity
     * If LPs want LP token price of deposit, _deltaLiquidityAmount is positive number of amount to deposit.
     * On the other hand, if LPs want LP token price of withdrawal, _deltaLiquidityAmount is negative number of amount to withdraw.
     * @return LP token price scaled by 1e6
     */
    function getLPTokenPrice(int256 _deltaLiquidityAmount) external view override returns (uint256) {
        return perpetualMarketCore.getLPTokenPrice(_deltaLiquidityAmount);
    }

    /**
     * @notice Gets trade price
     * @param _productId product id
     * @param _tradeAmount amount of position to trade. positive to get long price and negative to get short price.
     * @return trade info
     */
    function getTradePrice(uint256 _productId, int128 _tradeAmount) external view override returns (TradeInfo memory) {
        (
            int256 tradePrice,
            int256 indexPrice,
            int256 fundingRate,
            int256 tradeFee,
            int256 protocolFee
        ) = perpetualMarketCore.getTradePrice(_productId, _tradeAmount);

        return
            TradeInfo(
                tradePrice,
                indexPrice,
                fundingRate,
                tradeFee,
                protocolFee,
                indexPrice.mul(fundingRate).div(1e8),
                tradePrice.toUint256().mul(Math.abs(_tradeAmount)).div(1e8),
                tradeFee.toUint256().mul(Math.abs(_tradeAmount)).div(1e8)
            );
    }

    /**
     * @notice Gets value of min collateral to add positions
     * @param _vaultId The id of target vault
     * @param _tradeAmounts amounts to trade
     * @return minCollateral scaled by 1e6
     */
    function getMinCollateralToAddPosition(uint256 _vaultId, int128[2] memory _tradeAmounts)
        external
        view
        override
        returns (int256 minCollateral)
    {
        TraderVaultLib.TraderVault memory traderVault = traderVaults[_vaultId];

        minCollateral = traderVault.getMinCollateralToAddPosition(
            _tradeAmounts,
            perpetualMarketCore.getTradePriceInfo(traderVault.getPositionPerpetuals())
        );

        minCollateral = minCollateral / 1e2;
    }

    function getTraderVault(uint256 _vaultId) external view override returns (TraderVaultLib.TraderVault memory) {
        return traderVaults[_vaultId];
    }

    /**
     * @notice Gets position value of a vault
     * @param _vaultId The id of target vault
     * @return vault status
     */
    function getVaultStatus(uint256 _vaultId) external view override returns (VaultStatus memory) {
        TraderVaultLib.TraderVault memory traderVault = traderVaults[_vaultId];

        IPerpetualMarketCore.TradePriceInfo memory tradePriceInfo = perpetualMarketCore.getTradePriceInfo(
            traderVault.getPositionPerpetuals()
        );

        int256[2][] memory positionValues = new int256[2][](traderVault.subVaults.length);
        int256[2][] memory fundingPaid = new int256[2][](traderVault.subVaults.length);

        for (uint256 i = 0; i < traderVault.subVaults.length; i++) {
            for (uint256 j = 0; j < MAX_PRODUCT_ID; j++) {
                positionValues[i][j] = TraderVaultLib.getPerpetualValueOfSubVault(
                    traderVault.subVaults[i],
                    j,
                    tradePriceInfo
                );
                fundingPaid[i][j] = TraderVaultLib.getFundingFeePaidOfSubVault(
                    traderVault.subVaults[i],
                    j,
                    tradePriceInfo.amountsFundingPaidPerPosition
                );
            }
        }

        return
            VaultStatus(
                traderVault.getPositionValue(tradePriceInfo),
                traderVault.getMinCollateral(tradePriceInfo),
                positionValues,
                fundingPaid,
                traderVault
            );
    }

    /////////////////////////
    //  Admin Functions    //
    /////////////////////////

    /**
     * @notice Sets new fee recepient
     * @param _feeRecepient The address of new fee recepient
     */
    function setFeeRecepient(address _feeRecepient) external onlyOwner {
        require(_feeRecepient != address(0));
        feeRecepient = IFeePool(_feeRecepient);
        emit SetFeeRecepient(_feeRecepient);
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

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;

interface IFeePool {
    function sendProfitERC20(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;
pragma abicoder v2;

import "../lib/NettingLib.sol";

interface IPerpetualMarketCore {
    struct TradePriceInfo {
        uint128 spotPrice;
        int256[2] tradePrices;
        int256[2] fundingRates;
        int128[2] amountsFundingPaidPerPosition;
    }

    function initialize(
        address _depositor,
        uint256 _depositAmount,
        int256 _initialFundingRate
    ) external returns (uint256 mintAmount);

    function deposit(address _depositor, uint256 _depositAmount) external returns (uint256 mintAmount);

    function withdraw(address _withdrawer, uint256 _withdrawnAmount) external returns (uint256 burnAmount);

    function addLiquidity(uint256 _amount) external;

    function updatePoolPosition(uint256 _productId, int128 _tradeAmount)
        external
        returns (
            uint256 tradePrice,
            int256,
            uint256 protocolFee
        );

    function completeHedgingProcedure(NettingLib.CompleteParams memory _completeParams) external;

    function updatePoolSnapshot() external;

    function executeFundingPayment() external;

    function getTradePriceInfo(int128[2] memory amountAssets) external view returns (TradePriceInfo memory);

    function getTradePrice(uint256 _productId, int128 _tradeAmount)
        external
        view
        returns (
            int256,
            int256,
            int256,
            int256,
            int256
        );

    function rebalance() external;

    function getTokenAmountForHedging() external view returns (NettingLib.CompleteParams memory completeParams);

    function getLPTokenPrice(int256 _deltaLiquidityAmount) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;
pragma abicoder v2;

import "../lib/TraderVaultLib.sol";

interface IPerpetualMarket {
    struct MultiTradeParams {
        uint256 vaultId;
        TradeParams[] trades;
        int256 marginAmount;
        uint256 deadline;
    }

    struct TradeParams {
        uint256 productId;
        uint256 subVaultIndex;
        int128 tradeAmount;
        uint256 limitPrice;
        bytes metadata;
    }

    struct VaultStatus {
        int256 positionValue;
        int256 minCollateral;
        int256[2][] positionValues;
        int256[2][] fundingPaid;
        TraderVaultLib.TraderVault rawVaultData;
    }

    struct TradeInfo {
        int256 tradePrice;
        int256 indexPrice;
        int256 fundingRate;
        int256 tradeFee;
        int256 protocolFee;
        int256 fundingFee;
        uint256 totalValue;
        uint256 totalFee;
    }

    function initialize(uint256 _depositAmount, int256 _initialFundingRate) external;

    function deposit(uint256 _depositAmount) external;

    function withdraw(uint128 _withdrawnAmount) external;

    function trade(MultiTradeParams memory _tradeParams) external;

    function liquidateByPool(uint256 _vaultId) external;

    function getTokenAmountForHedging()
        external
        view
        returns (
            bool,
            uint256,
            uint256
        );

    function execHedge() external returns (uint256 amountUsdc, uint256 amountUnderlying);

    function getLPTokenPrice(int256 _deltaLiquidityAmount) external view returns (uint256);

    function getTradePrice(uint256 _productId, int128 _tradeAmount)
        external
        view
        returns (TradeInfo memory tradePriceInfo);

    function getMinCollateralToAddPosition(uint256 _vaultId, int128[2] memory _tradeAmounts)
        external
        view
        returns (int256 minCollateral);

    function getTraderVault(uint256 _vaultId) external view returns (TraderVaultLib.TraderVault memory);

    function getVaultStatus(uint256 _vaultId) external view returns (VaultStatus memory);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/**
 * @title Base Liquidity Pool
 * @notice Base Liquidity Pool Contract
 */
abstract contract BaseLiquidityPool {
    using SafeERC20 for IERC20;

    address public immutable quoteAsset;
    address public immutable underlyingAsset;

    /**
     * @notice initialize liquidity pool
     */
    constructor(address _quoteAsset, address _underlyingAsset) {
        require(_quoteAsset != address(0));
        require(_underlyingAsset != address(0));

        quoteAsset = _quoteAsset;
        underlyingAsset = _underlyingAsset;
    }

    function sendLiquidity(address _recipient, uint256 _amount) internal {
        IERC20(quoteAsset).safeTransfer(_recipient, _amount);
    }

    function sendUndrlying(address _recipient, uint256 _amount) internal {
        IERC20(underlyingAsset).safeTransfer(_recipient, _amount);
    }
}

//SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/SafeCast.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "../interfaces/IPerpetualMarketCore.sol";
import "./Math.sol";
import "./EntryPriceMath.sol";

/**
 * @title TraderVaultLib
 * @notice TraderVaultLib has functions to calculate position value and minimum collateral for implementing cross margin wallet.
 *
 * Data Structure
 *  Vault
 *  - PositionUSDC
 *  - SubVault0(PositionPerpetuals, EntryPrices, entryFundingFee)
 *  - SubVault1(PositionPerpetuals, EntryPrices, entryFundingFee)
 *  - ...
 *
 *  PositionPerpetuals = [PositionSqueeth, PositionFuture]
 *  EntryPrices = [EntryPriceSqueeth, EntryPriceFuture]
 *  entryFundingFee = [entryFundingFeeqeeth, FundingFeeEntryValueFuture]
 *
 *
 * Error codes
 *  T0: PositionValue must be greater than MinCollateral
 *  T1: PositionValue must be less than MinCollateral
 *  T2: Vault is insolvent
 *  T3: subVaultIndex is too large
 *  T4: position must not be 0
 */
library TraderVaultLib {
    using SafeCast for int256;
    using SafeCast for uint256;
    using SafeCast for uint128;
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using SignedSafeMath for int128;

    uint256 private constant MAX_PRODUCT_ID = 2;

    /// @dev minimum margin is 500 USDC
    uint256 private constant MIN_MARGIN = 500 * 1e8;

    /// @dev risk parameter for MinCollateral calculation is 5.0%
    uint256 private constant RISK_PARAM_FOR_VAULT = 500;

    struct SubVault {
        int128[2] positionPerpetuals;
        uint128[2] entryPrices;
        int128[2] entryFundingFee;
    }

    struct TraderVault {
        int128 positionUsdc;
        SubVault[] subVaults;
        bool isInsolvent;
    }

    /**
     * @notice Gets amount of min collateral to add Squees/Future
     * @param _traderVault trader vault object
     * @param _tradeAmounts amount to trade
     * @param _tradePriceInfo trade price info
     * @return minCollateral and positionValue
     */
    function getMinCollateralToAddPosition(
        TraderVault memory _traderVault,
        int128[2] memory _tradeAmounts,
        IPerpetualMarketCore.TradePriceInfo memory _tradePriceInfo
    ) internal pure returns (int256 minCollateral) {
        int128[2] memory positionPerpetuals = getPositionPerpetuals(_traderVault);

        for (uint256 i = 0; i < MAX_PRODUCT_ID; i++) {
            positionPerpetuals[i] = positionPerpetuals[i].add(_tradeAmounts[i]).toInt128();
        }

        minCollateral = calculateMinCollateral(positionPerpetuals, _tradePriceInfo);
    }

    /**
     * @notice Updates USDC position
     * @param _traderVault trader vault object
     * @param _usdcPositionToAdd amount to add. if positive then increase amount, if negative then decrease amount.
     * @param _tradePriceInfo trade price info
     * @return finalUsdcPosition positive means amount of deposited margin
     * and negative means amount of withdrawn margin.
     */
    function updateUsdcPosition(
        TraderVault storage _traderVault,
        int256 _usdcPositionToAdd,
        IPerpetualMarketCore.TradePriceInfo memory _tradePriceInfo
    ) external returns (int256 finalUsdcPosition) {
        finalUsdcPosition = _usdcPositionToAdd;
        require(!_traderVault.isInsolvent, "T2");

        int256 positionValue = getPositionValue(_traderVault, _tradePriceInfo);
        int256 minCollateral = getMinCollateral(_traderVault, _tradePriceInfo);
        int256 maxWithdrawable = positionValue - minCollateral;

        // If trader wants to withdraw all USDC, set maxWithdrawable.
        if (_usdcPositionToAdd < -maxWithdrawable && maxWithdrawable > 0 && _usdcPositionToAdd < 0) {
            finalUsdcPosition = -maxWithdrawable;
        }

        _traderVault.positionUsdc = _traderVault.positionUsdc.add(finalUsdcPosition).toInt128();

        require(!checkVaultIsLiquidatable(_traderVault, _tradePriceInfo), "T0");
    }

    /**
     * @notice Gets total position of perpetuals in the vault
     * @param _traderVault trader vault object
     * @return positionPerpetuals are total amount of perpetual scaled by 1e8
     */
    function getPositionPerpetuals(TraderVault memory _traderVault)
        internal
        pure
        returns (int128[2] memory positionPerpetuals)
    {
        for (uint256 i = 0; i < MAX_PRODUCT_ID; i++) {
            positionPerpetuals[i] = getPositionPerpetual(_traderVault, i);
        }
    }

    /**
     * @notice Gets position of a perpetual in the vault
     * @param _traderVault trader vault object
     * @param _productId product id
     * @return positionPerpetual is amount of perpetual scaled by 1e8
     */
    function getPositionPerpetual(TraderVault memory _traderVault, uint256 _productId)
        internal
        pure
        returns (int128 positionPerpetual)
    {
        for (uint256 i = 0; i < _traderVault.subVaults.length; i++) {
            positionPerpetual = positionPerpetual
                .add(_traderVault.subVaults[i].positionPerpetuals[_productId])
                .toInt128();
        }
    }

    /**
     * @notice Updates positions in the vault
     * @param _traderVault trader vault object
     * @param _subVaultIndex index of sub-vault
     * @param _productId product id
     * @param _positionPerpetual amount of position to increase or decrease
     * @param _tradePrice trade price
     * @param _fundingFeePerPosition entry funding fee paid per position
     */
    function updateVault(
        TraderVault storage _traderVault,
        uint256 _subVaultIndex,
        uint256 _productId,
        int128 _positionPerpetual,
        uint256 _tradePrice,
        int256 _fundingFeePerPosition
    ) external returns (int256 deltaUsdcPosition) {
        require(!_traderVault.isInsolvent, "T2");
        require(_positionPerpetual != 0, "T4");

        if (_traderVault.subVaults.length == _subVaultIndex) {
            int128[2] memory positionPerpetuals;
            uint128[2] memory entryPrices;
            int128[2] memory entryFundingFee;

            _traderVault.subVaults.push(SubVault(positionPerpetuals, entryPrices, entryFundingFee));
        } else {
            require(_traderVault.subVaults.length > _subVaultIndex, "T3");
        }

        SubVault storage subVault = _traderVault.subVaults[_subVaultIndex];

        {
            (int256 newEntryPrice, int256 profitValue) = EntryPriceMath.updateEntryPrice(
                int256(subVault.entryPrices[_productId]),
                subVault.positionPerpetuals[_productId],
                int256(_tradePrice),
                _positionPerpetual
            );

            subVault.entryPrices[_productId] = newEntryPrice.toUint256().toUint128();
            deltaUsdcPosition = deltaUsdcPosition.add(profitValue);
        }

        {
            (int256 newEntryFundingFee, int256 profitValue) = EntryPriceMath.updateEntryPrice(
                int256(subVault.entryFundingFee[_productId]),
                subVault.positionPerpetuals[_productId],
                _fundingFeePerPosition,
                _positionPerpetual
            );

            subVault.entryFundingFee[_productId] = newEntryFundingFee.toInt128();
            deltaUsdcPosition = deltaUsdcPosition.sub(profitValue);
        }

        _traderVault.positionUsdc = _traderVault.positionUsdc.add(deltaUsdcPosition).toInt128();

        subVault.positionPerpetuals[_productId] = subVault
            .positionPerpetuals[_productId]
            .add(_positionPerpetual)
            .toInt128();
    }

    /**
     * @notice Checks the vault is liquidatable and return result
     * if PositionValue is less than MinCollateral return true
     * otherwise return false
     * @param _traderVault trader vault object
     * @return if true the vault is liquidatable, if false the vault is not liquidatable
     */
    function checkVaultIsLiquidatable(
        TraderVault memory _traderVault,
        IPerpetualMarketCore.TradePriceInfo memory _tradePriceInfo
    ) internal pure returns (bool) {
        int256 positionValue = getPositionValue(_traderVault, _tradePriceInfo);

        return positionValue < getMinCollateral(_traderVault, _tradePriceInfo);
    }

    /**
     * @notice Set insolvency flag if needed
     * If PositionValue is negative, set insolvency flag.
     * @param _traderVault trader vault object
     */
    function setInsolvencyFlagIfNeeded(TraderVault storage _traderVault) external {
        // Confirm that there are no positions
        for (uint256 i = 0; i < _traderVault.subVaults.length; i++) {
            for (uint256 j = 0; j < MAX_PRODUCT_ID; j++) {
                require(_traderVault.subVaults[i].positionPerpetuals[j] == 0);
            }
        }

        // If there are no positions, PositionUSDC is equal to PositionValue.
        if (_traderVault.positionUsdc < 0) {
            _traderVault.isInsolvent = true;
        }
    }

    /**
     * @notice Decreases liquidation reward from usdc position
     * @param _traderVault trader vault object
     * @param _minCollateral min collateral
     * @param _liquidationFee liquidation fee rate
     */
    function decreaseLiquidationReward(
        TraderVault storage _traderVault,
        int256 _minCollateral,
        int256 _liquidationFee
    ) external returns (uint256) {
        if (_traderVault.positionUsdc <= 0) {
            return 0;
        }

        int256 reward = _minCollateral.mul(_liquidationFee).div(1e4);

        reward = Math.min(reward, _traderVault.positionUsdc);

        // reduce margin
        // sub is safe because we know reward is less than positionUsdc
        _traderVault.positionUsdc -= reward.toInt128();

        return reward.toUint256();
    }

    /**
     * @notice Gets min collateral of the vault
     * @param _traderVault trader vault object
     * @param _tradePriceInfo trade price info
     * @return MinCollateral scaled by 1e8
     */
    function getMinCollateral(
        TraderVault memory _traderVault,
        IPerpetualMarketCore.TradePriceInfo memory _tradePriceInfo
    ) internal pure returns (int256) {
        int128[2] memory assetAmounts = getPositionPerpetuals(_traderVault);

        return calculateMinCollateral(assetAmounts, _tradePriceInfo);
    }

    /**
     * @notice Calculates min collateral
     * MinCollateral = alpha*S*(|2*S*(1+fundingSqueeth)*PositionSqueeth + (1+fundingFuture)*PositionFuture| + 2*alpha*S*(1+fundingSqueeth)*|PositionSqueeth|)
     * where alpha is 0.05
     * @param positionPerpetuals amount of perpetual positions
     * @param _tradePriceInfo trade price info
     * @return MinCollateral scaled by 1e8
     */
    function calculateMinCollateral(
        int128[2] memory positionPerpetuals,
        IPerpetualMarketCore.TradePriceInfo memory _tradePriceInfo
    ) internal pure returns (int256) {
        uint256 maxDelta = Math.abs(
            (
                int256(_tradePriceInfo.spotPrice)
                    .mul(_tradePriceInfo.fundingRates[1].add(1e8))
                    .mul(positionPerpetuals[1])
                    .mul(2)
                    .div(1e20)
            ).add(positionPerpetuals[0].mul(_tradePriceInfo.fundingRates[0].add(1e8)).div(1e8))
        );

        maxDelta = maxDelta.add(
            Math.abs(
                int256(RISK_PARAM_FOR_VAULT)
                    .mul(int256(_tradePriceInfo.spotPrice))
                    .mul(_tradePriceInfo.fundingRates[1].add(1e8))
                    .mul(2)
                    .mul(positionPerpetuals[1])
                    .div(1e24)
            )
        );

        uint256 minCollateral = (RISK_PARAM_FOR_VAULT.mul(_tradePriceInfo.spotPrice).mul(maxDelta)) / 1e12;

        if ((positionPerpetuals[0] != 0 || positionPerpetuals[1] != 0) && minCollateral < MIN_MARGIN) {
            minCollateral = MIN_MARGIN;
        }

        return minCollateral.toInt256();
    }

    /**
     * @notice Gets position value in the vault
     * PositionValue = USDC + Σ(ValueOfSubVault_i)
     * @param _traderVault trader vault object
     * @param _tradePriceInfo trade price info
     * @return PositionValue scaled by 1e8
     */
    function getPositionValue(
        TraderVault memory _traderVault,
        IPerpetualMarketCore.TradePriceInfo memory _tradePriceInfo
    ) internal pure returns (int256) {
        int256 value = _traderVault.positionUsdc;

        for (uint256 i = 0; i < _traderVault.subVaults.length; i++) {
            value = value.add(getSubVaultPositionValue(_traderVault.subVaults[i], _tradePriceInfo));
        }

        return value;
    }

    /**
     * @notice Gets position value in the sub-vault
     * ValueOfSubVault = TotalPerpetualValueOfSubVault + TotalFundingFeePaidOfSubVault
     * @param _subVault sub-vault object
     * @param _tradePriceInfo trade price info
     * @return ValueOfSubVault scaled by 1e8
     */
    function getSubVaultPositionValue(
        SubVault memory _subVault,
        IPerpetualMarketCore.TradePriceInfo memory _tradePriceInfo
    ) internal pure returns (int256) {
        return
            getTotalPerpetualValueOfSubVault(_subVault, _tradePriceInfo).add(
                getTotalFundingFeePaidOfSubVault(_subVault, _tradePriceInfo.amountsFundingPaidPerPosition)
            );
    }

    /**
     * @notice Gets total perpetual value in the sub-vault
     * TotalPerpetualValueOfSubVault = Σ(PerpetualValueOfSubVault_i)
     * @param _subVault sub-vault object
     * @param _tradePriceInfo trade price info
     * @return TotalPerpetualValueOfSubVault scaled by 1e8
     */
    function getTotalPerpetualValueOfSubVault(
        SubVault memory _subVault,
        IPerpetualMarketCore.TradePriceInfo memory _tradePriceInfo
    ) internal pure returns (int256) {
        int256 pnl;

        for (uint256 i = 0; i < MAX_PRODUCT_ID; i++) {
            pnl = pnl.add(getPerpetualValueOfSubVault(_subVault, i, _tradePriceInfo));
        }

        return pnl;
    }

    /**
     * @notice Gets perpetual value in the sub-vault
     * PerpetualValueOfSubVault_i = (TradePrice_i - EntryPrice_i)*Position_i
     * @param _subVault sub-vault object
     * @param _productId product id
     * @param _tradePriceInfo trade price info
     * @return PerpetualValueOfSubVault_i scaled by 1e8
     */
    function getPerpetualValueOfSubVault(
        SubVault memory _subVault,
        uint256 _productId,
        IPerpetualMarketCore.TradePriceInfo memory _tradePriceInfo
    ) internal pure returns (int256) {
        int256 pnl = _tradePriceInfo.tradePrices[_productId].sub(_subVault.entryPrices[_productId].toInt256()).mul(
            _subVault.positionPerpetuals[_productId]
        );

        return pnl / 1e8;
    }

    /**
     * @notice Gets total funding fee in the sub-vault
     * TotalFundingFeePaidOfSubVault = Σ(FundingFeePaidOfSubVault_i)
     * @param _subVault sub-vault object
     * @param _amountsFundingPaidPerPosition the cumulative funding fee paid by long per position
     * @return TotalFundingFeePaidOfSubVault scaled by 1e8
     */
    function getTotalFundingFeePaidOfSubVault(
        SubVault memory _subVault,
        int128[2] memory _amountsFundingPaidPerPosition
    ) internal pure returns (int256) {
        int256 fundingFee;

        for (uint256 i = 0; i < MAX_PRODUCT_ID; i++) {
            fundingFee = fundingFee.add(getFundingFeePaidOfSubVault(_subVault, i, _amountsFundingPaidPerPosition));
        }

        return fundingFee;
    }

    /**
     * @notice Gets funding fee in the sub-vault
     * FundingFeePaidOfSubVault_i = Position_i*(EntryFundingFee_i - FundingFeeGlobal_i)
     * @param _subVault sub-vault object
     * @param _productId product id
     * @param _amountsFundingPaidPerPosition cumulative funding fee paid by long per position.
     * @return FundingFeePaidOfSubVault_i scaled by 1e8
     */
    function getFundingFeePaidOfSubVault(
        SubVault memory _subVault,
        uint256 _productId,
        int128[2] memory _amountsFundingPaidPerPosition
    ) internal pure returns (int256) {
        int256 fundingFee = _subVault.entryFundingFee[_productId].sub(_amountsFundingPaidPerPosition[_productId]).mul(
            _subVault.positionPerpetuals[_productId]
        );

        return fundingFee / 1e8;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IVaultNFT is IERC721 {
    function mintNFT(address _recipient) external returns (uint256 tokenId);
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

//SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;

import "@openzeppelin/contracts/utils/SafeCast.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "./Math.sol";

/**
 * @title NettingLib
 * Error codes
 * N0: Unknown product id
 * N1: Total delta must be greater than 0
 * N2: No enough USDC
 */
library NettingLib {
    using SafeCast for int256;
    using SafeCast for uint128;
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SafeMath for uint128;
    using SignedSafeMath for int256;
    using SignedSafeMath for int128;

    struct AddMarginParams {
        int256 delta0;
        int256 delta1;
        int256 gamma1;
        int256 spotPrice;
        int256 poolMarginRiskParam;
    }

    struct CompleteParams {
        uint256 amountUsdc;
        uint256 amountUnderlying;
        int256[2] amountsRequiredUnderlying;
        bool isLong;
    }

    struct Info {
        uint128 amountAaveCollateral;
        uint128[2] amountsUsdc;
        int128[2] amountsUnderlying;
    }

    /**
     * @notice Adds required margin for delta hedging
     */
    function addMargin(
        Info storage _info,
        uint256 _productId,
        AddMarginParams memory _params
    ) internal returns (int256 requiredMargin, int256 hedgePositionValue) {
        int256 totalRequiredMargin = getRequiredMargin(_productId, _params);

        hedgePositionValue = getHedgePositionValue(_info, _params.spotPrice, _productId);

        requiredMargin = totalRequiredMargin.sub(hedgePositionValue);

        if (_info.amountsUsdc[_productId].toInt256().add(requiredMargin) < 0) {
            requiredMargin = -_info.amountsUsdc[_productId].toInt256();
        }

        _info.amountsUsdc[_productId] = Math.addDelta(_info.amountsUsdc[_productId], requiredMargin).toUint128();
    }

    function getRequiredTokenAmountsForHedge(
        int128[2] memory _amountsUnderlying,
        int256[2] memory _deltas,
        int256 _spotPrice
    ) internal pure returns (CompleteParams memory completeParams) {
        completeParams.amountsRequiredUnderlying[0] = -_amountsUnderlying[0] - _deltas[0];
        completeParams.amountsRequiredUnderlying[1] = -_amountsUnderlying[1] - _deltas[1];

        int256 totalUnderlyingPosition = getTotalUnderlyingPosition(_amountsUnderlying);

        // 1. Calculate required amount of underlying token
        int256 requiredUnderlyingAmount;
        {
            // required amount is -(net delta)
            requiredUnderlyingAmount = -_deltas[0].add(_deltas[1]).add(totalUnderlyingPosition);

            if (_deltas[0].add(_deltas[1]) > 0) {
                // if pool delta is positive
                requiredUnderlyingAmount = -totalUnderlyingPosition;

                completeParams.amountsRequiredUnderlying[0] = -_amountsUnderlying[0] + _deltas[1];
            }

            completeParams.isLong = requiredUnderlyingAmount > 0;
        }

        // 2. Calculate USDC and ETH amounts.
        completeParams.amountUnderlying = Math.abs(requiredUnderlyingAmount);
        completeParams.amountUsdc = (Math.abs(requiredUnderlyingAmount).mul(uint256(_spotPrice))) / 1e8;

        return completeParams;
    }

    /**
     * @notice Completes delta hedging procedure
     * Calculate holding amount of Underlying and USDC after a hedge.
     */
    function complete(Info storage _info, CompleteParams memory _params) internal {
        uint256 totalUnderlying = Math.abs(_params.amountsRequiredUnderlying[0]).add(
            Math.abs(_params.amountsRequiredUnderlying[1])
        );

        require(totalUnderlying > 0, "N1");

        for (uint256 i = 0; i < 2; i++) {
            _info.amountsUnderlying[i] = _info
                .amountsUnderlying[i]
                .add(_params.amountsRequiredUnderlying[i])
                .toInt128();

            {
                uint256 deltaUsdcAmount = (_params.amountUsdc.mul(Math.abs(_params.amountsRequiredUnderlying[i]))).div(
                    totalUnderlying
                );

                if (_params.isLong) {
                    require(_info.amountsUsdc[i] >= deltaUsdcAmount, "N2");
                    _info.amountsUsdc[i] = _info.amountsUsdc[i].sub(deltaUsdcAmount).toUint128();
                } else {
                    _info.amountsUsdc[i] = _info.amountsUsdc[i].add(deltaUsdcAmount).toUint128();
                }
            }
        }
    }

    /**
     * @notice Gets required margin
     * @param _productId Id of product to get required margin
     * @param _params parameters to calculate required margin
     * @return RequiredMargin scaled by 1e8
     */
    function getRequiredMargin(uint256 _productId, AddMarginParams memory _params) internal pure returns (int256) {
        int256 weightedDelta = calculateWeightedDelta(_productId, _params.delta0, _params.delta1);

        if (_productId == 0) {
            return getRequiredMarginOfFuture(_params, weightedDelta);
        } else if (_productId == 1) {
            return getRequiredMarginOfSqueeth(_params, weightedDelta);
        } else {
            revert("N0");
        }
    }

    /**
     * @notice Gets required margin for future
     * RequiredMargin_{future} = (1+α)*S*|WeightedDelta|
     * @return RequiredMargin scaled by 1e8
     */
    function getRequiredMarginOfFuture(AddMarginParams memory _params, int256 _weightedDelta)
        internal
        pure
        returns (int256)
    {
        int256 requiredMargin = (_params.spotPrice.mul(Math.abs(_weightedDelta).toInt256())) / 1e8;
        return ((1e4 + _params.poolMarginRiskParam).mul(requiredMargin)) / 1e4;
    }

    /**
     * @notice Gets required margin for squeeth
     * RequiredMargin_{squeeth}
     * = max((1-α) * S * |WeightDelta_{sqeeth}-α * S * gamma|, (1+α) * S * |WeightDelta_{sqeeth}+α * S * gamma|)
     * @return RequiredMargin scaled by 1e8
     */
    function getRequiredMarginOfSqueeth(AddMarginParams memory _params, int256 _weightedDelta)
        internal
        pure
        returns (int256)
    {
        int256 deltaFromGamma = (_params.poolMarginRiskParam.mul(_params.spotPrice).mul(_params.gamma1)) / 1e12;

        return
            Math.max(
                (
                    (1e4 - _params.poolMarginRiskParam).mul(_params.spotPrice).mul(
                        Math.abs(_weightedDelta.sub(deltaFromGamma)).toInt256()
                    )
                ) / 1e12,
                (
                    (1e4 + _params.poolMarginRiskParam).mul(_params.spotPrice).mul(
                        Math.abs(_weightedDelta.add(deltaFromGamma)).toInt256()
                    )
                ) / 1e12
            );
    }

    /**
     * @notice Gets notional value of hedge positions
     * HedgePositionValue_i = AmountsUsdc_i+AmountsUnderlying_i*S
     * @return HedgePositionValue scaled by 1e8
     */
    function getHedgePositionValue(
        Info memory _info,
        int256 _spot,
        uint256 _productId
    ) internal pure returns (int256) {
        int256 hedgeNotional = _spot.mul(_info.amountsUnderlying[_productId]) / 1e8;

        return _info.amountsUsdc[_productId].toInt256().add(hedgeNotional);
    }

    /**
     * @notice Gets total underlying position
     * TotalUnderlyingPosition = ΣAmountsUnderlying_i
     */
    function getTotalUnderlyingPosition(int128[2] memory _amountsUnderlying)
        internal
        pure
        returns (int256 underlyingPosition)
    {
        for (uint256 i = 0; i < 2; i++) {
            underlyingPosition = underlyingPosition.add(_amountsUnderlying[i]);
        }

        return underlyingPosition;
    }

    /**
     * @notice Calculates weighted delta
     * WeightedDelta = delta_i * (Σdelta_i) / (Σ|delta_i|)
     * @return weighted delta scaled by 1e8
     */
    function calculateWeightedDelta(
        uint256 _productId,
        int256 _delta0,
        int256 _delta1
    ) internal pure returns (int256) {
        int256 netDelta = _delta0.add(_delta1);
        int256 totalDelta = (Math.abs(_delta0).add(Math.abs(_delta1))).toInt256();

        require(totalDelta >= 0, "N1");

        if (totalDelta == 0) {
            return 0;
        }

        if (_productId == 0) {
            return (Math.abs(_delta0).toInt256().mul(netDelta)).div(totalDelta);
        } else if (_productId == 1) {
            return (Math.abs(_delta1).toInt256().mul(netDelta)).div(totalDelta);
        } else {
            revert("N0");
        }
    }
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

//SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;

import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * Error codes
 * M0: y is too small
 * M1: y is too large
 * M2: possible overflow
 * M3: input should be positive number
 * M4: cannot handle exponents greater than 100
 */
library Math {
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    /// @dev Min exp
    int256 private constant MIN_EXP = -63 * 1e8;
    /// @dev Max exp
    uint256 private constant MAX_EXP = 100 * 1e8;
    /// @dev ln(2) scaled by 1e8
    uint256 private constant LN_2_E8 = 69314718;

    /**
     * @notice Return the addition of unsigned integer and sigined integer.
     * when y is negative reverting on negative result and when y is positive reverting on overflow.
     */
    function addDelta(uint256 x, int256 y) internal pure returns (uint256 z) {
        if (y < 0) {
            require((z = x - uint256(-y)) < x, "M0");
        } else {
            require((z = x + uint256(y)) >= x, "M1");
        }
    }

    function abs(int256 x) internal pure returns (uint256) {
        return uint256(x >= 0 ? x : -x);
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? b : a;
    }

    /**
     * @notice Returns scaled number.
     * Reverts if the scaler is greater than 50.
     */
    function scale(
        uint256 _a,
        uint256 _from,
        uint256 _to
    ) internal pure returns (uint256) {
        if (_from > _to) {
            require(_from - _to < 70, "M2");
            // (_from - _to) is safe because _from > _to.
            // 10**(_from - _to) is safe because it's less than 10**70.
            return _a.div(10**(_from - _to));
        } else if (_from < _to) {
            require(_to - _from < 70, "M2");
            // (_to - _from) is safe because _to > _from.
            // 10**(_to - _from) is safe because it's less than 10**70.
            return _a.mul(10**(_to - _from));
        } else {
            return _a;
        }
    }

    /**
     * @dev Calculates an approximate value of the logarithm of input value by Halley's method.
     */
    function log(uint256 x) internal pure returns (int256) {
        int256 res;
        int256 next;

        for (uint256 i = 0; i < 8; i++) {
            int256 e = int256(exp(res));
            next = res.add((int256(x).sub(e).mul(2)).mul(1e8).div(int256(x).add(e)));
            if (next == res) {
                break;
            }
            res = next;
        }

        return res;
    }

    /**
     * @dev Returns the exponent of the value using Taylor expansion with support for negative numbers.
     */
    function exp(int256 x) internal pure returns (uint256) {
        if (0 <= x) {
            return exp(uint256(x));
        } else if (x < MIN_EXP) {
            // return 0 because `exp(-63) < 1e-27`
            return 0;
        } else {
            return uint256(1e8).mul(1e8).div(exp(uint256(-x)));
        }
    }

    /**
     * @dev Calculates the exponent of the value using Taylor expansion.
     */
    function exp(uint256 x) internal pure returns (uint256) {
        if (x == 0) {
            return 1e8;
        }
        require(x <= MAX_EXP, "M4");

        uint256 k = floor(x.mul(1e8).div(LN_2_E8)) / 1e8;
        uint256 p = 2**k;
        uint256 r = x.sub(k.mul(LN_2_E8));

        uint256 multiplier = 1e8;

        uint256 lastMultiplier;
        for (uint256 i = 16; i > 0; i--) {
            multiplier = multiplier.mul(r / i).div(1e8).add(1e8);
            if (multiplier == lastMultiplier) {
                break;
            }
            lastMultiplier = multiplier;
        }

        return p.mul(multiplier);
    }

    /**
     * @dev Returns the floor of a 1e8
     */
    function floor(uint256 x) internal pure returns (uint256) {
        return x - (x % 1e8);
    }
}

//SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;

import "@openzeppelin/contracts/utils/SafeCast.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "./Math.sol";

/**
 * @title EntryPriceMath
 * @notice Library contract which has functions to calculate new entry price and profit
 * from previous entry price and trade price for implementing margin wallet.
 */
library EntryPriceMath {
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    /**
     * @notice Calculates new entry price and return profit if position is closed
     *
     * Calculation Patterns
     *  |Position|PositionTrade|NewPosition|Pattern|
     *  |       +|            +|          +|      A|
     *  |       +|            -|          +|      B|
     *  |       +|            -|          -|      C|
     *  |       -|            -|          -|      A|
     *  |       -|            +|          -|      B|
     *  |       -|            +|          +|      C|
     *
     * Calculations
     *  Pattern A (open positions)
     *   NewEntryPrice = (EntryPrice * |Position| + TradePrce * |PositionTrade|) / (Position + PositionTrade)
     *
     *  Pattern B (close positions)
     *   NewEntryPrice = EntryPrice
     *   ProfitValue = -PositionTrade * (TradePrice - EntryPrice)
     *
     *  Pattern C (close all positions & open new)
     *   NewEntryPrice = TradePrice
     *   ProfitValue = Position * (TradePrice - EntryPrice)
     *
     * @param _entryPrice previous entry price
     * @param _position current position
     * @param _tradePrice trade price
     * @param _positionTrade position to trade
     * @return newEntryPrice new entry price
     * @return profitValue notional profit value when positions are closed
     */
    function updateEntryPrice(
        int256 _entryPrice,
        int256 _position,
        int256 _tradePrice,
        int256 _positionTrade
    ) internal pure returns (int256 newEntryPrice, int256 profitValue) {
        int256 newPosition = _position.add(_positionTrade);
        if (_position == 0 || (_position > 0 && _positionTrade > 0) || (_position < 0 && _positionTrade < 0)) {
            newEntryPrice = (
                _entryPrice.mul(int256(Math.abs(_position))).add(_tradePrice.mul(int256(Math.abs(_positionTrade))))
            ).div(int256(Math.abs(_position.add(_positionTrade))));
        } else if (
            (_position > 0 && _positionTrade < 0 && newPosition > 0) ||
            (_position < 0 && _positionTrade > 0 && newPosition < 0)
        ) {
            newEntryPrice = _entryPrice;
            profitValue = (-_positionTrade).mul(_tradePrice.sub(_entryPrice)) / 1e8;
        } else {
            if (newPosition != 0) {
                newEntryPrice = _tradePrice;
            }

            profitValue = _position.mul(_tradePrice.sub(_entryPrice)) / 1e8;
        }
    }
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