#pragma version 0.3.10
"""
@title PegKeeper
@author Curve.Fi (with edits by defidotmoney)
@license MIT
@dev For use with StableSwap-ng pools
"""

interface Regulator:
    def get_max_provide(pk: address) -> uint256: view
    def get_max_withdraw(pk: address) -> uint256: view

interface CurvePool:
    def balances(i_coin: uint256) -> uint256: view
    def coins(i: uint256) -> address: view
    def calc_token_amount(_amounts: DynArray[uint256, 2], _is_deposit: bool) -> uint256: view
    def add_liquidity(_amounts: DynArray[uint256, 2], _min_mint_amount: uint256) -> uint256: nonpayable
    def remove_liquidity_imbalance(_amounts: DynArray[uint256, 2], _max_burn_amount: uint256) -> uint256: nonpayable
    def remove_liquidity(
        burn_amount: uint256,
        min_amounts: DynArray[uint256, 2],
        receiver: address
    ) -> DynArray[uint256, 2]: nonpayable
    def get_virtual_price() -> uint256: view
    def balanceOf(arg0: address) -> uint256: view
    def transfer(_to: address, _value: uint256) -> bool: nonpayable
    def N_COINS() -> uint256: view

interface ERC20:
    def approve(_spender: address, _amount: uint256): nonpayable
    def balanceOf(_owner: address) -> uint256: view
    def decimals() -> uint256: view
    def transfer(receiver: address, amount: uint256) -> bool: nonpayable
    def burn(target: address, amount: uint256) -> bool: nonpayable

interface CoreOwner:
    def owner() -> address: view
    def feeReceiver() -> address: view


event Provide:
    amount: uint256

event Withdraw:
    amount: uint256

event Profit:
    lp_amount: uint256

event SetNewCallerShare:
    caller_share: uint256

event SetNewRegulator:
    regulator: address

event RecallDebt:
    recalled: uint256
    burned: uint256
    owing: uint256


PRECISION: constant(uint256) = 10 ** 18
SHARE_PRECISION: constant(uint256) = 10 ** 5

CORE_OWNER: public(immutable(CoreOwner))
CONTROLLER: public(immutable(address))
POOL: public(immutable(CurvePool))
STABLECOIN: public(immutable(ERC20))
regulator: public(Regulator)

IS_INVERSE: public(immutable(bool))
I: immutable(uint256)  # index of pegged in pool
PEG_MUL: immutable(uint256)

last_change: public(uint256)
debt: public(uint256)
owed_debt: public(uint256)

caller_share: public(uint256)


@external
def __init__(
    core: CoreOwner,
    regulator: Regulator,
    controller: address,
    stable: ERC20,
    pool: CurvePool,
    caller_share: uint256
):
    """
    @notice Contract constructor
    @param core `DFMProtocolCore` address. Ownership is inherited from this contract.
    @param regulator Peg Keeper Regulator
    @param controller `MainController` address
    @param stable Address of the protocol stablecoin
    @param pool Curve StableSwap-ng pool where the peg keeper is active
    @param caller_share Caller's share of profit (with SHARE_PRECISION precision)
    """
    assert pool.N_COINS() == 2, "DFM:PK Wrong N_COINS"

    CORE_OWNER = core
    POOL = pool
    CONTROLLER = controller
    STABLECOIN = stable
    stable.approve(pool.address, max_value(uint256))

    has_stable: bool = False
    coins: ERC20[2] = [ERC20(pool.coins(0)), ERC20(pool.coins(1))]
    for i in range(2):
        if coins[i] == stable:
            I = i
            IS_INVERSE = (i == 0)
            has_stable = True
        else:
            PEG_MUL = 10 ** (18 - coins[i].decimals())

    assert has_stable, "DFM:PK Stablecoin not in pool"

    self.regulator = regulator
    log SetNewRegulator(regulator.address)

    assert caller_share <= SHARE_PRECISION  # dev: bad part value
    self.caller_share = caller_share
    log SetNewCallerShare(caller_share)


# --- external view functions ---

@view
@external
def owner() -> address:
    return CORE_OWNER.owner()


@view
@external
def calc_profit() -> uint256:
    """
    @notice Calculate generated profit in LP tokens. Does NOT include already withdrawn profit
    @return Amount of generated profit
    """
    return self._calc_profit()


@view
@external
def estimate_caller_profit() -> uint256:
    """
    @notice Estimate profit from calling update()
    @dev Users should instead call `PegKeeperRegulator.estimate_caller_profit`
         which returns the same value but with additional checks.
    @return Expected amount of profit going to beneficiary
    """
    balance_pegged: uint256 = POOL.balances(I)
    balance_peg: uint256 = POOL.balances(1 - I) * PEG_MUL

    call_profit: uint256 = 0
    if balance_peg > balance_pegged:
        allowed: uint256 = self.regulator.get_max_provide(self)
        # this dumps stablecoin
        call_profit = self._calc_call_profit(min((balance_peg - balance_pegged) / 5, allowed), True)

    else:
        allowed: uint256 = self.regulator.get_max_withdraw(self)
        # this pumps stablecoin
        call_profit = self._calc_call_profit(min((balance_pegged - balance_peg) / 5, allowed), False)

    return call_profit * self.caller_share / SHARE_PRECISION


# --- unguarded nonpayable functions ---

@external
def withdraw_profit() -> uint256:
    """
    @notice Withdraw profit generated by Peg Keeper
    @return Amount of LP Tokens burned during the withdrawal
    """
    lp_amount: uint256 = self._calc_profit()
    if lp_amount < PRECISION:
        # do not withdraw if profit is too small
        return 0

    POOL.remove_liquidity(lp_amount, [0, 0], CORE_OWNER.feeReceiver())
    log Profit(lp_amount)
    return lp_amount


# --- owner-only nonpayable functions ---

@external
def set_new_caller_share(_new_caller_share: uint256):
    """
    @notice Set new update caller's part
    @param _new_caller_share Part with SHARE_PRECISION
    """
    assert msg.sender == CORE_OWNER.owner(), "DFM:PK Only owner"
    assert _new_caller_share <= SHARE_PRECISION  # dev: bad part value

    self.caller_share = _new_caller_share

    log SetNewCallerShare(_new_caller_share)


# --- controller-only nonpayable functions ---

@external
def set_regulator(_new_regulator: Regulator):
    """
    @notice Set new peg keeper regulator
    @dev Called during migration to a new regulator
    """
    assert msg.sender == CONTROLLER, "DFM:PK Only controller"
    assert _new_regulator.address != empty(address), "DFM:PK Invalid regulator"

    self.regulator = _new_regulator
    log SetNewRegulator(_new_regulator.address)


# -- regulator-only nonpayable functions ---

@external
def update(_beneficiary: address) -> (int256, uint256):
    """
    @notice Provide or withdraw coins from the pool to stabilize it
    @dev Called via the regulator
    @param _beneficiary Beneficiary address
    @return (change in peg keeper's debt, profit received by beneficiary)
    """
    self._assert_only_regulator()

    balance_pegged: uint256 = POOL.balances(I)
    balance_peg: uint256 = POOL.balances(1 - I) * PEG_MUL

    initial_profit: uint256 = self._calc_profit()

    debt_adjustment: int256 = 0
    if balance_peg > balance_pegged:
        allowed: uint256 = self.regulator.get_max_provide(self)
        assert allowed > 0, "DFM:PK Regulator ban"
        debt_adjustment = self._provide(min(unsafe_sub(balance_peg, balance_pegged) / 5, allowed))  # this dumps stablecoin

    else:
        allowed: uint256 = self.regulator.get_max_withdraw(self)
        assert allowed > 0, "DFM:PK Regulator ban"
        debt_adjustment = self._withdraw(min(unsafe_sub(balance_pegged, balance_peg) / 5, allowed))  # this pumps stablecoin

    # Send generated profit
    new_profit: uint256 = self._calc_profit()
    assert new_profit > initial_profit, "DFM:PK Peg unprofitable"
    lp_amount: uint256 = new_profit - initial_profit
    caller_profit: uint256 = lp_amount * self.caller_share / SHARE_PRECISION
    if caller_profit > 0:
        POOL.transfer(_beneficiary, caller_profit)

    return (debt_adjustment, caller_profit)


@external
def recall_debt(amount: uint256) -> uint256:
    """
    @notice Burn a stablecoin balance held within this contract
    @dev Called by the regulator when reducing the peg keeper's debt ceiling
         or completely removing it from the system.
    @param amount Amount of stablecoin to burn. If the peg keeper's balance
                  is insufficient, the delta is tracked within `owed_debt`
                  and burned as it becomes available.
    @return Actual amount of stablecoin that was burned
    """
    self._assert_only_regulator()
    if amount == 0:
        return 0

    debt: uint256 = STABLECOIN.balanceOf(self)
    burned: uint256 = 0
    owed: uint256 = 0
    if debt >= amount:
        STABLECOIN.burn(self, amount)
        burned = amount
    else:
        if debt > 0:
            STABLECOIN.burn(self, debt)
            burned = debt
        owed = self.owed_debt + amount - burned
        self.owed_debt = owed

    log RecallDebt(amount, burned, owed)
    return burned


# --- internal functions ---

@view
@internal
def _assert_only_regulator():
    assert msg.sender == self.regulator.address, "DFM:PK Only regulator"


@pure
@internal
def _calc_profit_from(lp_balance: uint256, virtual_price: uint256, debt: uint256) -> uint256:
    """
    @notice PegKeeper's profit calculation formula
    """
    lp_debt: uint256 = debt * PRECISION / virtual_price

    if lp_balance <= lp_debt:
        return 0
    else:
        return lp_balance - lp_debt


@view
@internal
def _calc_profit() -> uint256:
    """
    @notice Calculate PegKeeper's profit using current values
    """
    return self._calc_profit_from(POOL.balanceOf(self), POOL.get_virtual_price(), self.debt)


@view
@internal
def _calc_call_profit(_amount: uint256, _is_deposit: bool) -> uint256:
    """
    @notice Calculate overall profit from calling update()
    """
    lp_balance: uint256 = POOL.balanceOf(self)
    virtual_price: uint256 = POOL.get_virtual_price()
    debt: uint256 = self.debt
    initial_profit: uint256 = self._calc_profit_from(lp_balance, virtual_price, debt)

    amount: uint256 = _amount
    if _is_deposit:
        amount = min(_amount, STABLECOIN.balanceOf(self))
    else:
        amount = min(_amount, debt)

    amounts: DynArray[uint256, 2] = [0, 0]
    amounts[I] = amount
    lp_balance_diff: uint256 = POOL.calc_token_amount(amounts, _is_deposit)

    if _is_deposit:
        lp_balance += lp_balance_diff
        debt += amount
    else:
        lp_balance -= lp_balance_diff
        debt -= amount

    new_profit: uint256 = self._calc_profit_from(lp_balance, virtual_price, debt)
    if new_profit <= initial_profit:
        return 0
    return new_profit - initial_profit


@internal
def _burn_owed_debt():
    owed_debt: uint256 = self.owed_debt
    if owed_debt > 0:
        debt_reduce: uint256 = min(owed_debt, STABLECOIN.balanceOf(self))
        if debt_reduce > 0:
            STABLECOIN.burn(self, debt_reduce)
            owed_debt -= debt_reduce
            self.owed_debt = owed_debt
            log RecallDebt(0, debt_reduce, owed_debt)


@internal
def _provide(_amount: uint256) -> int256:
    """
    @notice Implementation of provide
    @dev Coins should be already in the contract
    """
    if _amount == 0:
        return 0

    self._burn_owed_debt()

    amount: uint256 = min(_amount, STABLECOIN.balanceOf(self))

    amounts: DynArray[uint256, 2] = [0, 0]
    amounts[I] = amount
    POOL.add_liquidity(amounts, 0)

    self.last_change = block.timestamp
    self.debt += amount
    log Provide(amount)

    return convert(amount, int256)


@internal
def _withdraw(_amount: uint256) -> int256:
    """
    @notice Implementation of withdraw
    """
    if _amount == 0:
        return 0

    debt: uint256 = self.debt
    amount: uint256 = min(_amount, debt)

    amounts: DynArray[uint256, 2] = [0, 0]
    amounts[I] = amount
    POOL.remove_liquidity_imbalance(amounts, max_value(uint256))

    self.last_change = block.timestamp
    self.debt = debt - amount

    self._burn_owed_debt()

    log Withdraw(amount)

    return -convert(amount, int256)