pragma solidity ^0.8.0;

interface IGDAI {
    function shareToAssetsPrice() external returns(uint);
}

contract gDAIPriceSource {
    
    IGDAI public gDAI;

    constructor(address gDAI_) {
		gDAI = IGDAI(gDAI_);
    } 

	function getPrice() external returns(uint) {
        return gDAI.shareToAssetsPrice();
    }
}