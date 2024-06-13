// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC721URIStorage.sol";
import "../Counters.sol";

interface IProjectRegistry {
    function projectExists(string memory _name) external view returns (bool);
    function isProjOwner(string memory _name, address _address) external view returns (bool);
    function setAllTokensSold(string memory _name) external;
    function setProjectDetails(string memory _name, uint256 _tokenPrice, uint256 _totalTokens, uint256 _totalFunding) external;
    function addFunder(string memory _name, address _funder, uint256 _contribution) external;
}

contract OpenFilmsMainNFTContract is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    IProjectRegistry public projectRegistry;
    address public owner;
    address public pendingOwner;
    address public claimAddress; // Address where funds will go after NFT is bought

    mapping(string => uint256) public nftPrice;
    mapping(string => uint256) public collectedFunding;
    mapping(uint256 => string) public tokenIdToProjectName;
    mapping(string => bool) public mintedProjects;
    mapping(string => uint256) public projectTotalFundingRequirement;
    mapping(string => string) public projectTokenURIs;
    mapping(string => uint256[]) public projectTokenIDs; // Maps project names to token ID arrays
    mapping(string => uint256) public tokensMintedForProject;

    event Minted(address indexed projectOwner, string indexed projectName, uint256 numberOfTokens, string tokenURI);
    event Purchased(address indexed buyer, string indexed projectName, uint256 tokenQuantity, uint256 totalCost);
    event RegistryAddressSet(address indexed setter, address indexed registryAddress);
    event ClaimAddressSet(address indexed setter, address indexed newClaimAddress);
    event OwnershipTransferInitiated(address indexed initialOwner, address indexed pendingOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() ERC721("OpenFilms", "OFM") {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    function setRegistryAddress(address _projectRegistryAddress) external onlyOwner {
        projectRegistry = IProjectRegistry(_projectRegistryAddress);
        emit RegistryAddressSet(msg.sender, _projectRegistryAddress);
    }
    
    function setClaimAddress(address _claimAddress) external onlyOwner {
        claimAddress = _claimAddress;
        emit ClaimAddressSet(msg.sender, _claimAddress);
    }

    function mintNFT(
    string memory projectName,
    uint256 totalFundingRequirement,
    string memory tokenURI,
    uint256 totalTokens // Added to specify the total number of tokens
) public {
    require(projectRegistry.projectExists(projectName), "Project does not exist");
    require(projectRegistry.isProjOwner(projectName, msg.sender), "Only the project owner can mint");
    require(!mintedProjects[projectName], "Tokens for this project have already been minted.");

    uint256 priceInWei = totalFundingRequirement / totalTokens;
    nftPrice[projectName] = priceInWei;
    projectTotalFundingRequirement[projectName] = totalFundingRequirement;
    projectRegistry.setProjectDetails(projectName, priceInWei, totalTokens, totalFundingRequirement);
    mintedProjects[projectName] = true;
    projectTokenURIs[projectName] = tokenURI;

    // Remove actual token minting logic from here
}
function buyNFT(string memory projectName) public payable {
    require(msg.value > 0, "Must send some Ether");
    uint256 tokenPrice = nftPrice[projectName];
    uint256 totalTokensAllowed = projectTotalFundingRequirement[projectName] / tokenPrice;
    uint256 tokensAvailable = totalTokensAllowed - tokensMintedForProject[projectName];
    uint256 numberOfTokens = msg.value / tokenPrice;

    if (numberOfTokens > tokensAvailable) {
        numberOfTokens = tokensAvailable; // Limit to available tokens
    }
    require(numberOfTokens > 0, "No tokens available to purchase");

    uint256 spentAmount = numberOfTokens * tokenPrice;
    uint256 refundAmount = msg.value - spentAmount;

    require(collectedFunding[projectName] + spentAmount <= projectTotalFundingRequirement[projectName], "Project has reached its funding requirement");

    for (uint256 i = 0; i < numberOfTokens; i++) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, projectTokenURIs[projectName]);
        tokenIdToProjectName[newTokenId] = projectName;
        projectTokenIDs[projectName].push(newTokenId);
    }
    tokensMintedForProject[projectName] += numberOfTokens;

    // Ensure claimAddress is set and not zero
    require(claimAddress != address(0), "Claim address not set");

    // Transfer the spent amount to the claim address
    payable(claimAddress).transfer(spentAmount);
    collectedFunding[projectName] += spentAmount;

    if (refundAmount > 0) {
        payable(msg.sender).transfer(refundAmount);
    }

    if (tokensMintedForProject[projectName] == totalTokensAllowed) {
        projectRegistry.setAllTokensSold(projectName);
    }

    projectRegistry.addFunder(projectName, msg.sender, spentAmount);
    emit Purchased(msg.sender, projectName, numberOfTokens, spentAmount);
}
    function getProjectTokenIDs(string memory projectName) public view returns (uint256[] memory) {
        return projectTokenIDs[projectName];
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0) && newOwner != owner, "Invalid new owner address");
        pendingOwner = newOwner;
        emit OwnershipTransferInitiated(owner, pendingOwner);
    }

    function claimOwnership() public {
        require(msg.sender == pendingOwner, "Not the pending owner");
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}