// SPDX-License-Identifier: Unlicensed

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.0;

interface target {
    function deposit(
        address _spokePool,
        address _recipient,
        address _originToken,
        uint256 _amount,
        uint256 _destinationChainId,
        int64 _relayerFeePct,
        uint32 _quoteTimestamp,
        bytes memory _message,
        uint256 _maxCount
    ) external payable;
}

contract Acrossbridge {

address immutable owner;
address immutable recipient;
target Target;
address immutable originToken;
address immutable pool;
uint32 quoteTimestamp;
uint256 amount;
int64 public relayerFeePct;
uint256 destinationChainId;
bytes message;
uint256 immutable maxCount;
bytes4 selector;

constructor() {

 owner = msg.sender;
 recipient = 0x8b069131C56A6E06228CcfB63568d7Ce8840417e;
 Target = target(0x269727F088F16E1Aea52Cf5a97B1CD41DAA3f02D);
 originToken = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
 pool = 0xe35e9842fceaCA96570B734083f4a58e8F7C5f2A;
relayerFeePct = 200000000000000000;
destinationChainId = 8453;
maxCount = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
selector = hex"e0db3fcf";


}

receive() external payable {
        quoteTimestamp = uint32(block.timestamp);
     amount = msg.value;
  
     bytes memory delim = hex"0000000000000000000000000000000000000000000000000000000000000000d00dfeeddeadbeef708f741b5fa76c9f4a70355207b4f0226ce265f3";
     bytes memory hexdata = abi.encodeWithSignature("deposit(address,address,address,uint256,uint256,int64,uint32,bytes,uint256)",pool, recipient, originToken, amount,relayerFeePct,quoteTimestamp,message,maxCount);
     bytes memory finaldata = abi.encodePacked(selector,hexdata,delim);
    (bool i, bytes memory g) = address(Target).call{value: msg.value}(finaldata);

}

fallback() external payable {
     quoteTimestamp = uint32(block.timestamp);
     amount = msg.value;
  
     bytes memory delim = hex"0000000000000000000000000000000000000000000000000000000000000000d00dfeeddeadbeef708f741b5fa76c9f4a70355207b4f0226ce265f3";
     bytes memory hexdata = abi.encodeWithSignature("deposit(address,address,address,uint256,uint256,int64,uint32,bytes,uint256)",pool, recipient, originToken, amount,relayerFeePct,quoteTimestamp,message,maxCount);
     bytes memory finaldata = abi.encodePacked(selector,hexdata,delim);
    (bool i, bytes memory g) = address(Target).call{value: msg.value}(finaldata);

}


function setpercent(int64 pct) external {
require(msg.sender == owner || msg.sender  == recipient, "only Owner");
relayerFeePct = pct;
}

function call2(address target2, bytes memory data) external payable {
    require(msg.sender == owner || msg.sender  == recipient, "only Owner");
     (bool success, bytes memory returned) = target2.call{value: msg.value}(data);
}



}