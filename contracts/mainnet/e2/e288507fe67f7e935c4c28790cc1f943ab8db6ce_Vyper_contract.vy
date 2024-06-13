# @version 0.3.10

from vyper.interfaces import ERC20

reward_token: public(address)
recovery_address: public(address)

@external
def __init__(_reward_token: address,_recovery_address: address):
    """
    @notice Contract constructor
    @param _reward_token set reward token fixed
    @param _recovery_address set recovery address
    """
    self.reward_token = _reward_token
    self.recovery_address = _recovery_address

@external
def deposit_reward_token(_reward_token: address, _amount: uint256):
    """
    @notice send recoverd token to predefined recovery address
    @dev _reward_token is not used, it is just to make it compatible with the interface
    @param _reward_token reward token address
    @param _amount amount of reward token to deposit
    """
    
    assert ERC20(self.reward_token).transferFrom(msg.sender, self, _amount, default_return_value=True)


@external
def recover_token()->bool:
    """
    @notice send recoverd token to predefined recovery address
    @dev anybody can call that function to recover token
    """
    amount: uint256 = ERC20(self.reward_token).balanceOf(self)
    if amount > 0:
        assert ERC20(self.reward_token).transfer(self.recovery_address, amount)
        return True
    else:
        return False