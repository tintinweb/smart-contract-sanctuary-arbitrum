/**
 *Submitted for verification at Arbiscan on 2023-02-14
*/

// SPDX-License-Identifier: BUSL-1.1
// Unlimited Network

pragma solidity 0.8.17;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
}

contract TokenMinter {
    uint256 tokenAmount = 1_000_000_000 * 1e6; // MockToken Decimals
    uint256 ethAmount = 0.002 ether;
    IERC20 token;
    mapping(address => bool) isAdmin;

    constructor(address _token) {
        token = IERC20(_token);
        isAdmin[msg.sender] = true;
    }

    function onboardToUnlimited(address[] calldata users) external onlyAdmin {
        for (uint256 i = 0; i < users.length; i++) {
            _mint(users[i]);
        }
    }

    function _mint(address to) internal {
        token.transfer(to, tokenAmount);
        (bool sent,) = to.call{value: ethAmount}("");
        require(sent, "Failed to send Ether");
    }

    function withDraw(address to, uint256 amount) external onlyAdmin {
        (bool sent,) = to.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function addAdmin(address newUnlimitedAdmin) external onlyAdmin {
        isAdmin[newUnlimitedAdmin] = true;
    }

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Not Admin");
        _;
    }
}