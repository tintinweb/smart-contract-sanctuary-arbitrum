# @version 0.3.10

"""
This contract is for testing only.
If you see it on mainnet - it won't be used for anything except testing the actual deployment
"""

event PriceWrite:
    pass


price: public(uint256)


@external
def __init__(price: uint256):
    self.price = price


@external
def price_w() -> uint256:
    # State-changing price oracle in case we want to include EMA
    log PriceWrite()
    return self.price


@external
def set_price(price: uint256):
    self.price = price