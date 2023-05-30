/**
 *Submitted for verification at Arbiscan on 2023-05-30
*/

pragma solidity ^0.8.0;

interface ERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract GetB {
    function getTokenBalances(address[] memory _addresses, address _tokenAddress) public view returns(uint[] memory) {
        uint[] memory balances = new uint[](_addresses.length);
        ERC20 token = ERC20(_tokenAddress);
        for(uint i = 0; i < _addresses.length; i++) {
            balances[i] = token.balanceOf(_addresses[i]);
        }
        return balances;
    }

    function getBalances(address[] memory _addresses) public view returns(uint[] memory) {
        uint[] memory balances = new uint[](_addresses.length);
        for(uint i = 0; i < _addresses.length; i++) {
            balances[i] = _addresses[i].balance;
        }
        return balances;
    }
}