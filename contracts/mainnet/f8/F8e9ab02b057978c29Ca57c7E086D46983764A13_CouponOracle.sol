// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
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

// SPDX-License-Identifier: -
// License: https://license.coupon.finance/LICENSE.pdf

pragma solidity ^0.8.0;

import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

import {AggregatorV3Interface} from "./external/chainlink/AggregatorV3Interface.sol";
import {ICouponOracle} from "./interfaces/ICouponOracle.sol";
import {IFallbackOracle} from "./interfaces/IFallbackOracle.sol";

contract CouponOracle is ICouponOracle, Ownable2Step {
    uint256 private constant _MAX_TIMEOUT = 1 days;
    uint256 private constant _MIN_TIMEOUT = 20 minutes;
    uint256 private constant _MAX_GRACE_PERIOD = 1 days;
    uint256 private constant _MIN_GRACE_PERIOD = 20 minutes;

    uint256 public override timeout;
    address public override sequencerOracle;
    uint256 public override gracePeriod;
    address public override fallbackOracle;
    mapping(address => address[]) private _feeds;

    constructor(address sequencerOracle_, uint256 timeout_, uint256 gracePeriod_) {
        _setSequencerOracle(sequencerOracle_);
        _setTimeout(timeout_);
        _setGracePeriod(gracePeriod_);
    }

    function decimals() external pure returns (uint8) {
        return 8;
    }

    function getFeeds(address asset) external view returns (address[] memory) {
        return _feeds[asset];
    }

    function getAssetPrice(address asset) public view returns (uint256) {
        address[] memory feeds = _feeds[asset];
        if (feeds.length == 0) {
            return IFallbackOracle(fallbackOracle).getAssetPrice(asset);
        }
        uint256 price = 10 ** 8;
        for (uint256 i = 0; i < feeds.length; ++i) {
            try AggregatorV3Interface(feeds[i]).latestRoundData() returns (
                uint80 roundId, int256 answer, uint256, /* startedAt */ uint256 updatedAt, uint80 /* answeredInRound */
            ) {
                if (
                    roundId != 0 && answer >= 0 && updatedAt <= block.timestamp
                        && block.timestamp <= updatedAt + timeout && _isSequencerValid()
                ) {
                    uint256 feedDecimals = AggregatorV3Interface(feeds[i]).decimals();
                    price = price * uint256(answer) / 10 ** feedDecimals;
                    continue;
                }
            } catch {}
            return IFallbackOracle(fallbackOracle).getAssetPrice(asset);
        }
        return price;
    }

    function getAssetsPrices(address[] memory assets) external view returns (uint256[] memory prices) {
        prices = new uint256[](assets.length);
        unchecked {
            for (uint256 i = 0; i < assets.length; ++i) {
                prices[i] = getAssetPrice(assets[i]);
            }
        }
    }

    function isSequencerValid() external view returns (bool) {
        return _isSequencerValid();
    }

    function setFallbackOracle(address newFallbackOracle) external onlyOwner {
        fallbackOracle = newFallbackOracle;
        emit SetFallbackOracle(newFallbackOracle);
    }

    function setFeeds(address[] calldata assets, address[][] calldata feeds) external onlyOwner {
        if (assets.length != feeds.length) revert LengthMismatch();
        unchecked {
            for (uint256 i = 0; i < assets.length; ++i) {
                if (_feeds[assets[i]].length > 0) revert AssetFeedAlreadySet();
                if (feeds[i].length == 0) revert LengthMismatch();
                for (uint256 j = 0; j < feeds[i].length; ++j) {
                    _feeds[assets[i]].push(feeds[i][j]);
                }
                emit SetFeed(assets[i], feeds[i]);
            }
        }
    }

    function setSequencerOracle(address newSequencerOracle) external onlyOwner {
        _setSequencerOracle(newSequencerOracle);
    }

    function _setSequencerOracle(address newSequencerOracle) internal {
        sequencerOracle = newSequencerOracle;
        emit SetSequencerOracle(newSequencerOracle);
    }

    function setTimeout(uint256 newTimeout) external onlyOwner {
        _setTimeout(newTimeout);
    }

    function _setTimeout(uint256 newTimeout) internal {
        if (newTimeout < _MIN_TIMEOUT || newTimeout > _MAX_TIMEOUT) revert InvalidTimeout();
        timeout = newTimeout;
        emit SetTimeout(newTimeout);
    }

    function setGracePeriod(uint256 newGracePeriod) external onlyOwner {
        _setGracePeriod(newGracePeriod);
    }

    function _setGracePeriod(uint256 newGracePeriod) internal {
        if (newGracePeriod < _MIN_GRACE_PERIOD || newGracePeriod > _MAX_GRACE_PERIOD) revert InvalidGracePeriod();
        gracePeriod = newGracePeriod;
        emit SetGracePeriod(newGracePeriod);
    }

    function _isSequencerValid() internal view returns (bool) {
        (, int256 answer,, uint256 updatedAt,) = AggregatorV3Interface(sequencerOracle).latestRoundData();
        return answer == 0 && block.timestamp - updatedAt > gracePeriod;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

interface ICouponOracleTypes {
    error LengthMismatch();
    error AssetFeedAlreadySet();
    error InvalidTimeout();
    error InvalidGracePeriod();

    event SetSequencerOracle(address indexed newSequencerOracle);
    event SetTimeout(uint256 newTimeout);
    event SetGracePeriod(uint256 newGracePeriod);
    event SetFallbackOracle(address indexed newFallbackOracle);
    event SetFeed(address indexed asset, address[] feeds);
}

interface ICouponOracle is ICouponOracleTypes {
    function decimals() external view returns (uint8);

    function sequencerOracle() external view returns (address);

    function timeout() external view returns (uint256);

    function gracePeriod() external view returns (uint256);

    function fallbackOracle() external view returns (address);

    function getFeeds(address asset) external view returns (address[] memory);

    function getAssetPrice(address asset) external view returns (uint256);

    function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory);

    function isSequencerValid() external view returns (bool);

    function setFallbackOracle(address newFallbackOracle) external;

    function setFeeds(address[] calldata assets, address[][] calldata feeds) external;

    function setSequencerOracle(address newSequencerOracle) external;

    function setTimeout(uint256 newTimeout) external;

    function setGracePeriod(uint256 newGracePeriod) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

interface IFallbackOracle {
    function getAssetPrice(address asset) external view returns (uint256);
}