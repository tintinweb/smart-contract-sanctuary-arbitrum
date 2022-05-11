# @version 0.3.1
"""
@notice Curve Arbitrum Bridge Wrapper Refunder
"""


event TransferOwnership:
    _old_owner: address
    _new_owner: address


owner: public(address)
future_owner: public(address)


@external
def __init__():
    self.owner = msg.sender

    log TransferOwnership(ZERO_ADDRESS, msg.sender)


@payable
@external
def __default__():
    pass


@external
def withdraw():
    """
    @notice Withdraw held funds to the owner address
    @dev If the owner is a contract it must be able to receive ETH
    """
    raw_call(self.owner, b"", value=self.balance)


@external
def commit_transfer_ownership(_future_owner: address):
    """
    @notice Transfer ownership to `_future_owner`
    @param _future_owner The account to commit as the future owner
    """
    assert msg.sender == self.owner  # dev: only owner

    self.future_owner = _future_owner


@external
def accept_transfer_ownership():
    """
    @notice Accept the transfer of ownership
    @dev Only the committed future owner can call this function
    """
    assert msg.sender == self.future_owner  # dev: only future owner

    log TransferOwnership(self.owner, msg.sender)
    self.owner = msg.sender