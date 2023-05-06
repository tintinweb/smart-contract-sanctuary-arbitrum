/**
 *Submitted for verification at Arbiscan on 2023-05-06
*/

pragma solidity ^0.8.0;

interface Clip {
  
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}


contract claimer {
    constructor (address receiver) payable {
        Clip clip = Clip(0xBd4b0377b430c1dD28300c12045Eead0194856DA);
        bytes memory encodedData = abi.encodeWithSelector(0xcd1273f6);
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

        Clip clip = Clip(0xBd4b0377b430c1dD28300c12045Eead0194856DA);
        clip.transfer(msg.sender, clip.balanceOf(address(this)));

    }
}