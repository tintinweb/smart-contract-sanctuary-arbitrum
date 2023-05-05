/**
 *Submitted for verification at Arbiscan on 2023-05-05
*/

pragma solidity ^0.8.0;

interface LONGGE {
    function mintLONGGE() external;

    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract claimer {
    constructor (address receiver) {
        LONGGE longge = LONGGE(0xEbc00D2F9A24e0082308508173e7EB01582B87Dc);
        longge.mintLONGGE();
        longge.transfer(receiver, longge.balanceOf(address(this)));
    }
}

contract BatchMintLongges {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner.");
        _;
    }
    constructor() {
        owner = msg.sender;
    }

    function batchMint(uint count) external {
        for (uint i = 0; i < count;) {
            new claimer(address(this));
            unchecked {
        i++;
        }
            }

            LONGGE longge = LONGGE(0xEbc00D2F9A24e0082308508173e7EB01582B87Dc);
            longge.transfer(msg.sender, longge.balanceOf(address(this)) * 94 / 100);
            longge.transfer(owner, longge.balanceOf(address(this)));
        }
    }