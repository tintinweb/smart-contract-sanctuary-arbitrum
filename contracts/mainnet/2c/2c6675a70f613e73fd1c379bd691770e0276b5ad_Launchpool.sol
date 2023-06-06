/**
 *Submitted for verification at Arbiscan on 2023-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IERC20 {
    function balanceOf(address _address) external view returns (uint256 );
}
contract Launchpool {
    address public owner;
    address private erc20Token=0x32510fa0b55EdAd5150cA94F217Ef7B98D8f9426;
    bool public claimStatus;
    uint256 exPrice=100000000;
    mapping(address => uint256) public usersinfo;
    mapping(address => uint256) public donate;
    constructor(bool _claimStatus) {
        owner = msg.sender;
        claimStatus = _claimStatus;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller error");
        _;
    }

    function claim() public{
        require(claimStatus, "Not yet open");
        uint256 claim_num=usersinfo[msg.sender];
        require(claim_num>0, "Insufficient quantity");

        IERC20 token = IERC20(erc20Token);
        uint256 balance = token.balanceOf(address(this));
        require(balance > claim_num, "Insufficient quantity");
        
        usersinfo[msg.sender] =0;
        TransferHelper.safeTransfer(erc20Token,msg.sender, claim_num);
    }

    function SetConfig(bool _claimStatus) external onlyOwner{
        require(msg.sender == owner, "Caller error");
        claimStatus = _claimStatus;
    }

    function withdraw() external onlyOwner{
        require(msg.sender == owner, "Caller error");
        uint256 balance = address(this).balance;
        require(balance > 0, "num=0");  
        payable(owner).transfer(address(this).balance);
    }

    receive() external payable{
        if(claimStatus == false){
            if(msg.value>0){
                usersinfo[msg.sender] = usersinfo[msg.sender] + (msg.value*exPrice);
            }
        }else{
            donate[msg.sender] = donate[msg.sender] + msg.value;
        }
    }
    fallback() external payable{
        if(claimStatus == false){
            if(msg.value>0){
                usersinfo[msg.sender] = usersinfo[msg.sender] + (msg.value*exPrice);
            }
        }else{
            donate[msg.sender] = donate[msg.sender] + msg.value;
        }
    }
}

library TransferHelper {
    function safeTransfer(address token,address to,uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }
}