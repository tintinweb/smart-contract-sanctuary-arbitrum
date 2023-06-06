// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 

import './interfaces/IETHHandleBridge.sol';

contract Test 
{
    IETHHandleBridge public ETHHandleBridge;

    function SetETHHandleBridge(IETHHandleBridge _addess) public 
    {
        ETHHandleBridge = _addess;
    }

    function GetETHHandleBridgeAddress() public view returns(address)
    {
        return address(ETHHandleBridge);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IETHHandleBridge {
    function withdraw(uint256 amount) external;
}