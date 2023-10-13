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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {AggregatorV3Interface} from "../interfaces/AggregatorV3Interface.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

error NotSameDecimals();
error PriceFeedAOutdated(uint256 lastUpdate);
error PriceFeedBOutdated(uint256 lastUpdate);
error LatestRoundDataAFailed();
error LatestRoundDataBFailed();
error SequencerDown();
error GracePeriodNotOver();
error ZeroAddress();

contract PriceFeedAverage is Ownable {
    // solhint-disable-next-line private-vars-leading-underscore
    uint256 private constant GRACE_PERIOD_TIME = 3600;

    AggregatorV3Interface public immutable priceFeedA;
    AggregatorV3Interface public immutable priceFeedB;
    AggregatorV3Interface public immutable sequencerUptimeFeed;

    uint256 public outdatedA;
    uint256 public outdatedB;

    // #region events.

    event LogSetOutdatedA(
        address oracle,
        uint256 oldOutdated,
        uint256 newOutdated
    );

    event LogSetOutdatedB(
        address oracle,
        uint256 oldOutdated,
        uint256 newOutdated
    );

    // #endregion events.

    constructor(
        address priceFeedA_,
        address priceFeedB_,
        address sequencerUptimeFeed_,
        uint256 outdatedA_,
        uint256 outdatedB_
    ) {
        if(priceFeedA_ == address(0) || priceFeedB_ == address(0))
            revert ZeroAddress();
        priceFeedA = AggregatorV3Interface(priceFeedA_);
        priceFeedB = AggregatorV3Interface(priceFeedB_);

        if (priceFeedA.decimals() != priceFeedB.decimals())
            revert NotSameDecimals();

        sequencerUptimeFeed = AggregatorV3Interface(sequencerUptimeFeed_);

        outdatedA = outdatedA_;
        outdatedB = outdatedB_;
    }

    /// @notice set outdated value for Token A
    /// @param outdatedA_ new outdated value
    function setOutdatedA(uint256 outdatedA_) external onlyOwner {
        uint256 oldOutdatedA = outdatedA;
        outdatedA = outdatedA_;
        emit LogSetOutdatedA(address(this), oldOutdatedA, outdatedA_);
    }

    /// @notice set outdated value for Token B
    /// @param outdatedB_ new outdated value
    function setOutdatedB(uint256 outdatedB_) external onlyOwner {
        uint256 oldOutdatedB = outdatedB;
        outdatedB = outdatedB_;
        emit LogSetOutdatedB(address(this), oldOutdatedB, outdatedB_);
    }

    // solhint-disable-next-line function-max-lines
    function latestRoundData()
        external
        view
        returns (uint80, int256 answer, uint256, uint256 updatedAt, uint80)
    {
        if (address(sequencerUptimeFeed) != address(0)) _checkSequencer();

        int256 priceA;
        int256 priceB;

        uint256 updateAtA;
        uint256 updateAtB;

        try priceFeedA.latestRoundData() returns (
            uint80,
            int256 price,
            uint256,
            uint256 updatedAt,
            uint80
        ) {
            // solhint-disable-next-line not-rely-on-time
            if (block.timestamp - updatedAt > outdatedA)
                revert PriceFeedAOutdated(updatedAt);

            priceA = price;
            updateAtA = updatedAt;
        } catch {
            revert LatestRoundDataAFailed();
        }

        try priceFeedB.latestRoundData() returns (
            uint80,
            int256 price,
            uint256,
            uint256 updatedAt,
            uint80
        ) {
            // solhint-disable-next-line not-rely-on-time
            if (block.timestamp - updatedAt > outdatedB)
                revert PriceFeedBOutdated(updatedAt);

            priceB = price;
            updateAtB = updatedAt;
        } catch {
            revert LatestRoundDataBFailed();
        }

        answer = (priceA + priceB) / 2;
        updatedAt = updateAtA < updateAtB ? updateAtA: updateAtB;
    }

    function decimals() external view returns (uint8) {
        return priceFeedA.decimals();
    }

    // #region view function.

    /// @dev only needed for optimistic L2 chain
    function _checkSequencer() internal view {
        (, int256 answer, uint256 startedAt, , ) = sequencerUptimeFeed
            .latestRoundData();

        if(answer != 0)
            revert SequencerDown();

        // Make sure the grace period has passed after the
        // sequencer is back up.
        // solhint-disable-next-line not-rely-on-time, max-line-length
        if (block.timestamp - startedAt <= GRACE_PERIOD_TIME)
            revert GracePeriodNotOver();
    }

    // #endregion view functions.
}