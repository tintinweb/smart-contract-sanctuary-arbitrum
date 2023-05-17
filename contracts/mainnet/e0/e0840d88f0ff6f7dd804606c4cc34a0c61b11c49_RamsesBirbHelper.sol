/**
 *Submitted for verification at Arbiscan on 2023-05-16
*/

// SPDX-License-Identifier: MIT
/*******************************************************************/
//Bribe Helper contract for RAMSES to alleviate bulk bribe matching
/*********************************************************************/
pragma solidity ^0.8.16;

interface IERC20 {
    function approve(address _spender, uint256 _amount) external;

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external;
}

interface IBribe {
    function bribe(address _token, uint256 _amount) external;
}

contract RamsesBirbHelper {
    address public ramsesMultisig;
    address public ramTokenAddress;
    IERC20 private ramToken;

    constructor(address _ramsesMultisig, address _ramAddress) {
        ramsesMultisig = _ramsesMultisig;
        ramToken = IERC20(_ramAddress);
        ramTokenAddress = _ramAddress;
    }

    ///@dev Bribe RAM tokens to the array of addresses based on the corresponding array of amounts
    function bribeBulkRAM(address[] calldata _bribeContracts, uint256[] calldata _amounts) external {
        require(msg.sender == ramsesMultisig, "Only The Ramses Multisig can perform this task");
        for (uint256 i = 0; i < _bribeContracts.length; ++i) {
            ramToken.approve(_bribeContracts[i], _amounts[i]);
            ramToken.transferFrom(ramsesMultisig, address(this), _amounts[i]);
            IBribe(_bribeContracts[i]).bribe(ramTokenAddress, _amounts[i]);
        }
    }
}