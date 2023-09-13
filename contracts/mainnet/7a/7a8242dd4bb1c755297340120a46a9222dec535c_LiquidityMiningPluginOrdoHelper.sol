// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "../interfaces/IERC20.sol";

interface IFixedStrikeOptionTeller {
    function getOptionToken(
        address payoutToken,
        address quoteToken,
        uint48 eligible,
        uint48 expiry,
        address receiver,
        bool call,
        uint256 strikePrice
    ) external view returns (address);
}

contract LiquidityMiningPluginOrdoHelper {
    IFixedStrikeOptionTeller public teller;

    constructor(address _teller) {
        teller = IFixedStrikeOptionTeller(_teller);
    }

    function read(address owner, uint256 start, uint256 size) external view returns (address[] memory tokens, uint256[] memory strikes, uint256[] memory balances) {
        tokens = new address[](size);
        strikes = new uint256[](size);
        balances = new uint256[](size);
        for (uint256 i = 0; i < size; i++) {
            uint256 strike = start + (i * 0.01e6);
            tokens[i] = token(strike);
            strikes[i] = strike;
            if (tokens[i] != address(0)) {
                balances[i] = IERC20(tokens[i]).balanceOf(owner);
            }
        }
    }

    function token(uint256 strike) internal view returns (address) {
        try teller.getOptionToken(
            0x033f193b3Fceb22a440e89A2867E8FEE181594D9,
            0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8,
            943920000,
            2521843200,
            0xaB7d6293CE715F12879B9fa7CBaBbFCE3BAc0A5a,
            true,
            strike
        ) returns (address t) {
            return t;
        } catch {
            return address(0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}