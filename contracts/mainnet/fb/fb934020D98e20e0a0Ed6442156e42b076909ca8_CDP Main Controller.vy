#pragma version 0.3.10
"""
@title CDP Main Controller
@author Curve.Fi (with edits by defidotmoney)
@license Copyright (c) Curve.Fi, 2020-2024 - all rights reserved
"""

interface ERC20:
    def mint(_to: address, _value: uint256) -> bool: nonpayable
    def burn(_to: address, _value: uint256) -> bool: nonpayable
    def transferFrom(_from: address, _to: address, _value: uint256) -> bool: nonpayable
    def transfer(_to: address, _value: uint256) -> bool: nonpayable
    def balanceOf(account: address) -> uint256: view

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
    def set_rate(rate: uint256) -> uint256: nonpayable
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
    def guardian() -> address: view

interface MarketHook:
    def get_configuration() -> (uint256, bool[NUM_HOOK_IDS]): view



event AddMarket:
    collateral: indexed(address)
    market: address
    amm: address
    mp_idx: uint256

event SetDelegateApproval:
    account: indexed(address)
    delegate: indexed(address)
    is_approved: bool

event SetDelegationEnabled:
    caller: address
    is_enabled: bool

event SetProtocolEnabled:
    caller: address
    is_enabled: bool

event SetImplementations:
    A: indexed(uint256)
    amm: address
    market: address

event AddMarketHook:
    market: indexed(address)
    hook: indexed(address)
    hook_type: uint256
    active_hooks: bool[NUM_HOOK_IDS]

event RemoveMarketHook:
    market: indexed(address)
    hook: indexed(address)
    hook_debt_released: uint256

event HookDebtAjustment:
    market: indexed(address)
    hook: indexed(address)
    adjustment: int256
    new_hook_debt: uint256
    new_total_hook_debt: uint256

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
    caller: indexed(address)
    coll_amount: uint256
    debt_amount: uint256

event AdjustLoan:
    market: indexed(address)
    account: indexed(address)
    caller: indexed(address)
    coll_adjustment: int256
    debt_adjustment: int256

event CloseLoan:
    market: indexed(address)
    account: indexed(address)
    caller: indexed(address)
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

struct MarketHookData:
    hooks: address
    hook_type: uint256
    active_hooks: bool[NUM_HOOK_IDS]


enum HookId:
    ON_CREATE_LOAN
    ON_ADJUST_LOAN
    ON_CLOSE_LOAN
    ON_LIQUIDATION

enum HookType:
    VALIDATION_ONLY
    FEE_ONLY
    FEE_AND_REBATE


NUM_HOOK_IDS: constant(uint256) = 4
MAX_HOOKS: constant(uint256) = 4

# Limits
MIN_A: constant(uint256) = 2
MAX_A: constant(uint256) = 10000
MAX_RATE: constant(uint256) = 43959106799  # 300% APY
MIN_FEE: constant(uint256) = 10**6  # 1e-12, still needs to be above 0
MAX_FEE: constant(uint256) = 10**17  # 10%
MAX_ADMIN_FEE: constant(uint256) = 10**18  # 100%
MAX_LOAN_DISCOUNT: constant(uint256) = 5 * 10**17
MIN_LIQUIDATION_DISCOUNT: constant(uint256) = 10**16

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
isDelegationEnabled: public(bool)
is_protocol_enabled: public(bool)

implementations: HashMap[uint256, Implementations]

market_hooks: HashMap[address, DynArray[uint256, MAX_HOOKS]]
hook_debt: HashMap[address, HashMap[address, uint256]]
total_hook_debt: public(uint256)


@external
def __init__(
    core: CoreOwner,
    stable: ERC20,
    monetary_policies: DynArray[MonetaryPolicy, 10],
    debt_ceiling: uint256
):
    """
    @notice Contract constructor
    @param core `DFMProtocolCore` address. Ownership is inherited from this contract.
    @param stable Address of the protocol stablecoin. This contract must be given
                  minter privileges within the stablecoin.
    @param monetary_policies Array of `MonetaryPolicy` contracts to initially set.
    @param debt_ceiling Initial global debt ceiling
    """
    CORE_OWNER = core
    STABLECOIN = stable

    idx: uint256 = 0
    for mp in monetary_policies:
        log AddMonetaryPolicy(idx, mp)
        self.monetary_policies[idx] = mp
        idx += 1
    self.n_monetary_policies = idx

    self.global_market_debt_ceiling = debt_ceiling
    log SetGlobalMarketDebtCeiling(debt_ceiling)

    self.is_protocol_enabled = True
    self.isDelegationEnabled = True


# --- external view functions ---

@view
@external
def owner() -> address:
    return CORE_OWNER.owner()


@view
@external
def get_market_count() -> uint256:
    """
    @notice Get the total number of deployed markets
    """
    return len(self.markets)


@view
@external
def get_collateral_count() -> uint256:
    """
    @notice Get the number of unique collaterals used within the system
    @dev It is possible to deploy multiple markets for a collateral, so
         this number does not necessarily equal the number of markets.
    """
    return len(self.collaterals)


@view
@external
def get_all_markets() -> DynArray[MarketOperator, 65536]:
    """
    @notice Get a list of all deployed `MarketOperator` contracts
    """
    return self.markets


@view
@external
def get_all_collaterals() -> DynArray[address, 65536]:
    """
    @notice Get a list of collaterals for which a market exists
    """
    return self.collaterals


@view
@external
def get_all_markets_for_collateral(collateral: address) -> DynArray[address, 256]:
    """
    @notice Get a list of all deployed `MarketOperator` contracts
            that use a given collateral
    """
    return self.collateral_markets[collateral]


@view
@external
def get_market(collateral: address, i: uint256 = 0) -> address:
    """
    @notice Get market address for collateral
    @dev Returns empty(address) if market does not exist
    @param collateral Address of collateral token
    @param i Access the i-th market within the list
    """
    if i >= len(self.collateral_markets[collateral]):
        return empty(address)
    return self.collateral_markets[collateral][i]


@view
@external
def get_amm(collateral: address, i: uint256 = 0) -> address:
    """
    @notice Get AMM address for collateral
    @dev Returns empty(address) if market does not exist
    @param collateral Address of collateral token
    @param i Access the i-th collateral within the list
    """
    if i >= len(self.collateral_markets[collateral]):
        return empty(address)
    market: address = self.collateral_markets[collateral][i]
    return self.market_contracts[market].amm


@view
@external
def get_collateral(market: address) -> address:
    """
    @notice Get collateral token for a market
    @dev Returns empty(address) if market does not exist
    @param market Market address
    @return Address of collateral token
    """
    return self.market_contracts[market].collateral


@view
@external
def get_oracle_price(collateral: address) -> uint256:
    """
    @notice Get the current oracle price for `collateral`
    @dev Uses the AMM of the first market created for this collateral.
         Reverts if there is no existing market.
    @param collateral Address of collateral token
    @return Oracle price of `collateral` with 1e18 precision
    """
    market: address = self.collateral_markets[collateral][0]
    return AMM(self.market_contracts[market].amm).price_oracle()


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
    """
    @notice Get the `MarketOperator` and `AMM` implementation contracts used
            when deploying a market with the given amplification coefficient.
    @return (AMM address, MarketOperator address)
    """
    return self.implementations[A]


@view
@external
def get_market_hooks(market: address) -> DynArray[MarketHookData, MAX_HOOKS]:
    """
    @notice Get the hook contracts and active hooks for the given market
    @param market Market address. Set as empty(address) for global hooks.
    @return market hooks
    """
    hookdata_packed_array: DynArray[uint256, MAX_HOOKS] = self.market_hooks[market]
    hookdata_array: DynArray[MarketHookData, MAX_HOOKS] = []


    for hookdata_packed in hookdata_packed_array:
        hookdata: MarketHookData = empty(MarketHookData)
        hookdata.hooks = self._get_hook_address(hookdata_packed)
        hookdata.hook_type = (hookdata_packed & 7) >> 1

        for i in range(NUM_HOOK_IDS):
            if hookdata_packed >> i & 8 != 0:
                hookdata.active_hooks[i] = True

        hookdata_array.append(hookdata)

    return hookdata_array


@view
@external
def get_market_hook_debt(market: address, hook: address) -> uint256:
    """
    @notice Get the total aggregate hook debt adjustments for the given market
    @dev The sum of all hook debt adjustments cannot ever be less than zero
         or the system will have uncollateralized debt.
    """
    return self.hook_debt[market][hook]


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
    return self.total_debt + self.redeemed - self.minted - self.total_hook_debt


@view
@external
def get_close_loan_amounts(account: address, market: address) -> (int256, uint256):
    """
    @notice Get balance information related to closing a loan
    @param account The account to close the loan for
    @param market Market of the loan being closed
    @return Debt balance change for caller
             * negative value indicates the amount burned to close
             * positive value indicates a surplus from the AMM after closing
            Collateral balance received from AMM
    """
    amm: AMM = AMM(self._get_market_contracts_or_revert(market).amm)
    xy: (uint256, uint256) = amm.get_sum_xy(account)

    debt: uint256 = MarketOperator(market).debt(account)
    hook_debt_adjustment: int256 = self._call_view_hooks(
        market,
        HookId.ON_CLOSE_LOAN,
        _abi_encode(account, market, debt, method_id=method_id("on_close_loan_view(address,address,uint256)")),
        self._positive_only_bounds(debt)
    )
    debt = self._uint_plus_int(debt, hook_debt_adjustment)

    return convert(xy[0], int256) - convert(debt, int256), xy[1]


@view
@external
def on_create_loan_hook_adjustment(
    account: address,
    market: address,
    coll_amount: uint256,
    debt_amount: uint256,
) -> int256:
    """
    @notice Get the aggregate hook debt adjustment when creating a new loan
    @param account Account to open the loan for
    @param market Market where the loan will be opened
    @param coll_amount Collateral amount to deposit
    @param debt_amount Stablecoin amount to mint
    @return adjustment amount applied to the new debt created
    """
    return self._call_view_hooks(
        market,
        HookId.ON_CREATE_LOAN,
        _abi_encode(
            account,
            market,
            coll_amount,
            debt_amount,
            method_id=method_id("on_create_loan_view(address,address,uint256,uint256)")
        ),
        self._positive_only_bounds(debt_amount)
    )


@view
@external
def on_adjust_loan_hook_adjustment(
    account: address,
    market: address,
    coll_change: int256,
    debt_change: int256
) -> int256:
    """
    @notice Get the aggregate hook debt adjustment when adjusting an existing loan
    @param account Account to adjust the loan for
    @param market Market of the loan being adjusted
    @param coll_change Collateral adjustment amount. A positive value deposits, negative withdraws.
    @param debt_change Debt adjustment amount. A positive value mints, negative burns.
    @return adjustment amount applied to `debt_change`
    """
    return self._call_view_hooks(
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


@view
@external
def on_close_loan_hook_adjustment(account: address, market: address) -> int256:
    """
    @notice Get the aggregate hook debt adjustment when closing a loan
    @param account The account to close the loan for
    @param market Market of the loan being closed
    @return adjustment amount applied to the debt burned when closing the loan
    """
    debt: uint256 = MarketOperator(market).debt(account)
    return self._call_view_hooks(
        market,
        HookId.ON_CLOSE_LOAN,
        _abi_encode(account, market, debt, method_id=method_id("on_close_loan_view(address,address,uint256)")),
        self._positive_only_bounds(debt)
    )


@view
@external
def on_liquidate_hook_adjustment(caller: address, market: address, target: address) -> int256:
    """
    @notice Get the aggregate hook debt adjustment when liquidating a loan
    @param caller Caller address that will perform the liquidations
    @param market Market to check for liquidations
    @param target Address of the account to be liquidated
    @return adjustment amount applied to the debt burned during liquidation
    """
    debt: uint256 = MarketOperator(market).debt(target)
    return self._call_view_hooks(
        market,
        HookId.ON_LIQUIDATION,
        _abi_encode(
            caller,
            market,
            target,
            debt,
            method_id=method_id("on_liquidation_view(address,address,address,uint256)")
        ),
        self._positive_only_bounds(debt)
    )


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
    self._assert_is_protocol_enabled()
    self._assert_caller_or_approved_delegate(account)
    c: MarketContracts = self._get_market_contracts_or_revert(market)

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

    STABLECOIN.mint(msg.sender, debt_amount)

    self._update_rate(market, c.amm, c.mp_idx)

    log CreateLoan(market, account, msg.sender, coll_amount, debt_amount_final)


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

    self._assert_is_protocol_enabled()
    self._assert_caller_or_approved_delegate(account)
    c: MarketContracts = self._get_market_contracts_or_revert(market)

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

    self._update_rate(market, c.amm, c.mp_idx)

    log AdjustLoan(market, account, msg.sender, coll_change, debt_change_final)


@external
@nonreentrant('lock')
def close_loan(account: address, market: address) -> (int256, uint256):
    """
    @notice Close an existing loan
    @dev This function does not interact with the market's price oracle, so that
         users can still close their loans in case of a reverting oracle.
    @param account The account to close the loan for
    @param market Market of the loan being closed
    @return Debt balance change for caller
             * negative value indicates the amount burned to close
             * positive value indicates a surplus from the AMM after closing
            Collateral balance received from AMM
    """
    self._assert_caller_or_approved_delegate(account)
    c: MarketContracts = self._get_market_contracts_or_revert(market)

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

    if xy[0] > 0:
        STABLECOIN.transferFrom(c.amm, msg.sender, xy[0])
    STABLECOIN.burn(msg.sender, burn_amount)
    if xy[1] > 0:
        self._withdraw_collateral(msg.sender, c.collateral, c.amm, xy[1])

    self._update_rate(market, c.amm, c.mp_idx)

    log CloseLoan(market, account, msg.sender, xy[1], xy[0], burn_amount)

    return convert(xy[0], int256) - convert(burn_amount, int256), xy[1]


@external
@nonreentrant('lock')
def liquidate(market: address, target: address, min_x: uint256, frac: uint256 = 10**18) -> (int256, uint256):
    """
    @notice Perform a liquidation (or self-liquidation) on an unhealthy account
    @param market Market of the loan being liquidated
    @param target Address of the account to be liquidated
    @param min_x Minimal amount of stablecoin to receive (to avoid liquidators being sandwiched)
    @param frac Fraction to liquidate; 100% = 10**18
    @return Debt balance change for caller
             * negative value indicates the amount burned to liquidate
             * positive value indicates a surplus received from the AMM
            Collateral balance received from AMM
    """
    assert frac <= 10**18, "DFM:C frac too high"
    c: MarketContracts = self._get_market_contracts_or_revert(market)

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

    self._update_rate(market, c.amm, c.mp_idx)

    log LiquidateLoan(market, msg.sender, target, xy[1], xy[0], debt_amount)

    return convert(xy[0], int256) - convert(debt_amount, int256), xy[1]


@external
@nonreentrant('lock')
def collect_fees(market_list: DynArray[address, 255]) -> uint256:
    """
    @notice Collect admin fees across markets
    @param market_list List of markets to collect fees from. Can be left empty
                       to only claim already-stored interest fees.
    """
    self._assert_is_protocol_enabled()

    receiver: address = CORE_OWNER.feeReceiver()

    debt_increase_total: uint256 = 0
    i: uint256 = 0
    amm_list: address[255] = empty(address[255])
    mp_idx_list: uint256[255] = empty(uint256[255])

    # collect market fees and calculate aggregate debt increase
    for market in market_list:
        c: MarketContracts = self._get_market_contracts_or_revert(market)

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

    mint_total: uint256 = 0
    minted: uint256 = self.minted
    redeemed: uint256 = self.redeemed
    to_be_redeemed: uint256 = total_debt + redeemed - self.total_hook_debt

    if to_be_redeemed > minted:
        self.minted = to_be_redeemed
        mint_total = unsafe_sub(to_be_redeemed, minted)  # Now this is the fees to charge
        STABLECOIN.mint(receiver, mint_total)

    i = 0
    for market in market_list:
        self._update_rate(market, amm_list[i], mp_idx_list[i])
        i = unsafe_add(i, 1)

    log CollectFees(minted, redeemed, total_debt, mint_total)
    return mint_total


@external
def increase_hook_debt(market: address, hook: address, amount: uint256):
    """
    @notice Burn debt to increase the available hook debt value for a given
            market hook. This can be used to pre-fund hook debt rebates.
    """
    if market != empty(address):
        self._assert_market_exists(market)

    num_hooks: uint256 = len(self.market_hooks[market])
    for i in range(MAX_HOOKS + 1):
        if i == num_hooks:
            raise "DFM:C Unknown hook"
        hookdata: uint256 = self.market_hooks[market][i]
        if self._get_hook_address(hookdata) == hook:
            assert self._get_hook_type(hookdata) == HookType.FEE_AND_REBATE, "DFM:C Hook does not track debt"
            break

    STABLECOIN.burn(msg.sender, amount)
    self.hook_debt[market][hook] += amount
    self.total_hook_debt += amount
    self.redeemed += amount


# --- owner-only nonpayable functions ---

@external
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
    assert admin_fee <= MAX_ADMIN_FEE, "DFM:C Admin fee too high"
    assert liquidation_discount >= MIN_LIQUIDATION_DISCOUNT, "DFM:C liq discount too low"
    assert loan_discount <= MAX_LOAN_DISCOUNT, "DFM:C Loan discount too high"
    assert loan_discount > liquidation_discount, "DFM:C loan discount<liq discount"
    assert mp_idx < self.n_monetary_policies, "DFM:C invalid mp_idx"

    p: uint256 = oracle.price()
    assert p > 0, "DFM:C p == 0"
    assert oracle.price_w() == p, "DFM:C p != price_w"

    impl: Implementations = self.implementations[A]
    assert impl.amm != empty(address), "DFM:C No implementation for A"

    # deploy with `CREATE2` and include `chain.id` in the salt to ensure unique `MarketOperator`
    # and `AMM` addresses, even if the controller is deployed at the same address on each chain
    salt_num: uint256 = (chain.id << 176) + (convert(token, uint256) << 16) + len(self.collateral_markets[token])
    market: address = create_minimal_proxy_to(impl.market_operator, salt=keccak256(convert(salt_num, bytes32)))
    amm: address = create_minimal_proxy_to(impl.amm, salt= keccak256(convert(salt_num << 8, bytes32)))

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
    log SetImplementations(A, amm, market)


@external
def add_market_hook(market: address, hook: address):
    """
    @notice Add a new callback hook contract for `market`
    @dev Hook contracts must adhere to the interface and specification defined
         at `interfaces/IControllerHooks.sol`
    @param market Market to add a hook for. Use empty(address) to set a global hook.
    @param hook Address of the hook contract.
    """
    self._assert_only_owner()

    if market != empty(address):
        self._assert_market_exists(market)

    market_hooks: DynArray[uint256, MAX_HOOKS] = self.market_hooks[market]
    assert len(market_hooks) < MAX_HOOKS, "DFM:C Maximum hook count reached"
    for hookdata in market_hooks:
        assert self._get_hook_address(hookdata) != hook, "DFM:C Hook already added"

    config: (uint256, bool[NUM_HOOK_IDS]) = MarketHook(hook).get_configuration()

    # add hook type to 3 lowest bits
    assert config[0] < 3, "DFM:C Invalid hook type"
    hookdata_packed: uint256 = 1 << config[0]

    # add hook ids starting from 4th bit
    for i in range(NUM_HOOK_IDS):
        if config[1][i]:
            hookdata_packed += 1 << (i + 3)

    assert (hookdata_packed >> 3) > 0, "DFM:C No active hook points"

    # add address starting from 96th bit
    hookdata_packed += convert(hook, uint256) << 96

    self.market_hooks[market].append(hookdata_packed)

    log AddMarketHook(market, hook, config[0], config[1])


@external
def remove_market_hook(market: address, hook: address):
    """
    @notice Remove a callback hook contract for `market`
    @dev If the hook type is `FEE_AND_REBATE` and the current `hook_debt`
         is non-zero, is balance is creditted to the protocol fees.
    @param market Market to remove the hooks from. Set as empty(address) to
                  remove a global hook.
    @param hook Address of the hook contract.
    """
    self._assert_only_owner()

    if market != empty(address):
        self._assert_market_exists(market)

    num_hooks: uint256 = len(self.market_hooks[market])
    for i in range(MAX_HOOKS + 1):
        if i == num_hooks:
            raise "DFM:C Unknown hook"
        if self._get_hook_address(self.market_hooks[market][i]) != hook:
            continue

        last_hookdata: uint256 = self.market_hooks[market].pop()
        if i < num_hooks - 1:
            self.market_hooks[market][i] = last_hookdata
        break

    hook_debt: uint256 = self.hook_debt[market][hook]
    if hook_debt > 0:
        self._adjust_hook_debt(market, hook, -convert(hook_debt, int256))

    log RemoveMarketHook(market, hook, hook_debt)



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
    self._assert_market_exists(market)
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


@external
def set_protocol_enabled(is_enabled: bool):
    """
    @notice Enable or disable the protocol in case of an emergency.
    @dev * While disabled, `close_loan` and `liquidate` are the only callable
           functions related to loan management.
         * Only the owner can enable.
         * The owner and the guardian are both able to disable.
    """
    self._assert_owner_or_guardian_toggle(is_enabled)
    self.is_protocol_enabled = is_enabled

    log SetProtocolEnabled(msg.sender, is_enabled)


@external
def setDelegationEnabled(is_enabled: bool):
    """
    @notice Enable or disable all delegated operations within this contract
    @dev Delegated operations are enabled by default upon deployment.
         Only the owner can enable. The owner or the guardian can disable.
    """
    self._assert_owner_or_guardian_toggle(is_enabled)
    self.isDelegationEnabled = is_enabled

    log SetDelegationEnabled(msg.sender, is_enabled)



# --- internal functions ---

@view
@internal
def _assert_only_owner():
    assert msg.sender == CORE_OWNER.owner(), "DFM:C Only owner"


@view
@internal
def _assert_owner_or_guardian_toggle(is_enabled: bool):
    if msg.sender != CORE_OWNER.owner():
        if msg.sender == CORE_OWNER.guardian():
            assert not is_enabled, "DFM:C Guardian can only disable"
        else:
            raise "DFM:C Not owner or guardian"


@view
@internal
def _assert_is_protocol_enabled():
    assert self.is_protocol_enabled, "DFM:C Protocol pause, close only"



@view
@internal
def _assert_caller_or_approved_delegate(account: address):
    if msg.sender != account:
        assert self.isDelegationEnabled, "DFM:C Delegation disabled"
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


@view
@internal
def _assert_market_exists(market: address):
    assert self.market_contracts[market].collateral != empty(address), "DFM:C Invalid market"


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
        return [min_value(int256), -debt_change]
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
def _get_market_contracts_or_revert(market: address) -> MarketContracts:
    c: MarketContracts = self.market_contracts[market]

    assert c.collateral != empty(address), "DFM:C Invalid market"

    return c


@view
@internal
def _get_hook_address(hookdata: uint256) -> address:
    # hook address is stored in the upper 160 bits
    return convert(hookdata >> 96, address)


@view
@internal
def _get_hook_type(hookdata: uint256) -> HookType:
    # hook type is indicated in the three lowest bits:
    # 0b001 == VALIDATION_ONLY (cannot adjust debt)
    # 0b010 == FEE_ONLY (can only increase debt, adjustment is added to fees)
    # 0b100 == FEE_AND_REBATE (can increase and decrease debt, aggregate sum tracked in `hook_debt`)
    return convert(hookdata & 7, HookType)


@view
@internal
def _is_hook_id_active(hookdata: uint256, hook_id: HookId) -> bool:
    # hook ids are tracked from the 4th bit onward
    return hookdata & (convert(hook_id, uint256) << 3) != 0


@view
@internal
def _call_view_hooks(market: address, hook_id: HookId, calldata: Bytes[255], bounds: int256[2]) -> int256:
    debt_adjustment: int256 = 0
    for market_hooks_key in [market, empty(address)]:
        hookdata_array: DynArray[uint256, MAX_HOOKS] = self.market_hooks[market_hooks_key]
        if len(hookdata_array) == 0:
            continue

        for hookdata in hookdata_array:
            if not self._is_hook_id_active(hookdata, hook_id):
                continue

            hook: address = self._get_hook_address(hookdata)
            response: int256 = convert(raw_call(hook, calldata, max_outsize=32, is_static_call=True), int256)
            if response == 0:
                continue

            hook_type: HookType = self._get_hook_type(hookdata)
            if hook_type == HookType.VALIDATION_ONLY:
                raise "DFM:C Hook cannot adjust debt"
            if hook_type == HookType.FEE_ONLY:
                self._assert_in_bounds(response, [0, bounds[1]], False)
            else:
                self._assert_in_bounds(response, bounds, False)
                if response < 0:
                    hook_debt: uint256 = self.hook_debt[market_hooks_key][hook]
                    assert hook_debt >= convert(-response, uint256), "DFM:C Hook debt underflow"

            debt_adjustment += response

    if debt_adjustment != 0:
        self._assert_in_bounds(debt_adjustment, bounds, True)

    return debt_adjustment


@internal
def _deposit_collateral(account: address, collateral: address, amm: address, amount: uint256):
    assert ERC20(collateral).transferFrom(account, amm, amount, default_return_value=True)


@internal
def _withdraw_collateral(account: address, collateral: address, amm: address, amount: uint256):
    assert ERC20(collateral).transferFrom(amm, account, amount, default_return_value=True)


@internal
def _call_hooks(
    market: address,
    hook_id: HookId,
    calldata: Bytes[255],
    bounds: int256[2]
) -> int256:
    debt_adjustment: int256 = 0
    for market_hooks_key in [market, empty(address)]:
        hookdata_array: DynArray[uint256, MAX_HOOKS] = self.market_hooks[market_hooks_key]
        if len(hookdata_array) == 0:
            continue

        for hookdata in hookdata_array:
            if not self._is_hook_id_active(hookdata, hook_id):
                continue

            hook: address = self._get_hook_address(hookdata)
            response: int256 = convert(raw_call(hook, calldata, max_outsize=32), int256)
            if response == 0:
                continue

            hook_type: HookType = self._get_hook_type(hookdata)
            if hook_type == HookType.VALIDATION_ONLY:
                raise "DFM:C Hook cannot adjust debt"
            if hook_type == HookType.FEE_ONLY:
                self._assert_in_bounds(response, [0, bounds[1]], False)
            else:
                self._assert_in_bounds(response, bounds, False)
                self._adjust_hook_debt(market_hooks_key, hook, response)

            debt_adjustment += response

    if debt_adjustment != 0:
        self._assert_in_bounds(debt_adjustment, bounds, True)

    return debt_adjustment


@internal
def _adjust_hook_debt(market: address, hook: address, adjustment: int256):
    hook_debt: uint256 = self.hook_debt[market][hook]
    if adjustment < 0:
        assert hook_debt >= convert(-adjustment, uint256), "DFM:C Hook debt underflow"

    hook_debt = self._uint_plus_int(hook_debt, adjustment)
    total_hook_debt: uint256 = self._uint_plus_int(self.total_hook_debt, adjustment)
    self.hook_debt[market][hook] = hook_debt
    self.total_hook_debt = total_hook_debt

    log HookDebtAjustment(market, hook, adjustment, hook_debt, total_hook_debt)


@internal
def _update_rate(market: address, amm: address, mp_idx: uint256):
    # rate update is always the final action in a function, so that the
    # monetary policy has an accurate view of the current state
    mp_rate: uint256 = min(self.monetary_policies[mp_idx].rate_write(market), MAX_RATE)
    AMM(amm).set_rate(mp_rate)