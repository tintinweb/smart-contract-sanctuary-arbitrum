/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./IAssetCheckerFeature.sol";
import "../../libs/LibAssetHelper.sol";

contract AssetCheckerFeature is IAssetCheckerFeature, LibAssetHelper {

    function checkAssetsEx(
        address account,
        address operator,
        uint8[] calldata itemTypes,
        address[] calldata tokens,
        uint256[] calldata tokenIds
    )
        external
        override
        view
        returns (AssetCheckResultInfo[] memory infos)
    {
        require(itemTypes.length == tokens.length, "require(itemTypes.length == tokens.length)");
        require(itemTypes.length == tokenIds.length, "require(itemTypes.length == tokenIds.length)");

        infos = new AssetCheckResultInfo[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            uint256 tokenId = tokenIds[i];

            infos[i].itemType = itemTypes[i];
            if (itemTypes[i] == 0) {
                bool isERC404;
                (infos[i].allowance, isERC404) = _isApprovedForAllV2(token, true, account, operator);
                if (isERC404) {
                    infos[i].itemType = 3;
                }
                infos[i].erc721Owner = _erc721OwnerOf(token, tokenId);
                infos[i].erc721ApprovedAccount = _erc721GetApproved(token, tokenId);
                infos[i].balance = (infos[i].erc721Owner == account) ? 1 : 0;
                continue;
            }

            if (itemTypes[i] == 1) {
                infos[i].allowance = _isApprovedForAll(token, false, account, operator);
                infos[i].balance = _erc1155BalanceOf(token, account, tokenId);
                continue;
            }

            if (itemTypes[i] == 2) {
                infos[i].balance = _erc20BalanceOf(token, account);
                infos[i].allowance = _erc20Allowance(token, account, operator);
            }
        }
        return infos;
    }
}

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


interface IAssetCheckerFeature {

    struct AssetCheckResultInfo {
        uint8 itemType; // 0: ERC721, 1: ERC1155, 2: ERC20, 255: other
        uint256 allowance;
        uint256 balance;
        address erc721Owner;
        address erc721ApprovedAccount;
    }

    function checkAssetsEx(
        address account,
        address operator,
        uint8[] calldata itemTypes,
        address[] calldata tokens,
        uint256[] calldata tokenIds
    )
        external
        view
        returns (AssetCheckResultInfo[] memory infos);
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