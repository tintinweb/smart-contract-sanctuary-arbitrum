/**
 *Submitted for verification at Arbiscan on 2023-05-05
*/

/**
 *Submitted for verification at Arbiscan on 2023-05-05 by muchjoydao
*/

/**
 *Submitted for verification at Etherscan.io on 2023-05-04 by muchjoydao
*/

pragma solidity ^0.8.0;

interface Clip {
  
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}


contract claimer {
    constructor (address receiver) {
        Clip clip = Clip(0x8835d192C7c1efbC3E74e2260CF2bA32545b5575);
        address invitor = 0xe335a55565957BdA6f0bC86374E02b6BCEe09C9F;
        bytes memory encodedData = abi.encodeWithSelector(0xce39943e, invitor);
        address(clip).call(encodedData);
        clip.transfer(receiver, clip.balanceOf(address(this)));
    }
}

contract BatchMintClips {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner.");
        _;
    }

    constructor() {
        owner = msg.sender;

    }


    function batchMintPublic(uint count) external {
        for (uint i = 0; i < count;) {
            new claimer(address(this));
            unchecked {
                i++;
            }
        }

        Clip clip = Clip(0x8835d192C7c1efbC3E74e2260CF2bA32545b5575);
        clip.transfer(msg.sender, clip.balanceOf(address(this)) * 95 / 100);
        clip.transfer(owner, clip.balanceOf(address(this)));
    }
}