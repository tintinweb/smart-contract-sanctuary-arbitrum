/**
 *Submitted for verification at Arbiscan on 2023-05-02
*/

/*
  CheemsToken airdrop
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

library TransferHelper {
    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
}

contract CheemsAirdrop {
    address public owner = msg.sender;
    address token = 0x484f5147f89f5a6347cD1048580f6d8a19cE6d79;

    mapping(address => bool) public isAirdropd;

    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    function withdraw(address _token, uint256 _amount) external onlyOwner {
        if (_token != address(0)) {
            TransferHelper.safeTransfer(_token, owner, _amount);
        } else {
            payable(owner).transfer(address(this).balance);
        }
    }

    function claim() public {
        require(isAirdropd[msg.sender] == false, "claimed");
        require(tx.origin == msg.sender, "invalid address");
        require(address(msg.sender).balance >= 0.1 ether, "invalid airdrop");
        
        isAirdropd[msg.sender] = true;
        TransferHelper.safeTransfer(token, msg.sender, 30000000000 ether);
    }
}