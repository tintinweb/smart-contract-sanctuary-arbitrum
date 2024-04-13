# @version 0.3.9

N_COINS: constant(uint256) = 3
PRECISION: constant(uint256) = 10**18

interface Curve:
    def MATH() -> Math: view
    def A() -> uint256: view
    def gamma() -> uint256: view
    def price_scale(i: uint256) -> uint256: view
    def price_oracle(i: uint256) -> uint256: view
    def get_virtual_price() -> uint256: view
    def balances(i: uint256) -> uint256: view
    def D() -> uint256: view
    def fee_calc(xp: uint256[N_COINS]) -> uint256: view
    def calc_token_fee(
        amounts: uint256[N_COINS], xp: uint256[N_COINS]
    ) -> uint256: view
    def future_A_gamma_time() -> uint256: view
    def totalSupply() -> uint256: view
    def precisions() -> uint256[N_COINS]: view
    def packed_fee_params() -> uint256: view

interface Math:
    def newton_D(
        ANN: uint256,
        gamma: uint256,
        x_unsorted: uint256[N_COINS],
        K0_prev: uint256
    ) -> uint256: view
    def get_y(
        ANN: uint256,
        gamma: uint256,
        x: uint256[N_COINS],
        D: uint256,
        i: uint256,
    ) -> uint256[2]: view
    def cbrt(x: uint256) -> uint256: view
    def reduction_coefficient(
        x: uint256[N_COINS], fee_gamma: uint256
    ) -> uint256: view


@external
@view
def prep_calc(swap: address) -> (
    uint256[N_COINS],
    uint256,
    uint256,
    uint256[N_COINS-1],
    uint256,
    uint256,
    uint256[N_COINS]
):

    precisions: uint256[N_COINS] = Curve(swap).precisions()
    token_supply: uint256 = Curve(swap).totalSupply()
    xp: uint256[N_COINS] = empty(uint256[N_COINS])
    for k in range(N_COINS):
        xp[k] = Curve(swap).balances(k)

    price_scale: uint256[N_COINS - 1] = empty(uint256[N_COINS - 1])
    for k in range(N_COINS - 1):
        price_scale[k] = Curve(swap).price_scale(k)

    A: uint256 = Curve(swap).A()
    gamma: uint256 = Curve(swap).gamma()
    D: uint256 = self._calc_D_ramp(
        A, gamma, xp, precisions, price_scale, swap
    )

    return xp, D, token_supply, price_scale, A, gamma, precisions

@internal
@view
def _calc_D_ramp(
    A: uint256,
    gamma: uint256,
    xp: uint256[N_COINS],
    precisions: uint256[N_COINS],
    price_scale: uint256[N_COINS - 1],
    swap: address
) -> uint256:

    math: Math = Curve(swap).MATH()

    D: uint256 = Curve(swap).D()
    if Curve(swap).future_A_gamma_time() > block.timestamp:
        _xp: uint256[N_COINS] = xp
        _xp[0] *= precisions[0]
        for k in range(N_COINS - 1):
            _xp[k + 1] = (
                _xp[k + 1] * price_scale[k] * precisions[k + 1] / PRECISION
            )
        D = math.newton_D(A, gamma, _xp, 0)

    return D