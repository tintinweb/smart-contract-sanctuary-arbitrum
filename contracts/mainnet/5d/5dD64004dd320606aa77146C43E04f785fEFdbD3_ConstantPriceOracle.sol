// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity =0.7.6;

contract ConstantPriceOracle {

    /// @dev the price should take into account the number of decimals
    int256 immutable private _price;

    /// @dev the price decimals
    uint8 immutable private _decimals;

    /// @dev oracle description
    string private _description;

    constructor(int256 price, uint8 dec, string memory desc) {
        require(price > 0, "price must be positive");
        
        _price = price;
        _decimals = dec;
        _description = desc;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function version() public pure returns (uint256) {
        return 1;
    }

    function latestRoundData()
    public
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
      return (1, _price, block.timestamp, block.timestamp, 1);
    }

    function latestAnswer() public view returns (int256) {
        return _price;
    }

    function description() public view returns (string memory) {
        return _description;
    }
}