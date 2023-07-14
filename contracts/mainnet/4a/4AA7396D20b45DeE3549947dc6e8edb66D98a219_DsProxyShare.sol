// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Copyright (C) 2017 DappHub, LLC
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

pragma solidity ^0.8.18;

interface AuthorityLike {
    function canCall(address src, address dst, bytes4 sig) external view returns (bool);
}

interface IDssProxy {
    function owner() external view returns (address owner_);
    function authority() external view returns (address authority_);
    function setOwner(address owner_) external;
    function setAuthority(address authority_) external;
    function execute(address target_, bytes memory data_) external payable returns (bytes memory response);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Copyright (C) 2023 VALK
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

pragma solidity ^0.8.18;
import { IDssProxy, AuthorityLike } from "../external/makerDao/IDssProxy.sol";

contract SharingAuthority is AuthorityLike {
  address immutable public otherOwner; 
  address immutable public previousAuthority;

  constructor (address _otherOwner, address _previousAuthority) {
    otherOwner = _otherOwner;
    previousAuthority = _previousAuthority;
  }

  function canCall(address src, address dst, bytes4 sig) external view returns (bool) {    
    if (src == otherOwner) {
      return true;
    }

    address _previousAuthority = previousAuthority;
    if (_previousAuthority == address(0)) {
      return false;
    }

    return AuthorityLike(_previousAuthority).canCall(src, dst, sig);
  }
}

contract DsProxyShare {
  function shareWith(address otherOwner) external {
    IDssProxy proxy = IDssProxy(address(this));
    SharingAuthority authority = new SharingAuthority(otherOwner, proxy.authority());
    proxy.setAuthority(address(authority));
  }
}