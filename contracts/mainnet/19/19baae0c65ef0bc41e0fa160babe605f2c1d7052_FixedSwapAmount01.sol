// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.17;

interface ISwapAmount {
  function getAmount (bytes memory params) external view returns (uint amount);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.17;


/**
 *    ,,                           ,,                                
 *   *MM                           db                      `7MM      
 *    MM                                                     MM      
 *    MM,dMMb.      `7Mb,od8     `7MM      `7MMpMMMb.        MM  ,MP'
 *    MM    `Mb       MM' "'       MM        MM    MM        MM ;Y   
 *    MM     M8       MM           MM        MM    MM        MM;Mm   
 *    MM.   ,M9       MM           MM        MM    MM        MM `Mb. 
 *    P^YbmdP'      .JMML.       .JMML.    .JMML  JMML.    .JMML. YA.
 *
 *    FixedSwapAmount01.sol :: 0x19baae0c65ef0bc41e0fa160babe605f2c1d7052
 *    etherscan.io verified 2023-12-01
 */ 
import "../Interfaces/ISwapAmount.sol";

contract FixedSwapAmount01 is ISwapAmount {
  function getAmount (bytes memory params) public view returns (uint amount) {
    amount = abi.decode(params, (uint));
  }
}