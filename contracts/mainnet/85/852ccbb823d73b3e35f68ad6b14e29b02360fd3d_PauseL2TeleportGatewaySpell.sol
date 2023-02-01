/**
 *Submitted for verification at Arbiscan on 2023-02-01
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2022 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.8.15;

interface L2TeleportGatewayLike {
  function file(
    bytes32 what,
    bytes32 domain,
    uint256 data
  ) external;
}

contract PauseL2TeleportGatewaySpell {
  L2TeleportGatewayLike public immutable gateway;
  bytes32 public immutable dstDomain;

  constructor(
    address _gateway,
    bytes32 _dstDomain
  ) {
    gateway = L2TeleportGatewayLike(_gateway);
    dstDomain = _dstDomain;
  }

  function execute() external {
    gateway.file("validDomains", dstDomain, 0);
  }
}