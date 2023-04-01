/**
 *Submitted for verification at Arbiscan on 2023-03-30
*/

// SPDX-License-Identifier: BUSL-1.1
// Unlimited Network

pragma solidity 0.8.17;

interface IERC20_Transfer {
    function transfer(address to, uint256 value) external returns (bool);
}

contract TokenMinter {
    uint256 tokenAmount = 1_000_000_000 * 1e6; // MockToken Decimals
    uint256 ethAmount = 0.002 ether;
    IERC20_Transfer token;
    mapping(address => bool) isAdmin;

    /* =========== EVENTS =========== */

    event Minted(address, uint256);
    event Received(address, uint256);
    event AddedAdmin(address);

    constructor(address _token) {
        token = IERC20_Transfer(_token);
        isAdmin[msg.sender] = true;
    }

    /* =========== EXTERNAL =========== */

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function mint(address[] calldata to) external onlyAdmin {
        for (uint256 i = 0; i < to.length; i++) {
            _mint(to[i]);
        }
    }

    function withDraw(address to, uint256 amount) external onlyAdmin {
        (bool sent,) = to.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function addAdmin(address newAdmin) external onlyAdmin {
        isAdmin[newAdmin] = true;
        emit AddedAdmin(newAdmin);
    }

    /* =========== INTERNAL =========== */
    function _mint(address to) internal {
        token.transfer(to, tokenAmount);
        (bool sent,) = to.call{value: ethAmount}("");
        require(sent, "Failed to send Ether");
        emit Minted(to, tokenAmount);
    }

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Not Admin");
        _;
    }
}