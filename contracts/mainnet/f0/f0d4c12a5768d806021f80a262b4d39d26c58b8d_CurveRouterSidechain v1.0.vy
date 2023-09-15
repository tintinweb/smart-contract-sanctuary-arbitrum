# @version 0.3.7

"""
@title CurveRouterSidechain v1.0
@author Curve.Fi
@license Copyright (c) Curve.Fi, 2020-2023 - all rights reserved
@notice Performs up to 5 swaps in a single transaction, can do estimations with get_dy and get_dx
"""

from vyper.interfaces import ERC20

interface StablePool:
    def exchange(i: int128, j: int128, dx: uint256, min_dy: uint256): payable
    def exchange_underlying(i: int128, j: int128, dx: uint256, min_dy: uint256): payable
    def get_dy(i: int128, j: int128, amount: uint256) -> uint256: view
    def get_dy_underlying(i: int128, j: int128, amount: uint256) -> uint256: view
    def coins(i: uint256) -> address: view
    def calc_withdraw_one_coin(token_amount: uint256, i: int128) -> uint256: view
    def remove_liquidity_one_coin(token_amount: uint256, i: int128, min_amount: uint256): nonpayable

interface CryptoPool:
    def exchange(i: uint256, j: uint256, dx: uint256, min_dy: uint256): payable
    def exchange_underlying(i: uint256, j: uint256, dx: uint256, min_dy: uint256): payable
    def get_dy(i: uint256, j: uint256, amount: uint256) -> uint256: view
    def get_dy_underlying(i: uint256, j: uint256, amount: uint256) -> uint256: view
    def calc_withdraw_one_coin(token_amount: uint256, i: uint256) -> uint256: view
    def remove_liquidity_one_coin(token_amount: uint256, i: uint256, min_amount: uint256): nonpayable

interface CryptoPoolETH:
    def exchange(i: uint256, j: uint256, dx: uint256, min_dy: uint256, use_eth: bool): payable

interface LendingBasePoolMetaZap:
    def exchange_underlying(pool: address, i: int128, j: int128, dx: uint256, min_dy: uint256): nonpayable

interface CryptoMetaZap:
    def get_dy(pool: address, i: uint256, j: uint256, dx: uint256) -> uint256: view
    def exchange(pool: address, i: uint256, j: uint256, dx: uint256, min_dy: uint256, use_eth: bool): payable

interface StablePool2Coins:
    def add_liquidity(amounts: uint256[2], min_mint_amount: uint256): payable
    def calc_token_amount(amounts: uint256[2], is_deposit: bool) -> uint256: view

interface CryptoPool2Coins:
    def calc_token_amount(amounts: uint256[2]) -> uint256: view

interface StablePool3Coins:
    def add_liquidity(amounts: uint256[3], min_mint_amount: uint256): payable
    def calc_token_amount(amounts: uint256[3], is_deposit: bool) -> uint256: view

interface CryptoPool3Coins:
    def calc_token_amount(amounts: uint256[3]) -> uint256: view

interface StablePool4Coins:
    def add_liquidity(amounts: uint256[4], min_mint_amount: uint256): payable
    def calc_token_amount(amounts: uint256[4], is_deposit: bool) -> uint256: view

interface CryptoPool4Coins:
    def calc_token_amount(amounts: uint256[4]) -> uint256: view

interface StablePool5Coins:
    def add_liquidity(amounts: uint256[5], min_mint_amount: uint256): payable
    def calc_token_amount(amounts: uint256[5], is_deposit: bool) -> uint256: view

interface CryptoPool5Coins:
    def calc_token_amount(amounts: uint256[5]) -> uint256: view

interface LendingStablePool3Coins:
    def add_liquidity(amounts: uint256[3], min_mint_amount: uint256, use_underlying: bool): payable
    def remove_liquidity_one_coin(token_amount: uint256, i: int128, min_amount: uint256, use_underlying: bool) -> uint256: nonpayable

interface Llamma:
    def get_dx(i: uint256, j: uint256, out_amount: uint256) -> uint256: view

interface WETH:
    def deposit(): payable
    def withdraw(_amount: uint256): nonpayable

# Calc zaps
interface StableCalc:
    def calc_token_amount(pool: address, token: address, amounts: uint256[10], n_coins: uint256, deposit: bool, use_underlying: bool) -> uint256: view
    def get_dx(pool: address, i: int128, j: int128, dy: uint256, n_coins: uint256) -> uint256: view
    def get_dx_underlying(pool: address, i: int128, j: int128, dy: uint256, n_coins: uint256) -> uint256: view
    def get_dx_meta(pool: address, i: int128, j: int128, dy: uint256, n_coins: uint256, base_pool: address) -> uint256: view
    def get_dx_meta_underlying(pool: address, i: int128, j: int128, dy: uint256, n_coins: uint256, base_pool: address, base_token: address) -> uint256: view

interface CryptoCalc:
    def get_dx(pool: address, i: uint256, j: uint256, dy: uint256, n_coins: uint256) -> uint256: view
    def get_dx_meta_underlying(pool: address, i: uint256, j: uint256, dy: uint256, n_coins: uint256, base_pool: address, base_token: address) -> uint256: view


struct AmountAndFee:
    amountReceived: uint256
    fee: uint256
    exchangeFeeRate: uint256


event Exchange:
    sender: indexed(address)
    receiver: indexed(address)
    route: address[11]
    swap_params: uint256[5][5]
    pools: address[5]
    in_amount: uint256
    out_amount: uint256


ETH_ADDRESS: constant(address) = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
WETH_ADDRESS: immutable(address)

# Calc zaps
STABLE_CALC: immutable(StableCalc)
CRYPTO_CALC: immutable(CryptoCalc)

is_approved: HashMap[address, HashMap[address, bool]]


@external
@payable
def __default__():
    pass


@external
def __init__( _weth: address, _stable_calc: address, _crypto_calc: address):
    WETH_ADDRESS = _weth
    STABLE_CALC = StableCalc(_stable_calc)
    CRYPTO_CALC = CryptoCalc(_crypto_calc)


@external
@payable
@nonreentrant('lock')
def exchange(
    _route: address[11],
    _swap_params: uint256[5][5],
    _amount: uint256,
    _expected: uint256,
    _pools: address[5]=empty(address[5]),
    _receiver: address=msg.sender
) -> uint256:
    """
    @notice Performs up to 5 swaps in a single transaction.
    @dev Routing and swap params must be determined off-chain. This
         functionality is designed for gas efficiency over ease-of-use.
    @param _route Array of [initial token, pool or zap, token, pool or zap, token, ...]
                  The array is iterated until a pool address of 0x00, then the last
                  given token is transferred to `_receiver`
    @param _swap_params Multidimensional array of [i, j, swap type, pool_type, n_coins] where
                        i is the index of input token
                        j is the index of output token

                        The swap_type should be:
                        1. for `exchange`,
                        2. for `exchange_underlying`,
                        3. for underlying exchange via zap: factory stable metapools with lending base pool `exchange_underlying`
                           and factory crypto-meta pools underlying exchange (`exchange` method in zap)
                        4. for coin -> LP token "exchange" (actually `add_liquidity`),
                        5. for lending pool underlying coin -> LP token "exchange" (actually `add_liquidity`),
                        6. for LP token -> coin "exchange" (actually `remove_liquidity_one_coin`)
                        7. for LP token -> lending or fake pool underlying coin "exchange" (actually `remove_liquidity_one_coin`)
                        8. for ETH <-> WETH

                        pool_type: 1 - stable, 2 - crypto, 3 - tricrypto, 4 - llamma
                        n_coins is the number of coins in pool
    @param _amount The amount of input token (`_route[0]`) to be sent.
    @param _expected The minimum amount received after the final swap.
    @param _pools Array of pools for swaps via zap contracts. This parameter is needed only for swap_type = 3.
    @param _receiver Address to transfer the final output token to.
    @return Received amount of the final output token.
    """
    input_token: address = _route[0]
    output_token: address = empty(address)
    amount: uint256 = _amount

    # validate / transfer initial token
    if input_token == ETH_ADDRESS:
        assert msg.value == amount
    else:
        assert msg.value == 0
        assert ERC20(input_token).transferFrom(msg.sender, self, amount, default_return_value=True)

    for i in range(1, 6):
        # 5 rounds of iteration to perform up to 5 swaps
        swap: address = _route[i*2-1]
        pool: address = _pools[i-1] # Only for Polygon meta-factories underlying swap (swap_type == 6)
        output_token = _route[i*2]
        params: uint256[5] = _swap_params[i-1]  # i, j, swap_type, pool_type, n_coins

        if not self.is_approved[input_token][swap]:
            assert ERC20(input_token).approve(swap, max_value(uint256), default_return_value=True, skip_contract_check=True)
            self.is_approved[input_token][swap] = True

        eth_amount: uint256 = 0
        if input_token == ETH_ADDRESS:
            eth_amount = amount
        # perform the swap according to the swap type
        if params[2] == 1:
            if params[3] == 1:  # stable
                StablePool(swap).exchange(convert(params[0], int128), convert(params[1], int128), amount, 0, value=eth_amount)
            else:  # crypto, tricrypto or llamma
                if input_token == ETH_ADDRESS or output_token == ETH_ADDRESS:
                    CryptoPoolETH(swap).exchange(params[0], params[1], amount, 0, True, value=eth_amount)
                else:
                    CryptoPool(swap).exchange(params[0], params[1], amount, 0)
        elif params[2] == 2:
            if params[3] == 1:  # stable
                StablePool(swap).exchange_underlying(convert(params[0], int128), convert(params[1], int128), amount, 0, value=eth_amount)
            else:  # crypto or tricrypto
                CryptoPool(swap).exchange_underlying(params[0], params[1], amount, 0, value=eth_amount)
        elif params[2] == 3:  # SWAP IS ZAP HERE !!!
            if params[3] == 1:  # stable
                LendingBasePoolMetaZap(swap).exchange_underlying(pool, convert(params[0], int128), convert(params[1], int128), amount, 0)
            else:  # crypto or tricrypto
                use_eth: bool = input_token == ETH_ADDRESS or output_token == ETH_ADDRESS
                CryptoMetaZap(swap).exchange(pool, params[0], params[1], amount, 0, use_eth, value=eth_amount)
        elif params[2] == 4:
            if params[4] == 2:
                amounts: uint256[2] = [0, 0]
                amounts[params[0]] = amount
                StablePool2Coins(swap).add_liquidity(amounts, 0, value=eth_amount)
            elif params[4] == 3:
                amounts: uint256[3] = [0, 0, 0]
                amounts[params[0]] = amount
                StablePool3Coins(swap).add_liquidity(amounts, 0, value=eth_amount)
            elif params[4] == 4:
                amounts: uint256[4] = [0, 0, 0, 0]
                amounts[params[0]] = amount
                StablePool4Coins(swap).add_liquidity(amounts, 0, value=eth_amount)
            elif params[4] == 5:
                amounts: uint256[5] = [0, 0, 0, 0, 0]
                amounts[params[0]] = amount
                StablePool5Coins(swap).add_liquidity(amounts, 0, value=eth_amount)
        elif params[2] == 5:
            amounts: uint256[3] = [0, 0, 0]
            amounts[params[0]] = amount
            LendingStablePool3Coins(swap).add_liquidity(amounts, 0, True, value=eth_amount) # example: aave on Polygon
        elif params[2] == 6:
            if params[3] == 1:  # stable
                StablePool(swap).remove_liquidity_one_coin(amount, convert(params[1], int128), 0)
            else:  # crypto or tricrypto
                CryptoPool(swap).remove_liquidity_one_coin(amount, params[1], 0)  # example: atricrypto3 on Polygon
        elif params[2] == 7:
            LendingStablePool3Coins(swap).remove_liquidity_one_coin(amount, convert(params[1], int128), 0, True) # example: aave on Polygon
        elif params[2] == 8:
            if input_token == ETH_ADDRESS and output_token == WETH_ADDRESS:
                WETH(swap).deposit(value=amount)
            elif input_token == WETH_ADDRESS and output_token == ETH_ADDRESS:
                WETH(swap).withdraw(amount)
            else:
                raise "Swap type 8 is only for ETH <-> WETH"
        else:
            raise "Bad swap type"

        # update the amount received
        if output_token == ETH_ADDRESS:
            amount = self.balance
        else:
            amount = ERC20(output_token).balanceOf(self)

        # sanity check, if the routing data is incorrect we will have a 0 balance and that is bad
        assert amount != 0, "Received nothing"

        # check if this was the last swap
        if i == 5 or _route[i*2+1] == empty(address):
            break
        # if there is another swap, the output token becomes the input for the next round
        input_token = output_token

    amount -= 1  # Change non-zero -> non-zero costs less gas than zero -> non-zero
    assert amount >= _expected, "Slippage"

    # transfer the final token to the receiver
    if output_token == ETH_ADDRESS:
        raw_call(_receiver, b"", value=amount)
    else:
        assert ERC20(output_token).transfer(_receiver, amount, default_return_value=True)

    log Exchange(msg.sender, _receiver, _route, _swap_params, _pools, _amount, amount)

    return amount


@view
@external
def get_dy(
    _route: address[11],
    _swap_params: uint256[5][5],
    _amount: uint256,
    _pools: address[5]=empty(address[5])
) -> uint256:
    """
    @notice Get amount of the final output token received in an exchange
    @dev Routing and swap params must be determined off-chain. This
         functionality is designed for gas efficiency over ease-of-use.
    @param _route Array of [initial token, pool or zap, token, pool or zap, token, ...]
                  The array is iterated until a pool address of 0x00, then the last
                  given token is transferred to `_receiver`
    @param _swap_params Multidimensional array of [i, j, swap type, pool_type, n_coins] where
                        i is the index of input token
                        j is the index of output token

                        The swap_type should be:
                        1. for `exchange`,
                        2. for `exchange_underlying`,
                        3. for underlying exchange via zap: factory stable metapools with lending base pool `exchange_underlying`
                           and factory crypto-meta pools underlying exchange (`exchange` method in zap)
                        4. for coin -> LP token "exchange" (actually `add_liquidity`),
                        5. for lending pool underlying coin -> LP token "exchange" (actually `add_liquidity`),
                        6. for LP token -> coin "exchange" (actually `remove_liquidity_one_coin`)
                        7. for LP token -> lending or fake pool underlying coin "exchange" (actually `remove_liquidity_one_coin`)
                        8. for ETH <-> WETH

                        pool_type: 1 - stable, 2 - crypto, 3 - tricrypto, 4 - llamma
                        n_coins is the number of coins in pool
    @param _amount The amount of input token (`_route[0]`) to be sent.
    @param _pools Array of pools for swaps via zap contracts. This parameter is needed only for swap_type = 3.
    @return Expected amount of the final output token.
    """
    input_token: address = _route[0]
    output_token: address = empty(address)
    amount: uint256 = _amount

    for i in range(1, 6):
        # 5 rounds of iteration to perform up to 5 swaps
        swap: address = _route[i*2-1]
        pool: address = _pools[i-1] # Only for Polygon meta-factories underlying swap (swap_type == 4)
        output_token = _route[i * 2]
        params: uint256[5] = _swap_params[i-1]  # i, j, swap_type, pool_type, n_coins

        # Calc output amount according to the swap type
        if params[2] == 1:
            if params[3] == 1:  # stable
                amount = StablePool(swap).get_dy(convert(params[0], int128), convert(params[1], int128), amount)
            else:  # crypto or llamma
                amount = CryptoPool(swap).get_dy(params[0], params[1], amount)
        elif params[2] == 2:
            if params[3] == 1:  # stable
                amount = StablePool(swap).get_dy_underlying(convert(params[0], int128), convert(params[1], int128), amount)
            else:  # crypto
                amount = CryptoPool(swap).get_dy_underlying(params[0], params[1], amount)
        elif params[2] == 3:  # SWAP IS ZAP HERE !!!
            if params[3] == 1:  # stable
                amount = StablePool(pool).get_dy_underlying(convert(params[0], int128), convert(params[1], int128), amount)
            else:  # crypto
                amount = CryptoMetaZap(swap).get_dy(pool, params[0], params[1], amount)
        elif params[2] in [4, 5]:
            if params[3] == 1: # stable
                amounts: uint256[10] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
                amounts[params[0]] = amount
                amount = STABLE_CALC.calc_token_amount(swap, output_token, amounts, params[4], True, True)
            else:
                # Tricrypto pools have stablepool interface for calc_token_amount
                if params[4] == 2:
                    amounts: uint256[2] = [0, 0]
                    amounts[params[0]] = amount
                    if params[3] == 2:  # crypto
                        amount = CryptoPool2Coins(swap).calc_token_amount(amounts)
                    else:  # tricrypto
                        amount = StablePool2Coins(swap).calc_token_amount(amounts, True)
                elif params[4] == 3:
                    amounts: uint256[3] = [0, 0, 0]
                    amounts[params[0]] = amount
                    if params[3] == 2:  # crypto
                        amount = CryptoPool3Coins(swap).calc_token_amount(amounts)
                    else:  # tricrypto
                        amount = StablePool3Coins(swap).calc_token_amount(amounts, True)
                elif params[4] == 4:
                    amounts: uint256[4] = [0, 0, 0, 0]
                    amounts[params[0]] = amount
                    if params[3] == 2:  # crypto
                        amount = CryptoPool4Coins(swap).calc_token_amount(amounts)
                    else:  # tricrypto
                        amount = StablePool4Coins(swap).calc_token_amount(amounts, True)
                elif params[4] == 5:
                    amounts: uint256[5] = [0, 0, 0, 0, 0]
                    amounts[params[0]] = amount
                    if params[3] == 2:  # crypto
                        amount = CryptoPool5Coins(swap).calc_token_amount(amounts)
                    else:  # tricrypto
                        amount = StablePool5Coins(swap).calc_token_amount(amounts, True)
        elif params[2] in [6, 7]:
            if params[3] == 1:  # stable
                amount = StablePool(swap).calc_withdraw_one_coin(amount, convert(params[1], int128))
            else:  # crypto
                amount = CryptoPool(swap).calc_withdraw_one_coin(amount, params[1])
        elif params[2] == 8:
            if input_token == WETH_ADDRESS or output_token == WETH_ADDRESS:
                # ETH <--> WETH rate is 1:1
                pass
            else:
                raise "Swap type 8 is only for ETH <-> WETH"
        else:
            raise "Bad swap type"

        # check if this was the last swap
        if i == 5 or _route[i*2+1] == empty(address):
            break
        # if there is another swap, the output token becomes the input for the next round
        input_token = output_token

    return amount - 1


@view
@external
def get_dx(
    _route: address[11],
    _swap_params: uint256[5][5],
    _out_amount: uint256,
    _pools: address[5],
    _base_pools: address[5]=empty(address[5]),
    _base_tokens: address[5]=empty(address[5]),
) -> uint256:
    """
    @notice Calculate the input amount required to receive the desired `_out_amount`
    @dev Routing and swap params must be determined off-chain. This
         functionality is designed for gas efficiency over ease-of-use.
    @param _route Array of [initial token, pool or zap, token, pool or zap, token, ...]
                  The array is iterated until a pool address of 0x00, then the last
                  given token is transferred to `_receiver`
    @param _swap_params Multidimensional array of [i, j, swap type, pool_type, n_coins] where
                        i is the index of input token
                        j is the index of output token

                        The swap_type should be:
                        1. for `exchange`,
                        2. for `exchange_underlying`,
                        3. for underlying exchange via zap: factory stable metapools with lending base pool `exchange_underlying`
                           and factory crypto-meta pools underlying exchange (`exchange` method in zap)
                        4. for coin -> LP token "exchange" (actually `add_liquidity`),
                        5. for lending pool underlying coin -> LP token "exchange" (actually `add_liquidity`),
                        6. for LP token -> coin "exchange" (actually `remove_liquidity_one_coin`)
                        7. for LP token -> lending or fake pool underlying coin "exchange" (actually `remove_liquidity_one_coin`)
                        8. for ETH <-> WETH

                        pool_type: 1 - stable, 2 - crypto, 3 - tricrypto, 4 - llamma
                        n_coins is the number of coins in pool
    @param _out_amount The desired amount of output coin to receive.
    @param _pools Array of pools.
    @param _base_pools Array of base pools (for meta pools).
    @param _base_tokens Array of base lp tokens (for meta pools).
    @return Required amount of input token to send.
    """
    amount: uint256 = _out_amount

    for _i in range(1, 6):
        # 5 rounds of iteration to perform up to 5 swaps
        i: uint256 = 6 - _i
        swap: address = _route[i*2-1]
        if swap == empty(address):
            continue
        input_token: address = _route[(i - 1) * 2]
        output_token: address = _route[i * 2]
        pool: address = _pools[i-1]
        base_pool: address = _base_pools[i-1]
        base_token: address = _base_tokens[i-1]
        params: uint256[5] = _swap_params[i-1]  # i, j, swap_type, pool_type, n_coins
        n_coins: uint256 = params[4]

        # Calc a required input amount according to the swap type
        if params[2] == 1:
            if params[3] == 1:  # stable
                if base_pool == empty(address):  # non-meta
                    amount = STABLE_CALC.get_dx(pool, convert(params[0], int128), convert(params[1], int128), amount, n_coins)
                else:
                    amount = STABLE_CALC.get_dx_meta(pool, convert(params[0], int128), convert(params[1], int128), amount, n_coins, base_pool)
            elif params[3] in [2, 3]:  # crypto or tricrypto
                amount = CRYPTO_CALC.get_dx(pool, params[0], params[1], amount, n_coins)
            else:  # llamma
                amount = Llamma(pool).get_dx(params[0], params[1], amount)
        elif params[2] in [2, 3]:
            if params[3] == 1:  # stable
                if base_pool == empty(address):  # non-meta
                    amount = STABLE_CALC.get_dx_underlying(pool, convert(params[0], int128), convert(params[1], int128), amount, n_coins)
                else:
                    amount = STABLE_CALC.get_dx_meta_underlying(pool, convert(params[0], int128), convert(params[1], int128), amount, n_coins, base_pool, base_token)
            else:  # crypto
                amount = CRYPTO_CALC.get_dx_meta_underlying(pool, params[0], params[1], amount, n_coins, base_pool, base_token)
        elif params[2] in [4, 5]:
            # This is not correct. Should be something like calc_add_one_coin. But tests say that it's precise enough.
            if params[3] == 1:  # stable
                amount = StablePool(swap).calc_withdraw_one_coin(amount, convert(params[0], int128))
            else:  # crypto
                amount = CryptoPool(swap).calc_withdraw_one_coin(amount, params[0])
        elif params[2] in [6, 7]:
            if params[3] == 1: # stable
                amounts: uint256[10] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
                amounts[params[1]] = amount
                amount = STABLE_CALC.calc_token_amount(swap, input_token, amounts, n_coins, False, True)
            else:
                # Tricrypto pools have stablepool interface for calc_token_amount
                if n_coins == 2:
                    amounts: uint256[2] = [0, 0]
                    amounts[params[1]] = amount
                    if params[3] == 2:  # crypto
                        amount = CryptoPool2Coins(swap).calc_token_amount(amounts)  # This is not correct
                    else:  # tricrypto
                        amount = StablePool2Coins(swap).calc_token_amount(amounts, False)
                elif n_coins == 3:
                    amounts: uint256[3] = [0, 0, 0]
                    amounts[params[1]] = amount
                    if params[3] == 2:  # crypto
                        amount = CryptoPool3Coins(swap).calc_token_amount(amounts)  # This is not correct
                    else:  # tricrypto
                        amount = StablePool3Coins(swap).calc_token_amount(amounts, False)
                elif n_coins == 4:
                    amounts: uint256[4] = [0, 0, 0, 0]
                    amounts[params[1]] = amount
                    if params[3] == 2:  # crypto
                        amount = CryptoPool4Coins(swap).calc_token_amount(amounts)  # This is not correct
                    else:  # tricrypto
                        amount = StablePool4Coins(swap).calc_token_amount(amounts, False)
                elif n_coins == 5:
                    amounts: uint256[5] = [0, 0, 0, 0, 0]
                    amounts[params[1]] = amount
                    if params[3] == 2:  # crypto
                        amount = CryptoPool5Coins(swap).calc_token_amount(amounts)  # This is not correct
                    else:  # tricrypto
                        amount = StablePool5Coins(swap).calc_token_amount(amounts, False)
        elif params[2] == 8:
            if input_token == WETH_ADDRESS or output_token == WETH_ADDRESS:
                # ETH <--> WETH rate is 1:1
                pass
            else:
                raise "Swap type 8 is only for ETH <-> WETH"
        else:
            raise "Bad swap type"

    return amount