# @version 0.2.4

"""
@title Gauge Controller
@license MIT
@notice Controls liquidity gauges and the issuance of coins through the gauges
"""

event CommitOwnership:
    admin: address

event ApplyOwnership:
    admin: address

admin: public(address)  # Can and will be a smart contract
future_admin: public(address)  # Can and will be a smart contract
# Needed for enumeration
valid_gauge: HashMap[address, bool]
gauge_relative_weight_: HashMap[address, uint256]

@external
def __init__():
    self.admin = msg.sender

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
def apply_transfer_ownership():
    """
    @notice Apply pending ownership transfer
    """
    assert msg.sender == self.admin  # dev: admin only
    _admin: address = self.future_admin
    assert _admin != ZERO_ADDRESS  # dev: admin not set
    self.admin = _admin
    log ApplyOwnership(_admin)

@external
@view
def gauge_relative_weight(addr: address, time: uint256 = block.timestamp) -> uint256:
    return self.gauge_relative_weight_[addr]

@external
def set_gauge_relative_weight(addr: address, weight: uint256):
    assert msg.sender == self.admin  # dev: admin only
    self.valid_gauge[addr] = True
    self.gauge_relative_weight_[addr] = weight

@external
def set_gauge_valid(addr: address, valid: bool):
    assert msg.sender == self.admin  # dev: admin only
    self.valid_gauge[addr] = valid