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

/// SPDX-License-Identifier: MIT


pragma solidity ^0.8.15;

import "./IElementExCheckerFeature.sol";
import "../../libs/LibAssetHelper.sol";

interface IERC721OrdersFeature {
    function validateERC721SellOrderSignature(LibNFTOrder.NFTSellOrder calldata order, LibSignature.Signature calldata signature) external view;
    function validateERC721BuyOrderSignature(LibNFTOrder.NFTBuyOrder calldata order, LibSignature.Signature calldata signature) external view;
    function getERC721SellOrderHash(LibNFTOrder.NFTSellOrder calldata order) external view returns (bytes32);
    function getERC721BuyOrderHash(LibNFTOrder.NFTBuyOrder calldata order) external view returns (bytes32);
    function getERC721OrderStatusBitVector(address maker, uint248 nonceRange) external view returns (uint256);
    function getHashNonce(address maker) external view returns (uint256);
}

interface IERC1155OrdersFeature {
    function validateERC1155SellOrderSignature(LibNFTOrder.ERC1155SellOrder calldata order, LibSignature.Signature calldata signature) external view;
    function validateERC1155BuyOrderSignature(LibNFTOrder.ERC1155BuyOrder calldata order, LibSignature.Signature calldata signature) external view;
    function getERC1155SellOrderInfo(LibNFTOrder.ERC1155SellOrder calldata order) external view returns (LibNFTOrder.OrderInfo memory orderInfo);
    function getERC1155BuyOrderInfo(LibNFTOrder.ERC1155BuyOrder calldata order) external view returns (LibNFTOrder.OrderInfo memory orderInfo);
    function getERC1155OrderNonceStatusBitVector(address maker, uint248 nonceRange) external view returns (uint256);
}

contract ElementExCheckerFeature is IElementExCheckerFeature, LibAssetHelper {

    address public immutable ELEMENT_EX;

    constructor(address elementEx) {
        ELEMENT_EX = elementEx;
    }

    function checkERC721SellOrder(LibNFTOrder.NFTSellOrder calldata order, address taker)
        public
        override
        view
        returns (ERC721SellOrderCheckInfo memory info, ERC20CheckInfo memory takerCheckInfo)
    {
        info.hashNonce = getHashNonce(order.maker);
        info.orderHash = getERC721SellOrderHash(order);
        info.makerCheck = (order.maker != address(0));
        info.takerCheck = (order.taker != ELEMENT_EX);
        info.listingTimeCheck = checkListingTime(order.expiry);
        info.expireTimeCheck = checkExpiryTime(order.expiry);
        info.extraCheck = checkExtra(order.expiry);
        info.nonceCheck = !isERC721OrderNonceFilled(order.maker, order.nonce);
        info.feesCheck = checkFees(order.fees);
        info.erc20TotalAmount = calcERC20TotalAmount(order.erc20TokenAmount, order.fees);
        info.erc721OwnerCheck = checkERC721Owner(order.nft, order.nftId, order.maker);
        info.erc721ApprovedCheck = checkERC721Approved(order.nft, order.nftId, order.maker);
        info.erc20AddressCheck = checkERC20Address(true, address(order.erc20Token));
        info.erc721AddressCheck = checkERC721Address(order.nft);
        info.success = _isERC721SellOrderSuccess(info);

        if (taker != address(0)) {
            takerCheckInfo.listingTimeCheck = (block.timestamp >= ((order.expiry >> 32) & 0xffffffff));
            takerCheckInfo.takerCheck = (order.taker == taker || order.taker == address(0));
            (takerCheckInfo.balanceCheck, takerCheckInfo.balance) =
                checkERC20Balance(true, taker, address(order.erc20Token), info.erc20TotalAmount);
            (takerCheckInfo.allowanceCheck, takerCheckInfo.allowance) =
                checkERC20Allowance(true, taker, address(order.erc20Token), info.erc20TotalAmount);
        }
        return (info, takerCheckInfo);
    }

    function checkERC721SellOrderEx(
        LibNFTOrder.NFTSellOrder calldata order,
        address taker,
        LibSignature.Signature calldata signature
    )
        public
        override
        view
        returns (ERC721SellOrderCheckInfo memory info, ERC20CheckInfo memory takerCheckInfo, bool validSignature)
    {
        (info, takerCheckInfo) = checkERC721SellOrder(order, taker);
        validSignature = validateERC721SellOrderSignature(order, signature);
        return (info, takerCheckInfo, validSignature);
    }

    function checkERC721BuyOrder(LibNFTOrder.NFTBuyOrder calldata order, address taker, uint256 erc721TokenId)
        public
        view
        returns (ERC721BuyOrderCheckInfo memory info, ERC721CheckInfo memory takerCheckInfo)
    {
        info.hashNonce = getHashNonce(order.maker);
        info.orderHash = getERC721BuyOrderHash(order);
        info.makerCheck = (order.maker != address(0));
        info.takerCheck = (order.taker != ELEMENT_EX);
        info.listingTimeCheck = checkListingTime(order.expiry);
        info.expireTimeCheck = checkExpiryTime(order.expiry);
        info.nonceCheck = !isERC721OrderNonceFilled(order.maker, order.nonce);
        info.feesCheck = checkFees(order.fees);
        info.propertiesCheck = checkProperties(order.nftProperties, order.nftId);
        info.erc20AddressCheck = checkERC20Address(false, address(order.erc20Token));
        info.erc721AddressCheck = checkERC721Address(order.nft);

        info.erc20TotalAmount = calcERC20TotalAmount(order.erc20TokenAmount, order.fees);
        (info.erc20BalanceCheck, info.erc20Balance) =
            checkERC20Balance(false, order.maker, address(order.erc20Token), info.erc20TotalAmount);
        (info.erc20AllowanceCheck, info.erc20Allowance) =
            checkERC20Allowance(false, order.maker, address(order.erc20Token), info.erc20TotalAmount);
        info.success = _isERC721BuyOrderSuccess(info);

        if (taker != address(0)) {
            takerCheckInfo.listingTimeCheck = (block.timestamp >= ((order.expiry >> 32) & 0xffffffff));
            takerCheckInfo.takerCheck = (order.taker == taker || order.taker == address(0));
            takerCheckInfo.ecr721TokenIdCheck = checkNftIdIsMatched(order.nftProperties, order.nft, order.nftId, erc721TokenId);
            takerCheckInfo.erc721OwnerCheck = checkERC721Owner(order.nft, erc721TokenId, taker);
            takerCheckInfo.erc721ApprovedCheck = checkERC721Approved(order.nft, erc721TokenId, taker);
        }
        return (info, takerCheckInfo);
    }

    function checkERC721BuyOrderEx(
        LibNFTOrder.NFTBuyOrder calldata order,
        address taker,
        uint256 erc721TokenId,
        LibSignature.Signature calldata signature
    )
        public
        override
        view
        returns (ERC721BuyOrderCheckInfo memory info, ERC721CheckInfo memory takerCheckInfo, bool validSignature)
    {
        (info, takerCheckInfo) = checkERC721BuyOrder(order, taker, erc721TokenId);
        validSignature = validateERC721BuyOrderSignature(order, signature);
        return (info, takerCheckInfo, validSignature);
    }

    function checkERC1155SellOrder(LibNFTOrder.ERC1155SellOrder calldata order, address taker, uint128 erc1155BuyAmount)
        public
        override
        view
        returns (ERC1155SellOrderCheckInfo memory info, ERC1155SellOrderTakerCheckInfo memory takerCheckInfo)
    {
        LibNFTOrder.OrderInfo memory orderInfo = getERC1155SellOrderInfo(order);
        (uint256 balance, bool isApprovedForAll) = getERC1155Info(order.erc1155Token, order.erc1155TokenId, order.maker, ELEMENT_EX);

        info.hashNonce = getHashNonce(order.maker);
        info.orderHash = orderInfo.orderHash;
        info.erc1155RemainingAmount = orderInfo.remainingAmount;
        info.erc1155Balance = balance;
        info.makerCheck = (order.maker != address(0));
        info.takerCheck = (order.taker != ELEMENT_EX);
        info.listingTimeCheck = checkListingTime(order.expiry);
        info.expireTimeCheck = checkExpiryTime(order.expiry);
        info.extraCheck = checkExtra(order.expiry);
        info.nonceCheck = !isERC1155OrderNonceCancelled(order.maker, order.nonce);
        info.remainingAmountCheck = (info.erc1155RemainingAmount > 0);
        info.feesCheck = checkFees(order.fees);
        info.erc20TotalAmount = calcERC20TotalAmount(order.erc20TokenAmount, order.fees);
        info.erc1155BalanceCheck = (balance >= order.erc1155TokenAmount);
        info.erc1155ApprovedCheck = isApprovedForAll;
        info.erc20AddressCheck = checkERC20Address(true, address(order.erc20Token));
        info.erc1155AddressCheck = checkERC1155Address(order.erc1155Token);
        info.success = _isERC1155SellOrderSuccess(info);

        if (taker != address(0)) {
            if (order.erc1155TokenAmount > 0) {
                takerCheckInfo.erc20WillPayAmount = _ceilDiv(order.erc20TokenAmount * erc1155BuyAmount, order.erc1155TokenAmount);
                for (uint256 i = 0; i < order.fees.length; i++) {
                    takerCheckInfo.erc20WillPayAmount += order.fees[i].amount * erc1155BuyAmount / order.erc1155TokenAmount;
                }
            } else {
                takerCheckInfo.erc20WillPayAmount = type(uint128).max;
            }
            (takerCheckInfo.balanceCheck, takerCheckInfo.erc20Balance) = checkERC20Balance(true, taker, address(order.erc20Token), takerCheckInfo.erc20WillPayAmount);
            (takerCheckInfo.allowanceCheck, takerCheckInfo.erc20Allowance) = checkERC20Allowance(true, taker, address(order.erc20Token), takerCheckInfo.erc20WillPayAmount);
            takerCheckInfo.buyAmountCheck = (erc1155BuyAmount <= info.erc1155RemainingAmount);
            takerCheckInfo.listingTimeCheck = (block.timestamp >= ((order.expiry >> 32) & 0xffffffff));
            takerCheckInfo.takerCheck = (order.taker == taker || order.taker == address(0));
        }
        return (info, takerCheckInfo);
    }

    function checkERC1155SellOrderEx(
        LibNFTOrder.ERC1155SellOrder calldata order,
        address taker,
        uint128 erc1155BuyAmount,
        LibSignature.Signature calldata signature
    )
        public
        override
        view
        returns (ERC1155SellOrderCheckInfo memory info, ERC1155SellOrderTakerCheckInfo memory takerCheckInfo, bool validSignature)
    {
        (info, takerCheckInfo) = checkERC1155SellOrder(order, taker, erc1155BuyAmount);
        validSignature = validateERC1155SellOrderSignature(order, signature);
        return (info, takerCheckInfo, validSignature);
    }

    function checkERC1155BuyOrder(
        LibNFTOrder.ERC1155BuyOrder calldata order,
        address taker,
        uint256 erc1155TokenId,
        uint128 erc1155SellAmount
    )
        public
        override
        view
        returns (ERC1155BuyOrderCheckInfo memory info, ERC1155BuyOrderTakerCheckInfo memory takerCheckInfo)
    {
        LibNFTOrder.OrderInfo memory orderInfo = getERC1155BuyOrderInfo(order);
        info.hashNonce = getHashNonce(order.maker);
        info.orderHash = orderInfo.orderHash;
        info.erc1155RemainingAmount = orderInfo.remainingAmount;
        info.makerCheck = (order.maker != address(0));
        info.takerCheck = (order.taker != ELEMENT_EX);
        info.listingTimeCheck = checkListingTime(order.expiry);
        info.expireTimeCheck = checkExpiryTime(order.expiry);
        info.nonceCheck = !isERC1155OrderNonceCancelled(order.maker, order.nonce);
        info.remainingAmountCheck = (info.erc1155RemainingAmount > 0);
        info.feesCheck = checkFees(order.fees);
        info.propertiesCheck = checkProperties(order.erc1155TokenProperties, order.erc1155TokenId);
        info.erc20AddressCheck = checkERC20Address(false, address(order.erc20Token));
        info.erc1155AddressCheck = checkERC1155Address(order.erc1155Token);
        info.erc20TotalAmount = calcERC20TotalAmount(order.erc20TokenAmount, order.fees);
        (info.erc20BalanceCheck, info.erc20Balance) = checkERC20Balance(false, order.maker, address(order.erc20Token), info.erc20TotalAmount);
        (info.erc20AllowanceCheck, info.erc20Allowance) = checkERC20Allowance(false, order.maker, address(order.erc20Token), info.erc20TotalAmount);
        info.success = _isERC1155BuyOrderSuccess(info);

        if (taker != address(0)) {
            takerCheckInfo.ecr1155TokenIdCheck = checkNftIdIsMatched(order.erc1155TokenProperties, order.erc1155Token, order.erc1155TokenId, erc1155TokenId);
            (takerCheckInfo.erc1155Balance, takerCheckInfo.erc1155ApprovedCheck) = getERC1155Info(order.erc1155Token, erc1155TokenId, taker, ELEMENT_EX);
            takerCheckInfo.erc1155BalanceCheck = (erc1155SellAmount <= takerCheckInfo.erc1155Balance);
            takerCheckInfo.sellAmountCheck = (erc1155SellAmount <= info.erc1155RemainingAmount);
            takerCheckInfo.listingTimeCheck = (block.timestamp >= ((order.expiry >> 32) & 0xffffffff));
            takerCheckInfo.takerCheck = (order.taker == taker || order.taker == address(0));
        }
        return (info, takerCheckInfo);
    }

    function checkERC1155BuyOrderEx(
        LibNFTOrder.ERC1155BuyOrder calldata order,
        address taker,
        uint256 erc1155TokenId,
        uint128 erc1155SellAmount,
        LibSignature.Signature calldata signature
    )
        public
        override
        view
        returns (ERC1155BuyOrderCheckInfo memory info, ERC1155BuyOrderTakerCheckInfo memory takerCheckInfo, bool validSignature)
    {
        (info, takerCheckInfo) = checkERC1155BuyOrder(order, taker, erc1155TokenId, erc1155SellAmount);
        validSignature = validateERC1155BuyOrderSignature(order, signature);
        return (info, takerCheckInfo, validSignature);
    }

    function getERC1155Info(address erc1155, uint256 tokenId, address account, address approvedAddress)
        internal
        view
        returns (uint256 balance, bool isApprovedForAll)
    {
        balance = _erc1155BalanceOf(erc1155, account, tokenId);
        isApprovedForAll = _isApprovedForAll(erc1155, false, account, approvedAddress) > 0;
        return (balance, isApprovedForAll);
    }

    function validateERC721SellOrderSignature(LibNFTOrder.NFTSellOrder calldata order, LibSignature.Signature calldata signature)
        public
        override
        view
        returns (bool valid)
    {
        try IERC721OrdersFeature(ELEMENT_EX).validateERC721SellOrderSignature(order, signature) {
            return true;
        } catch {}
        return false;
    }

    function validateERC721BuyOrderSignature(LibNFTOrder.NFTBuyOrder calldata order, LibSignature.Signature calldata signature)
        public
        override
        view
        returns (bool valid)
    {
        try IERC721OrdersFeature(ELEMENT_EX).validateERC721BuyOrderSignature(order, signature) {
            return true;
        } catch {}
        return false;
    }

    function getERC721SellOrderHash(LibNFTOrder.NFTSellOrder calldata order) public override view returns (bytes32) {
        try IERC721OrdersFeature(ELEMENT_EX).getERC721SellOrderHash(order) returns (bytes32 orderHash) {
            return orderHash;
        } catch {}
        return bytes32("");
    }

    function getERC721BuyOrderHash(LibNFTOrder.NFTBuyOrder calldata order) public override view returns (bytes32) {
        try IERC721OrdersFeature(ELEMENT_EX).getERC721BuyOrderHash(order) returns (bytes32 orderHash) {
            return orderHash;
        } catch {}
        return bytes32("");
    }

    function isERC721OrderNonceFilled(address account, uint256 nonce) public override view returns (bool filled) {
        uint256 bitVector = IERC721OrdersFeature(ELEMENT_EX).getERC721OrderStatusBitVector(account, uint248(nonce >> 8));
        uint256 flag = 1 << (nonce & 0xff);
        return (bitVector & flag) != 0;
    }

    function isERC1155OrderNonceCancelled(address account, uint256 nonce) public override view returns (bool filled) {
        uint256 bitVector = IERC1155OrdersFeature(ELEMENT_EX).getERC1155OrderNonceStatusBitVector(account, uint248(nonce >> 8));
        uint256 flag = 1 << (nonce & 0xff);
        return (bitVector & flag) != 0;
    }

    function getHashNonce(address maker) public override view returns (uint256) {
        return IERC721OrdersFeature(ELEMENT_EX).getHashNonce(maker);
    }

    function getERC1155SellOrderInfo(LibNFTOrder.ERC1155SellOrder calldata order)
        public
        override
        view
        returns (LibNFTOrder.OrderInfo memory orderInfo)
    {
        try IERC1155OrdersFeature(ELEMENT_EX).getERC1155SellOrderInfo(order) returns (LibNFTOrder.OrderInfo memory _orderInfo) {
            orderInfo = _orderInfo;
        } catch {}
        return orderInfo;
    }

    function getERC1155BuyOrderInfo(LibNFTOrder.ERC1155BuyOrder calldata order)
        public
        override
        view
        returns (LibNFTOrder.OrderInfo memory orderInfo)
    {
        try IERC1155OrdersFeature(ELEMENT_EX).getERC1155BuyOrderInfo(order) returns (LibNFTOrder.OrderInfo memory _orderInfo) {
            orderInfo = _orderInfo;
        } catch {}
        return orderInfo;
    }

    function validateERC1155SellOrderSignature(LibNFTOrder.ERC1155SellOrder calldata order, LibSignature.Signature calldata signature)
        public
        override
        view
        returns (bool valid)
    {
        try IERC1155OrdersFeature(ELEMENT_EX).validateERC1155SellOrderSignature(order, signature) {
            return true;
        } catch {}
        return false;
    }

    function validateERC1155BuyOrderSignature(LibNFTOrder.ERC1155BuyOrder calldata order, LibSignature.Signature calldata signature)
        public
        override
        view
        returns (bool valid)
    {
        try IERC1155OrdersFeature(ELEMENT_EX).validateERC1155BuyOrderSignature(order, signature) {
            return true;
        } catch {}
        return false;
    }

    function _isERC721SellOrderSuccess(ERC721SellOrderCheckInfo memory info) private pure returns (bool successAll) {
        return info.makerCheck &&
            info.takerCheck &&
            info.listingTimeCheck &&
            info.expireTimeCheck &&
            info.extraCheck &&
            info.nonceCheck &&
            info.feesCheck &&
            info.erc721OwnerCheck &&
            info.erc721ApprovedCheck &&
            info.erc20AddressCheck;
    }

    function _isERC721BuyOrderSuccess(ERC721BuyOrderCheckInfo memory info) private pure returns (bool successAll) {
        return info.makerCheck &&
            info.takerCheck &&
            info.listingTimeCheck &&
            info.expireTimeCheck &&
            info.nonceCheck &&
            info.feesCheck &&
            info.propertiesCheck &&
            info.erc20BalanceCheck &&
            info.erc20AllowanceCheck &&
            info.erc20AddressCheck;
    }

    function _isERC1155SellOrderSuccess(ERC1155SellOrderCheckInfo memory info) private pure returns (bool successAll) {
        return info.makerCheck &&
            info.takerCheck &&
            info.listingTimeCheck &&
            info.expireTimeCheck &&
            info.extraCheck &&
            info.nonceCheck &&
            info.remainingAmountCheck &&
            info.feesCheck &&
            info.erc20AddressCheck &&
            info.erc1155BalanceCheck &&
            info.erc1155ApprovedCheck;
    }

    function _isERC1155BuyOrderSuccess(ERC1155BuyOrderCheckInfo memory info) private pure returns (bool successAll) {
        return info.makerCheck &&
            info.takerCheck &&
            info.listingTimeCheck &&
            info.expireTimeCheck &&
            info.nonceCheck &&
            info.remainingAmountCheck &&
            info.feesCheck &&
            info.propertiesCheck &&
            info.erc20AddressCheck &&
            info.erc20BalanceCheck &&
            info.erc20AllowanceCheck;
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

    function checkExtra(uint256 expiry) internal pure returns (bool success) {
        if (expiry >> 252 == 1) {
            uint256 extra = (expiry >> 64) & 0xffffffff;
            return (extra <= 100000000);
        }
        return true;
    }

    function checkERC721Owner(address nft, uint256 nftId, address owner) internal view returns (bool success) {
        return _erc721OwnerOf(nft, nftId) == owner;
    }

    function checkERC721Approved(address nft, uint256 nftId, address owner) internal view returns (bool) {
        if (_isApprovedForAll(nft, true, owner, ELEMENT_EX) > 0) {
            return true;
        }
        return _erc721GetApproved(nft, nftId) == ELEMENT_EX;
    }

    function checkERC20Balance(bool buyNft, address buyer, address erc20, uint256 erc20TotalAmount)
        internal
        view
        returns
        (bool success, uint256 balance)
    {
        if (erc20 == address(0)) {
            return (false, 0);
        }
        if (erc20 == NATIVE_TOKEN_ADDRESS) {
            if (buyNft) {
                balance = buyer.balance;
                success = (balance >= erc20TotalAmount);
                return (success, balance);
            } else {
                return (false, 0);
            }
        }
        balance = _erc20BalanceOf(erc20, buyer);
        success = (balance >= erc20TotalAmount);
        return (success, balance);
    }

    function checkERC20Allowance(bool buyNft, address buyer, address erc20, uint256 erc20TotalAmount)
        internal
        view
        returns
        (bool success, uint256 allowance)
    {
        if (erc20 == address(0)) {
            return (false, 0);
        }
        if (erc20 == NATIVE_TOKEN_ADDRESS) {
            return (buyNft, 0);
        }
        allowance = _erc20Allowance(erc20, buyer, ELEMENT_EX);
        success = (allowance >= erc20TotalAmount);
        return (success, allowance);
    }

    function checkERC20Address(bool sellOrder, address erc20) internal view returns (bool) {
        if (erc20 == address(0)) {
            return false;
        }
        if (erc20 == NATIVE_TOKEN_ADDRESS) {
            return sellOrder;
        }
        return isContract(erc20);
    }

    function checkERC721Address(address erc721) internal view returns (bool) {
        if (erc721 == address(0) || erc721 == NATIVE_TOKEN_ADDRESS) {
            return false;
        }
        return isContract(erc721);
    }

    function checkERC1155Address(address erc1155) internal view returns (bool) {
        if (erc1155 == address(0) || erc1155 == NATIVE_TOKEN_ADDRESS) {
            return false;
        }
        return isContract(erc1155);
    }

    function checkFees(LibNFTOrder.Fee[] calldata fees) internal view returns (bool success) {
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

    function checkProperties(LibNFTOrder.Property[] calldata properties, uint256 nftId) internal view returns (bool success) {
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

    function checkNftIdIsMatched(LibNFTOrder.Property[] calldata properties, address nft, uint256 orderNftId, uint256 nftId)
        internal
        pure
        returns (bool isMatched)
    {
        if (properties.length == 0) {
            return orderNftId == nftId;
        }
        return true;
    }

    function calcERC20TotalAmount(uint256 erc20TokenAmount, LibNFTOrder.Fee[] calldata fees) internal pure returns (uint256) {
        uint256 sum = erc20TokenAmount;
        for (uint256 i = 0; i < fees.length; i++) {
            sum += fees[i].amount;
        }
        return sum;
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function _ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // ceil(a / b) = floor((a + b - 1) / b)
        return (a + b - 1) / b;
    }
}

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./LibStructure.sol";

interface IElementExCheckerFeature {

    struct ERC20CheckInfo {
        uint256 balance;            // 买家ERC20余额或ETH余额
        uint256 allowance;          // erc20.allowance(taker, elementEx)。erc20若为ETH，固定返回true
        bool balanceCheck;          // check `balance >= erc20TotalAmount`
        bool allowanceCheck;        // check `allowance >= erc20TotalAmount`，如果是NATIVE_ADDRESS默认返回true
        bool listingTimeCheck;      // check `block.timestamp >= listingTime`
        bool takerCheck;            // check `order.taker == taker || order.taker == address(0)`
    }

    struct ERC721CheckInfo {
        bool ecr721TokenIdCheck;    // 检查买家与卖家的的`ecr721TokenId`是否匹配. ecr721TokenId相等，或者满足properties条件.
        bool erc721OwnerCheck;      // 检查卖家是否是该ecr721TokenId的拥有者
        bool erc721ApprovedCheck;   // 721授权检查
        bool listingTimeCheck;      // check `block.timestamp >= listingTime`
        bool takerCheck;            // check `order.taker == taker || order.taker == address(0)`
    }

    struct ERC721SellOrderCheckInfo {
        bool success;               // 所有的检查通过时为true，只要有一项检查未通过时为false
        uint256 hashNonce;
        bytes32 orderHash;
        bool makerCheck;            // check `maker != address(0)`
        bool takerCheck;            // check `taker != ElementEx`
        bool listingTimeCheck;      // check `listingTime < expireTime`
        bool expireTimeCheck;       // check `expireTime > block.timestamp`
        bool extraCheck;            // 荷兰拍模式下，extra必须小于等于100000000
        bool nonceCheck;            // 检查订单nonce，通过检查返回true(即：订单未成交也未取消)，未通过检查返回false
        bool feesCheck;             // fee地址不能是0x地址，并且如果有回调，fee地址必须是合约地址
        bool erc20AddressCheck;     // erc20地址检查。不能为address(0)，且该地址为NATIVE_ADDRESS，或者为一个合约地址
        bool erc721AddressCheck;    // erc721地址检查，erc721合约需要实现IERC721标准
        bool erc721OwnerCheck;      // 检查maker是否是该nftId的拥有者
        bool erc721ApprovedCheck;   // 721授权检查
        uint256 erc20TotalAmount;   // erc20TotalAmount = `order.erc20TokenAmount` + totalFeesAmount
    }

    struct ERC721BuyOrderCheckInfo {
        bool success;               // 所有的检查通过时为true，只要有一项检查未通过时为false
        uint256 hashNonce;
        bytes32 orderHash;
        bool makerCheck;            // check `maker != address(0)`
        bool takerCheck;            // check `taker != ElementEx`
        bool listingTimeCheck;      // check `listingTime < expireTime`
        bool expireTimeCheck;       // check `expireTime > block.timestamp`
        bool nonceCheck;            // 检查订单nonce，通过检查返回true(即：订单未成交也未取消)，未通过检查返回false
        bool feesCheck;             // fee地址不能是0x地址，并且如果有回调，fee地址必须是合约地址
        bool propertiesCheck;       // 属性检查。若`order.nftProperties`不为空,则`nftId`必须为0，并且property地址必须是address(0)或合约地址
        bool erc20AddressCheck;     // erc20地址检查。该地址必须为一个合约地址，不能是NATIVE_ADDRESS，不能为address(0)
        bool erc721AddressCheck;    // erc721地址检查。erc721合约需要实现IERC721标准
        uint256 erc20TotalAmount;   // erc20TotalAmount = `order.erc20TokenAmount` + totalFeesAmount
        uint256 erc20Balance;       // 买家ERC20余额
        uint256 erc20Allowance;     // 买家ERC20授权额度
        bool erc20BalanceCheck;     // check `erc20Balance >= erc20TotalAmount`
        bool erc20AllowanceCheck;   // check `erc20Allowance >= erc20TotalAmount`
    }

    struct ERC1155SellOrderCheckInfo {
        bool success;               // 所有的检查通过时为true，只要有一项检查未通过时为false
        uint256 hashNonce;
        bytes32 orderHash;
        uint256 erc1155RemainingAmount; // 1155支持部分成交，remainingAmount返回订单剩余的数量
        uint256 erc1155Balance;     // erc1155.balanceOf(order.maker, order.erc1155TokenId)
        bool makerCheck;            // check `maker != address(0)`
        bool takerCheck;            // check `taker != ElementEx`
        bool listingTimeCheck;      // check `listingTime < expireTime`
        bool expireTimeCheck;       // check `expireTime > block.timestamp`
        bool extraCheck;            // 荷兰拍模式下，extra必须小于等于100000000
        bool nonceCheck;            // 检查订单nonce
        bool remainingAmountCheck;  // check `erc1155RemainingAmount > 0`
        bool feesCheck;             // fee地址不能是0x地址，并且如果有回调，fee地址必须是合约地址
        bool erc20AddressCheck;     // erc20地址检查。不能为address(0)，且该地址为NATIVE_ADDRESS，或者为一个合约地址
        bool erc1155AddressCheck;   // erc1155地址检查，erc1155合约需要实现IERC1155标准
        bool erc1155BalanceCheck;   // check `erc1155Balance >= order.erc1155TokenAmount`
        bool erc1155ApprovedCheck;  // check `erc1155.isApprovedForAll(order.maker, elementEx)`
        uint256 erc20TotalAmount;   // erc20TotalAmount = `order.erc20TokenAmount` + totalFeesAmount
    }

    struct ERC1155SellOrderTakerCheckInfo {
        uint256 erc20Balance;       // 买家ERC20余额或ETH余额
        uint256 erc20Allowance;     // erc20.allowance(taker, elementEx)。erc20若为ETH，固定返回true
        uint256 erc20WillPayAmount; // 1155支持部分成交，`erc20WillPayAmount`为部分成交所需的总费用
        bool balanceCheck;          // check `erc20Balance >= erc20WillPayAmount
        bool allowanceCheck;        // check `erc20Allowance >= erc20WillPayAmount
        bool buyAmountCheck;        // 1155支持部分成交，购买的数量不能大于订单剩余的数量，即：`erc1155BuyAmount <= erc1155RemainingAmount`
        bool listingTimeCheck;      // check `block.timestamp >= listingTime`
        bool takerCheck;            // check `order.taker == taker || order.taker == address(0)`
    }

    struct ERC1155BuyOrderCheckInfo {
        bool success;               // 所有的检查通过时为true，只要有一项检查未通过时为false
        uint256 hashNonce;
        bytes32 orderHash;
        uint256 erc1155RemainingAmount; // 1155支持部分成交，remainingAmount返回剩余未成交的数量
        bool makerCheck;            // check `maker != address(0)`
        bool takerCheck;            // check `taker != ElementEx`
        bool listingTimeCheck;      // check `listingTime < expireTime`
        bool expireTimeCheck;       // check `expireTime > block.timestamp`
        bool nonceCheck;            // 检查订单nonce
        bool remainingAmountCheck;  // check `erc1155RemainingAmount > 0`
        bool feesCheck;             // fee地址不能是0x地址，并且如果有回调，fee地址必须是合约地址
        bool propertiesCheck;       // 属性检查。若order.erc1155Properties不为空,则`order.erc1155TokenId`必须为0，并且property地址必须是address(0)或合约地址
        bool erc20AddressCheck;     // erc20地址检查。该地址必须为一个合约地址，不能是NATIVE_ADDRESS，不能为address(0)
        bool erc1155AddressCheck;   // erc1155地址检查，erc1155合约需要实现IERC1155标准
        uint256 erc20TotalAmount;   // erc20TotalAmount = `order.erc20TokenAmount` + totalFeesAmount
        uint256 erc20Balance;       // 买家ERC20余额
        uint256 erc20Allowance;     // 买家ERC20授权额度
        bool erc20BalanceCheck;     // check `erc20Balance >= erc20TotalAmount`
        bool erc20AllowanceCheck;   // check `erc20AllowanceCheck >= erc20TotalAmount`
    }

    struct ERC1155BuyOrderTakerCheckInfo {
        uint256 erc1155Balance;     // erc1155.balanceOf(taker, erc1155TokenId)
        bool ecr1155TokenIdCheck;   // 检查买家与卖家的的`ecr1155TokenId`是否匹配. ecr1155TokenId，或者满足properties条件.
        bool erc1155BalanceCheck;   // check `erc1155SellAmount <= erc1155Balance`
        bool erc1155ApprovedCheck;  // check `erc1155.isApprovedForAll(taker, elementEx)`
        bool sellAmountCheck;       // check `erc1155SellAmount <= erc1155RemainingAmount`，即：卖出的数量不能大于订单剩余的数量
        bool listingTimeCheck;      // check `block.timestamp >= listingTime`
        bool takerCheck;            // check `order.taker == taker || order.taker == address(0)`
    }

    /// 注意：taker在这里指买家，当taker为address(0)时，忽略`takerCheckInfo`，
    ///      当买家不为address(0)时，takerCheckInfo返回taker相关检查信息.
    function checkERC721SellOrder(LibNFTOrder.NFTSellOrder calldata order, address taker)
        external
        view
        returns (ERC721SellOrderCheckInfo memory info, ERC20CheckInfo memory takerCheckInfo);

    /// 注意：taker在这里指买家，当taker为address(0)时，忽略`takerCheckInfo`，
    ///      当taker不为address(0)时，takerCheckInfo返回taker相关检查信息.
    function checkERC721SellOrderEx(
        LibNFTOrder.NFTSellOrder calldata order,
        address taker,
        LibSignature.Signature calldata signature
    )
        external
        view
        returns (ERC721SellOrderCheckInfo memory info, ERC20CheckInfo memory takerCheckInfo, bool validSignature);

    /// 注意：taker在这里指卖家，当taker为address(0)时，忽略`takerCheckInfo`，
    ///      当taker不为address(0)时，takerCheckInfo返回ERC721相关检查信息.
    function checkERC721BuyOrder(LibNFTOrder.NFTBuyOrder calldata order, address taker, uint256 erc721TokenId)
        external
        view
        returns (ERC721BuyOrderCheckInfo memory info, ERC721CheckInfo memory takerCheckInfo);

    /// 注意：taker在这里指卖家，当taker为address(0)时，忽略`takerCheckInfo`，
    ///      当taker不为address(0)时，takerCheckInfo返回ERC721相关检查信息.
    function checkERC721BuyOrderEx(
        LibNFTOrder.NFTBuyOrder calldata order,
        address taker,
        uint256 erc721TokenId,
        LibSignature.Signature calldata signature
    )
        external
        view
        returns (ERC721BuyOrderCheckInfo memory info, ERC721CheckInfo memory takerCheckInfo, bool validSignature);

    /// 注意：
    ///     1.taker在这里指买家，当taker为address(0)时，忽略`takerCheckInfo`，当taker不为address(0)时，takerCheckInfo返回taker相关检查信息.
    ///     2.1155支持部分成交，erc1155BuyAmount指taker购买的数量，taker为address(0)时，该字段忽略
    function checkERC1155SellOrder(LibNFTOrder.ERC1155SellOrder calldata order, address taker, uint128 erc1155BuyAmount)
        external
        view
        returns (ERC1155SellOrderCheckInfo memory info, ERC1155SellOrderTakerCheckInfo memory takerCheckInfo);

    /// 注意：
    ///     1.taker在这里指买家，当taker为address(0)时，忽略`takerCheckInfo`，当taker不为address(0)时，takerCheckInfo返回taker相关检查信息.
    ///     2.1155支持部分成交，erc1155BuyAmount指taker购买的数量，taker为address(0)时，该字段忽略
    function checkERC1155SellOrderEx(
        LibNFTOrder.ERC1155SellOrder calldata order,
        address taker,
        uint128 erc1155BuyAmount,
        LibSignature.Signature calldata signature
    )
        external
        view
        returns (ERC1155SellOrderCheckInfo memory info, ERC1155SellOrderTakerCheckInfo memory takerCheckInfo, bool validSignature);

    /// 注意：
    ///     1.taker在这里指卖家，当taker为address(0)时，忽略`takerCheckInfo`，当taker不为address(0)时，takerCheckInfo返回ERC1155相关检查信息.
    ///     2.1155支持部分成交，erc1155SellAmount指taker卖出的数量，taker为address(0)时，该字段忽略
    function checkERC1155BuyOrder(
        LibNFTOrder.ERC1155BuyOrder calldata order,
        address taker,
        uint256 erc1155TokenId,
        uint128 erc1155SellAmount
    )
        external
        view
        returns (ERC1155BuyOrderCheckInfo memory info, ERC1155BuyOrderTakerCheckInfo memory takerCheckInfo);

    /// 注意：
    ///     1.taker在这里指卖家，当taker为address(0)时，忽略`takerCheckInfo`，当taker不为address(0)时，takerCheckInfo返回ERC1155相关检查信息.
    ///     2.1155支持部分成交，erc1155SellAmount指taker卖出的数量，taker为address(0)时，该字段忽略
    function checkERC1155BuyOrderEx(
        LibNFTOrder.ERC1155BuyOrder calldata order,
        address taker,
        uint256 erc1155TokenId,
        uint128 erc1155SellAmount,
        LibSignature.Signature calldata signature
    )
        external
        view
        returns (ERC1155BuyOrderCheckInfo memory info, ERC1155BuyOrderTakerCheckInfo memory takerCheckInfo, bool validSignature);

    function validateERC721SellOrderSignature(LibNFTOrder.NFTSellOrder calldata order, LibSignature.Signature calldata signature)
        external
        view
        returns (bool valid);

    function validateERC721BuyOrderSignature(LibNFTOrder.NFTBuyOrder calldata order, LibSignature.Signature calldata signature)
        external
        view
        returns (bool valid);

    function getERC721SellOrderHash(LibNFTOrder.NFTSellOrder calldata order) external view returns (bytes32);

    function getERC721BuyOrderHash(LibNFTOrder.NFTBuyOrder calldata order) external view returns (bytes32);

    function isERC721OrderNonceFilled(address account, uint256 nonce) external view returns (bool filled);

    function isERC1155OrderNonceCancelled(address account, uint256 nonce) external view returns (bool filled);

    function getHashNonce(address maker) external view returns (uint256);

    function getERC1155SellOrderInfo(LibNFTOrder.ERC1155SellOrder calldata order)
        external
        view
        returns (LibNFTOrder.OrderInfo memory orderInfo);

    function getERC1155BuyOrderInfo(LibNFTOrder.ERC1155BuyOrder calldata order)
        external
        view
        returns (LibNFTOrder.OrderInfo memory orderInfo);

    function validateERC1155SellOrderSignature(LibNFTOrder.ERC1155SellOrder calldata order, LibSignature.Signature calldata signature)
        external
        view
        returns (bool valid);

    function validateERC1155BuyOrderSignature(LibNFTOrder.ERC1155BuyOrder calldata order, LibSignature.Signature calldata signature)
        external
        view
        returns (bool valid);
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