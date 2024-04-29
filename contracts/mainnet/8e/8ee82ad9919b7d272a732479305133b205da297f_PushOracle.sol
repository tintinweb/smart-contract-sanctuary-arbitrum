pragma solidity ^0.8.13;

import {Owned} from "solmate/auth/Owned.sol";
import {IOracle} from "../interfaces/IOracle.sol";

contract PushOracle is IOracle, Owned {
    uint price;

    event PriceUpdate(uint oldPrice, uint newPrice);

    constructor(address _owner) Owned(_owner) {}

    function setPrice(uint _price) external onlyOwner {
        emit PriceUpdate(price, _price);
        price = _price;
    }

    function getPrice() external view returns (uint) {
        return price;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/// @title Interface for an oracle of the options token's strike price
/// @author zefram.eth
/// @notice An oracle of the options token's strike price
interface IOracle {
    /// @notice Computes the current strike price of the option
    /// @return price The strike price in terms of the payment token, scaled by 18 decimals.
    /// For example, if the payment token is $2 and the strike price is $4, the return value
    /// would be 2e18.
    function getPrice() external view returns (uint256 price);
}