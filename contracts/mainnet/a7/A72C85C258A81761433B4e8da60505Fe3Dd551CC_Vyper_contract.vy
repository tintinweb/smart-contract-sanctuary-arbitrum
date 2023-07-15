# @version 0.3.7

# A "zap" for crypto pools to get_dx
# (c) Curve.Fi, 2023

interface ERC20:
    def decimals() -> uint256: view

interface Curve:
    def A() -> uint256: view
    def gamma() -> uint256: view
    def price_scale(i: uint256) -> uint256: view
    def coins(i: uint256) -> address: view
    def balances(i: uint256) -> uint256: view
    def D() -> uint256: view
    def fee_calc(xp: uint256[3]) -> uint256: view
    def future_A_gamma_time() -> uint256: view

interface Curve2:
    def price_scale() -> uint256: view

interface Math3:
    def newton_D(ANN: uint256, gamma: uint256, x_unsorted: uint256[3]) -> uint256: view
    def newton_y(ANN: uint256, gamma: uint256, x: uint256[3], D: uint256, i: uint256) -> uint256: view

interface Math2:
    def newton_D(ANN: uint256, gamma: uint256, x_unsorted: uint256[2]) -> uint256: view
    def newton_y(ANN: uint256, gamma: uint256, x: uint256[2], D: uint256, i: uint256) -> uint256: view
    def fee_calc(pool: address, xp: uint256[2]) -> uint256: view

interface StablePool:
    def calc_withdraw_one_coin(_token_amount: uint256, i: int128) -> uint256: view

interface StableCalcZap:
    def calc_token_amount(pool: address, token: address, amounts: uint256[MAX_COINS], n_coins: uint256, deposit: bool, use_underlying: bool) -> uint256: view
    def get_dx_underlying(pool: address, i: int128, j: int128, dy: uint256, n_coins: uint256) -> uint256: view

interface AtricryptoZap:
    def calc_token_amount(amounts: uint256[5], deposit: bool) -> uint256: view
    def calc_withdraw_one_coin(token_amount: uint256, i: uint256) -> uint256: view


STABLE_CALC_ZAP: constant(address) = 0xCA8d0747B5573D69653C3aC22242e6341C36e4b4
MATH2: constant(address) = 0x69522fb5337663d3B4dFB0030b881c1A750Adb4f
MATH3: constant(address) = 0x4f37A9d177470499A2dD084621020b023fcffc1F
MAX_COINS: constant(uint256) = 10
PRECISION: constant(uint256) = 10**18  # The precision to convert to


@internal
@view
def _get_dx_2_coins(
        pool: address,
        i: uint256,
        j: uint256,
        dy: uint256,
        xp: DynArray[uint256, MAX_COINS],
        precisions: DynArray[uint256, MAX_COINS],
        price_scale: DynArray[uint256, MAX_COINS],
) -> uint256:
    A: uint256 = Curve(pool).A()
    gamma: uint256 = Curve(pool).gamma()
    D: uint256 = Curve(pool).D()
    _xp_initial: uint256[2] = [
        xp[0] * precisions[0],
        xp[1] * price_scale[0] * precisions[1] / PRECISION,
    ]
    if Curve(pool).future_A_gamma_time() > 0:
        D = Math2(MATH2).newton_D(A, gamma, _xp_initial)

    _fee: uint256 = 0
    x: uint256 = 0
    for k in range(10):
        _xp: uint256[2] = [xp[0], xp[1]]
        _xp[j] -= dy * 10 ** 10 / (10 ** 10 - _fee)
        _xp[0] *= precisions[0]
        _xp[1] = _xp[1] * price_scale[0] * precisions[1] / PRECISION
        x = Math2(MATH2).newton_y(A, gamma, _xp, D, i)
        _xp[i] = x
        _fee = Math2(MATH2).fee_calc(pool, _xp)

    dx: uint256 = x - _xp_initial[i] + 1
    if i > 0:
        dx = dx * PRECISION / price_scale[i - 1]
    dx /= precisions[i]

    return dx


@internal
@view
def _get_dx_3_coins(
        pool: address,
        i: uint256,
        j: uint256,
        dy: uint256,
        xp: DynArray[uint256, MAX_COINS],
        precisions: DynArray[uint256, MAX_COINS],
        price_scale: DynArray[uint256, MAX_COINS],
) -> uint256:
    A: uint256 = Curve(pool).A()
    gamma: uint256 = Curve(pool).gamma()
    D: uint256 = Curve(pool).D()
    _xp_initial: uint256[3] = [
        xp[0] * precisions[0],
        xp[1] * price_scale[0] * precisions[1] / PRECISION,
        xp[2] * price_scale[1] * precisions[2] / PRECISION,
    ]
    if Curve(pool).future_A_gamma_time() > 0:
        D = Math3(MATH3).newton_D(A, gamma, _xp_initial)

    # Calc new balances without fees

    _fee: uint256 = 0
    x: uint256 = 0
    for k in range(10):
        _xp: uint256[3] = [xp[0], xp[1], xp[2]]
        _xp[j] -= dy * 10**10 / (10**10 - _fee)
        _xp[0] *= precisions[0]
        _xp[1] = _xp[1] * price_scale[0] * precisions[1] / PRECISION
        _xp[2] = _xp[2] * price_scale[1] * precisions[2] / PRECISION
        x = Math3(MATH3).newton_y(A, gamma, _xp, D, i)
        _xp[i] = x
        _fee = Curve(pool).fee_calc(_xp)

    dx: uint256 = x - _xp_initial[i] + 1
    if i > 0:
        dx = dx * PRECISION / price_scale[i - 1]
    dx /= precisions[i]

    return dx


@internal
@view
def _get_dx(pool: address, i: uint256, j: uint256, dy: uint256, n_coins: uint256) -> uint256:
    assert i != j and i < MAX_COINS and j < MAX_COINS, "coin index out of range"
    assert dy > 0, "do not exchange 0 coins"

    precisions: DynArray[uint256, MAX_COINS] = []
    xp: DynArray[uint256, MAX_COINS] = []
    for k in range(MAX_COINS):
        if k == n_coins:
            break
        xp.append(Curve(pool).balances(k))
        coin: address = Curve(pool).coins(k)
        precisions.append(10**(18 - ERC20(coin).decimals()))

    price_scale: DynArray[uint256, MAX_COINS] = []
    for k in range(MAX_COINS):
        if k == n_coins - 1:
            break
        if n_coins == 2:
            price_scale.append(Curve2(pool).price_scale())
            break
        price_scale.append(Curve(pool).price_scale(k))

    if n_coins == 3:
        return self._get_dx_3_coins(pool, i, j, dy, xp, precisions, price_scale)
    else:
        return self._get_dx_2_coins(pool, i, j, dy, xp, precisions, price_scale)


@external
@view
def get_dx(pool: address, i: uint256, j: uint256, dy: uint256, n_coins: uint256) -> uint256:
    """
    @notice Calculate the input amount required to receive the desired output amount.
    @param pool Address of the pool
    @param i Input coin index
    @param j Output coin index
    @param dy Desired amount of the coin going out
    @param n_coins Number of coins in the pool
    @return Required input amount
    """
    return self._get_dx(pool, i, j, dy, n_coins)


@external
@view
def get_dx_meta_underlying(pool: address, i: uint256, j: uint256, dy: uint256, n_coins: uint256, base_pool: address, base_token: address) -> uint256:
    """
    @notice Calculate the input amount required to receive the desired output amount.
            For underlying calculations in meta pool of a type [coin, stable-pool-LP].
    @param pool Address of the pool
    @param i Input coin index
    @param j Output coin index
    @param dy Desired amount of the coin going out
    @param n_coins Number of coins in the pool
    @param base_pool Address of the base pool
    @param base_token Address of the base pool's LP token
    @return Required input amount
    """
    # [coin] + [...n_meta_coins...]
    if i > 0 and j > 0:  # meta_coin1 -> meta_coin2
        return StableCalcZap(STABLE_CALC_ZAP).get_dx_underlying(base_pool, convert(i - 1, int128), convert(j - 1, int128), dy, n_coins - 1)
    elif i == 0:  # coin -> meta_coin
        # coin -(swap)-> LP -(remove)-> meta_coin (dy - meta_coin)
        # 1. lp_amount = calc_token_amount([..., dy, ...], deposit=False)
        # 2. dx = get_dx(0, 1, lp_amount)
        base_amounts: uint256[MAX_COINS] = empty(uint256[MAX_COINS])
        base_amounts[j - 1] = dy
        lp_amount: uint256 = StableCalcZap(STABLE_CALC_ZAP).calc_token_amount(base_pool, base_token, base_amounts, n_coins - 1, False, True)
        return self._get_dx(pool, 0, 1, lp_amount, 2)
    else:  # j == 0, meta_coin -> coin
        # meta_coin -(add)-> LP -(swap)-> coin (dy - coin)
        # 1. lp_amount = get_dx(1, 0, dy)
        # 2. dx = calc_withdraw_one_coin(lp_amount, i - 1)
        lp_amount: uint256 = self._get_dx(pool, 1, 0, dy, 2)
        # This is not right. Should be something like calc_add_one_coin. But tests say that it's precise enough.
        return StablePool(base_pool).calc_withdraw_one_coin(lp_amount, convert(i - 1, int128))


@internal
@view
def _get_dx_tricrypto_meta_underlying(pool: address, i: uint256, j: uint256, dy: uint256, n_coins: uint256, base_pool: address, base_token: address) -> uint256:
    # [...n_meta_coins...] + [coin1, coin2]
    n_meta_coins: uint256 = n_coins - 2
    if i < n_meta_coins and j < n_meta_coins:  # meta_coin1 -> meta_coin2
        return StableCalcZap(STABLE_CALC_ZAP).get_dx_underlying(base_pool, convert(i, int128), convert(j, int128), dy, n_meta_coins)
    elif i >= n_meta_coins and j >= n_meta_coins:  # coin1 -> coin2
        return self._get_dx(pool, i - n_meta_coins + 1, j - n_meta_coins + 1, dy, 3)
    elif i >= n_meta_coins:  # coin -> meta_coin
        # coin -(swap)-> LP -(remove)-> meta_coin (dy - meta_coin)
        # 1. lp_amount = calc_token_amount([..., dy, ...], deposit=False)
        # 2. dx = get_dx(1 or 2, 0, lp_amount)
        base_amounts: uint256[MAX_COINS] = empty(uint256[MAX_COINS])
        base_amounts[j] = dy
        lp_amount: uint256 = StableCalcZap(STABLE_CALC_ZAP).calc_token_amount(base_pool, base_token, base_amounts, n_meta_coins, False, True)
        return self._get_dx(pool, i - n_meta_coins + 1, 0, lp_amount, 3)
    else:  # j >= n_meta_coins, meta_coin -> coin
        # meta_coin -(add)-> LP -(swap)-> coin (dy - coin)
        # 1. lp_amount = get_dx(0, 1 or 2, dy)
        # 2. dx = calc_withdraw_one_coin(lp_amount, i - 1)
        lp_amount: uint256 = self._get_dx(pool, 0, j - n_meta_coins + 1, dy, 3)
        # This is not right. Should be something like calc_add_one_coin. But tests say that it's precise enough.
        return StablePool(base_pool).calc_withdraw_one_coin(lp_amount, convert(i, int128))


@external
@view
def get_dx_tricrypto_meta_underlying(pool: address, i: uint256, j: uint256, dy: uint256, n_coins: uint256, base_pool: address, base_token: address) -> uint256:
    """
    @notice Calculate the input amount required to receive the desired output amount.
            For underlying calculations in meta pool of a type [stable-pool-LP, coin1, coin2].
            xDAI (Gnosis): tricrypto
            Polygon: atricrypto3
            Avalanche: atricrypto, avaxcrypto
    @param pool Address of the pool
    @param i Input coin index
    @param j Output coin index
    @param dy Desired amount of the coin going out
    @param n_coins Number of coins in the pool
    @param base_pool Address of the base pool
    @param base_token Address of the base pool's LP token
    @return Required input amount
    """
    return self._get_dx_tricrypto_meta_underlying(pool, i, j, dy, n_coins, base_pool, base_token)


@external
@view
def get_dx_double_meta_underlying(
        pool: address,
        i: uint256,
        j: uint256,
        dy: uint256,
        base_pool: address,
        base_pool_zap: address,
        second_base_pool: address,
        second_base_token: address,
) -> uint256:
    """
    @notice Calculate the input amount required to receive the desired output amount.
            For underlying calculations in double meta pool of a type [coin, tricrypto-meta-pool-LP].
            Polygon: crv/tricrypto and wmatic/tricrypto.
    @param pool Address of the pool
    @param i Input coin index
    @param j Output coin index
    @param dy Desired amount of the coin going out
    @param base_pool Address of the base pool
    @param base_pool_zap Address of the base pool's zap for underlying calc_token_amount
    @param second_base_pool Address of the second base pool
    @param second_base_token Address of the second base pool's LP token
    @return Required input amount
    """
    # [coin] + [...n_meta_coins...]
    if i > 0 and j > 0:  # meta_coin1 -> meta_coin2
        return self._get_dx_tricrypto_meta_underlying(base_pool, i - 1, j - 1, dy, 5, second_base_pool, second_base_token)
    elif i == 0:  # coin -> meta_coin
        # coin -(swap)-> LP -(remove)-> meta_coin (dy - meta_coin)
        # 1. lp_amount = calc_token_amount([..., dy, ...], deposit=False)
        # 2. dx = get_dx(0, 1, lp_amount)
        base_amounts: uint256[5] = empty(uint256[5])
        base_amounts[j - 1] = dy
        lp_amount: uint256 = AtricryptoZap(base_pool_zap).calc_token_amount(base_amounts, False)
        return self._get_dx(pool, 0, 1, lp_amount, 2)
    else:  # j == 0, meta_coin -> coin
        # meta_coin -(add)-> LP -(swap)-> coin (dy - coin)
        # 1. lp_amount = get_dx(1, 0, dy)
        # 2. dx = calc_withdraw_one_coin(lp_amount, i - 1)
        lp_amount: uint256 = self._get_dx(pool, 1, 0, dy, 2)
        # This is not right. Should be something like calc_add_one_coin. But tests say that it's precise enough.
        return AtricryptoZap(base_pool_zap).calc_withdraw_one_coin(lp_amount, i - 1)