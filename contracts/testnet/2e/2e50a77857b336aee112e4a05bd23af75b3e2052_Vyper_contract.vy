# @version ^0.3.1

"""
Events
- examples
    - user interface
    - cheap storage (cannot access inside smart contract)
"""
# up to 3 indexed arguments
event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256

event Authorized:
    addr: indexed(address)
    authorized: bool

authorized: public(HashMap[address, bool])

@external
def __init__():
    self.authorized[msg.sender] = True

@external
def transfer(to: address, amount: uint256):
    # transfer logic here...
    log Transfer(msg.sender, to, amount)

### example of cheap storage ###
@external
def grantAuthorization(addr: address):
    assert self.authorized[msg.sender], "!authorized"
    self.authorized[addr] = True
    log Authorized(addr, True)

@external
def revokeAuthorization(addr: address):
    assert self.authorized[msg.sender], "!authorized"
    self.authorized[addr] = False
    log Authorized(addr, False)