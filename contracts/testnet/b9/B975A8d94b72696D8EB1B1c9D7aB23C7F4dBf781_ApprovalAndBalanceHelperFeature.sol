/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


interface IAsset {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function balanceOf(address account, uint256 id) external view returns (uint256);
}

contract ApprovalAndBalanceHelperFeature {

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
                if (isApprovedForAll(list[i].token, list[i].account, list[i].operator)) {
                    infos[i].approval = 1;
                }
                if (ownerOf(list[i].token, list[i].tokenId) == list[i].account) {
                    infos[i].balance = 1;
                }
            } else if (itemType == 1) {
                if (isApprovedForAll(list[i].token, list[i].account, list[i].operator)) {
                    infos[i].approval = 1;
                }
                infos[i].balance = balanceOf(list[i].token, list[i].account, list[i].tokenId);
            } else if (itemType == 2) {
                infos[i].approval = allowanceOf(list[i].token, list[i].account, list[i].operator);
                infos[i].balance = balanceOf(list[i].token, list[i].account);
            }
        }
        return infos;
    }

    function ownerOf(address nft, uint256 tokenId) internal view returns (address owner) {
        if (nft != address(0)) {
            try IAsset(nft).ownerOf(tokenId) returns (address _owner) {
                owner = _owner;
            } catch {
            }
        }
        return owner;
    }

    function isApprovedForAll(address nft, address owner, address operator) internal view returns (bool isApproved) {
        if (nft != address(0)) {
            try IAsset(nft).isApprovedForAll(owner, operator) returns (bool _isApprovedForAll) {
                isApproved = _isApprovedForAll;
            } catch {
            }
        }
        return isApproved;
    }

    function balanceOf(address nft, address account, uint256 id) internal view returns (uint256 balance) {
        if (nft != address(0)) {
            try IAsset(nft).balanceOf(account, id) returns (uint256 _balance) {
                balance = _balance;
            } catch {
            }
        }
        return balance;
    }

    address internal constant NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function balanceOf(address erc20, address account) internal view returns (uint256 balance) {
        if (erc20 != address(0) && erc20 != NATIVE_TOKEN_ADDRESS) {
            try IAsset(erc20).balanceOf(account) returns (uint256 _balance) {
                balance = _balance;
            } catch {
            }
            return balance;
        }
        return account.balance;
    }

    function allowanceOf(address erc20, address owner, address spender) internal view returns (uint256 allowance) {
        if (erc20 != address(0) && erc20 != NATIVE_TOKEN_ADDRESS) {
            try IAsset(erc20).allowance(owner, spender) returns (uint256 _allowance) {
                allowance = _allowance;
            } catch {
            }
        }
        return allowance;
    }
}