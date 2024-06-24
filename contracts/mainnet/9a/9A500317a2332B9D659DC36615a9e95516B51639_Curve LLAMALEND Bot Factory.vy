#pragma version 0.3.10
#pragma optimize gas
#pragma evm-version shanghai
"""
@title Curve LLAMALEND Bot Factory
@license Apache 2.0
@author Volume.finance
"""

struct SwapInfo:
    route: address[11]
    swap_params: uint256[5][5]
    amount: uint256
    expected: uint256
    pools: address[5]

struct BotInfo:
    depositor: address
    collateral: address
    amount: uint256
    debt: uint256
    N: uint256
    leverage: uint256
    deleverage_percentage: uint256
    health_threshold: uint256
    expire: uint256
    remaining_count: uint256
    interval: uint256
    is_new_market: bool
    controller_idx: uint256

interface ControllerFactory:
    def token_to_vaults(token0: address, idx: uint256) -> address: view
    def STABLECOIN() -> address: view

interface Vault:
    def controller() -> address: view

interface ERC20:
    def approve(_spender: address, _value: uint256) -> bool: nonpayable
    def transfer(_to: address, _value: uint256) -> bool: nonpayable
    def transferFrom(_from: address, _to: address, _value: uint256) -> bool: nonpayable

interface WrappedEth:
    def deposit(): payable
    def withdraw(amount: uint256): nonpayable

interface Bot:
    def create_loan_extended(collateral_amount: uint256, debt: uint256, N: uint256, callbacker: address, callback_args: DynArray[uint256,5], callback_bytes: Bytes[10**4]): nonpayable
    def borrow_more_extended(collateral_amount: uint256, debt: uint256, callbacker: address, callback_args: DynArray[uint256, 5], callback_bytes: Bytes[10**4]): nonpayable
    def repay_extended(callbacker: address, callback_args: DynArray[uint256,5], callback_bytes: Bytes[10**4]) -> uint256: nonpayable
    def set_new_market(is_new_market: bool): nonpayable
    def state() -> uint256[4]: view
    def health() -> int256: view

interface CurveSwapRouter:
    def exchange(
        _route: address[11],
        _swap_params: uint256[5][5],
        _amount: uint256,
        _expected: uint256,
        _pools: address[5]=empty(address[5]),
        _receiver: address=msg.sender
    ) -> uint256: payable

event BotStarted:
    deposit_id: uint256
    owner: address
    bot: address
    collateral: address
    collateral_amount: uint256
    debt: uint256
    N: uint256
    leverage: uint256
    deleverage_percentage: uint256
    health_threshold: uint256
    expire: uint256
    callbacker: address
    callback_args: DynArray[uint256, 5]
    remaining_count: uint256
    interval: uint256

event BotAdded:
    deposit_id: uint256
    owner: address
    bot: address
    collateral: address
    collateral_amount: uint256
    debt: uint256
    N: uint256
    leverage: uint256
    deleverage_percentage: uint256
    health_threshold: uint256
    expire: uint256
    callbacker: address
    callback_args: DynArray[uint256, 5]
    remaining_count: uint256
    interval: uint256

event CancelPendingBot:
    user: address
    collateral: address
    collateral_amount: uint256

event BotRepayed:
    owner: address
    bot: address
    return_amount: uint256

event UpdateBlueprint:
    old_blueprint: address
    new_blueprint: address

event UpdateCompass:
    old_compass: address
    new_compass: address

event UpdateRefundWallet:
    old_refund_wallet: address
    new_refund_wallet: address

event SetPaloma:
    paloma: bytes32

event UpdateGasFee:
    old_gas_fee: uint256
    new_gas_fee: uint256

event UpdateServiceFeeCollector:
    old_service_fee_collector: address
    new_service_fee_collector: address

event UpdateServiceFee:
    old_service_fee: uint256
    new_service_fee: uint256

MAX_SIZE: constant(uint256) = 8
DENOMINATOR: constant(uint256) = 10**18
VETH: constant(address) = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
WETH: immutable(address)
CONTROLLER_FACTORY: immutable(address)
ROUTER: immutable(address)
STABLECOIN: immutable(address)
blueprint: public(address)
compass: public(address)
bot_to_owner: public(HashMap[address, address])
owner_to_bot: public(HashMap[address, HashMap[address, address]])
refund_wallet: public(address)
gas_fee: public(uint256)
service_fee_collector: public(address)
service_fee: public(uint256)
paloma: public(bytes32)
bot_info: public(HashMap[uint256, BotInfo])
last_deposit_id: public(uint256)
remaining_funds: public(HashMap[address, HashMap[address, uint256]])

@external
def __init__(_blueprint: address, _compass: address, controller_factory: address, weth: address, router: address, _refund_wallet: address, _gas_fee: uint256, _service_fee_collector: address, _service_fee: uint256):
    self.blueprint = _blueprint
    self.compass = _compass
    self.refund_wallet = _refund_wallet
    self.gas_fee = _gas_fee
    self.service_fee_collector = _service_fee_collector
    self.service_fee = _service_fee
    assert _service_fee < DENOMINATOR, "Wrong service fee"
    CONTROLLER_FACTORY = controller_factory
    ROUTER = router
    WETH = weth
    STABLECOIN = ControllerFactory(CONTROLLER_FACTORY).STABLECOIN()
    log UpdateCompass(empty(address), _compass)
    log UpdateBlueprint(empty(address), _blueprint)
    log UpdateRefundWallet(empty(address), _refund_wallet)
    log UpdateGasFee(empty(uint256), _gas_fee)
    log UpdateServiceFeeCollector(empty(address), _service_fee_collector)
    log UpdateServiceFee(empty(uint256), _service_fee)

@internal
def _safe_approve(_token: address, _to: address, _value: uint256):
    assert ERC20(_token).approve(_to, _value, default_return_value=True), "Failed approve"

@internal
def _safe_transfer(_token: address, _to: address, _value: uint256):
    assert ERC20(_token).transfer(_to, _value, default_return_value=True), "Failed transfer"

@internal
def _safe_transfer_from(_token: address, _from: address, _to: address, _value: uint256):
    assert ERC20(_token).transferFrom(_from, _to, _value, default_return_value=True), "Failed transferFrom"

@external
@payable
@nonreentrant('lock')
def create_bot(swap_infos: DynArray[SwapInfo, MAX_SIZE], collateral: address, debt: uint256, N: uint256, callbacker: address, callback_args: DynArray[uint256,5], callback_bytes: Bytes[10**4], is_new_market: bool, leverage: uint256, deleverage_percentage: uint256, health_threshold: uint256, expire: uint256, number_trades: uint256, interval: uint256, controller_idx: uint256=0, delegate: address=msg.sender):
    _gas_fee: uint256 = self.gas_fee * number_trades
    _service_fee: uint256 = self.service_fee
    collateral_amount: uint256 = 0
    _value: uint256 = msg.value
    for swap_info in swap_infos:
        last_index: uint256 = 0
        for i in range(6): # to the first
            last_index = unsafe_sub(10, unsafe_add(i, i))
            if swap_info.route[last_index] != empty(address):
                break
        assert swap_info.route[last_index] == collateral or (swap_info.route[last_index] == VETH and collateral == WETH), "Wrong path"
        amount: uint256 = swap_info.amount
        assert amount > 0, "Insuf deposit"
        if collateral == WETH:
            if swap_info.route[0] == VETH:
                assert _value >= amount, "Insuf deposit"
                _value = unsafe_sub(_value, amount)
            else:
                self._safe_transfer_from(swap_info.route[0], msg.sender, self, amount)
                if swap_info.route[0] == WETH:
                    WrappedEth(WETH).withdraw(amount)
                else:
                    self._safe_approve(swap_info.route[0], ROUTER, amount)
                    amount = CurveSwapRouter(ROUTER).exchange(swap_info.route, swap_info.swap_params, amount, swap_info.expected, swap_info.pools, self)
        else:
            if swap_info.route[0] == VETH:
                assert _value >= amount, "Insuf deposit"
                _value = unsafe_sub(_value, amount)
                amount = CurveSwapRouter(ROUTER).exchange(swap_info.route, swap_info.swap_params, amount, swap_info.expected, swap_info.pools, self, value=amount)
            else:
                self._safe_transfer_from(swap_info.route[0], msg.sender, self, amount)
                if swap_info.route[0] != collateral:
                    self._safe_approve(swap_info.route[0], ROUTER, amount)
                    amount = CurveSwapRouter(ROUTER).exchange(swap_info.route, swap_info.swap_params, amount, swap_info.expected, swap_info.pools, self)
        collateral_amount += amount
    if _value > _gas_fee:
        send(msg.sender, unsafe_sub(_value, _gas_fee))
    else:
        assert _value == _gas_fee, "Insuf deposit"
    send(self.refund_wallet, _gas_fee)
    _service_fee_amount: uint256 = 0
    if _service_fee > 0:
        _service_fee_amount = unsafe_div(collateral_amount * _service_fee, DENOMINATOR)
        collateral_amount = unsafe_sub(collateral_amount, _service_fee_amount)
    assert collateral_amount > 0, "Insuf deposit"
    if _service_fee_amount > 0:
        if collateral == WETH:
            send(self.service_fee_collector, _service_fee_amount)
        else:
            self._safe_transfer(collateral, self.service_fee_collector, _service_fee_amount)
    _deposit_id: uint256 = self.last_deposit_id
    self.last_deposit_id = unsafe_add(_deposit_id, 1)
    _amount: uint256 = unsafe_div(collateral_amount, number_trades)
    if number_trades > 1:
        self.bot_info[_deposit_id] = BotInfo({
            depositor: delegate,
            collateral: collateral,
            amount: _amount,
            debt: debt,
            N: N,
            leverage: leverage,
            deleverage_percentage: deleverage_percentage,
            health_threshold: health_threshold,
            expire: expire,
            remaining_count: unsafe_sub(number_trades, 1),
            interval: interval,
            is_new_market: is_new_market,
            controller_idx: controller_idx
        })
        self.remaining_funds[delegate][collateral] +=  unsafe_sub(collateral_amount, _amount)
    else:
        assert number_trades == 1, "Wrong number trades"
    self._create_bot(_deposit_id, delegate, collateral, unsafe_div(collateral_amount, number_trades), debt, N, callbacker, callback_args, callback_bytes, is_new_market, leverage, deleverage_percentage, health_threshold, expire, number_trades, interval, controller_idx)

@internal
def _create_bot(deposit_id: uint256, depositor: address, collateral: address, amount: uint256, debt: uint256, N: uint256, callbacker: address, callback_args: DynArray[uint256,5], callback_bytes: Bytes[10**4], is_new_market: bool, leverage: uint256, deleverage_percentage: uint256, health_threshold: uint256, expire: uint256, remaining_count: uint256, interval: uint256, controller_idx: uint256):
    _service_fee: uint256 = self.service_fee
    vault: address = ControllerFactory(CONTROLLER_FACTORY).token_to_vaults(collateral, controller_idx)
    controller: address = Vault(vault).controller()
    bot: address = self.owner_to_bot[depositor][collateral]
    if bot != empty(address):
        if Bot(bot).health() < 0:
            bot = empty(address)
        else:
            assert Bot(bot).state()[1] == 0, "In Soft liquidation. Full Repay instead"
    if amount > 0:
        if bot == empty(address):
            if collateral == WETH:
                WrappedEth(WETH).deposit(value=amount)
            bot = create_from_blueprint(self.blueprint, controller, WETH, depositor, collateral, STABLECOIN, is_new_market, code_offset=3)
            self._safe_transfer(collateral, bot, amount)
            Bot(bot).create_loan_extended(amount, debt, N, callbacker, callback_args, callback_bytes)
            self.bot_to_owner[bot] = depositor
            self.owner_to_bot[depositor][collateral] = bot
            log BotStarted(deposit_id, depositor, bot, collateral, amount, debt, N, leverage, deleverage_percentage, health_threshold, expire, callbacker, callback_args, remaining_count, interval)
        else:
            if collateral == WETH:
                WrappedEth(WETH).deposit(value=amount)
            self._safe_transfer(collateral, bot, amount)
            if Bot(bot).state()[3] == 0:
                Bot(bot).create_loan_extended(amount, debt, N, callbacker, callback_args, callback_bytes)
            else:
                Bot(bot).borrow_more_extended(amount, debt, callbacker, callback_args, callback_bytes)
            log BotAdded(deposit_id, depositor, bot, collateral, amount, debt, N, leverage, deleverage_percentage, health_threshold, expire, callbacker, callback_args, remaining_count, interval)

@internal
def _paloma_check():
    assert msg.sender == self.compass, "Not compass"
    assert self.paloma == convert(slice(msg.data, unsafe_sub(len(msg.data), 32), 32), bytes32), "Invalid paloma"

@external
def create_next_bot(deposit_id: uint256, callbacker: address, callback_args: DynArray[uint256,5], callback_bytes: Bytes[10**4], remaining_count: uint256):
    self._paloma_check()
    _bot_info: BotInfo = self.bot_info[deposit_id]
    assert _bot_info.remaining_count == remaining_count and remaining_count > 0, "Wrong count"
    self.remaining_funds[_bot_info.depositor][_bot_info.collateral] -= _bot_info.amount
    self._create_bot(deposit_id, _bot_info.depositor, _bot_info.collateral, _bot_info.amount, _bot_info.debt, _bot_info.N, callbacker, callback_args, callback_bytes, _bot_info.is_new_market, _bot_info.leverage, _bot_info.deleverage_percentage, _bot_info.health_threshold, _bot_info.expire, remaining_count, _bot_info.interval, _bot_info.controller_idx)
    self.bot_info[deposit_id].remaining_count = unsafe_sub(remaining_count, 1)

@external
@nonreentrant('lock')
def repay_bot(bots: DynArray[address, MAX_SIZE], callbackers: DynArray[address, MAX_SIZE], callback_args: DynArray[DynArray[uint256,5], MAX_SIZE], callback_bytes: DynArray[Bytes[10**4], MAX_SIZE]):
    assert len(bots) == len(callbackers) and len(bots) == len(callback_args), "invalidate"
    if msg.sender == self.compass:
        assert convert(slice(msg.data, unsafe_sub(len(msg.data), 32), 32), bytes32) == self.paloma, "Invalid paloma"
        for i in range(MAX_SIZE):
            if i >= len(bots):
                break
            bal: uint256 = Bot(bots[i]).repay_extended(callbackers[i], callback_args[i], callback_bytes[i])
            log BotRepayed(self.bot_to_owner[bots[i]], bots[i], bal)
    else:
        for i in range(MAX_SIZE):
            if i >= len(bots):
                break
            owner: address = self.bot_to_owner[bots[i]]
            assert owner == msg.sender, "Unauthorized"
            bal: uint256 = Bot(bots[i]).repay_extended(callbackers[i], callback_args[i], callback_bytes[i])
            log BotRepayed(owner, bots[i], bal)

@external
@nonreentrant('lock')
def cancel_pending_bot(collateral: address, collateral_amount: uint256):
    _amount: uint256 = self.remaining_funds[msg.sender][collateral]
    assert _amount >= collateral_amount, "Unavailable"
    self.remaining_funds[msg.sender][collateral] = unsafe_sub(_amount, collateral_amount)
    if collateral == WETH:
        send(msg.sender, collateral_amount)
    else:
        self._safe_transfer(collateral, msg.sender, collateral_amount)
    log CancelPendingBot(msg.sender, collateral, collateral_amount)

@external
def set_new_market(bot: address, is_new_market: bool):
    assert self.bot_to_owner[bot] == msg.sender, "Unauthorized"
    Bot(bot).set_new_market(is_new_market)

@external
@view
def state(bot: address) -> uint256[4]:
    return Bot(bot).state()

@external
@view
def health(bot: address) -> int256:
    return Bot(bot).health()

@external
@view
def get_controller(collateral: address) -> address:
    vault: address = ControllerFactory(CONTROLLER_FACTORY).token_to_vaults(collateral, 0)
    return Vault(vault).controller()

@external
def update_compass(new_compass: address):
    self._paloma_check()
    self.compass = new_compass
    log UpdateCompass(msg.sender, new_compass)

@external
def update_blueprint(new_blueprint: address):
    self._paloma_check()
    old_blueprint:address = self.blueprint
    self.blueprint = new_blueprint
    log UpdateCompass(old_blueprint, new_blueprint)

@external
def set_paloma():
    assert msg.sender == self.compass and self.paloma == empty(bytes32) and len(msg.data) == 36, "Invalid"
    _paloma: bytes32 = convert(slice(msg.data, 4, 32), bytes32)
    self.paloma = _paloma
    log SetPaloma(_paloma)

@external
def update_refund_wallet(new_refund_wallet: address):
    self._paloma_check()
    old_refund_wallet: address = self.refund_wallet
    self.refund_wallet = new_refund_wallet
    log UpdateRefundWallet(old_refund_wallet, new_refund_wallet)

@external
def update_gas_fee(new_gas_fee: uint256):
    self._paloma_check()
    old_gas_fee: uint256 = self.gas_fee
    self.gas_fee = new_gas_fee
    log UpdateGasFee(old_gas_fee, new_gas_fee)

@external
def update_service_fee_collector(new_service_fee_collector: address):
    self._paloma_check()
    old_service_fee_collector: address = self.service_fee_collector
    self.service_fee_collector = new_service_fee_collector
    log UpdateServiceFeeCollector(old_service_fee_collector, new_service_fee_collector)

@external
def update_service_fee(new_service_fee: uint256):
    self._paloma_check()
    old_service_fee: uint256 = self.service_fee
    self.service_fee = new_service_fee
    log UpdateServiceFee(old_service_fee, new_service_fee)


@external
@payable
def __default__():
    pass