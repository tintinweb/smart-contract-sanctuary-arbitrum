// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.13;

// ====================================================================
// ======================= SWEEP Dollar Coin (SWEEP) ======================
// ====================================================================


// Primary Author(s)
// Che Jin: https://github.com/topdev104

import "./BaseSweep.sol";
import "./PRBMathSD59x18.sol";
import "./UniV3TWAPOracle.sol";

contract SweepDollarCoin is BaseSweep {
    using PRBMathSD59x18 for int256;

    // 2M SWEEP (only for testing, genesis supply will be 5k on Mainnet). This is to help with establishing the Uniswap pools, as they need liquidity
    uint256 public constant GENESIS_SUPPLY = 2000000e18;

    // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e6;
    uint256 private constant PRECISE_PRICE_PRECISION = 1e18;

    // Contants for seconds of Year
    uint private constant TIME_ONE_YEAR = 365 * 24 * 60 * 60;

    /* ========== STATE VARIABLES ========== */
    UniV3TWAPOracle private uniV3TWAPOracle;

    address public sweep_usdc_oracle_address;

    uint256 public interest_rate; // 6 decimals of precision, e.g. 50000 = 5%

    uint256 public period_start;
    uint256 public period_finish;
    uint256 public period_time; // Period Time

    uint256 public current_target_price; // The cuurent target price of SWEEP
    uint256 public next_target_price; // The next target price of SWEEP
    uint256 public previous_target_price; // The previous target price of SWEEP
    uint256 public previous_amm_price; // The previous AMM price of SWEEP

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        address _timelock_address,
        address _multisig_address,
        address _transfer_approver_address
    )
    public initializer {
        BaseSweep.__Sweep_init(_timelock_address, _multisig_address, _transfer_approver_address, "SWEEP Dollar Coin", "SWEEP");
        _mint(msg.sender, GENESIS_SUPPLY);

        setInterestRate(0);
        setPriceTarget(1e6);
    }

    /* ========== VIEWS ========== */

    function amm_price() public view returns (uint256) {
        return uniV3TWAPOracle.getPrice();
    }

    function target_price() public view returns (uint256) {
        if (block.timestamp - period_start >= period_time) { // if over period, return next target price for new period
            return next_target_price;
        } else { // if in period, return current target price
            return current_target_price;
        }
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    function refreshTargetPrice(uint _amm_price) public onlyMinters {
        previous_target_price = current_target_price;
        current_target_price = (previous_target_price * _amm_price) / previous_amm_price;

        previous_amm_price = _amm_price;
        emit TargetPriceRefreshed(current_target_price);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function beginNewPeriod(uint256 _new_period_time) public onlyOwner {
        require(block.timestamp - period_start >= period_time, "Must wait for the period time since previos period");

        uint256 _new_target_price = target_price();

        setPeriodTime(_new_period_time);
        setPriceTarget(_new_target_price);
    }

    function setInterestRate(uint256 _new_interest_rate) public onlyOwner {
        interest_rate = _new_interest_rate;

        emit InterestRateSet(_new_interest_rate);
    }

    /* Set new target price with the following formula:  
        new_price = p * (1 + r) ^ (t / y)
        * r: interest rate per year
        * t: time period to pay the rate
        * y: time in one year
        * p: starting price
    */
    function setPriceTarget(uint256 _new_target_price) public onlyOwner {
        previous_target_price = current_target_price;
        current_target_price = _new_target_price;

        int256 year = int256(TIME_ONE_YEAR).fromInt();
        int256 period = int256(period_time).fromInt();
        int256 time_ratio = period.div(year);

        int256 price_ratio = int256(PRICE_PRECISION + interest_rate).fromInt();
        int256 base_precision = int256(PRICE_PRECISION).fromInt();
        int256 price_unit = price_ratio.pow(time_ratio).div(base_precision.pow(time_ratio));

        if (interest_rate > 0) {
            next_target_price = current_target_price * uint256(price_unit) / PRECISE_PRICE_PRECISION;
        } else {
            next_target_price = current_target_price;
        }

        emit PriceTargetSet(_new_target_price);
    }

    function setUniswapOracle(address _uniswap_oracle_address) public onlyOwner {
        require(_uniswap_oracle_address != address(0), "Zero address detected");

        sweep_usdc_oracle_address = _uniswap_oracle_address;
        uniV3TWAPOracle = UniV3TWAPOracle(_uniswap_oracle_address);
        previous_amm_price = uniV3TWAPOracle.getPrice();

        emit UniswapOracleSet(_uniswap_oracle_address);
    }

    function setPeriodTime(uint256 _period_time) public onlyOwner {
        period_time = _period_time;
        period_start = block.timestamp;
        period_finish = period_start + period_time;

        emit PeriodTimeSet(_period_time);
    }
    
    /* ========== EVENTS ========== */

    event TargetPriceRefreshed(uint256 new_target_price);
    event PriceTargetSet(uint256 new_price_target);
    event PeriodTimeSet(uint256 new_period_time_set);
    event InterestRateSet(uint256 new_interest_rate);
    event UniswapOracleSet(address uniswap_oracle_address);
}