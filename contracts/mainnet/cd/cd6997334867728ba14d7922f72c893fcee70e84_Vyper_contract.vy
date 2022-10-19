# @version 0.2.16
"""
@title Liquidity Gauge v4 XChain
@author StakeDAO Protocol
@license MIT
"""

# Original idea and credit:
# Curve Finance's veCRV
# https://github.com/curvefi/curve-dao-contracts/blob/master/contracts/gauges/LiquidityGaugeV4.vy
# Mostly forked from Curve, except that now there is no direct link between the gauge controller
# and the gauges. In this implementation, SDT rewards are like any other token rewards.

from vyper.interfaces import ERC20

implements: ERC20                

interface ERC20Extended:
    def symbol() -> String[26]: view
    def decimals() -> uint256: view

interface CommonRegistry:
    def getAddrIfNotZero(_name: String[100]) -> address: view

event Deposit:
    provider: indexed(address)
    value: uint256

event Withdraw:
    provider: indexed(address)
    value: uint256

event Transfer:
    _from: indexed(address)
    _to: indexed(address)
    _value: uint256

event Approval:
    _owner: indexed(address)
    _spender: indexed(address)
    _value: uint256

event RewardDataUpdate:
    _token: indexed(address)
    _amount: uint256

struct Reward:
    token: address
    distributor: address
    period_finish: uint256
    rate: uint256
    last_update: uint256
    integral: uint256

MAX_REWARDS: constant(uint256) = 8
TOKENLESS_PRODUCTION: constant(uint256) = 40
WEEK: constant(uint256) = 604800

GOVERNANCE: constant(String[100]) = "GOVERNANCE"

staking_token: public(address)
decimal_staking_token: public(uint256)

balanceOf: public(HashMap[address, uint256])
totalSupply: public(uint256)
allowance: public(HashMap[address, HashMap[address, uint256]])

name: public(String[64])
symbol: public(String[32])

integrate_checkpoint_of: public(HashMap[address, uint256])

# For tracking external rewards
reward_count: public(uint256)
reward_tokens: public(address[MAX_REWARDS])

reward_data: public(HashMap[address, Reward])

# claimant -> default reward receiver
rewards_receiver: public(HashMap[address, address])

# reward token -> claiming address -> integral
reward_integral_for: public(HashMap[address, HashMap[address, uint256]])

# user -> [uint128 claimable amount][uint128 claimed amount]
claim_data: HashMap[address, HashMap[address, uint256]]

registry: public(CommonRegistry)

claimer: public(address)

initialized: public(bool)

vault:public(address)

@external
def __init__():
    """
    @notice Contract constructor
    @dev The contract has an initializer to prevent the take over of the implementation
    """
    assert self.initialized == False #dev: contract is already initialized
    self.initialized = True

@external
def initialize(_registry: address, _staking_token: address, _vault: address, _reward_token: address, _distributor: address, _claimer: address):
    """
    @notice Contract initializer
    @param _staking_token Liquidity Pool contract address
    @param _vault
    @param _reward_token
    @param _distributor
    """
    assert self.initialized == False #dev: contract is already initialized
    self.initialized = True

    assert _staking_token != ZERO_ADDRESS
    assert _vault != ZERO_ADDRESS
    assert _reward_token != ZERO_ADDRESS
    assert _distributor != ZERO_ADDRESS
    assert _claimer != ZERO_ADDRESS
    assert _registry != ZERO_ADDRESS

    self.staking_token = _staking_token
    self.decimal_staking_token = ERC20Extended(_staking_token).decimals()

    symbol: String[26] = ERC20Extended(_staking_token).symbol()
    self.name = concat("Stake DAO ", symbol, " Gauge")
    self.symbol = concat(symbol, "-gauge")
    self.vault = _vault
    
    self.reward_data[_reward_token].distributor = _distributor
    self.reward_tokens[0] = _reward_token
    self.reward_count = 1

    self.registry = CommonRegistry(_registry)
    self.claimer = _claimer

@view
@external
def decimals() -> uint256:
    """
    @notice Get the number of decimals for this token
    @dev Implemented as a view method to reduce gas costs
    @return uint256 decimal places
    """
    return self.decimal_staking_token

@internal
def _checkpoint_reward(_user: address, token: address, _total_supply: uint256, _user_balance: uint256, _claim: bool, receiver: address):
    """
    @notice Claim pending rewards and checkpoint rewards for a user
    """
    total_supply: uint256 = _total_supply
    user_balance: uint256 = _user_balance

    integral: uint256 = self.reward_data[token].integral
    last_update: uint256 = min(block.timestamp, self.reward_data[token].period_finish)
    duration: uint256 = last_update - self.reward_data[token].last_update
    if duration != 0:
        self.reward_data[token].last_update = last_update
        if total_supply != 0:
            integral += duration * self.reward_data[token].rate * 10**18 / total_supply
            self.reward_data[token].integral = integral

    if _user != ZERO_ADDRESS:
        integral_for: uint256 = self.reward_integral_for[token][_user]
        new_claimable: uint256 = 0

        if integral_for < integral:
            self.reward_integral_for[token][_user] = integral
            new_claimable = user_balance * (integral - integral_for) / 10**18

        claim_data: uint256 = self.claim_data[_user][token]
        total_claimable: uint256 = shift(claim_data, -128) + new_claimable
        if total_claimable > 0:
            total_claimed: uint256 = claim_data % 2**128
            if _claim:
                response: Bytes[32] = raw_call(
                    token,
                    concat(
                        method_id("transfer(address,uint256)"),
                        convert(receiver, bytes32),
                        convert(total_claimable, bytes32),
                    ),
                    max_outsize=32,
                )
                if len(response) != 0:
                    assert convert(response, bool)
                self.claim_data[_user][token] = total_claimed + total_claimable
            elif new_claimable > 0:
                self.claim_data[_user][token] = total_claimed + shift(total_claimable, 128)
                
@internal
def _checkpoint_rewards(_user: address, _total_supply: uint256, _claim: bool, _receiver: address):
    """
    @notice Claim pending rewards and checkpoint rewards for a user
    """

    receiver: address = _receiver
    user_balance: uint256 = 0
    if _user != ZERO_ADDRESS:
        user_balance = self.balanceOf[_user]
        if _claim and _receiver == ZERO_ADDRESS:
            # if receiver is not explicitly declared, check if a default receiver is set
            receiver = self.rewards_receiver[_user]
            if receiver == ZERO_ADDRESS:
                # if no default receiver is set, direct claims to the user
                receiver = _user

    reward_count: uint256 = self.reward_count
    for i in range(MAX_REWARDS):
        if i == reward_count:
            break
        token: address = self.reward_tokens[i]
        self._checkpoint_reward(_user, token, _total_supply, user_balance, _claim, receiver)

@view
@external
def claimed_reward(_addr: address, _token: address) -> uint256:
    """
    @notice Get the number of already-claimed reward tokens for a user
    @param _addr Account to get reward amount for
    @param _token Token to get reward amount for
    @return uint256 Total amount of `_token` already claimed by `_addr`
    """
    return self.claim_data[_addr][_token] % 2**128


@view
@external
def claimable_reward(_user: address, _reward_token: address) -> uint256:
    """
    @notice Get the number of claimable reward tokens for a user
    @param _user Account to get reward amount for
    @param _reward_token Token to get reward amount for
    @return uint256 Claimable reward token amount
    """
    integral: uint256 = self.reward_data[_reward_token].integral
    total_supply: uint256 = self.totalSupply
    user_balance: uint256 = self.balanceOf[_user]
        
    if total_supply != 0:
        last_update: uint256 = min(block.timestamp, self.reward_data[_reward_token].period_finish)
        duration: uint256 = last_update - self.reward_data[_reward_token].last_update
        integral += (duration * self.reward_data[_reward_token].rate * 10**18 / total_supply)

    integral_for: uint256 = self.reward_integral_for[_reward_token][_user]
    new_claimable: uint256 = user_balance * (integral - integral_for) / 10**18

    return shift(self.claim_data[_user][_reward_token], -128) + new_claimable


@external
def set_rewards_receiver(_receiver: address):
    """
    @notice Set the default reward receiver for the caller.
    @dev When set to ZERO_ADDRESS, rewards are sent to the caller
    @param _receiver Receiver address for any rewards claimed via `claim_rewards`
    """
    self.rewards_receiver[msg.sender] = _receiver

@external
def set_vault(_vault:address):
    """
    @notice Set the vault contract
    @param _vault Address of the new vault
    """
    admin: address = self.registry.getAddrIfNotZero(GOVERNANCE) 
    assert admin == msg.sender #dev : only admin can call this function 
    self.vault = _vault

@external
@nonreentrant('lock')
def claim_rewards(_addr: address = msg.sender, _receiver: address = ZERO_ADDRESS):
    """
    @notice Claim available reward tokens for `_addr`
    @param _addr Address to claim for
    @param _receiver Address to transfer rewards to - if set to
                     ZERO_ADDRESS, uses the default reward receiver
                     for the caller
    """
    if _receiver != ZERO_ADDRESS:
        assert _addr == msg.sender  # dev: cannot redirect when claiming for another user
    self._checkpoint_rewards(_addr, self.totalSupply, True, _receiver)

@external
@nonreentrant('lock')
def claim_rewards_for(_addr: address, _receiver: address):
    """
    @notice Claim available reward tokens for `_addr`
    @param _addr Address to claim for
    @param _receiver Address to transfer rewards to - if set to
                     ZERO_ADDRESS, uses the default reward receiver
                     for the caller
    """
    assert self.claimer == msg.sender  # dev: only the claim contract can claim for other 
    if _receiver != _addr:
        assert _receiver == self.claimer # dev: if the receiver is not the user it needs to be the claimer
    self._checkpoint_rewards(_addr, self.totalSupply, True, _receiver)

@external
@nonreentrant('lock')
def deposit(_value: uint256, _addr: address = msg.sender, _claim_rewards: bool = False):
    """
    @notice Deposit `_value` LP tokens
    @dev Depositting also claims pending reward tokens
    @param _value Number of tokens to deposit
    @param _addr Address to deposit for
    """
    assert msg.sender == self.vault #only vault contract can deposit
    total_supply: uint256 = self.totalSupply

    if _value != 0:  
        is_rewards: bool = self.reward_count != 0
        if is_rewards:
            self._checkpoint_rewards(_addr, total_supply, _claim_rewards, ZERO_ADDRESS)

        total_supply += _value
        new_balance: uint256 = self.balanceOf[_addr] + _value
        self.balanceOf[_addr] = new_balance
        self.totalSupply = total_supply

        ERC20(self.staking_token).transferFrom(msg.sender, self, _value)
    else:
        self._checkpoint_rewards(_addr, total_supply, False, ZERO_ADDRESS)

    log Deposit(_addr, _value)
    log Transfer(ZERO_ADDRESS, _addr, _value)


@external
@nonreentrant('lock')
def withdraw(_value: uint256, _addr: address, _claim_rewards: bool = False):
    """
    @notice Withdraw `_value` LP tokens
    @dev Withdrawing also claims pending reward tokens
    @param _value Number of tokens to withdraw
    """
    assert msg.sender == self.vault #only vault contract can withdraw
    total_supply: uint256 = self.totalSupply

    if _value != 0:
        is_rewards: bool = self.reward_count != 0
        if is_rewards:
            self._checkpoint_rewards(_addr, total_supply, _claim_rewards, ZERO_ADDRESS)

        total_supply -= _value
        new_balance: uint256 = self.balanceOf[_addr] - _value
        self.balanceOf[_addr] = new_balance
        self.totalSupply = total_supply

        ERC20(self.staking_token).transfer(msg.sender, _value)
    else:
        self._checkpoint_rewards(_addr, total_supply, False, ZERO_ADDRESS)

    log Withdraw(_addr, _value)
    log Transfer(msg.sender, ZERO_ADDRESS, _value)


@internal
def _transfer(_from: address, _to: address, _value: uint256):
    total_supply: uint256 = self.totalSupply

    if _value != 0:
        is_rewards: bool = self.reward_count != 0
        if is_rewards:
            self._checkpoint_rewards(_from, total_supply, False, ZERO_ADDRESS)
        new_balance: uint256 = self.balanceOf[_from] - _value
        self.balanceOf[_from] = new_balance

        if is_rewards:
            self._checkpoint_rewards(_to, total_supply, False, ZERO_ADDRESS)
        new_balance = self.balanceOf[_to] + _value
        self.balanceOf[_to] = new_balance
    else:
        self._checkpoint_rewards(_from, total_supply, False, ZERO_ADDRESS)
        self._checkpoint_rewards(_to, total_supply, False, ZERO_ADDRESS)

    log Transfer(_from, _to, _value)


@external
@nonreentrant('lock')
def transfer(_to : address, _value : uint256) -> bool:
    """
    @notice Transfer token for a specified address
    @dev Transferring claims pending reward tokens for the sender and receiver
    @param _to The address to transfer to.
    @param _value The amount to be transferred.
    """
    self._transfer(msg.sender, _to, _value)

    return True


@external
@nonreentrant('lock')
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    """
     @notice Transfer tokens from one address to another.
     @dev Transferring claims pending reward tokens for the sender and receiver
     @param _from address The address which you want to send tokens from
     @param _to address The address which you want to transfer to
     @param _value uint256 the amount of tokens to be transferred
    """
    _allowance: uint256 = self.allowance[_from][msg.sender]
    if _allowance != MAX_UINT256:
        self.allowance[_from][msg.sender] = _allowance - _value

    self._transfer(_from, _to, _value)

    return True


@external
def approve(_spender : address, _value : uint256) -> bool:
    """
    @notice Approve the passed address to transfer the specified amount of
            tokens on behalf of msg.sender
    @dev Beware that changing an allowance via this method brings the risk
         that someone may use both the old and new allowance by unfortunate
         transaction ordering. This may be mitigated with the use of
         {incraseAllowance} and {decreaseAllowance}.
         https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    @param _spender The address which will transfer the funds
    @param _value The amount of tokens that may be transferred
    @return bool success
    """
    self.allowance[msg.sender][_spender] = _value
    log Approval(msg.sender, _spender, _value)

    return True


@external
def increaseAllowance(_spender: address, _added_value: uint256) -> bool:
    """
    @notice Increase the allowance granted to `_spender` by the caller
    @dev This is alternative to {approve} that can be used as a mitigation for
         the potential race condition
    @param _spender The address which will transfer the funds
    @param _added_value The amount of to increase the allowance
    @return bool success
    """
    allowance: uint256 = self.allowance[msg.sender][_spender] + _added_value
    self.allowance[msg.sender][_spender] = allowance

    log Approval(msg.sender, _spender, allowance)

    return True


@external
def decreaseAllowance(_spender: address, _subtracted_value: uint256) -> bool:
    """
    @notice Decrease the allowance granted to `_spender` by the caller
    @dev This is alternative to {approve} that can be used as a mitigation for
         the potential race condition
    @param _spender The address which will transfer the funds
    @param _subtracted_value The amount of to decrease the allowance
    @return bool success
    """
    allowance: uint256 = self.allowance[msg.sender][_spender] - _subtracted_value
    self.allowance[msg.sender][_spender] = allowance

    log Approval(msg.sender, _spender, allowance)

    return True

@external
def add_reward(_reward_token: address, _distributor: address):
    """
    @notice Set the active reward contract
    """
    admin: address = self.registry.getAddrIfNotZero(GOVERNANCE) 
    assert msg.sender == admin  # dev: only owner
    assert _reward_token != ZERO_ADDRESS

    reward_count: uint256 = self.reward_count
    assert reward_count < MAX_REWARDS
    assert self.reward_data[_reward_token].distributor == ZERO_ADDRESS

    self.reward_data[_reward_token].distributor = _distributor
    self.reward_tokens[reward_count] = _reward_token
    self.reward_count = reward_count + 1

@external
def set_reward_distributor(_reward_token: address, _distributor: address):
    current_distributor: address = self.reward_data[_reward_token].distributor
    admin: address = self.registry.getAddrIfNotZero(GOVERNANCE) 
    assert msg.sender == current_distributor or msg.sender == admin
    assert current_distributor != ZERO_ADDRESS
    assert _distributor != ZERO_ADDRESS

    self.reward_data[_reward_token].distributor = _distributor

@external
def set_claimer(_claimer: address):
    admin: address = self.registry.getAddrIfNotZero(GOVERNANCE) 
    assert msg.sender == admin
    assert _claimer != ZERO_ADDRESS

    self.claimer = _claimer

@external
@nonreentrant("lock")
def deposit_reward_token(_reward_token: address, _amount: uint256):
    assert msg.sender == self.reward_data[_reward_token].distributor

    self._checkpoint_rewards(ZERO_ADDRESS, self.totalSupply, False, ZERO_ADDRESS)

    response: Bytes[32] = raw_call(
        _reward_token,
        concat(
            method_id("transferFrom(address,address,uint256)"),
            convert(msg.sender, bytes32),
            convert(self, bytes32),
            convert(_amount, bytes32),
        ),
        max_outsize=32,
    )
    if len(response) != 0:
        assert convert(response, bool)

    period_finish: uint256 = self.reward_data[_reward_token].period_finish
    if block.timestamp >= period_finish:
        self.reward_data[_reward_token].rate = _amount / WEEK
    else:
        remaining: uint256 = period_finish - block.timestamp
        leftover: uint256 = remaining * self.reward_data[_reward_token].rate
        self.reward_data[_reward_token].rate = (_amount + leftover) / WEEK

    self.reward_data[_reward_token].last_update = block.timestamp
    self.reward_data[_reward_token].period_finish = block.timestamp + WEEK

    log RewardDataUpdate(_reward_token,_amount)