// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {ILeverageFacet} from "../interfaces/internal/ILeverageFacet.sol";

contract LeverageFacet is ILeverageFacet {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.LeverageFacet.diamond.storage");
    struct Leverage {
        mapping(address => LeveragePutOrder) borrowerPutOrder;
        mapping(uint256 => LeveragePutOrder) leverageOrder;
        mapping(address => address[]) lenderPutOrder;
        bytes32 domainHash;
        mapping(address => bool) whiteList;
        address priceOracle;
        mapping(bytes => bool) borrowSignature;
        mapping(uint => FeeData) feeDataOrder;
        address  leverageLendPlatformFeeRecipient;

    }

    function setWhiteList(address _user, bool _type) external {
        Leverage storage ds = diamondStorage();
        ds.whiteList[_user] = _type;
    }

    function setBorrowSignature(bytes memory _sign) external {
        Leverage storage ds = diamondStorage();
        ds.borrowSignature[_sign] = true;
    }


    function getBorrowSignature(
        bytes memory _sign
    ) external view returns (bool) {
        Leverage storage ds = diamondStorage();
        return ds.borrowSignature[_sign];
    }

    function setPriceOracle(address _o) external {
        Leverage storage ds = diamondStorage();
        ds.priceOracle = _o;
    }
    function setleverageLendPlatformFeeRecipient(address _addr) external {
        Leverage storage ds = diamondStorage();
        ds.leverageLendPlatformFeeRecipient = _addr;
    }

    function getleverageLendPlatformFeeRecipient(
    ) external view returns (address) {
        Leverage storage ds = diamondStorage();
        return ds.leverageLendPlatformFeeRecipient;
    }
    function getPriceOracle() external view returns (address) {
        Leverage storage ds = diamondStorage();
        return ds.priceOracle;
    }

    function getWhiteList(address _user) external view returns (bool) {
        Leverage storage ds = diamondStorage();
        return ds.whiteList[_user];
    }

    function diamondStorage() internal pure returns (Leverage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function setLeverageBorrowerPutOrder(
        address _borrower,
        LeveragePutOrder memory _putOrder
    ) external {
        Leverage storage ds = diamondStorage();
        ds.borrowerPutOrder[_borrower] = _putOrder;
    }

    function deleteLeverageBorrowerPutOrder(address _borrower) external {
        Leverage storage ds = diamondStorage();
        delete ds.borrowerPutOrder[_borrower];
    }

    function setLeverageFeeData(uint _orderID, FeeData memory _data) external {
        Leverage storage ds = diamondStorage();
        ds.feeDataOrder[_orderID] = _data;
    }

    function deleteLeverageFeeData(uint _orderID) external {
        Leverage storage ds = diamondStorage();
        delete ds.feeDataOrder[_orderID];
    }

    function getLeverageFeeData(
        uint _orderID
    ) external view returns (FeeData memory) {
        Leverage storage ds = diamondStorage();
        return ds.feeDataOrder[_orderID];
    }

    function getLeverageBorrowerPutOrder(
        address _borrower
    ) external view returns (LeveragePutOrder memory) {
        Leverage storage ds = diamondStorage();
        return ds.borrowerPutOrder[_borrower];
    }

    function setLeverageLenderPutOrder(
        address _lender,
        address _borrower
    ) external {
        Leverage storage ds = diamondStorage();
        ds.lenderPutOrder[_lender].push(_borrower);
    }

    function getLeverageLenderPutOrder(
        address _lender
    ) external view returns (address[] memory) {
        Leverage storage ds = diamondStorage();
        return ds.lenderPutOrder[_lender];
    }

    function getLeverageLenderPutOrderLength(
        address _lender
    ) external view returns (uint256) {
        Leverage storage ds = diamondStorage();
        return ds.lenderPutOrder[_lender].length;
    }

    function deleteLeverageLenderPutOrder(
        address _lender,
        uint256 _index
    ) external {
        Leverage storage ds = diamondStorage();
        uint256 lastIndex = ds.lenderPutOrder[_lender].length - 1;
        if (lastIndex != _index) {
            address lastAddr = ds.lenderPutOrder[_lender][lastIndex];
            ds.borrowerPutOrder[lastAddr].index = _index;
            ds.lenderPutOrder[_lender][_index] = lastAddr;
        }
        ds.lenderPutOrder[_lender].pop();
    }

    function getLeverageOrderByOrderId(
        uint256 orderId
    ) external view returns (LeveragePutOrder memory) {
        Leverage storage ds = diamondStorage();
        return ds.leverageOrder[orderId];
    }

    function setLeverageOrderByOrderId(
        uint256 orderId,
        LeveragePutOrder memory _order
    ) external {
        Leverage storage ds = diamondStorage();
        ds.leverageOrder[orderId] = _order;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface ILeverageFacet {
    struct LeveragePutOrder {
        uint256 orderId;
        uint256 startDate;
        uint256 expirationDate;
        address lender;
        address borrower;
        address recipient;
        address collateralAsset;
        uint256 collateralAmount;
        address borrowAsset;
        uint256 borrowAmount;
        uint256 lockedCollateralAmount;
        uint256 debtAmount;
        uint256 pledgeCount;
        uint256 slippage;
        uint256 ltv;
        uint256 platformFeeAmount;
        uint256 tradeFeeAmount;
        uint256 loanFeeAmount;
        uint256 platformFeeRate;
        uint256 tradeFeeRate;
        uint256 interest;
        uint256 index;
    }
    struct LeveragePutLenderData {
        address lender;
        address collateralAsset;
        address borrowAsset;
        uint256 minCollateraAmount;
        uint256 maxCollateraAmount;
        uint256 ltv;
        uint256 interest;
        uint256 slippage;
        uint256 pledgeCount;
        uint256 startDate;
        uint256 expirationDate;
        uint256 platformFeeRate;
        uint256 tradeFeeRate;
    }
    struct FeeData {
        uint collateralAmount;
        uint interestAmount;
        uint tradeFeeAmount;
        uint borrowAmount;
        uint debtAmount;
        uint lockedCollateralAmount;
    }
    event SetLendFeePlatformRecipient(address _recipient);

    function getPriceOracle() external view returns (address);

    function setWhiteList(address _user, bool _type) external;

    function getWhiteList(address _user) external view returns (bool);

    function setLeverageBorrowerPutOrder(
        address _borrower,
        LeveragePutOrder memory _putOrder
    ) external;

    function deleteLeverageBorrowerPutOrder(address _borrower) external;

    function getLeverageBorrowerPutOrder(
        address _borrower
    ) external view returns (LeveragePutOrder memory);

    function setLeverageLenderPutOrder(
        address _lender,
        address _borrower
    ) external;

    function getLeverageLenderPutOrder(
        address _lender
    ) external view returns (address[] memory);

    function getLeverageLenderPutOrderLength(
        address _lender
    ) external view returns (uint256);

    function deleteLeverageLenderPutOrder(
        address _lender,
        uint256 _index
    ) external;

    function setLeverageOrderByOrderId(
        uint256 orderId,
        LeveragePutOrder memory _order
    ) external;

    function getLeverageOrderByOrderId(
        uint256 orderId
    ) external view returns (LeveragePutOrder memory);

    function setLeverageFeeData(uint _orderID, FeeData memory _data) external;

    function deleteLeverageFeeData(uint _orderID) external;

    function getLeverageFeeData(
        uint _orderID
    ) external view returns (FeeData memory);

    function setBorrowSignature(bytes memory _sign) external;

    function getBorrowSignature(
        bytes memory _sign
    ) external view returns (bool);

    function setleverageLendPlatformFeeRecipient(address _addr) external;

    function getleverageLendPlatformFeeRecipient()
        external
        view
        returns (address);
}