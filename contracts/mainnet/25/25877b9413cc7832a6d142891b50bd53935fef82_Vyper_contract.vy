# @version 0.3.7
"""
@title Vault
@author CurveFi
@notice Holds the chain native asset and ERC20s
"""
from vyper.interfaces import ERC20


event CommitOwnership:
    future_owner: address

event ApplyOwnership:
    owner: address


NATIVE: constant(address) = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE


owner: public(address)
future_owner: public(address)


@external
def __init__(_owner: address):
    self.owner = _owner

    log ApplyOwnership(_owner)


@external
def transfer(_token: address, _to: address, _value: uint256):
    """
    @notice Transfer an asset
    @param _token The token to transfer, or NATIVE if transferring the chain native asset
    @param _to The destination of the asset
    @param _value The amount of the asset to transfer
    """
    assert msg.sender == self.owner

    if _token == NATIVE:
        send(_to, _value)
    else:
        assert ERC20(_token).transfer(_to, _value, default_return_value=True)


@external
def commit_future_owner(_future_owner: address):
    assert msg.sender == self.owner

    self.future_owner = _future_owner
    log CommitOwnership(_future_owner)


@external
def apply_future_owner():
    assert msg.sender == self.owner

    future_owner: address = self.future_owner
    self.owner = future_owner

    log ApplyOwnership(future_owner)


@payable
@external
def __default__():
    assert len(msg.data) == 0