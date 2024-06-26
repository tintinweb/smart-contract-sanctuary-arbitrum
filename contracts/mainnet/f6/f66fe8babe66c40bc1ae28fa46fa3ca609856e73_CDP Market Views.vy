#pragma version 0.3.10
"""
@title CDP Market Views
@author defidotmoney
@license MIT
@notice Aggregate view methods intended for off-chain use
"""

from vyper.interfaces import ERC20


interface MainController:
    def markets(i: uint256) -> address: view
    def market_contracts(market: address) -> MarketContracts: view
    def global_market_debt_ceiling() -> uint256: view
    def total_debt() -> uint256: view
    def monetary_policies(i: uint256) -> MonetaryPolicy: view
    def on_create_loan_hook_adjustment(
        account: address,
        market: address,
        coll_amount: uint256,
        debt_amount: uint256,
    ) -> int256: view
    def on_adjust_loan_hook_adjustment(
        account: address,
        market: address,
        coll_change: int256,
        debt_change: int256
    ) -> int256: view
    def on_close_loan_hook_adjustment(account: address, market: address) -> int256: view
    def on_liquidate_hook_adjustment(caller: address, market: address, target: address) -> int256: view
    def max_borrowable(market: MarketOperator, coll_amount: uint256, n_bands: uint256) -> uint256: view

interface MarketOperator:
    def total_debt() -> uint256: view
    def pending_debt() -> uint256: view
    def debt_ceiling() -> uint256: view
    def debt(account: address) -> uint256: view
    def max_borrowable(collateral: uint256, n_bands: uint256) -> uint256: view
    def health(account: address, full: bool) -> int256: view
    def AMM() -> address: view
    def A() -> uint256: view
    def pending_account_state_calculator(
        account: address,
        coll_change: int256,
        debt_change: int256,
        num_bands: uint256
    ) -> (uint256, uint256, uint256, int256, int256[2]): view
    def users_to_liquidate(_from: uint256=0, _limit: uint256=0) -> DynArray[Position, 1000]: view
    def min_collateral(debt_amount: uint256, n_bands: uint256) -> uint256: view

interface AMM:
    def A() -> uint256: view
    def get_p() -> uint256: view
    def get_base_price() -> uint256: view
    def active_band() -> int256: view
    def active_band_with_skip() -> int256: view
    def p_oracle_up(n: int256) -> uint256: view
    def p_oracle_down(n: int256) -> uint256: view
    def read_user_tick_numbers(receiver: address) -> int256[2]: view
    def get_sum_xy(account: address) -> (uint256, uint256): view
    def get_x_down(account: address) -> uint256: view
    def get_rate_mul() -> uint256: view
    def price_oracle() -> uint256: view
    def can_skip_bands(n_end: int256) -> bool: view
    def admin_fees_x() -> uint256: view
    def admin_fees_y() -> uint256: view
    def has_liquidity(account: address) -> bool: view
    def bands_x(n: int256) -> uint256: view
    def bands_y(n: int256) -> uint256: view
    def rate() -> uint256: view
    def min_band() -> int256: view
    def max_band() -> int256: view

interface MonetaryPolicy:
    def rate(market: MarketOperator) -> uint256: view

interface PriceOracle:
    def price() -> uint256: view


struct MarketContracts:
    collateral: address
    amm: address
    mp_idx: uint256

struct Position:
    account: address
    x: uint256
    y: uint256
    debt: uint256
    health: int256

struct Band:
    band_num: int256
    price_range: uint256[2]
    coll_balance: uint256
    debt_balance: uint256

struct MarketState:
    total_debt: uint256
    total_coll: uint256
    debt_ceiling: uint256
    remaining_mintable: uint256
    oracle_price: uint256
    current_rate: uint256
    pending_rate: uint256

struct AccountState:
    market: MarketOperator
    account_debt: uint256
    amm_coll_balance: uint256
    amm_stable_balance: uint256
    health: int256
    bands: int256[2]
    coll_conversion_range: uint256[2]

struct PendingAccountState:
    account_debt: uint256
    amm_coll_balance: uint256
    amm_stable_balance: uint256
    health: int256
    bands: int256[2]
    coll_conversion_range: uint256[2]
    hook_debt_adjustment: int256

struct CloseLoanState:
    total_debt_repaid: uint256
    debt_burned: uint256
    debt_from_amm: uint256
    coll_withdrawn: uint256
    hook_debt_adjustment: int256

struct LiquidationState:
    account: address
    total_debt_repaid: uint256
    debt_burned: uint256
    debt_from_amm: uint256
    coll_received: uint256
    hook_debt_adjustment: int256

MAIN_CONTROLLER: public(immutable(MainController))


@external
def __init__(controller: MainController):
    MAIN_CONTROLLER = controller


@view
@external
def get_market_states(markets: DynArray[MarketOperator, 255]) -> DynArray[MarketState, 255]:
    """
    @notice Get information about the state of one or more markets
    @dev To calculate annualized interest rate: (1 + rate/1e18)**31536000 - 1
    @return Total debt,
            Total deposited collateral,
            Market debt ceiling,
            Remaining mintable debt,
            Oracle price (normalized to 1e18),
            Current interest rate per second,
            Pending interest rate (applied on the next interaction)
    """
    market_states: DynArray[MarketState, 255] = []

    global_ceiling: uint256 = MAIN_CONTROLLER.global_market_debt_ceiling()
    global_debt: uint256 = MAIN_CONTROLLER.total_debt()

    for market in markets:
        state: MarketState = empty(MarketState)
        c: MarketContracts = MAIN_CONTROLLER.market_contracts(market.address)

        if c.collateral != empty(address):
            state.total_debt = market.total_debt()
            state.total_coll = ERC20(c.collateral).balanceOf(c.amm)
            state.debt_ceiling = market.debt_ceiling()

            if state.debt_ceiling > state.total_debt:
                if global_ceiling > global_debt:
                    state.remaining_mintable = min(state.debt_ceiling - state.total_debt, global_ceiling - global_debt)

            state.oracle_price = AMM(c.amm).price_oracle()
            state.current_rate = AMM(c.amm).rate()
            state.pending_rate = MAIN_CONTROLLER.monetary_policies(c.mp_idx).rate(market)

        market_states.append(state)

    return market_states


@view
@external
def get_market_amm_bands(
    market: address,
    lower_band: int256=-2**255,
    num_bands: uint256=5000
) -> (DynArray[Band, 5000], int256[2]):
    """
    @notice Get information on a market's active AMM bands
    @param market Market address
    @param lower_band Lowest band to return data from. If the given
                      value is less than the lowest active AMM band,
                      the returned data will instead start from the
                      lowest active band.
    @param num_bands The number of bands to return data from. If
                     `lower_band + num_bands` is more than the total
                     active bands, the returned data will stop at
                     the highest active band.
    @return Dynamic array of band data:
             * band number
             * (band lowest price, band highest price)
             * collateral balance deposited at band (normalized to 1e18)
             * debt balance deposited at band
    @return (min active band, max active band)
    """
    c: MarketContracts = self._get_market_contracts_or_revert(market)
    amm: AMM = AMM(c.amm)
    min_band: int256 = amm.min_band()
    max_band: int256 = amm.max_band()
    n: int256 = max(lower_band, min_band)
    n_final: int256 = min(n + convert(num_bands, int256)-1, max_band)
    bands: DynArray[Band, 5000] = []
    for i in range(5000):
        if n > n_final:
            break
        bands.append(Band({
            band_num: n,
            price_range: [amm.p_oracle_down(n), amm.p_oracle_up(n)],
            coll_balance: amm.bands_y(n),
            debt_balance: amm.bands_x(n)}
        ))
        n = unsafe_add(n, 1)
    return bands, [min_band, max_band]


@view
@external
def get_market_states_for_account(
    account: address,
    markets: DynArray[MarketOperator, 255]
) -> DynArray[AccountState, 255]:
    """
    @notice Get information about the open loans for `account`
    @dev Results are filtered by markets where `account` has non-zero debt
    @return Market address,
            Account debt,
            AMM balances (collateral, stablecoin),
            Number of bands,
            Account health (liquidation is possible if health < 0),
            Liquidation price range (high, low)
    """
    account_states: DynArray[AccountState, 255] = []

    for market in markets:
        c: MarketContracts = MAIN_CONTROLLER.market_contracts(market.address)

        if c.collateral != empty(address):
            debt: uint256 = market.debt(account)
            if debt > 0:
                state: AccountState = empty(AccountState)
                state.market = market
                state.account_debt = debt
                amm: AMM = AMM(c.amm)
                state.amm_stable_balance, state.amm_coll_balance = amm.get_sum_xy(account)
                state.health = market.health(account, True)
                state.bands = amm.read_user_tick_numbers(account)
                state.coll_conversion_range = [amm.p_oracle_up(state.bands[0]), amm.p_oracle_down(state.bands[1])]
                account_states.append(state)

    return account_states


@view
@external
def get_pending_market_state_for_account(
    account: address,
    market: address,
    coll_change: int256,
    debt_change: int256,
    num_bands: uint256 = 0
) -> PendingAccountState:
    """
    @notice Get adjusted market data if `account` opens or adjusts a loan
    @param account Address opening or adjusting loan
    @param market Market of the loan being adjusted
    @param coll_change Collateral adjustment amount. A positive value deposits, negative withdraws.
    @param debt_change Debt adjustment amount. A positive value mints, negative burns.
    @param num_bands Number of bands. Ignored if there is already an existing loan.
    @return New account debt
            AMM balances (Collateral, stablecoin)
            Account health
            Bands (high, low)
            Liquidation price range (high, low)
            Debt adjustment applied by hooks
    """
    c: MarketContracts = self._get_market_contracts_or_revert(market)

    state: PendingAccountState = empty(PendingAccountState)
    debt: uint256 = MarketOperator(market).debt(account)
    assert convert(debt, int256) + debt_change > 0, "DFM:C Non-positive debt"

    if debt == 0:
        if coll_change == 0 and debt_change == 0:
            return state

        assert coll_change > 0 and debt_change > 0, "DFM:C 0 coll or debt"
        state.hook_debt_adjustment = MAIN_CONTROLLER.on_create_loan_hook_adjustment(
            account,
            market,
            convert(coll_change, uint256),
            convert(debt_change, uint256),
        )
    elif coll_change != 0 or debt_change != 0:
        state.hook_debt_adjustment = MAIN_CONTROLLER.on_adjust_loan_hook_adjustment(
            account,
            market,
            coll_change,
            debt_change,
        )

    debt_final: int256 = debt_change + state.hook_debt_adjustment
    (
        state.account_debt,
        state.amm_stable_balance,
        state.amm_coll_balance,
        state.health,
        state.bands
    ) = MarketOperator(market).pending_account_state_calculator(account, coll_change, debt_final, num_bands)
    amm: AMM = AMM(c.amm)
    state.coll_conversion_range = [amm.p_oracle_up(state.bands[0]), amm.p_oracle_down(state.bands[1])]

    return state


@view
@external
def get_close_loan_amounts(account: address, market: address) -> CloseLoanState:
    """
    @notice Get balance information related to closing a loan
    @param account The account to close the loan for
    @param market Market of the loan being closed
    @return Total debt repaid
            Stablecoin amount burned from `account` (balance required to close the loan)
            Stablecoin amount withdrawn from AMM (used toward repayment)
            Collateral amount received by `account` once loan is closed
            Debt adjustment amount applied by hooks
    """
    c: MarketContracts = self._get_market_contracts_or_revert(market)
    state: CloseLoanState = empty(CloseLoanState)
    debt: uint256 = MarketOperator(market).debt(account)

    if debt != 0:
        state.total_debt_repaid = debt
        state.hook_debt_adjustment = MAIN_CONTROLLER.on_close_loan_hook_adjustment(account, market)
        state.debt_from_amm, state.coll_withdrawn = AMM(c.amm).get_sum_xy(account)
        debt_to_burn: uint256 = self._uint_plus_int(debt, state.hook_debt_adjustment)
        if state.debt_from_amm < debt_to_burn:
            state.debt_burned = debt_to_burn - state.debt_from_amm

    return state


@view
@external
def get_liquidation_amounts(
    caller: address,
    market: address,
    start: uint256=0,
    limit: uint256=0
) -> DynArray[LiquidationState, 1000]:
    """
    @notice Get a list of liquidatable accounts and related data
    @param caller Caller address that will perform the liquidations
    @param market Market to check for liquidations
    @param start Loan index to start iteration from
    @param limit Number of loans to iterate over (leave as 0 for all)
    @return Array of detailed information about liquidatable positions:
                Address of liquidatable account
                Total debt to be repaid via liquidation
                Stablecoin amount burned from `caller` (balance required to perform liquidation)
                Stablecoin amount withdrawn from AMM (used toward liquidation)
                Collateral amount received by `caller` from liquidation
                Debt adjustment amount applied by hooks
    """
    self._get_market_contracts_or_revert(market)
    liquidatable_accounts: DynArray[Position, 1000] = MarketOperator(market).users_to_liquidate(start, limit)
    liquidation_states: DynArray[LiquidationState, 1000] = []

    for item in liquidatable_accounts:
        state: LiquidationState = empty(LiquidationState)
        state.account = item.account
        state.total_debt_repaid = item.debt
        state.hook_debt_adjustment = MAIN_CONTROLLER.on_liquidate_hook_adjustment(
            caller,
            market,
            state.account,
        )
        state.debt_from_amm = item.x
        state.coll_received = item.y
        debt_to_burn: uint256 = self._uint_plus_int(item.debt, state.hook_debt_adjustment)
        if state.debt_from_amm < debt_to_burn:
            state.debt_burned = debt_to_burn - state.debt_from_amm
        liquidation_states.append(state)

    return liquidation_states


@view
@external
def get_max_borrowable(market: MarketOperator, coll_amount: uint256, n_bands: uint256) -> uint256:
    """
    @notice Calculation of maximum which can be borrowed in the given market
    @param market Market where the loan will be taken
    @param coll_amount Collateral amount against which to borrow
    @param n_bands number of bands the collateral will be deposited over
    @return Maximum amount of stablecoin that can be borrowed
    """
    return MAIN_CONTROLLER.max_borrowable(market, coll_amount, n_bands)


@view
@external
def get_min_collateral(market: MarketOperator, debt_amount: uint256, n_bands: uint256) -> uint256:
    """
    @notice Calculate teh minimal amount of collateral required to support debt
    @param market Market where the loan will be taken
    @param debt_amount The debt to support
    @param n_bands Number of bands to deposit into
    @return Minimal collateral required
    """
    return market.min_collateral(debt_amount, n_bands)


@pure
@internal
def _uint_plus_int(initial: uint256, adjustment: int256) -> uint256:
    if adjustment < 0:
        return initial - convert(-adjustment, uint256)
    else:
        return initial + convert(adjustment, uint256)


@view
@internal
def _get_market_contracts_or_revert(market: address) -> MarketContracts:
    c: MarketContracts = MAIN_CONTROLLER.market_contracts(market)
    assert c.collateral != empty(address), "DFM Invalid market"

    return c