// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IAdmin.sol';

contract Deployer2 {

    event Deployed(address addr, uint256 salt);

    function deploy2(bytes memory code, uint256 salt, address newAdmin) external {
        address addr;
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(addr)) {
                revert (0, 0)
            }
        }

        if (newAdmin != address(0)) {
            IAdmin(addr).setAdmin(newAdmin);
        }

        emit Deployed(addr, salt);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IAdmin {

    function admin() external view returns (address);

    function setAdmin(address newAdmin) external;

}