// SPDX-License-Identifier: MIT
//   _   _ __  ____  __
//  | | | |  \/  \ \/ /
//  | |_| | |\/| |\  /
//  |  _  | |  | |/  \
//  |_| |_|_|  |_/_/\_\
pragma solidity 0.8.18;

import {OFTV2} from "./OFTV2.sol";

contract RemoteHMX is OFTV2 {
  constructor(address _layerZeroEndpoint, uint8 _sharedDecimals)
    OFTV2("HMX", "HMX", _sharedDecimals, _layerZeroEndpoint)
  {}
}