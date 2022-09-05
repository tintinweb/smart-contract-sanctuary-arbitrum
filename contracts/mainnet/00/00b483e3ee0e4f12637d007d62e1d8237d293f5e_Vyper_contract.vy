# @version ^0.3.6
# @notice  whitehat probe

admin: address
MAX: constant(uint256) = 1024

@external
def __init__():
  self.admin = msg.sender

@external
@payable
def fn_relay(_dest: address, _data: Bytes[MAX]) -> (bool, Bytes[128]):
  assert msg.sender == self.admin
  success: bool = False
  response: Bytes[128] = b''
  success, response = raw_call(
    _dest,
    _data, 
    value=msg.value, 
    max_outsize=128, 
    revert_on_failure=False
  )

  return success, response

 # 1 love