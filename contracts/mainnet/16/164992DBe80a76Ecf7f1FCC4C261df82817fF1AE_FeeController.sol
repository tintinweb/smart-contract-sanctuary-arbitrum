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

pragma solidity ^0.8.0;

/**
 * @title FixedPoint
 * @dev Math library to operate with fixed point values with 18 decimals
 */
library FixedPoint {
    // 1 in fixed point value: 18 decimal places
    uint256 internal constant ONE = 1e18;

    /**
     * @dev Multiplies two fixed point numbers rounding down
     */
    function mulDown(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            uint256 product = a * b;
            require(a == 0 || product / a == b, 'MUL_OVERFLOW');
            return product / ONE;
        }
    }

    /**
     * @dev Multiplies two fixed point numbers rounding up
     */
    function mulUp(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            uint256 product = a * b;
            require(a == 0 || product / a == b, 'MUL_OVERFLOW');
            return product == 0 ? 0 : (((product - 1) / ONE) + 1);
        }
    }

    /**
     * @dev Divides two fixed point numbers rounding down
     */
    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            require(b != 0, 'ZERO_DIVISION');
            if (a == 0) return 0;
            uint256 aInflated = a * ONE;
            require(aInflated / a == ONE, 'DIV_INTERNAL');
            return aInflated / b;
        }
    }

    /**
     * @dev Divides two fixed point numbers rounding up
     */
    function divUp(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            require(b != 0, 'ZERO_DIVISION');
            if (a == 0) return 0;
            uint256 aInflated = a * ONE;
            require(aInflated / a == ONE, 'DIV_INTERNAL');
            return ((aInflated - 1) / b) + 1;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';

import '@mimic-fi/v3-helpers/contracts/math/FixedPoint.sol';

import './interfaces/IFeeController.sol';

/**
 * @title Fee Controller
 * @dev Controller used to manage all the fee-related information of the protocol
 */
contract FeeController is IFeeController, Ownable {
    /**
     * @dev Fee information stored per smart vault
     * @param pct Current fee percentage that should be applied to a smart vault
     * @param maxPct Maximum fee percentage that can be charged to a smart vault
     * @param collector Address that will receive the charged fees for this smart vault
     */
    struct Fee {
        uint256 pct;
        uint256 maxPct;
        address collector;
    }

    // Address of the default collector
    address public override defaultFeeCollector;

    // List of fees indexed per smart vault address
    mapping (address => Fee) internal _fees;

    /**
     * @dev Creates a new fee controller contract
     * @param collector Default fee collector to be set
     * @param owner Address that will own the fee collector
     */
    constructor(address collector, address owner) {
        _transferOwnership(owner);
        _setDefaultFeeCollector(collector);
    }

    /**
     * @dev Tells if there is a fee set for a smart vault
     * @param smartVault Address of the smart vault being queried
     */
    function hasFee(address smartVault) external view override returns (bool) {
        return _fees[smartVault].maxPct != 0;
    }

    /**
     * @dev Tells the fee information for a smart vault
     * @param smartVault Address of the smart vault being queried
     */
    function getFee(address smartVault) external view override returns (uint256 max, uint256 pct, address collector) {
        Fee storage fee = _fees[smartVault];
        require(fee.maxPct > 0, 'FEE_CONTROLLER_SV_NOT_SET');

        pct = fee.pct;
        max = fee.maxPct;
        collector = fee.collector != address(0) ? fee.collector : defaultFeeCollector;
    }

    /**
     * @dev Sets the default fee collector
     * @param collector Default fee collector to be set
     */
    function setDefaultFeeCollector(address collector) external override onlyOwner {
        _setDefaultFeeCollector(collector);
    }

    /**
     * @dev Sets a max fee percentage for a smart vault
     * @param smartVault Address of smart vault to set a fee percentage for
     * @param maxPct Max fee percentage to be set
     */
    function setMaxFeePercentage(address smartVault, uint256 maxPct) external override onlyOwner {
        require(maxPct > 0, 'FEE_CONTROLLER_MAX_PCT_ZERO');

        Fee storage fee = _fees[smartVault];
        if (fee.maxPct == 0) {
            require(maxPct < FixedPoint.ONE, 'FEE_CONTROLLER_MAX_PCT_ABOVE_ONE');
        } else {
            require(maxPct < fee.maxPct, 'FEE_CONTROLLER_MAX_PCT_ABOVE_PRE');
        }

        fee.maxPct = maxPct;
        emit MaxFeePercentageSet(smartVault, maxPct);
        if (fee.pct == 0 || fee.pct > maxPct) _setFeePercentage(smartVault, maxPct);
    }

    /**
     * @dev Sets a fee percentage for a smart vault
     * @param smartVault Address of smart vault to set a fee percentage for
     * @param pct Fee percentage to be set
     */
    function setFeePercentage(address smartVault, uint256 pct) external override onlyOwner {
        _setFeePercentage(smartVault, pct);
    }

    /**
     * @dev Sets a fee collector for a smart vault
     * @param smartVault Address of smart vault to set a fee collector for
     * @param collector Fee collector to be set
     */
    function setFeeCollector(address smartVault, address collector) external override onlyOwner {
        require(collector != address(0), 'FEE_CONTROLLER_COLLECTOR_ZERO');
        Fee storage fee = _fees[smartVault];
        require(fee.maxPct > 0, 'FEE_CONTROLLER_SV_NOT_SET');
        fee.collector = collector;
        emit FeeCollectorSet(smartVault, collector);
    }

    /**
     * @dev Sets the default fee collector
     * @param collector Default fee collector to be set
     */
    function _setDefaultFeeCollector(address collector) private {
        require(collector != address(0), 'FEE_CONTROLLER_COLLECTOR_ZERO');
        defaultFeeCollector = collector;
        emit DefaultFeeCollectorSet(collector);
    }

    /**
     * @dev Sets the fee percentage of a smart vault
     * @param smartVault Address of the smart vault to set a fee percentage for
     * @param pct Fee percentage to be set
     */
    function _setFeePercentage(address smartVault, uint256 pct) private {
        Fee storage fee = _fees[smartVault];
        require(fee.maxPct > 0, 'FEE_CONTROLLER_SV_NOT_SET');
        require(pct <= fee.maxPct, 'FEE_CONTROLLER_PCT_ABOVE_MAX');
        fee.pct = pct;
        emit FeePercentageSet(smartVault, pct);
    }
}

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

pragma solidity >=0.8.0;

/**
 * @dev Fee controller interface
 */
interface IFeeController {
    /**
     * @dev Emitted every time a default fee collector is set
     */
    event DefaultFeeCollectorSet(address indexed collector);

    /**
     * @dev Emitted every time a max fee percentage is set for a smart vault
     */
    event MaxFeePercentageSet(address indexed smartVault, uint256 maxPct);

    /**
     * @dev Emitted every time a custom fee percentage is set
     */
    event FeePercentageSet(address indexed smartVault, uint256 pct);

    /**
     * @dev Emitted every time a custom fee collector is set
     */
    event FeeCollectorSet(address indexed smartVault, address indexed collector);

    /**
     * @dev Tells the default fee collector
     */
    function defaultFeeCollector() external view returns (address);

    /**
     * @dev Tells if there is a fee set for a smart vault
     * @param smartVault Address of the smart vault being queried
     */
    function hasFee(address smartVault) external view returns (bool);

    /**
     * @dev Tells the applicable fee information for a smart vault
     * @param smartVault Address of the smart vault being queried
     */
    function getFee(address smartVault) external view returns (uint256 max, uint256 pct, address collector);

    /**
     * @dev Sets the default fee collector
     * @param collector Default fee collector to be set
     */
    function setDefaultFeeCollector(address collector) external;

    /**
     * @dev Sets a max fee percentage for a smart vault
     * @param smartVault Address of smart vault to set a fee percentage for
     * @param maxPct Max fee percentage to be set
     */
    function setMaxFeePercentage(address smartVault, uint256 maxPct) external;

    /**
     * @dev Sets a fee percentage for a smart vault
     * @param smartVault Address of smart vault to set a fee percentage for
     * @param pct Fee percentage to be set
     */
    function setFeePercentage(address smartVault, uint256 pct) external;

    /**
     * @dev Sets a fee collector for a smart vault
     * @param smartVault Address of smart vault to set a fee collector for
     * @param collector Fee collector to be set
     */
    function setFeeCollector(address smartVault, address collector) external;
}