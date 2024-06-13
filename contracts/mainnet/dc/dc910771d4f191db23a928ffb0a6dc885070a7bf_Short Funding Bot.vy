#pragma version 0.3.10
#pragma optimize gas
#pragma evm-version paris
"""
@title Short Funding Bot
@license Apache 2.0
@author Volume.finance
"""

struct CreateOrderParamsAddresses:
    receiver: address
    callbackContract: address
    uiFeeReceiver: address
    market: address
    initialCollateralToken: address
    swapPath: DynArray[address, MAX_SIZE]

struct CreateOrderParamsNumbers:
    sizeDeltaUsd: uint256
    initialCollateralDeltaAmount: uint256
    triggerPrice: uint256
    acceptablePrice: uint256
    executionFee: uint256
    callbackGasLimit: uint256
    minOutputAmount: uint256

enum OrderType:
    MarketSwap
    LimitSwap
    MarketIncrease
    LimitIncrease
    MarketDecrease
    LimitDecrease
    StopLossDecrease
    Liquidation

enum DecreasePositionSwapType:
    NoSwap
    SwapPnlTokenToCollateralToken
    SwapCollateralTokenToPnlToken

struct CreateOrderParams:
    addresses: CreateOrderParamsAddresses
    numbers: CreateOrderParamsNumbers
    orderType: OrderType
    decreasePositionSwapType: DecreasePositionSwapType
    isLong: bool
    shouldUnwrapNativeToken: bool
    referralCode: bytes32

event BotDeployed:
    owner: address
    bot: address

event Deposited:
    bot: address
    amount0: uint256
    order_params: CreateOrderParams

event Withdrawn:
    bot: address
    amount0: uint256
    order_params: CreateOrderParams

event Canceled:
    bot: address

event UpdateBlueprint:
    old_blueprint: address
    new_blueprint: address

event UpdateCompass:
    old_compass: address
    new_compass: address

event SetPaloma:
    paloma: bytes32

event UpdateRefundWallet:
    old_refund_wallet: address
    new_refund_wallet: address

event UpdateFee:
    old_fee: uint256
    new_fee: uint256

event UpdateServiceFeeCollector:
    old_service_fee_collector: address
    new_service_fee_collector: address

event UpdateServiceFee:
    old_service_fee: uint256
    new_service_fee: uint256

interface Bot:
    def deposit(amount0: uint256, order_params: CreateOrderParams, swap_min_amount: uint256) -> uint256: nonpayable
    def withdraw(amount0: uint256, order_params: CreateOrderParams, swap_min_amount: uint256) -> uint256: nonpayable
    def withdraw_and_end_bot(amount0: uint256, order_params: CreateOrderParams, markets: DynArray[address, MAX_SIZE], expected_token: address, _min_amount: uint256) -> uint256: nonpayable
    def end_bot(markets: DynArray[address, MAX_SIZE], expected_token: address, _min_amount: uint256) -> uint256: nonpayable

interface Router:
    def sendWnt(receiver: address, amount: uint256): payable
    def sendTokens(token: address, receiver: address, amount: uint256): payable
    def createOrder(params: CreateOrderParams) -> bytes32: nonpayable

interface ERC20:
    def balanceOf(_owner: address) -> uint256: view
    def approve(_spender: address, _value: uint256) -> bool: nonpayable
    def transfer(_to: address, _value: uint256) -> bool: nonpayable
    def transferFrom(_from: address, _to: address, _value: uint256) -> bool: nonpayable

MAX_SIZE: constant(uint256) = 8
DENOMINATOR: constant(uint256) = 10**18
GMX_ROUTER: constant(address) = 0x7C68C7866A64FA2160F78EEaE12217FFbf871fa8
USDC: constant(address) = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831
WETH: constant(address) = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1
GMX_MARKET: constant(address) = 0x6853EA96FF216fAb11D2d930CE3C508556A4bdc4
bot_to_owner: public(HashMap[address, address])
owner_to_bot: public(HashMap[address, address])
blueprint: public(address)
compass: public(address)
paloma: public(bytes32)
refund_wallet: public(address)
fee: public(uint256)
service_fee_collector: public(address)
service_fee: public(uint256)

@external
def __init__(_blueprint: address, _compass: address, _refund_wallet: address, _fee: uint256, _service_fee_collector: address, _service_fee: uint256):
    self.blueprint = _blueprint
    self.compass = _compass
    self.refund_wallet = _refund_wallet
    self.fee = _fee
    self.service_fee_collector = _service_fee_collector
    self.service_fee = _service_fee
    log UpdateCompass(empty(address), _compass)
    log UpdateBlueprint(empty(address), _blueprint)
    log UpdateRefundWallet(empty(address), _refund_wallet)
    log UpdateFee(0, _fee)
    log UpdateServiceFeeCollector(empty(address), _service_fee_collector)
    log UpdateServiceFee(0, _service_fee)

@internal
def _safe_transfer_from(_token: address, _from: address, _to: address, _value: uint256):
    assert ERC20(_token).transferFrom(_from, _to, _value, default_return_value=True), "Failed transferFrom"

@internal
def _paloma_check():
    assert msg.sender == self.compass, "Not compass"
    assert self.paloma == convert(slice(msg.data, unsafe_sub(len(msg.data), 32), 32), bytes32), "Invalid paloma"

@external
def deposit(user: address, amount0: uint256, order_params: CreateOrderParams, swap_min_amount: uint256) -> uint256:
    bot: address = self.owner_to_bot[msg.sender]
    if user == msg.sender:
        assert user != self.compass
        if bot == empty(address):
            bot = create_from_blueprint(self.blueprint, msg.sender, GMX_ROUTER, USDC, WETH, GMX_MARKET)
            self.bot_to_owner[bot] = msg.sender
            self.owner_to_bot[msg.sender] = bot
        self._safe_transfer_from(USDC, msg.sender, bot, amount0)
    else:
        self._paloma_check()
    res: uint256 = Bot(bot).deposit(amount0, order_params, swap_min_amount)
    log Deposited(bot, amount0, order_params)
    return res

@internal
def _bot_check():
    assert self.bot_to_owner[msg.sender] != empty(address), "Not bot"

@external
def withdraw(bot: address, amount0: uint256, order_params: CreateOrderParams, swap_min_amount: uint256) -> uint256:
    if self.bot_to_owner[bot] != msg.sender:
        self._paloma_check()
    res: uint256 = Bot(bot).withdraw(amount0, order_params, swap_min_amount)
    log Withdrawn(bot, amount0, order_params)
    return res

@external
def withdraw_and_end_bot(bot: address, amount0: uint256, order_params: CreateOrderParams, markets: DynArray[address, MAX_SIZE], expected_token: address, _min_amount: uint256) -> uint256:
    assert self.bot_to_owner[bot] == msg.sender, "Unauthorized"
    res: uint256 = Bot(bot).withdraw_and_end_bot(amount0, order_params, markets, expected_token, _min_amount)
    log Withdrawn(bot, amount0, order_params)
    log Canceled(msg.sender)
    return res

@external
def end_bot(bot: address, markets: DynArray[address, MAX_SIZE], expected_token: address, _min_amount: uint256) -> uint256:
    assert self.bot_to_owner[bot] == msg.sender, "Unauthorized"
    res: uint256 = Bot(bot).end_bot(markets, expected_token, _min_amount)
    log Canceled(msg.sender)
    return res

@external
def update_compass(new_compass: address):
    self._paloma_check()
    self.compass = new_compass
    log UpdateCompass(msg.sender, new_compass)

@external
def update_blueprint(new_blueprint: address):
    self._paloma_check()
    old_blueprint: address = self.blueprint
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
def update_fee(new_fee: uint256):
    self._paloma_check()
    old_fee: uint256 = self.fee
    self.fee = new_fee
    log UpdateFee(old_fee, new_fee)

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