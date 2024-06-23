// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { ERC1155 } from "./ERC1155.sol";
import { Ownable, Ownable2Step } from "./Ownable2Step.sol";
import { Strings } from "./Strings.sol";

/// @title GemsNFT contract
/// @notice Implements the minting of Gems NFTs
/// @dev The gems nft contract allows you to mint gems nft
contract GemsNFT is ERC1155, Ownable2Step {
    using Strings for uint256;

    /// @notice The address of gems claims contract
    address public gemsClaims;

    /// @dev Emitted when gems claims contract is updated
    event GemsClaimsUpdated(address indexed prevAddress, address indexed newAddress);

    /// @notice Thrown when caller is other than gems claims contract
    error OnlyGemsClaims();

    /// @notice Thrown when updating an address with zero address
    error ZeroAddress();

    /// @notice Thrown when updating with the same value as previously stored
    error IdenticalValue();

    /// @notice Ensures that only claims contract can call the function
    modifier OnlyClaims() {
        if (gemsClaims != msg.sender) {
            revert OnlyGemsClaims();
        }
        _;
    }

    /// Constructor
    /// @param baseUri The base uri of the tokens
    /// @param owner The address of owner wallet
    constructor(string memory baseUri, address owner) ERC1155(baseUri) Ownable(owner) {}

    /// @notice Mint nfts to the user
    /// @param to The address to which nfts will be minted, it will be non-zero address
    /// @param ids The token ids that will be minted to `to`
    /// @param quantity The amount of nfts that will be minted to `to`
    function mint(address to, uint256[] calldata ids, uint256[] calldata quantity) external OnlyClaims {
        _mintBatch(to, ids, quantity, "");
    }

    /// @notice The function updates uri of the tokens
    /// @param newUri The new bas uri of the tokens
    function setBaseUri(string memory newUri) external onlyOwner {
        _setURI(newUri);
    }

    /// @notice Changes gems claims contract to a new address
    /// @param newGemsClaims The address of the new claims contract
    function setGemsClaims(address newGemsClaims) external onlyOwner {
        if (newGemsClaims == address(0)) {
            revert ZeroAddress();
        }

        address oldWallet = gemsClaims;

        if (oldWallet == newGemsClaims) {
            revert IdenticalValue();
        }

        emit GemsClaimsUpdated({ prevAddress: oldWallet, newAddress: newGemsClaims });
        gemsClaims = newGemsClaims;
    }

    /// @notice The function overrides existing function
    /// @param tokenId The nft token id for which base uri will be calculated
    function uri(uint256 tokenId) public view override returns (string memory) {
        string memory baseUri = super.uri(tokenId);
        return bytes(baseUri).length > 0 ? string.concat(baseUri, tokenId.toString()) : "";
    }
}