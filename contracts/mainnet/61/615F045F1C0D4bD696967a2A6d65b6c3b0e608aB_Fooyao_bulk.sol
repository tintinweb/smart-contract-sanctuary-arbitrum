/**
 *Submitted for verification at Arbiscan.io on 2023-09-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface interfaceMaster {
  function myProxyNum(address user) external view returns (uint256);
  function batchActivate(address user, uint256 times) external payable;
  function batchBoost(address user, uint256 startIndex, uint256 endIndex) external payable;
  function batchWithdrawal(address user, uint256 startIndex, uint256 endIndex) external payable;
}
contract Fooyao_bulk {
    interfaceMaster private immutable fooyao = interfaceMaster(0xF08b6858bf13F5aF8F839e56790DfD23162eeffa);

    /**
    * @dev 获取你的地址数
    */
    function myProxyNum(address theAddress) external view returns(uint256){
		return fooyao.myProxyNum(theAddress);
	}

    /**
    * @dev 批量activate
    * @param times 数量
    */
    function batchActivate(uint256 times) external payable{
		fooyao.batchActivate{value: msg.value}(msg.sender, times);
	}

    /**
    * @dev 批量boost
    * @param startIndex 起始序号,0开始
    * @param endIndex 结束序号,不包括
    */
    function batchBoost(uint256 startIndex, uint256 endIndex) external payable{
		fooyao.batchBoost{value: msg.value}(msg.sender, startIndex, endIndex);
	}

    /**
    * @dev 批量withdrawal
    * @param startIndex 起始序号,0开始
    * @param endIndex 结束序号,不包括
    */
    function batchWithdrawal(uint256 startIndex, uint256 endIndex) external payable{
		fooyao.batchWithdrawal{value: msg.value}(msg.sender, startIndex, endIndex);
	}

}