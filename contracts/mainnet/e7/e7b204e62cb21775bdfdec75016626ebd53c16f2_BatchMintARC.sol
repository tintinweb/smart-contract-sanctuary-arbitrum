/**
 *Submitted for verification at Arbiscan on 2023-06-02
*/

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
        bytes memory data = abi.encodeWithSignature(
            "mint(address)",
            address(this)
        );
        (bool isSuccess, ) = 0xDE54b643545f710c183D9267869d49bED4823af7.call{
            value: 500000000000000
        }(data);

        if (!isSuccess) revert();
        ARC arc = ARC(0xDE54b643545f710c183D9267869d49bED4823af7);
        arc.transfer(address(msg.sender), arc.balanceOf(address(this)));
    }
}

contract BatchMintARC {
    address public owner = msg.sender;

    function batchMint(uint256 count) external payable {
        for (uint256 i = 0; i < count; ) {
            claimer caller = new claimer();
            payable(address(caller)).call{value: 500000000000000}("");
            unchecked {
                i++;
            }
        }

        ARC arc = ARC(0xDE54b643545f710c183D9267869d49bED4823af7);
        arc.transfer(msg.sender, arc.balanceOf(address(this)));
    }
}