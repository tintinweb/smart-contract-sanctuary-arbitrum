# pragma version 0.3.10
# pragma optimize gas
# pragma evm-version paris

"""
@title Uniswap V3 TWAP Bot
@license Apache 2.0
@author Volume.finance
"""

struct SwapInfo:
    path: Bytes[224]
    amount: uint256

struct ExactInputParams:
    path: Bytes[224]
    recipient: address
    deadline: uint256
    amountIn: uint256
    amountOutMinimum: uint256

struct Deposit:
    depositor: address
    path: Bytes[224]
    input_amount: uint256
    number_trades: uint256
    interval: uint256
    remaining_counts: uint256
    starting_time: uint256

interface SwapRouter:
    def WETH9() -> address: pure
    def exactInput(params: ExactInputParams) -> uint256: payable

interface ERC20:
    def balanceOf(_owner: address) -> uint256: view
    def approve(_spender: address, _value: uint256) -> bool: nonpayable
    def transfer(_to: address, _value: uint256) -> bool: nonpayable
    def transferFrom(_from: address, _to: address, _value: uint256) -> bool: nonpayable

interface Weth:
    def deposit(): payable
    def withdraw(wad: uint256): nonpayable
    def approve(guy: address, wad: uint256) -> bool: nonpayable

VETH: constant(address) = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE # Virtual ETH
WETH: immutable(address)
ROUTER: immutable(address)
MAX_SIZE: constant(uint256) = 8
DENOMINATOR: constant(uint256) = 10 ** 18
compass_evm: public(address)
deposit_list: public(HashMap[uint256, Deposit])
next_deposit: public(uint256)
refund_wallet: public(address)
fee: public(uint256)
paloma: public(bytes32)
service_fee_collector: public(address)
service_fee: public(uint256)

event Deposited:
    deposit_id: uint256
    token0: address
    token1: address
    input_amount: uint256
    number_trades: uint256
    interval: uint256
    starting_time: uint256
    depositor: address
    is_stable_swap: bool

event Swapped:
    deposit_id: uint256
    remaining_counts: uint256
    amount: uint256
    out_amount: uint256

event Canceled:
    deposit_id: uint256
    token0: address
    token1: address
    input_amount: uint256

event UpdateCompass:
    old_compass: address
    new_compass: address

event UpdateRefundWallet:
    old_refund_wallet: address
    new_refund_wallet: address

event UpdateFee:
    old_fee: uint256
    new_fee: uint256

event SetPaloma:
    paloma: bytes32

event UpdateServiceFeeCollector:
    old_service_fee_collector: address
    new_service_fee_collector: address

event UpdateServiceFee:
    old_service_fee: uint256
    new_service_fee: uint256

@external
def __init__(_compass_evm: address, router: address, _refund_wallet: address, _fee: uint256, _service_fee_collector: address, _service_fee: uint256):
    self.compass_evm = _compass_evm
    ROUTER = router
    WETH = SwapRouter(router).WETH9()
    self.refund_wallet = _refund_wallet
    self.fee = _fee
    self.service_fee_collector = _service_fee_collector
    assert _service_fee < DENOMINATOR
    self.service_fee = _service_fee
    log UpdateCompass(empty(address), _compass_evm)
    log UpdateRefundWallet(empty(address), _refund_wallet)
    log UpdateFee(0, _fee)
    log UpdateServiceFeeCollector(empty(address), _service_fee_collector)
    log UpdateServiceFee(0, _service_fee)

@external
@payable
@nonreentrant('lock')
def deposit(swap_infos: DynArray[SwapInfo, MAX_SIZE], number_trades: uint256, interval: uint256, starting_time: uint256):
    _value: uint256 = msg.value
    _fee: uint256 = self.fee
    if _fee > 0:
        _fee = _fee * number_trades
        assert _value >= _fee, "Insuf fee"
        send(self.refund_wallet, _fee)
        _value = unsafe_sub(_value, _fee)
    _next_deposit: uint256 = self.next_deposit
    _starting_time: uint256 = starting_time
    if starting_time <= block.timestamp:
        _starting_time = block.timestamp
    assert number_trades > 0, "Wrong count"
    for swap_info in swap_infos:
        amount: uint256 = 0
        assert len(swap_info.path) >= 43, "Path error"
        token0: address = convert(slice(swap_info.path, 0, 20), address)
        fee_index: uint256 = 20
        if token0 == VETH:
            amount = swap_info.amount
            assert _value >= amount, "Insuf deposit"
            _value = unsafe_sub(_value, amount)
            fee_index = 40
        else:
            amount = ERC20(token0).balanceOf(self)
            assert ERC20(token0).transferFrom(msg.sender, self, swap_info.amount, default_return_value=True), "TF fail"
            amount = ERC20(token0).balanceOf(self) - amount
        is_stable_swap: bool = True
        for i in range(8):
            if unsafe_add(fee_index, 3) >= len(swap_info.path):
                break
            fee_level: uint256 = convert(slice(swap_info.path, fee_index, 3), uint256)
            if fee_level == 0:
                break
            if fee_level > 500:
                is_stable_swap = False
            fee_index = unsafe_add(fee_index, 23)
        self.deposit_list[_next_deposit] = Deposit({
            depositor: msg.sender,
            path: swap_info.path,
            input_amount: amount,
            number_trades: number_trades,
            interval: interval,
            remaining_counts: number_trades,
            starting_time: _starting_time
        })
        log Deposited(_next_deposit, token0, convert(slice(swap_info.path, unsafe_sub(len(swap_info.path), 20), 20), address), amount, number_trades, interval, _starting_time, msg.sender, is_stable_swap)
        _next_deposit = unsafe_add(_next_deposit, 1)
    self.next_deposit = _next_deposit
    if _value > 0:
        send(msg.sender, _value)

@internal
def _swap(deposit_id: uint256, remaining_count: uint256, amount_out_min: uint256) -> uint256:
    _deposit: Deposit = self.deposit_list[deposit_id]
    assert _deposit.remaining_counts > 0 and _deposit.remaining_counts == remaining_count, "Wrong count"
    _amount: uint256 = _deposit.input_amount / _deposit.remaining_counts
    _deposit.input_amount -= _amount
    _deposit.remaining_counts -= 1
    self.deposit_list[deposit_id] = _deposit
    _out_amount: uint256 = 0
    _path: Bytes[224] = _deposit.path
    token0: address = convert(slice(_path, 0, 20), address)
    token1: address = convert(slice(_path, unsafe_sub(len(_path), 20), 20), address)
    if token0 == VETH:
        _path = slice(_path, 20, unsafe_sub(len(_path), 20))
        Weth(WETH).deposit(value=_amount)
        assert ERC20(WETH).approve(ROUTER, _amount), "Ap fail"
        _out_amount = ERC20(token1).balanceOf(self)
        SwapRouter(ROUTER).exactInput(ExactInputParams({
            path: _path,
            recipient: self,
            deadline: block.timestamp,
            amountIn: _amount,
            amountOutMinimum: amount_out_min
        }))
        _out_amount = ERC20(token1).balanceOf(self) - _out_amount
    else:
        assert ERC20(token0).approve(ROUTER, _amount), "Ap fail"
        if token1 == VETH:
            _path = slice(_path, 0, unsafe_sub(len(_path), 20))
            _out_amount = ERC20(WETH).balanceOf(self)
            SwapRouter(ROUTER).exactInput(ExactInputParams({
                path: _path,
                recipient: self,
                deadline: block.timestamp,
                amountIn: _amount,
                amountOutMinimum: amount_out_min
            }))
            _out_amount = ERC20(WETH).balanceOf(self) - _out_amount
            Weth(WETH).withdraw(_out_amount)
        else:
            _out_amount = ERC20(token1).balanceOf(self)
            SwapRouter(ROUTER).exactInput(ExactInputParams({
                path: _path,
                recipient: self,
                deadline: block.timestamp,
                amountIn: _amount,
                amountOutMinimum: amount_out_min
            }))
            _out_amount = ERC20(token1).balanceOf(self) - _out_amount
    _service_fee: uint256 = self.service_fee
    service_fee_amount: uint256 = 0
    if _service_fee > 0:
        service_fee_amount = unsafe_div(_out_amount * _service_fee, DENOMINATOR)
    if token1 == VETH:
        if service_fee_amount > 0:
            send(self.service_fee_collector, service_fee_amount)
            send(_deposit.depositor, unsafe_sub(_out_amount, service_fee_amount))
        else:
            send(_deposit.depositor, _out_amount)
    else:
        if service_fee_amount > 0:
            assert ERC20(token1).transfer(self.service_fee_collector, service_fee_amount), "Tr fail"
            _out_amount = unsafe_sub(_out_amount, service_fee_amount)
        assert ERC20(token1).transfer(_deposit.depositor, _out_amount), "Tr fail"
    log Swapped(deposit_id, _deposit.remaining_counts, _amount, _out_amount)
    return _out_amount

@external
@nonreentrant('lock')
def multiple_swap(deposit_id: DynArray[uint256, MAX_SIZE], remaining_counts: DynArray[uint256, MAX_SIZE], amount_out_min: DynArray[uint256, MAX_SIZE]):
    assert msg.sender == self.compass_evm, "Unauth"
    _len: uint256 = len(deposit_id)
    assert _len == len(amount_out_min) and _len == len(remaining_counts), "Validation error"
    _len = unsafe_add(unsafe_mul(unsafe_add(_len, 2), 96), 36)
    assert len(msg.data) == _len, "Invalid payload"
    assert self.paloma == convert(slice(msg.data, unsafe_sub(_len, 32), 32), bytes32), "Invalid paloma"
    for i in range(MAX_SIZE):
        if i >= len(deposit_id):
            break
        self._swap(deposit_id[i], remaining_counts[i], amount_out_min[i])

@external
def multiple_swap_view(deposit_id: DynArray[uint256, MAX_SIZE], remaining_counts: DynArray[uint256, MAX_SIZE]) -> DynArray[uint256, MAX_SIZE]:
    assert msg.sender == empty(address) # only for view function
    _len: uint256 = len(deposit_id)
    res: DynArray[uint256, MAX_SIZE] = []
    for i in range(MAX_SIZE):
        if i >= len(deposit_id):
            break
        res.append(self._swap(deposit_id[i], remaining_counts[i], 1))
    return res

@external
@nonreentrant('lock')
def cancel(deposit_id: uint256):
    _deposit: Deposit = self.deposit_list[deposit_id]
    assert _deposit.depositor == msg.sender, "Unauth"
    assert _deposit.input_amount > 0, "All traded"
    token0: address = convert(slice(_deposit.path, 0, 20), address)
    if token0 == VETH:
        send(msg.sender, _deposit.input_amount)
    else:
        assert ERC20(token0).transfer(msg.sender, _deposit.input_amount), "Tr fail"
    log Canceled(deposit_id, token0, convert(slice(_deposit.path, unsafe_sub(len(_deposit.path), 20), 20), address), _deposit.input_amount)
    _deposit.input_amount = 0
    _deposit.remaining_counts = 0
    self.deposit_list[deposit_id] = _deposit

@external
@nonreentrant('lock')
def multiple_cancel(deposit_ids: DynArray[uint256, MAX_SIZE]):
    for deposit_id in deposit_ids:
        _deposit: Deposit = self.deposit_list[deposit_id]
        assert _deposit.depositor == msg.sender, "Unauth"
        assert _deposit.input_amount > 0, "All traded"
        token0: address = convert(slice(_deposit.path, 0, 20), address)
        if token0 == VETH:
            send(msg.sender, _deposit.input_amount)
        else:
            assert ERC20(token0).transfer(msg.sender, _deposit.input_amount), "Tr fail"
        log Canceled(deposit_id, token0, convert(slice(_deposit.path, unsafe_sub(len(_deposit.path), 20), 20), address), _deposit.input_amount)
        _deposit.input_amount = 0
        _deposit.remaining_counts = 0
        self.deposit_list[deposit_id] = _deposit

@external
def update_compass(new_compass: address):
    assert msg.sender == self.compass_evm and len(msg.data) == 68 and convert(slice(msg.data, 36, 32), bytes32) == self.paloma, "Unauth"
    self.compass_evm = new_compass
    log UpdateCompass(msg.sender, new_compass)

@external
def update_refund_wallet(new_refund_wallet: address):
    assert msg.sender == self.compass_evm and len(msg.data) == 68 and convert(slice(msg.data, 36, 32), bytes32) == self.paloma, "Unauth"
    old_refund_wallet: address = self.refund_wallet
    self.refund_wallet = new_refund_wallet
    log UpdateRefundWallet(old_refund_wallet, new_refund_wallet)

@external
def update_fee(new_fee: uint256):
    assert msg.sender == self.compass_evm and len(msg.data) == 68 and convert(slice(msg.data, 36, 32), bytes32) == self.paloma, "Unauth"
    old_fee: uint256 = self.fee
    self.fee = new_fee
    log UpdateFee(old_fee, new_fee)

@external
def set_paloma():
    assert msg.sender == self.compass_evm and self.paloma == empty(bytes32) and len(msg.data) == 36, "Invalid"
    _paloma: bytes32 = convert(slice(msg.data, 4, 32), bytes32)
    self.paloma = _paloma
    log SetPaloma(_paloma)

@external
def update_service_fee_collector(new_service_fee_collector: address):
    assert msg.sender == self.compass_evm and len(msg.data) == 68 and convert(slice(msg.data, 36, 32), bytes32) == self.paloma, "Unauth"
    old_service_fee_collector: address = self.service_fee_collector
    self.service_fee_collector = new_service_fee_collector
    log UpdateServiceFeeCollector(old_service_fee_collector, new_service_fee_collector)

@external
def update_service_fee(new_service_fee: uint256):
    assert msg.sender == self.compass_evm and len(msg.data) == 68 and convert(slice(msg.data, 36, 32), bytes32) == self.paloma, "Unauth"
    assert new_service_fee < DENOMINATOR
    old_service_fee: uint256 = self.service_fee
    self.service_fee = new_service_fee
    log UpdateServiceFee(old_service_fee, new_service_fee)

@external
@payable
def __default__():
    assert msg.sender == WETH