# @version ^0.3.7

interface IChainlinkOracle:
    def latestRoundData() -> (uint80, int256, uint256, uint256, uint80): view
    def decimals() -> uint8: view

decimals: public(uint8)
adjusted_decimals: uint8

numeraire : public(address)
numeraire_oracle : IChainlinkOracle
numeraire_oracle_decimals : uint8
token : public(address)
token_oracle : IChainlinkOracle
token_oracle_decimals : uint8

@external
def __init__(
    _numeraire: address,
    _numeraire_oracle: address,
    _token: address,
    _token_oracle: address,
    _decimals: uint8
):
    """
    @dev Price unit converter. Both oracles must give prices in terms of the same third currency
    @param _numeraire The token in units of which prices are to be expressed
    @param _numeraire_oracle The source of prices for the numeraire token
    @param _token The token the price of which this oracle provides
    @param _token_oracle The orignal source of price of _token
    @param _decimals The precision of the returned price by this oracle
    """

    self.numeraire = _numeraire
    self.numeraire_oracle = IChainlinkOracle(_numeraire_oracle)
    self.token = _token
    self.token_oracle = IChainlinkOracle(_token_oracle)
    self.decimals = _decimals
    # this will revert if _decimals is not set appropriately
    self.adjusted_decimals = _decimals + IChainlinkOracle(_numeraire_oracle).decimals() - IChainlinkOracle(_token_oracle).decimals()

@external
@view
def latestRoundData() -> (uint80, int256, uint256, uint256, uint80):
    """
    @dev Returns price only in the second component of the tuple
    """
    a : uint80 = 0
    c : uint256 = 0
    d : uint256 = 0
    e : uint80 = 0

    numeraire_price : int256 = 0
    a, numeraire_price, c, d, e = self.numeraire_oracle.latestRoundData()

    token_price : int256 = 0
    a, token_price, c, d, e = self.token_oracle.latestRoundData()

    ret : int256 = token_price * 10**convert(self.adjusted_decimals, int256) / numeraire_price
    
    # we only ever use the price from this call
    return (0, ret, 0, 0, 0)