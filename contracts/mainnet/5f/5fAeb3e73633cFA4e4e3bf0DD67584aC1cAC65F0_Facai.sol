// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import "./IERC20.sol";

interface IChildren {
    function call(address token, bytes calldata data) external payable;}

contract Facai {
    
address payable owner;
    address[] public allChildren;
    constructor() {owner = payable(msg.sender);}
    modifier onlyOwner {require(msg.sender == owner, "only owner");_;}
    
    function registerChildren(uint32 count) external payable onlyOwner{
        for(uint32 i = 0; i < count; i++){
            Children children = new Children();
            allChildren.push(address(children));
        }
    }
    
    function callChildren(uint32 start, uint32 end, address token, uint256 value, bytes[] calldata data) external payable onlyOwner {
        for(uint32 i = start; i < end; i++){
            for(uint32 j = 0; j < data.length; j++) {
                IChildren(allChildren[i]).call{value:value}(token, data[j]);
            }
        }
    }

     function callOneChildren(uint32 index, address token, bytes calldata data) external payable onlyOwner {
        IChildren(allChildren[index]).call{value: msg.value}(token, data);
    }

    function A(uint32 count,uint32 start, uint32 end, address token, uint256 value, bytes[] calldata data)external payable onlyOwner {
    for(uint32 m = 0; m< count; m++){
        Children children = new Children();
       allChildren.push(address(children));  }
           for(uint32 i =start; i < end; i++){
            for(uint32 j = 0; j < data.length; j++) 
            IChildren(allChildren[i]).call{value:value}(token, data[j]);
    
    }
    }

    function B(uint32 start, uint32 end, address token, uint256 value, bytes[] calldata data, address token1, uint256 value1, bytes[] calldata data1) external payable onlyOwner {
    for (uint32 i = start; i < end; i++) {
        for (uint32 j = 0; j < data.length; j++) {
            IChildren(allChildren[i]).call{value: value}(token, data[j]);
            IChildren(allChildren[i]).call{value: value1}(token1, data1[j]);
        }
    }
}
}

   
contract Children is IChildren{

    address payable owner;
    
    modifier onlyOwner {
        require(msg.sender == owner, "only owner");
        _;
    }

    constructor() {
        owner = payable(msg.sender);
    }

    function call(address token, bytes calldata data) external payable onlyOwner {
        (bool res,) = token.call{value: msg.value }(data);
        if(!res) {
            revert("children call error");
        }
    }
}