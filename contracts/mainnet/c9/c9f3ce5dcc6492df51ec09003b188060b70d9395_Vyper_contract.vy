# @version ^0.3

# ========================================
# Toga Party / $TOGA
# https://togaparty.xyz
# https://twitter.com/togacoin
# ========================================


# ========================================
# Section 1: Events
# ========================================

# Triggered when tokens are transferred
event Transfer:
	_from: indexed(address)
	_to: indexed(address)
	_value: uint256

# Triggered when an address approves another address to spend its tokens
event Approval:
	_owner: indexed(address)
	_spender: indexed(address)
	_value: uint256

# Triggered when the contract's ownership is transferred
event OwnershipTransferred:
	_old_owner: indexed(address)
	_new_owner: indexed(address)

# Triggered when the contract is paused or unpaused
event Pause:
	_status: bool


# ========================================
# Section 2: Token Info and Storage
# ========================================

owner: public(address)  # Contract owner's address
name: public(String[32])  # Token name
symbol: public(String[4])  # Token symbol
decimals: public(uint256)  # Token decimals
totalSupply: public(uint256)  # Total supply of tokens
paused: public(bool)  # Contract paused status
transferFee: public(uint256)  # Transfer fee for reflections
balances: HashMap[address, uint256]  # Token balances
allowances: HashMap[address, HashMap[address, uint256]]  # Token allowances


# ========================================
# Section 3: Modifiers
# ========================================

# Ensure the function caller is the contract owner
@internal
def only_owner():
	assert msg.sender == self.owner, "Only the owner can call this function."

# Ensure the contract is not paused
@internal
def when_not_paused():
	assert not self.paused, "Contract is paused."

# Ensure the contract is paused
@internal
def when_paused():
	assert self.paused, "Contract is not paused."


# ========================================
# Section 4: Initialization
# ========================================

# Initialize the contract with token information and initial supply
@external
def __init__(_name: String[32], _symbol: String[4], _decimals: uint256, _initial_supply: uint256, _transfer_fee: uint256):
	self.owner = msg.sender
	self.name = _name
	self.symbol = _symbol
	self.decimals = _decimals
	self.totalSupply = _initial_supply
	self.balances[msg.sender] = _initial_supply
	self.transferFee = _transfer_fee
	log Transfer(empty(address), msg.sender, _initial_supply)


# ========================================
# Section 5: Core Token Functions
# ========================================

# Returns the token balance of the given address
@view
@external
def balanceOf(_owner: address) -> uint256:
	return self.balances[_owner]

# Returns the allowance granted to the spender by the owner
@view
@external
def allowance(_owner: address, _spender: address) -> uint256:
	return self.allowances[_owner][_spender]

# Approves the spender to spend a certain amount of tokens on behalf of the owner
@external
def approve(_spender: address, _value: uint256) -> bool:
	self.when_not_paused()
	self.allowances[msg.sender][_spender] = _value
	log Approval(msg.sender, _spender, _value)
	return True

# Transfers tokens from the sender to the recipient
@external
def transfer(_to: address, _value: uint256) -> bool:
	self.when_not_paused()
	assert _value <= self.balances[msg.sender], "Insufficient balance"
	transferFee: uint256 = (_value * self.transferFee) / 100
	self.balances[msg.sender] -= _value
	self.balances[_to] += _value - transferFee
	self._reflect(transferFee)
	log Transfer(msg.sender, _to, _value)
	return True

# Transfers tokens on behalf of the owner to the recipient, according to the allowance
@external
def transferFrom(_from: address, _to: address, _value: uint256) -> bool:
	self.when_not_paused()
	assert _value <= self.balances[_from], "Insufficient balance"
	assert _value <= self.allowances[_from][msg.sender], "Insufficient allowance"
	self.balances[_from] -= _value
	self.balances[_to] += _value
	self.allowances[_from][msg.sender] -= _value
	log Transfer(_from, _to, _value)
	return True


# ========================================
# Section 6: Ownership Functions
# ========================================

# Renounces the ownership of the contract by setting the owner to the zero address
@external
def renounceOwnership():
	self.only_owner()
	self.when_not_paused()
	old_owner: address = self.owner
	self.owner = empty(address)
	log OwnershipTransferred(old_owner, empty(address))

# Transfers the ownership of the contract to a new owner
@external
def transferOwnership(new_owner: address):
	self.only_owner()
	self.when_not_paused()
	assert new_owner != empty(address), "New owner is the zero address"
	old_owner: address = self.owner
	self.owner = new_owner
	log OwnershipTransferred(old_owner, new_owner)


# ========================================
# Section 7: Additional Functions
# ========================================

# Internal function to handle fee distribution (reflection)
@internal
def _reflect(fee: uint256):
    self.totalSupply -= fee
    self.balances[msg.sender] -= fee

# Pauses the contract, preventing token transfers and approvals
@external
def pause():
	self.only_owner()
	self.paused = True
	log Pause(True)

# Unpauses the contract, resuming token transfers and approvals
@external
def unpause():
	self.only_owner()
	self.when_paused()
	self.paused = False
	log Pause(False)