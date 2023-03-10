# @version 0.2.12
"""
@title Liquidity Gauge v3
@author Bencu
@license MIT
"""
from vyper.interfaces import ERC20

interface CErc20:
    def balanceOf(addr: address) -> uint256: view
    def totalSupply() -> uint256: view

interface RewardPolicyMaker:
    def future_epoch_time() -> uint256: nonpayable
    def rate_at(_timestamp: uint256) -> uint256: view
    def epoch_at(_timestamp: uint256) -> uint256: view
    def epoch_start_time(_epoch: uint256) -> uint256: view

interface Controller:
    def gauge_relative_weight(addr: address, time: uint256) -> uint256: view
    def voting_escrow() -> address: view
    def checkpoint(): nonpayable
    def checkpoint_gauge(addr: address): nonpayable

interface Minter:
    def controller() -> address: view
    def minted(user: address, gauge: address) -> uint256: view

interface VotingEscrow:
    def user_point_epoch(addr: address) -> uint256: view
    def user_point_history__ts(addr: address, epoch: uint256) -> uint256: view


event Deposit:
    provider: indexed(address)
    value: uint256

event Withdraw:
    provider: indexed(address)
    value: uint256

event UpdateLiquidityLimit:
    user: address
    original_balance: uint256
    original_supply: uint256
    working_balance: uint256
    working_supply: uint256

event CommitOwnership:
    admin: address

event ApplyOwnership:
    admin: address

event RewardTokenAdded:
    token: address
    rate: uint256

event RewardRateChanged:
    token: address
    rate: uint256

event PointProportionChanged:
    proportion: uint256


MAX_REWARDS: constant(uint256) = 8
TOKENLESS_PRODUCTION: constant(uint256) = 40
WEEK: constant(uint256) = 604800
CLAIM_FREQUENCY: constant(uint256) = 3600

minter: public(address)
reward_policy_maker: public(address)
lp_token: public(address)
controller: public(address)
voting_escrow: public(address)

lpBalanceOf: HashMap[address, uint256]
lpTotalSupply: public(uint256)
totalSupply: public(uint256)

name: public(String[64])

working_balances: public(HashMap[address, uint256])
working_supply: public(uint256)

# The goal is to be able to calculate ∫(rate * balance / totalSupply dt) from 0 till checkpoint
# All values are kept in units of being multiplied by 1e18
period: public(int128)
period_timestamp: public(uint256[100000000000000000000000000000])

# 1e18 * ∫(rate(t) / totalSupply(t) dt) from 0 till checkpoint
integrate_inv_supply: public(uint256[100000000000000000000000000000])  # bump epoch when rate() changes

# 1e18 * ∫(rate(t) / totalSupply(t) dt) from (last_action) till checkpoint
integrate_inv_supply_of: public(HashMap[address, uint256])
integrate_checkpoint_of: public(HashMap[address, uint256])

# ∫(balance * rate(t) / totalSupply(t) dt) from 0 till checkpoint
# Units: rate * t = already number of coins per address to issue
integrate_fraction: public(HashMap[address, uint256])

# For tracking rewards
reward_rate: public(HashMap[address, uint256])
reward_tokens: public(address[MAX_REWARDS])
reward_timestamp: public(uint256)
reward_token_length: public(uint256)

# claimant -> default reward receiver
rewards_receiver: public(HashMap[address, address])

# reward token -> integral
reward_integral: public(HashMap[address, uint256])

# reward token -> claiming address -> integral
reward_integral_for: public(HashMap[address, HashMap[address, uint256]])

# user -> [uint128 claimable amount][uint128 claimed amount]
claim_data: HashMap[address, HashMap[address, uint256]]

admin: public(address)
future_admin: public(address)  # Can and will be a smart contract
is_killed: public(bool)


# For tracking point
point_current_epoch_time: public(uint256)
point_rate: public(uint256)
point_proportion: public(uint256)

# The goal is to be able to calculate ∫(pointrate * balance / totalSupply dt) from 0 till checkpoint
# All values are kept in units of being multiplied by 1e18
point_period: public(int128)
point_period_timestamp: public(uint256[100000000000000000000000000000])

# 1e18 * ∫(pointrate(t) / lptotalSupply(t) dt) from 0 till checkpoint
point_integrate_inv_supply: public(uint256[100000000000000000000000000000])  # bump epoch when rate() changes
point_integrate_inv_supply_of: public(HashMap[address, uint256])
point_integrate_checkpoint_of: public(HashMap[address, uint256])
point_integrate_fraction: public(HashMap[address, uint256])


@external
def __init__(_name: String[64], _lp_token: address, _minter: address,
        _admin: address, _reward_policy_maker: address, _default_point_rate: uint256, _point_proportion: uint256):
    """
    @notice Contract constructor
    @param _name gauge name
    @param _lp_token Liquidity Pool contract address
    @param _minter Minter contract address
    @param _admin Admin who can kill the gauge
    @param _reward_policy_maker Reward policy maker contract address
    """
    assert _lp_token != ZERO_ADDRESS # dev: lp_token can not be zero address

    self.name = _name

    controller: address = Minter(_minter).controller()

    self.lp_token = _lp_token
    self.minter = _minter
    self.admin = _admin
    self.reward_policy_maker = _reward_policy_maker
    self.controller = controller
    self.voting_escrow = Controller(controller).voting_escrow()

    self.period_timestamp[0] = block.timestamp

    self.point_rate = _default_point_rate
    self.point_proportion = _point_proportion
    self.point_period_timestamp[0] = block.timestamp
    self.point_current_epoch_time = (block.timestamp + WEEK) / WEEK * WEEK - WEEK


@view
@external
def integrate_checkpoint() -> uint256:
    return self.period_timestamp[self.period]


@internal
def _update_liquidity_limit(addr: address, l: uint256, L: uint256):
    """
    @notice Calculate limits which depend on the amount of CRV token per-user.
            Effectively it calculates working balances to apply amplification
            of CRV production by CRV
    @param addr User address
    @param l User's amount of liquidity (LP tokens)
    @param L Total amount of liquidity (LP tokens)
    """
    # To be called after totalSupply is updated
    _voting_escrow: address = self.voting_escrow
    voting_balance: uint256 = ERC20(_voting_escrow).balanceOf(addr)
    voting_total: uint256 = ERC20(_voting_escrow).totalSupply()

    lim: uint256 = l * TOKENLESS_PRODUCTION / 100
    if voting_total > 0:
        lim += L * voting_balance / voting_total * (100 - TOKENLESS_PRODUCTION) / 100

    lim = min(l, lim)
    old_bal: uint256 = self.working_balances[addr]
    self.working_balances[addr] = lim
    _working_supply: uint256 = self.working_supply + lim - old_bal
    self.working_supply = _working_supply

    log UpdateLiquidityLimit(addr, l, L, lim, _working_supply)


@internal
def _checkpoint_rewards( _user: address, _claim: bool, _receiver: address):
    """
    @notice Checkpoint rewards for a user
    """
    # load reward tokens and integrals into memory
    reward_tokens: address[MAX_REWARDS] = empty(address[MAX_REWARDS])
    reward_rate: uint256[MAX_REWARDS] = empty(uint256[MAX_REWARDS])
    reward_integrals: uint256[MAX_REWARDS] = empty(uint256[MAX_REWARDS])

    reward_timestamp: uint256 = self.reward_timestamp
    if reward_timestamp == 0:
        reward_timestamp = block.timestamp

    self.reward_timestamp = block.timestamp

    for i in range(MAX_REWARDS):
        token: address = self.reward_tokens[i]
        if token == ZERO_ADDRESS:
            break
        reward_tokens[i] = token
        reward_rate[i] = self.reward_rate[token]
        reward_integrals[i] = self.reward_integral[token]

    _working_supply: uint256 = self.working_supply

    if _working_supply != 0:

        dt: uint256 = block.timestamp - reward_timestamp
        # get balances after claim and calculate new reward integrals
        for i in range(MAX_REWARDS):
            token: address = reward_tokens[i]
            if token == ZERO_ADDRESS:
                break
            dI: uint256 = 10**18 * reward_rate[i] * dt / _working_supply
            if dI > 0:
                reward_integrals[i] += dI
                self.reward_integral[token] = reward_integrals[i]

    if _user != ZERO_ADDRESS:

        receiver: address = _receiver
        if _claim and receiver == ZERO_ADDRESS:
            # if receiver is not explicitly declared, check for default receiver
            receiver = self.rewards_receiver[_user]
            if receiver == ZERO_ADDRESS:
                # direct claims to user if no default receiver is set
                receiver = _user

        # calculate new user reward integral and transfer any owed rewards
        user_balance: uint256 = self.working_balances[_user]
        for i in range(MAX_REWARDS):
            token: address = reward_tokens[i]
            if token == ZERO_ADDRESS:
                break

            integral: uint256 = reward_integrals[i]
            integral_for: uint256 = self.reward_integral_for[token][_user]
            new_claimable: uint256 = 0
            if integral_for < integral:
                self.reward_integral_for[token][_user] = integral
                new_claimable = user_balance * (integral - integral_for) / 10**18

            claim_data: uint256 = self.claim_data[_user][token]
            total_claimable: uint256 = shift(claim_data, -128) + new_claimable
            if total_claimable > 0:
                total_claimed: uint256 = claim_data % 2 ** 128
                if _claim:
                    ERC20(token).transfer(receiver, total_claimable)
                    # update amount claimed (lower order bytes)
                    self.claim_data[_user][token] = total_claimed + total_claimable
                elif new_claimable > 0:
                    # update total_claimable (higher order bytes)
                    self.claim_data[_user][token] = total_claimed + shift(total_claimable, 128)


@internal
def _checkpoint_dao(addr: address):
    """
    @notice Checkpoint interest for a user
    @param addr User address
    """
    _period: int128 = self.period
    _period_time: uint256 = self.period_timestamp[_period]
    _integrate_inv_supply: uint256 = self.integrate_inv_supply[_period]

    _epoch: uint256 = RewardPolicyMaker(self.reward_policy_maker).epoch_at(block.timestamp)
    if _period_time == 0:
        _period_time = RewardPolicyMaker(self.reward_policy_maker).epoch_start_time(_epoch)

    # Update integral of 1/supply
    if block.timestamp > _period_time and not self.is_killed:
        _working_supply: uint256 = self.working_supply
        _controller: address = self.controller
        Controller(_controller).checkpoint_gauge(self)
        prev_week_time: uint256 = _period_time

        for i in range(500):
            _epoch = RewardPolicyMaker(self.reward_policy_maker).epoch_at(prev_week_time)
            week_time: uint256 = RewardPolicyMaker(self.reward_policy_maker).epoch_start_time(_epoch + 1)
            week_time = min(week_time, block.timestamp)

            dt: uint256 = week_time - prev_week_time
            w: uint256 = Controller(_controller).gauge_relative_weight(self, prev_week_time / WEEK * WEEK)

            if _working_supply > 0:
                _integrate_inv_supply += RewardPolicyMaker(self.reward_policy_maker).rate_at(prev_week_time) * w * dt / _working_supply
                # On precisions of the calculation
                # rate ~= 10e18
                # last_weight > 0.01 * 1e18 = 1e16 (if pool weight is 1%)
                # _working_supply ~= TVL * 1e18 ~= 1e26 ($100M for example)
                # The largest loss is at dt = 1
                # Loss is 1e-9 - acceptable

            if week_time == block.timestamp:
                break
            prev_week_time = week_time

    _period += 1
    self.period = _period
    self.period_timestamp[_period] = block.timestamp
    self.integrate_inv_supply[_period] = _integrate_inv_supply

    if addr != ZERO_ADDRESS:
        # Update user-specific integrals
        _working_balance: uint256 = self.working_balances[addr]
        self.integrate_fraction[addr] += _working_balance * (_integrate_inv_supply - self.integrate_inv_supply_of[addr]) / 10 ** 18
        self.integrate_inv_supply_of[addr] = _integrate_inv_supply
        self.integrate_checkpoint_of[addr] = block.timestamp

@internal
def _checkpoint(addr: address):
    """
    @notice Checkpoint for a user
    @param addr User address
    """
    _point_period: int128 = self.point_period
    _point_period_timestamp: uint256 = self.point_period_timestamp[_point_period]
    _point_integrate_inv_supply: uint256 = self.point_integrate_inv_supply[_point_period]

    rate: uint256 = self.point_rate
    prev_epoch: uint256 = self.point_current_epoch_time
    new_rate: uint256 = rate
    next_epoch: uint256 = prev_epoch + WEEK
    _totalSupply: uint256 = self.lpTotalSupply

    if block.timestamp > next_epoch:
        if _totalSupply > 0:
            new_rate = self.point_proportion * _totalSupply / WEEK
        self.point_current_epoch_time = next_epoch
        self.point_rate = new_rate

    # Update integral of 1/supply
    if block.timestamp > _point_period_timestamp and not self.is_killed:
        prev_week_time: uint256 = _point_period_timestamp
        week_time: uint256 = min((_point_period_timestamp + WEEK) / WEEK * WEEK, block.timestamp)

        for i in range(500):
            dt: uint256 = week_time - prev_week_time
            if _totalSupply > 0:
                if next_epoch >= prev_week_time and next_epoch < week_time:
                    # If we went across epoch, apply the rate
                    # of the first epoch until it ends, and then the rate of
                    # the last epoch.
                    _point_integrate_inv_supply += rate * (next_epoch - prev_week_time) / _totalSupply
                    rate = new_rate
                    _point_integrate_inv_supply += rate * (week_time - next_epoch) / _totalSupply

                else:
                    _point_integrate_inv_supply += rate * dt / _totalSupply
                    # On precisions of the calculation
                    # rate ~= 10e18
                    # _totalSupply ~= TVL * 1e18 ~= 1e26 ($100M for example)
                    # The largest loss is at dt = 1
                    # Loss is 1e-9 - acceptable

            if week_time == block.timestamp:
                break
            prev_week_time = week_time
            week_time = min(week_time + WEEK, block.timestamp)

    _point_period += 1
    self.point_period = _point_period
    self.point_period_timestamp[_point_period] = block.timestamp
    self.point_integrate_inv_supply[_point_period] = _point_integrate_inv_supply

    if addr != ZERO_ADDRESS:
        # Update user-specific integrals
        _balance: uint256 = self.lpBalanceOf[addr]
        _user_integrate_amount: uint256 = _balance * (_point_integrate_inv_supply - self.point_integrate_inv_supply_of[addr]) / 10 ** 18
        self.totalSupply += _user_integrate_amount
        self.point_integrate_fraction[addr] += _user_integrate_amount
        self.point_integrate_inv_supply_of[addr] = _point_integrate_inv_supply
        self.point_integrate_checkpoint_of[addr] = block.timestamp

@view
@internal
def _balance_of(addr: address) -> uint256:
    return self.lpBalanceOf[addr] + self.point_integrate_fraction[addr]

@external
def user_checkpoint(addr: address) -> bool:
    """
    @notice Record a checkpoint for `addr`
    @param addr User address
    @return bool success
    """
    assert (msg.sender == addr) or (msg.sender == self.minter)  # dev: unauthorized
    self._checkpoint(addr)
    self._checkpoint_dao(addr)
    self._checkpoint_rewards(addr, False, ZERO_ADDRESS)
    self._update_liquidity_limit(addr, self._balance_of(addr), self.totalSupply)
    return True


@external
def claimable_tokens(addr: address) -> uint256:
    """
    @notice Get the number of claimable tokens per user
    @dev This function should be manually changed to "view" in the ABI
    @return uint256 number of claimable tokens per user
    """
    self._checkpoint(addr)
    self._checkpoint_dao(addr)
    return self.integrate_fraction[addr] - Minter(self.minter).minted(addr, self)



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
def claimable_reward(_addr: address, _token: address) -> uint256:
    """
    @notice Get the number of claimable reward tokens for a user
    @dev This call does not consider pending claimable amount from last update time.
         Off-chain callers should instead use `claimable_rewards_write` as a
         view method.
    @param _addr Account to get reward amount for
    @param _token Token to get reward amount for
    @return uint256 Claimable reward token amount
    """
    return shift(self.claim_data[_addr][_token], -128)


@external
@nonreentrant('lock')
def claimable_reward_write(_addr: address, _token: address) -> uint256:
    """
    @notice Get the number of claimable reward tokens for a user
    @dev This function should be manually changed to "view" in the ABI
         Calling it via a transaction will claim available reward tokens
    @param _addr Account to get reward amount for
    @param _token Token to get reward amount for
    @return uint256 Claimable reward token amount
    """
    if self.reward_tokens[0] != ZERO_ADDRESS:
        self._checkpoint_rewards(_addr, False, ZERO_ADDRESS)
    return shift(self.claim_data[_addr][_token], -128)


@external
def set_rewards_receiver(_receiver: address):
    """
    @notice Set the default reward receiver for the caller.
    @dev When set to ZERO_ADDRESS, rewards are sent to the caller
    @param _receiver Receiver address for any rewards claimed via `claim_rewards`
    """
    self.rewards_receiver[msg.sender] = _receiver


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
    self._checkpoint_rewards(_addr, True, _receiver)

    # update user's point amount and working balance
    self._checkpoint_dao(_addr)
    self._checkpoint(_addr)
    self._update_liquidity_limit(_addr, self._balance_of(_addr), self.totalSupply)


@external
def kick(addr: address):
    """
    @notice Kick `addr` for abusing their boost
    @dev Only if either they had another voting event, or their voting escrow lock expired
    @param addr Address to kick
    """
    _voting_escrow: address = self.voting_escrow
    t_last: uint256 = self.integrate_checkpoint_of[addr]
    t_ve: uint256 = VotingEscrow(_voting_escrow).user_point_history__ts(
        addr, VotingEscrow(_voting_escrow).user_point_epoch(addr)
    )
    _balance: uint256 = self.lpBalanceOf[addr]

    assert ERC20(_voting_escrow).balanceOf(addr) == 0 or t_ve > t_last # dev: kick not allowed
    assert self.working_balances[addr] > _balance * TOKENLESS_PRODUCTION / 100  # dev: kick not needed

    self._checkpoint(addr)
    self._checkpoint_dao(addr)
    self._update_liquidity_limit(addr, self._balance_of(addr), self.totalSupply)


@internal
def deposit(_value: uint256, _addr: address):
    """
    @notice Deposit `_value` LP tokens
    @dev Depositting also claims pending reward tokens
    @param _value Number of tokens to deposit
    @param _addr Address to deposit for
    """

    self._checkpoint(_addr)
    self._checkpoint_dao(_addr)

    if _value != 0:
        total_supply: uint256 = self.totalSupply
        self._checkpoint_rewards(_addr, False, ZERO_ADDRESS)

        total_supply += _value
        new_balance: uint256 = self.lpBalanceOf[_addr] + _value
        self.lpBalanceOf[_addr] = new_balance
        self.totalSupply = total_supply
        self.lpTotalSupply += _value

        self._update_liquidity_limit(_addr, new_balance + self.point_integrate_fraction[_addr], total_supply)

    log Deposit(_addr, _value)


@internal
def withdraw(_value: uint256, _addr: address):
    """
    @notice Withdraw `_value` LP tokens
    @dev Withdrawing also claims pending reward tokens
    @param _value Number of tokens to withdraw
    """
    self._checkpoint(_addr)
    self._checkpoint_dao(_addr)

    if _value != 0:
        total_supply: uint256 = self.totalSupply
        self._checkpoint_rewards(_addr, False, ZERO_ADDRESS)

        # When user withdraws token, the points will be reduced in proportion to the withdrawal
        old_integrate_fraction: uint256 = self.point_integrate_fraction[_addr]
        new_integrate_fraction: uint256 = 0
        if old_integrate_fraction > 0:
            point_decrease: uint256 = old_integrate_fraction * _value / self.lpBalanceOf[_addr]
            total_supply -= point_decrease
            new_integrate_fraction = old_integrate_fraction - point_decrease
            self.point_integrate_fraction[_addr] = new_integrate_fraction

        total_supply -= _value
        new_balance: uint256 = self.lpBalanceOf[_addr] - _value
        self.lpBalanceOf[_addr] = new_balance
        self.totalSupply = total_supply
        self.lpTotalSupply -= _value

        self._update_liquidity_limit(_addr, new_balance + new_integrate_fraction, total_supply)

    log Withdraw(_addr, _value)

@view
@external
def balanceOf(_addr: address) -> uint256:
    """
    @notice Get the point balance of user
    @param _addr The user address
    @return uint256 point balance
    """
    return self._balance_of(_addr)

@view
@internal
def _is_reward_token_exist(_reward_token: address) -> bool:
    for i in range(MAX_REWARDS):
        if self.reward_tokens[i] == _reward_token:
            return True

    return False

@view
@external
def is_reward_token_exist(_reward_token: address) -> bool:
    """
    @notice Check the reward token exist
    @param _reward_token Reward token address
    @return bool is exist
    """
    return self._is_reward_token_exist(_reward_token)

@external
def add_reward_token(_reward_token: address, _token_per_second: uint256):
    """
    @notice Add the reward token and reward rate
    @param _reward_token Reward token address
    @param _token_per_second Reward rate in second
    """
    assert msg.sender == self.admin  # dev: admin only
    assert not self._is_reward_token_exist(_reward_token) # dev: the reward token is added

    token_length: uint256 = self.reward_token_length
    assert (_reward_token != ZERO_ADDRESS and token_length < MAX_REWARDS) # dev: reward token is zero or exceed max length

    self._checkpoint_rewards(ZERO_ADDRESS, False, ZERO_ADDRESS)

    self.reward_tokens[token_length] = _reward_token
    self.reward_rate[_reward_token] = _token_per_second
    token_length += 1
    self.reward_token_length = token_length


    log RewardTokenAdded(_reward_token, _token_per_second)

@external
def set_reward_rate(_reward_token: address, _token_per_second: uint256):
    """
    @notice Set reward rate
    @param _reward_token Reward token address
    @param _token_per_second Reward rate in second
    """
    assert msg.sender == self.admin  # dev: admin only
    assert self._is_reward_token_exist(_reward_token) # dev: the reward token must be added

    self._checkpoint_rewards(ZERO_ADDRESS, False, ZERO_ADDRESS)

    self.reward_rate[_reward_token] = _token_per_second

    log RewardRateChanged(_reward_token, _token_per_second)

@external
def set_killed(_is_killed: bool):
    """
    @notice Set the killed status for this contract
    @dev When killed, the gauge always yields a rate of 0 and so cannot mint CRV
    @param _is_killed Killed status to set
    """
    assert msg.sender == self.admin

    self.is_killed = _is_killed


@external
def commit_transfer_ownership(addr: address):
    """
    @notice Transfer ownership of GaugeController to `addr`
    @param addr Address to have ownership transferred to
    """
    assert msg.sender == self.admin  # dev: admin only

    self.future_admin = addr
    log CommitOwnership(addr)


@external
def accept_transfer_ownership():
    """
    @notice Accept a pending ownership transfer
    """
    _admin: address = self.future_admin
    assert msg.sender == _admin  # dev: future admin only

    self.admin = _admin
    log ApplyOwnership(_admin)

@external
@nonreentrant('lock')
def notifySavingsChange(addr: address):
    """
    @notice Notify the saving balance of addr changed
    """
    old_balance: uint256 = self.lpBalanceOf[addr]
    new_balance: uint256 = CErc20(self.lp_token).balanceOf(addr)
    if old_balance < new_balance:
        self.deposit(new_balance - old_balance, addr)
    else:
        self.withdraw(old_balance - new_balance, addr)


@external
def set_point_proportion(_point_proportion: uint256):
    """
    @notice Set point proportion
    """
    assert msg.sender == self.admin  # dev: admin only

    self._checkpoint(ZERO_ADDRESS)
    self.point_proportion = _point_proportion

    log PointProportionChanged(_point_proportion)

@external
@nonreentrant('lock')
def balance_of_write(_addr: address) -> uint256:
    """
    @notice Get the number of point for a user
    @dev This function should be manually changed to "view" in the ABI
         Calling it via a transaction will update point balance
    @param _addr Account to get point amount for
    @return uint256 Point amount
    """
    self._checkpoint(_addr)
    return self._balance_of(_addr)