// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "ERC721APet.sol";
import "PetMerkle.sol";

contract CatScientist is ERC721APet, PetMerkle {
    // state vars
    uint256 public constant MAX_SUPPLY = 600;
    string private _baseURIextended;
    /**
     * Exceeds maximum supply.
     */
    error ExceedsMaximumSupply();
    /**
     * @dev emit when a user claims tokens on the allowlist
     * @param userAddress the minting wallet and token recipient
     * @param numberOfTokens the quantity of tokens claimed
     */
    event AllowListClaimMint(
        address indexed userAddress,
        uint256 numberOfTokens
    );

    /**
     * @dev revert if minting a quantity of tokens would exceed the maximum supply
     * @param numberOfTokens the quantity of tokens to be minted
     */
    modifier supplyAvailable(uint256 numberOfTokens) {
        if (_totalMinted() + numberOfTokens > MAX_SUPPLY) {
            revert ExceedsMaximumSupply();
        }
        _;
    }

    constructor(bytes32 merkleRoot) ERC721A("CatScientist", "CS") {
        setAllowList(merkleRoot);
        // 10=1%
        setDefaultRoyalty(owner(), 25);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // *************************************************************************
    // CLAIM - Allowlist claim from EOS snapshot
    /**
     * @notice claim tokens 1-for-1 against your EOS holdings at the snapshot.
     *  If EOS holdings were in a different wallet, delegate.cash may be used to
     *  delegate a different wallet to make this claim, e.g. a "hot wallet".
     *  If using delegation, ensure the hot wallet is delegated on the EOS
     *  contract, or the entire vault wallet.
     *  NOTE delegate.cash is an unaffiliated external service, use it at your
     *  own risk! Their docs are available at http://delegate.cash
     *
     * @param numberOfTokens the number of tokens to claim
     * @param tokenQuota the total quota of tokens for the claiming address
     * @param proof the Merkle proof for this claimer
     */
    function mintAllowList(
        uint256 numberOfTokens,
        uint256 tokenQuota,
        bytes32[] calldata proof
    ) external supplyAvailable(numberOfTokens) {
        address claimer = msg.sender;
        // check if the claimer has tokens remaining in their quota
        uint256 tokensClaimed = getAllowListMinted(claimer);
        if (tokensClaimed + numberOfTokens > tokenQuota) {
            revert ExceedsAllowListQuota();
        }

        // check if the claimer is on the allowlist
        if (!onAllowListB(claimer, tokenQuota, proof)) {
            revert NotOnAllowList();
        }

        // claim tokens
        _setAllowListMinted(claimer, numberOfTokens);
        _safeMint(claimer, numberOfTokens);
        emit AllowListClaimMint(claimer, numberOfTokens);
    }

    // *************************************************************************
    // ADMIN & DEV
    /**
     * @dev mint reserved tokens
     * @param to the recipient address
     * @param numberOfTokens the quantity of tokens to mint
     */
    function teamMint(
        address to,
        uint256 numberOfTokens
    ) external supplyAvailable(numberOfTokens) onlyOwner {
        _safeMint(to, numberOfTokens);
    }

    /**
     * @dev set the base URI for the collection, returned from {_baseURI()}
     * @param baseURI_ the new base URI
     */
    function setBaseURI(string calldata baseURI_) public onlyOwner {
        _baseURIextended = baseURI_;
    }

    /**
     * @dev See {ERC721A-_baseURI}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }
    
    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "transfer failed.");
    }
}