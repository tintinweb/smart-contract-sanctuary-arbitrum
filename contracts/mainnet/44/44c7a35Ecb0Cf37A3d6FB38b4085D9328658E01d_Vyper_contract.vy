# @version 0.3.1
"""
@title Simple Child veOracle
"""


event UpdateCallProxy:
    _old_call_proxy: address
    _new_call_proxy: address

event TransferOwnership:
    _old_owner: address
    _new_owner: address


struct Point:
    bias: int128
    slope: int128
    ts: uint256


call_proxy: public(address)
owner: public(address)
future_owner: public(address)

user_points: public(HashMap[address, Point])
global_point: public(Point)


@external
def __init__(_call_proxy: address):
    self.call_proxy = _call_proxy
    log UpdateCallProxy(ZERO_ADDRESS, _call_proxy)

    self.owner = msg.sender
    log TransferOwnership(ZERO_ADDRESS, msg.sender)


@view
@external
def balanceOf(_user: address) -> uint256:
    last_point: Point = self.user_points[_user]
    last_point.bias -= last_point.slope * convert(block.timestamp - last_point.ts, int128)
    if last_point.bias < 0:
        last_point.bias = 0
    return convert(last_point.bias, uint256)


@view
@external
def totalSupply() -> uint256:
    last_point: Point = self.global_point
    last_point.bias -= last_point.slope * convert(block.timestamp - last_point.ts, int128)
    if last_point.bias < 0:
        last_point.bias = 0
    return convert(last_point.bias, uint256)


@external
def receive(_user_point: Point, _global_point: Point, _user: address):
    assert msg.sender == self.call_proxy

    prev_user_point: Point = self.user_points[_user]
    if _user_point.ts > prev_user_point.ts:
        self.user_points[_user] = _user_point

    prev_global_point: Point = self.global_point
    if _global_point.ts > prev_global_point.ts:
        self.global_point = _global_point


@external
def set_call_proxy(_new_call_proxy: address):
    """
    @notice Set the address of the call proxy used
    @dev _new_call_proxy should adhere to the same interface as defined
    @param _new_call_proxy Address of the cross chain call proxy
    """
    assert msg.sender == self.owner

    log UpdateCallProxy(self.call_proxy, _new_call_proxy)
    self.call_proxy = _new_call_proxy


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