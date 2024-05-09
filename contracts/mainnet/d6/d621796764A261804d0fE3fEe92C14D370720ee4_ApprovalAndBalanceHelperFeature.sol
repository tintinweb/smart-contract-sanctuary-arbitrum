/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../../libs/LibAssetHelper.sol";

contract ApprovalAndBalanceHelperFeature is LibAssetHelper {

    struct ABItemInfo {
        uint8 itemType; // 0: ERC721, 1: ERC1155, 2: ERC20
        address token;
        uint256 tokenId;
        address account;
        address operator;
    }

    struct ABResultInfo {
        uint256 approval;
        uint256 balance;
    }

    function getApprovalsAndBalances(ABItemInfo[] calldata list)
        external
        view
        returns (ABResultInfo[] memory infos)
    {
        infos = new ABResultInfo[](list.length);
        for (uint256 i; i < list.length; i++) {
            uint8 itemType = list[i].itemType;
            if (itemType == 0) {
                infos[i].approval = _isApprovedForAll(list[i].token, true, list[i].account, list[i].operator);
                infos[i].balance = _erc721OwnerOf(list[i].token, list[i].tokenId) == list[i].account ? 1 : 0;
            } else if (itemType == 1) {
                infos[i].approval = _isApprovedForAll(list[i].token, false, list[i].account, list[i].operator);
                infos[i].balance = _erc1155BalanceOf(list[i].token, list[i].account, list[i].tokenId);
            } else if (itemType == 2) {
                infos[i].approval = _erc20Allowance(list[i].token, list[i].account, list[i].operator);
                infos[i].balance = _erc20BalanceOf(list[i].token, list[i].account);
            }
        }
        return infos;
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