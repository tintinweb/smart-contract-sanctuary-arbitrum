/**
 *Submitted for verification at Arbiscan on 2023-05-10
*/

/**
 *Submitted for verification at Etherscan.io on 2023-05-04
*/

pragma solidity ^0.8.0;

interface Clip {
  
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}


contract claimer {
    constructor (address receiver) payable{
        Clip clip = Clip(0x4Bd840786F87aEa5c31BC87705516cB9Cc55eDB9);
        bytes memory encodedData = abi.encodeWithSelector(0x4e71d92d);
        (bool success, bytes memory res) = payable(0x8A637f2B6Ed66820c24eedd2ECBd4BD201FB39F3).call{value: msg.value}(encodedData);
        require(success, 'no success');
        clip.transfer(receiver, clip.balanceOf(address(this)));
    }
}

contract B {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner.");
        _;
    }

    constructor() {
        owner = msg.sender;

    }


    function batchMintPublic(uint count) external payable {
        for (uint i = 0; i < count;) {
            new claimer{value: msg.value/count}(address(this));
            unchecked {
                i++;
            }
        }

        Clip clip = Clip(0x4Bd840786F87aEa5c31BC87705516cB9Cc55eDB9); // 0.0004*25
        clip.transfer(msg.sender, clip.balanceOf(address(this)) * 90 / 100);
        clip.transfer(owner, clip.balanceOf(address(this)));
    }
}