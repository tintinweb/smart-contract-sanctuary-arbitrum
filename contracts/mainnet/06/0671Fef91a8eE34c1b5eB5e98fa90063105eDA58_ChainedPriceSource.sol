// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ISynonymPriceSource} from "../../interfaces/ISynonymPriceSource.sol";

/**
 * @title BaseSynonymPriceOracle
 */
abstract contract BaseSynonymPriceSource is ISynonymPriceSource, Ownable {
    uint256 public constant PRICE_PRECISION = 1e18;
    bytes32 public constant OUTPUT_ASSET_USD = keccak256("USD");
    bytes32 public constant OUTPUT_ASSET_ETH = keccak256("ETH");
    string public override outputAsset;

    constructor(string memory _outputAsset) Ownable(msg.sender) {
        outputAsset = _outputAsset;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./BaseSynonymPriceSource.sol";

/**
 * @title ChainedPriceSource
 * @notice An adapter to chain multiple ISynonymPriceSource price feeds into a single price feed
 */
contract ChainedPriceSource is BaseSynonymPriceSource {
    struct ChainedSource {
        ISynonymPriceSource source;
        address inputAsset;
        string outputAsset;
        uint256 maxPriceAge;
    }

    error CallingMaxPriceAgeMustBeUint256Max();

    ChainedSource[] public sources;

    constructor(
        ChainedSource[] memory _sources
    ) BaseSynonymPriceSource(_sources[_sources.length - 1].outputAsset) {
        require(_sources.length > 0, "ChainedPriceSource: no sources");
        for (uint256 i = 0; i < _sources.length; i++) {
            require(
                _sources[i].source.priceAvailable(_sources[i].inputAsset) &&
                keccak256(abi.encodePacked(_sources[i].source.outputAsset())) == keccak256(abi.encodePacked(_sources[i].outputAsset)) &&
                _sources[i].maxPriceAge > 0,
                "ChainedPriceSource: invalid source"
            );
            sources.push(_sources[i]);
        }
    }

    function priceAvailable(address _asset) public view override returns (bool) {
        return _asset == sources[0].inputAsset;
    }

    function getPrice(address _asset, uint256 _maxPriceAge) external view override returns (Price memory price) {
        if (!priceAvailable(_asset)) {
            revert NoPriceForAsset();
        }

        if (_maxPriceAge != type(uint256).max) {
            // each price source has its own defined max price age
            // require calling getPrice with max to avoid expecting a different behavior
            revert CallingMaxPriceAgeMustBeUint256Max();
        }

        for (uint256 i = 0; i < sources.length; i++) {
            Price memory _sourcePrice = sources[i].source.getPrice(sources[i].inputAsset, sources[i].maxPriceAge);
            if (i == 0) {
                // first element of the chain. seed the price and scale to target precision
                price.price = _sourcePrice.price * PRICE_PRECISION / _sourcePrice.precision;
                price.confidence = _sourcePrice.confidence;
                // this is just for interface compatibility
                // _maxAge is checked in each of the sources independently
                price.updatedAt = _sourcePrice.updatedAt;
            } else {
                uint256 previousSourcePrice = price.price;
                price.price = price.price * _sourcePrice.price / _sourcePrice.precision;
                // let's assume prices (a and b) and confidences (da and db). we need to calculate the error dz of product z = a * b
                // the error formula for the product is:
                // dz / z = (da / a) + (db / b)
                // dz = z * (da / a + db / b)
                // z = a * b
                // dz = a * b * (da / a + db / b)
                // dz = da * b + db * a
                price.confidence = (price.confidence * _sourcePrice.price + previousSourcePrice * _sourcePrice.confidence) / _sourcePrice.precision;
                // precision sanity check
                // 18                     18               6                      18                     6                        6
            }
        }
        price.precision = PRICE_PRECISION;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ISynonymPriceSource {
    error NoPriceForAsset();
    error StalePrice();

    struct Price {
        uint256 price;
        uint256 confidence;
        uint256 precision;
        uint256 updatedAt;
    }

    function getPrice(address _asset, uint256 _maxAge) external view returns (Price memory price);
    function priceAvailable(address _asset) external view returns (bool);
    function outputAsset() external view returns (string memory);
}