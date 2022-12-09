// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;
pragma experimental ABIEncoderV2;

// ====================================================================
// ====================== Stabilizer.sol ==============================
// ====================================================================

import "./ISweep.sol";
import "./ERC20.sol";
import "./Math.sol";
import "./PRBMathSD59x18.sol";
import "./TransferHelper.sol";
import "./IAsset.sol";
import "./IBalancer.sol";
import "./UniswapAMM.sol";

/**
 * @title Stabilizer
 * @author MAXOS Team - https://maxos.finance/
 * @dev Implementation:
 * Facilitates the investment and paybacks of off-chain & on-chain strategies
 * Allows to deposit and withdraw usdx
 * Allows to take debt by minting sweep and repaying by burning sweep
 * Allows to buy and sell sweep in an AMM
 * Repayments made by burning sweep
 * EquityRatio = Junior / (Junior + Senior)
 * Requires that the EquityRatio > MinimumEquityRatio when:
 * minting => increase of the senior tranche
 * withdrawing => decrease of the junior tranche
 */
contract Stabilizer {
    using PRBMathSD59x18 for int256;

    uint256 public sweep_borrowed;
    uint256 public minimum_equity_ratio;

    // Investment Strategy
    IAsset public asset;
    UniswapAMM public amm;

    address public banker;
    address public admin;
    address public settings_manager;
    address public balancer;

    // Spread Variables
    uint256 public spread_ratio; // 100 is 1%
    uint256 public spread_payment_time;
    address public treasury;

    // Tokens
    ISweep public sweep;
    ERC20 public usdx;

    // Control
    bool public frozen;

    // Constants for various precisions
    uint256 private constant TIME_ONE_YEAR = 365 * 24 * 60 * 60; // seconds of Year
    uint256 private constant SPREAD_PRECISION = 1e5;

    constructor(
        address _admin_address,
        address _sweep_address,
        address _usdx_address,
        uint256 _min_equity_ratio,
        uint256 _spread_ratio,
        address _treasury_address,
        address _balancer_address,
        address _amm_address
    ) {
        admin = _admin_address;
        banker = _admin_address;
        settings_manager = _admin_address;
        treasury = _treasury_address;
        balancer = _balancer_address;
        sweep = ISweep(_sweep_address);
        usdx = ERC20(_usdx_address);
        amm = UniswapAMM(_amm_address);
        minimum_equity_ratio = _min_equity_ratio;
        spread_ratio = _spread_ratio;
        frozen = false;
    }

    // EVENTS ====================================================================

    event Minted(uint256 sweep_amount);
    event Invested(address token, uint256 amount);
    event Paidback(uint256 amount);
    event Burnt(uint256 sweep_amount);
    event Withdrawn(address token, uint256 amount);
    event Collected(address owner);
    event PaySpread(uint256 sweep_amount);
    event Liquidate(address user);
    event Bought(uint256 sweep_amount);
    event Sold(uint256 sweep_amount);
    event FrozenChanged(bool frozen);
    event AdminChanged(address admin);
    event BankerChanged(address banker);
    event BalancerChanged(address balancer);
    event SettingsManagerChanged(address settings_manager);
    event SpreadRatioChanged(uint256 spread_ratio);
    event UsdxChanged(address usdx_address);
    event TreasuryChanged(address treasury);
    event AssetChanged(address asset);
    event MinimumEquityRatioChanged(uint256 minimum_equity_ratio);

    // MODIFIERS =================================================================

    modifier notFrozen() {
        require(!frozen, "Frozen");
        _;
    }

    modifier onlyBanker() {
        require(msg.sender == banker, "Not a Banker");
        _;
    }

    modifier onlyBankerOrBalancer() {
        require(msg.sender == banker || msg.sender == balancer, "Not a Banker or Balancer");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not a Admin");
        _;
    }

    modifier onlySettingsManager() {
        require(msg.sender == settings_manager, "Not a Setting Manager");
        _;
    }

    // ADMIN FUNCTIONS ===========================================================

    /**
     * @notice Set Admin - a MAXOS protocol representative.
     * @param _admin.
     */
    function setAdmin(address _admin) external onlyAdmin {
        admin = _admin;
        emit AdminChanged(_admin);
    }

    /**
     * @notice Set Banker - who manages the investment actions.
     * @param _banker.
     */
    function setBanker(address _banker) external onlyAdmin {
        banker = _banker;
        settings_manager = _banker;
        emit BankerChanged(_banker);
    }

    /**
     * @notice Set Spread Ratio that will be used to calculate the spread that we owe to the protocol.
     * @param _ratio spread ratio.
     */
    function setSpreadRatio(uint256 _ratio) public onlyAdmin {
        spread_ratio = _ratio;
        emit SpreadRatioChanged(_ratio);
    }

    /**
     * @notice Frozen - stops investment actions.
     * @param _frozen.
     */
    function setFrozen(bool _frozen) external onlyAdmin {
        frozen = _frozen;
        emit FrozenChanged(_frozen);
    }

    /**
     * @notice Set Balancer - a Balancer contract address to repay debt.
     * @param _balancer.
     */
    function setBalancer(address _balancer) external onlyAdmin {
        balancer = _balancer;
        emit BalancerChanged(_balancer);
    }

    /**
    * @notice set Treasury.
    * @param _treasury.
    */
    function setTreasury(address _treasury) external onlyAdmin {
        treasury = _treasury;
        emit TreasuryChanged(_treasury);
    }

    /**
    * @notice set Usdx.
    * @param _usdx_address.
    */
    function setUSDX(address _usdx_address) external onlyAdmin {
        usdx = ERC20(_usdx_address);
        emit UsdxChanged(_usdx_address);
    }

    // SETTINGS FUNCTIONS ====================================================

    /**
     * @notice Set Asset to invest. This can be an On-Chain or Off-Chain asset.
     * @param _asset Address
     */
    function setAsset(address _asset) public onlySettingsManager {
        asset = IAsset(_asset);

        emit AssetChanged(_asset);
    }

    /**
     * @notice Set Minimum Equity Ratio that defines the junior tranche size.
     * @param _value New minimum equity ratio.
     * @dev this value is a percentage with 6 decimals.
     */
    function setMinimumEquityRatio(uint256 _value) public onlySettingsManager {
        minimum_equity_ratio = _value;
        emit MinimumEquityRatioChanged(_value);
    }

    /**
     * @notice set Settings Manager to control the global configuration.
     * @dev after delegating the settings management to the admin
     * the protocol will evaluate adding the stabilizer to the minter list.
     */
    function setSettingsManager() public onlySettingsManager {
        settings_manager = settings_manager == banker ? admin : banker;
        emit SettingsManagerChanged(settings_manager);
    }

    // BANKER FUNCTIONS ==========================================================

    /**
     * @notice Mint Sweep
     * Asks the stabilizer to mint a certain amount of sweep token.
     * @param _sweep_amount.
     * @dev Increases the sweep_borrowed (senior tranche).
     */
    function mint(uint256 _sweep_amount) public onlyBanker notFrozen {
        require(_sweep_amount > 0, "Over Zero");
        require(sweep.isValidMinter(address(this)), "Not a Minter");
        uint256 sweep_available = sweep.minters(address(this)).max_mint_amount - sweep_borrowed;
        require(sweep_available >= _sweep_amount, "Not Enough");
        uint256 current_equity_ratio = calculateEquityRatio(_sweep_amount, 0);
        require(current_equity_ratio >= minimum_equity_ratio, "Equity Ratio Excessed");

        _paySpread();
        sweep.minter_mint(address(this), _sweep_amount);
        sweep_borrowed += _sweep_amount;

        emit Minted(_sweep_amount);
    }

    /**
     * @notice Burn
     * Burns the sweep_amount to reduce the debt (senior tranche).
     * @param _sweep_amount Amount to be burnt by Sweep.
     * @dev Decreases the sweep borrowed.
     */
    function burn(uint256 _sweep_amount) public onlyBankerOrBalancer {
        require(_sweep_amount > 0, "Over Zero");
        require(_sweep_amount <= sweep.balanceOf(address(this)), "Not Enough");
        _burn(_sweep_amount);
    }

    /**
     * @notice Repay debt
     * takes sweep from the sender and burns it
     * @param _sweep_amount Amount to be burnt by Sweep.
     */
    function repay(uint256 _sweep_amount) public {
        require(_sweep_amount > 0, "Over Zero");
        TransferHelper.safeTransferFrom(address(sweep), msg.sender, address(this), _sweep_amount);
        _burn(_sweep_amount);
    }

    /**
     * @notice Invest USDX
     * Sends balances from the STABILIZER to the ASSET address.
     * @param _token token address to deposit. USDX, SWEEP ...
     * @param _amount Amount to be invested.
     */
    function invest(address _token, uint256 _amount) external onlyBanker notFrozen {
        require(_amount > 0, "Over Zero");
        require(_token == address(sweep) || _token == address(usdx), "Invalid Token");
        require(_amount <= ERC20(_token).balanceOf(address(this)), "Not Enough");
        TransferHelper.safeApprove(address(_token), address(asset), _amount);
        asset.deposit(_token, _amount);

        emit Invested(_token, _amount);
    }

    /**
     * @notice Payback USDX
     * Sends balance from the ASSET to the STABILIZER.
     * @param _usdx_amount Amount to be repaid.
     */
    function payback(uint256 _usdx_amount) external onlyBanker {
        require(_usdx_amount > 0, "Over Zero");
        asset.withdraw(_usdx_amount);

        emit Paidback(_usdx_amount);
    }

    /**
     * @notice Collect Rewards
     * Takes the rewards generated by the asset (On-Chain only).
     * @dev Rewards are sent to the banker.
     */
    function collect() external onlyBanker {
        asset.withdrawRewards(banker);

        emit Collected(banker);
    }

    /**
     * @notice Pay the spread to the treasury
     */
    function paySpread() external onlyBanker {
        _paySpread();
    }

    /**
     * @notice Liquidates a stabilizer
     * takes ownership of the stabilizer by repaying its debt
     */
    function liquidate(uint256 sweep_amount) public {
        require(isDefaulted(), "Not Defaulted");
        repay(sweep_amount);
        require(sweep_borrowed == 0, "Debt not yet Paid");
        banker = msg.sender;

        emit Liquidate(msg.sender);
    }

    function _burn(uint256 _sweep_amount) internal {
        uint256 spread_amount = getSpreadValue();
        uint256 sweep_amount = _sweep_amount - spread_amount;
        if (sweep_borrowed < sweep_amount) {
            sweep_amount = sweep_borrowed;
            sweep_borrowed = 0;
        } else {
            sweep_borrowed -= sweep_amount;
        }

        _paySpread();
        TransferHelper.safeApprove(address(sweep), address(this), sweep_amount);
        sweep.minter_burn_from(sweep_amount);

        emit Burnt(sweep_amount);
    }

    function _paySpread() internal {
        uint256 spread_amount = getSpreadValue();
        require(spread_amount <= sweep.balanceOf(address(this)), "Spread Not Enough");
        spread_payment_time = block.timestamp;
        if (spread_amount > 0) {
            TransferHelper.safeTransfer(address(sweep), treasury, spread_amount);
        }

        emit PaySpread(spread_amount);
    }

    /**
    * @notice Buy
    * Buys sweep_amount from the stabilizer's balance to the AMM (swaps USDX to SWEEP).
    * @param _usdx_amount Amount to be changed in the AMM.
    * @dev Increases the sweep balance and decrease usdx balance.
    */
    function buy(uint256 _usdx_amount) public onlyBanker notFrozen returns(uint256 sweep_amount) {
        require(_usdx_amount > 0, "Over Zero");
        require(_usdx_amount <= usdx.balanceOf(address(this)), "Not Enough");
        TransferHelper.safeApprove(address(usdx), address(amm), _usdx_amount);
        sweep_amount = amm.buySweep(address(usdx), _usdx_amount);

        emit Bought(sweep_amount);
    }

    /**
    * @notice Sell Sweep
    * Sells sweep_amount from the stabilizer's balance to the AMM (swaps SWEEP to USDX).
    * @param _sweep_amount.
    * @dev Decreases the sweep balance and increase usdx balance
    */
    function sell(uint256 _sweep_amount) public onlyBanker notFrozen returns(uint256 usdx_amount) {
        require(_sweep_amount > 0, "Over Zero");
        require(_sweep_amount <= sweep.balanceOf(address(this)), "Not Enough");
        TransferHelper.safeApprove(address(sweep), address(amm), _sweep_amount);
        usdx_amount = amm.sellSweep(address(usdx), _sweep_amount);

        emit Sold(_sweep_amount);
    }

    /**
     * @notice Withdraw SWEEP
     * Takes out sweep balance if the new equity ratio is higher than the minimum equity ratio.
     * @param token.
     * @dev Decreases the sweep balance.
     */
    function withdraw(address token, uint256 amount) public onlyBanker notFrozen {
        require(amount > 0, "Over Zero");
        require(token == address(sweep) || token == address(usdx), "Invalid Token");
        require(amount <= ERC20(token).balanceOf(address(this)), "Not Enough");

        if(sweep_borrowed > 0) {
            if(token == address(sweep)) amount = SWEEPinUSDX(amount);
            uint256 current_equity_ratio = calculateEquityRatio(0, amount);
            require(current_equity_ratio >= minimum_equity_ratio, "Equity Ratio Excessed");
        }

        TransferHelper.safeTransfer(token, msg.sender, amount);

        emit Withdrawn(token, amount);
    }

    // GETTERS ===================================================================

    /**
     * @notice Calculate Equity Ratio
     * Calculated the equity ratio based on the internal storage.
     * @param sweep_delta Variation of SWEEP to recalculate the new equity ratio.
     * @param usdx_delta Variation of USDX to recalculate the new equity ratio.
     * @return the new equity ratio used to control the Mint and Withdraw functions.
     * @dev Current Equity Ratio percentage has a precision of 6 decimals.
     */
    function calculateEquityRatio(
        uint256 sweep_delta,
        uint256 usdx_delta
    ) internal view returns (uint256) {
        uint256 sweep_balance = sweep.balanceOf(address(this));
        uint256 usdx_balance = usdx.balanceOf(address(this));
        uint256 sweep_balance_in_usdx = SWEEPinUSDX(sweep_balance + sweep_delta);
        uint256 senior_tranche_in_usdx = SWEEPinUSDX(sweep_borrowed + sweep_delta);
        uint256 total_value = asset.currentValue() + usdx_balance + sweep_balance_in_usdx - usdx_delta;

        if (total_value == 0 || total_value <= senior_tranche_in_usdx) return 0;

        // 1e6 is decimals of the percentage result
        uint256 current_equity_ratio = ((total_value - senior_tranche_in_usdx) * 100e6) / total_value;

        return current_equity_ratio;
    }

    /**
     * @notice Get Equity Ratio
     * @return the current equity ratio based in the internal storage.
     * @dev this value have a precision of 6 decimals.
     */
    function getEquityRatio() public view returns (uint256) {
        return calculateEquityRatio(0, 0);
    }

    /**
     * @notice Defaulted
     * @return bool that tells if stabilizer is in default.
     */
    function isDefaulted() public view returns (bool) {
        return getEquityRatio() < minimum_equity_ratio || IBalancer(balancer).isDefaulted(banker);
    }

    /**
     * @notice Get Junior Tranche Value
     * @return int calculated junior tranche amount.
     */
    function getJuniorTrancheValue() external view returns (int256) {
        uint256 sweep_balance = sweep.balanceOf(address(this));
        uint256 usdx_balance = usdx.balanceOf(address(this));
        uint256 sweep_balance_in_usdx = SWEEPinUSDX(sweep_balance);
        uint256 senior_tranche_in_usdx = SWEEPinUSDX(sweep_borrowed);
        uint256 total_value = asset.currentValue() + usdx_balance + sweep_balance_in_usdx;

        return int256(total_value) - int256(senior_tranche_in_usdx);
    }

    /**
     * @notice Get Spread Amount
     * r: interest rate per year
     * t: time period we pay the rate
     * y: time in one year
     * v: starting value
     * new v = v * (1 + r) ^ (t / y);
     * @return uint calculated spread amount.
     */
    function getSpreadValue() public view returns (uint256) {
        if (sweep_borrowed == 0) return 0;
        else {
            int256 sp_ratio = int256(SPREAD_PRECISION + spread_ratio).fromInt();
            int256 period = int256(block.timestamp - spread_payment_time).fromInt();
            int256 year = int256(TIME_ONE_YEAR).fromInt();
            int256 sp_prec = int256(SPREAD_PRECISION).fromInt();
            int256 time_ratio = period.div(year);
            int256 sp_unit = sp_ratio.pow(time_ratio).div(sp_prec.pow(time_ratio));

            return (sweep_borrowed * uint256(sp_unit)) / (10**sweep.decimals()) - sweep_borrowed;
        }
    }

    /**
     * @notice SWEEP in USDX
     * Calculate the amount of USDX that are equivalent to the SWEEP input.
     * @param amount Amount of SWEEP.
     * @return amount of USDX.
     * @dev 1e6 = PRICE_PRECISION
     */
    function SWEEPinUSDX(uint256 amount) internal view returns (uint256) {
        return (amount * sweep.target_price() * (10**usdx.decimals())) / (10**sweep.decimals() * 1e6);
    }
}