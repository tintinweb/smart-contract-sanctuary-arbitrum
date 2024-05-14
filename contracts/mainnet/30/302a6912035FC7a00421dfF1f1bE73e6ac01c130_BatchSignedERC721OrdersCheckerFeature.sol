/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./IBatchSignedERC721OrdersCheckerFeature.sol";
import "../../libs/LibAssetHelper.sol";

interface IElement {
    function getERC721OrderStatusBitVector(address maker, uint248 nonceRange) external view returns (uint256);
    function getHashNonce(address maker) external view returns (uint256);
}

contract BatchSignedERC721OrdersCheckerFeature is IBatchSignedERC721OrdersCheckerFeature, LibAssetHelper {

    uint256 internal constant MASK_96 = (1 << 96) - 1;
    uint256 internal constant MASK_160 = (1 << 160) - 1;
    uint256 internal constant MASK_224 = (1 << 224) - 1;

    bytes32 public immutable EIP712_DOMAIN_SEPARATOR;
    address public immutable ELEMENT;

    constructor(address element) {
        ELEMENT = element;
        EIP712_DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256("ElementEx"),
            keccak256("1.0.0"),
            block.chainid,
            element
        ));
    }

    function checkBSERC721Orders(BSERC721Orders calldata order) external view override returns (BSERC721OrdersCheckResult memory r) {
        uint256 nonce;
        (r.basicCollections, nonce) = _checkBasicCollections(order, true);
        r.collections = _checkCollections(order, nonce, true);
        r.hashNonce = _getHashNonce(order.maker);
        r.orderHash = _getOrderHash(order, r.hashNonce);
        r.validSignature = _validateSignature(order, r.orderHash, 0);
        return r;
    }

    function checkBSERC721OrdersV2(BSERC721Orders calldata order, uint8 signatureType) external view returns (BSERC721OrdersCheckResult memory r) {
        uint256 nonce;
        (r.basicCollections, nonce) = _checkBasicCollections(order, true);
        r.collections = _checkCollections(order, nonce, true);
        r.hashNonce = _getHashNonce(order.maker);
        r.orderHash = _getOrderHash(order, r.hashNonce);
        r.validSignature = _validateSignature(order, r.orderHash, signatureType);
        return r;
    }

    function checkBSERC721OrdersV3(BSERC721Orders calldata order, uint8 signatureType, bool isGetOwnerOf) external view returns (BSERC721OrdersCheckResult memory r) {
        uint256 nonce;
        (r.basicCollections, nonce) = _checkBasicCollections(order, isGetOwnerOf);
        r.collections = _checkCollections(order, nonce, isGetOwnerOf);
        r.hashNonce = _getHashNonce(order.maker);
        r.orderHash = _getOrderHash(order, r.hashNonce);
        r.validSignature = _validateSignature(order, r.orderHash, signatureType);
        return r;
    }

    function _checkBasicCollections(BSERC721Orders calldata order, bool isGetOwnerOf) internal view returns (BSCollectionCheckResult[] memory basicCollections, uint256 nonce) {
        nonce = order.startNonce;
        basicCollections = new BSCollectionCheckResult[](order.basicCollections.length);

        for (uint256 i; i < basicCollections.length; ) {
            address nftAddress = order.basicCollections[i].nftAddress;
            basicCollections[i].isApprovedForAll = _isApprovedForAll(nftAddress, true, order.maker, ELEMENT) > 0;

            BSOrderItemCheckResult[] memory items = new BSOrderItemCheckResult[](order.basicCollections[i].items.length);
            basicCollections[i].items = items;

            for (uint256 j; j < items.length; ) {
                items[j].isNonceValid = _isNonceValid(order.maker, nonce);
                unchecked { ++nonce; }

                items[j].isERC20AmountValid = order.basicCollections[i].items[j].erc20TokenAmount <= MASK_96;
                uint256 nftId = order.basicCollections[i].items[j].nftId;
                if (nftId <= MASK_160) {
                    if (isGetOwnerOf) {
                        items[j].ownerOfNftId = _erc721OwnerOf(nftAddress, nftId);
                        items[j].approvedAccountOfNftId = _erc721GetApproved(nftAddress, nftId);
                    }
                } else {
                    items[j].ownerOfNftId = address(0);
                    items[j].approvedAccountOfNftId = address(0);
                }
                unchecked { ++j; }
            }
            unchecked { ++i; }
        }
    }

    function _checkCollections(BSERC721Orders calldata order, uint256 nonce, bool isGetOwnerOf) internal view returns (BSCollectionCheckResult[] memory collections) {
        collections = new BSCollectionCheckResult[](order.collections.length);
        for (uint256 i; i < collections.length; ) {
            address nftAddress = order.collections[i].nftAddress;
            collections[i].isApprovedForAll = _isApprovedForAll(nftAddress, true, order.maker, ELEMENT) > 0;

            BSOrderItemCheckResult[] memory items = new BSOrderItemCheckResult[](order.collections[i].items.length);
            collections[i].items = items;

            for (uint256 j; j < items.length; ) {
                items[j].isNonceValid = _isNonceValid(order.maker, nonce);
                unchecked { ++nonce; }

                items[j].isERC20AmountValid = order.collections[i].items[j].erc20TokenAmount <= MASK_224;

                uint256 nftId = order.collections[i].items[j].nftId;
                if (isGetOwnerOf) {
                    items[j].ownerOfNftId = _erc721OwnerOf(nftAddress, nftId);
                    items[j].approvedAccountOfNftId = _erc721GetApproved(nftAddress, nftId);
                }

                unchecked { ++j; }
            }
            unchecked { ++i; }
        }
    }

    function _validateSignature(
        BSERC721Orders calldata order,
        bytes32 hash,
        uint8 signatureType
    ) internal view returns (bool)  {
        address maker = order.maker;
        if (maker == address(0)) {
            return false;
        }

        uint8 v = order.v;
        bytes32 r = order.r;
        bytes32 s = order.s;
        if (signatureType == 0) {
            return order.maker == ecrecover(hash, v, r, s);
        } else if (signatureType == 3) {
            return isValidSignature1271(order.maker, hash, v, r, s);
        } else if (signatureType == 5) {
            uint256 personalSignState = _getPersonalSignState();
            if ((personalSignState & 0x1) == 0) {
               return false;
            }
            bytes32 validateHash = toEthereumPersonalSignHash(hash);
            return isValidSignature1271(order.maker, validateHash, v, r, s);
        } else if (signatureType == 7) {
            uint256 personalSignState = _getPersonalSignState();
            if ((personalSignState & 0x2) == 0) {
                return false;
            }
            bytes32 validateHash = toBitcoinPersonalSignHash(hash);
            return isValidSignature1271(order.maker, validateHash, v, r, s);
        } else if (signatureType == 9) {
            uint256 personalSignState = _getPersonalSignState();
            if ((personalSignState & 0x4) == 0) {
                return false;
            }
            bytes32 validateHash = toBitcoinPersonalSignHash(hash);
            return isValidSignature173(order.maker, validateHash, v, r, s);
        } else {
            return false;
        }
    }

    function _getPersonalSignState() internal view returns (uint256 state) {
        address element = ELEMENT;
        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for getPersonalSignState
            mstore(ptr, 0x3cdad7ce)

            let success := staticcall(gas(), element, ptr, 0x4, ptr, 32)
            if success {
                if eq(returndatasize(), 32) {
                    state := mload(ptr)
                }
            }
        }
    }

    function _isNonceValid(address account, uint256 nonce) internal view returns (bool filled) {
        uint256 bitVector = IElement(ELEMENT).getERC721OrderStatusBitVector(account, uint248(nonce >> 8));
        uint256 flag = 1 << (nonce & 0xff);
        return (bitVector & flag) == 0;
    }

    function _getHashNonce(address maker) internal view returns (uint256) {
        return IElement(ELEMENT).getHashNonce(maker);
    }

    // keccak256(""));
    bytes32 internal constant _EMPTY_ARRAY_KECCAK256 = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    // keccak256(abi.encodePacked(
    //    "BatchSignedERC721Orders(address maker,uint256 listingTime,uint256 expiryTime,uint256 startNonce,address erc20Token,address platformFeeRecipient,BasicCollection[] basicCollections,Collection[] collections,uint256 hashNonce)",
    //    "BasicCollection(address nftAddress,bytes32 fee,bytes32[] items)",
    //    "Collection(address nftAddress,bytes32 fee,OrderItem[] items)",
    //    "OrderItem(uint256 erc20TokenAmount,uint256 nftId)"
    // ))
    bytes32 internal constant _BATCH_SIGNED_ERC721_ORDERS_TYPE_HASH = 0x2d8cbbbc696e7292c3b5beb38e1363d34ff11beb8c3456c14cb938854597b9ed;
    // keccak256("BasicCollection(address nftAddress,bytes32 fee,bytes32[] items)")
    bytes32 internal constant _BASIC_COLLECTION_TYPE_HASH = 0x12ad29288fd70022f26997a9958d9eceb6e840ceaa79b72ea5945ba87e4d33b0;
    // keccak256(abi.encodePacked(
    //    "Collection(address nftAddress,bytes32 fee,OrderItem[] items)",
    //    "OrderItem(uint256 erc20TokenAmount,uint256 nftId)"
    // ))
    bytes32 internal constant _COLLECTION_TYPE_HASH = 0xb9f488d48cec782be9ecdb74330c9c6a33c236a8022d8a91a4e4df4e81b51620;
    // keccak256("OrderItem(uint256 erc20TokenAmount,uint256 nftId)")
    bytes32 internal constant _ORDER_ITEM_TYPE_HASH = 0x5f93394997caa49a9382d44a75e3ce6a460f32b39870464866ac994f8be97afe;

    function _getOrderHash(BSERC721Orders calldata order, uint256 hashNonce) internal view returns (bytes32) {
        bytes32 basicCollectionsHash = _getBasicCollectionsHash(order.basicCollections);
        bytes32 collectionsHash = _getCollectionsHash(order.collections);
        address paymentToken = order.paymentToken;
        if (paymentToken == address(0)) {
            paymentToken = NATIVE_TOKEN_ADDRESS;
        }
        bytes32 structHash = keccak256(abi.encode(
            _BATCH_SIGNED_ERC721_ORDERS_TYPE_HASH,
            order.maker,
            order.listingTime,
            order.expirationTime,
            order.startNonce,
            paymentToken,
            order.platformFeeRecipient,
            basicCollectionsHash,
            collectionsHash,
            hashNonce
        ));
        return keccak256(abi.encodePacked(hex"1901", EIP712_DOMAIN_SEPARATOR, structHash));
    }

    function _getBasicCollectionsHash(BSCollection[] calldata basicCollections) internal pure returns (bytes32 hash) {
        if (basicCollections.length == 0) {
            hash = _EMPTY_ARRAY_KECCAK256;
        } else {
            uint256 num = basicCollections.length;
            bytes32[] memory structHashArray = new bytes32[](num);
            for (uint256 i = 0; i < num; ) {
                structHashArray[i] = _getBasicCollectionHash(basicCollections[i]);
                unchecked { i++; }
            }
            assembly {
                hash := keccak256(add(structHashArray, 0x20), mul(num, 0x20))
            }
        }
    }

    function _getBasicCollectionHash(BSCollection calldata basicCollection) internal pure returns (bytes32) {
        bytes32 itemsHash;
        if (basicCollection.items.length == 0) {
            itemsHash = _EMPTY_ARRAY_KECCAK256;
        } else {
            uint256 num = basicCollection.items.length;
            uint256[] memory structHashArray = new uint256[](num);
            for (uint256 i = 0; i < num; ) {
                uint256 erc20TokenAmount = basicCollection.items[i].erc20TokenAmount;
                uint256 nftId = basicCollection.items[i].nftId;
                if (erc20TokenAmount > MASK_96 || nftId > MASK_160) {
                    structHashArray[i] = 0;
                } else {
                    structHashArray[i] = (erc20TokenAmount << 160) | nftId;
                }
                unchecked { i++; }
            }
            assembly {
                itemsHash := keccak256(add(structHashArray, 0x20), mul(num, 0x20))
            }
        }

        uint256 fee = (basicCollection.platformFee << 176) | (basicCollection.royaltyFee << 160) | uint256(uint160(basicCollection.royaltyFeeRecipient));
        return keccak256(abi.encode(
            _BASIC_COLLECTION_TYPE_HASH,
            basicCollection.nftAddress,
            fee,
            itemsHash
        ));
    }

    function _getCollectionsHash(BSCollection[] calldata collections) internal pure returns (bytes32 hash) {
        if (collections.length == 0) {
            hash = _EMPTY_ARRAY_KECCAK256;
        } else {
            uint256 num = collections.length;
            bytes32[] memory structHashArray = new bytes32[](num);
            for (uint256 i = 0; i < num; ) {
                structHashArray[i] = _getCollectionHash(collections[i]);
                unchecked { i++; }
            }
            assembly {
                hash := keccak256(add(structHashArray, 0x20), mul(num, 0x20))
            }
        }
    }

    function _getCollectionHash(BSCollection calldata collection) internal pure returns (bytes32) {
        bytes32 itemsHash;
        if (collection.items.length == 0) {
            itemsHash = _EMPTY_ARRAY_KECCAK256;
        } else {
            uint256 num = collection.items.length;
            bytes32[] memory structHashArray = new bytes32[](num);
            for (uint256 i = 0; i < num; ) {
                uint256 erc20TokenAmount = collection.items[i].erc20TokenAmount;
                uint256 nftId = collection.items[i].nftId;
                if (erc20TokenAmount > MASK_224) {
                    structHashArray[i] = 0;
                } else {
                    structHashArray[i] = keccak256(abi.encode(_ORDER_ITEM_TYPE_HASH, erc20TokenAmount, nftId));
                }
                unchecked { i++; }
            }
            assembly {
                itemsHash := keccak256(add(structHashArray, 0x20), mul(num, 0x20))
            }
        }

        uint256 fee = (collection.platformFee << 176) | (collection.royaltyFee << 160) | uint256(uint160(collection.royaltyFeeRecipient));
        return keccak256(abi.encode(
            _COLLECTION_TYPE_HASH,
            collection.nftAddress,
            fee,
            itemsHash
        ));
    }

    bytes16 private constant HEX_DIGITS = "0123456789abcdef";

    function bytes32ToHexBuffer(bytes32 data) internal pure returns(bytes memory buffer) {
        uint256 localValue = uint256(data);
        buffer = new bytes(66);
        buffer[0] = "0";
        buffer[1] = "x";
        unchecked {
            for (uint256 i = 65; i > 1; --i) {
                buffer[i] = HEX_DIGITS[localValue & 0xf];
                localValue >>= 4;
            }
        }
        return buffer;
    }

    function toEthereumPersonalSignHash(bytes32 hash) internal pure returns(bytes32) {
        return keccak256(
            bytes.concat(
                "\x19Ethereum Signed Message:\n101Element.market listing/offer hash:\n",
                bytes32ToHexBuffer(hash)
            )
        );
    }

    function toBitcoinPersonalSignHash(bytes32 hash) internal pure returns(bytes32) {
        bytes32 tempHash = sha256(
            bytes.concat(
                "\x18Bitcoin Signed Message:\n\x65Element.market listing/offer hash:\n",
                bytes32ToHexBuffer(hash)
            )
        );
        // Convert bytes32 to bytes.
        bytes memory buffer = new bytes(32);
        assembly {
            mstore(add(buffer, 32), tempHash)
        }
        return sha256(buffer);
    }

    function isValidSignature1271(
        address aa,
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns(bool) {
        bool isValid;
        assembly {
            if extcodesize(aa) {
                let ptr := mload(0x40) // free memory pointer

                // selector for `isValidSignature(bytes32,bytes)`
                mstore(ptr, 0x1626ba7e)
                mstore(add(ptr, 0x20), hash)
                mstore(add(ptr, 0x40), 0x40)
                mstore(add(ptr, 0x60), 0x41)
                mstore(add(ptr, 0x80), r)
                mstore(add(ptr, 0xa0), s)
                mstore(add(ptr, 0xc0), shl(248, v))

                if staticcall(gas(), aa, add(ptr, 0x1c), 0xa5, ptr, 0x20) {
                    if eq(mload(ptr), 0x1626ba7e00000000000000000000000000000000000000000000000000000000) {
                        isValid := 1
                    }
                }
            }
        }
        return isValid;
    }

    uint256 constant private ADDRESS_LIMIT = 1 << 160;

    function isValidSignature173(
        address aa,
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns(bool) {
        address owner;
        assembly {
            if extcodesize(aa) {
                let ptr := mload(0x40) // free memory pointer

                // selector for `owner()`
                mstore(ptr, 0x8da5cb5b)

                if staticcall(gas(), aa, add(ptr, 0x1c), 0x4, ptr, 0x20) {
                    if lt(mload(ptr), ADDRESS_LIMIT) {
                        owner := mload(ptr)
                    }
                }
            }
        }
        return owner != address(0) && owner == ecrecover(hash, v, r, s);
    }
}

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


interface IBatchSignedERC721OrdersCheckerFeature {

    struct BSOrderItem {
        uint256 erc20TokenAmount;
        uint256 nftId;
    }

    struct BSCollection {
        address nftAddress;
        uint256 platformFee;
        uint256 royaltyFee;
        address royaltyFeeRecipient;
        BSOrderItem[] items;
    }

    struct BSERC721Orders {
        address maker;
        uint256 listingTime;
        uint256 expirationTime;
        uint256 startNonce;
        address paymentToken;
        address platformFeeRecipient;
        BSCollection[] basicCollections;
        BSCollection[] collections;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct BSOrderItemCheckResult {
        bool isNonceValid;
        bool isERC20AmountValid;
        address ownerOfNftId;
        address approvedAccountOfNftId;
    }

    struct BSCollectionCheckResult {
        bool isApprovedForAll;
        BSOrderItemCheckResult[] items;
    }

    struct BSERC721OrdersCheckResult {
        bytes32 orderHash;
        uint256 hashNonce;
        bool validSignature;
        BSCollectionCheckResult[] basicCollections;
        BSCollectionCheckResult[] collections;
    }

    function checkBSERC721Orders(BSERC721Orders calldata order) external view returns (BSERC721OrdersCheckResult memory r);
    function checkBSERC721OrdersV2(BSERC721Orders calldata order, uint8 signatureType) external view returns (BSERC721OrdersCheckResult memory r);
    function checkBSERC721OrdersV3(BSERC721Orders calldata order, uint8 signatureType, bool isGetOwnerOf) external view returns (BSERC721OrdersCheckResult memory r);
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