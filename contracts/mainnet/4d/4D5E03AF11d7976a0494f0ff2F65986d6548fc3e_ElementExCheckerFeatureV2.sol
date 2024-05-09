// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IElementExCheckerFeatureV2.sol";
import "../../libs/LibAssetHelper.sol";

interface IERC721OrdersFeature {
    function validateERC721BuyOrderSignature(LibNFTOrder.NFTBuyOrder calldata order, LibSignature.Signature calldata signature, bytes calldata takerData) external view;
    function getERC721BuyOrderInfo(LibNFTOrder.NFTBuyOrder calldata order) external view returns (LibNFTOrder.OrderInfo memory);
    function getERC721OrderStatusBitVector(address maker, uint248 nonceRange) external view returns (uint256);
    function getHashNonce(address maker) external view returns (uint256);
}

interface IERC1155OrdersFeature {
    function validateERC1155BuyOrderSignature(LibNFTOrder.ERC1155BuyOrder calldata order, LibSignature.Signature calldata signature, bytes calldata takerData) external view;
    function getERC1155BuyOrderInfo(LibNFTOrder.ERC1155BuyOrder calldata order) external view returns (LibNFTOrder.OrderInfo memory orderInfo);
    function getERC1155OrderNonceStatusBitVector(address maker, uint248 nonceRange) external view returns (uint256);
}

contract ElementExCheckerFeatureV2 is IElementExCheckerFeatureV2, LibAssetHelper {

    address public immutable ELEMENT_EX;

    constructor(address elementEx) {
        ELEMENT_EX = elementEx;
    }

    function checkERC721BuyOrderV2(
        LibNFTOrder.NFTBuyOrder memory order,
        LibSignature.Signature memory signature,
        bytes memory data
    ) external override view returns (
        BuyOrderCheckInfo memory info,
        bool validSignature
    ) {
        info.nonceCheck = !isERC721OrderNonceFilled(order.maker, order.nonce);
        info.propertiesCheck = checkProperties(order.expiry >> 252 == 8, order.nftProperties, order.nftId);
        _checkBuyOrder(order, getERC721BuyOrderInfo(order), info);

        validSignature = validateERC721BuyOrderSignatureV2(order, signature, data);
        return (info, validSignature);
    }

    function checkERC1155BuyOrderV2(
        LibNFTOrder.ERC1155BuyOrder memory order,
        LibSignature.Signature memory signature,
        bytes memory data
    ) external override view returns (
        BuyOrderCheckInfo memory info,
        bool validSignature
    ) {
        info.nonceCheck = !isERC1155OrderNonceCancelled(order.maker, order.nonce);
        info.propertiesCheck = checkProperties(false, order.erc1155TokenProperties, order.erc1155TokenId);

        LibNFTOrder.NFTBuyOrder memory nftOrder;
        assembly { nftOrder := order }
        _checkBuyOrder(nftOrder, getERC1155BuyOrderInfo(order), info);

        validSignature = validateERC1155BuyOrderSignatureV2(order, signature, data);
        return (info, validSignature);
    }

    function _checkBuyOrder(
        LibNFTOrder.NFTBuyOrder memory order,
        LibNFTOrder.OrderInfo memory orderInfo,
        BuyOrderCheckInfo memory info
    ) internal view {
        info.hashNonce = getHashNonce(order.maker);
        info.orderHash = orderInfo.orderHash;
        info.orderAmount = orderInfo.orderAmount;
        info.remainingAmount = orderInfo.remainingAmount;
        info.remainingAmountCheck = (info.remainingAmount > 0);

        info.makerCheck = (order.maker != address(0));
        info.takerCheck = (order.taker != ELEMENT_EX);
        info.listingTimeCheck = checkListingTime(order.expiry);
        info.expireTimeCheck = checkExpiryTime(order.expiry);
        info.feesCheck = checkFees(order.fees);

        info.erc20AddressCheck = checkERC20Address(address(order.erc20Token));
        info.erc20TotalAmount = calcERC20TotalAmount(order.erc20TokenAmount, order.fees);

        (
            info.erc20BalanceCheck,
            info.erc20Balance
        ) = checkERC20Balance(order.maker, address(order.erc20Token), info.erc20TotalAmount);

        (
            info.erc20AllowanceCheck,
            info.erc20Allowance
        ) = checkERC20Allowance(order.maker, address(order.erc20Token), info.erc20TotalAmount);

        info.success = (
            info.makerCheck &&
            info.takerCheck &&
            info.listingTimeCheck &&
            info.expireTimeCheck &&
            info.nonceCheck &&
            info.remainingAmountCheck &&
            info.feesCheck &&
            info.propertiesCheck &&
            info.erc20AddressCheck &&
            info.erc20BalanceCheck &&
            info.erc20AllowanceCheck
        );
    }

    function validateERC721BuyOrderSignatureV2(
        LibNFTOrder.NFTBuyOrder memory order,
        LibSignature.Signature memory signature,
        bytes memory data
    ) public override view returns (bool valid) {
        try IERC721OrdersFeature(ELEMENT_EX).validateERC721BuyOrderSignature(order, signature, data) {
            return true;
        } catch {}
        return false;
    }

    function validateERC1155BuyOrderSignatureV2(
        LibNFTOrder.ERC1155BuyOrder memory order,
        LibSignature.Signature memory signature,
        bytes memory data
    ) public override view returns (bool valid) {
        try IERC1155OrdersFeature(ELEMENT_EX).validateERC1155BuyOrderSignature(order, signature, data) {
            return true;
        } catch {}
        return false;
    }

    function getERC721BuyOrderInfo(
        LibNFTOrder.NFTBuyOrder memory order
    ) public override view returns (
        LibNFTOrder.OrderInfo memory orderInfo
    ) {
        try IERC721OrdersFeature(ELEMENT_EX).getERC721BuyOrderInfo(order) returns (LibNFTOrder.OrderInfo memory _orderInfo) {
            orderInfo = _orderInfo;
        } catch {}
        return orderInfo;
    }

    function getERC1155BuyOrderInfo(
        LibNFTOrder.ERC1155BuyOrder memory order
    ) internal view returns (
        LibNFTOrder.OrderInfo memory orderInfo
    ) {
        try IERC1155OrdersFeature(ELEMENT_EX).getERC1155BuyOrderInfo(order) returns (LibNFTOrder.OrderInfo memory _orderInfo) {
            orderInfo = _orderInfo;
        } catch {}
        return orderInfo;
    }

    function isERC721OrderNonceFilled(address account, uint256 nonce) internal view returns (bool filled) {
        uint256 bitVector = IERC721OrdersFeature(ELEMENT_EX).getERC721OrderStatusBitVector(account, uint248(nonce >> 8));
        uint256 flag = 1 << (nonce & 0xff);
        return (bitVector & flag) != 0;
    }

    function isERC1155OrderNonceCancelled(address account, uint256 nonce) internal view returns (bool filled) {
        uint256 bitVector = IERC1155OrdersFeature(ELEMENT_EX).getERC1155OrderNonceStatusBitVector(account, uint248(nonce >> 8));
        uint256 flag = 1 << (nonce & 0xff);
        return (bitVector & flag) != 0;
    }

    function getHashNonce(address maker) internal view returns (uint256) {
        return IERC721OrdersFeature(ELEMENT_EX).getHashNonce(maker);
    }

    function checkListingTime(uint256 expiry) internal pure returns (bool success) {
        uint256 listingTime = (expiry >> 32) & 0xffffffff;
        uint256 expiryTime = expiry & 0xffffffff;
        return listingTime < expiryTime;
    }

    function checkExpiryTime(uint256 expiry) internal view returns (bool success) {
        uint256 expiryTime = expiry & 0xffffffff;
        return expiryTime > block.timestamp;
    }

    function checkERC20Balance(address buyer, address erc20, uint256 erc20TotalAmount)
        internal
        view
        returns
        (bool success, uint256 balance)
    {
        if (erc20 == address(0) || erc20 == NATIVE_TOKEN_ADDRESS) {
            return (false, 0);
        }
        balance = _erc20BalanceOf(erc20, buyer);
        success = (balance >= erc20TotalAmount);
        return (success, balance);
    }

    function checkERC20Allowance(address buyer, address erc20, uint256 erc20TotalAmount)
        internal
        view
        returns
        (bool success, uint256 allowance)
    {
        if (erc20 == address(0) || erc20 == NATIVE_TOKEN_ADDRESS) {
            return (false, 0);
        }
        allowance = _erc20Allowance(erc20, buyer, ELEMENT_EX);
        success = (allowance >= erc20TotalAmount);
        return (success, allowance);
    }

    function checkERC20Address(address erc20) internal view returns (bool) {
        if (erc20 != address(0) && erc20 != NATIVE_TOKEN_ADDRESS) {
            return isContract(erc20);
        }
        return false;
    }

    function checkFees(LibNFTOrder.Fee[] memory fees) internal view returns (bool success) {
        for (uint256 i = 0; i < fees.length; i++) {
            if (fees[i].recipient == ELEMENT_EX) {
                return false;
            }
            if (fees[i].feeData.length > 0 && !isContract(fees[i].recipient)) {
                return false;
            }
        }
        return true;
    }

    function checkProperties(bool isOfferMultiERC721s, LibNFTOrder.Property[] memory properties, uint256 nftId) internal view returns (bool success) {
        if (isOfferMultiERC721s) {
            if (properties.length == 0) {
                return false;
            }
        }
        if (properties.length > 0) {
            if (nftId != 0) {
                return false;
            }
            for (uint256 i = 0; i < properties.length; i++) {
                address propertyValidator = address(properties[i].propertyValidator);
                if (propertyValidator != address(0) && !isContract(propertyValidator)) {
                    return false;
                }
            }
        }
        return true;
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function calcERC20TotalAmount(uint256 erc20TokenAmount, LibNFTOrder.Fee[] memory fees) internal pure returns (uint256) {
        uint256 sum = erc20TokenAmount;
        for (uint256 i = 0; i < fees.length; i++) {
            sum += fees[i].amount;
        }
        return sum;
    }
}

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./LibStructure.sol";

interface IElementExCheckerFeatureV2 {

    struct BuyOrderCheckInfo {
        bool success;               // 所有的检查通过时为true，只要有一项检查未通过时为false
        uint256 hashNonce;
        bytes32 orderHash;
        bool makerCheck;            // check `maker != address(0)`
        bool takerCheck;            // check `taker != ElementEx`
        bool listingTimeCheck;      // check `listingTime < expireTime`
        bool expireTimeCheck;       // check `expireTime > block.timestamp`
        bool nonceCheck;            // 检查订单nonce
        uint256 orderAmount;        // offer的Nft资产总量
        uint256 remainingAmount;    // remainingAmount返回剩余未成交的数量
        bool remainingAmountCheck;  // check `remainingAmount > 0`
        bool feesCheck;             // fee地址不能是0x地址，并且如果有回调，fee地址必须是合约地址
        bool propertiesCheck;       // 属性检查。若order.erc1155Properties不为空,则`order.erc1155TokenId`必须为0，并且property地址必须是address(0)或合约地址
        bool erc20AddressCheck;     // erc20地址检查。该地址必须为一个合约地址，不能是NATIVE_ADDRESS，不能为address(0)
        uint256 erc20TotalAmount;   // erc20TotalAmount = `order.erc20TokenAmount` + totalFeesAmount
        uint256 erc20Balance;       // 买家ERC20余额
        uint256 erc20Allowance;     // 买家ERC20授权额度
        bool erc20BalanceCheck;     // check `erc20Balance >= erc20TotalAmount`
        bool erc20AllowanceCheck;   // check `erc20AllowanceCheck >= erc20TotalAmount`
    }

    function checkERC721BuyOrderV2(
        LibNFTOrder.NFTBuyOrder calldata order,
        LibSignature.Signature calldata signature,
        bytes calldata data
    ) external view returns (
        BuyOrderCheckInfo memory info,
        bool validSignature
    );

    function checkERC1155BuyOrderV2(
        LibNFTOrder.ERC1155BuyOrder calldata order,
        LibSignature.Signature calldata signature,
        bytes calldata data
    ) external view returns (
        BuyOrderCheckInfo memory info,
        bool validSignature
    );

    function getERC721BuyOrderInfo(
        LibNFTOrder.NFTBuyOrder calldata order
    ) external view returns (
        LibNFTOrder.OrderInfo memory orderInfo
    );

    function validateERC721BuyOrderSignatureV2(
        LibNFTOrder.NFTBuyOrder calldata order,
        LibSignature.Signature calldata signature,
        bytes calldata data
    ) external view returns (bool valid);

    function validateERC1155BuyOrderSignatureV2(
        LibNFTOrder.ERC1155BuyOrder calldata order,
        LibSignature.Signature calldata signature,
        bytes calldata data
    ) external view returns (bool valid);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IPropertyValidator {
    function validateProperty(
        address tokenAddress,
        uint256 tokenId,
        bytes32 orderHash,
        bytes calldata propertyData,
        bytes calldata takerData
    ) external view returns(bytes4);
}

library LibSignature {

    enum SignatureType {
        EIP712,     // 0
        PRESIGNED,  // 1
        EIP712_BULK,// 2
        EIP712_1271,// 3
        EIP712_BULK_1271,   // 4
        ETHEREUM_PERSONAL_SIGN_1271,     // 5
        ETHEREUM_PERSONAL_SIGN_BULK_1271,// 6
        BITCOIN_PERSONAL_SIGN_1271,      // 7
        BITCOIN_PERSONAL_SIGN_BULK_1271, // 8
        BITCOIN_PERSONAL_SIGN_173,       // 9
        BITCOIN_PERSONAL_SIGN_BULK_173   // 10
    }

    struct Signature {
        // How to validate the signature.
        uint8 signatureType;
        // EC Signature data.
        uint8 v;
        // EC Signature data.
        bytes32 r;
        // EC Signature data.
        bytes32 s;
    }
}

library LibNFTOrder {

    enum OrderStatus {
        INVALID,
        FILLABLE,
        UNFILLABLE,
        EXPIRED
    }

    struct Property {
        IPropertyValidator propertyValidator;
        bytes propertyData;
    }

    struct Fee {
        address recipient;
        uint256 amount;
        bytes feeData;
    }

    struct NFTSellOrder {
        address maker;
        address taker;
        uint256 expiry;
        uint256 nonce;
        IERC20 erc20Token;
        uint256 erc20TokenAmount;
        Fee[] fees;
        address nft;
        uint256 nftId;
    }

    // All fields except `nftProperties` align
    // with those of NFTSellOrder
    struct NFTBuyOrder {
        address maker;
        address taker;
        uint256 expiry;
        uint256 nonce;
        IERC20 erc20Token;
        uint256 erc20TokenAmount;
        Fee[] fees;
        address nft;
        uint256 nftId;
        Property[] nftProperties;
    }

    // All fields except `erc1155TokenAmount` align
    // with those of NFTSellOrder
    struct ERC1155SellOrder {
        address maker;
        address taker;
        uint256 expiry;
        uint256 nonce;
        IERC20 erc20Token;
        uint256 erc20TokenAmount;
        Fee[] fees;
        address erc1155Token;
        uint256 erc1155TokenId;
        // End of fields shared with NFTOrder
        uint128 erc1155TokenAmount;
    }

    // All fields except `erc1155TokenAmount` align
    // with those of NFTBuyOrder
    struct ERC1155BuyOrder {
        address maker;
        address taker;
        uint256 expiry;
        uint256 nonce;
        IERC20 erc20Token;
        uint256 erc20TokenAmount;
        Fee[] fees;
        address erc1155Token;
        uint256 erc1155TokenId;
        Property[] erc1155TokenProperties;
        // End of fields shared with NFTOrder
        uint128 erc1155TokenAmount;
    }

    struct OrderInfo {
        bytes32 orderHash;
        OrderStatus status;
        // `orderAmount` is 1 for all ERC721Orders, and
        // `erc1155TokenAmount` for ERC1155Orders.
        uint128 orderAmount;
        // The remaining amount of the ERC721/ERC1155 asset
        // that can be filled for the order.
        uint128 remainingAmount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


abstract contract LibAssetHelper {

    address internal constant NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 internal constant ERC404_APPROVAL = 1 << 126;

    function _isApprovedForAll(
        address token,
        bool isERC721,
        address owner,
        address operator
    ) internal view returns(uint256 approval) {
        (approval, ) = _isApprovedForAllV2(token, isERC721, owner, operator);
    }

    function _isApprovedForAllV2(
        address token,
        bool isERC721,
        address owner,
        address operator
    ) internal view returns(uint256 approval, bool isERC404) {
        if (token == address(0) || token == NATIVE_TOKEN_ADDRESS) {
            return (0, false);
        }

        bool isApprovedForAll;
        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for `isApprovedForAll(address,address)`
            mstore(ptr, 0xe985e9c500000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x4), owner)
            mstore(add(ptr, 0x24), operator)

            if staticcall(gas(), token, ptr, 0x44, ptr, 0x20) {
                if gt(mload(ptr), 0) {
                    isApprovedForAll := 1
                }
            }
        }
        if (isApprovedForAll) {
            return (1, false);
        }
//        if (isERC721) {
//            if (_erc20Decimals(token) == 0) {
//                return (0, false);
//            }
//            (uint256 allowance, bool success) = _erc20AllowanceV2(token, owner, operator);
//            approval = allowance > ERC404_APPROVAL ? 1 : 0;
//            isERC404 = success;
//            return (approval, isERC404);
//        } else {
//            return (0, false);
//        }
        return (0, false);
    }

    function _erc721OwnerOf(
        address token, uint256 tokenId
    ) internal view returns (address owner) {
        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for `ownerOf(uint256)`
            mstore(ptr, 0x6352211e00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x4), tokenId)

            if staticcall(gas(), token, ptr, 0x24, ptr, 0x20) {
                if lt(mload(ptr), shl(160, 1)) {
                    owner := mload(ptr)
                }
            }
        }
        return owner;
    }

    function _erc721GetApproved(
        address token, uint256 tokenId
    ) internal view returns (address operator) {
        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for `getApproved(uint256)`
            mstore(ptr, 0x081812fc00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x4), tokenId)

            if staticcall(gas(), token, ptr, 0x24, ptr, 0x20) {
                if lt(mload(ptr), shl(160, 1)) {
                    operator := mload(ptr)
                }
            }
        }
        return operator;
    }

    function _erc1155BalanceOf(
        address token,
        address account,
        uint256 tokenId
    ) internal view returns (uint256 _balance) {
        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for `balanceOf(address,uint256)`
            mstore(ptr, 0x00fdd58e00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x4), account)
            mstore(add(ptr, 0x24), tokenId)

            if staticcall(gas(), token, ptr, 0x44, ptr, 0x20) {
                _balance := mload(ptr)
            }
        }
        return _balance;
    }

    function _erc20BalanceOf(
        address token, address account
    ) internal view returns (uint256 _balance) {
        if (token == address(0) || token == NATIVE_TOKEN_ADDRESS) {
            return account.balance;
        }
        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for `balanceOf(address)`
            mstore(ptr, 0x70a0823100000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x4), account)

            if staticcall(gas(), token, ptr, 0x24, ptr, 0x20) {
                _balance := mload(ptr)
            }
        }
        return _balance;
    }

    function _erc20Allowance(
        address token,
        address owner,
        address spender
    ) internal view returns (uint256 allowance) {
        (allowance, ) = _erc20AllowanceV2(token, owner, spender);
    }

    function _erc20AllowanceV2(
        address token,
        address owner,
        address spender
    ) internal view returns (uint256 allowance, bool callSuccess) {
        if (token == address(0) || token == NATIVE_TOKEN_ADDRESS) {
            return (type(uint256).max, false);
        }
        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for `allowance(address,address)`
            mstore(ptr, 0xdd62ed3e00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x4), owner)
            mstore(add(ptr, 0x24), spender)

            if staticcall(gas(), token, ptr, 0x44, ptr, 0x20) {
                allowance := mload(ptr)
                callSuccess := 1
            }
        }
        return (allowance, callSuccess);
    }

    function _erc20Decimals(address token) internal view returns (uint8 decimals) {
        if (token == address(0) || token == NATIVE_TOKEN_ADDRESS) {
            return 18;
        }
        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for `decimals()`
            mstore(ptr, 0x313ce56700000000000000000000000000000000000000000000000000000000)

            if staticcall(gas(), token, ptr, 0x4, ptr, 0x20) {
                if lt(mload(ptr), 48) {
                    decimals := mload(ptr)
                }
            }
        }
        return decimals;
    }
}