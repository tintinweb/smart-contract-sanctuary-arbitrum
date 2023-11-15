# SPDX-License-Identifier: AGPL-3.0

interface Dmap:
    def set(name: bytes32, meta: bytes32, data: bytes32): nonpayable
    def get(key: bytes32) -> (bytes32, bytes32): view

event Commit:
    commitment: bytes32
    amount: uint256

event Transfer:
    owner: address
    recipient: address
    name: bytes32

event Configure:
    param: uint256
    data: bytes32

event Extend:
    name: bytes32
    term: uint256

THREE_YEARS:  public(constant(uint256)) = 94608000
MAX_MATURITY: public(constant(uint256)) = 2 ** 39 - 1
DMAP:         public(immutable(Dmap))
gov:          public(address)
treasury:     public(address)
rate:         public(uint256)
breakeven:    public(uint256)
commitment:   public(HashMap[bytes32, uint256])
owner:        public(HashMap[bytes32, address])
names:        public(DynArray[bytes32, max_value(uint248)])

@external
def __init__(d: address, gov: address, treasury: address, rate: uint256):
    DMAP           = Dmap(d)
    self.gov       = gov
    self.treasury  = treasury
    self.rate      = rate
    self.breakeven = THREE_YEARS

@payable
@external
def commit(commitment: bytes32):
    self.commitment[commitment] = msg.value
    _: bool = raw_call(self.treasury, b"", value=msg.value, revert_on_failure=False)
    log Commit(commitment, msg.value)

@external
def take(salt: bytes32, name: bytes32, data: bytes32, term: uint256):
    commitment: bytes32 = keccak256(_abi_encode(salt, name, data, term))    
    if self.commitment[commitment] < self.rate * term: raise "ERR_PAYMENT"
    if block.timestamp < self._maturity(name):         raise "ERR_PREMATURE"
    self.commitment[commitment] = 0
    self.owner[name]            = msg.sender
    maturity: uint256 = MAX_MATURITY if self.breakeven <= term else block.timestamp + term
    self._set(name, convert(maturity << 1, bytes32), data)
    log Transfer(empty(address), msg.sender, name)

@external
@payable
def extend(name: bytes32, term: uint256):
    if self.owner[name] != msg.sender: raise "ERR_OWNER"
    if msg.value < self.rate * term:   raise "ERR_PAYMENT"
    meta: bytes32     = empty(bytes32)
    data: bytes32     = empty(bytes32)        
    meta, data        = DMAP.get(keccak256(_abi_encode(self, name)))
    maturity: uint256 = convert(meta, uint256) >> 1
    maturity          = MAX_MATURITY if self.breakeven <= term else maturity + term
    lock: uint256     = convert(meta, uint256) & 1
    meta              = convert((maturity << 1) | lock, bytes32)    
    self._set(name, meta, data)
    _: bool = raw_call(self.treasury, b"", value=msg.value, revert_on_failure=False)
    log Extend(name, term)

@external
def set(name: bytes32, data: bytes32):
    if self.owner[name] != msg.sender: raise "ERR_OWNER"
    meta: bytes32 = empty(bytes32)
    _:    bytes32 = empty(bytes32)    
    meta, _       = DMAP.get(keccak256(_abi_encode(self, name)))
    self._set(name, meta, data)

@external
def lock(name: bytes32):
    if self.owner[name] != msg.sender: raise "ERR_OWNER"
    meta: bytes32     = empty(bytes32)
    data: bytes32     = empty(bytes32)
    meta, data        = DMAP.get(keccak256(_abi_encode(self, name)))
    maturity: uint256 = convert(meta, uint256) >> 1
    if maturity < MAX_MATURITY: raise "ERR_MATURITY"    
    self._set(name, convert(convert(meta, uint256) | 1, bytes32), data)    

@external
def transfer(name: bytes32, recipient: address):
    if self.owner[name] != msg.sender: raise "ERR_OWNER"
    self.owner[name] = recipient
    log Transfer(msg.sender, recipient, name)

@external
def configure(param: uint256, data: bytes32):
    if msg.sender != self.gov: raise "ERR_GOV"
    if   param == 1: self.gov       = convert(data, address)
    elif param == 2: self.treasury  = convert(data, address)
    elif param == 3: self.rate      = convert(data, uint256)
    elif param == 4: self.breakeven = convert(data, uint256)
    log Configure(param, data)

@internal
@view
def _maturity(name: bytes32) -> uint256:
    meta: bytes32 = empty(bytes32)
    _:    bytes32 = empty(bytes32)
    meta, _       = DMAP.get(keccak256(_abi_encode(self, name)))
    return convert(meta, uint256) >> 1

@internal
def _set(name: bytes32, meta: bytes32, data: bytes32):
    if self._maturity(name) == 0: self.names.append(name)
    DMAP.set(name, meta, data)