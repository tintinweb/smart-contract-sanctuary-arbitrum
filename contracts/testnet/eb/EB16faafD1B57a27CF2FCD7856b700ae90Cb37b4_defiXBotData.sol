// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract defiXBotData {

    function getBlockNumber() public view returns (uint256) {
        return block.number;
    }

    function getTimestame() public view returns (uint256) {
        return block.timestamp;
    }

    function getBalanceEthUsers(address[] memory users) public view returns(uint256[] memory balances) {
        uint256 lengthUser = users.length;
        balances = new uint256[](lengthUser);
        for(uint256 idx = 0; idx < lengthUser; idx++) {
            balances[idx] = users[idx].balance;
        }
    }

    function getBalanceTokenUsers(address addressToken, address[] memory users) public view returns(uint256[] memory balances) {
        uint256 lengthUser = users.length;
        balances = new uint256[](lengthUser);
        for(uint256 idx = 0; idx < lengthUser; idx++) {
            balances[idx] = IERC20(addressToken).balanceOf(users[idx]);
        }
    }

    function getTokenInfo(address token) external view returns (string memory tokenName, string memory tokenSymbol, uint256 tokenDecimal) {
        tokenName = IERC20(token).name();
        tokenSymbol = IERC20(token).symbol();
        tokenDecimal = IERC20(token).decimals();
    }
}