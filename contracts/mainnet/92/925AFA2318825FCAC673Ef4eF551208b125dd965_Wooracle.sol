// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

/*

░██╗░░░░░░░██╗░█████╗░░█████╗░░░░░░░███████╗██╗
░██║░░██╗░░██║██╔══██╗██╔══██╗░░░░░░██╔════╝██║
░╚██╗████╗██╔╝██║░░██║██║░░██║█████╗█████╗░░██║
░░████╔═████║░██║░░██║██║░░██║╚════╝██╔══╝░░██║
░░╚██╔╝░╚██╔╝░╚█████╔╝╚█████╔╝░░░░░░██║░░░░░██║
░░░╚═╝░░░╚═╝░░░╚════╝░░╚════╝░░░░░░░╚═╝░░░░░╚═╝

*
* MIT License
* ===========
*
* Copyright (c) 2020 WooTrade
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

import './libraries/InitializableOwnable.sol';
import './interfaces/IWooracle.sol';

/// @title Wooracle implementation in Fantom and Avalanche chain and other layer2 chains.
/// @notice Will be maintained and updated periodically by Woo.network in multichains.
contract Wooracle is InitializableOwnable, IWooracle {
    /* ----- State variables ----- */

    struct TokenInfo {
        uint256 price; // 18 - base_decimal + quote_decimal
        uint256 coeff; // 36 - quote
        uint256 spread; // 18
    }

    mapping(address => TokenInfo) public infos;

    address public override quoteToken;
    uint256 public override timestamp;

    uint256 public staleDuration;

    constructor() public {
        initOwner(msg.sender);
        staleDuration = uint256(300);
    }

    /* ----- External Functions ----- */

    /// @dev Set the quote token address.
    /// @param newQuoteToken token address
    function setQuoteToken(address newQuoteToken) external onlyOwner {
        quoteToken = newQuoteToken;
    }

    /// @dev Set the staleDuration.
    /// @param newStaleDuration the new stale duration
    function setStaleDuration(uint256 newStaleDuration) external onlyOwner {
        staleDuration = newStaleDuration;
    }

    /// @dev Update the base token prices.
    /// @param base the baseToken address
    /// @param newPrice the new prices for the base token
    function postPrice(address base, uint256 newPrice) external onlyOwner {
        infos[base].price = newPrice;
        timestamp = block.timestamp;
    }

    /// @dev batch update baseTokens prices
    /// @param bases list of baseToken address
    /// @param newPrices the updated prices list
    function postPriceList(address[] calldata bases, uint256[] calldata newPrices) external onlyOwner {
        uint256 length = bases.length;
        require(length == newPrices.length, 'Wooracle: length_INVALID');

        for (uint256 i = 0; i < length; i++) {
            infos[bases[i]].price = newPrices[i];
        }

        timestamp = block.timestamp;
    }

    /// @dev update the spreads info.
    /// @param base baseToken address
    /// @param newSpread the new spreads
    function postSpread(address base, uint256 newSpread) external onlyOwner {
        infos[base].spread = newSpread;
        timestamp = block.timestamp;
    }

    /// @dev batch update the spreads info.
    /// @param bases list of baseToken address
    /// @param newSpreads list of spreads info
    function postSpreadList(address[] calldata bases, uint256[] calldata newSpreads) external onlyOwner {
        uint256 length = bases.length;
        require(length == newSpreads.length, 'Wooracle: length_INVALID');

        for (uint256 i = 0; i < length; i++) {
            infos[bases[i]].spread = newSpreads[i];
        }

        timestamp = block.timestamp;
    }

    /// @dev update the state of the given base token.
    /// @param base baseToken address
    /// @param newPrice the new prices
    /// @param newSpread the new spreads
    /// @param newCoeff the new slippage coefficent
    function postState(
        address base,
        uint256 newPrice,
        uint256 newSpread,
        uint256 newCoeff
    ) external onlyOwner {
        _setState(base, newPrice, newSpread, newCoeff);
        timestamp = block.timestamp;
    }

    /// @dev batch update the prices, spreads and slipagge coeffs info.
    /// @param bases list of baseToken address
    /// @param newPrices the prices list
    /// @param newSpreads the spreads list
    /// @param newCoeffs the slippage coefficent list
    function postStateList(
        address[] calldata bases,
        uint256[] calldata newPrices,
        uint256[] calldata newSpreads,
        uint256[] calldata newCoeffs
    ) external onlyOwner {
        uint256 length = bases.length;
        require(
            length == newPrices.length && length == newSpreads.length && length == newCoeffs.length,
            'Wooracle: length_INVALID'
        );

        for (uint256 i = 0; i < length; i++) {
            _setState(bases[i], newPrices[i], newSpreads[i], newCoeffs[i]);
        }
        timestamp = block.timestamp;
    }

    /// @inheritdoc IWooracle
    function price(address base) external view override returns (uint256 priceNow, bool feasible) {
        priceNow = infos[base].price;
        feasible = priceNow != 0 && block.timestamp <= (timestamp + staleDuration * 1 seconds);
    }

    function getPrice(address base) external view override returns (uint256) {
        return infos[base].price;
    }

    function getSpread(address base) external view override returns (uint256) {
        return infos[base].spread;
    }

    function getCoeff(address base) external view override returns (uint256) {
        return infos[base].coeff;
    }

    /// @inheritdoc IWooracle
    function state(address base)
        external
        view
        override
        returns (
            uint256 priceNow,
            uint256 spreadNow,
            uint256 coeffNow,
            bool feasible
        )
    {
        TokenInfo storage info = infos[base];
        priceNow = info.price;
        spreadNow = info.spread;
        coeffNow = info.coeff;
        feasible = priceNow != 0 && block.timestamp <= (timestamp + staleDuration * 1 seconds);
    }

    function isFeasible(address base) public view override returns (bool) {
        return infos[base].price != 0 && block.timestamp <= (timestamp + staleDuration * 1 seconds);
    }

    /* ----- Private Functions ----- */

    function _setState(
        address base,
        uint256 newPrice,
        uint256 newSpread,
        uint256 newCoeff
    ) private {
        TokenInfo storage info = infos[base];
        info.price = newPrice;
        info.spread = newSpread;
        info.coeff = newCoeff;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

/**
 * @title Ownable initializable contract.
 *
 * @notice Ownership related functions
 */
contract InitializableOwnable {
    address public _OWNER_;
    address public _NEW_OWNER_;
    bool internal _INITIALIZED_;

    // ============ Events ============

    event OwnershipTransferPrepared(address indexed previousOwner, address indexed newOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // ============ Modifiers ============

    modifier notInitialized() {
        require(!_INITIALIZED_, 'InitializableOwnable: SHOULD_NOT_BE_INITIALIZED');
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _OWNER_, 'InitializableOwnable: NOT_OWNER');
        _;
    }

    // ============ Functions ============

    /// @dev Init _OWNER_ from newOwner and set _INITIALIZED_ as true
    /// @param newOwner new owner address
    function initOwner(address newOwner) public notInitialized {
        _INITIALIZED_ = true;
        _OWNER_ = newOwner;
    }

    /// @dev Set _NEW_OWNER_ from newOwner
    /// @param newOwner new owner address
    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferPrepared(_OWNER_, newOwner);
        _NEW_OWNER_ = newOwner;
    }

    /// @dev Set _OWNER_ from _NEW_OWNER_ and set _NEW_OWNER_ equal zero address
    function claimOwnership() public {
        require(msg.sender == _NEW_OWNER_, 'InitializableOwnable: INVALID_CLAIM');
        emit OwnershipTransferred(_OWNER_, _NEW_OWNER_);
        _OWNER_ = _NEW_OWNER_;
        _NEW_OWNER_ = address(0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

/*

░██╗░░░░░░░██╗░█████╗░░█████╗░░░░░░░███████╗██╗
░██║░░██╗░░██║██╔══██╗██╔══██╗░░░░░░██╔════╝██║
░╚██╗████╗██╔╝██║░░██║██║░░██║█████╗█████╗░░██║
░░████╔═████║░██║░░██║██║░░██║╚════╝██╔══╝░░██║
░░╚██╔╝░╚██╔╝░╚█████╔╝╚█████╔╝░░░░░░██║░░░░░██║
░░░╚═╝░░░╚═╝░░░╚════╝░░╚════╝░░░░░░░╚═╝░░░░░╚═╝

*
* MIT License
* ===========
*
* Copyright (c) 2020 WooTrade
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/// @title The oracle interface by Woo.Network.
/// @notice update and posted the latest price info by Woo.
interface IWooracle {
    /// @dev the quote token for Wooracle's pricing.
    /// @return the quote token
    function quoteToken() external view returns (address);

    /// @dev the price for the given base token
    /// @param base baseToken address
    /// @return priceNow the current price of base token
    /// @return feasible whether the current price is feasible and valid
    function price(address base) external view returns (uint256 priceNow, bool feasible);

    function getPrice(address base) external view returns (uint256);

    function getSpread(address base) external view returns (uint256);

    function getCoeff(address base) external view returns (uint256);

    /// @dev returns the state for the given base token.
    /// @param base baseToken address
    /// @return priceNow the current price of base token
    /// @return spreadNow the current spread of base token
    /// @return coeffNow the slippage coefficient of base token
    /// @return feasible whether the current state is feasible and valid
    function state(address base)
        external
        view
        returns (
            uint256 priceNow,
            uint256 spreadNow,
            uint256 coeffNow,
            bool feasible
        );

    /// @dev returns the last updated timestamp
    /// @return the last updated timestamp
    function timestamp() external view returns (uint256);

    /// @dev returns whether the base token price is valid.
    /// @param base baseToken address
    /// @return whether the base token price is valid.
    function isFeasible(address base) external view returns (bool);
}