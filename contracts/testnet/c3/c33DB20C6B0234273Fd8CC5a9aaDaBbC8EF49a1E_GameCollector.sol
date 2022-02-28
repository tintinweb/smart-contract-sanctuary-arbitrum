// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./IGameCollector.sol";

contract GameCollector is IGameCollector{

    receive() external payable {}

    fallback() external payable {}
    
    function payPrize(address player, uint256 totalPayment) public {

        (bool paymentSent, ) = player.call{value: totalPayment}("");

        require(paymentSent, "RMS: ETH PAYMENT FAILED");

    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IGameCollector {

    function payPrize(address player, uint256 totalPayment) external ;
}