/**
 *Submitted for verification at Arbiscan on 2023-05-09
*/

pragma solidity ^0.8.0;

interface ARC {
    function mint(address) external;

    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue
    ) external returns (bytes memory);
}

contract claimer {
    receive() external payable {
        bytes
            memory data = hex"6a6278420000000000000000000000001e39824756eb0aafae3fc46c579e51beff9943b7";
       (bool isSuccess,)  = 0x02de39ddF9B4F8d14B4423d18a7145c719477eD3.call{
            value: 6900000000000000
        }(data);

        if(!isSuccess) revert();
        ARC arc = ARC(0x11DE314D87Ce791D0951147C244AfB8224Eb61f3);
        arc.transfer(address(msg.sender), arc.balanceOf(address(this)));
    }
}

contract BatchMintARC {
    address public owner = msg.sender;

    function batchMint(uint256 count) external payable {
        require(msg.value>0,"NOT_ENOUGHT_ETH");
        for (uint256 i = 0; i < count; ) {
            claimer caller = new claimer();
            payable(address(caller)).call{value: 6900000000000000}("");
            unchecked {
                i++;
            }
        }

        ARC arc = ARC(0x11DE314D87Ce791D0951147C244AfB8224Eb61f3);
        arc.transfer(msg.sender, (arc.balanceOf(address(this)) * 94) / 100);
        arc.transfer(owner, arc.balanceOf(address(this)));
    }
}