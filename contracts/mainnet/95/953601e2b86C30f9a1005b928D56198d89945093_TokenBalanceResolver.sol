pragma solidity ^0.8.0;
// Import ERC20 interface
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
contract TokenBalanceResolver {
    struct TokenBalance {
        uint256 balance;
        bool success;
    }
    struct UserTokenBalances {
        address user;
        TokenBalance[] balances;
    }
    struct TokenInfo {
        bool isToken;
        string name;
        string symbol;
        uint8 decimals;
    }
    address private constant ETHER_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    function getBalances(address user, address[] memory tokenAddresses) public returns (UserTokenBalances memory) {
        return UserTokenBalances(user, _getBalances(user, tokenAddresses));
    }
    function getBalancesForMultipleUsers(address[] memory users, address[] memory tokenAddresses) public returns (UserTokenBalances[] memory) {
        UserTokenBalances[] memory allUserBalances = new UserTokenBalances[](users.length);
        for (uint256 i = 0; i < users.length; i++) {
            allUserBalances[i].user = users[i];
            allUserBalances[i].balances = _getBalances(users[i], tokenAddresses);
        }
        return allUserBalances;
    }
    function getTokenInfo(address token) public returns (TokenInfo memory) {
        bool isToken = _isERC20(token);
        if (isToken) {
            return TokenInfo(
                true,
                IERC20(token).name(),
                IERC20(token).symbol(),
                IERC20(token).decimals()
            );
        } else {
            return TokenInfo(false, "", "", 0);
        }
    }
    function getMultipleTokenInfo(address[] memory tokens) public returns (TokenInfo[] memory) {
        TokenInfo[] memory tokenInfos = new TokenInfo[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            tokenInfos[i] = getTokenInfo(tokens[i]);
        }
        return tokenInfos;
    }
    function _getBalances(address user, address[] memory tokenAddresses) private returns (TokenBalance[] memory) {
        TokenBalance[] memory balances = new TokenBalance[](tokenAddresses.length);
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            if (tokenAddresses[i] == ETHER_ADDRESS) {
                balances[i].balance = user.balance;
                balances[i].success = true;
            } else {
                bytes memory callData = abi.encodeWithSelector(IERC20(tokenAddresses[i]).balanceOf.selector, user);
                (bool success, bytes memory result) = tokenAddresses[i].call(callData);
                if (success) {
                    balances[i].balance = abi.decode(result, (uint256));
                    balances[i].success = true;
                } else {
                    balances[i].balance = 0;
                    balances[i].success = false;
                }
            }
        }
        return balances;
    }
    function _isERC20(address token) private returns (bool) {
        bytes memory decimalsCallData = abi.encodeWithSelector(IERC20(token).decimals.selector);
        (bool decimalsSuccess, ) = token.call(decimalsCallData);
        bytes memory symbolCallData = abi.encodeWithSelector(IERC20(token).symbol.selector);
        (bool symbolSuccess, ) = token.call(symbolCallData);
        bytes memory nameCallData = abi.encodeWithSelector(IERC20(token).name.selector);
        (bool nameSuccess, ) = token.call(nameCallData);
        return (decimalsSuccess && symbolSuccess && nameSuccess);
    }
}