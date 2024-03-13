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

pragma solidity >=0.5.0;

interface IPancakePair {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

// SPDX-License-Identifier: MIT

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IVaultPriceFeed.sol";
import "../oracle/interfaces/IPriceFeed.sol";
import "../oracle/interfaces/ISecondaryPriceFeed.sol";
import "../amm/interfaces/IPancakePair.sol";

pragma solidity 0.8.19;

contract VaultPriceFeed is Ownable, IVaultPriceFeed {
    uint256 public constant PRICE_PRECISION = 10**30;
    uint256 public constant ONE_USD = PRICE_PRECISION;
    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    uint256 public constant MAX_SPREAD_BASIS_POINTS = 50;
    uint256 public constant MAX_ADJUSTMENT_INTERVAL = 2 hours;
    uint256 public constant MAX_ADJUSTMENT_BASIS_POINTS = 20;

    bool public isAmmEnabled = true;
    bool public isSecondaryPriceEnabled = true;
    bool public useV2Pricing = false;
    bool public favorPrimaryPrice = false;
    uint256 public priceSampleSpace = 3;
    uint256 public maxStrictPriceDeviation = 0;
    address public secondaryPriceFeed;
    uint256 public spreadThresholdBasisPoints = 30;

    address public btc;
    address public eth;
    address public bnb;
    address public bnbBusd;
    address public ethBnb;
    address public btcBnb;

    mapping(address => address) public priceFeeds;
    mapping(address => uint256) public priceDecimals;
    mapping(address => uint256) public spreadBasisPoints;
    // Chainlink can return prices for stablecoins
    // that differs from 1 USD by a larger percentage than stableSwapFeeBasisPoints
    // we use strictStableTokens to cap the price to 1 USD
    // this allows us to configure stablecoins like DAI as being a stableToken
    // while not being a strictStableToken
    mapping(address => bool) public strictStableTokens;

    mapping(address => uint256) public override adjustmentBasisPoints;
    mapping(address => bool) public override isAdjustmentAdditive;
    mapping(address => uint256) public lastAdjustmentTimings;
    mapping(address => uint256) public stalePriceThresholds;

    function setAdjustment(
        address _token,
        bool _isAdditive,
        uint256 _adjustmentBps
    ) external override onlyOwner {
        require(
            lastAdjustmentTimings[_token] + MAX_ADJUSTMENT_INTERVAL <
                block.timestamp,
            "VaultPriceFeed: adjustment frequency exceeded"
        );
        require(
            _adjustmentBps <= MAX_ADJUSTMENT_BASIS_POINTS,
            "invalid _adjustmentBps"
        );
        isAdjustmentAdditive[_token] = _isAdditive;
        adjustmentBasisPoints[_token] = _adjustmentBps;
        lastAdjustmentTimings[_token] = block.timestamp;
    }

    function setUseV2Pricing(bool _useV2Pricing) external override onlyOwner {
        useV2Pricing = _useV2Pricing;
    }

    function setIsAmmEnabled(bool _isEnabled) external override onlyOwner {
        isAmmEnabled = _isEnabled;
    }

    function setIsSecondaryPriceEnabled(bool _isEnabled)
        external
        override
        onlyOwner
    {
        isSecondaryPriceEnabled = _isEnabled;
    }

    function setSecondaryPriceFeed(address _secondaryPriceFeed)
        external
        onlyOwner
    {
        secondaryPriceFeed = _secondaryPriceFeed;
    }

    function setTokens(
        address _btc,
        address _eth,
        address _bnb
    ) external onlyOwner {
        btc = _btc;
        eth = _eth;
        bnb = _bnb;
    }

    function setPairs(
        address _bnbBusd,
        address _ethBnb,
        address _btcBnb
    ) external onlyOwner {
        bnbBusd = _bnbBusd;
        ethBnb = _ethBnb;
        btcBnb = _btcBnb;
    }

    function setSpreadBasisPoints(address _token, uint256 _spreadBasisPoints)
        external
        override
        onlyOwner
    {
        require(
            _spreadBasisPoints <= MAX_SPREAD_BASIS_POINTS,
            "VaultPriceFeed: invalid _spreadBasisPoints"
        );
        spreadBasisPoints[_token] = _spreadBasisPoints;
    }

    function setSpreadThresholdBasisPoints(uint256 _spreadThresholdBasisPoints)
        external
        override
        onlyOwner
    {
        spreadThresholdBasisPoints = _spreadThresholdBasisPoints;
    }

    function setFavorPrimaryPrice(bool _favorPrimaryPrice)
        external
        override
        onlyOwner
    {
        favorPrimaryPrice = _favorPrimaryPrice;
    }

    function setPriceSampleSpace(uint256 _priceSampleSpace)
        external
        override
        onlyOwner
    {
        require(
            _priceSampleSpace > 0,
            "VaultPriceFeed: invalid _priceSampleSpace"
        );
        priceSampleSpace = _priceSampleSpace;
    }

    function setMaxStrictPriceDeviation(uint256 _maxStrictPriceDeviation)
        external
        override
        onlyOwner
    {
        maxStrictPriceDeviation = _maxStrictPriceDeviation;
    }

    function setTokenConfig(
        address _token,
        address _priceFeed,
        uint256 _priceDecimals,
        bool _isStrictStable,
        uint256 _stalePriceThreshold
    ) external override onlyOwner {
        priceFeeds[_token] = _priceFeed;
        priceDecimals[_token] = _priceDecimals;
        strictStableTokens[_token] = _isStrictStable;
        stalePriceThresholds[_token] = _stalePriceThreshold;
    }

    function getPrice(
        address _token,
        bool _maximise,
        bool _includeAmmPrice,
        bool /* _useSwapPricing */
    ) public view override returns (uint256) {
        uint256 price = useV2Pricing
            ? getPriceV2(_token, _maximise, _includeAmmPrice)
            : getPriceV1(_token, _maximise, _includeAmmPrice);

        uint256 adjustmentBps = adjustmentBasisPoints[_token];
        if (adjustmentBps > 0) {
            bool isAdditive = isAdjustmentAdditive[_token];
            if (isAdditive) {
                price =
                    (price * (BASIS_POINTS_DIVISOR + adjustmentBps)) /
                    BASIS_POINTS_DIVISOR;
            } else {
                price =
                    (price * (BASIS_POINTS_DIVISOR - adjustmentBps)) /
                    BASIS_POINTS_DIVISOR;
            }
        }

        return price;
    }

    function getPriceV1(
        address _token,
        bool _maximise,
        bool _includeAmmPrice
    ) public view returns (uint256) {
        uint256 price = getPrimaryPrice(_token, _maximise);

        if (_includeAmmPrice && isAmmEnabled) {
            uint256 ammPrice = getAmmPrice(_token);
            if (ammPrice > 0) {
                if (_maximise && ammPrice > price) {
                    price = ammPrice;
                }
                if (!_maximise && ammPrice < price) {
                    price = ammPrice;
                }
            }
        }

        if (isSecondaryPriceEnabled) {
            price = getSecondaryPrice(_token, price, _maximise);
        }

        if (strictStableTokens[_token]) {
            uint256 delta = price > ONE_USD ? price - ONE_USD : ONE_USD - price;
            if (delta <= maxStrictPriceDeviation) {
                return ONE_USD;
            }

            // if _maximise and price is e.g. 1.02, return 1.02
            if (_maximise && price > ONE_USD) {
                return price;
            }

            // if !_maximise and price is e.g. 0.98, return 0.98
            if (!_maximise && price < ONE_USD) {
                return price;
            }

            return ONE_USD;
        }

        uint256 _spreadBasisPoints = spreadBasisPoints[_token];

        if (_maximise) {
            return
                (price * (BASIS_POINTS_DIVISOR + _spreadBasisPoints)) /
                BASIS_POINTS_DIVISOR;
        }

        return
            (price * (BASIS_POINTS_DIVISOR - _spreadBasisPoints)) /
            BASIS_POINTS_DIVISOR;
    }

    function getPriceV2(
        address _token,
        bool _maximise,
        bool _includeAmmPrice
    ) public view returns (uint256) {
        uint256 price = getPrimaryPrice(_token, _maximise);

        if (_includeAmmPrice && isAmmEnabled) {
            price = getAmmPriceV2(_token, _maximise, price);
        }

        if (isSecondaryPriceEnabled) {
            price = getSecondaryPrice(_token, price, _maximise);
        }

        if (strictStableTokens[_token]) {
            uint256 delta = price > ONE_USD ? price - ONE_USD : ONE_USD - price;
            if (delta <= maxStrictPriceDeviation) {
                return ONE_USD;
            }

            // if _maximise and price is e.g. 1.02, return 1.02
            if (_maximise && price > ONE_USD) {
                return price;
            }

            // if !_maximise and price is e.g. 0.98, return 0.98
            if (!_maximise && price < ONE_USD) {
                return price;
            }

            return ONE_USD;
        }

        uint256 _spreadBasisPoints = spreadBasisPoints[_token];

        if (_maximise) {
            return
                (price * (BASIS_POINTS_DIVISOR + _spreadBasisPoints)) /
                BASIS_POINTS_DIVISOR;
        }

        return
            (price * (BASIS_POINTS_DIVISOR - _spreadBasisPoints)) /
            BASIS_POINTS_DIVISOR;
    }

    function getAmmPriceV2(
        address _token,
        bool _maximise,
        uint256 _primaryPrice
    ) public view returns (uint256) {
        uint256 ammPrice = getAmmPrice(_token);
        if (ammPrice == 0) {
            return _primaryPrice;
        }

        uint256 diff = ammPrice > _primaryPrice
            ? ammPrice - _primaryPrice
            : _primaryPrice - ammPrice;
        if (
            diff * BASIS_POINTS_DIVISOR <
            _primaryPrice * spreadThresholdBasisPoints
        ) {
            if (favorPrimaryPrice) {
                return _primaryPrice;
            }
            return ammPrice;
        }

        if (_maximise && ammPrice > _primaryPrice) {
            return ammPrice;
        }

        if (!_maximise && ammPrice < _primaryPrice) {
            return ammPrice;
        }

        return _primaryPrice;
    }

    function getLatestPrimaryPrice(address _token)
        public
        view
        override
        returns (uint256)
    {
        address priceFeedAddress = priceFeeds[_token];
        require(
            priceFeedAddress != address(0),
            "VaultPriceFeed: invalid price feed"
        );

        IPriceFeed priceFeed = IPriceFeed(priceFeedAddress);

        (, int256 price, , uint256 updatedAt, ) = priceFeed.latestRoundData();
        require(
            stalePriceThresholds[_token] == 0 ||
                updatedAt >= block.timestamp - stalePriceThresholds[_token],
            "VaultPriceFeed: stale price"
        );

        require(price > 0, "VaultPriceFeed: invalid price");

        return uint256(price);
    }

    function getPrimaryPrice(address _token, bool _maximise)
        public
        view
        override
        returns (uint256)
    {
        address priceFeedAddress = priceFeeds[_token];
        require(
            priceFeedAddress != address(0),
            "VaultPriceFeed: invalid price feed"
        );

        IPriceFeed priceFeed = IPriceFeed(priceFeedAddress);

        uint256 price = 0;
        uint80 roundId = priceFeed.latestRound();

        uint256 stalePriceThreshold = stalePriceThresholds[_token];
        uint256 lastUpdatedAt = block.timestamp;

        for (uint80 i = 0; i < priceSampleSpace; i++) {
            if (roundId <= i) {
                break;
            }
            uint256 p;

            (, int256 _p, , uint256 updatedAt, ) = priceFeed.getRoundData(
                roundId - i
            );
            require(
                stalePriceThreshold == 0 ||
                    updatedAt >= lastUpdatedAt - stalePriceThreshold,
                "VaultPriceFeed: stale price"
            );
            require(_p > 0, "VaultPriceFeed: invalid price");
            lastUpdatedAt = updatedAt;
            p = uint256(_p);

            if (price == 0) {
                price = p;
                continue;
            }

            if (_maximise && p > price) {
                price = p;
                continue;
            }

            if (!_maximise && p < price) {
                price = p;
            }
        }

        require(price > 0, "VaultPriceFeed: could not fetch price");
        // normalise price precision
        uint256 _priceDecimals = priceDecimals[_token];
        return (price * PRICE_PRECISION) / (10**_priceDecimals);
    }

    function getSecondaryPrice(
        address _token,
        uint256 _referencePrice,
        bool _maximise
    ) public view returns (uint256) {
        if (secondaryPriceFeed == address(0)) {
            return _referencePrice;
        }
        return
            ISecondaryPriceFeed(secondaryPriceFeed).getPrice(
                _token,
                _referencePrice,
                _maximise
            );
    }

    function getAmmPrice(address _token)
        public
        view
        override
        returns (uint256)
    {
        if (_token == bnb) {
            // for bnbBusd, reserve0: BNB, reserve1: BUSD
            return getPairPrice(bnbBusd, true);
        }

        if (_token == eth) {
            uint256 price0 = getPairPrice(bnbBusd, true);
            // for ethBnb, reserve0: ETH, reserve1: BNB
            uint256 price1 = getPairPrice(ethBnb, true);
            // this calculation could overflow if (price0 / 10**30) * (price1 / 10**30) is more than 10**17
            return (price0 * price1) / PRICE_PRECISION;
        }

        if (_token == btc) {
            uint256 price0 = getPairPrice(bnbBusd, true);
            // for btcBnb, reserve0: BTC, reserve1: BNB
            uint256 price1 = getPairPrice(btcBnb, true);
            // this calculation could overflow if (price0 / 10**30) * (price1 / 10**30) is more than 10**17
            return (price0 * price1) / PRICE_PRECISION;
        }

        return 0;
    }

    // if divByReserve0: calculate price as reserve1 / reserve0
    // if !divByReserve1: calculate price as reserve0 / reserve1
    function getPairPrice(address _pair, bool _divByReserve0)
        public
        view
        returns (uint256)
    {
        (uint256 reserve0, uint256 reserve1, ) = IPancakePair(_pair)
            .getReserves();
        if (_divByReserve0) {
            if (reserve0 == 0) {
                return 0;
            }
            return (reserve1 * PRICE_PRECISION) / reserve0;
        }
        if (reserve1 == 0) {
            return 0;
        }
        return (reserve0 * PRICE_PRECISION) / reserve1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IVaultPriceFeed {
    function adjustmentBasisPoints(address _token)
        external
        view
        returns (uint256);

    function isAdjustmentAdditive(address _token) external view returns (bool);

    function setAdjustment(
        address _token,
        bool _isAdditive,
        uint256 _adjustmentBps
    ) external;

    function setUseV2Pricing(bool _useV2Pricing) external;

    function setIsAmmEnabled(bool _isEnabled) external;

    function setIsSecondaryPriceEnabled(bool _isEnabled) external;

    function setSpreadBasisPoints(address _token, uint256 _spreadBasisPoints)
        external;

    function setSpreadThresholdBasisPoints(uint256 _spreadThresholdBasisPoints)
        external;

    function setFavorPrimaryPrice(bool _favorPrimaryPrice) external;

    function setPriceSampleSpace(uint256 _priceSampleSpace) external;

    function setMaxStrictPriceDeviation(uint256 _maxStrictPriceDeviation)
        external;

    function getPrice(
        address _token,
        bool _maximise,
        bool _includeAmmPrice,
        bool _useSwapPricing
    ) external view returns (uint256);

    function getAmmPrice(address _token) external view returns (uint256);

    function getLatestPrimaryPrice(address _token)
        external
        view
        returns (uint256);

    function getPrimaryPrice(address _token, bool _maximise)
        external
        view
        returns (uint256);

    function setTokenConfig(
        address _token,
        address _priceFeed,
        uint256 _priceDecimals,
        bool _isStrictStable,
        uint256 _stalePriceThreshold
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IPriceFeed {
    function description() external view returns (string memory);

    function aggregator() external view returns (address);

    function latestAnswer() external view returns (int256);

    function latestRound() external view returns (uint80);

    function getRoundData(uint80 roundId)
        external
        view
        returns (
            uint80,
            int256,
            uint256,
            uint256,
            uint80
        );

    function latestRoundData()
        external
        view
        returns (
            uint80,
            int256,
            uint256,
            uint256,
            uint80
        );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface ISecondaryPriceFeed {
    function getPrice(
        address _token,
        uint256 _referencePrice,
        bool _maximise
    ) external view returns (uint256);
}