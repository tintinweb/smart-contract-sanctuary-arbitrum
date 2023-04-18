/**
 *Submitted for verification at Arbiscan on 2023-04-18
*/

pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract Locker {
    address private immutable owner = msg.sender;

    modifier onlyOwner {
        checkOwner();
        _;
    }

    function withdraw(IERC20 token, uint256 amount) external onlyOwner {
        token.transfer(owner, amount);
    }

    function withdrawNFT(IERC721 token, uint256 tokenId) external onlyOwner {
        token.transferFrom(address(this), owner, tokenId);
    }

    function call(address target, bytes calldata data) external onlyOwner {
        target.call(data);
    }

    function checkOwner() internal view {
        require(msg.sender == owner);
    }
}