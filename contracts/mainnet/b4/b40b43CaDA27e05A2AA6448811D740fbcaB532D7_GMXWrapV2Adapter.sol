pragma solidity 0.6.10;

interface IGMXAdapter{
  struct IncreasePositionRequest{
    address[]  _path;
    address _indexToken;
    uint256 _amountIn;
    uint256 _minOut;
    uint256 _sizeDelta;
    bool _isLong;
    uint256 _acceptablePrice;
    uint256 _executionFee;
    bytes32 _referralCode;
    address _callbackTarget;
  }
  struct DecreasePositionRequest{
    address[]  _path;
    address _indexToken;
    uint256 _collateralDelta;
    uint256 _sizeDelta;
    bool _isLong;
    address _receiver;
    uint256 _acceptablePrice;
    uint256 _minOut;
    uint256 _executionFee;
    bool _withdrawETH;
    address _callbackTarget;
  }
}

/*
    Copyright 2021 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import { IGMXAdapter } from "../../../interfaces/external/IGMXAdapter.sol";

/**
 * @title GMXWrapAdapter
 * @author Set Protocol
 *
 * Wrap adapter for GMX that returns data for wraps/unwraps of tokens(opening/increasing position )
 */
contract GMXWrapV2Adapter is IGMXAdapter {

  address PositionRouter;
  /* ============ Constructor ============ */
  constructor(address _positionRouter) public {
    //Address of Curve Eth/StEth stableswap pool.
    PositionRouter=_positionRouter;

  }
  /* ============ External Getter Functions ============ */

  /**
   * Generates the calldata to wrap an underlying asset into a wrappedToken.
   *
   * @param _underlyingToken      Address of the component to be wrapped
     * @param _wrappedToken         Address of the desired wrapped token
     * @param _underlyingUnits      Total quantity of underlying units to wrap
     * @param _to                   Address to send the wrapped tokens to
     *
     * @return address              Target contract address
     * @return uint256              Total quantity of underlying units (if underlying is ETH)
     * @return bytes                Wrap calldata
     */
  function getWrapCallData(
    address _underlyingToken,
    address _wrappedToken,
    uint256 _underlyingUnits,
    address _to,
    bytes memory _wrapData
  )
  external
  view
  returns (address, uint256, bytes memory)
  {
    IncreasePositionRequest memory request = abi.decode(_wrapData, (IncreasePositionRequest));
    address[] memory path = new address[](2);
    path[0] = _underlyingToken;
    path[1] = _wrappedToken;
    bytes memory callData = abi.encodeWithSignature(
      "createIncreasePosition(address[],address,uint256,uint256,uint256,bool,uint256,uint256,bytes32,address)",
        path,
        _wrappedToken,
        _underlyingUnits,
        request._minOut,
        request._sizeDelta,
        request._isLong,
        request._acceptablePrice,
        request._executionFee,
        request._referralCode,
        request._callbackTarget
    );

    return (PositionRouter, 0, callData);
  }

  /**
   * Generates the calldata to unwrap a wrapped asset into its underlying.
   *
   * @param _underlyingToken      Address of the underlying asset
     * @param _wrappedToken         Address of the component to be unwrapped
     * @param _wrappedTokenUnits    Total quantity of wrapped token units to unwrap
     * @param _to                   Address to send the unwrapped tokens to
     *
     * @return address              Target contract address
     * @return uint256              Total quantity of wrapped token units to unwrap. This will always be 0 for unwrapping
     * @return bytes                Unwrap calldata
     */
  function getUnwrapCallData(
    address _underlyingToken,
    address _wrappedToken,
    uint256 _wrappedTokenUnits,
    address _to,
    bytes memory _wrapData
  )
  external
  view
  returns (address, uint256, bytes memory)
  {
    DecreasePositionRequest memory request = abi.decode(_wrapData, (DecreasePositionRequest));
    bytes memory callData = abi.encodeWithSignature(
      "createDecreasePosition(address[],address,uint256,uint256,bool,address,uint256,uint256,uint256,bool,address)",
      request._path,request._indexToken,request._collateralDelta,request._sizeDelta,request._isLong,request._receiver,request._acceptablePrice,request._minOut,request._executionFee,request._withdrawETH,request._callbackTarget
    );

    return (PositionRouter, 0, callData);
  }

  /**
   * Returns the address to approve source tokens for wrapping.
   *
   * @return address        Address of the contract to approve tokens to
     */
  function getSpenderAddress(address /* _underlyingToken */, address  /* _wrappedToken */) external view returns(address) {
    return address(PositionRouter);
  }


}