pragma solidity ^0.8.12;

contract CandideBalances {

  /* Check the ERC20 token balances of a wallet for multiple tokens.
     Returns array of token balances in wei units. */
  function tokenBalances(address user,  address[] calldata tokens) external view returns (uint[] memory balances) {
    balances = new uint[](tokens.length);
    
    for(uint i = 0; i < tokens.length; i++) {
      if(tokens[i] != address(0x0)) { 
        balances[i] = tokenBalance(user, tokens[i]); // check token balance and catch errors
      } else {
        balances[i] = user.balance; // ETH balance    
      }
    }    
    return balances;
  }
  
  /* Check the token allowances of a specific contract for multiple tokens.
     Returns array of deposited token balances in wei units. */
  function tokenAllowances(address spenderContract, address user, address[] calldata tokens) external view returns (uint[] memory allowances) {
    allowances = new uint[](tokens.length);
    
    for(uint i = 0; i < tokens.length; i++) {
      allowances[i] = tokenAllowance(spenderContract, user, tokens[i]); // check token allowance and catch errors
    }    
    return allowances;
  }

 /* Check the token balance of a wallet in a token contract.
    Returns 0 on a bad token contract   */
  function tokenBalance(address user, address token) internal view returns (uint) {
    // token.balanceOf(user), selector 0x70a08231
    return getNumberOneArg(token, 0x70a08231, user);
  }
  
  
  /* Check the token allowance of a wallet for a specific contract.
     Returns 0 on a bad token contract.   */
  function tokenAllowance(address spenderContract, address user, address token) internal view returns (uint) {
      // token.allowance(owner, spender), selector 0xdd62ed3e
      return getNumberTwoArgs(token, 0xdd62ed3e, user, spenderContract);
  }
  
  
  
  
  /* Generic private functions */
  
  // Get a token or exchange value that requires 1 address argument (most likely arg1 == user).
  // selector is the hashed function signature (see top comments)
  function getNumberOneArg(address contractAddr, bytes4 selector, address arg1) internal view returns (uint) {
    if(isAContract(contractAddr)) {
      (bool success, bytes memory result) = contractAddr.staticcall(abi.encodeWithSelector(selector, arg1));
      // if the contract call succeeded & the result looks good to parse
      if(success && result.length == 32) {
        return abi.decode(result, (uint)); // return the result as uint
      } else {
        return 0; // function call failed, return 0
      }
    } else {
      return 0; // not a valid contract, return 0 instead of error
    }
  }
  
  // Get an exchange balance requires 2 address arguments ( (token, user) and  (user, token) are both common).
  // selector is the hashed function signature (see top comments)
  function getNumberTwoArgs(address contractAddr, bytes4 selector, address arg1, address arg2) internal view returns (uint) {
    if(isAContract(contractAddr)) {
      (bool success, bytes memory result) = contractAddr.staticcall(abi.encodeWithSelector(selector, arg1, arg2));
      // if the contract call succeeded & the result looks good to parse
      if(success && result.length == 32) {
        return abi.decode(result, (uint)); // return the result as uint
      } else {
        return 0; // function call failed, return 0
      }
    } else {
      return 0; // not a valid contract, return 0 instead of error
    }
  }
  
  // check if contract (token, exchange) is actually a smart contract and not a 'regular' address
  function isAContract(address contractAddr) internal view returns (bool) {
    uint256 codeSize;
    assembly { codeSize := extcodesize(contractAddr) } // contract code size
    return codeSize > 0; 
    // Might not be 100% foolproof, but reliable enough for an early return in 'view' functions 
  }
}