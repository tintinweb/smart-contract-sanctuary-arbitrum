#pragma version 0.3.10
#pragma optimize gas
#pragma evm-version shanghai
"""
@title Uniswap v2 Limit Order Bot
@license Apache 2.0
@author Volume.finance
"""

struct Deposit:
    path: DynArray[address, MAX_SIZE]
    amount: uint256
    depositor: address

enum WithdrawType:
    CANCEL
    PROFIT_TAKING
    STOP_LOSS
    EXPIRE

interface ERC20:
    def balanceOf(_owner: address) -> uint256: view
    def approve(_spender: address, _value: uint256) -> bool: nonpayable
    def transfer(_to: address, _value: uint256) -> bool: nonpayable
    def transferFrom(_from: address, _to: address, _value: uint256) -> bool: nonpayable

interface WrappedEth:
    def deposit(): payable
    def withdraw(amount: uint256): nonpayable

interface UniswapV2Router:
    def WETH() -> address: pure
    def swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn: uint256, amountOutMin: uint256, path: DynArray[address, MAX_SIZE], to: address, deadline: uint256): nonpayable
    def swapExactTokensForETHSupportingFeeOnTransferTokens(amountIn: uint256, amountOutMin: uint256, path: DynArray[address, MAX_SIZE], to: address, deadline: uint256): nonpayable
    def getAmountsOut(amountIn: uint256, path: DynArray[address, MAX_SIZE]) -> DynArray[uint256, MAX_SIZE]: view

event Deposited:
    deposit_id: uint256
    token0: address
    token1: address
    amount0: uint256
    depositor: address
    profit_taking: uint256
    stop_loss: uint256
    expire: uint256

event Withdrawn:
    deposit_id: uint256
    withdrawer: address
    withdraw_type: WithdrawType
    withdraw_amount: uint256

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

WETH: immutable(address)
VETH: constant(address) = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE # Virtual ETH
MAX_SIZE: constant(uint256) = 8
DENOMINATOR: constant(uint256) = 10 ** 18
ROUTER: immutable(address)
compass: public(address)
deposit_size: public(uint256)
deposits: public(HashMap[uint256, Deposit])
refund_wallet: public(address)
fee: public(uint256)
paloma: public(bytes32)
service_fee_collector: public(address)
service_fee: public(uint256)

@external
def __init__(_compass: address, router: address, _refund_wallet: address, _fee: uint256, _service_fee_collector: address, _service_fee: uint256):
    self.compass = _compass
    ROUTER = router
    WETH = UniswapV2Router(ROUTER).WETH()
    self.refund_wallet = _refund_wallet
    self.fee = _fee
    self.service_fee_collector = _service_fee_collector
    self.service_fee = _service_fee
    log UpdateCompass(empty(address), _compass)
    log UpdateRefundWallet(empty(address), _refund_wallet)
    log UpdateFee(0, _fee)
    log UpdateServiceFeeCollector(empty(address), _service_fee_collector)
    log UpdateServiceFee(0, _service_fee)

@internal
def _safe_transfer(_token: address, _to: address, _value: uint256):
    assert ERC20(_token).transfer(_to, _value, default_return_value=True), "Failed transfer"

@external
@payable
@nonreentrant("lock")
def deposit(path: DynArray[address, MAX_SIZE], amount0: uint256, profit_taking: uint256, stop_loss: uint256, expire: uint256):
    assert block.timestamp < expire, "Invalidated expire"
    _value: uint256 = msg.value
    assert self.paloma != empty(bytes32), "Paloma not set"
    _fee: uint256 = self.fee
    if _fee > 0:
        assert _value >= _fee, "Insufficient fee"
        send(self.refund_wallet, _fee)
        _value = unsafe_sub(_value, _fee)
    assert len(path) >= 2, "Wrong path"
    token0: address = path[0]
    _amount0: uint256 = amount0
    _service_fee: uint256 = self.service_fee
    if token0 == VETH:
        assert _value >= amount0, "Insufficient deposit"
        if _value > _amount0:
            send(msg.sender, unsafe_sub(_value, _amount0))
        if _service_fee > 0:
            _service_fee_amount: uint256 = unsafe_div(_amount0 * _service_fee, DENOMINATOR)
            send(self.service_fee_collector, _service_fee_amount)
            _amount0 = unsafe_sub(_amount0, _service_fee_amount)
        WrappedEth(WETH).deposit(value=_amount0)
    else:
        send(msg.sender, _value)
        _amount0 = ERC20(token0).balanceOf(self)
        assert ERC20(token0).transferFrom(msg.sender, self, amount0, default_return_value=True), "Failed transferFrom"
        _amount0 = ERC20(token0).balanceOf(self) - _amount0
        if _service_fee > 0:
            _service_fee_amount: uint256 = unsafe_div(_amount0 * _service_fee, DENOMINATOR)
            self._safe_transfer(token0, self.service_fee_collector, _service_fee_amount)
            _amount0 = unsafe_sub(_amount0, _service_fee_amount)
    assert _amount0 > 0, "Insufficient deposit"
    deposit_id: uint256 = self.deposit_size
    self.deposits[deposit_id] = Deposit({
        path: path,
        amount: _amount0,
        depositor: msg.sender
    })
    self.deposit_size = unsafe_add(deposit_id, 1)
    log Deposited(deposit_id, token0, path[unsafe_sub(len(path), 1)], amount0, msg.sender, profit_taking, stop_loss, expire)

@internal
@nonreentrant("lock")
def _withdraw(deposit_id: uint256, expected: uint256, withdraw_type: WithdrawType) -> uint256:
    deposit: Deposit = self.deposits[deposit_id]
    if withdraw_type == WithdrawType.CANCEL:
        assert msg.sender == deposit.depositor, "Unauthorized"
    self.deposits[deposit_id] = Deposit({
        path: empty(DynArray[address, MAX_SIZE]),
        amount: empty(uint256),
        depositor: empty(address)
    })
    assert deposit.amount > 0, "Empty deposit"
    if withdraw_type == WithdrawType.CANCEL or withdraw_type == WithdrawType.EXPIRE:
        if deposit.path[0] == VETH:
            WrappedEth(WETH).withdraw(deposit.amount)
            send(deposit.depositor, deposit.amount)
        else:
            self._safe_transfer(deposit.path[0], deposit.depositor, deposit.amount)
        log Withdrawn(deposit_id, msg.sender, withdraw_type, deposit.amount)
        return deposit.amount
    else:
        last_index: uint256 = unsafe_sub(len(deposit.path), 1)
        path: DynArray[address, MAX_SIZE] = deposit.path
        if path[0] == VETH:
            path[0] = WETH
        if path[last_index] == VETH:
            path[last_index] = WETH
        assert ERC20(path[0]).approve(ROUTER, deposit.amount, default_return_value=True), "Failed approve"
        _amount0: uint256 = 0
        if deposit.path[last_index] == VETH:
            _amount0 = deposit.depositor.balance
            UniswapV2Router(ROUTER).swapExactTokensForETHSupportingFeeOnTransferTokens(deposit.amount, expected, path, deposit.depositor, block.timestamp)
            _amount0 = deposit.depositor.balance - _amount0
        else:
            _amount0 = ERC20(path[last_index]).balanceOf(self)
            UniswapV2Router(ROUTER).swapExactTokensForTokensSupportingFeeOnTransferTokens(deposit.amount, expected, path, deposit.depositor, block.timestamp)
            _amount0 = ERC20(path[last_index]).balanceOf(self) - _amount0
        log Withdrawn(deposit_id, msg.sender, withdraw_type, _amount0)
        return _amount0

@external
def cancel(deposit_id: uint256) -> uint256:
    return self._withdraw(deposit_id, 0, WithdrawType.CANCEL)

@internal
def _paloma_check():
    assert msg.sender == self.compass, "Not compass"
    assert self.paloma == convert(slice(msg.data, unsafe_sub(len(msg.data), 32), 32), bytes32), "Invalid paloma"

@external
def multiple_withdraw(deposit_ids: DynArray[uint256, MAX_SIZE], expected: DynArray[uint256, MAX_SIZE], withdraw_types: DynArray[WithdrawType, MAX_SIZE]):
    self._paloma_check()
    _len: uint256 = len(deposit_ids)
    assert _len == len(expected) and _len == len(withdraw_types), "Validation error"
    for i in range(MAX_SIZE):
        if i >= len(deposit_ids):
            break
        self._withdraw(deposit_ids[i], expected[i], withdraw_types[i])

@external
def withdraw(deposit_id: uint256, withdraw_type: WithdrawType) -> uint256:
    assert msg.sender == empty(address) # this will work as a view function only
    return self._withdraw(deposit_id, 1, withdraw_type)

@external
def update_compass(new_compass: address):
    self._paloma_check()
    self.compass = new_compass
    log UpdateCompass(msg.sender, new_compass)

@external
def update_refund_wallet(new_refund_wallet: address):
    self._paloma_check()
    old_refund_wallet: address = self.refund_wallet
    self.refund_wallet = new_refund_wallet
    log UpdateRefundWallet(old_refund_wallet, new_refund_wallet)

@external
def update_fee(new_fee: uint256):
    self._paloma_check()
    old_fee: uint256 = self.fee
    self.fee = new_fee
    log UpdateFee(old_fee, new_fee)

@external
def set_paloma():
    assert msg.sender == self.compass and self.paloma == empty(bytes32) and len(msg.data) == 36, "Invalid"
    _paloma: bytes32 = convert(slice(msg.data, 4, 32), bytes32)
    self.paloma = _paloma
    log SetPaloma(_paloma)

@external
def update_service_fee_collector(new_service_fee_collector: address):
    self._paloma_check()
    self.service_fee_collector = new_service_fee_collector
    log UpdateServiceFeeCollector(msg.sender, new_service_fee_collector)

@external
def update_service_fee(new_service_fee: uint256):
    self._paloma_check()
    assert new_service_fee < DENOMINATOR, "Wrong service fee"
    old_service_fee: uint256 = self.service_fee
    self.service_fee = new_service_fee
    log UpdateServiceFee(old_service_fee, new_service_fee)

@external
@payable
def __default__():
    pass