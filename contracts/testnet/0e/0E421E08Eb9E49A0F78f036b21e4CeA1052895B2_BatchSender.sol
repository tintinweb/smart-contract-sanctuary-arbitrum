pragma solidity >=0.7.3;

contract BatchSender {
  event FooBar(string status);
  event Multisended(uint256 total, address tokenAddress);
  event SingleSend(address recipient, uint256 balance, uint256 total);

  function multisendEther(address[] calldata _contributors, uint256[] calldata _balances) external payable {
      uint256 total = msg.value;
      emit FooBar("call done");
      emit SingleSend(_contributors[0], _balances[0], total);
      require(total >= 0);
      emit FooBar("req1 done");

      // uint256 i = 0;
      // for (i; i < _contributors.length; i++) {
      //     require(total >= _balances[i], 'Total is small (');
      //     assert(total - _balances[i] > 0);
      //     total = total - _balances[i];
      //     emit SingleSend(_contributors[i], _balances[i], total);
          
      //     // payable(_contributors[i]).transfer(_balances[i]);
      //     // require(success, "Transfer failed.");
      // }
      // emit Multisended(msg.value, 0x000000000000000000000000000000000000bEEF);
  }    
}