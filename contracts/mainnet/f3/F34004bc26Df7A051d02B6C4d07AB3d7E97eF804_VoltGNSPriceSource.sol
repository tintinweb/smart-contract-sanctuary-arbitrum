pragma solidity ^0.8.0;

interface IGNSPriceProvider {
    function tokenPriceDai() external returns(uint);
}

interface IVOLTGNS {
    function price() external returns(uint);
}

contract VoltGNSPriceSource {
    
    IGNSPriceProvider public gnsPriceProvider;
    IVOLTGNS public voltGNSPriceProvider;

    constructor(address gns_, address voltGNS_) {
		gnsPriceProvider = IGNSPriceProvider(gns_);
        voltGNSPriceProvider = IVOLTGNS(voltGNS_);
    } 

    //gnsPriceProvider returns price in 1e10 precision
	function getPrice() external returns(uint) {
        return gnsPriceProvider.tokenPriceDai() * 1e8 * voltGNSPriceProvider.price() / 1e18;
    }
}