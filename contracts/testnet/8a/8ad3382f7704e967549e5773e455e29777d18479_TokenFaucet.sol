// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "multi-chain-tokens/interfaces/IERC6160Ext20.sol";

contract TokenFaucet {
    mapping(address => uint256) private consumers;
    address private token;

    constructor(address _token) {
        token = _token;
    }

    function drip() public {
        uint256 lastDrip = consumers[msg.sender];
        uint256 delay = block.timestamp - lastDrip;

        if (delay < 86400) {
            revert("Can only request tokens once daily");
        }

        consumers[msg.sender] = block.timestamp;
        IERC5679Ext20(token).mint(msg.sender, 100 * 10e18, "");
    }
}

pragma solidity ^0.8.17;

import {IERC_ACL_CORE} from "./IERCAclCore.sol";

// The EIP-165 identifier of this interface is 0xd0017968
interface IERC5679Ext20 {
    function mint(address _to, uint256 _amount, bytes calldata _data) external;
    function burn(address _from, uint256 _amount, bytes calldata _data) external;
}

/**
 * @dev Interface of the ERC6160 standard, as defined in
 * https://github.com/polytope-labs/EIPs/blob/master/EIPS/eip-6160.md.
 *
 * @author Polytope Labs
 *
 * The EIP-165 identifier of this interface is 0xbbb8b47e
 */
interface IERC6160Ext20 is IERC5679Ext20, IERC_ACL_CORE {}

pragma solidity ^0.8.17;

/**
 * @dev Interface of the EIP5982 standard, as defined in
 * https://github.com/polytope-labs/EIPs/blob/master/EIPS/eip-5982.md
 *
 * The EIP-165 identifier of this interface is 0x6bb9cd16
 */
interface IERC_ACL_CORE {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
}