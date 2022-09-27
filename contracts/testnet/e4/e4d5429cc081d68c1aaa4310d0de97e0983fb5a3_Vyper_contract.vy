storedData: immutable(uint256)
storedData2: immutable(address)

@external
def __init__(_a: address):
  storedData = block.timestamp
  storedData2 = _a

@view
@external
def returnStoredData() -> uint256:
    return storedData

@view
@external
def returnStoredData2() -> address:
    return storedData2