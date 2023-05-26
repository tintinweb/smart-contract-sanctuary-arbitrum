# @version 0.3.7

interface IERC20:
    def approve(a: address, b: uint256) -> bool: nonpayable
    def balanceOf(a: address) -> uint256: view
    def allowance(a: address, b: address) -> uint256: view
    def transfer(a: address, b: uint256) -> bool: nonpayable
    def transferFrom(a: address, b: address, c: uint256) -> bool: nonpayable

interface IGMXRouter:
    def stakeGmx(amount: uint256): nonpayable 
    def unstakeGmx(amount: uint256): nonpayable
    def compound(): nonpayable
    def claimFees(): nonpayable
    def mintAndStakeGlp(
        _token: address,
        _amount: uint256,
        _minUsdg: uint256,
        _minGlp: uint256
    ) -> uint256: nonpayable
    def unstakeAndRedeemGlp(
        _tokenOut: address,
        _glpAmount: uint256,
        _minOut: uint256,
        _receiver: address
    ) -> uint256: nonpayable
    def feeGlpTracker() -> address: view
    def feeGmxTracker() -> address: view
    def stakedGmxTracker() -> address: view
    def glpManager() -> address: view
    def glp() -> address: view
    def signalTransfer(_receiver: address): nonpayable
    def acceptTransfer(_sender: address): nonpayable

interface IGMXTracker:
    def claim(receiver: address): nonpayable
    def claimable(user: address) -> uint256: view
    def depositBalances(user: address, token: address) -> uint256: view
    def stakedAmounts(user: address) -> uint256: view

# constants
PRECISION: constant(uint256) = 10 ** 18  # The precision to convert to wei

strategy_name: public(String[64])

# common addresses
vault: public(address)
unirouter: public(address)
owner: public(address)
fee_recipient: public(address)

# token addresses
native: public(address)
want: public(address)
chef: public(address)
gmx_reward_storage: public(address)
staked_gmx_tracker: public(address)

# configs
is_paused: public(bool)
withdrawal_fee: public(uint256)

# states
last_harvest: public(uint256)

# events
event SetVault:
    vault: address
event OwnershipTransferred:
    previousOwner: address
    newOwner: address
event SetUniRouter:
    unirouter: address
event SetFeeRecipient:
    feeRecipient: address
event SetWithdrawalFee:
    withdrawal_fee: uint256
event Deposit:
    tvl: uint256
event Withdraw:
    tvl: uint256
event Harvest:
    harvester: address
    want_harvested: uint256
    tvl: uint256

struct StrategyConfig:
    strategy_name: String[64]
    vault: address
    unirouter: address
    fee_recipient: address
    want: address
    native: address
    chef: address

@external
def __init__(
    _config: StrategyConfig,
):
    assert _config.vault != empty(address), "Vault address cannot be 0"
    assert _config.unirouter != empty(address), "Unirouter address cannot be 0"
    assert _config.chef != empty(address), "Chef address cannot be 0"
    assert _config.fee_recipient != empty(address), "Fee recipient address cannot be 0"
    assert _config.want != empty(address), "Want address cannot be 0"
    assert _config.native != empty(address), "Native address cannot be 0"
    
    self.strategy_name = _config.strategy_name

    self.vault = _config.vault
    self.unirouter = _config.unirouter
    self.owner = msg.sender
    self.fee_recipient = _config.fee_recipient

    self.native = _config.native
    self.want = _config.want
    self.chef = _config.chef
    self.gmx_reward_storage = IGMXRouter(_config.chef).feeGmxTracker()
    self.staked_gmx_tracker = IGMXRouter(_config.chef).stakedGmxTracker()

    self.is_paused = False
    self.withdrawal_fee = 0

    self.last_harvest = block.timestamp

    self._give_allowances()

@view
@external
def getComponentAmount(token: address) -> uint256:
    assert token == self.want, "Token is not want"
    pool_balance: uint256 = IGMXTracker(self.staked_gmx_tracker).depositBalances(self, self.want)
    want_balance: uint256 = IERC20(self.want).balanceOf(self)
    return pool_balance + want_balance 

@view
@external
def pending_rewards() -> uint256:
    return IGMXTracker(self.gmx_reward_storage).claimable(self)

@external
def deposit():
    assert msg.sender == self.owner, "Only the owner can call this function"
    self._deposit()

@external
def request_tokens(_amount: uint256):
    assert msg.sender == self.owner, "Only the owner can call this function"
    IERC20(self.want).transferFrom(self.vault, self, _amount)

@internal
def _deposit():
    assert msg.sender == self.owner, "Only the owner can call this function"
    assert not self.is_paused, "Strategy is paused"

    want: uint256 = IERC20(self.want).balanceOf(self)

    if (want > 0):
        IGMXRouter(self.chef).stakeGmx(want)

    log Deposit(self.balance)

@external
@nonreentrant("withdraw")
def withdraw(_amount: uint256):
    assert msg.sender == self.owner, "Only the vault can call this function"
    assert not self.is_paused, "Strategy is paused"

    want: uint256 = IERC20(self.want).balanceOf(self)

    if (want < _amount):
        IGMXRouter(self.chef).unstakeGmx(_amount - want)
        want = IERC20(self.want).balanceOf(self)
    
    if (want > _amount):
        want = _amount
    
    if (self.withdrawal_fee > 0):
        fee: uint256 = want * self.withdrawal_fee / PRECISION
        IERC20(self.want).transfer(self.fee_recipient, fee)
        want = want - fee
    
    IERC20(self.want).transfer(self.vault, want)

    log Withdraw(self.balance)

@external
def harvest():
    assert not self.is_paused, "Strategy is paused"
    assert block.timestamp - self.last_harvest >= 3600, "Harvest interval not reached"
    assert msg.sender == self.owner, "Only the vault can call this function"

    IGMXRouter(self.chef).compound()

    IGMXTracker(self.gmx_reward_storage).claim(self)

    nativeBalance: uint256 = IERC20(self.native).balanceOf(self)
    if (nativeBalance > 0):
        want_harvested: uint256 = IERC20(self.want).balanceOf(self)
        self._deposit()
        native_harvested: uint256 = IERC20(self.native).balanceOf(self)
        IERC20(self.native).transfer(self.vault, native_harvested)
        self.last_harvest = block.timestamp
        log Harvest(msg.sender ,want_harvested, self.balance)

@external
def panic():
    assert msg.sender == self.owner, "Only the owner can call this function"
    self._pause()
    pool_balance: uint256 = IGMXTracker(self.staked_gmx_tracker).depositBalances(self, self.want)
    IGMXRouter(self.chef).unstakeGmx(pool_balance)

@external
def pause():
    assert msg.sender == self.owner, "Only the owner can call this function"
    self._pause()

@internal
def _pause():
    assert msg.sender == self.owner, "Only the owner can call this function"
    self._remove_allowances()
    self.is_paused = True

@external
def unpause():
    assert msg.sender == self.owner, "Only the owner can call this function"
    self._give_allowances()
    self.is_paused = False

@external
def emergency_withdraw():
    assert msg.sender == self.owner, "Only the owner can call this function"
    self._pause()
    pool_balance: uint256 = IGMXTracker(self.staked_gmx_tracker).depositBalances(self, self.want)
    IGMXRouter(self.chef).unstakeGmx(pool_balance)
    IERC20(self.want).transfer(self.vault, IERC20(self.want).balanceOf(self))

@external
def transfer_ownership(new_owner: address):
    assert msg.sender == self.owner, "Only the owner can call this function"
    previous_owner: address = self.owner
    self.owner = new_owner
    log OwnershipTransferred(previous_owner, new_owner)

@external
def set_strategy_name(_strategy_name: String[64]):
    assert msg.sender == self.owner, "Only the owner can call this function"
    self.strategy_name = _strategy_name

@external
def set_vault(_vault: address):
    assert msg.sender == self.owner, "Only the owner can call this function"
    self.vault = _vault
    log SetVault(_vault)

@external
def set_unirouter(_unirouter: address):
    assert msg.sender == self.owner, "Only the owner can call this function"
    self.unirouter = _unirouter
    log SetUniRouter(_unirouter)

@external
def set_fee_recipient(_fee_recipient: address):
    assert msg.sender == self.owner, "Only the owner can call this function"
    self.fee_recipient = _fee_recipient
    log SetFeeRecipient(_fee_recipient)

@external
def set_withdrawal_fee(_withdrawal_fee: uint256):
    assert msg.sender == self.owner, "Only the owner can call this function"
    self.withdrawal_fee = _withdrawal_fee
    log SetWithdrawalFee(_withdrawal_fee)

@internal
def _give_allowances():
    assert msg.sender == self.owner, "Only the owner can call this function"
    IERC20(self.want).approve(self.staked_gmx_tracker, max_value(uint256))
    IERC20(self.native).approve(self.unirouter, max_value(uint256))

@internal
def _remove_allowances():
    assert msg.sender == self.owner, "Only the owner can call this function"
    IERC20(self.want).approve(self.staked_gmx_tracker, 0)
    IERC20(self.native).approve(self.unirouter, 0)