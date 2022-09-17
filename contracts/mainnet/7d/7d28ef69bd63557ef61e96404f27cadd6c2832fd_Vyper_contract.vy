# @version ^0.2.16
# @notice Minimum viable test token
# @dev Deploy with name, symbol, decimals and total supply
#
# @author Maka
# @title NAS - NOT A SECURITY TOKEN

name: public(String[20])  
symbol: public(String[6]) 
decimals: public(uint256) 

event Approval:
  src: indexed(address) 
  spender: indexed(address) 
  amount: uint256

event Transfer:
  src: indexed(address)
  dst: indexed(address)
  amount: uint256 

balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])
totalSupply: public(uint256)

@external
def __init__(
  _name: String[20], 
  _symbol: String[6], 
  _decimals: uint256, 
  _supply: uint256
):
  self.name = _name         # 'Not A Securtity'
  self.symbol = _symbol     # 'NAS' 
  self.decimals = _decimals # 18
  supply: uint256 = _supply # 100*10**18
  self.balanceOf[msg.sender] = _supply
  self.totalSupply = _supply
  log Transfer(ZERO_ADDRESS, msg.sender, _supply)

@external
def approve(spender: address, amount: uint256) -> bool:
  self.allowance[msg.sender][spender] = amount
  log Approval(msg.sender, spender, amount)
  return True

@external
def transfer(dst: address, amount: uint256) -> bool:
  self.balanceOf[msg.sender] -= amount
  self.balanceOf[dst] += amount
  log Transfer(msg.sender, dst, amount)
  return True

@external
def transferFrom(src: address, dst: address, amount: uint256) -> bool:
  self.balanceOf[src] -= amount
  self.balanceOf[dst] += amount
  self.allowance[src][msg.sender] -= amount
  log Transfer(src, dst, amount)
  return True

# 1 love