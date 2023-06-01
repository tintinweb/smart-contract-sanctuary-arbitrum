/**
 *Submitted for verification at Arbiscan on 2023-05-31
*/

// Sources flattened with hardhat v2.14.0 https://hardhat.org

// File contracts/IStarNFT.sol

/**
 * @title IStarNFT
 * @author Galaxy Protocol
 *
 * Interface for operating with StarNFTs.
 */
interface IStarNFT {
    /* ============ Events =============== */

    /* ============ Functions ============ */

    function isOwnerOf(address, uint256) external view returns (bool);
    function getNumMinted() external view returns (uint256);
    // mint
    function mint(address account, uint256 powah) external returns (uint256);
    function mintBatch(address account, uint256 amount, uint256[] calldata powahArr) external returns (uint256[] memory);
    function burn(address account, uint256 id) external;
    function burnBatch(address account, uint256[] calldata ids) external;
}


// File contracts/FakeGalxeGraphQL.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

contract FakeGalxeGraphQL {
    struct nfts {
        uint256 id;
        address contractAddress;
        string name;
    }
    function allNFTsByOwnersCoresAndChain(address owners, address[] calldata nftCoreAddresses)
    public
    view
    returns (nfts[] memory)
    {
        uint256 j = 0;
        nfts[] memory tokenList = new nfts[](50);
        for (uint256 k = 0; k < nftCoreAddresses.length; k++) {
            address nftAddr = nftCoreAddresses[k];
            IStarNFT statNFT = IStarNFT(nftAddr);
            for (uint256 i = 1; i <= statNFT.getNumMinted(); i++) {
                try statNFT.isOwnerOf(owners, i) returns (bool owned) {
                    if (owned) {
                        string memory name = _getName(nftAddr, i);
                        nfts memory nft = nfts(i, nftAddr, name);
                        tokenList[j] = nft;
                        j++;
                    }
                } catch (bytes memory) {}
            }
        }

        nfts[] memory tokenListOut = new nfts[](j);
        for (uint256 i = 0; i < j; i++) {
            tokenListOut[i] = tokenList[i];
        }
        return tokenListOut;
    }

    function _getName(address nftAddr, uint256 tokenId)
    private
    pure
    returns (string memory)
    {
        if (nftAddr == 0x91859ac6c0ddaB7EaCe723E59b543F932932C4d1) {
            return "Space Puzzle Forging Event";
        } else {
            if (tokenId <= 20) {
                return "Aboard Blue Robot";
            } else if (tokenId==21 || tokenId==28) {
                return "Robot Chip";
            } else if (tokenId==22 || tokenId==26 || tokenId==32 || tokenId==34 || tokenId==36 || tokenId==38) {
                return "Robot Legs";
            } else if (tokenId==24 || tokenId==30 || tokenId==35) {
                return "Robot Body";
            } else {
                return "Gold Robot";
            }
        }
    }
}