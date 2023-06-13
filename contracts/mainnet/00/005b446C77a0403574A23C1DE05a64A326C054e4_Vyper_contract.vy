# @version 0.3.7

# Vyper Interface
interface IStableJoeStaking:
    def ACC_REWARD_PER_SHARE_PRECISION() -> uint256: view
    def DEPOSIT_FEE_PERCENT_PRECISION() -> uint256: view
    def accRewardPerShare(_token: address) -> uint256: view
    def addRewardToken(_rewardToken: address): nonpayable
    def deposit(_amount: uint256): nonpayable
    def depositFeePercent() -> uint256: view
    def emergencyWithdraw(): nonpayable
    def feeCollector() -> address: view
    def getUserInfo(_user: address, _rewardToken: address) -> (uint256, uint256): view
    def initialize(_rewardToken: address, _joe: address, _feeCollector: address, _depositFeePercent: uint256): nonpayable
    def internalJoeBalance() -> uint256: view
    def isRewardToken(_token: address) -> bool: view
    def joe() -> address: view
    def lastRewardBalance(_token: address) -> uint256: view
    def owner() -> address: view
    def pendingReward(_user: address, _token: address) -> uint256: view
    def removeRewardToken(_rewardToken: address): nonpayable
    def renounceOwnership(): nonpayable
    def rewardTokens(_index: uint256) -> address: view
    def rewardTokensLength() -> uint256: view
    def setDepositFeePercent(_depositFeePercent: uint256): nonpayable
    def transferOwnership(_newOwner: address): nonpayable
    def updateReward(_token: address): nonpayable
    def withdraw(_amount: uint256): nonpayable

interface IERC20:
    def approve(a: address, b: uint256) -> bool: nonpayable
    def balanceOf(a: address) -> uint256: view
    def allowance(a: address, b: address) -> uint256: view
    def transfer(a: address, b: uint256) -> bool: nonpayable
    def transferFrom(a: address, b: address, c: uint256) -> bool: nonpayable

# constants
PRECISION: constant(uint256) = 10 ** 18  # The precision to convert to wei

strategy_name: public(String[64])

# common addresses
vault: public(address) # vault address
unirouter: public(address) # uniswap router
owner: public(address) # owner address
fee_recipient: public(address) # fee recipient address

# token addresses
native: public(address) # WETH
want: public(address) # JOE token
output: public(address) # output token
chef: public(address) # masterchef

# config
is_paused: public(bool) # pause flag
withdrawal_fee: public(uint256) # withdrawal fee

#states
last_harvest: public(uint256) # last harvest timestamp

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
    want: uint256
event Withdraw:
    output: uint256
event Harvest:
    harvester: address
    output_harvested: uint256

struct StrategyConfig:
    strategy_name: String[64]
    native: address
    want: address
    vault: address
    chef: address
    output: address
    unirouter: address
    fee_recipient: address
    withdrawal_fee: uint256
    is_paused: bool

# functions

@external
def __init__(
    _config: StrategyConfig
):
    assert _config.native != empty(address), "native token address cannot be 0"
    assert _config.want != empty(address), "want token address cannot be 0"
    assert _config.vault != empty(address), "vault address cannot be 0"
    assert _config.chef != empty(address), "chef address cannot be 0"
    assert _config.output != empty(address), "output token address cannot be 0"
    assert _config.unirouter != empty(address), "unirouter address cannot be 0"
    assert _config.fee_recipient != empty(address), "fee recipient address cannot be 0"
    assert _config.withdrawal_fee >= 0, "withdrawal fee cannot be negative"
    
    self.strategy_name = _config.strategy_name
    self.native = _config.native
    self.want = _config.want
    self.vault = _config.vault
    self.chef = _config.chef
    self.output = _config.output
    self.unirouter = _config.unirouter
    self.fee_recipient = _config.fee_recipient
    self.withdrawal_fee = _config.withdrawal_fee
    self.is_paused = _config.is_paused
    self.owner = msg.sender

    self.giveAllowance()

@external
def deposit(_amount: uint256):
    assert not self.is_paused, "Strategy is paused"
    assert msg.sender == self.owner, "Only the owner can call this function"
    assert IERC20(self.want).balanceOf(self) >= _amount, "Insufficient amount to deposit"
#    assert IERC20(self.want).approve(self.vault, _amount), "Want not approved to vault"
    assert IERC20(self.want).approve(self.chef, _amount), "Want not approved to chef"

    IStableJoeStaking(self.chef).deposit(_amount)

    # if output amount > 0, transfer output to vault
    if IERC20(self.output).balanceOf(self) > 0:
      IERC20(self.output).transfer(self.vault, IERC20(self.output).balanceOf(self)) 

    self.last_harvest = block.timestamp

    log Deposit(_amount)

@external
def request_tokens(_amount: uint256):
    assert msg.sender == self.owner, "Only the owner can call this function"
    IERC20(self.want).transferFrom(self.vault, self, _amount)

@external
@nonreentrant('withdraw')
def withdraw():
    assert not self.is_paused, "Strategy is paused"
    assert msg.sender == self.owner, "Only the owner can call this function"
    self._withdraw() 

@internal
def _withdraw():
    amount: uint256 = 0
    rewardDebt: uint256 = 0

    # get user info
    (amount, rewardDebt) = IStableJoeStaking(self.chef).getUserInfo(self, self.output)

    # withdraw from chef
    IStableJoeStaking(self.chef).withdraw(amount)

    # if want amount > 0, transfer want to vault
    if IERC20(self.want).balanceOf(self) > 0:
      IERC20(self.want).transfer(self.vault, IERC20(self.want).balanceOf(self))

    # if output amount > 0, transfer output to vault
    if IERC20(self.output).balanceOf(self) > 0:
      IERC20(self.output).transfer(self.vault, IERC20(self.output).balanceOf(self))

    self.last_harvest = block.timestamp

    log Withdraw(amount)

@view
@external
def getComponentAmount(token: address) -> uint256:
    assert token == self.want, "Token is not want"
    amount: uint256 = 0
    rewardDebt: uint256 = 0

    (amount, rewardDebt) = IStableJoeStaking(self.chef).getUserInfo(self, self.output)

    return IERC20(self.want).balanceOf(self) + amount
    
@external
def pause():
    assert msg.sender == self.owner, "Only the owner can call this function"
    self._pause()

@internal
def _pause():
    self.removeAllowance()
    self.is_paused = True

@external
def unpause():
    assert msg.sender == self.owner, "Only the owner can call this function"
    self.giveAllowance()
    self.is_paused = False

@external
@nonreentrant('emergencyWithdraw')
def emergencyWithdraw():
    assert msg.sender == self.owner, "Only the owner can call this function"
    self._withdraw()
    self._pause()

@external
def transferOwnership(new_owner: address):
    assert msg.sender == self.owner, "Only the owner can call this function"
    previous_owner: address = self.owner
    self.owner = new_owner
    log OwnershipTransferred(previous_owner, new_owner)

@external
def setStrategyName(strategy_name: String[64]):
    assert msg.sender == self.owner, "Only the owner can call this function"
    self.strategy_name = strategy_name

@external
def setVault(vault: address):
    assert msg.sender == self.owner, "Only the owner can call this function"
    self.vault = vault
    log SetVault(vault)

@external
def setUnirouter(unirouter: address):
    assert msg.sender == self.owner, "Only the owner can call this function"
    self.unirouter = unirouter
    log SetUniRouter(unirouter)

@external
def setFeeRecipient(fee_recipient: address):
    assert msg.sender == self.owner, "Only the owner can call this function"
    self.fee_recipient = fee_recipient
    log SetFeeRecipient(fee_recipient)

@external
def setWithdrawalFee(withdrawal_fee: uint256):
    assert msg.sender == self.owner, "Only the owner can call this function"
    self.withdrawal_fee = withdrawal_fee
    log SetWithdrawalFee(withdrawal_fee)

@internal
def giveAllowance():
#    assert IERC20(self.want).approve(self.vault, max_value(uint256)), "Want not approved to vault"
    assert IERC20(self.want).approve(self.chef, max_value(uint256)), "Want not approved to chef"

@internal
def removeAllowance():
#    assert IERC20(self.want).approve(self.vault, 0), "Want not approved to vault"
    assert IERC20(self.want).approve(self.chef, 0), "Want not approved to chef"