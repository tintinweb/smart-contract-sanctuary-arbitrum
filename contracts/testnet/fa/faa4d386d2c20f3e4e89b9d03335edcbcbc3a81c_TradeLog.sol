/**
 *Submitted for verification at Arbiscan on 2022-04-28
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/// Event for trading logs drill
contract TradeLog {
    event LogTrade(
        address indexed account,
        bytes32 indexed symbol,
        bytes1 indexed trader,
        address account_addr,
        string symbol_string,
        bytes1 trader_byte,
        uint256 amount,
        //uint256 fillPrice,
        //bytes32 funding,
        bytes32 fee,
        bytes32 isBuyisMaker,
        bool isBuy
    );
    
    /// @notice Emit log to see the format on etherscan
    /// @dev  Check input debug method and output event format.Especially without code verify
    function emitLog(
        address account,
        bytes32 symbol,
        uint256 amount
    )
        external
    {
        string memory symbol_string = string(abi.encodePacked(symbol));
        bytes1 trader = symbol[31];
        bytes32 fee = bytes32(amount);
        bytes32 isBuyisMaker = bytes32(abi.encodePacked(true,false));
        bool isBuy = true;

        emit LogTrade(
            account,
            symbol,
            trader,
            account,
            symbol_string,
            trader,
            amount,
            fee,
            isBuyisMaker,
            isBuy
        );
    }
}