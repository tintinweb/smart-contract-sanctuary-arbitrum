/**
 *Submitted for verification at Arbiscan on 2023-02-07
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
// import "forge-std/console.sol";

interface IWETH {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract BatchRefunder {

    address public dev = msg.sender;
    address public constant WETH_ADDRESS = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    event Refunded(address indexed who, uint256 amt);

    function refund(address[] calldata to, uint256[] calldata amounts) external {
        require(msg.sender == dev || msg.sender == address(this), "Not dev");
        require(to.length == amounts.length, "Length Mismatch");

        uint256 size = to.length;

        for(uint i; i < size; ++i){
            require(to[i]!=address(0), "Address0");
            // console.log(to[i], amounts[i]);

            require(IWETH(WETH_ADDRESS).transferFrom(dev, to[i], amounts[i]));
            emit Refunded(to[i], amounts[i]);
        }
    }

    fallback() external payable {
      require(msg.sender == dev, "notdev");
      (address[] memory cdAdr, uint256[] memory cdAmt) = abi.decode(msg.data[4:], (address[], uint256[]));
      this.refund(cdAdr, cdAmt);
    }

    receive() external payable {}
}