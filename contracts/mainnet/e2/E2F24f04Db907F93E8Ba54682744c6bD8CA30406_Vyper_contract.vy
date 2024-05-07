# @version 0.3.10
"""
@notice Passthrough to allow depositing reward from multiple depositors
"""
from vyper.interfaces import ERC20

interface Gauge:
    def deposit_reward_token(_reward_token: address, _amount: uint256): nonpayable
    def reward_data(_token: address) -> (address, uint256): view
    def manager() -> address: view


OWNERSHIP_ADMIN: constant(address) = 0x452030a5D962d37D97A9D65487663cD5fd9C2B32
PARAMETER_ADMIN: constant(address) = 0x5ccbB27FB594c5cF6aC0670bbcb360c0072F6839


reward_receiver: public(address)
is_depositor: public(HashMap[address, bool])


@external
def __init__(_reward_receiver: address, _depositors: DynArray[address, 10]):
    """
    @notice Contract constructor
    @param _reward_receiver Reward receiver address
    """
    self.reward_receiver = _reward_receiver

    for depositor in _depositors:
        self.is_depositor[depositor] = True


@external
def deposit_reward_token(_reward_token: address, _amount: uint256):
    assert self.is_depositor[msg.sender]

    assert ERC20(_reward_token).transferFrom(msg.sender, self, _amount)
    assert ERC20(_reward_token).approve(self.reward_receiver, _amount)

    Gauge(self.reward_receiver).deposit_reward_token(_reward_token, _amount)


@view
@external
def reward_data(_token: address) -> (address, uint256):
    return Gauge(self.reward_receiver).reward_data(_token)


@external
def set_depositor(_depositor: address, _status: bool):
    assert msg.sender in [Gauge(self.reward_receiver).manager(), PARAMETER_ADMIN, OWNERSHIP_ADMIN]

    self.is_depositor[_depositor] = _status