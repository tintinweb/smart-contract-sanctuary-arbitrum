// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.5.0;

interface IPriceCurve {
  function getOutput (
    uint totalInput,
    uint filledInput,
    uint input,
    bytes memory curveParams
  ) external pure returns (uint output);
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
 *    FlatPriceCurve.sol :: 0xc509733b8dddbab9369a96f6f216d6e59db3900f
 *    etherscan.io verified 2023-11-30
 */ 
import "./PriceCurveBase.sol";

contract FlatPriceCurve is PriceCurveBase {

  function calcOutput (uint input, bytes memory curveParams) public pure override returns (uint output) {
    uint basePriceX96 = abi.decode(curveParams, (uint));
    output = input * basePriceX96 / Q96;
  }

  // the only param for flat curve is uint basePriceX96, no calculations needed
  function calcCurveParams (bytes memory curvePriceData) public pure override returns (bytes memory curveParams) {
    curveParams = curvePriceData;
  }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.17;

import "../Interfaces/IPriceCurve.sol";

error MaxInputExceeded(uint remainingInput);

abstract contract PriceCurveBase is IPriceCurve {

  uint256 public constant Q96 = 0x1000000000000000000000000;

  function getOutput (
    uint totalInput,
    uint filledInput,
    uint input,
    bytes memory curveParams
  ) public pure returns (uint output) {
    requireInputRemaining(totalInput, filledInput, input);

    uint filledOutput = calcOutput(filledInput, curveParams);
    uint totalOutput = calcOutput(filledInput + input, curveParams);

    output = totalOutput - filledOutput;
  }
  
  function requireInputRemaining (uint totalInput, uint filledInput, uint input) internal pure {
    uint remainingInput = totalInput - filledInput;
    if (input > remainingInput) {
      revert MaxInputExceeded(remainingInput);
    }
  }

  function calcOutput (uint input, bytes memory curveParams) public pure virtual returns (uint output);
  function calcCurveParams (bytes memory curvePriceData) public pure virtual returns (bytes memory curveParams);

}