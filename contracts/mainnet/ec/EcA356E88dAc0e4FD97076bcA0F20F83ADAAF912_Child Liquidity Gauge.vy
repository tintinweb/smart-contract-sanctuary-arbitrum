# @version 0.3.7
"""
@title Child Liquidity Gauge
@license MIT
@author Curve Finance
"""
from vyper.interfaces import ERC20

implements: ERC20


interface ERC20Extended:
    def symbol() -> String[26]: view

interface Factory:
    def owner() -> address: view
    def voting_escrow() -> address: view
    def token() -> address: view

interface Minter:
    def minted(_user: address, _gauge: address) -> uint256: view

interface ERC1271:
    def isValidSignature(_hash: bytes32, _signature: Bytes[65]) -> bytes32: view

interface VotingEscrow:
    def user_point_epoch(addr: address) -> uint256: view
    def user_point_history__ts(addr: address, epoch: uint256) -> uint256: view

interface UniswapPoorOracle:
    def getPositionStateFromKey(key: bytes32) -> uint256: view


event Approval:
    _owner: indexed(address)
    _spender: indexed(address)
    _value: uint256

event Transfer:
    _from: indexed(address)
    _to: indexed(address)
    _value: uint256

event Deposit:
    _user: indexed(address)
    _value: uint256

event Withdraw:
    _user: indexed(address)
    _value: uint256

event UpdateLiquidityLimit:
    _user: indexed(address)
    _original_balance: uint256
    _original_supply: uint256
    _working_balance: uint256
    _working_supply: uint256

event NewTokenlessProduction:
    new_tokenless_production: indexed(uint8)

event NewGaugeState:
    new_gauge_state: indexed(uint8)

event NewManager:
    new_manager: indexed(address)

event DepositRewardToken:
    reward_token: indexed(address)
    amount: uint256

event Kick:
    user: indexed(address)

event SetRewardDistributor:
    reward_token: indexed(address)
    distributor: indexed(address)

event AddReward:
    reward_token: indexed(address)

event ClaimRewards:
    user: indexed(address)
    receiver: indexed(address)

event SetRewardsReceiver:
    user: indexed(address)
    receiver: indexed(address)

struct Reward:
    distributor: address
    period_finish: uint256
    rate: uint256
    last_update: uint256
    integral: uint256


DOMAIN_TYPE_HASH: constant(bytes32) = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
PERMIT_TYPE_HASH: constant(bytes32) = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")
ERC1271_MAGIC_VAL: constant(bytes32) = 0x1626ba7e00000000000000000000000000000000000000000000000000000000

MAX_REWARDS: constant(uint256) = 8
WEEK: constant(uint256) = 86400 * 7
VERSION: constant(String[8]) = "v0.1.0"


FACTORY: immutable(address)
UNISWAP_POOR_ORACLE: immutable(UniswapPoorOracle)


DOMAIN_SEPARATOR: public(bytes32)
nonces: public(HashMap[address, uint256])

tokenless_production: public(uint8)
gauge_state: public(uint8)
lp_token: public(address)
manager: public(address)
position_key: public(bytes32)

name: public(String[64])
symbol: public(String[32])

allowance: public(HashMap[address, HashMap[address, uint256]])
balanceOf: public(HashMap[address, uint256])
totalSupply: public(uint256)

working_balances: public(HashMap[address, uint256])
working_supply: public(uint256)

period: public(uint256)
period_timestamp: public(HashMap[uint256, uint256])

integrate_checkpoint_of: public(HashMap[address, uint256])
integrate_fraction: public(HashMap[address, uint256])
integrate_inv_supply: public(HashMap[uint256, uint256])
integrate_inv_supply_of: public(HashMap[address, uint256])
last_tokenless_production_of: public(HashMap[address, uint8])

# For tracking external rewards
reward_count: public(uint256)
reward_tokens: public(address[MAX_REWARDS])
reward_data: public(HashMap[address, Reward])
# claimant -> default reward receiver
rewards_receiver: public(HashMap[address, address])
# reward token -> claiming address -> integral
reward_integral_for: public(HashMap[address, HashMap[address, uint256]])
# user -> token -> [uint128 claimable amount][uint128 claimed amount]
claim_data: HashMap[address, HashMap[address, uint256]]

inflation_rate: public(HashMap[uint256, uint256])


@external
def __init__(_factory: address, _uniswap_poor_oracle: UniswapPoorOracle):
    self.lp_token = 0x000000000000000000000000000000000000dEaD

    FACTORY = _factory
    UNISWAP_POOR_ORACLE = _uniswap_poor_oracle


@internal
def _checkpoint(_user: address):
    """
    @notice Checkpoint a user calculating their TOKEN entitlement
    @param _user User address
    """
    period: uint256 = self.period
    period_time: uint256 = self.period_timestamp[period]
    integrate_inv_supply: uint256 = self.integrate_inv_supply[period]
    killed: bool = self._is_killed()

    if block.timestamp > period_time and not killed:
        working_supply: uint256 = self.working_supply
        prev_week_time: uint256 = period_time
        week_time: uint256 = min((period_time + WEEK) / WEEK * WEEK, block.timestamp)

        for i in range(256):
            dt: uint256 = week_time - prev_week_time

            if working_supply != 0:
                # we don't have to worry about crossing inflation epochs
                # and if we miss any weeks, those weeks inflation rates will be 0 for sure
                # but that means no one interacted with the gauge for that long
                integrate_inv_supply += self.inflation_rate[prev_week_time / WEEK] * 10 ** 18 * dt / working_supply

            if week_time == block.timestamp:
                break
            prev_week_time = week_time
            week_time = min(week_time + WEEK, block.timestamp)

    # check TOKEN balance and increase weekly inflation rate by delta for the rest of the week
    TOKEN: address = Factory(FACTORY).token()
    token_balance: uint256 = ERC20(TOKEN).balanceOf(self)
    if token_balance != 0:
        current_week: uint256 = block.timestamp / WEEK
        self.inflation_rate[current_week] += token_balance / ((current_week + 1) * WEEK - block.timestamp)
        ERC20(TOKEN).transfer(FACTORY, token_balance)

    period += 1
    self.period = period
    self.period_timestamp[period] = block.timestamp
    self.integrate_inv_supply[period] = integrate_inv_supply

    working_balance: uint256 = self.working_balances[_user]
    self.integrate_fraction[_user] += working_balance * (integrate_inv_supply - self.integrate_inv_supply_of[_user]) / 10 ** 18
    self.integrate_inv_supply_of[_user] = integrate_inv_supply
    self.integrate_checkpoint_of[_user] = block.timestamp
    self.last_tokenless_production_of[_user] = self.tokenless_production


@internal
def _update_liquidity_limit(_user: address, _user_balance: uint256, _total_supply: uint256):
    """
    @notice Calculate working balances to apply amplification of TOKEN production.
    @dev https://resources.curve.fi/guides/boosting-your-crv-rewards#formula
    @param _user The user address
    @param _user_balance User's amount of liquidity (LP tokens)
    @param _total_supply Total amount of liquidity (LP tokens)
    """
    _tokenless_production: uint256 = convert(self.tokenless_production, uint256)
    working_balance: uint256 = _user_balance * _tokenless_production / 100

    voting_escrow: ERC20 = ERC20(Factory(FACTORY).voting_escrow())
    ve_ts: uint256 = voting_escrow.totalSupply()
    if ve_ts != 0:
        working_balance += _total_supply * voting_escrow.balanceOf(_user) / ve_ts * (100 - _tokenless_production) / 100
        working_balance = min(_user_balance, working_balance)

    old_working_balance: uint256 = self.working_balances[_user]
    self.working_balances[_user] = working_balance

    working_supply: uint256 = self.working_supply + working_balance - old_working_balance
    self.working_supply = working_supply

    log UpdateLiquidityLimit(_user, _user_balance, _total_supply, working_balance, working_supply)


@internal
def _checkpoint_rewards(_user: address, _total_supply: uint256, _claim: bool, _receiver: address):
    """
    @notice Claim pending rewards and checkpoint rewards for a user
    """
    user_balance: uint256 = 0
    receiver: address = _receiver
    if _user != empty(address):
        user_balance = self.balanceOf[_user]
        if _claim and _receiver == empty(address):
            # if receiver is not explicitly declared, check if a default receiver is set
            receiver = self.rewards_receiver[_user]
            if receiver == empty(address):
                # if no default receiver is set, direct claims to the user
                receiver = _user

    reward_count: uint256 = self.reward_count
    for i in range(MAX_REWARDS):
        if i == reward_count:
            break
        token: address = self.reward_tokens[i]

        integral: uint256 = self.reward_data[token].integral
        last_update: uint256 = min(block.timestamp, self.reward_data[token].period_finish)
        duration: uint256 = last_update - self.reward_data[token].last_update
        if duration != 0:
            self.reward_data[token].last_update = last_update
            if _total_supply != 0:
                integral += duration * self.reward_data[token].rate / _total_supply
                self.reward_data[token].integral = integral

        if _user != empty(address):
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
                    assert ERC20(token).transfer(receiver, total_claimable, default_return_value=True)
                    self.claim_data[_user][token] = total_claimed + total_claimable
                elif new_claimable > 0:
                    self.claim_data[_user][token] = total_claimed + shift(total_claimable, 128)


@internal
def _transfer(_from: address, _to: address, _value: uint256):
    if _value == 0:
        return
    total_supply: uint256 = self.totalSupply

    has_rewards: bool = self.reward_count != 0
    for addr in [_from, _to]:
        self._checkpoint(addr)
        self._checkpoint_rewards(addr, total_supply, False, empty(address))

    new_balance: uint256 = self.balanceOf[_from] - _value
    self.balanceOf[_from] = new_balance
    self._update_liquidity_limit(_from, new_balance, total_supply)

    new_balance = self.balanceOf[_to] + _value
    self.balanceOf[_to] = new_balance
    self._update_liquidity_limit(_to, new_balance, total_supply)

    log Transfer(_from, _to, _value)


@external
@nonreentrant("lock")
def deposit(_value: uint256, _user: address = msg.sender, _claim_rewards: bool = False):
    """
    @notice Deposit `_value` LP tokens
    @param _value Number of tokens to deposit
    @param _user The account to send gauge tokens to
    """
    self._checkpoint(_user)
    if _value == 0:
        return

    total_supply: uint256 = self.totalSupply
    new_balance: uint256 = self.balanceOf[_user] + _value

    if self.reward_count != 0:
        self._checkpoint_rewards(_user, total_supply, _claim_rewards, empty(address))

    total_supply += _value

    self.balanceOf[_user] = new_balance
    self.totalSupply = total_supply

    self._update_liquidity_limit(_user, new_balance, total_supply)

    ERC20(self.lp_token).transferFrom(msg.sender, self, _value)

    log Deposit(_user, _value)
    log Transfer(empty(address), _user, _value)


@external
@nonreentrant("lock")
def withdraw(_value: uint256, _user: address = msg.sender, _claim_rewards: bool = False):
    """
    @notice Withdraw `_value` LP tokens
    @param _value Number of tokens to withdraw
    @param _user The account to send LP tokens to
    """
    self._checkpoint(_user)
    if _value == 0:
        return

    total_supply: uint256 = self.totalSupply
    new_balance: uint256 = self.balanceOf[msg.sender] - _value

    if self.reward_count != 0:
        self._checkpoint_rewards(_user, total_supply, _claim_rewards, empty(address))

    total_supply -= _value

    self.balanceOf[msg.sender] = new_balance
    self.totalSupply = total_supply

    self._update_liquidity_limit(msg.sender, new_balance, total_supply)

    ERC20(self.lp_token).transfer(_user, _value)

    log Withdraw(_user, _value)
    log Transfer(msg.sender, empty(address), _value)


@external
@nonreentrant("lock")
def transferFrom(_from: address, _to: address, _value: uint256) -> bool:
    """
    @notice Transfer tokens from one address to another
    @param _from The address which you want to send tokens from
    @param _to The address which you want to transfer to
    @param _value the amount of tokens to be transferred
    @return bool success
    """
    allowance: uint256 = self.allowance[_from][msg.sender]
    if allowance != max_value(uint256):
        self.allowance[_from][msg.sender] = allowance - _value

    self._transfer(_from, _to, _value)
    return True


@external
def approve(_spender: address, _value: uint256) -> bool:
    """
    @notice Approve the passed address to transfer the specified amount of
            tokens on behalf of msg.sender
    @dev Beware that changing an allowance via this method brings the risk
         that someone may use both the old and new allowance by unfortunate
         transaction ordering. This may be mitigated with the use of
         {increaseAllowance} and {decreaseAllowance}.
         https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    @param _spender The address which will transfer the funds
    @param _value The amount of tokens that may be transferred
    @return bool success
    """
    self.allowance[msg.sender][_spender] = _value

    log Approval(msg.sender, _spender, _value)
    return True


@external
def permit(
    _owner: address,
    _spender: address,
    _value: uint256,
    _deadline: uint256,
    _v: uint8,
    _r: bytes32,
    _s: bytes32
) -> bool:
    """
    @notice Approves spender by owner's signature to expend owner's tokens.
        See https://eips.ethereum.org/EIPS/eip-2612.
    @dev Inspired by https://github.com/yearn/yearn-vaults/blob/main/contracts/Vault.vy#L753-L793
    @dev Supports smart contract wallets which implement ERC1271
        https://eips.ethereum.org/EIPS/eip-1271
    @param _owner The address which is a source of funds and has signed the Permit.
    @param _spender The address which is allowed to spend the funds.
    @param _value The amount of tokens to be spent.
    @param _deadline The timestamp after which the Permit is no longer valid.
    @param _v The bytes[64] of the valid secp256k1 signature of permit by owner
    @param _r The bytes[0:32] of the valid secp256k1 signature of permit by owner
    @param _s The bytes[32:64] of the valid secp256k1 signature of permit by owner
    @return True, if transaction completes successfully
    """
    assert _owner != empty(address)
    assert block.timestamp <= _deadline

    nonce: uint256 = self.nonces[_owner]
    digest: bytes32 = keccak256(
        concat(
            b"\x19\x01",
            self.DOMAIN_SEPARATOR,
            keccak256(_abi_encode(PERMIT_TYPE_HASH, _owner, _spender, _value, nonce, _deadline))
        )
    )

    if _owner.is_contract:
        sig: Bytes[65] = concat(_abi_encode(_r, _s), slice(convert(_v, bytes32), 31, 1))
        assert ERC1271(_owner).isValidSignature(digest, sig) == ERC1271_MAGIC_VAL
    else:
        assert ecrecover(digest, convert(_v, uint256), convert(_r, uint256), convert(_s, uint256)) == _owner

    self.allowance[_owner][_spender] = _value
    self.nonces[_owner] = nonce + 1

    log Approval(_owner, _spender, _value)
    return True


@external
@nonreentrant("lock")
def transfer(_to: address, _value: uint256) -> bool:
    """
    @notice Transfer token to a specified address
    @param _to The address to transfer to
    @param _value The amount to be transferred
    @return bool success
    """
    self._transfer(msg.sender, _to, _value)
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
def user_checkpoint(addr: address) -> bool:
    """
    @notice Record a checkpoint for `addr`
    @param addr User address
    @return bool success
    """
    assert msg.sender in [addr, FACTORY]  # dev: unauthorized
    self._checkpoint(addr)
    self._update_liquidity_limit(addr, self.balanceOf[addr], self.totalSupply)
    return True


@external
def claimable_tokens(addr: address) -> uint256:
    """
    @notice Get the number of claimable tokens per user
    @dev This function should be manually changed to "view" in the ABI
    @return uint256 number of claimable tokens per user
    """
    self._checkpoint(addr)
    return self.integrate_fraction[addr] - Minter(FACTORY).minted(addr, self)


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
    if total_supply != 0:
        last_update: uint256 = min(block.timestamp, self.reward_data[_reward_token].period_finish)
        duration: uint256 = last_update - self.reward_data[_reward_token].last_update
        integral += (duration * self.reward_data[_reward_token].rate / total_supply)

    integral_for: uint256 = self.reward_integral_for[_reward_token][_user]
    new_claimable: uint256 = self.balanceOf[_user] * (integral - integral_for) / 10**18

    return shift(self.claim_data[_user][_reward_token], -128) + new_claimable


@external
def set_rewards_receiver(_receiver: address):
    """
    @notice Set the default reward receiver for the caller.
    @dev When set to empty(address), rewards are sent to the caller
    @param _receiver Receiver address for any rewards claimed via `claim_rewards`
    """
    self.rewards_receiver[msg.sender] = _receiver
    log SetRewardsReceiver(msg.sender, _receiver)


@external
@nonreentrant('lock')
def claim_rewards(_addr: address = msg.sender, _receiver: address = empty(address)):
    """
    @notice Claim available reward tokens for `_addr`
    @param _addr Address to claim for
    @param _receiver Address to transfer rewards to - if set to
                     empty(address), uses the default reward receiver
                     for the caller
    """
    if _receiver != empty(address):
        assert _addr == msg.sender  # dev: cannot redirect when claiming for another user
    self._checkpoint_rewards(_addr, self.totalSupply, True, _receiver)
    log ClaimRewards(_addr, _receiver)


@external
def add_reward(_reward_token: address, _distributor: address):
    """
    @notice Set the active reward contract
    """
    assert msg.sender == self.manager or msg.sender == Factory(FACTORY).owner()

    reward_count: uint256 = self.reward_count
    assert reward_count < MAX_REWARDS
    assert self.reward_data[_reward_token].distributor == empty(address)

    self.reward_data[_reward_token].distributor = _distributor
    self.reward_tokens[reward_count] = _reward_token
    self.reward_count = reward_count + 1

    log AddReward(_reward_token)
    log SetRewardDistributor(_reward_token, _distributor)


@external
def set_reward_distributor(_reward_token: address, _distributor: address):
    current_distributor: address = self.reward_data[_reward_token].distributor

    assert msg.sender == current_distributor or msg.sender == self.manager or msg.sender == Factory(FACTORY).owner()
    assert current_distributor != empty(address)
    assert _distributor != empty(address)

    self.reward_data[_reward_token].distributor = _distributor

    log SetRewardDistributor(_reward_token, _distributor)


@external
def kick(addr: address):
    """
    @notice Kick `addr` for abusing their boost
    @dev Only if either they had another voting event, or their voting escrow lock expired, or tokenless_production has been decreased
    @param addr Address to kick
    """
    voting_escrow: address = Factory(FACTORY).voting_escrow()
    t_last: uint256 = self.integrate_checkpoint_of[addr]
    t_ve: uint256 = VotingEscrow(voting_escrow).user_point_history__ts(
        addr, VotingEscrow(voting_escrow).user_point_epoch(addr)
    )
    _balance: uint256 = self.balanceOf[addr]
    _tokenless_production: uint8 = self.tokenless_production

    assert ERC20(voting_escrow).balanceOf(addr) == 0 or t_ve > t_last or _tokenless_production < self.last_tokenless_production_of[addr] # dev: kick not allowed
    assert self.working_balances[addr] > _balance * convert(_tokenless_production, uint256) / 100  # dev: kick not needed

    self._checkpoint(addr)
    self._update_liquidity_limit(addr, self.balanceOf[addr], self.totalSupply)

    log Kick(addr)


@external
@nonreentrant("lock")
def deposit_reward_token(_reward_token: address, _amount: uint256):
    assert msg.sender == self.reward_data[_reward_token].distributor

    self._checkpoint_rewards(empty(address), self.totalSupply, False, empty(address))

    assert ERC20(_reward_token).transferFrom(msg.sender, self, _amount, default_return_value=True)

    period_finish: uint256 = self.reward_data[_reward_token].period_finish
    if block.timestamp >= period_finish:
        self.reward_data[_reward_token].rate = _amount * 10**18 / WEEK
    else:
        remaining: uint256 = period_finish - block.timestamp
        leftover: uint256 = remaining * self.reward_data[_reward_token].rate / 10**18
        self.reward_data[_reward_token].rate = (_amount + leftover) * 10**18 / WEEK

    self.reward_data[_reward_token].last_update = block.timestamp
    self.reward_data[_reward_token].period_finish = block.timestamp + WEEK

    log DepositRewardToken(_reward_token, _amount)


@external
def set_manager(_manager: address):
    assert msg.sender == Factory(FACTORY).owner()

    self.manager = _manager
    log NewManager(_manager)


@external
def makeGaugePermissionless():
    """
    @notice Uses the Uniswap Poor oracle to decide whether a gauge is alive
    """
    assert msg.sender == Factory(FACTORY).owner() # dev: only owner

    self.gauge_state = 0 # PERMISSIONLESS
    log NewGaugeState(0)


@external
def killGauge():
    """
    @notice Kills the gauge so it always yields a rate of 0 and so cannot mint rewards
    """
    assert msg.sender == Factory(FACTORY).owner() # dev: only owner

    self.gauge_state = 1 # DEAD
    log NewGaugeState(1)


@external
def unkillGauge():
    """
    @notice Unkills the gauge so it can mint rewards again
    """
    assert msg.sender == Factory(FACTORY).owner() # dev: only owner

    self.gauge_state = 2 # ALIVE

    # update period to prevent distribution of rewards while the gauge was killed
    period: uint256 = self.period + 1
    self.period = period
    self.period_timestamp[period] = block.timestamp
    log NewGaugeState(2)


@external
def set_tokenless_production(new_tokenless_production: uint8):
    """
    @notice Updates the tokenless production weight, which affects how
    much staking weight is given to liquidity and how much is given to
    vote locked tokens.
    @param new_tokenless_production The new tokenless_production value
    """
    assert msg.sender == Factory(FACTORY).owner() # dev: only owner
    assert new_tokenless_production <= 100 # dev: has to be between 0 and 100

    self.tokenless_production = new_tokenless_production

    log NewTokenlessProduction(new_tokenless_production)


@external
def rescue_token(_token: address, _recipient: address = msg.sender):
    """
    @notice Enables rescuing stuck tokens
    @dev Only the owner can call this function. Useful for when `set_token()` is called
    and there's still a balance of the old `self.token` in the factory.
    """
    assert msg.sender == Factory(FACTORY).owner() # dev: only owner
    assert (_token not in [self.lp_token, Factory(FACTORY).token()]) and (_token not in self.reward_tokens) # dev: not stealing

    assert ERC20(_token).transfer(_recipient, ERC20(_token).balanceOf(self), default_return_value=True)


@view
@external
def decimals() -> uint256:
    """
    @notice Returns the number of decimals the token uses
    """
    return 18


@view
@external
def integrate_checkpoint() -> uint256:
    return self.period_timestamp[self.period]


@view
@external
def version() -> String[8]:
    return VERSION


@view
@external
def factory() -> address:
    return FACTORY


@external
@view
def is_killed() -> bool:
    return self._is_killed()


@internal
@view
def _is_killed() -> bool:
    _gauge_state: uint8 = self.gauge_state

    if _gauge_state == 0:
        # PERMISSIONLESS
        return UNISWAP_POOR_ORACLE.getPositionStateFromKey(self.position_key) == 2 # PositionState.OUT_OF_RANGE
    else:
        # DEAD or ALIVE
        return _gauge_state == 1 # DEAD


@external
def initialize(_lp_token: address, _manager: address, _position_key: bytes32):
    assert self.lp_token == empty(address)  # dev: already initialzed

    self.lp_token = _lp_token
    self.manager = _manager
    self.position_key = _position_key

    symbol: String[26] = ERC20Extended(_lp_token).symbol()
    name: String[64] = concat("Timeless ", symbol, " Gauge Deposit")

    self.name = name
    self.symbol = concat(symbol, "-gauge")

    self.period_timestamp[0] = block.timestamp
    self.DOMAIN_SEPARATOR = keccak256(
        _abi_encode(
            DOMAIN_TYPE_HASH,
            keccak256(name),
            keccak256(VERSION),
            chain.id,
            self
        )
    )