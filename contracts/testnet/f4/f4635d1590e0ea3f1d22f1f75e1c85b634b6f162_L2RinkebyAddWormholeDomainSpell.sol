/**
 *Submitted for verification at arbiscan.io on 2022-03-04
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Dai Foundation
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

pragma solidity 0.8.9;

interface DaiLike {
  function rely(address usr) external;
}

interface WormholeBridgeLike {
  function file(
    bytes32 what,
    bytes32 domain,
    uint256 data
  ) external;
}

contract L2RinkebyAddWormholeDomainSpell {
  function execute() external {
    DaiLike dai = DaiLike(0x78e59654Bc33dBbFf9FfF83703743566B1a0eA15);
    WormholeBridgeLike wormholeBridge = WormholeBridgeLike(
      0xEbA80E9d7C6C2F575a642a43199e32F47Bbd1306
    );
    bytes32 masterDomain = "RINKEBY-MASTER-1";

    // wormhole bridge has to burn without approval
    dai.rely(address(wormholeBridge));

    wormholeBridge.file(bytes32("validDomains"), masterDomain, 1);
  }
}