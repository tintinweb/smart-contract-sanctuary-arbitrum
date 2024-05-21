# @version 0.3.10
"""
@title CDP Main Controller
@author Curve.Fi (with edits by defidotmoney)
@license Copyright (c) Curve.Fi, 2020-2023 - all rights reserved
"""

interface ERC20:
    def mint(_to: address, _value: uint256) -> bool: nonpayable
    def burn(_to: address, _value: uint256) -> bool: nonpayable
    def transferFrom(_from: address, _to: address, _value: uint256) -> bool: nonpayable
    def transfer(_to: address, _value: uint256) -> bool: nonpayable

interface PriceOracle:
    def price() -> uint256: view
    def price_w() -> uint256: nonpayable

interface AMM:
    def initialize(
        operator: address,
        oracle: PriceOracle,
        collateral: address,
        _base_price: uint256,
        fee: uint256,
        admin_fee: uint256
    ): nonpayable
    def set_exchange_hook(hook: address): nonpayable
    def set_rate(rate: uint256) -> uint256: nonpayable
    def collateral_balance() -> uint256: view
    def price_oracle() -> uint256: view
    def rate() -> uint256: view
    def get_sum_xy(account: address) -> (uint256, uint256): view
    def read_user_tick_numbers(receiver: address) -> int256[2]: view
    def p_oracle_up(n: int256) -> uint256: view
    def p_oracle_down(n: int256) -> uint256: view
    def A() -> uint256: view

interface MarketOperator:
    def initialize(
        amm: address,
        collateral_token: address,
        debt_ceiling: uint256,
        loan_discount: uint256,
        liquidation_discount: uint256,
    ): nonpayable
    def total_debt() -> uint256: view
    def pending_debt() -> uint256: view
    def debt_ceiling() -> uint256: view
    def debt(account: address) -> uint256: view
    def max_borrowable(collateral: uint256, n_bands: uint256) -> uint256: view
    def health(account: address, full: bool) -> int256: view
    def collect_fees() -> (uint256, uint256[2]): nonpayable
    def create_loan(account: address, coll_amount: uint256, debt_amount: uint256, n_bands: uint256) -> uint256: nonpayable
    def adjust_loan(account: address, coll_amount: int256, debt_amount: int256, max_active_band: int256) -> int256: nonpayable
    def close_loan(account: address) -> (int256, uint256, uint256[2]): nonpayable
    def liquidate(caller: address, target: address, min_x: uint256, frac: uint256) -> (int256, uint256, uint256[2]): nonpayable
    def AMM() -> address: view
    def A() -> uint256: view
    def pending_account_state_calculator(
        account: address,
        coll_change: int256,
        debt_change: int256,
        num_bands: uint256
    ) -> (uint256, uint256, uint256, int256, int256[2]): view
    def users_to_liquidate(_from: uint256=0, _limit: uint256=0) -> DynArray[Position, 1000]: view

interface MonetaryPolicy:
    def rate(market: MarketOperator) -> uint256: view
    def rate_write(market: address) -> uint256: nonpayable

interface PegKeeper:
    def set_regulator(regulator: address): nonpayable

interface PegKeeperRegulator:
    def active_debt() -> uint256: view
    def get_peg_keepers_with_debt_ceilings() -> (DynArray[PegKeeper, 256], DynArray[uint256, 256]): view
    def init_migrate_peg_keepers(peg_keepers: DynArray[PegKeeper, 256], debt_ceilings: DynArray[uint256, 256]): nonpayable

interface CoreOwner:
    def owner() -> address: view
    def feeReceiver() -> address: view

interface ControllerHooks:
    def on_create_loan(account: address, market: address, coll_amount: uint256, debt_amount: uint256) -> int256: nonpayable
    def on_adjust_loan(account: address, market: address, coll_change: int256, debt_changet: int256) -> int256: nonpayable
    def on_close_loan(account: address, market: address, account_debt: uint256) -> int256: nonpayable
    def on_liquidation(caller: address, market: address, target: address, debt_liquidated: uint256) -> int256: nonpayable

interface AmmHooks:
    def before_collateral_out(amount: uint256): nonpayable
    def after_collateral_in(amount: uint256): nonpayable


event AddMarket:
    collateral: indexed(address)
    market: address
    amm: address
    mp_idx: uint256

event SetDelegateApproval:
    account: indexed(address)
    delegate: indexed(address)
    is_approved: bool

event SetImplementations:
    amm: address
    market: address

event SetMarketHooks:
    market: indexed(address)
    hookdata: DynArray[MarketHookData, MAX_HOOKS]

event SetAmmHooks:
    market: indexed(address)
    hooks: indexed(address)

event AddMonetaryPolicy:
    mp_idx: indexed(uint256)
    monetary_policy: MonetaryPolicy

event ChangeMonetaryPolicy:
    mp_idx: indexed(uint256)
    monetary_policy: MonetaryPolicy

event ChangeMonetaryPolicyForMarket:
    market: indexed(address)
    mp_idx: indexed(uint256)

event SetGlobalMarketDebtCeiling:
    debt_ceiling: uint256

event SetPegKeeperRegulator:
    regulator: address
    with_migration: bool

event CreateLoan:
    market: indexed(address)
    account: indexed(address)
    coll_amount: uint256
    debt_amount: uint256

event AdjustLoan:
    market: indexed(address)
    account: indexed(address)
    coll_adjustment: int256
    debt_adjustment: int256

event CloseLoan:
    market: indexed(address)
    account: indexed(address)
    coll_withdrawn: uint256
    debt_withdrawn: uint256
    debt_repaid: uint256

event LiquidateLoan:
    market: indexed(address)
    liquidator: indexed(address)
    account: indexed(address)
    coll_received: uint256
    debt_received: uint256
    debt_repaid: uint256

event CollectAmmFees:
    market: indexed(address)
    amm_coll_fees: uint256
    amm_debt_fees: uint256

event CollectFees:
    minted: uint256
    redeemed: uint256
    total_debt: uint256
    fee: uint256


struct MarketContracts:
    collateral: address
    amm: address
    mp_idx: uint256

struct Implementations:
    amm: address
    market_operator: address

struct Position:
    account: address
    x: uint256
    y: uint256
    debt: uint256
    health: int256

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
    liquidation_range: uint256[2]

struct PendingAccountState:
    account_debt: uint256
    amm_coll_balance: uint256
    amm_stable_balance: uint256
    health: int256
    bands: int256[2]
    liquidation_range: uint256[2]
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

struct MarketHookData:
    hooks: address
    active_hooks: bool[NUM_HOOK_IDS]


enum HookId:
    ON_CREATE_LOAN
    ON_ADJUST_LOAN
    ON_CLOSE_LOAN
    ON_LIQUIDATION


NUM_HOOK_IDS: constant(uint256) = 4
MAX_HOOKS: constant(uint256) = 4

# Limits
MIN_A: constant(uint256) = 2
MAX_A: constant(uint256) = 10000
MIN_FEE: constant(uint256) = 10**6  # 1e-12, still needs to be above 0
MAX_FEE: constant(uint256) = 10**17  # 10%
MAX_ADMIN_FEE: constant(uint256) = 10**18  # 100%
MAX_LOAN_DISCOUNT: constant(uint256) = 5 * 10**17
MIN_LIQUIDATION_DISCOUNT: constant(uint256) = 10**16
MAX_ACTIVE_BAND: constant(int256) = max_value(int256)

STABLECOIN: public(immutable(ERC20))
CORE_OWNER: public(immutable(CoreOwner))
peg_keeper_regulator: public(PegKeeperRegulator)

markets: public(DynArray[MarketOperator, 65536])
collaterals: public(DynArray[address, 65536])
collateral_markets: HashMap[address, DynArray[address, 256]]
market_contracts: public(HashMap[address, MarketContracts])
monetary_policies: public(MonetaryPolicy[256])
n_monetary_policies: public(uint256)

global_market_debt_ceiling: public(uint256)
total_debt: public(uint256)
minted: public(uint256)
redeemed: public(uint256)

isApprovedDelegate: public(HashMap[address, HashMap[address, bool]])

global_hooks: DynArray[uint256, MAX_HOOKS]
market_hooks: HashMap[address, DynArray[uint256, MAX_HOOKS]]
amm_hooks: HashMap[address, address]
hook_debt_adjustment: HashMap[address, uint256]
implementations: HashMap[uint256, Implementations]


@external
def __init__(
    core: CoreOwner,
    stable: ERC20,
    monetary_policies: DynArray[MonetaryPolicy, 10],
    debt_ceiling: uint256
):
    CORE_OWNER = core
    STABLECOIN = stable

    idx: uint256 = 0
    for mp in monetary_policies:
        self.monetary_policies[idx] = mp
        idx += 1
    self.n_monetary_policies = idx

    self.global_market_debt_ceiling = debt_ceiling
    log SetGlobalMarketDebtCeiling(debt_ceiling)


# --- external view functions ---

@view
@external
def owner() -> address:
    return CORE_OWNER.owner()


@view
@external
def get_market_count() -> uint256:
    return len(self.markets)


@view
@external
def get_collateral_count() -> uint256:
    return len(self.collaterals)


@view
@external
def get_all_markets() -> DynArray[MarketOperator, 65536]:
    return self.markets


@view
@external
def get_all_collaterals() -> DynArray[address, 65536]:
    return self.collaterals


@view
@external
def get_all_markets_for_collateral(collateral: address) -> DynArray[address, 256]:
    return self.collateral_markets[collateral]


@view
@external
def get_market(collateral: address, i: uint256 = 0) -> address:
    """
    @notice Get market address for collateral
    @dev Returns empty(address) if market does not exist
    @param collateral Address of collateral token
    @param i Iterate over several markets for collateral if needed
    """
    if i > len(self.collateral_markets[collateral]):
        return empty(address)
    return self.collateral_markets[collateral][i]


@view
@external
def get_amm(collateral: address, i: uint256 = 0) -> address:
    """
    @notice Get AMM address for collateral
    @dev Returns empty(address) if market does not exist
    @param collateral Address of collateral token
    @param i Iterate over several amms for collateral if needed
    """
    if i > len(self.collateral_markets[collateral]):
        return empty(address)
    market: address = self.collateral_markets[collateral][i]
    return self.market_contracts[market].amm


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

    for market in markets:
        state: MarketState = empty(MarketState)
        c: MarketContracts = self.market_contracts[market.address]

        if c.collateral != empty(address):
            state.total_debt = market.total_debt()
            state.total_coll = AMM(c.amm).collateral_balance()
            state.debt_ceiling = market.debt_ceiling()

            if state.debt_ceiling > state.total_debt:
                global_ceiling: uint256 = self.global_market_debt_ceiling
                global_debt: uint256 = self.total_debt
                if global_ceiling > global_debt:
                    state.remaining_mintable = min(state.debt_ceiling - state.total_debt, global_ceiling - global_debt)

            state.oracle_price = AMM(c.amm).price_oracle()
            state.current_rate = AMM(c.amm).rate()
            state.pending_rate = self.monetary_policies[c.mp_idx].rate(market)

        market_states.append(state)

    return market_states


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
            Account health (liquidation is possible at 0),
            Liquidation price range (high, low)
    """
    account_states: DynArray[AccountState, 255] = []

    for market in markets:
        c: MarketContracts = self.market_contracts[market.address]

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
                state.liquidation_range = [amm.p_oracle_up(state.bands[0]), amm.p_oracle_down(state.bands[1])]
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
    c: MarketContracts = self._get_contracts(market)
    state: PendingAccountState = empty(PendingAccountState)
    debt: uint256 = MarketOperator(market).debt(account)
    assert convert(debt, int256) + debt_change > 0, "DFM:C Negative debt"

    if debt == 0:
        if coll_change == 0 and debt_change == 0:
            return state

        assert coll_change > 0 and debt_change > 0, "DFM:C 0 coll or debt"
        state.hook_debt_adjustment = self._call_view_hooks(
            market,
            HookId.ON_CREATE_LOAN,
            _abi_encode(
                account,
                market,
                coll_change,
                debt_change,
                method_id=method_id("on_create_loan_view(address,address,uint256,uint256)")
            ),
            self._positive_only_bounds(convert(debt_change, uint256))
        )
    elif coll_change != 0 or debt_change != 0:
        state.hook_debt_adjustment = self._call_view_hooks(
            market,
            HookId.ON_ADJUST_LOAN,
            _abi_encode(
                account,
                market,
                coll_change,
                debt_change,
                method_id=method_id("on_adjust_loan_view(address,address,int256,int256)")
            ),
            self._adjust_loan_bounds(debt_change)
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
    state.liquidation_range = [amm.p_oracle_up(state.bands[0]), amm.p_oracle_down(state.bands[1])]

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
    c: MarketContracts = self._get_contracts(market)
    state: CloseLoanState = empty(CloseLoanState)
    debt: uint256 = MarketOperator(market).debt(account)

    if debt != 0:
        state.hook_debt_adjustment = self._call_view_hooks(
            market,
            HookId.ON_CLOSE_LOAN,
            _abi_encode(account, market, debt, method_id=method_id("on_close_loan_view(address,address,uint256)")),
            self._positive_only_bounds(debt)
        )
        state.total_debt_repaid = self._uint_plus_int(debt, state.hook_debt_adjustment)
        state.debt_from_amm, state.coll_withdrawn = AMM(c.amm).get_sum_xy(account)
        if state.debt_from_amm < state.total_debt_repaid:
            state.debt_burned = state.total_debt_repaid - state.debt_from_amm

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
    self._get_contracts(market)
    liquidatable_accounts: DynArray[Position, 1000] = MarketOperator(market).users_to_liquidate(start, limit)
    liquidation_states: DynArray[LiquidationState, 1000] = []

    for item in liquidatable_accounts:
        state: LiquidationState = empty(LiquidationState)
        state.account = item.account
        state.hook_debt_adjustment = self._call_view_hooks(
            market,
            HookId.ON_LIQUIDATION,
            _abi_encode(
                caller,
                market,
                state.account,
                item.debt,
                method_id=method_id("on_liquidation_view(address,address,address,uint256)")
            ),
            self._positive_only_bounds(item.debt)
        )
        state.total_debt_repaid = self._uint_plus_int(item.debt, state.hook_debt_adjustment)
        state.debt_from_amm = item.x
        state.coll_received = item.y
        if state.debt_from_amm < state.total_debt_repaid:
            state.debt_burned = state.total_debt_repaid - state.debt_from_amm
        liquidation_states.append(state)

    return liquidation_states


@view
@external
def max_borrowable(market: MarketOperator, coll_amount: uint256, n_bands: uint256) -> uint256:
    """
    @notice Calculation of maximum which can be borrowed in the given market
    @param market Market where the loan will be taken
    @param coll_amount Collateral amount against which to borrow
    @param n_bands number of bands the collateral will be deposited over
    @return Maximum amount of stablecoin that can be borrowed
    """
    debt_ceiling: uint256 = self.global_market_debt_ceiling
    total_debt: uint256 = self.total_debt + market.pending_debt()
    if total_debt >= debt_ceiling:
        return 0

    global_max: uint256 = debt_ceiling - total_debt
    market_max: uint256 = market.max_borrowable(coll_amount, n_bands)

    return min(global_max, market_max)


@view
@external
def get_implementations(A: uint256) -> Implementations:
    return self.implementations[A]


@view
@external
def get_hooks(market: address) -> (address, DynArray[MarketHookData, MAX_HOOKS]):
    """
    @notice Get the hook contracts and active hooks for the given market
    @param market Market address. Set as empty(address) for global hooks.
    @return (amm hooks, market hooks)
    """
    hookdata_packed_array: DynArray[uint256, MAX_HOOKS] = []
    hookdata_array: DynArray[MarketHookData, MAX_HOOKS] = []

    if market == empty(address):
        hookdata_packed_array = self.global_hooks
    else:
        hookdata_packed_array = self.market_hooks[market]

    for hookdata_packed in hookdata_packed_array:
        hookdata: MarketHookData = empty(MarketHookData)
        hookdata.hooks = convert(hookdata_packed >> 96, address)

        for i in range(NUM_HOOK_IDS):
            if hookdata_packed >> i & 1 != 0:
                hookdata.active_hooks[i] = True

        hookdata_array.append(hookdata)

    return self.amm_hooks[market], hookdata_array


@view
@external
def get_total_hook_debt_adjustment(market: address) -> uint256:
    """
    @notice Get the total aggregate hook debt adjustments for the given market
    @dev The sum of all hook debt adjustments cannot ever be less than zero
         or the system will have uncollateralized debt.
    """
    return self.hook_debt_adjustment[market]


@view
@external
def get_monetary_policy_for_market(market: address) -> MonetaryPolicy:
    """
    @notice Get the address of the monetary policy for `market`
    """
    c: MarketContracts = self.market_contracts[market]

    if c.collateral == empty(address):
        return empty(MonetaryPolicy)

    return self.monetary_policies[c.mp_idx]


@view
@external
def get_peg_keeper_active_debt() -> uint256:
    """
    @notice Get the total active debt across all peg keepers
    """
    regulator: PegKeeperRegulator = self.peg_keeper_regulator
    if regulator.address == empty(address):
        return 0
    return regulator.active_debt()


@view
@external
def stored_admin_fees() -> uint256:
    """
    @notice Calculate the amount of fees obtained from the interest
    """
    return self.total_debt + self.redeemed - self.minted


# --- unguarded nonpayable functions ---

@external
def setDelegateApproval(delegate: address, is_approved: bool):
    """
    @dev Functions that supports delegation include an `account` input allowing
         the delegated caller to indicate who they are calling on behalf of.
         In executing the call, all internal state updates are applied for
         `account` and all value transfers occur to or from the caller.

        For example: a delegated call to `create_loan` will transfer collateral
        from the caller, create the debt position for `account`, and send newly
        minted stablecoins to the caller.
    """
    self.isApprovedDelegate[msg.sender][delegate] = is_approved
    log SetDelegateApproval(msg.sender, delegate, is_approved)


@external
@nonreentrant('lock')
def create_loan(
    account: address,
    market: address,
    coll_amount: uint256,
    debt_amount: uint256,
    n_bands: uint256
):
    """
    @notice Create loan
    @param account Account to open the loan for
    @param market Market where the loan will be opened
    @param coll_amount Collateral amount to deposit
    @param debt_amount Stablecoin amount to mint
    @param n_bands Number of bands to deposit collateral into
                   Can be from market.MIN_TICKS() to market.MAX_TICKS()
    """
    assert coll_amount > 0 and debt_amount > 0, "DFM:C 0 coll or debt"
    self._assert_caller_or_approved_delegate(account)
    c: MarketContracts = self._get_contracts(market)

    hook_adjust: int256 = self._call_hooks(
        market,
        HookId.ON_CREATE_LOAN,
        _abi_encode(
            account,
            market,
            coll_amount,
            debt_amount,
            method_id=method_id("on_create_loan(address,address,uint256,uint256)")
        ),
        self._positive_only_bounds(debt_amount)
    )
    debt_amount_final: uint256 = self._uint_plus_int(debt_amount, hook_adjust)

    self._deposit_collateral(msg.sender, c.collateral, c.amm, coll_amount)
    debt_increase: uint256 = MarketOperator(market).create_loan(account, coll_amount, debt_amount_final, n_bands)

    total_debt: uint256 = self.total_debt + debt_increase
    self._assert_below_debt_ceiling(total_debt)

    self.total_debt = total_debt
    self.minted += debt_amount
    self._update_rate(market, c.amm, c.mp_idx)

    STABLECOIN.mint(msg.sender, debt_amount)

    log CreateLoan(market, account, coll_amount, debt_amount_final)


@external
@nonreentrant('lock')
def adjust_loan(
    account: address,
    market: address,
    coll_change: int256,
    debt_change: int256,
    max_active_band: int256 = max_value(int256)
):
    """
    @notice Adjust collateral/debt amounts for an existing loan
    @param account Account to adjust the loan for
    @param market Market of the loan being adjusted
    @param coll_change Collateral adjustment amount. A positive value deposits, negative withdraws.
    @param debt_change Debt adjustment amount. A positive value mints, negative burns.
    @param max_active_band Maximum active band (used to prevent front-running)
    """
    assert coll_change != 0 or debt_change != 0, "DFM:C No change"

    self._assert_caller_or_approved_delegate(account)
    c: MarketContracts = self._get_contracts(market)

    debt_change_final: int256 = self._call_hooks(
        market,
        HookId.ON_ADJUST_LOAN,
        _abi_encode(
            account,
            market,
            coll_change,
            debt_change,
            method_id=method_id("on_adjust_loan(address,address,int256,int256)")
        ),
        self._adjust_loan_bounds(debt_change)
    ) + debt_change

    debt_adjustment: int256 = MarketOperator(market).adjust_loan(account, coll_change, debt_change_final, max_active_band)

    total_debt: uint256 = self._uint_plus_int(self.total_debt, debt_adjustment)
    self.total_debt = total_debt
    self._update_rate(market, c.amm, c.mp_idx)

    if debt_change != 0:
        debt_change_abs: uint256 = convert(abs(debt_change), uint256)
        if debt_change > 0:
            self._assert_below_debt_ceiling(total_debt)
            self.minted += debt_change_abs
            STABLECOIN.mint(msg.sender, debt_change_abs)
        else:
            self.redeemed += debt_change_abs
            STABLECOIN.burn(msg.sender, debt_change_abs)

    if coll_change != 0:
        coll_change_abs: uint256 = convert(abs(coll_change), uint256)
        if coll_change > 0:
            self._deposit_collateral(msg.sender, c.collateral, c.amm, coll_change_abs)
        else:
            self._withdraw_collateral(msg.sender, c.collateral, c.amm, coll_change_abs)

    log AdjustLoan(market, account, coll_change, debt_change_final)


@external
@nonreentrant('lock')
def close_loan(account: address, market: address):
    """
    @notice Close an existing loan
    @dev This function does not interact with the market's price oracle, so that
         users can still close their loans in case of a reverting oracle.
    @param account The account to close the loan for
    @param market Market of the loan being closed
    """
    self._assert_caller_or_approved_delegate(account)
    c: MarketContracts = self._get_contracts(market)

    debt_adjustment: int256 = 0
    burn_amount: uint256 = 0
    xy: uint256[2] = empty(uint256[2])
    debt_adjustment, burn_amount, xy = MarketOperator(market).close_loan(account)

    burn_adjust: int256 = self._call_hooks(
        market,
        HookId.ON_CLOSE_LOAN,
        _abi_encode(account, market, burn_amount, method_id=method_id("on_close_loan(address,address,uint256)")),
        self._positive_only_bounds(burn_amount)
    )
    burn_amount = self._uint_plus_int(burn_amount, burn_adjust)

    self.redeemed += burn_amount
    self.total_debt = self._uint_plus_int(self.total_debt, debt_adjustment)
    self._update_rate(market, c.amm, c.mp_idx)

    if xy[0] > 0:
        STABLECOIN.transferFrom(c.amm, msg.sender, xy[0])
    STABLECOIN.burn(msg.sender, burn_amount)
    if xy[1] > 0:
        self._withdraw_collateral(msg.sender, c.collateral, c.amm, xy[1])

    log CloseLoan(market, account, xy[1], xy[0], burn_amount)


@external
@nonreentrant('lock')
def liquidate(market: address, target: address, min_x: uint256, frac: uint256 = 10**18):
    """
    @notice Perform a liquidation (or self-liquidation) on an unhealthy account
    @param market Market of the loan being liquidated
    @param target Address of the account to be liquidated
    @param min_x Minimal amount of stablecoin to receive (to avoid liquidators being sandwiched)
    @param frac Fraction to liquidate; 100% = 10**18
    """
    assert frac <= 10**18, "DFM:C frac too high"
    c: MarketContracts = self._get_contracts(market)

    debt_adjustment: int256 = 0
    debt_amount: uint256 = 0
    xy: uint256[2] = empty(uint256[2])
    debt_adjustment, debt_amount, xy = MarketOperator(market).liquidate(msg.sender, target, min_x, frac)

    burn_adjust: int256 = self._call_hooks(
        market,
        HookId.ON_LIQUIDATION,
        _abi_encode(
            msg.sender,
            market,
            target,
            debt_amount,
            method_id=method_id("on_liquidation(address,address,address,uint256)")
        ),
        self._positive_only_bounds(debt_amount)
    )
    debt_amount = self._uint_plus_int(debt_amount, burn_adjust)

    self.redeemed += debt_amount
    self.total_debt = self._uint_plus_int(self.total_debt, debt_adjustment)
    self._update_rate(market, c.amm, c.mp_idx)

    burn_amm: uint256 = min(xy[0], debt_amount)
    if burn_amm != 0:
        STABLECOIN.burn(c.amm, burn_amm)

    if debt_amount > xy[0]:
        remaining: uint256 = unsafe_sub(debt_amount, xy[0])
        STABLECOIN.burn(msg.sender, remaining)
    elif xy[0] > debt_amount:
        STABLECOIN.transferFrom(c.amm, msg.sender, unsafe_sub(xy[0], debt_amount))

    if xy[1] > 0:
        self._withdraw_collateral(msg.sender, c.collateral, c.amm, xy[1])

    log LiquidateLoan(market, msg.sender, target, xy[1], xy[0], debt_amount)


@external
@nonreentrant('lock')
def collect_fees(market_list: DynArray[address, 255]) -> uint256:
    """
    @notice Collect admin fees across markets
    @param market_list List of markets to collect fees from. Can be left empty
                       to only claim already-stored interest fees.
    """
    receiver: address = CORE_OWNER.feeReceiver()

    debt_increase_total: uint256 = 0
    i: uint256 = 0
    amm_list: address[255] = empty(address[255])
    mp_idx_list: uint256[255] = empty(uint256[255])

    # collect market fees and calculate aggregate debt increase
    for market in market_list:
        c: MarketContracts = self._get_contracts(market)

        debt_increase: uint256 = 0
        xy: uint256[2] = empty(uint256[2])

        debt_increase, xy = MarketOperator(market).collect_fees()
        debt_increase_total += debt_increase

        if xy[0] > 0:
            STABLECOIN.transferFrom(c.amm, receiver, xy[0])
        if xy[1] > 0:
            self._withdraw_collateral(receiver, c.collateral, c.amm, xy[1])

        log CollectAmmFees(market, xy[1], xy[0])

        amm_list[i] = c.amm
        mp_idx_list[i] = c.mp_idx
        i = unsafe_add(i, 1)

    # update total debt and market rates
    total_debt: uint256 = self.total_debt + debt_increase_total
    self.total_debt = total_debt
    i = 0
    for market in market_list:
        self._update_rate(market, amm_list[i], mp_idx_list[i])
        i = unsafe_add(i, 1)

    mint_total: uint256 = 0
    minted: uint256 = self.minted
    redeemed: uint256 = self.redeemed
    to_be_redeemed: uint256 = total_debt + redeemed

    # Difference between to_be_redeemed and minted amount is exactly due to interest charged
    if to_be_redeemed > minted:
        self.minted = to_be_redeemed
        mint_total = unsafe_sub(to_be_redeemed, minted)  # Now this is the fees to charge
        STABLECOIN.mint(receiver, mint_total)

    log CollectFees(minted, redeemed, total_debt, mint_total)
    return mint_total


@external
def increase_total_hook_debt_adjustment(market: address, amount: uint256):
    """
    @notice Burn debt to increase the total aggregate hook debt adjustment
            value for the given market. Used to pre-fund hook debt rebates.
    """
    assert self.market_contracts[market].collateral != empty(address), "DFM:C Invalid market"

    STABLECOIN.burn(msg.sender, amount)
    self.hook_debt_adjustment[market] += amount


# --- owner-only nonpayable functions ---

@external
@nonreentrant('lock')
def add_market(token: address, A: uint256, fee: uint256, admin_fee: uint256, oracle: PriceOracle,
               mp_idx: uint256, loan_discount: uint256, liquidation_discount: uint256,
               debt_ceiling: uint256) -> address[2]:
    """
    @notice Add a new market, creating an AMM and a MarketOperator from a blueprint
    @param token Collateral token address
    @param A Amplification coefficient; one band size is 1/A
    @param fee AMM fee in the market's AMM
    @param admin_fee AMM admin fee
    @param oracle Address of price oracle contract for this market
    @param mp_idx Monetary policy index for this market
    @param loan_discount Loan discount: allowed to borrow only up to x_down * (1 - loan_discount)
    @param liquidation_discount Discount which defines a bad liquidation threshold
    @param debt_ceiling Debt ceiling for this market
    @return (MarketOperator, AMM)
    """
    self._assert_only_owner()
    assert fee <= MAX_FEE, "DFM:C Fee too high"
    assert fee >= MIN_FEE, "DFM:C Fee too low"
    assert admin_fee < MAX_ADMIN_FEE, "DFM:C Admin fee too high"
    assert liquidation_discount >= MIN_LIQUIDATION_DISCOUNT, "DFM:C liq discount too low"
    assert loan_discount <= MAX_LOAN_DISCOUNT, "DFM:C Loan discount too high"
    assert loan_discount > liquidation_discount, "DFM:C loan discount<liq discount"
    assert mp_idx < self.n_monetary_policies, "DFM:C invalid mp_idx"

    p: uint256 = oracle.price()
    assert p > 0, "DFM:C p == 0"
    assert oracle.price_w() == p, "DFM:C p != price_w"

    impl: Implementations = self.implementations[A]
    assert impl.amm != empty(address), "DFM:C No implementation for A"
    market: address = create_minimal_proxy_to(impl.market_operator)
    amm: address = create_minimal_proxy_to(impl.amm)

    MarketOperator(market).initialize(amm, token, debt_ceiling, loan_discount, liquidation_discount)
    AMM(amm).initialize(market, oracle, token, p, fee, admin_fee)

    self.markets.append(MarketOperator(market))
    if len(self.collateral_markets[token]) == 0:
        self.collaterals.append(token)
    self.collateral_markets[token].append(market)
    self.market_contracts[market] = MarketContracts({collateral: token, amm: amm, mp_idx: mp_idx})

    log AddMarket(token, market, amm, mp_idx)
    return [market, amm]


@external
def set_global_market_debt_ceiling(debt_ceiling: uint256):
    """
    @notice Set the global debt ceiling
    @dev There is no requirement for the global ceiling to be equal to the sum
         of the market ceilings. Individual markets may mint up to their own debt
         ceiling, so long as the aggregate debt does not exceed the global ceiling.
    """
    self._assert_only_owner()
    self.global_market_debt_ceiling = debt_ceiling

    log SetGlobalMarketDebtCeiling(debt_ceiling)


@external
def set_implementations(A: uint256, market: address, amm: address):
    """
    @notice Set new implementations for market and amm for given A
    @dev Already-deployed markets are unaffected by this change
    @param A Amplification co-efficient
    @param market Address of the market blueprint
    @param amm Address of the AMM blueprint
    """
    self._assert_only_owner()
    assert A >= MIN_A and A <= MAX_A, "DFM:C A outside bounds"

    if amm == market:
        assert amm == empty(address), "DFM:C matching implementations"
    else:
        assert amm != empty(address) and market != empty(address), "DFM:C empty implementation"
        assert MarketOperator(market).A() == A, "DFM:C incorrect market A"
        assert AMM(amm).A() == A, "DFM:C incorrect amm A"

    self.implementations[A] = Implementations({amm: amm, market_operator: market})
    log SetImplementations(amm, market)


@external
def set_market_hooks(market: address, hookdata_array: DynArray[MarketHookData, MAX_HOOKS]):
    """
    @notice Set callback hooks for `market`
    @dev Existing hooks are replaced with this call, be sure to include
         previously set hooks if the goal is to add a new one
    @param market Market to set hooks for. Set as empty(address) for global hooks.
    @param hookdata_array Dynamic array with hook configuration data
    """
    self._assert_only_owner()

    hookdata_packed_array: DynArray[uint256, MAX_HOOKS] = []
    for hookdata in hookdata_array:
        assert hookdata.hooks != empty(address), "DFM:C Empty hooks address"
        hookdata_packed: uint256 = (convert(hookdata.hooks, uint256) << 96)

        for i in range(NUM_HOOK_IDS):
            if hookdata.active_hooks[i]:
                hookdata_packed += 1 << i

        assert hookdata_packed % (1 << NUM_HOOK_IDS) != 0, "DFM:C No active hooks"
        hookdata_packed_array.append(hookdata_packed)

    if market == empty(address):
        self.global_hooks = hookdata_packed_array
    else:
        self.market_hooks[market] = hookdata_packed_array

    log SetMarketHooks(market, hookdata_array)


@external
def set_amm_hook(market: address, hook: address):
    """
    @notice Set callback hooks for `market`'s AMM
    @dev When an AMM hook is set, the AMM also approves the hook to transfer the collateral token.
    @param market Market to set the hooks for
    @param hook Address of the AMM hooks contract. Set to empty(address) to disable.
    """
    self._assert_only_owner()
    amm: address = self._get_contracts(market).amm
    amount: uint256 = AMM(amm).collateral_balance()
    AMM(amm).set_exchange_hook(hook)
    assert AMM(amm).collateral_balance() == amount, "DFM:C balance changed"
    self.amm_hooks[amm] = hook

    log SetAmmHooks(market, hook)


@external
def add_new_monetary_policy(monetary_policy: MonetaryPolicy):
    """
    @notice Add a new monetary policy
    @dev The new policy is assigned an identifier `mp_idx` which is used to
         associate it to individual markets
    """
    self._assert_only_owner()
    idx: uint256 = self.n_monetary_policies
    self.monetary_policies[idx] = monetary_policy
    self.n_monetary_policies = idx +1

    log AddMonetaryPolicy(idx, monetary_policy)


@external
def change_existing_monetary_policy(monetary_policy: MonetaryPolicy, mp_idx: uint256):
    """
    @notice Change the monetary policy at an existing `mp_idx`
    @dev Rates for markets using `mp_idx` are NOT updated,
         it is recommended to force an update via `collect_fees`
    """
    self._assert_only_owner()
    assert mp_idx < self.n_monetary_policies, "DFM:C invalid mp_idx"
    self.monetary_policies[mp_idx] = monetary_policy

    log ChangeMonetaryPolicy(mp_idx, monetary_policy)


@external
def change_market_monetary_policy(market: address, mp_idx: uint256):
    """
    @notice Modify the assigned `mp_idx` for the given market
    @dev Also updates the current market rate
    """
    self._assert_only_owner()
    assert mp_idx < self.n_monetary_policies, "DFM:C invalid mp_idx"
    self.market_contracts[market].mp_idx = mp_idx
    self._update_rate(market, self.market_contracts[market].amm, mp_idx)

    log ChangeMonetaryPolicyForMarket(market, mp_idx)


@external
def set_peg_keeper_regulator(regulator: PegKeeperRegulator, with_migration: bool):
    """
    @notice Set the active peg keeper regulator
    @dev The regulator must also be given permission to mint `STABLECOIN`
    @param regulator Address of the new peg keeper regulator. Can also be set to
                     empty(address) to have no active regulator.
    @param with_migration if True, all peg keepers from the old regulator are
                          added to the new regulator with the same debt ceilings.
    """
    self._assert_only_owner()
    old: PegKeeperRegulator = self.peg_keeper_regulator
    assert old != regulator, "DFM:C regulator unchanged"

    if with_migration:
        peg_keepers: DynArray[PegKeeper, 256] = []
        debt_ceilings: DynArray[uint256, 256] = []
        (peg_keepers, debt_ceilings) = old.get_peg_keepers_with_debt_ceilings()
        for pk in peg_keepers:
            pk.set_regulator(regulator.address)
        regulator.init_migrate_peg_keepers(peg_keepers, debt_ceilings)

    self.peg_keeper_regulator = regulator

    log SetPegKeeperRegulator(regulator.address, with_migration)


# --- internal functions ---

@view
@internal
def _assert_only_owner():
    assert msg.sender == CORE_OWNER.owner(), "DFM:C Only owner"


@view
@internal
def _assert_caller_or_approved_delegate(account: address):
    if msg.sender != account:
        assert self.isApprovedDelegate[account][msg.sender], "DFM:C Delegate not approved"


@view
@internal
def _assert_below_debt_ceiling(total_debt: uint256):
    assert total_debt <= self.global_market_debt_ceiling, "DFM:C global debt ceiling"


@pure
@internal
def _assert_in_bounds(amount: int256, bounds: int256[2], is_sum: bool):
    if amount < bounds[0] or amount > bounds[1]:
        if is_sum:
            raise "DFM:C hook sum out of bounds"
        else:
            raise "DFM:C Hook caused invalid debt"


@pure
@internal
def _uint_plus_int(initial: uint256, adjustment: int256) -> uint256:
    if adjustment < 0:
        return initial - convert(-adjustment, uint256)
    else:
        return initial + convert(adjustment, uint256)


@pure
@internal
def _adjust_loan_bounds(debt_change: int256) -> int256[2]:
    if debt_change < 0:
        # when reducing debt, hook cannot cause a debt increase
        return [-2**255, -debt_change]
    if debt_change > 0:
        # when increasing debt, hook cannot cause a debt reduction
        return [-debt_change, max_value(int256)]
    # when debt is unchanged, hook cannot apply any adjustment
    return empty(int256[2])


@pure
@internal
def _positive_only_bounds(debt_amount: uint256) -> int256[2]:
    # hook adjustment cannot cause debt_amount to go below 0
    return [-convert(debt_amount, int256), max_value(int256)]


@view
@internal
def _get_contracts(market: address) -> MarketContracts:
    c: MarketContracts = self.market_contracts[market]

    assert c.collateral != empty(address), "DFM:C Invalid market"

    return c


@view
@internal
def _limit_debt_adjustment(market: address, debt_adjustment: int256) -> (int256, uint256):
    total_adjustment: int256 = convert(self.hook_debt_adjustment[market], int256)
    if debt_adjustment < 0 and abs(debt_adjustment) > total_adjustment:
        debt_adjustment = -total_adjustment
    return debt_adjustment, convert(debt_adjustment + total_adjustment, uint256)


@view
@internal
def _call_view_hook(
    hookdata_array: DynArray[uint256, MAX_HOOKS],
    hook_id: HookId,
    calldata: Bytes[255],
    bounds: int256[2]
) -> int256:
    if len(hookdata_array) == 0:
        return 0

    total: int256 = 0
    for hookdata in hookdata_array:
        if hookdata & convert(hook_id, uint256) == 0:
            continue

        hook: address = convert(hookdata >> 96, address)
        response: int256 = convert(raw_call(hook, calldata, max_outsize=32, is_static_call=True), int256)
        self._assert_in_bounds(response, bounds, False)
        total += response

    return total


@view
@internal
def _call_view_hooks(market: address, hook_id: HookId, calldata: Bytes[255], bounds: int256[2]) -> int256:
    debt_adjustment: int256 = 0

    debt_adjustment += self._call_view_hook(self.market_hooks[market], hook_id, calldata, bounds)
    debt_adjustment += self._call_view_hook(self.global_hooks, hook_id, calldata, bounds)

    self._assert_in_bounds(debt_adjustment, bounds, True)
    return self._limit_debt_adjustment(market, debt_adjustment)[0]


@internal
def _deposit_collateral(account: address, collateral: address, amm: address, amount: uint256):
    assert ERC20(collateral).transferFrom(account, amm, amount, default_return_value=True)

    hooks: address = self.amm_hooks[amm]
    if hooks != empty(address):
        AmmHooks(hooks).after_collateral_in(amount)



@internal
def _withdraw_collateral(account: address, collateral: address, amm: address, amount: uint256):
    hooks: address = self.amm_hooks[amm]
    if hooks != empty(address):
        AmmHooks(hooks).before_collateral_out(amount)

    assert ERC20(collateral).transferFrom(amm, account, amount, default_return_value=True)


@internal
def _call_hook(
    hookdata_array: DynArray[uint256, MAX_HOOKS],
    hook_id: HookId,
    calldata: Bytes[255],
    bounds: int256[2]
) -> int256:
    if len(hookdata_array) == 0:
        return 0

    total: int256 = 0
    for hookdata in hookdata_array:
        if hookdata & convert(hook_id, uint256) == 0:
            continue

        hook: address = convert(hookdata >> 96, address)
        response: int256 = convert(raw_call(hook, calldata, max_outsize=32), int256)
        self._assert_in_bounds(response, bounds, False)
        total += response

    return total


@internal
def _call_hooks(market: address, hook_id: HookId, calldata: Bytes[255], bounds: int256[2]) -> int256:
    debt_adjustment: int256 = 0

    debt_adjustment += self._call_hook(self.market_hooks[market], hook_id, calldata, bounds)
    debt_adjustment += self._call_hook(self.global_hooks, hook_id, calldata, bounds)

    if debt_adjustment != 0:
        self._assert_in_bounds(debt_adjustment, bounds, True)
        debt_adjustment, self.hook_debt_adjustment[market] = self._limit_debt_adjustment(market, debt_adjustment)

    return debt_adjustment


@internal
def _update_rate(market: address, amm: address, mp_idx: uint256):
    mp_rate: uint256 = self.monetary_policies[mp_idx].rate_write(market)
    AMM(amm).set_rate(mp_rate)