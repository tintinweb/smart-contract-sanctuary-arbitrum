#pragma version 0.3.10
"""
@title Peg Keeper Regulator
@author Curve.Fi (with edits by defidotmoney)
@license MIT
@notice Regulations for Peg Keeper
"""

interface ERC20:
    def balanceOf(_owner: address) -> uint256: view
    def transfer(receiver: address, amount: uint256) -> bool: nonpayable
    def mint(target: address, amount: uint256) -> bool: nonpayable
    def burn(target: address, amount: uint256) -> bool: nonpayable

interface StableSwapNG:
    def get_p(i: uint256) -> uint256: view
    def price_oracle(i: uint256) -> uint256: view

interface PegKeeper:
    def POOL() -> StableSwapNG: view
    def regulator() -> address: view
    def debt() -> uint256: view
    def owed_debt() -> uint256: view
    def IS_INVERSE() -> bool: view
    def estimate_caller_profit() -> uint256: view
    def recall_debt(amount: uint256) -> uint256: nonpayable
    def update(_beneficiary: address) -> (int256, uint256): nonpayable
    def withdraw_profit(): nonpayable

interface PriceOracle:
    def price() -> uint256: view

interface CoreOwner:
    def owner() -> address: view
    def feeReceiver() -> address: view


event AddPegKeeper:
    peg_keeper: PegKeeper
    pool: StableSwapNG
    is_inverse: bool

event RemovePegKeeper:
    peg_keeper: PegKeeper

event WorstPriceThreshold:
    threshold: uint256

event PriceDeviation:
    price_deviation: uint256

event ActionDelay:
    action_delay: uint256

event DebtParameters:
    alpha: uint256
    beta: uint256

event SetKilled:
    is_killed: Killed
    by: address


struct PegKeeperInfo:
    peg_keeper: PegKeeper
    pool: StableSwapNG
    is_inverse: bool
    debt_ceiling: uint256
    last_change: uint256


enum Killed:
    Provide  # 1
    Withdraw  # 2


MAX_LEN: constant(uint256) = 8
ONE: constant(uint256) = 10 ** 18

STABLECOIN: public(immutable(ERC20))
CORE_OWNER: public(immutable(CoreOwner))
CONTROLLER: public(immutable(address))
STABLECOIN_ORACLE: public(immutable(PriceOracle))

peg_keepers: public(DynArray[PegKeeperInfo, MAX_LEN])
peg_keeper_i: HashMap[PegKeeper,  uint256]  # 1 + index of peg keeper in a list

max_debt: public(uint256)
active_debt: public(uint256)

worst_price_threshold: public(uint256)  # 3 * 10 ** 14  # 0.0003
price_deviation: public(uint256)        # 5 * 10 ** 14 # 0.0005 = 0.05%
action_delay: public(uint256)
alpha: public(uint256)  # Initial boundary
beta: public(uint256)  # Each PegKeeper's impact

is_killed: public(Killed)


@external
def __init__(
    core: CoreOwner,
    controller: address,
    stablecoin: ERC20,
    stable_oracle: PriceOracle,
    worst_price_threshold: uint256,
    price_deviation: uint256,
    action_delay: uint256,
):
    """
    @notice Contract constructor
    @param core `DFMProtocolCore` address. Ownership is inherited from this contract.
    @param stablecoin Address of the protocol stablecoin. This contract must be given
                  minter privileges within the stablecoin.
    @param stable_oracle `AggregatorStablePrice` address. Used to determine the stablecoin price.
    @param controller `MainController` address. After deployment, this address must be
                      set within the controller using `set_peg_keeper_regulator`.
    @param worst_price_threshold Price threshold with 1e18 precision.
    @param price_deviation Acceptable price deviation with 1e18 precision.
    @param action_delay Minimum time between PegKeeper updates.
    """
    CORE_OWNER = core
    CONTROLLER = controller
    STABLECOIN = stablecoin
    STABLECOIN_ORACLE = stable_oracle

    assert action_delay <= 900  # 15 minutes
    assert worst_price_threshold <= 10 ** 16  # 0.01
    assert price_deviation <= 10 ** 20

    self.worst_price_threshold = worst_price_threshold
    self.price_deviation = price_deviation
    self.action_delay = action_delay
    self.alpha = ONE / 2 # 1/2
    self.beta = ONE / 4  # 1/4

    log WorstPriceThreshold(worst_price_threshold)
    log PriceDeviation(price_deviation)
    log ActionDelay(action_delay)
    log DebtParameters(self.alpha, self.beta)


# --- external view functions ---

@view
@external
def owner() -> address:
    return CORE_OWNER.owner()


@view
@external
def get_peg_keepers_with_debt_ceilings() -> (DynArray[address, MAX_LEN], DynArray[uint256, MAX_LEN]):
    """
    @notice Gets all active peg keepers and their current debt ceilings
    """
    peg_keepers: DynArray[address, MAX_LEN] = []
    debt_ceilings: DynArray[uint256, MAX_LEN] = []
    for info in self.peg_keepers:
        peg_keepers.append(info.peg_keeper.address)
        debt_ceilings.append(info.debt_ceiling)

    return peg_keepers, debt_ceilings


@view
@external
def estimate_caller_profit(pk: PegKeeper) -> uint256:
    """
    @notice Estimate profit for the caller
    @dev Estimate the profit that the caller will receive when calling `update` function.
         The result is not precise, real profit is always more because of increasing virtual price.
    @param pk Address of the peg keeper to estimate profit for
    @return Estimated profit for the caller
    """
    i: uint256 = self.peg_keeper_i[pk]
    if i > 0 and self.peg_keepers[i - 1].last_change + self.action_delay < block.timestamp:
        return pk.estimate_caller_profit()

    return 0


@view
@external
def owed_debt() -> uint256:
    """
    @notice Total owed debt across all active peg keepers
    @dev Debt becomes "owed" if a peg keeper's ceiling is reduced
         but the keeper does not have enough available balance to
         meet the reduction requirement. Each time the keeper withdraws
         from it's pool it will burn the received tokens until the owed
         debt returns to zero.
    """
    debt: uint256 = 0
    for info in self.peg_keepers:
        debt += info.peg_keeper.owed_debt()
    return debt


@view
@external
def get_max_provide(pk: PegKeeper) -> uint256:
    """
    @notice Allow PegKeeper to provide stablecoin into the pool
    @dev Can return more amount than available
    @dev Checks
        1) current price in range of oracle in case of spam-attack
        2) current price location among other pools in case of contrary coin depeg
        3) stablecoin price is above 1
    @param pk Address of the peg keeper to check max deposit amount for
    @return Amount of stablecoin allowed to provide
    """
    if self.is_killed in Killed.Provide:
        return 0

    if STABLECOIN_ORACLE.price() < ONE:
        return 0

    price: uint256 = max_value(uint256)
    largest_price: uint256 = 0
    debt_ratios: DynArray[uint256, MAX_LEN] = []
    for info in self.peg_keepers:
        price_oracle: uint256 = self._get_price_oracle(info)
        if info.peg_keeper == pk:
            price = price_oracle
            if not self._price_in_range(price, self._get_price(info)):
                return 0
            continue
        elif largest_price < price_oracle:
            largest_price = price_oracle
        debt_ratios.append(self._get_ratio(info.peg_keeper))

    # underflow here is OK, in a severe depeg we do not wish to add liquidity
    if largest_price < unsafe_sub(price, self.worst_price_threshold):
        return 0

    debt: uint256 = pk.debt()
    total: uint256 = debt + STABLECOIN.balanceOf(pk.address)
    return self._get_max_ratio(debt_ratios) * total / ONE - debt


@view
@external
def get_max_withdraw(pk: PegKeeper) -> uint256:
    """
    @notice Allow Peg Keeper to withdraw stablecoin from the pool
    @dev Can return more amount than available
    @dev Checks
        1) current price in range of oracle in case of spam-attack
        2) stablecoin price is below 1
    @param pk Address of the peg keeper to check max withdrawal amount for
    @return Amount of stablecoin allowed to withdraw
    """
    if self.is_killed in Killed.Withdraw:
        return 0

    if STABLECOIN_ORACLE.price() > ONE:
        return 0

    i: uint256 = self.peg_keeper_i[pk]
    if i > 0:
        info: PegKeeperInfo = self.peg_keepers[i - 1]
        if self._price_in_range(self._get_price(info), self._get_price_oracle(info)):
            return max_value(uint256)
    return 0


# --- unguarded nonpayable functions ---

@external
@nonreentrant("lock")
def update(pk: PegKeeper, beneficiary: address = msg.sender) -> uint256:
    """
    @notice Provide or withdraw coins from the pool to stabilize it
    @param pk PegKeeper to provide or withdraw from
    @param beneficiary Address to send earned profits to
    @return Amount of profit received by beneficiary
    """
    i: uint256 = self.peg_keeper_i[pk]
    assert i != 0, "DFM:R Unknown PegKeeper"
    assert self.peg_keepers[i - 1].last_change + self.action_delay < block.timestamp, "DFM:R Action delay still active"

    debt_adjustment: int256 = 0
    caller_profit: uint256 = 0
    (debt_adjustment, caller_profit) = pk.update(beneficiary)
    if debt_adjustment != 0:
        self.peg_keepers[i - 1].last_change = block.timestamp
        self.active_debt = self._uint_plus_int(self.active_debt, debt_adjustment)

    return caller_profit


@external
def withdraw_profit():
    """
    @notice Withdraw profit from all peg keepers
    """
    for info in self.peg_keepers:
        info.peg_keeper.withdraw_profit()


# --- owner-only nonpayable functions ---

@external
def add_peg_keeper(pk: PegKeeper, debt_ceiling: uint256):
    """
    @notice Add a new peg keeper
    @param pk Address of the peg keeper to add
    @param debt_ceiling Amount of stablecoin allocated to the peg keeper
    """
    self._assert_only_owner()
    assert self.peg_keeper_i[pk] == empty(uint256)  # dev: duplicate
    assert pk.debt() == 0, "DFM:R keeper has debt"

    info: PegKeeperInfo = PegKeeperInfo({
        peg_keeper: pk,
        pool: pk.POOL(),
        is_inverse: pk.IS_INVERSE(),
        debt_ceiling: debt_ceiling,
        last_change: 0,
    })
    self.peg_keepers.append(info)  # dev: too many pairs
    self.peg_keeper_i[pk] = len(self.peg_keepers)

    # confirm StableSwapNG interface
    self._get_price_oracle(info)

    if debt_ceiling > 0:
        self._mint(pk, debt_ceiling)

    log AddPegKeeper(info.peg_keeper, info.pool, info.is_inverse)



@external
def adjust_peg_keeper_debt_ceiling(pk: PegKeeper, debt_ceiling: uint256):
    """
    @notice Adjust debt ceiling for an active peg keeper
    @dev If the ceiling is reduced, and the peg keeper does not have
         a sufficient balance to immediately repay the funds, it will
         record the remaining amount as "owed debt" and reduce it on
         subsequent interactions where possible.
    @param pk Address of the peg keeper to adjust the ceiling for
    @param debt_ceiling New amount of stablecoin allocated to the peg keeper.
                        If the ceiling increases, coins are minted.
                        If the ceiling decreases, coins are burned.
    """
    self._assert_only_owner()
    i: uint256 = self.peg_keeper_i[pk] - 1  # dev: pool not found

    current_debt_ceiling: uint256 = self.peg_keepers[i].debt_ceiling
    if current_debt_ceiling > debt_ceiling:
        self._recall_debt(pk, current_debt_ceiling - debt_ceiling)
    else:
        self._mint(pk, debt_ceiling - current_debt_ceiling)

    self.peg_keepers[i].debt_ceiling = debt_ceiling


@external
def remove_peg_keeper(pk: PegKeeper):
    """
    @notice Remove an existing peg keeper
    @dev A peg keeper cannot be removed while it has active debt,
         in that case the debt ceiling should first be set to zero.
    @param pk Address of the peg keeper to remove
    """
    self._assert_only_owner()

    peg_keepers: DynArray[PegKeeperInfo, MAX_LEN] = self.peg_keepers

    i: uint256 = self.peg_keeper_i[pk] - 1  # dev: pool not found

    debt_ceiling: uint256 = self.peg_keepers[i].debt_ceiling
    if debt_ceiling > 0:
        self._recall_debt(pk, debt_ceiling)

    assert pk.debt() == 0, "DFM:R keeper has debt"

    max_n: uint256 = len(self.peg_keepers) - 1
    if i < max_n:
        self.peg_keepers[i] = self.peg_keepers[max_n]
        self.peg_keeper_i[self.peg_keepers[i].peg_keeper] = 1 + i

    self.peg_keepers.pop()
    self.peg_keeper_i[pk] = empty(uint256)

    log RemovePegKeeper(pk)


@external
def set_action_delay(action_delay: uint256):
    """
    @notice Set minimum time between PegKeeper updates
    @dev Action delay is applied per-PegKeeper. Time passed must be greater than
         the given duration. If set to zero, updates are limited to once per block.
    @param action_delay PegKeeper action delay in seconds.
    """
    self._assert_only_owner()
    assert action_delay <= 900  # 15 minutes
    self.action_delay = action_delay
    log ActionDelay(action_delay)


@external
def set_worst_price_threshold(_threshold: uint256):
    """
    @notice Set threshold for the worst price that is still accepted
    @dev If this threshold is violated (due to depeg of one of the paired assets)
         the peg keepers will not provide any further liquidity.
    @param _threshold Price threshold with base 10 ** 18 (1.0 = 10 ** 18)
    """
    self._assert_only_owner()
    assert _threshold <= 10 ** (18 - 2)  # 0.01
    self.worst_price_threshold = _threshold
    log WorstPriceThreshold(_threshold)


@external
def set_price_deviation(_deviation: uint256):
    """
    @notice Set acceptable deviation of current price from oracle's
    @dev Setting to 10**20 effectively disables this check
    @param _deviation Deviation of price with base 10 ** 18 (1.0 = 10 ** 18)
    """
    self._assert_only_owner()
    assert _deviation <= 10 ** 20
    self.price_deviation = _deviation
    log PriceDeviation(_deviation)


@external
def set_debt_parameters(_alpha: uint256, _beta: uint256):
    """
    @notice Set parameters for calculation of debt limits
    @dev 10 ** 18 precision
    """
    self._assert_only_owner()
    assert _alpha <= ONE
    assert _beta <= ONE

    self.alpha = _alpha
    self.beta = _beta
    log DebtParameters(_alpha, _beta)


@external
def set_killed(_is_killed: Killed):
    """
    @notice Pause/unpause Peg Keepers
    @dev 0 unpause, 1 provide, 2 withdraw, 3 everything
    """
    self._assert_only_owner()
    self.is_killed = _is_killed
    log SetKilled(_is_killed, msg.sender)


# --- controller-only nonpayble functions ---

@external
def init_migrate_peg_keepers(peg_keepers: DynArray[PegKeeper, MAX_LEN], debt_ceilings: DynArray[uint256, MAX_LEN]):
    """
    @notice Add peg keepers and debt ceilings from another PegKeeperRegulator deployment
    @dev Called via `MainController.set_peg_keeper_regulator`
    """
    assert msg.sender == CONTROLLER, "DFM:R Only controller"
    assert len(self.peg_keepers) == 0, "DFM:R Already set"

    max_debt: uint256 = 0
    active_debt: uint256 = 0
    for i in range(MAX_LEN):
        if i == len(peg_keepers): break
        pk: PegKeeper = peg_keepers[i]

        assert self.peg_keeper_i[pk] == empty(uint256)  # dev: duplicate

        # verify that the regulator has permission to call `recall_debt`
        pk.recall_debt(0)

        info: PegKeeperInfo = PegKeeperInfo({
            peg_keeper: pk,
            pool: pk.POOL(),
            is_inverse: pk.IS_INVERSE(),
            debt_ceiling: debt_ceilings[i],
            last_change: block.timestamp,
        })
        self.peg_keepers.append(info)  # dev: too many pairs
        self.peg_keeper_i[pk] = len(self.peg_keepers)

        max_debt += debt_ceilings[i]
        active_debt += pk.debt()

    self.max_debt = max_debt
    self.active_debt = active_debt


# --- internal functions ---

@view
@internal
def _assert_only_owner():
    assert msg.sender == CORE_OWNER.owner(), "DFM:R Only owner"


@pure
@internal
def _get_price(_info: PegKeeperInfo) -> uint256:
    """
    @return Price of the coin in STABLECOIN
    """
    price: uint256 = _info.pool.get_p(0)
    if _info.is_inverse:
        price = 10 ** 36 / price
    return price


@pure
@internal
def _get_price_oracle(_info: PegKeeperInfo) -> uint256:
    """
    @return Price of the coin in STABLECOIN
    """
    price: uint256 = _info.pool.price_oracle(0)
    if _info.is_inverse:
        price = 10 ** 36 / price
    return price


@view
@internal
def _price_in_range(_p0: uint256, _p1: uint256) -> bool:
    """
    @notice Check that the price is in accepted range using absolute error
    @dev Needed for spam-attack protection
    """
    # |p1 - p0| <= deviation
    # -deviation <= p1 - p0 <= deviation
    # 0 < deviation + p1 - p0 <= 2 * deviation
    # can use unsafe
    deviation: uint256 = self.price_deviation
    return unsafe_sub(unsafe_add(deviation, _p0), _p1) < deviation << 1


@view
@internal
def _get_ratio(_peg_keeper: PegKeeper) -> uint256:
    """
    @return debt ratio limited up to 1
    """
    debt: uint256 = _peg_keeper.debt()
    return debt * ONE / (1 + debt + STABLECOIN.balanceOf(_peg_keeper.address))


@view
@internal
def _get_max_ratio(_debt_ratios: DynArray[uint256, MAX_LEN]) -> uint256:
    rsum: uint256 = 0
    for r in _debt_ratios:
        rsum += isqrt(r * ONE)
    return (self.alpha + self.beta * rsum / ONE) ** 2 / ONE


@pure
@internal
def _uint_plus_int(initial: uint256, adjustment: int256) -> uint256:
    if adjustment < 0:
        return initial - convert(-adjustment, uint256)
    else:
        return initial + convert(adjustment, uint256)


@internal
def _mint(pk: PegKeeper, amount: uint256):
     # always verify the regulator can `recall_debt` prior to minting
    pk.recall_debt(0)

    STABLECOIN.mint(pk.address, amount)
    self.max_debt += amount


@internal
def _recall_debt(pk: PegKeeper, reduce_amount: uint256):
    pk.recall_debt(reduce_amount)
    self.max_debt -= reduce_amount