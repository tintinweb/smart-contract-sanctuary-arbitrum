# @version 0.3.10

"""
@title Simple Vesting Escrow
@author Curve Finance, Yearn Finance
@license MIT
@notice Vests ERC20 tokens for a single address
@dev Intended to be deployed many times via `VotingEscrowFactory`
"""

from vyper.interfaces import ERC20


event Claim:
    recipient: indexed(address)
    claimed: uint256


event Revoked:
    recipient: address
    owner: address
    rugged: uint256
    ts: uint256


event Disowned:
    owner: address


event SetOpenClaim:
    state: bool


recipient: public(address)
token: public(ERC20)
start_time: public(uint256)
end_time: public(uint256)
cliff_length: public(uint256)
total_locked: public(uint256)
total_claimed: public(uint256)
disabled_at: public(uint256)
open_claim: public(bool)
initialized: public(bool)

owner: public(address)


@external
def __init__():
    # ensure that the original contract cannot be initialized
    self.initialized = True


@external
def initialize(
    owner: address,
    token: ERC20,
    recipient: address,
    amount: uint256,
    start_time: uint256,
    end_time: uint256,
    cliff_length: uint256,
    open_claim: bool,
) -> bool:
    """
    @notice Initialize the contract
    @dev This function is seperate from `__init__` because of the factory pattern
         used in `VestingEscrowFactory.deploy_vesting_contract`. It may be called
         once per deployment
    @param owner Owner address
    @param token Address of the ERC20 token being distributed
    @param recipient Address to vest tokens for
    @param amount Amount of tokens being vested for `recipient`
    @param start_time Epoch time at which token distribution starts
    @param end_time Time until everything should be vested
    @param cliff_length Duration (in seconds) after which the first portion vests
    @param open_claim Switch if anyone can claim for `recipient`
    """
    assert not self.initialized  # dev: can only initialize once
    self.initialized = True

    self.token = token
    self.owner = owner
    self.start_time = start_time
    self.end_time = end_time
    self.cliff_length = cliff_length

    self.recipient = recipient
    self.disabled_at = end_time  # Set to maximum time
    self.total_locked = amount
    self.open_claim = open_claim

    return True


@internal
@view
def _total_vested_at(time: uint256 = block.timestamp) -> uint256:
    start: uint256 = self.start_time
    end: uint256 = self.end_time
    locked: uint256 = self.total_locked
    if time < start + self.cliff_length:
        return 0
    return min(locked * (time - start) / (end - start), locked)


@internal
@view
def _unclaimed(time: uint256 = block.timestamp) -> uint256:
    return self._total_vested_at(time) - self.total_claimed


@external
@view
def unclaimed() -> uint256:
    """
    @notice Get the number of unclaimed, vested tokens for recipient
    @dev If `revoke` is activated, limit by the activation timestamp
    """
    return self._unclaimed(min(block.timestamp, self.disabled_at))


@internal
@view
def _locked(time: uint256 = block.timestamp) -> uint256:
    return self._total_vested_at(self.disabled_at) - self._total_vested_at(time)


@external
@view
def locked() -> uint256:
    """
    @notice Get the number of locked tokens for recipient
    @dev If `revoke` is activated, limit by the activation timestamp
    """
    return self._locked(min(block.timestamp, self.disabled_at))


@external
def claim(beneficiary: address = msg.sender, amount: uint256 = max_value(uint256)) -> uint256:
    """
    @notice Claim tokens which have vested
    @param beneficiary Address to transfer claimed tokens to
    @param amount Amount of tokens to claim
    """
    recipient: address = self.recipient
    assert msg.sender == recipient or self.open_claim and recipient == beneficiary  # dev: not authorized

    claim_period_end: uint256 = min(block.timestamp, self.disabled_at)
    claimable: uint256 = min(self._unclaimed(claim_period_end), amount)
    self.total_claimed += claimable

    assert self.token.transfer(beneficiary, claimable, default_return_value=True)
    log Claim(beneficiary, claimable)

    return claimable


@external
def revoke(ts: uint256 = block.timestamp, beneficiary: address = msg.sender):
    """
    @notice Disable further flow of tokens and clawback the unvested part to `beneficiary`
            Revoking more than once is futile
    @dev Owner is set to zero address
    @param ts Timestamp of the clawback
    @param beneficiary Recipient of the unvested part
    """
    owner: address = self.owner
    assert msg.sender == owner  # dev: not owner
    assert ts >= block.timestamp and ts < self.end_time  # dev: no back to the future

    ruggable: uint256 = self._locked(ts)
    self.disabled_at = ts
    self.owner = empty(address)

    assert self.token.transfer(beneficiary, ruggable, default_return_value=True)

    log Disowned(owner)
    log Revoked(self.recipient, owner, ruggable, ts)


@external
def disown():
    """
    @notice Renounce owner control of the escrow
    """
    owner: address = self.owner
    assert msg.sender == owner  # dev: not owner
    self.owner = empty(address)

    log Disowned(owner)


@external
def set_open_claim(open_claim: bool):
    """
    @notice Disallow or let anyone claim tokens for `recipient`
    """
    assert msg.sender == self.recipient  # dev: not recipient
    self.open_claim = open_claim

    log SetOpenClaim(open_claim)


@external
def collect_dust(token: ERC20, beneficiary: address = msg.sender):
    recipient: address = self.recipient
    assert msg.sender == recipient or self.open_claim and recipient == beneficiary  # dev: not authorized

    amount: uint256 = token.balanceOf(self)
    if token == self.token:
        amount = amount + self.total_claimed - self._total_vested_at(self.disabled_at)

    assert token.transfer(beneficiary, amount, default_return_value=True)
    assert self.token.balanceOf(self) >= (self._total_vested_at(self.disabled_at) - self.total_claimed)