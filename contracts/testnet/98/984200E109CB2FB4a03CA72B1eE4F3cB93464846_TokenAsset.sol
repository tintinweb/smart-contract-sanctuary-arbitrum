// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;
pragma experimental ABIEncoderV2;

interface IAMM {
    function swapExactInput(
        address _tokenA,
        address _tokenB,
        uint256 _amountIn,
        uint256 _amountOutMin
    ) external returns (uint256);

    function buySweep(address _token, uint256 _amountIn, uint256 _amountOutMin)
        external
        returns (uint256);

    function sellSweep(address _token, uint256 _amountIn, uint256 _amountOutMin)
        external
        returns (uint256);

    function poolFee() external view returns (uint24);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;
pragma experimental ABIEncoderV2;

// ====================================================================
// ========================== TokenAsset.sol ==========================
// ====================================================================

/**
 * @title Token Asset
 * @dev Representation of an on-chain investment like Wrapped Ether, Wrapped Bitcoin ...
 */

import "../Stabilizer/Stabilizer.sol";
import "../Oracle/AggregatorV3Interface.sol";

contract TokenAsset is Stabilizer {
    // Variables
    IERC20Metadata public token;

    // Oracle to fetch price token / base
    AggregatorV3Interface private immutable token_oracle;

    constructor(
        string memory _name,
        address _sweep_address,
        address _usdx_address,
        address _token_address,
        address _token_oracle_address,
        address _amm_address,
        address _borrower,
        address _usd_oracle_address
    )
        Stabilizer(
            _name,
            _sweep_address,
            _usdx_address,
            _amm_address,
            _borrower,
            _usd_oracle_address
        )
    {
        token = IERC20Metadata(_token_address);
        token_oracle = AggregatorV3Interface(_token_oracle_address);
    }

    /* ========== Views ========== */

    /**
     * @notice Current Value of investment.
     * @return total with 6 decimal to be compatible with dollar coins.
     */
    function currentValue() public view override returns (uint256) {
        return assetValue() + super.currentValue();
    }

    /**
     * @notice Asset Value of investment.
     * @return the Returns the value of the investment in the USD coin
     * @dev the price is obtained from Chainlink
     */
    function assetValue() public view returns (uint256) {
        uint256 token_balance = token.balanceOf(address(this));
        (, int256 price, , uint256 updatedAt, ) = token_oracle.latestRoundData();

        if(price == 0) revert ZeroPrice();
        if(updatedAt < block.timestamp - 1 hours) revert StalePrice();

        uint256 usdx_amount = (token_balance *
            uint256(price) *
            10 ** usdx.decimals()) /
            (10 ** (token.decimals() + token_oracle.decimals()));

        return usdx_amount;
    }

    /* ========== Actions ========== */

    /**
     * @notice Invest.
     * @param _usdx_amount Amount of usdx to be swapped for token.
     * @dev Swap from usdx to token.
     */
    function invest(
        uint256 _usdx_amount
    ) external onlyBorrower notFrozen validAmount(_usdx_amount) {
        _invest(_usdx_amount, 0);
    }

    /**
     * @notice Divest.
     * @param _usdx_amount Amount to be divested.
     * @dev Swap from the token to usdx.
     */
    function divest(
        uint256 _usdx_amount
    ) external onlyBorrower validAmount(_usdx_amount) {
        _divest(_usdx_amount);
    }

    /**
     * @notice Liquidate
     */
    function liquidate() external {
        _liquidate(address(token));
    }

    /* ========== Internals ========== */

    function _invest(uint256 _usdx_amount, uint256) internal override {
        (uint256 usdx_balance, ) = _balances();
        _usdx_amount = _min(_usdx_amount, usdx_balance);

        TransferHelper.safeApprove(address(usdx), address(amm), _usdx_amount);
        amm.swapExactInput(address(usdx), address(token), _usdx_amount, 0);

        emit Invested(_usdx_amount, 0);
    }

    function _divest(uint256 _usdx_amount) internal override {
        (, int256 price, , uint256 updatedAt, ) = token_oracle.latestRoundData();

        if(price == 0) revert ZeroPrice();
        if(updatedAt < block.timestamp - 1 hours) revert StalePrice();

        uint256 token_amount = (_usdx_amount *
            (10 ** (token.decimals() + token_oracle.decimals()))) /
            (uint256(price) * 10 ** usdx.decimals());

        uint256 token_balance = token.balanceOf(address(this));
        token_amount = _min(token_amount, token_balance);

        TransferHelper.safeApprove(address(token), address(amm), token_amount);
        uint256 usdx_amount = amm.swapExactInput(
            address(token),
            address(usdx),
            token_amount,
            0
        );

        emit Divested(usdx_amount, 0);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)
pragma solidity 0.8.16;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)
pragma solidity 0.8.16;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./AggregatorV3Interface.sol";

contract ChainlinkUSDPricer {
    AggregatorV3Interface internal priceFeed;

    constructor(address _usd_oracle_address) {
        priceFeed = AggregatorV3Interface(_usd_oracle_address);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        (uint80 roundID, int price, , uint256 updatedAt, uint80 answeredInRound) = priceFeed.latestRoundData();
        require(price >= 0 && updatedAt!= 0 && answeredInRound >= roundID, "Invalid chainlink price");
        
        return price;
    }

    function getDecimals() public view returns (uint8) {
        return priceFeed.decimals();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;
pragma experimental ABIEncoderV2;

// ====================================================================
// ====================== Stabilizer.sol ==============================
// ====================================================================

/**
 * @title Stabilizer
 * @dev Implementation:
 * Allows to take debt by minting sweep and repaying by burning sweep
 * Allows to buy and sell sweep in an AMM
 * Allows auto invest according the borrower configuration
 * Allows auto repays by the balancer to control sweep price
 * Allow liquidate the Asset when is defaulted
 * Repayments made by burning sweep
 * EquityRatio = Junior / (Junior + Senior)
 */

import "../Sweep/ISweep.sol";
import "../AMM/IAMM.sol";
import "../Common/ERC20/IERC20Metadata.sol";
import "../Utils/Uniswap/V3/libraries/TransferHelper.sol";
import "../Oracle/ChainlinkUSDPricer.sol";

contract Stabilizer {
    // Variables
    string public name;
    address public borrower;
    int256 public min_equity_ratio; // Minimum Equity Ratio. 10000 is 1%
    uint256 public sweep_borrowed;
    uint256 public loan_limit;

    uint256 public call_time;
    uint256 public call_delay; // 86400 is 1 day
    uint256 public call_amount;

    uint256 public spread_fee; // 10000 is 1%
    uint256 public spread_date;
    uint256 public liquidator_discount; // 10000 is 1%
    string public link;

    int256 public auto_invest_min_ratio; // 10000 is 1%
    uint256 public auto_invest_min_amount;
    bool public auto_invest;

    bool public settings_enabled;
    bool public frozen;

    IAMM public amm;
    ChainlinkUSDPricer private usd_oracle;

    // Tokens
    ISweep public sweep;
    IERC20Metadata public usdx;

    // Constants for various precisions
    uint256 private constant DAY_SECONDS = 60 * 60 * 24; // seconds of Day
    uint256 private constant TIME_ONE_YEAR = 365 * DAY_SECONDS; // seconds of Year
    uint256 private constant PRECISION = 1e6;

    /* ========== Events ========== */

    event Borrowed(uint256 indexed sweep_amount);
    event Repaid(uint256 indexed sweep_amount);
    event Withdrawn(address indexed token, uint256 indexed amount);
    event PayFee(uint256 indexed sweep_amount);
    event Bought(uint256 indexed sweep_amount);
    event Sold(uint256 indexed sweep_amount);
    event BoughtSWEEP(uint256 indexed sweep_amount);
    event SoldSWEEP(uint256 indexed usdx_amount);
    event FrozenChanged(bool indexed frozen);
    event LoanLimitChanged(uint256 loan_limit);
    event BorrowerChanged(address indexed borrower);
    event Proposed(address indexed borrower);
    event Rejected(address indexed borrower);

    event Invested(uint256 indexed usdx_amount, uint256 indexed sweep_amount);
    event Divested(uint256 indexed usdx_amount, uint256 indexed sweep_amount);
    event Liquidated(address indexed user);

    event AutoCalled(uint256 indexed sweep_amount);
    event AutoInvested(uint256 indexed sweep_amount);
    event CallCancelled(uint256 indexed sweep_amount);
    

    event ConfigurationChanged(
        int256 indexed min_equity_ratio,
        uint256 indexed spread_fee,
        uint256 loan_limit,
        uint256 liquidator_discount,
        uint256 call_delay,
        int256 auto_invest_min_ratio,
        uint256 auto_invest_min_amount,
        bool auto_invest,
        string url_link
    );

    /* ========== Errors ========== */

    error StabilizerFrozen();
    error OnlyBorrower();
    error OnlyBalancer();
    error OnlyAdmin();
    error SettingsDisabled();
    error ZeroAddressDetected();
    error OverZero();
    error InvalidMinter();
    error NotEnoughBalance();
    error EquityRatioExcessed();
    error InvalidToken();
    error SpreadNotEnough();
    error NotDefaulted();
    error ZeroPrice();
    error StalePrice();
    error NotAutoInvest();
    error NotAutoInvesMinAMount();
    error NotAutoInvestMinRatio();

    /* ========== Modifies ========== */

    modifier notFrozen() {
        if (frozen) revert StabilizerFrozen();
        _;
    }

    modifier onlyBorrower() {
        if (msg.sender != borrower) revert OnlyBorrower();
        _;
    }

    modifier onlyBalancer() {
        if (msg.sender != sweep.balancer()) revert OnlyBalancer();
        _;
    }

    modifier onlyAdmin() {
        if (msg.sender != sweep.owner()) revert OnlyAdmin();
        _;
    }

    modifier onlySettingsEnabled() {
        if (!settings_enabled) revert SettingsDisabled();
        _;
    }

    modifier validAddress(address _addr) {
        if (_addr == address(0)) revert ZeroAddressDetected();
        _;
    }

    modifier validAmount(uint256 _amount) {
        if (_amount == 0) revert OverZero();
        _;
    }

    constructor(
        string memory _name,
        address _sweep_address,
        address _usdx_address,
        address _amm_address,
        address _borrower,
        address _usd_oracle_address
    ) {
        name = _name;
        sweep = ISweep(_sweep_address);
        usdx = IERC20Metadata(_usdx_address);
        amm = IAMM(_amm_address);
        borrower = _borrower;
        settings_enabled = true;
        frozen = false;
        usd_oracle = ChainlinkUSDPricer(_usd_oracle_address);
    }

    /* ========== Views ========== */

    /**
     * @notice Defaulted
     * @return bool that tells if stabilizer is in default.
     */
    function isDefaulted() public view returns (bool) {
        return
            (call_amount > 0 && block.timestamp > call_time) ||
            (sweep_borrowed > 0 && getEquityRatio() < min_equity_ratio);
    }

    /**
     * @notice Get Equity Ratio
     * @return the current equity ratio based in the internal storage.
     * @dev this value have a precision of 6 decimals.
     */
    function getEquityRatio() public view returns (int256) {
        return _calculateEquityRatio(0, 0);
    }

    /**
     * @notice Get Spread Amount
     * fee = borrow_amount * spread_ratio * (time / time_per_year)
     * @return uint256 calculated spread amount.
     */
    function accruedFee() public view returns (uint256) {
        if (sweep_borrowed == 0) return 0;
        else {
            uint256 period = block.timestamp - spread_date;
            return
                (sweep_borrowed * spread_fee * period) /
                (TIME_ONE_YEAR * PRECISION);
        }
    }

    /**
     * @notice Get Debt Amount
     * debt = borrow_amount + spread fee
     * @return uint256 calculated debt amount.
     */
    function getDebt() public view returns (uint256) {
        return sweep_borrowed + accruedFee();
    }

    /**
     * @notice Get Current Value
     * value = sweep balance + usdx balance
     * @return uint256.
     */
    function currentValue() public view virtual returns (uint256) {
        (uint256 usdx_balance, uint256 sweep_balance) = _balances();
        uint256 sweep_balance_in_usd = sweep.convertToUSD(sweep_balance);

        return (_USDXtoUSD(usdx_balance) + sweep_balance_in_usd);
    }

    /**
     * @notice Get Junior Tranche Value
     * @return int256 calculated junior tranche amount.
     */
    function getJuniorTrancheValue() external view returns (int256) {
        uint256 senior_tranche_in_usdx = sweep.convertToUSD(sweep_borrowed);
        uint256 total_value = currentValue();

        return int256(total_value) - int256(senior_tranche_in_usdx);
    }

    /**
     * @notice Returns the SWEEP required to liquidate the stabilizer
     * @return uint256
     */
    function getLiquidationValue() public view returns (uint256) {
        return
            sweep.convertToSWEEP(
                (currentValue() * (1e6 - liquidator_discount)) / PRECISION
            );
    }

    /* ========== Settings ========== */

    /**
     * @notice Set Borrower
     * @param _borrower.
     * @dev Who manages the investment actions.
     */
    function setBorrower(
        address _borrower
    ) external onlyAdmin validAddress(_borrower) {
        borrower = _borrower;
        settings_enabled = true;

        emit BorrowerChanged(_borrower);
    }

    /**
     * @notice Frozen
     * @param _frozen.
     * @dev Stops investment actions.
     */
    function setFrozen(bool _frozen) external onlyAdmin {
        frozen = _frozen;

        emit FrozenChanged(_frozen);
    }

    /**
     * @notice Configure intial settings
     * @param _min_equity_ratio The minimum equity ratio can be negative.
     * @param _spread_fee The fee that the protocol will get for providing the loan when the stabilizer takes debt
     * @param _loan_limit How much debt a Stabilizer can take in SWEEP.
     * @param _liquidator_discount A percentage that will be discounted in favor to the liquidator when the stabilizer is liquidated
     * @param _call_delay Time in seconds after AutoCall until the Stabilizer gets defaulted if the debt is not paid in that period
     * @param _auto_invest_min_ratio Minimum equity ratio that should be kept to allow the execution of an auto invest
     * @param _auto_invest_min_amount Minimum amount to be invested to allow the execution of an auto invest
     * @param _auto_invest Represents if an auto invest execution is allowed or not
     * @param _link A URL link to a Web page that describes the borrower and the asset
     * @dev Sets the initial configuration of the Stabilizer.
     * This configuration will be analyzed by the protocol and if accepted,
     * used to include the Stabilizer in the minter's whitelist of Sweep.
     */
    function configure(
        int256 _min_equity_ratio,
        uint256 _spread_fee,
        uint256 _loan_limit,
        uint256 _liquidator_discount,
        uint256 _call_delay,
        int256 _auto_invest_min_ratio,
        uint256 _auto_invest_min_amount,
        bool _auto_invest,
        string calldata _link
    ) external onlyBorrower onlySettingsEnabled {
        min_equity_ratio = _min_equity_ratio;
        spread_fee = _spread_fee;
        loan_limit = _loan_limit;
        liquidator_discount = _liquidator_discount;
        call_delay = _call_delay;
        auto_invest_min_ratio = _auto_invest_min_ratio;
        auto_invest_min_amount = _auto_invest_min_amount;
        auto_invest = _auto_invest;
        link = _link;

        emit ConfigurationChanged(
            _min_equity_ratio,
            _spread_fee,
            _loan_limit,
            _liquidator_discount,
            _call_delay,
            _auto_invest_min_ratio,
            _auto_invest_min_amount,
            _auto_invest,
            _link
        );
    }

    /**
     * @notice Changes the account that control the global configuration to the protocol/governance admin
     * @dev after disable settings by admin
     * the protocol will evaluate adding the stabilizer to the minter list.
     */
    function propose() external onlyBorrower {
        settings_enabled = false;

        emit Proposed(borrower);
    }

    /**
     * @notice Changes the account that control the global configuration to the borrower
     * @dev after enable settings for the borrower
     * he/she should edit the values to align to the protocol requirements
     */
    function reject() external onlyAdmin {
        settings_enabled = true;

        emit Rejected(borrower);
    }

    /* ========== Actions ========== */

    /**
     * @notice Borrows Sweep
     * Asks the stabilizer to mint a certain amount of sweep token.
     * @param _sweep_amount.
     * @dev Increases the sweep_borrowed (senior tranche).
     */
    function borrow(
        uint256 _sweep_amount
    ) external onlyBorrower notFrozen validAmount(_sweep_amount) {
        if (!sweep.isValidMinter(address(this))) revert InvalidMinter();

        uint256 sweep_available = loan_limit - sweep_borrowed;
        if (sweep_available < _sweep_amount) revert NotEnoughBalance();

        int256 current_equity_ratio = _calculateEquityRatio(_sweep_amount, 0);
        if (current_equity_ratio < min_equity_ratio)
            revert EquityRatioExcessed();

        _borrow(_sweep_amount);
    }

    /**
     * @notice Repays Sweep
     * Burns the sweep_amount to reduce the debt (senior tranche).
     * @param _sweep_amount Amount to be burnt by Sweep.
     * @dev Decreases the sweep borrowed.
     */
    function repay(uint256 _sweep_amount) external onlyBorrower {
        _repay(_sweep_amount);
    }

    /**
     * @notice Pay the spread to the treasury
     */
    function payFee() external onlyBorrower {
        uint256 spread_amount = accruedFee();
        spread_date = block.timestamp;

        (, uint256 sweep_balance) = _balances();

        if (spread_amount > sweep_balance) revert SpreadNotEnough();

        if (spread_amount > 0) {
            TransferHelper.safeTransfer(
                address(sweep),
                sweep.treasury(),
                spread_amount
            );

            emit PayFee(spread_amount);
        }
    }

    /**
     * @notice Set Loan Limit.
     * @param _new_loan_limit.
     * @dev How much debt an Stabilizer can take in SWEEP.
     */
    function setLoanLimit(uint256 _new_loan_limit) external onlyBalancer {
        loan_limit = _new_loan_limit;

        emit LoanLimitChanged(_new_loan_limit);
    }

    /**
     * @notice Auto Call.
     * @param _sweep_amount to repay.
     * @dev Strategy:
     * 1) repays debt with SWEEP balance
     * 2) repays remaining debt by divesting
     * 3) repays remaining debt by buying on SWEEP in the AMM
     */
    function autoCall(uint256 _sweep_amount) external onlyBalancer {
        uint256 missing_usdx = 0;
        (uint256 usdx_balance, uint256 sweep_balance) = _balances();

        if (call_delay > 0) call_time = block.timestamp + call_delay;

        call_amount = _min(_sweep_amount, sweep_borrowed);

        if (sweep_balance < call_amount) {
            uint256 missing_sweep = call_amount - sweep_balance;
            missing_usdx = sweep.convertToUSD(missing_sweep);
            if (missing_usdx > usdx_balance)
                _divest(missing_usdx - usdx_balance);
        }

        if (missing_usdx > 0) call_amount = _buy(missing_usdx, 0);
        if (call_amount > 0) _repay(call_amount);

        emit AutoCalled(_sweep_amount);
    }

    /**
     * @notice Cancel Call
     * @dev Cancels the auto call request by clearing variables for an asset that has a call_delay: meaning that it does not autorepay.
     */
    function cancelCall() external onlyAdmin {
        emit CallCancelled(call_amount);
        call_amount = 0;
        call_time = 0;
    }

    /**
     * @notice Auto Invest.
     * @param _sweep_amount to mint.
     */
    function autoInvest(uint256 _sweep_amount) external onlyBalancer {
        uint256 sweep_limit = sweep.minters(address(this)).max_amount;
        uint256 sweep_available = sweep_limit - sweep_borrowed;
        _sweep_amount = _min(_sweep_amount, sweep_available);
        int256 current_equity_ratio = _calculateEquityRatio(_sweep_amount, 0);

        if(!auto_invest) revert NotAutoInvest();
        if(_sweep_amount < auto_invest_min_amount) revert NotAutoInvesMinAMount();
        if(current_equity_ratio < auto_invest_min_ratio) revert NotAutoInvestMinRatio();

        _borrow(_sweep_amount);
        uint256 usdx_amount = _sell(_sweep_amount, 0);
        _invest(usdx_amount, 0);

        emit AutoInvested(_sweep_amount);
    }

    /**
     * @notice Buy
     * Buys sweep_amount from the stabilizer's balance to the AMM (swaps USDX to SWEEP).
     * @param _usdx_amount Amount to be changed in the AMM.
     * @param _amountOutMin Minimum amount out.
     * @dev Increases the sweep balance and decrease usdx balance.
     */
    function buySweepOnAMM(
        uint256 _usdx_amount,
        uint256 _amountOutMin
    ) external onlyBorrower notFrozen returns (uint256 sweep_amount) {
        sweep_amount = _buy(_usdx_amount, _amountOutMin);

        emit Bought(sweep_amount);
    }

    /**
     * @notice Sell Sweep
     * Sells sweep_amount from the stabilizer's balance to the AMM (swaps SWEEP to USDX).
     * @param _sweep_amount.
     * @param _amountOutMin Minimum amount out.
     * @dev Decreases the sweep balance and increase usdx balance
     */
    function sellSweepOnAMM(
        uint256 _sweep_amount,
        uint256 _amountOutMin
    ) external onlyBorrower notFrozen returns (uint256 usdx_amount) {
        usdx_amount = _sell(_sweep_amount, _amountOutMin);

        emit Sold(_sweep_amount);
    }

    /**
     * @notice Buy Sweep with Stabilizer
     * Buys sweep_amount from the stabilizer's balance to the Borrower (swaps USDX to SWEEP).
     * @param _usdx_amount.
     * @dev Decreases the sweep balance and increase usdx balance
     */
    function swapUsdxToSweep(
        uint256 _usdx_amount
    ) external onlyBorrower notFrozen validAmount(_usdx_amount) {
        uint256 sweep_amount = sweep.convertToSWEEP(_usdx_amount);
        (, uint256 sweep_balance) = _balances();
        if (sweep_amount > sweep_balance) revert NotEnoughBalance();

        TransferHelper.safeTransferFrom(
            address(usdx),
            msg.sender,
            address(this),
            _usdx_amount
        );
        TransferHelper.safeTransfer(address(sweep), msg.sender, sweep_amount);

        emit BoughtSWEEP(sweep_amount);
    }

    /**
     * @notice Sell Sweep with Stabilizer
     * Sells sweep_amount to the stabilizer (swaps SWEEP to USDX).
     * @param _sweep_amount.
     * @dev Decreases the sweep balance and increase usdx balance
     */
    function swapSweepToUsdx(
        uint256 _sweep_amount
    ) external onlyBorrower notFrozen validAmount(_sweep_amount) {
        uint256 usd_amount = sweep.convertToUSD(_sweep_amount);
        (uint256 usdx_balance, ) = _balances();
        uint256 usdx_amount = _USDtoUSDX(usd_amount);

        if (usdx_amount > usdx_balance) revert NotEnoughBalance();

        TransferHelper.safeTransferFrom(
            address(sweep),
            msg.sender,
            address(this),
            _sweep_amount
        );
        TransferHelper.safeTransfer(address(usdx), msg.sender, usdx_amount);

        emit SoldSWEEP(usdx_amount);
    }

    /**
     * @notice Withdraw SWEEP
     * Takes out sweep balance if the new equity ratio is higher than the minimum equity ratio.
     * @param _token.
     * @param _amount.
     * @dev Decreases the sweep balance.
     */
    function withdraw(
        address _token,
        uint256 _amount
    ) external onlyBorrower notFrozen validAmount(_amount) {
        if (_token != address(sweep) && _token != address(usdx))
            revert InvalidToken();

        if (_amount > IERC20Metadata(_token).balanceOf(address(this)))
            revert NotEnoughBalance();

        if (sweep_borrowed > 0) {
            uint256 usdx_amount = _amount;
            if (_token == address(sweep))
                usdx_amount = sweep.convertToUSD(_amount);
            int256 current_equity_ratio = _calculateEquityRatio(0, _USDXtoUSD(usdx_amount));
            if (current_equity_ratio < min_equity_ratio)
                revert EquityRatioExcessed();
        }

        TransferHelper.safeTransfer(_token, msg.sender, _amount);

        emit Withdrawn(_token, _amount);
    }

    /* ========== Internals ========== */

    /**
     * @notice Invest To Asset.
     */
    function _invest(
        uint256 _usdx_amount,
        uint256 _sweep_amount
    ) internal virtual {}

    /**
     * @notice Divest From Asset.
     */
    function _divest(uint256 _amount) internal virtual {}

    /**
     * @notice Liquidates
     * A liquidator repays the debt in sweep and gets the same value
     * of the assets that the stabilizer holds at a discount
     */
    function _liquidate(address token) internal {
        if (!isDefaulted()) revert NotDefaulted();

        uint256 sweep_to_liquidate = getLiquidationValue();
        (uint256 usdx_balance, uint256 sweep_balance) = _balances();
        uint256 token_balance = IERC20Metadata(token).balanceOf(address(this));
        // Gives all the assets to the liquidator first
        TransferHelper.safeTransfer(address(sweep), msg.sender, sweep_balance);
        TransferHelper.safeTransfer(address(usdx), msg.sender, usdx_balance);
        TransferHelper.safeTransfer(token, msg.sender, token_balance);

        // Takes SWEEP from the liquidator and repays as much debt as it can
        TransferHelper.safeTransferFrom(
            address(sweep),
            msg.sender,
            address(this),
            sweep_to_liquidate
        );

        _repay(_min(sweep_to_liquidate, getDebt()));

        emit Liquidated(msg.sender);
    }

    function _buy(
        uint256 _usdx_amount,
        uint256 _amountOutMin
    ) internal returns (uint256) {
        (uint256 usdx_balance, ) = _balances();
        _usdx_amount = _min(_usdx_amount, usdx_balance);

        if (_usdx_amount == 0) revert NotEnoughBalance();

        TransferHelper.safeApprove(address(usdx), address(amm), _usdx_amount);
        uint256 sweep_amount = amm.buySweep(
            address(usdx),
            _usdx_amount,
            _amountOutMin
        );

        return sweep_amount;
    }

    function _sell(
        uint256 _sweep_amount,
        uint256 _amountOutMin
    ) internal returns (uint256) {
        (, uint256 sweep_balance) = _balances();
        _sweep_amount = _min(_sweep_amount, sweep_balance);

        if (_sweep_amount == 0) revert NotEnoughBalance();

        TransferHelper.safeApprove(address(sweep), address(amm), _sweep_amount);
        uint256 usdx_amount = amm.sellSweep(
            address(usdx),
            _sweep_amount,
            _amountOutMin
        );

        return usdx_amount;
    }

    function _borrow(uint256 _sweep_amount) internal {
        uint256 spread_amount = accruedFee();
        sweep.minter_mint(address(this), _sweep_amount);
        sweep_borrowed += _sweep_amount;
        spread_date = block.timestamp;

        if (spread_amount > 0) {
            TransferHelper.safeTransfer(
                address(sweep),
                sweep.treasury(),
                spread_amount
            );
            emit PayFee(spread_amount);
        }

        emit Borrowed(_sweep_amount);
    }

    function _repay(uint256 _sweep_amount) internal {
        (, uint256 sweep_balance) = _balances();
        _sweep_amount = _min(_sweep_amount, sweep_balance);

        if (_sweep_amount == 0) revert NotEnoughBalance();

        call_amount = (call_amount > _sweep_amount)
            ? call_amount - _sweep_amount
            : 0;

        if (call_delay > 0 && call_amount == 0) call_time = 0;

        uint256 spread_amount = accruedFee();
        spread_date = block.timestamp;

        uint256 sweep_amount = _sweep_amount - spread_amount;
        if (sweep_borrowed < sweep_amount) {
            sweep_amount = sweep_borrowed;
            sweep_borrowed = 0;
        } else {
            sweep_borrowed -= sweep_amount;
        }

        TransferHelper.safeTransfer(
            address(sweep),
            sweep.treasury(),
            spread_amount
        );

        TransferHelper.safeApprove(address(sweep), address(this), sweep_amount);
        sweep.minter_burn_from(sweep_amount);

        emit Repaid(sweep_amount);
    }

    /**
     * @notice Calculate Equity Ratio
     * Calculated the equity ratio based on the internal storage.
     * @param _sweep_delta Variation of SWEEP to recalculate the new equity ratio.
     * @param _usd_delta Variation of USD to recalculate the new equity ratio.
     * @return the new equity ratio used to control the Mint and Withdraw functions.
     * @dev Current Equity Ratio percentage has a precision of 4 decimals.
     */
    function _calculateEquityRatio(
        uint256 _sweep_delta,
        uint256 _usd_delta
    ) internal view returns (int256) {
        uint256 current_value = currentValue();
        uint256 sweep_delta_in_usd = sweep.convertToUSD(_sweep_delta);
        uint256 total_value = current_value + sweep_delta_in_usd - _usd_delta;

        if (total_value == 0) return 0;

        uint256 senior_tranche_in_usd = sweep.convertToUSD(
            sweep_borrowed + _sweep_delta
        );

        // 1e6 is decimals of the percentage result
        int256 current_equity_ratio = ((int256(total_value) -
            int256(senior_tranche_in_usd)) * 1e6) / int256(total_value);

        if (current_equity_ratio < -1e6) current_equity_ratio = -1e6;

        return current_equity_ratio;
    }

    /**
     * @notice Get Balances of the usdx and sweep.
     **/
    function _balances()
        internal
        view
        returns (uint256 usdx_balance, uint256 sweep_balance)
    {
        usdx_balance = usdx.balanceOf(address(this));
        sweep_balance = sweep.balanceOf(address(this));
    }

    /**
     * @notice Get minimum value between a and b.
     **/
    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a < b) ? a : b;
    }

    /**
     * @notice Calculate the amount USD that are equivalent to the USDX input.
     **/
    function _USDXtoUSD(uint256 _usdx_amount) internal view returns (uint256) {
        return ((_usdx_amount * uint256(usd_oracle.getLatestPrice())) / (10 ** (usd_oracle.getDecimals())));
    }

    /**
     * @notice Calculate the amount USDX that are equivalent to the USD input.
     **/
    function _USDtoUSDX(uint256 _usdx_amount) internal view returns (uint256) {
        return ((_usdx_amount * (10 ** (usd_oracle.getDecimals()))) / uint256(usd_oracle.getLatestPrice()));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

interface ISweep {
    struct Minter {
        uint256 max_amount;
        uint256 minted_amount;
        bool is_listed;
        bool is_enabled;
    }

    function DEFAULT_ADMIN_ADDRESS() external view returns (address);

    function balancer() external view returns (address);

    function treasury() external view returns (address);

    function collateral_agency() external view returns (address);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function isValidMinter(address) external view returns (bool);

    function amm_price() external view returns (uint256);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function minter_burn_from(uint256 amount) external;

    function minter_mint(address m_address, uint256 m_amount) external;

    function minters(address m_address) external returns (Minter memory);

    function minter_addresses(uint256 index) external view returns (address);

    function getMinters() external view returns(address[] memory);

    function target_price() external view returns (uint256);

    function interest_rate() external view returns (int256);

    function period_time() external view returns (uint256);

    function step_value() external view returns (int256);

    function setInterestRate(int256 interest_rate) external;

    function setTargetPrice(uint256 current_target_price, uint256 next_target_price) external;    

    function startNewPeriod() external;

    function setUniswapOracle(address uniswap_oracle_address) external;

    function setTimelock(address new_timelock) external;

    function symbol() external view returns (string memory);

    function timelock_address() external view returns (address);

    function totalSupply() external view returns (uint256);

    function convertToUSD(uint256 amount) external view returns (uint256);

    function convertToSWEEP(uint256 amount) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

import "../../../../Common/ERC20/IERC20.sol";

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
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                from,
                to,
                value
            )
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "STF"
        );
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
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "ST"
        );
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
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.approve.selector, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SA"
        );
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "STE");
    }
}