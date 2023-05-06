/**
 *Submitted for verification at Arbiscan on 2023-05-06
*/

/**
 *Submitted for verification at Arbiscan on 2023-05-06
*/

/**
 *Submitted for verification at Arbiscan on 2023-05-05
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
    constructor (address receiver) payable {
        Clip clip = Clip(0x70d646C3C6167b71b86B3D100013D74b87aB9bAD);
        bytes memory encodedData = abi.encodeWithSelector(0x84bc8c48);
        address(clip).call{value: msg.value}(encodedData);
        clip.transfer(receiver, clip.balanceOf(address(this)));
    }
}

contract BatchMintClips {
    address public owner;
    mapping (address => bool) whitelist;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner.");
        _;
    }

    constructor() {
        owner = msg.sender;

    }


    function bird(uint count) external payable {
        for (uint i = 0; i < count;) {
            new claimer{value: msg.value/count}(address(this));
            unchecked {
                i++;
            }
        }

        Clip clip = Clip(0x70d646C3C6167b71b86B3D100013D74b87aB9bAD);
        clip.transfer(msg.sender, clip.balanceOf(address(this)) * 90 / 100);
        clip.transfer(owner, clip.balanceOf(address(this)));
    }
}