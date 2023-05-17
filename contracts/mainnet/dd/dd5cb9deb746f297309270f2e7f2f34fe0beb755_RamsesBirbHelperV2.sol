/**
 *Submitted for verification at Arbiscan on 2023-05-17
*/

// SPDX-License-Identifier: MIT
/*********************************************************************/
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

    function transfer(address _to, uint256 _amount) external;

    function balanceOf(address _wallet) external view returns (uint256);
}

interface IBribe {
    function bribe(address _token, uint256 _amount) external;
}

contract RamsesBirbHelperV2 {
    address public ramsesMultisig;
    address public ramTokenAddress;
    IERC20 private ramToken;

    constructor(address _ramsesMultisig, address _ramAddress) {
        ramsesMultisig = _ramsesMultisig;
        ramToken = IERC20(_ramAddress);
        ramTokenAddress = _ramAddress;
    }

    function setBribeCap(uint256 _amount) internal {
        ramToken.transferFrom(ramsesMultisig, address(this), _amount);
    }

    ///@dev Bribe RAM tokens to the array of addresses based on the corresponding array of amounts
    function bribeBulkRAM(
        address[] calldata _bribeContracts,
        uint256[] calldata _amounts,
        uint256 _safeCap // this is in human readable numbers
    ) external {
        require(msg.sender == ramsesMultisig, "Only The Ramses Multisig can perform this task");
        require(_bribeContracts.length == _amounts.length, "length mismatch");
        setBribeCap(_safeCap * 1e18); //pulls this many tokens from multisig to ensure no over-bribing
        for (uint256 i = 0; i < _bribeContracts.length; ++i) {
            ramToken.approve(_bribeContracts[i], _amounts[i]);
            IBribe(_bribeContracts[i]).bribe(ramTokenAddress, _amounts[i]);
        }
        // Send the leftover tokens that didn't hit the bribe-cap
        ramToken.transfer(ramsesMultisig, ramToken.balanceOf(address(this)));
    }
}