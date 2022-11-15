pragma solidity >=0.7.3;

contract BatchSender {
  event Multisended(uint256 total, address tokenAddress);

  function multisendEther(address[] calldata _contributors, uint256[] calldata _balances) external payable {
      uint256 total = msg.value;
      require(total >= 0);

      uint256 i = 0;
      for (i; i < _contributors.length; i++) {
          require(total >= _balances[i]);
          assert(total - _balances[i] > 0);
          total = total - _balances[i];
          
          payable(_contributors[i]).transfer(_balances[i]);
          // require(success, "Transfer failed.");
      }
      emit Multisended(msg.value, 0x000000000000000000000000000000000000bEEF);
  }    
}