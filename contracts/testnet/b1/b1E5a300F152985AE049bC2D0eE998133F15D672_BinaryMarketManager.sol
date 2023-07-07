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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/binary/IBinaryMarketManager.sol";

/// @notice One place to get current used markets on Ryze platform
/// @author https://balance.capital
contract BinaryMarketManager is Ownable, IBinaryMarketManager {
    struct MarketData {
        address market;
        string pairName;
    }

    MarketData[] public allMarkets;

    event MarketAdded(
        address indexed market,
        string pairName,
        string marketName
    );

    /// @notice register market with given address
    /// @param market address of market
    function registerMarket(IBinaryMarket market) external onlyOwner {
        string memory pairName = market.oracle().pairName();
        string memory name = market.marketName();
        allMarkets.push(MarketData(address(market), pairName));

        emit MarketAdded(address(market), pairName, name);
    }

    /// @notice Retrieve market by market pair name
    /// @param pairName name of pair
    /// @return address of given market
    function getMarketByPairName(string memory pairName)
        external
        view
        returns (address)
    {
        for (uint256 i = 0; i < allMarkets.length; i = i + 1) {
            MarketData memory d = allMarkets[i];
            if (
                keccak256(abi.encodePacked(d.pairName)) ==
                keccak256(abi.encodePacked(pairName))
            ) {
                return d.market;
            }
        }
        return address(0);
    }

    /// @notice Retrieve market pair name by market address
    /// @param market address of market
    /// @return pair name of given market
    function getPairNameByMarket(address market)
        external
        view
        returns (string memory)
    {
        for (uint256 i = 0; i < allMarkets.length; i = i + 1) {
            MarketData memory d = allMarkets[i];
            if (d.market == market) {
                return d.pairName;
            }
        }
        revert("None exists");
    }

    /// FIXME do we need this function? if state variable is public, its automatically accessible with allMarkets() method
    /// @return All markets
    function getAllMarkets() external view returns (MarketData[] memory) {
        return allMarkets;
    }
}

// SPDX-License-Identifier: MIT
import "./IOracle.sol";
import "./IBinaryVault.sol";

pragma solidity 0.8.18;

interface IBinaryMarket {
    function oracle() external view returns (IOracle);

    function vault() external view returns (IBinaryVault);

    function marketName() external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;
import "./IBinaryMarket.sol";

interface IBinaryMarketManager {
    function registerMarket(IBinaryMarket market) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IBinaryVault {
    function claimBettingRewards(
        address to,
        uint256 amount,
        bool isRefund
    ) external returns (uint256);

    function onRoundExecuted(uint256 wonAmount, uint256 loseAmount) external;

    function getMaxHourlyExposure() external view returns (uint256);

    function isFutureBettingAvailable() external view returns (bool);

    function onPlaceBet(
        uint256 amount,
        address from,
        uint256 endTime,
        uint8 position
    ) external;

    function getExposureAmountAt(uint256 endTime)
        external
        view
        returns (uint256 exposureAmount, uint8 direction);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IOracle {
    function getLatestRoundData()
        external
        view
        returns (uint256 timestamp, uint256 price);

    function pairName() external view returns (string memory);

    function isWritable() external view returns (bool);

    function writePrice(uint256 timestamp, uint256 price) external;
}