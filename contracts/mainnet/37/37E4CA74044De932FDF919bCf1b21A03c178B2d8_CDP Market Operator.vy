#pragma version 0.3.10
"""
@title CDP Market Operator
@author Curve.Fi (with edits by defidotmoney)
@license Copyright (c) Curve.Fi, 2020-2024 - all rights reserved
"""

interface LLAMMA:
    def A() -> uint256: view
    def get_p() -> uint256: view
    def get_base_price() -> uint256: view
    def active_band() -> int256: view
    def active_band_with_skip() -> int256: view
    def p_oracle_up(n: int256) -> uint256: view
    def p_oracle_down(n: int256) -> uint256: view
    def deposit_range(account: address, amount: uint256, n1: int256, n2: int256): nonpayable
    def read_user_tick_numbers(receiver: address) -> int256[2]: view
    def get_sum_xy(account: address) -> uint256[2]: view
    def withdraw(account: address, frac: uint256) -> uint256[2]: nonpayable
    def get_x_down(account: address) -> uint256: view
    def get_rate_mul() -> uint256: view
    def set_fee(fee: uint256): nonpayable
    def set_admin_fee(fee: uint256): nonpayable
    def price_oracle() -> uint256: view
    def price_oracle_w() -> uint256: nonpayable
    def can_skip_bands(n_end: int256) -> bool: view
    def admin_fees_x() -> uint256: view
    def admin_fees_y() -> uint256: view
    def reset_admin_fees() -> uint256[2]: nonpayable
    def has_liquidity(account: address) -> bool: view
    def bands_x(n: int256) -> uint256: view
    def bands_y(n: int256) -> uint256: view
    def set_liquidity_mining_hook(account: address): nonpayable
    def set_oracle(oracle: PriceOracle): nonpayable

interface PriceOracle:
    def price() -> uint256: view
    def price_w() -> uint256: nonpayable

interface ERC20:
    def transferFrom(_from: address, _to: address, _value: uint256) -> bool: nonpayable
    def transfer(_to: address, _value: uint256) -> bool: nonpayable
    def decimals() -> uint256: view
    def approve(_spender: address, _value: uint256) -> bool: nonpayable
    def balanceOf(_from: address) -> uint256: view

interface Controller:
    def STABLECOIN() -> ERC20: view

interface CoreOwner:
    def owner() -> address: view


event UserState:
    account: indexed(address)
    collateral: uint256
    debt: uint256
    n1: int256
    n2: int256
    liquidation_discount: uint256

event SetBorrowingDiscounts:
    loan_discount: uint256
    liquidation_discount: uint256

event SetAmmFee:
    fee: uint256

event SetAmmAdminFee:
    fee: uint256

event SetLiquidityMiningHook:
    hook: address

event SetDebtCeiling:
    debt_ceiling: uint256

event SetPriceOracle:
    oracle: PriceOracle


struct Loan:
    initial_debt: uint256
    rate_mul: uint256

struct Position:
    account: address
    x: uint256
    y: uint256
    debt: uint256
    health: int256


CORE_OWNER: public(immutable(CoreOwner))
CONTROLLER: public(immutable(address))
COLLATERAL_TOKEN: public(ERC20)
AMM: public(LLAMMA)

COLLATERAL_PRECISION: uint256
A: public(immutable(uint256))
Aminus1: immutable(uint256)
LOGN_A_RATIO: immutable(int256)  # log(A / (A - 1))
SQRT_BAND_RATIO: immutable(uint256)

MAX_LOAN_DISCOUNT: constant(uint256) = 5 * 10**17
MIN_LIQUIDATION_DISCOUNT: constant(uint256) = 10**16 # Start liquidating when threshold reached
MAX_TICKS: public(constant(uint256)) = 50
MIN_TICKS: public(constant(uint256)) = 4
MAX_SKIP_TICKS: constant(uint256) = 1024
MAX_P_BASE_BANDS: constant(int256) = 5

MAX_ADMIN_FEE: constant(uint256) = 10**18  # 100%
MIN_FEE: constant(uint256) = 10**6  # 1e-12, still needs to be above 0
MAX_FEE: public(immutable(uint256))  # MIN_TICKS / A: for example, 4% max fee for A=100
DEAD_SHARES: constant(uint256) = 1000

loan: HashMap[address, Loan]
liquidation_discounts: public(HashMap[address, uint256])
_total_debt: Loan

loans: public(address[2**64 - 1])  # Enumerate existing loans
loan_ix: public(HashMap[address, uint256])  # Position of the loan in the list
n_loans: public(uint256)  # Number of nonzero loans

debt_ceiling: public(uint256)
liquidation_discount: public(uint256)
loan_discount: public(uint256)


@external
def __init__(core: CoreOwner, controller: address, _A: uint256):
    """
    @notice Contract constructor
    @param core `DFMProtocolCore` address. Ownership is inherited from this contract.
    @param controller `MainController` address.
    @param _A amplification coefficient. The size of one band is 1/A.
    """
    CONTROLLER = controller
    CORE_OWNER = core

    A = _A
    Aminus1 = unsafe_sub(_A, 1)
    LOGN_A_RATIO = self.wad_ln(unsafe_div(_A * 10**18, unsafe_sub(_A, 1)))
    MAX_FEE = min(unsafe_div(10**18 * MIN_TICKS, A), 10**17)
    SQRT_BAND_RATIO = isqrt(unsafe_div(10**36 * _A, unsafe_sub(_A, 1)))


@external
def initialize(
    amm: LLAMMA,
    collateral: ERC20,
    debt_ceiling: uint256,
    loan_discount: uint256,
    liquidation_discount: uint256,
):
    """
    @notice Market Operator initializer
    @param amm Address of LLAMMA deployment associated with this market
    @param collateral Token to use for collateral
    @param debt_ceiling Market-specific debt ceiling
    @param loan_discount Discount of the maximum loan size compare to get_x_down() value
    @param liquidation_discount Discount of the maximum loan size compare to
           get_x_down() for "bad liquidation" purposes
    """
    self._assert_only_controller()
    self.AMM = amm
    self.COLLATERAL_TOKEN = collateral
    self.COLLATERAL_PRECISION = pow_mod256(10, 18 - collateral.decimals())

    self.debt_ceiling = debt_ceiling
    self.liquidation_discount = liquidation_discount
    self.loan_discount = loan_discount
    self._total_debt.rate_mul = 10**18

    log SetDebtCeiling(debt_ceiling)
    log SetBorrowingDiscounts(loan_discount, liquidation_discount)


# --- external view functions ---
# Most views in this contract should instead be accessed via related methods in `MainController`


@view
@external
def owner() -> address:
    return CORE_OWNER.owner()


@view
@external
def debt(account: address) -> uint256:
    """
    @notice Get the value of debt without changing the state
    @param account User address
    @return Value of debt
    """
    return self._debt(account, self.AMM)[0]


@view
@external
def loan_exists(account: address) -> bool:
    """
    @notice Check whether there is a loan of `account` in existence
    """
    return self.loan[account].initial_debt > 0


@view
@external
def total_debt() -> uint256:
    """
    @notice Total debt of this market
    """
    return self._get_total_debt()


@view
@external
def pending_debt() -> uint256:
    """
    @notice Market debt which has not been stored in `MainController.total_debt`
    """
    return self._get_total_debt() - self._total_debt.initial_debt


@view
@external
def max_borrowable(collateral: uint256, n_bands: uint256) -> uint256:
    """
    @notice Calculation of maximum which can be borrowed (details in comments)
    @dev Users should instead call `MainController.max_borrowable` which also
         considers the global debt ceiling in the returned value
    @param collateral Collateral amount against which to borrow
    @param n_bands number of bands to have the deposit into
    @return Maximum amount of stablecoin to borrow
    """
    # Calculation of maximum which can be borrowed.
    # It corresponds to a minimum between the amount corresponding to price_oracle
    # and the one given by the min reachable band.
    #
    # Given by p_oracle (perhaps needs to be multiplied by (A - 1) / A to account for mid-band effects)
    # x_max ~= y_effective * p_oracle
    #
    # Given by band number:
    # if n1 is the lowest empty band in the AMM
    # xmax ~= y_effective * amm.p_oracle_up(n1)
    #
    # When n1 -= 1:
    # p_oracle_up *= A / (A - 1)

    assert n_bands > MIN_TICKS-1, "DFM:M Need more ticks"
    assert n_bands < MAX_TICKS+1, "DFM:M Need less ticks"

    total_debt: uint256 = self._get_total_debt()
    debt_ceiling: uint256 = self.debt_ceiling
    if total_debt < debt_ceiling:
        y_effective: uint256 = self.get_y_effective(collateral * self.COLLATERAL_PRECISION, n_bands, self.loan_discount)

        x: uint256 = unsafe_sub(max(unsafe_div(y_effective * self.max_p_base(), 10**18), 1), 1)
        x = unsafe_div(x * (10**18 - 10**14), 10**18)  # Make it a bit smaller
        return min(x, debt_ceiling - total_debt)
    else:
        return 0


@view
@external
def min_collateral(debt: uint256, n_bands: uint256) -> uint256:
    """
    @notice Minimal amount of collateral required to support debt
    @param debt The debt to support
    @param n_bands Number of bands to deposit into
    @return Minimal collateral required
    """
    # Add N**2 to account for precision loss in multiple bands, e.g. N / (y/N) = N**2 / y
    y_effective: uint256 = self.get_y_effective(10**18, n_bands, self.loan_discount)
    x: uint256 = debt * 10**18 / self.max_p_base() * 10**18 / y_effective
    x += n_bands * (n_bands + 2 * DEAD_SHARES) + self.COLLATERAL_PRECISION - 1
    return ((x / self.COLLATERAL_PRECISION) * 10**18) / (10**18 - 10**14)



@view
@external
def calculate_debt_n1(collateral: uint256, debt: uint256, n_bands: uint256) -> int256:
    """
    @notice Calculate the upper band number for the deposit to sit in to support
            the given debt. Reverts if requested debt is too high.
    @param collateral Amount of collateral (at its native precision)
    @param debt Amount of requested debt
    @param n_bands Number of bands to deposit into
    @return Upper band n1 (n1 <= n2) to deposit into. Signed integer
    """
    return self._calculate_debt_n1(self.AMM, collateral, debt, n_bands, self.AMM.price_oracle())


@view
@external
def tokens_to_liquidate(caller: address, target: address, frac: uint256 = 10 ** 18) -> uint256:
    """
    @notice Calculate the required stablecoin balance to liquidate an account
    @param caller Address of the account performing the liquidation
    @param target Address of the account to liquidate
    @param frac Fraction to liquidate; 100% = 10**18
    @return The amount of stablecoins needed
    """
    health_limit: uint256 = 0
    if caller != target:
        health_limit = self.liquidation_discounts[target]
    amm: LLAMMA = self.AMM
    stablecoins: uint256 = unsafe_div(amm.get_sum_xy(target)[0] * self._get_f_remove(frac, health_limit), 10 ** 18)
    debt: uint256 = unsafe_div(self._debt(target, amm)[0] * frac, 10 ** 18)

    return unsafe_sub(max(debt, stablecoins), stablecoins)


@view
@external
def health(account: address, full: bool = False) -> int256:
    """
    @notice Returns position health normalized to 1e18 for the account.
            Liquidation starts when < 0, however devaluation of collateral doesn't cause liquidation
    """
    amm: LLAMMA = self.AMM
    return self._health(amm, account, self._debt(account, amm)[0], full, self.liquidation_discounts[account], amm.price_oracle())


@view
@external
def users_to_liquidate(_from: uint256=0, _limit: uint256=0) -> DynArray[Position, 1000]:
    """
    @notice Returns a dynamic array of users who can be "hard-liquidated".
            This method is designed for convenience of liquidation bots.
    @param _from Loan index to start iteration from
    @param _limit Number of loans to look over
    @return Dynamic array with detailed info about positions of users
    """
    amm: LLAMMA = self.AMM
    price: uint256 = amm.price_oracle()
    n_loans: uint256 = self.n_loans
    limit: uint256 = _limit
    if _limit == 0:
        limit = n_loans
    ix: uint256 = _from
    out: DynArray[Position, 1000] = []
    for i in range(10**6):
        if ix >= n_loans or i == limit:
            break
        account: address = self.loans[ix]
        debt: uint256 = self._debt(account, amm)[0]
        health: int256 = self._health(amm, account, debt, True, self.liquidation_discounts[account], price)
        if health < 0:
            xy: uint256[2] = amm.get_sum_xy(account)
            out.append(Position({
                account: account,
                x: xy[0],
                y: xy[1],
                debt: debt,
                health: health
            }))
        ix += 1
    return out


@view
@external
def amm_price() -> uint256:
    """
    @notice Current price from the AMM
    """
    return self.AMM.get_p()


@view
@external
def user_prices(account: address) -> uint256[2]:  # Upper, lower
    """
    @notice Lowest price of the lower band and highest price of the upper band the account has deposit in the AMM
    @param account User address
    @return (upper_price, lower_price)
    """
    amm: LLAMMA = self.AMM
    if not amm.has_liquidity(account):
        return [0, 0]
    ns: int256[2] = amm.read_user_tick_numbers(account) # ns[1] > ns[0]
    return [amm.p_oracle_up(ns[0]), amm.p_oracle_down(ns[1])]


@view
@external
def user_state(account: address) -> uint256[4]:
    """
    @notice Return the account state in one call
    @param account User to return the state for
    @return (collateral, stablecoin, debt, n_bands)
    """
    amm: LLAMMA = self.AMM
    xy: uint256[2] = amm.get_sum_xy(account)
    ns: int256[2] = amm.read_user_tick_numbers(account) # ns[1] > ns[0]
    return [xy[1], xy[0], self._debt(account, amm)[0], convert(unsafe_add(unsafe_sub(ns[1], ns[0]), 1), uint256)]


@view
@external
def health_calculator(account: address, coll_amount: int256, debt_amount: int256, full: bool, n_bands: uint256 = 0) -> int256:
    """
    @notice Health predictor in case account changes the debt or collateral
    @param account Address of the account
    @param coll_amount Change in collateral amount (signed)
    @param debt_amount Change in debt amount (signed)
    @param full Whether it's a 'full' health or not
    @param n_bands Number of bands in case loan doesn't yet exist
    @return Signed health value
    """
    amm: LLAMMA = self.AMM
    price: uint256 = amm.price_oracle()
    ns: int256[2] = amm.read_user_tick_numbers(account)
    debt: int256 = convert(self._debt(account, amm)[0], int256)
    n: uint256 = n_bands
    ld: int256 = 0
    if debt != 0:
        ld = convert(self.liquidation_discounts[account], int256)
        n = convert(unsafe_add(unsafe_sub(ns[1], ns[0]), 1), uint256)
    else:
        ld = convert(self.liquidation_discount, int256)
        ns[0] = max_value(int256)  # This will trigger a "re-deposit"

    n1: int256 = 0
    collateral: int256 = 0
    x_eff: int256 = 0
    debt += debt_amount
    assert debt > 0, "DFM:M Non-positive debt"

    active_band: int256 = amm.active_band_with_skip()

    if ns[0] > active_band:  # re-deposit
        collateral = convert(amm.get_sum_xy(account)[1], int256) + coll_amount
        n1 = self._calculate_debt_n1(amm, convert(collateral, uint256), convert(debt, uint256), n, price)
        collateral *= convert(self.COLLATERAL_PRECISION, int256)  # now has 18 decimals
    else:
        n1 = ns[0]
        x_eff = convert(amm.get_x_down(account) * 10**18, int256)

    p0: int256 = convert(amm.p_oracle_up(n1), int256)
    if ns[0] > active_band:
        x_eff = convert(self.get_y_effective(convert(collateral, uint256), n, 0), int256) * p0

    health: int256 = unsafe_div(x_eff, debt)
    health = health - unsafe_div(health * ld, 10**18) - 10**18

    if full:
        if n1 > active_band:  # We are not in liquidation mode
            p_diff: int256 = max(p0, convert(price, int256)) - p0
            if p_diff > 0:
                health += unsafe_div(p_diff * collateral, debt)

    return health


@view
@external
def pending_account_state_calculator(
    account: address,
    coll_change: int256,
    debt_change: int256,
    num_bands: uint256
) -> (uint256, uint256[2], int256, int256[2]):
    """
    @notice Get adjusted market data when `account` opens or adjusts a loan
    @dev Called via `MarketController.get_pending_market_state_for_account`
    @return New account debt, collateral balances, health, bands
    """
    amm: LLAMMA = self.AMM
    price: uint256 = amm.price_oracle()
    debt: int256 = convert(self._debt(account, amm)[0], int256)
    n_bands: uint256 = num_bands
    ld: int256 = 0
    ns: int256[2] = empty(int256[2])
    if debt != 0:
        ns = amm.read_user_tick_numbers(account)
        ld = convert(self.liquidation_discounts[account], int256)
        n_bands = convert(unsafe_add(unsafe_sub(ns[1], ns[0]), 1), uint256)
    else:
        ld = convert(self.liquidation_discount, int256)
        ns[0] = max_value(int256)  # This will trigger a "re-deposit"
        assert n_bands >= MIN_TICKS and n_bands <= MAX_TICKS, "DFM:M Invalid num_bands"

    n1: int256 = 0
    collateral: int256 = 0
    x_eff: int256 = 0
    debt += debt_change
    assert debt > 0, "DFM:M Non-positive debt"

    active_band: int256 = amm.active_band_with_skip()

    xy: uint256[2] = amm.get_sum_xy(account)
    if ns[0] > active_band:  # re-deposit
        collateral = convert(xy[1], int256) + coll_change
        xy[1] = convert(collateral, uint256)
        n1 = self._calculate_debt_n1(amm, convert(collateral, uint256), convert(debt, uint256), n_bands, price)
        collateral *= convert(self.COLLATERAL_PRECISION, int256)  # now has 18 decimals
    else:
        assert debt_change <= 0 and coll_change == 0, "DFM:M Unhealthy loan, repay only"
        n1 = ns[0]
        x_eff = convert(amm.get_x_down(account) * 10**18, int256)

    p0: int256 = convert(amm.p_oracle_up(n1), int256)
    if ns[0] > active_band:
        x_eff = convert(self.get_y_effective(convert(collateral, uint256), n_bands, 0), int256) * p0

    health: int256 = unsafe_div(x_eff, debt)
    health = health - unsafe_div(health * ld, 10**18) - 10**18

    if n1 > active_band:  # We are not in liquidation mode
        p_diff: int256 = max(p0, convert(price, int256)) - p0
        if p_diff > 0:
            health += unsafe_div(p_diff * collateral, debt)

    return convert(debt, uint256), xy, health, [n1, n1 + convert(n_bands, int256) - 1]


# --- owner-only nonpayable functions ---

@external
def set_amm_fee(fee: uint256):
    """
    @notice Set the AMM fee
    @param fee The fee which should be no higher than MAX_FEE
    """
    self._assert_only_owner()
    assert fee <= MAX_FEE and fee >= MIN_FEE, "DFM:M Invalid AMM fee"
    self.AMM.set_fee(fee)

    log SetAmmFee(fee)


@external
def set_amm_admin_fee(fee: uint256):
    """
    @notice Set AMM's admin fee
    @param fee New admin fee (not higher than MAX_ADMIN_FEE)
    """
    self._assert_only_owner()
    assert fee <= MAX_ADMIN_FEE, "DFM:M Fee too high"
    self.AMM.set_admin_fee(fee)

    log SetAmmAdminFee(fee)


@external
def set_borrowing_discounts(loan_discount: uint256, liquidation_discount: uint256):
    """
    @notice Set discounts at which we can borrow (defines max LTV) and where bad liquidation starts
    @param loan_discount Discount which defines LTV
    @param liquidation_discount Discount where bad liquidation starts
    """
    self._assert_only_owner()
    assert loan_discount > liquidation_discount, "DFM:M loan discount<liq discount"
    assert liquidation_discount >= MIN_LIQUIDATION_DISCOUNT, "DFM:M liq discount too low"
    assert loan_discount <= MAX_LOAN_DISCOUNT, "DFM:M Loan discount too high"
    self.liquidation_discount = liquidation_discount
    self.loan_discount = loan_discount
    log SetBorrowingDiscounts(loan_discount, liquidation_discount)


@external
def set_liquidity_mining_hook(hook: address):
    """
    @notice Set liquidity mining callback
    """
    self._assert_only_owner()
    self.AMM.set_liquidity_mining_hook(hook)
    log SetLiquidityMiningHook(hook)


@external
def set_debt_ceiling(debt_ceiling: uint256):
    """
    @notice Set debt ceiling
    @param debt_ceiling New debt ceiling
    """
    self._assert_only_owner()
    self.debt_ceiling = debt_ceiling
    log SetDebtCeiling(debt_ceiling)


@external
def set_oracle(oracle: PriceOracle):
    self._assert_only_owner()
    p: uint256 = oracle.price()
    assert p > 0, "DFM:M p == 0"
    assert oracle.price_w() == p, "DFM:M p != price_w"
    self.AMM.set_oracle(oracle)
    log SetPriceOracle(oracle)


# --- controller-only nonpayable functions ---

@external
def create_loan(account: address, coll_amount: uint256, debt_amount: uint256, n_bands: uint256) -> uint256:
    """
    @notice Create loan
    @dev Only callable by the controller. End users access this functionality
         by calling `MainController.create_loan`.
    @param account Account to open the loan for
    @param coll_amount Amount of collateral to use
    @param debt_amount Stablecoin amount to mint
    @param n_bands Number of bands to deposit into (to do autoliquidation-deliquidation),
           can be from MIN_TICKS to MAX_TICKS
    @return Increase in total debt (including accrued interest since last interaction)
    """
    self._assert_only_controller()

    assert self.loan[account].initial_debt == 0, "DFM:M Loan already exists"
    assert n_bands > MIN_TICKS-1, "DFM:M Need more ticks"
    assert n_bands < MAX_TICKS+1, "DFM:M Need less ticks"

    amm: LLAMMA = self.AMM
    n1: int256 = self._calculate_debt_n1(amm, coll_amount, debt_amount, n_bands, amm.price_oracle_w())
    n2: int256 = n1 + convert(n_bands - 1, int256)

    rate_mul: uint256 = amm.get_rate_mul()
    self.loan[account] = Loan({initial_debt: debt_amount, rate_mul: rate_mul})
    liquidation_discount: uint256 = self.liquidation_discount
    self.liquidation_discounts[account] = liquidation_discount

    n_loans: uint256 = self.n_loans
    self.loans[n_loans] = account
    self.loan_ix[account] = n_loans
    self.n_loans = unsafe_add(n_loans, 1)

    debt_increase: uint256 = self._increase_total_debt(debt_amount, rate_mul)

    amm.deposit_range(account, coll_amount, n1, n2)

    log UserState(account, coll_amount, debt_amount, n1, n2, liquidation_discount)

    return debt_increase


@external
def adjust_loan(account: address, coll_change: int256, debt_change: int256, max_active_band: int256) -> int256:
    """
    @notice Adjust collateral/debt amounts for an existing loan
    @dev Only callable by the controller. End users access this functionality
         by calling `MainController.adjust_loan`.
    @param account Account to adjust the loan for
    @param coll_change Collateral adjustment amount. A positive value deposits, negative withdraws.
    @param debt_change Debt adjustment amount. A positive value mints, negative burns.
    @param max_active_band Maximum active band (used to prevent front-running)
    @return Change in total debt (including accrued interest since last interaction)
    """
    self._assert_only_controller()

    amm: LLAMMA = self.AMM
    price: uint256 = amm.price_oracle_w()
    account_debt: uint256 = 0
    rate_mul: uint256 = 0
    account_debt, rate_mul = self._debt(account, amm)
    assert account_debt > 0, "DFM:M Loan doesn't exist"
    account_debt = self._uint_plus_int(account_debt, debt_change)
    assert account_debt > 0, "DFM:M No remaining debt"

    ns: int256[2] = amm.read_user_tick_numbers(account)
    size: uint256 = convert(unsafe_add(unsafe_sub(ns[1], ns[0]), 1), uint256)

    active_band: int256 = amm.active_band_with_skip()
    assert active_band <= max_active_band, "DFM:M band > max_active_band"

    if ns[0] > active_band:
        # Not in liquidation - can move bands
        coll_amount: uint256 = amm.withdraw(account, 10**18)[1]

        coll_amount = self._uint_plus_int(coll_amount, coll_change)

        n1: int256 = self._calculate_debt_n1(amm, coll_amount, account_debt, size, price)
        n2: int256 = n1 + unsafe_sub(ns[1], ns[0])
        amm.deposit_range(account, coll_amount, n1, n2)
        liquidation_discount: uint256 = self.liquidation_discount
        self.liquidation_discounts[account] = liquidation_discount
        log UserState(account, coll_amount, account_debt, n1, n2, liquidation_discount)
    else:
        assert debt_change < 0 and coll_change == 0, "DFM:M Unhealthy loan, repay only"
        # Underwater - cannot move band but can avoid a bad liquidation
        log UserState(account, max_value(uint256), account_debt, ns[0], ns[1], self.liquidation_discounts[account])

    self.loan[account] = Loan({initial_debt: account_debt, rate_mul: rate_mul})
    if debt_change < 0:
        return self._decrease_total_debt(convert(-debt_change, uint256), rate_mul)
    else:
        return convert(self._increase_total_debt(convert(debt_change, uint256), rate_mul), int256)


@external
def close_loan(account: address) -> (int256, uint256, uint256[2]):
    """
    @notice Close an existing loan
    @dev Only callable by the controller. End users access this functionality
         by calling `MainController.close_loan`.
    @param account The account to close the loan for
    @return Change in total debt (including accrued interest since last interaction)
            Debt amount to be repaid
            (debt, collateral) amounts withdrawn from AMM
    """
    self._assert_only_controller()

    amm: LLAMMA = self.AMM
    account_debt: uint256 = 0
    rate_mul: uint256 = 0
    account_debt, rate_mul = self._debt(account, amm)
    assert account_debt > 0, "DFM:M Loan doesn't exist"

    xy: uint256[2] = amm.withdraw(account, 10**18)

    self.loan[account] = Loan({initial_debt: 0, rate_mul: 0})
    debt_adjustment: int256 = self._decrease_total_debt(account_debt, rate_mul)
    debt_adjustment -= self._remove_from_list(account)
    log UserState(account, 0, 0, 0, 0, 0)

    return debt_adjustment, account_debt, xy


@external
def liquidate(caller: address, target: address, min_x: uint256, frac: uint256) -> (int256, uint256, uint256[2]):
    """
    @notice Perform a bad liquidation (or self-liquidation) of account if health is not good
    @dev Only callable by the controller. End users access this functionality
         by calling `MainController.liquidate`.
    @param caller Address of the account performing the liquidation
    @param target Address of the account to be liquidated
    @param min_x Minimal amount of stablecoin to receive (to avoid liquidators being sandwiched)
    @param frac Fraction to liquidate; 100% = 10**18
    @return Change in total debt (including accrued interest since last interaction)
            Debt amount to be repaid
            (debt, collateral) amounts withdrawn from AMM
    """
    self._assert_only_controller()

    health_limit: uint256 = 0
    if target != caller:
        health_limit = self.liquidation_discounts[target]

    amm: LLAMMA = self.AMM
    price: uint256 = amm.price_oracle_w()
    debt: uint256 = 0
    rate_mul: uint256 = 0
    debt, rate_mul = self._debt(target, amm)

    if health_limit != 0:
        assert self._health(amm, target, debt, True, health_limit, price) < 0, "DFM:M Not enough rekt"

    final_debt: uint256 = debt
    debt = unsafe_div(debt * frac, 10**18)
    assert debt > 0, "DFM:M No Debt"
    final_debt = unsafe_sub(final_debt, debt)

    # Withdraw sender's stablecoin and collateral to our contract
    # When frac is set - we withdraw a bit less for the same debt fraction
    # f_remove = ((1 + h/2) / (1 + h) * (1 - frac) + frac) * frac
    # where h is health limit.
    # This is less than full h discount but more than no discount
    xy: uint256[2] = amm.withdraw(target, self._get_f_remove(frac, health_limit))  # [stable, collateral]

    # x increase in same block -> price up -> good
    # x decrease in same block -> price down -> bad
    assert xy[0] >= min_x, "DFM:M Slippage"

    self.loan[target] = Loan({initial_debt: final_debt, rate_mul: rate_mul})
    debt_adjustment: int256 = self._decrease_total_debt(debt, rate_mul)

    if final_debt == 0:
        log UserState(target, 0, 0, 0, 0, 0)  # Not logging partial removeal b/c we have not enough info
        debt_adjustment -= self._remove_from_list(target)

    return debt_adjustment, debt, xy


@external
def collect_fees() -> (uint256, uint256[2]):
    """
    @notice Collect the fees charged as interest
    @dev Only callable by the controller. End users access this functionality
         by calling `MainController.collect_fees`.
    @return Increase in total debt (accrued interest since last interaction)
            (debt, collateral) amounts taken from from AMM as fees
    """
    self._assert_only_controller()

    # AMM-based fees
    amm: LLAMMA = self.AMM
    xy: uint256[2] = amm.reset_admin_fees()

    # Borrowing-based fees
    # Total debt increases here, but we intentionally do not enforce `debt_ceiling`
    rate_mul: uint256 = amm.get_rate_mul()
    debt_increase: uint256 = self._increase_total_debt(0, rate_mul)

    return debt_increase, xy


# --- internal functions ---

@view
@internal
def _assert_only_owner():
    assert msg.sender == CORE_OWNER.owner(), "DFM:M Only owner"


@view
@internal
def _assert_only_controller():
    assert msg.sender == CONTROLLER, "DFM:M Only controller"


@pure
@internal
def _log_2(x: uint256) -> uint256:
    """
    @dev An `internal` helper function that returns the log in base 2
         of `x`, following the selected rounding direction.
    @notice Note that it returns 0 if given 0. The implementation is
            inspired by OpenZeppelin's implementation here:
            https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/Math.sol.
            This code is taken from snekmate.
    @param x The 32-byte variable.
    @return uint256 The 32-byte calculation result.
    """
    value: uint256 = x
    result: uint256 = empty(uint256)

    # The following lines cannot overflow because we have the well-known
    # decay behaviour of `log_2(max_value(uint256)) < max_value(uint256)`.
    if (x >> 128 != empty(uint256)):
        value = x >> 128
        result = 128
    if (value >> 64 != empty(uint256)):
        value = value >> 64
        result = unsafe_add(result, 64)
    if (value >> 32 != empty(uint256)):
        value = value >> 32
        result = unsafe_add(result, 32)
    if (value >> 16 != empty(uint256)):
        value = value >> 16
        result = unsafe_add(result, 16)
    if (value >> 8 != empty(uint256)):
        value = value >> 8
        result = unsafe_add(result, 8)
    if (value >> 4 != empty(uint256)):
        value = value >> 4
        result = unsafe_add(result, 4)
    if (value >> 2 != empty(uint256)):
        value = value >> 2
        result = unsafe_add(result, 2)
    if (value >> 1 != empty(uint256)):
        result = unsafe_add(result, 1)

    return result


@internal
@pure
def wad_ln(x: uint256) -> int256:
    """
    @dev Calculates the natural logarithm of a signed integer with a
         precision of 1e18.
    @notice Note that it returns 0 if given 0. Furthermore, this function
            consumes about 1,400 to 1,650 gas units depending on the value
            of `x`. The implementation is inspired by Remco Bloemen's
            implementation under the MIT license here:
            https://xn--2-umb.com/22/exp-ln.
            This code is taken from snekmate.
    @param x The 32-byte variable.
    @return int256 The 32-byte calculation result.
    """
    value: int256 = convert(x, int256)

    assert x > 0

    # We want to convert `x` from "10 ** 18" fixed point to "2 ** 96"
    # fixed point. We do this by multiplying by "2 ** 96 / 10 ** 18".
    # But since "ln(x * C) = ln(x) + ln(C)" holds, we can just do nothing
    # here and add "ln(2 ** 96 / 10 ** 18)" at the end.

    # Reduce the range of `x` to "(1, 2) * 2 ** 96".
    # Also remember that "ln(2 ** k * x) = k * ln(2) + ln(x)" holds.
    k: int256 = unsafe_sub(convert(self._log_2(x), int256), 96)
    # Note that to circumvent Vyper's safecast feature for the potentially
    # negative expression `value <<= uint256(159 - k)`, we first convert the
    # expression `value <<= uint256(159 - k)` to `bytes32` and subsequently
    # to `uint256`. Remember that the EVM default behaviour is to use two's
    # complement representation to handle signed integers.
    value = convert(convert(convert(value << convert(unsafe_sub(159, k), uint256), bytes32), uint256) >> 159, int256)

    # Evaluate using a "(8, 8)"-term rational approximation. Since `p` is monic,
    # we will multiply by a scaling factor later.
    p: int256 = unsafe_add(unsafe_mul(unsafe_add(value, 3_273_285_459_638_523_848_632_254_066_296), value) >> 96, 24_828_157_081_833_163_892_658_089_445_524)
    p = unsafe_add(unsafe_mul(p, value) >> 96, 43_456_485_725_739_037_958_740_375_743_393)
    p = unsafe_sub(unsafe_mul(p, value) >> 96, 11_111_509_109_440_967_052_023_855_526_967)
    p = unsafe_sub(unsafe_mul(p, value) >> 96, 45_023_709_667_254_063_763_336_534_515_857)
    p = unsafe_sub(unsafe_mul(p, value) >> 96, 14_706_773_417_378_608_786_704_636_184_526)
    p = unsafe_sub(unsafe_mul(p, value), 795_164_235_651_350_426_258_249_787_498 << 96)

    # We leave `p` in the "2 ** 192" base so that we do not have to scale it up
    # again for the division. Note that `q` is monic by convention.
    q: int256 = unsafe_add(unsafe_mul(unsafe_add(value, 5_573_035_233_440_673_466_300_451_813_936), value) >> 96, 71_694_874_799_317_883_764_090_561_454_958)
    q = unsafe_add(unsafe_mul(q, value) >> 96, 283_447_036_172_924_575_727_196_451_306_956)
    q = unsafe_add(unsafe_mul(q, value) >> 96, 401_686_690_394_027_663_651_624_208_769_553)
    q = unsafe_add(unsafe_mul(q, value) >> 96, 204_048_457_590_392_012_362_485_061_816_622)
    q = unsafe_add(unsafe_mul(q, value) >> 96, 31_853_899_698_501_571_402_653_359_427_138)
    q = unsafe_add(unsafe_mul(q, value) >> 96, 909_429_971_244_387_300_277_376_558_375)

    # It is known that the polynomial `q` has no zeros in the domain.
    # No scaling is required, as `p` is already "2 ** 96" too large. Also,
    # `r` is in the range "(0, 0.125) * 2 ** 96" after the division.
    r: int256 = unsafe_div(p, q)

    # To finalise the calculation, we have to proceed with the following steps:
    #   - multiply by the scaling factor "s = 5.549...",
    #   - add "ln(2 ** 96 / 10 ** 18)",
    #   - add "k * ln(2)", and
    #   - multiply by "10 ** 18 / 2 ** 96 = 5 ** 18 >> 78".
    # In order to perform the most gas-efficient calculation, we carry out all
    # these steps in one expression.
    return unsafe_add(unsafe_add(unsafe_mul(r, 1_677_202_110_996_718_588_342_820_967_067_443_963_516_166),\
           unsafe_mul(k, 16_597_577_552_685_614_221_487_285_958_193_947_469_193_820_559_219_878_177_908_093_499_208_371)),\
           600_920_179_829_731_861_736_702_779_321_621_459_595_472_258_049_074_101_567_377_883_020_018_308) >> 174


@view
@internal
def _debt(account: address, amm: LLAMMA) -> (uint256, uint256):
    """
    @notice Get the value of debt without changing the state
    @param account User address
    @return Value of debt
    """
    rate_mul: uint256 = amm.get_rate_mul()
    loan: Loan = self.loan[account]
    if loan.initial_debt == 0:
        return (0, rate_mul)
    else:
        return (loan.initial_debt * rate_mul / loan.rate_mul, rate_mul)


@view
@internal
def _get_total_debt() -> uint256:
    rate_mul: uint256 = self.AMM.get_rate_mul()
    loan: Loan = self._total_debt
    return loan.initial_debt * rate_mul / loan.rate_mul


@view
@internal
def get_y_effective(collateral: uint256, n_bands: uint256, discount: uint256) -> uint256:
    """
    @notice Intermediary method which calculates y_effective defined as x_effective / p_base,
            however discounted by loan_discount.
            x_effective is an amount which can be obtained from collateral when liquidating
    @param collateral Amount of collateral to get the value for
    @param n_bands Number of bands the deposit is made into
    @param discount Loan discount at 1e18 base (e.g. 1e18 == 100%)
    @return y_effective
    """
    # x_effective = sum_{i=0..N-1}(y / N * p(n_{n1+i})) =
    # = y / N * p_oracle_up(n1) * sqrt((A - 1) / A) * sum_{0..N-1}(((A-1) / A)**k)
    # === d_y_effective * p_oracle_up(n1) * sum(...) === y_effective * p_oracle_up(n1)
    # d_y_effective = y / N / sqrt(A / (A - 1))
    # d_y_effective: uint256 = collateral * unsafe_sub(10**18, discount) / (SQRT_BAND_RATIO * N)
    # Make some extra discount to always deposit lower when we have DEAD_SHARES rounding
    d_y_effective: uint256 = collateral * unsafe_sub(
        10**18, min(discount + unsafe_div((DEAD_SHARES * 10**18), max(unsafe_div(collateral, n_bands), DEAD_SHARES)), 10**18)
    ) / unsafe_mul(SQRT_BAND_RATIO, n_bands)
    y_effective: uint256 = d_y_effective
    for i in range(1, MAX_TICKS):
        if i == n_bands:
            break
        d_y_effective = unsafe_div(d_y_effective * Aminus1, A)
        y_effective = unsafe_add(y_effective, d_y_effective)
    return y_effective


@view
@internal
def _calculate_debt_n1(amm: LLAMMA, collateral: uint256, debt: uint256, n_bands: uint256, price: uint256) -> int256:
    """
    @notice Calculate the upper band number for the deposit to sit in to support
            the given debt. Reverts if requested debt is too high.
    @param collateral Amount of collateral (at its native precision)
    @param debt Amount of requested debt
    @param n_bands Number of bands to deposit into
    @return Upper band n1 (n1 <= n2) to deposit into. Signed integer
    """
    assert debt > 0, "DFM:M No loan"
    n0: int256 = amm.active_band()
    p_base: uint256 = amm.p_oracle_up(n0)

    # x_effective = y / N * p_oracle_up(n1) * sqrt((A - 1) / A) * sum_{0..N-1}(((A-1) / A)**k)
    # === d_y_effective * p_oracle_up(n1) * sum(...) === y_effective * p_oracle_up(n1)
    # d_y_effective = y / N / sqrt(A / (A - 1))
    y_effective: uint256 = self.get_y_effective(collateral * self.COLLATERAL_PRECISION, n_bands, self.loan_discount)
    # p_oracle_up(n1) = base_price * ((A - 1) / A)**n1

    # We borrow up until min band touches p_oracle,
    # or it touches non-empty bands which cannot be skipped.
    # We calculate required n1 for given (collateral, debt),
    # and if n1 corresponds to price_oracle being too high, or unreachable band
    # - we revert.

    # n1 is band number based on adiabatic trading, e.g. when p_oracle ~ p
    y_effective = unsafe_div(y_effective * p_base, debt + 1)  # Now it's a ratio

    # n1 = floor(log(y_effective) / self.logAratio)
    # EVM semantics is not doing floor unlike Python, so we do this
    assert y_effective > 0, "DFM:M Amount too low"
    n1: int256 = self.wad_ln(y_effective)
    if n1 < 0:
        n1 -= unsafe_sub(LOGN_A_RATIO, 1)  # This is to deal with vyper's rounding of negative numbers
    n1 = unsafe_div(n1, LOGN_A_RATIO)

    n1 = min(n1, 1024 - convert(n_bands, int256)) + n0
    if n1 <= n0:
        assert amm.can_skip_bands(n1 - 1), "DFM:M Debt too high"

    # Let's not rely on active_band corresponding to price_oracle:
    # this will be not correct if we are in the area of empty bands
    assert amm.p_oracle_up(n1) < price, "DFM:M Debt too high"

    return n1


@view
@internal
def max_p_base() -> uint256:
    """
    @notice Calculate max base price including skipping bands
    """
    amm: LLAMMA = self.AMM
    p_oracle: uint256 = amm.price_oracle()
    # Should be correct unless price changes suddenly by MAX_P_BASE_BANDS+ bands
    n1: int256 = self.wad_ln(amm.get_base_price() * 10**18 / p_oracle)
    if n1 < 0:
        n1 -= LOGN_A_RATIO - 1  # This is to deal with vyper's rounding of negative numbers
    n1 = unsafe_div(n1, LOGN_A_RATIO) + MAX_P_BASE_BANDS
    n_min: int256 = amm.active_band_with_skip()
    n1 = max(n1, n_min + 1)
    p_base: uint256 = amm.p_oracle_up(n1)

    for i in range(MAX_SKIP_TICKS + 1):
        n1 -= 1
        if n1 <= n_min:
            break
        p_base_prev: uint256 = p_base
        p_base = unsafe_div(p_base * A, Aminus1)
        if p_base > p_oracle:
            return p_base_prev

    return p_base


@pure
@internal
def _uint_plus_int(initial: uint256, adjustment: int256) -> uint256:
    if adjustment < 0:
        return initial - convert(-adjustment, uint256)
    else:
        return initial + convert(adjustment, uint256)


@view
@internal
def _health(amm: LLAMMA, account: address, debt: uint256, full: bool, liquidation_discount: uint256, price: uint256) -> int256:
    """
    @notice Returns position health normalized to 1e18 for the account.
            Liquidation starts when < 0, however devaluation of collateral doesn't cause liquidation
    @param account User address to calculate health for
    @param debt The amount of debt to calculate health for
    @param full Whether to take into account the price difference above the highest account's band
    @param liquidation_discount Liquidation discount to use (can be 0)
    @return Health: > 0 = good.
    """
    assert debt > 0, "DFM:M Loan doesn't exist"
    health: int256 = 10**18 - convert(liquidation_discount, int256)
    health = unsafe_div(convert(amm.get_x_down(account), int256) * health, convert(debt, int256)) - 10**18

    if full:
        ns0: int256 = amm.read_user_tick_numbers(account)[0] # ns[1] > ns[0]
        if ns0 > amm.active_band():  # We are not in liquidation mode
            p_up: uint256 = amm.p_oracle_up(ns0)
            if price > p_up:
                health += convert(unsafe_div(unsafe_sub(price, p_up) * amm.get_sum_xy(account)[1] * self.COLLATERAL_PRECISION, debt), int256)

    return health


@view
@internal
def _get_f_remove(frac: uint256, health_limit: uint256) -> uint256:
    # f_remove = ((1 + h / 2) / (1 + h) * (1 - frac) + frac) * frac
    f_remove: uint256 = 10 ** 18
    if frac < 10 ** 18:
        f_remove = unsafe_div(unsafe_mul(unsafe_add(10 ** 18, unsafe_div(health_limit, 2)), unsafe_sub(10 ** 18, frac)), unsafe_add(10 ** 18, health_limit))
        f_remove = unsafe_div(unsafe_mul(unsafe_add(f_remove, frac), frac), 10 ** 18)

    return f_remove


@internal
def _increase_total_debt(amount: uint256, rate_mul: uint256) -> uint256:
    stored_debt: uint256 = self._total_debt.initial_debt
    total_debt: uint256 = stored_debt * rate_mul / self._total_debt.rate_mul
    if amount > 0:
        total_debt += amount
        assert total_debt <= self.debt_ceiling, "DFM:M Exceeds debt ceiling"

    self._total_debt = Loan({initial_debt: total_debt, rate_mul: rate_mul})
    return total_debt - stored_debt


@internal
def _decrease_total_debt(amount: uint256, rate_mul: uint256) -> int256:
    stored_debt: uint256 = self._total_debt.initial_debt
    total_debt: uint256 = stored_debt * rate_mul / self._total_debt.rate_mul
    if total_debt > amount:
        total_debt = unsafe_sub(total_debt, amount)
    else:
        total_debt = 0

    self._total_debt = Loan({initial_debt: total_debt, rate_mul: rate_mul})
    return convert(total_debt, int256) - convert(stored_debt, int256)



@internal
def _remove_from_list(receiver: address) -> int256:
    last_loan_ix: uint256 = self.n_loans - 1
    loan_ix: uint256 = self.loan_ix[receiver]
    assert self.loans[loan_ix] == receiver  # dev: should never fail but safety first
    self.loan_ix[receiver] = 0
    if loan_ix < last_loan_ix:  # Need to replace
        last_loan: address = self.loans[last_loan_ix]
        self.loans[loan_ix] = last_loan
        self.loan_ix[last_loan] = loan_ix
    self.n_loans = last_loan_ix

    if last_loan_ix == 0:
        # if this was the last loan, zero the total debt to avoid rounding dust
        remaining: int256 = convert(self._total_debt.initial_debt, int256)
        self._total_debt.initial_debt = 0
        return remaining

    return 0