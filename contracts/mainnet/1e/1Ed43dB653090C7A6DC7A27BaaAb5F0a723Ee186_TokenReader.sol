/**
 *Submitted for verification at Arbiscan on 2023-05-21
*/

pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;


// SPDX-License-Identifier: MIT
interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function allowance(
        address _owner,
        address _spender
    ) external view returns (uint256);

    function approve(address _spender, uint256 _value) external returns (bool);

    function transfer(address _to, uint256 _value) external returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool);

    function permit(
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;
}

contract TokenReader {
    function getTokenSupplies(
        address[] memory _tokens
    ) external view returns (uint256[] memory) {
        uint256 length = _tokens.length;
        uint256[] memory supplies = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            require(_tokens[i] != address(0), "TokenReader: ZERO_ADDRESS");
            supplies[i] = IERC20(_tokens[i]).totalSupply();
        }
        return supplies;
    }

    function getTokenDecimals(
        address[] memory _tokens
    ) external view returns (uint256[] memory) {
        uint256 length = _tokens.length;
        uint256[] memory decimals = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            require(_tokens[i] != address(0), "TokenReader: ZERO_ADDRESS");
            decimals[i] = IERC20(_tokens[i]).decimals();
        }
        return decimals;
    }

    function getTokensBalance(
        address _user,
        address[] memory _tokens
    ) external view returns (uint256[] memory) {
        uint256 length = _tokens.length;
        uint256[] memory balances = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            require(_tokens[i] != address(0), "TokenReader: ZERO_ADDRESS");
            balances[i] = IERC20(_tokens[i]).balanceOf(_user);
        }
        return balances;
    }

    function getTokenBalances(
        address[] memory _users,
        address _token
    ) external view returns (uint256[] memory) {
        require(_token != address(0), "TokenReader: ZERO_ADDRESS");
        uint256 length = _users.length;
        uint256[] memory balances = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            balances[i] = IERC20(_token).balanceOf(_users[i]);
        }
        return balances;
    }
}