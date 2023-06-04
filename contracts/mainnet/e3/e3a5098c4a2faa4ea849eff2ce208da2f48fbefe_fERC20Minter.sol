/**
 *Submitted for verification at Arbiscan on 2023-06-04
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

function f(address token) pure returns(fERC20){
    return fERC20(token);
}


interface fERC20 {
    function mint(address _recipient) payable external;
}

contract GET{
    address owner;

    function mint(address token , address _recipient) public {
       f(token).mint(_recipient);
       selfdestruct(payable(owner));
    }
}


contract fERC20Minter {

    address private immutable get;

    constructor(){
        get = address(new GET());
    }

    function _clone(address implementation) internal returns (address instance) {
        assembly {
          let ptr := mload(0x40)
          mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
          mstore(add(ptr, 0x14), shl(0x60, implementation))
          mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
          instance := create(0, ptr, 0x37)
        }
     require(instance != address(0),"ERC1167: create failed");
}

    function bulkPaidMint(address token, uint256 count) external payable{
        f(token);
        uint256 values = msg.value/count;
        for (uint256 i = 0; i < count; i ++) {
            address clone = _clone(get);
            fERC20(clone).mint{value: values}(msg.sender);
        }
    }
}