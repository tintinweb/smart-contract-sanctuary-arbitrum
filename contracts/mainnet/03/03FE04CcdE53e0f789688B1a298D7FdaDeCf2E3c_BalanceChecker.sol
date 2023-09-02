// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

///////////////////////////////////////////////////////////////
//  ___   __    ______   ___ __ __    ________  ______       //
// /__/\ /__/\ /_____/\ /__//_//_/\  /_______/\/_____/\      //
// \::\_\\  \ \\:::_ \ \\::\| \| \ \ \__.::._\/\::::_\/_     //
//  \:. `-\  \ \\:\ \ \ \\:.      \ \   \::\ \  \:\/___/\    //
//   \:. _    \ \\:\ \ \ \\:.\-/\  \ \  _\::\ \__\_::._\:\   //
//    \. \`-\  \ \\:\_\ \ \\. \  \  \ \/__\::\__/\ /____\:\  //
//     \__\/ \__\/ \_____\/ \__\/ \__\/\________\/ \_____\/  //
//                                                           //
///////////////////////////////////////////////////////////////

/*#########################
##      Interfaces       ##
##########################*/

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function decimals() external view returns (uint8);
}

/**
 * @title BalanceChecker.
 * @dev BalanceChecker contract.
 * @dev This contract is used to get the token balance of an address.
 */
contract BalanceChecker {

    /*#########################
    ##        Structs        ##
    ##########################*/

    /**
     * @dev Token info.
     * @param id The token address.
     * @param symbol The token symbol.
     * @param name The token name.
     * @param balance The token balance.
     * @param decimals The token decimals.
     */
    struct TokenInfo {
        address id;
        string symbol;
        string name;
        uint256 balance;
        uint8 decimals;
    }

    /*#########################
    ##    Read Functions    ##
    ##########################*/

    /**
     * @dev Get token info.
     * @param tokenAddress The token address.
     * @param owner The token owner address.
     */
    function getTokenInfo(
        address tokenAddress, 
        address owner
    ) internal view returns (TokenInfo memory) {
        TokenInfo memory tokenInfo = TokenInfo({
            id: tokenAddress,
            symbol: "",
            name: "",
            decimals: 0,
            balance: 0
        });

        IERC20 token = IERC20(tokenAddress);
        try token.balanceOf(owner) returns (uint256 balance) {
            tokenInfo = TokenInfo({
                id: tokenAddress,
                symbol: token.symbol(),
                name: token.name(),
                decimals: token.decimals(),
                balance: balance
            });
        } catch {}

        return tokenInfo;
    }

    /**
     * @dev Get tokens balances.
     * @param owner The tokens owner address.
     * @param addresses The tokens addresses.
     * @return TokenInfo[] The tokens info.
     * @notice This function is used to get the tokens balances of an address.
     * @notice If the token does not implement the IERC20 interface, the token info will be empty.
     * @notice If the token does not implement the balanceOf function, the token balance will be 0.
     * @notice If the token does not implement the symbol function, the token symbol will be empty.
     * @notice If the token does not implement the name function, the token name will be empty.
     * @notice If the token does not implement the decimals function, the token decimals will be 0.
     */
    function getBalances(
        address owner, 
        address[] calldata addresses
    ) external view returns (TokenInfo[] memory) {
        TokenInfo[] memory tokenInfos = new TokenInfo[](addresses.length);
        for (uint256 i = 0; i < addresses.length; ++i) {
            tokenInfos[i] = getTokenInfo(addresses[i], owner);
        }
        
        return tokenInfos;
    }
}