/**
 *Submitted for verification at Arbiscan on 2022-03-23
*/

pragma solidity ^0.5.16;

interface PriceOracle {
    /**
     * @notice Get the underlying price of a cToken asset
     * @param cToken The cToken to get the underlying price of
     * @return The underlying asset price mantissa (scaled by 1e18).
     *  Zero means the price is unavailable.
     */
    function getUnderlyingPrice(address cToken) external view returns (uint256);
}


contract FakeAmpOracle is PriceOracle {
    PriceOracle public realOracle;
    uint public ampFactor = 1000;
    address public admin;

    constructor(PriceOracle _realOracle) public {
        realOracle = _realOracle;
        admin = msg.sender;
    }

    function setAmpFactor(uint _factor) public {
        require(admin == msg.sender, "!admin");
        ampFactor = _factor;
    }

    function getUnderlyingPrice(address cToken) public view returns(uint) {
        // this is only for tests. so we don't check for overflows.
        return ampFactor * realOracle.getUnderlyingPrice(cToken);
    }
}