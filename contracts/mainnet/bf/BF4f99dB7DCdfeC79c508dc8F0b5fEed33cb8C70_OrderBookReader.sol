// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IOrderBook {
    function getIncreaseOrder(address _account, uint256 _orderIndex)
        external
        view
        returns (
            uint256 tokenAmount,
            address collateralToken,
            address indexToken,
            uint256 sizeDelta,
            bool isLong,
            uint256 triggerPrice,
            bool triggerAboveThreshold,
            uint256 executionFee
        );

    function getDecreaseOrder(address _account, uint256 _orderIndex)
        external
        view
        returns (
            address collateralToken,
            uint256 collateralDelta,
            address indexToken,
            uint256 sizeDelta,
            bool isLong,
            uint256 triggerPrice,
            bool triggerAboveThreshold,
            uint256 executionFee
        );

    function executeDecreaseOrder(
        address,
        uint256,
        address payable
    ) external;

    function executeIncreaseOrder(
        address,
        uint256,
        address payable
    ) external;

    function validatePositionOrderPrice(
        bool _triggerAboveThreshold,
        uint256 _triggerPrice,
        address _indexToken,
        bool _maximizePrice,
        bool _raise
    ) external view returns (uint256, bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "../core/interfaces/IOrderBook.sol";

contract OrderBookReader {
    struct Vars {
        uint256 i;
        uint256 index;
        address account;
        uint256 uintLength;
        uint256 addressLength;
    }

    function getIncreaseOrders(
        address payable _orderBookAddress,
        address _account,
        uint256[] memory _indices
    ) external view returns (uint256[] memory, address[] memory) {
        Vars memory vars = Vars(0, 0, _account, 5, 2);

        uint256[] memory uintProps = new uint256[](
            vars.uintLength * _indices.length
        );
        address[] memory addressProps = new address[](
            vars.addressLength * _indices.length
        );

        IOrderBook orderBook = IOrderBook(_orderBookAddress);

        while (vars.i < _indices.length) {
            vars.index = _indices[vars.i];
            (
                uint256 tokenAmount,
                address collateralToken,
                address indexToken,
                uint256 sizeDelta,
                bool isLong,
                uint256 triggerPrice,
                bool triggerAboveThreshold, // uint256 executionFee

            ) = orderBook.getIncreaseOrder(vars.account, vars.index);

            uintProps[vars.i * vars.uintLength] = uint256(tokenAmount);
            uintProps[vars.i * vars.uintLength + 1] = uint256(sizeDelta);
            uintProps[vars.i * vars.uintLength + 2] = uint256(isLong ? 1 : 0);
            uintProps[vars.i * vars.uintLength + 3] = uint256(triggerPrice);
            uintProps[vars.i * vars.uintLength + 4] = uint256(
                triggerAboveThreshold ? 1 : 0
            );

            addressProps[vars.i * vars.addressLength] = (collateralToken);
            addressProps[vars.i * vars.addressLength + 1] = (indexToken);

            vars.i++;
        }

        return (uintProps, addressProps);
    }

    function getDecreaseOrders(
        address payable _orderBookAddress,
        address _account,
        uint256[] memory _indices
    ) external view returns (uint256[] memory, address[] memory) {
        Vars memory vars = Vars(0, 0, _account, 5, 2);

        uint256[] memory uintProps = new uint256[](
            vars.uintLength * _indices.length
        );
        address[] memory addressProps = new address[](
            vars.addressLength * _indices.length
        );

        IOrderBook orderBook = IOrderBook(_orderBookAddress);

        while (vars.i < _indices.length) {
            vars.index = _indices[vars.i];
            (
                address collateralToken,
                uint256 collateralDelta,
                address indexToken,
                uint256 sizeDelta,
                bool isLong,
                uint256 triggerPrice,
                bool triggerAboveThreshold, // uint256 executionFee

            ) = orderBook.getDecreaseOrder(vars.account, vars.index);

            uintProps[vars.i * vars.uintLength] = uint256(collateralDelta);
            uintProps[vars.i * vars.uintLength + 1] = uint256(sizeDelta);
            uintProps[vars.i * vars.uintLength + 2] = uint256(isLong ? 1 : 0);
            uintProps[vars.i * vars.uintLength + 3] = uint256(triggerPrice);
            uintProps[vars.i * vars.uintLength + 4] = uint256(
                triggerAboveThreshold ? 1 : 0
            );

            addressProps[vars.i * vars.addressLength] = (collateralToken);
            addressProps[vars.i * vars.addressLength + 1] = (indexToken);

            vars.i++;
        }

        return (uintProps, addressProps);
    }

    function validateOrderWithPrice(
        address orderBookAddress,
        uint256 price,
        address accounts,
        uint256 orderIndex,
        bool increase
    ) external view returns (bool isPriceValid) {
        IOrderBook orderBook = IOrderBook(orderBookAddress);

        address indexToken;
        bool isLong;
        uint256 triggerPrice;
        bool triggerAboveThreshold;

        if (increase) {
            (
                ,
                ,
                indexToken,
                ,
                isLong,
                triggerPrice,
                triggerAboveThreshold,

            ) = orderBook.getIncreaseOrder(accounts, orderIndex);
        } else {
            (
                ,
                ,
                indexToken,
                ,
                isLong,
                triggerPrice,
                triggerAboveThreshold,

            ) = orderBook.getDecreaseOrder(accounts, orderIndex);
        }
        if (indexToken != address(0)) {
            isPriceValid = triggerAboveThreshold
                ? price > triggerPrice
                : price < triggerPrice;
        }
    }
}