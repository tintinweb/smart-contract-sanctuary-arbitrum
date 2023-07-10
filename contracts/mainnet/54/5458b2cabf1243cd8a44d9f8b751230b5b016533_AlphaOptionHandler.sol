/**
 *Submitted for verification at Arbiscan on 2023-07-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library Types {
    struct OptionSeries {
        uint64 expiration;
        uint128 strike;
        bool isPut;
        address underlying;
        address strikeAsset;
        address collateral;
    }
    struct Option {
		uint64 expiration;
		uint128 strike;
		bool isPut;
		bool isBuyable;
		bool isSellable;
	}
}

contract AlphaOptionHandler {

    event OrderCreated(
        Types.OptionSeries optionSeries,
        uint256 amount,
        uint256 price,
        uint256 orderExpiry,
        address buyerAddress,
        bool _isBuyBack,
        uint256[2] spotMovementRange
    );

    event StrangleCreated(
        Types.OptionSeries optionSeriesCall,
        Types.OptionSeries optionSeriesPut,
        uint256 amountCall,
        uint256 amountPut,
        uint256 priceCall,
        uint256 pricePut,
        uint256 orderExpiry,
        address buyerAddress,
        uint256[2] callSpotMovementRange,
        uint256[2] putSpotMovementRange
    );

    event PortfolioDeltaRebalanced(
        int256 delta,
        uint256 reactorIndex
    );


	event SeriesApproved(
		bytes32 indexed optionHash,
		uint64 expiration,
		uint128 strike,
		bool isPut,
		bool isBuyable,
		bool isSellable
	);
	event SeriesAltered(
		bytes32 indexed optionHash,
		uint64 expiration,
		uint128 strike,
		bool isPut,
		bool isBuyable,
		bool isSellable
	);

    /**
    * @notice creates an order for a number of options from the pool to a specified user. The function
	 *      is intended to be used to issue options to market makers/ OTC market participants
	 *      in order to have flexibility and customisability on option issuance and market
	 *      participant UX.
	 * @param _optionSeries the option token series to issue - strike in e18
	 * @param _amount the number of options to issue - e18
	 * @param _price the price per unit to issue at - in e18
	 * @param _orderExpiry the expiry of the custom order, after which the
	 *        buyer cannot use this order (if past the order is redundant)
	 * @param _buyerAddress the agreed upon buyer address
	 * @param _isBuyBack whether the order being created is buy back
	 * @param _spotMovementRange min and max amount that the spot price can move during the order
	 */
    function createOrder(
        Types.OptionSeries memory _optionSeries,
        uint256 _amount,
        uint256 _price,
        uint256 _orderExpiry,
        address _buyerAddress,
        bool _isBuyBack,
        uint256[2] memory _spotMovementRange
    ) public {
        emit OrderCreated(
            _optionSeries,
            _amount,
            _price,
            _orderExpiry,
            _buyerAddress,
            _isBuyBack,
            _spotMovementRange
        );
    }

    /**
 * @notice function for hedging portfolio delta through external means
	 * @param delta the current portfolio delta
	 * @param reactorIndex the index of the reactor in the hedgingReactors array to use
	 */
    function rebalancePortfolioDelta(int256 delta, uint256 reactorIndex) public {
        emit PortfolioDeltaRebalanced(
            delta,
            reactorIndex
        );
    }


    /**
     * @notice creates a strangle order. One custom put and one custom call order to be executed simultaneously.
	 * @param _optionSeriesCall the option token series to issue for the call part of the strangle - strike in e18
	 * @param _optionSeriesPut the option token series to issue for the put part of the strangle - strike in e18
	 * @param _amountCall the number of call options to issue
	 * @param _amountPut the number of put options to issue
	 * @param _priceCall the price per unit to issue calls at
	 * @param _pricePut the price per unit to issue puts at
	 * @param _orderExpiry the expiry of the order (if past the order is redundant)
	 * @param _buyerAddress the agreed upon buyer address
	 */
    function createStrangle(
        Types.OptionSeries memory _optionSeriesCall,
        Types.OptionSeries memory _optionSeriesPut,
        uint256 _amountCall,
        uint256 _amountPut,
        uint256 _priceCall,
        uint256 _pricePut,
        uint256 _orderExpiry,
        address _buyerAddress,
        uint256[2] memory _callSpotMovementRange,
        uint256[2] memory _putSpotMovementRange
    ) public {
        emit StrangleCreated(
            _optionSeriesCall,
            _optionSeriesPut,
            _amountCall,
            _amountPut,
            _priceCall,
            _pricePut,
            _orderExpiry,
            _buyerAddress,
            _callSpotMovementRange,
            _putSpotMovementRange
        );
    }

    function issueNewSeries(Types.Option[] memory options) public {
        uint256 addressLength = options.length;

        for (uint256 i = 0; i < addressLength; i++) {
            Types.Option memory o = options[i];

            bytes32 optionHash = keccak256(abi.encodePacked(o.expiration, o.strike, o.isPut));

            emit SeriesApproved(optionHash, o.expiration, o.strike, o.isPut, o.isBuyable, o.isSellable);
        }
    }

    function changeOptionBuyOrSell(Types.Option[] memory options) public {
        uint256 addressLength = options.length;

        for (uint256 i = 0; i < addressLength; i++) {
            Types.Option memory o = options[i];

            bytes32 optionHash = keccak256(abi.encodePacked(o.expiration, o.strike, o.isPut));

            emit SeriesAltered(optionHash, o.expiration, o.strike, o.isPut, o.isBuyable, o.isSellable);
        }
    }
}