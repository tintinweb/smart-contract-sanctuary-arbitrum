/**
 *Submitted for verification at Arbiscan.io on 2024-04-12
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;











contract BytesTransientStorageL2 {
    bytes data;

    function setBytesTransiently(bytes calldata _data) public {
        data = _data;
    }

    function getBytesTransiently() public view returns (bytes memory){
        return data;
    }
}