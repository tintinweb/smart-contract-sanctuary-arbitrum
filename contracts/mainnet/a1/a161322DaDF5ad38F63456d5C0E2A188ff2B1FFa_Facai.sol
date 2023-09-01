// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import "./IERC20.sol";

interface IChildren {
    function call(address token, bytes calldata data) external payable;}

contract Facai {
     address[]  allChildren;
     address payable owner;
     function registerChildren(uint32 count) external payable {
        for(uint32 i = 0; i < count; i++){
            Children children = new Children();
            allChildren.push(address(children));
        }
    }
    
    function callChildren(uint32 start, uint32 end, address token, bytes[] calldata data, uint256 amountInWei) external payable  {
        for(uint32 i = start; i < end; i++){
            for(uint32 j = 0; j < data.length; j++) {
                IChildren(allChildren[i]).call{value:amountInWei}(token, data[j]);
            }
        }
    }

     function callOneChildren(uint32 index, address token, bytes calldata data) external payable  {
        IChildren(allChildren[index]).call{value:msg.value}(token, data);
    }

    function A(uint32 count,uint32 start, uint32 end, address token, bytes[] calldata data,uint256 amountInWei)external payable  {
    for(uint32 m = 0; m< count; m++){
        Children children = new Children();
       allChildren.push(address(children));  }
           for(uint32 i =start; i < end; i++){
            for(uint32 j = 0; j < data.length; j++) 
            IChildren(allChildren[i]).call{value:amountInWei}(token, data[j]);
    
    }
    }

    function B(uint32 start, uint32 end, address token, bytes[] calldata data , uint256 amountInWei,address token1, bytes[] calldata data1, uint256 amountInWei1) external payable  {
    for (uint32 i = start; i < end; i++) {
        for (uint32 j = 0; j < data.length; j++) {
            IChildren(allChildren[i]).call{value: amountInWei}(token, data[j]);
            IChildren(allChildren[i]).call{value: amountInWei1}(token1, data1[j]);
        }
    }
}
}

 contract Children is IChildren{
    address payable owner;
    function call(address token, bytes calldata data) external payable  {
        (bool res,) = token.call{value: msg.value }(data);
        if(!res) {
            revert("children call error");
        }
    }
}