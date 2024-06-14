/**
 *Submitted for verification at Arbiscan.io on 2024-06-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProjectRegistry {
    function getTotalFundingOfProject(string memory _name) external view returns (uint256);
    function isFunderOfProject(string memory _name, address _funder) external view returns (bool);
    function getFunderOwnership(string memory _name) external view returns (uint8);
    function isProjOwner(string memory _name, address _address) external view returns (bool);
    function getFundersContribution(string memory _name, address _funder) external view returns (uint256);
}

interface IOpenFilmsMainNFTContract {
    function getProjectTokenIDs(string memory projectName) external view returns (uint256[] memory);
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract ReleaseContract {
    struct Movie {
        string ipfsHash;
        uint256 viewCost;
        uint256 totalRevenue;
        address[] viewers;
        uint256 revenuePerToken; // Total revenue accrued per token
    }

    struct RevenueLedger {
        uint256 creatorShare;
        uint256 fundersPool;
        uint256 OFShare;
    }

    address public owner;
    address public pendingOwner;
    address public openFilmsWallet;
    IProjectRegistry public projectRegistry;
    IOpenFilmsMainNFTContract public openFilmsNFTContract;
    mapping(string => Movie) public movies;
    mapping(string => RevenueLedger) public revenueLedgers;
    mapping(uint256 => uint256) public revenuePerToken; // Revenue per token
    mapping(uint256 => uint256) public tokenClaimedRevenue; // Revenue claimed per token
    uint256 public totalOFShare;
    string[] private allMovieNames;

    event MovieReleased(string projectName, string ipfsHash);
    event MovieWatched(string projectName, address viewer);
    event CreatorWithdrawal(string projectName, address indexed creator, uint256 amount);
    event FunderWithdrawal(string projectName, address indexed funder, uint256 amount);
    event MovieDetailsUpdated(string projectName, string newIpfsHash, uint256 newViewCost);
    event OwnershipTransferInitiated(address indexed initialOwner, address indexed pendingOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event RevenueClaimed(uint256 tokenId, address indexed claimant, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    function setProjectRegistryAddress(address _projectRegistryAddress) public onlyOwner {
        projectRegistry = IProjectRegistry(_projectRegistryAddress);
    }

    function setOpenFilmsWallet(address _openFilmsWallet) public onlyOwner {
    require(_openFilmsWallet != address(0), "Invalid address");
    openFilmsWallet = _openFilmsWallet;
}

    function setNFTContractAddress(address _nftContractAddress) public onlyOwner {
        openFilmsNFTContract = IOpenFilmsMainNFTContract(_nftContractAddress);
    }

    function releaseMovie(string memory _projectName, string memory _ipfsHash, uint256 _viewCost) public {
        require(bytes(movies[_projectName].ipfsHash).length == 0, "Movie already released");
        require(projectRegistry.isProjOwner(_projectName, msg.sender), "Only the project owner can release the movie");

        movies[_projectName] = Movie({
            ipfsHash: _ipfsHash,
            viewCost: _viewCost,
            totalRevenue: 0,
            viewers: new address[](0) ,
            revenuePerToken: 0
        });
        allMovieNames.push(_projectName);
        emit MovieReleased(_projectName, _ipfsHash);
    }

    function watch(string memory _projectName) public payable {
        require(msg.value == movies[_projectName].viewCost, "Incorrect view cost provided");
        
        uint256 ofShare = (msg.value * 5) / 100; // OF_SHARE_PERCENTAGE assumed as 5%
        uint256 fundersShare = (msg.value * projectRegistry.getFunderOwnership(_projectName)) / 100;
        uint256 creatorsShare = msg.value - (ofShare + fundersShare);

        uint256[] memory tokenIds = openFilmsNFTContract.getProjectTokenIDs(_projectName);
        uint256 revenuePerTokenIncrement = fundersShare / tokenIds.length;

        for (uint i = 0; i < tokenIds.length; i++) {
            revenuePerToken[tokenIds[i]] += revenuePerTokenIncrement;
        }

        movies[_projectName].totalRevenue += msg.value - ofShare;
        movies[_projectName].viewers.push(msg.sender);

        revenueLedgers[_projectName].creatorShare += creatorsShare;
        revenueLedgers[_projectName].fundersPool += fundersShare;
        revenueLedgers[_projectName].OFShare += ofShare;

        totalOFShare += ofShare;

        emit MovieWatched(_projectName, msg.sender);
    }

    function claimAllRevenueAsFunder(string memory _projectName) public {
        uint256[] memory tokenIds = openFilmsNFTContract.getProjectTokenIDs(_projectName);
        uint256 totalClaimableAmount = 0;

        for (uint i = 0; i < tokenIds.length; i++) {
            if (openFilmsNFTContract.ownerOf(tokenIds[i]) == msg.sender) {
                uint256 claimable = revenuePerToken[tokenIds[i]] - tokenClaimedRevenue[tokenIds[i]];
                totalClaimableAmount += claimable;
                tokenClaimedRevenue[tokenIds[i]] = revenuePerToken[tokenIds[i]]; // Update claimed revenue
            }
        }

        require(totalClaimableAmount > 0, "No revenue available to claim");
        payable(msg.sender).transfer(totalClaimableAmount);

        emit FunderWithdrawal(_projectName, msg.sender, totalClaimableAmount);
    }

    function withdrawAsCreator(string memory _projectName) public {
        require(projectRegistry.isProjOwner(_projectName, msg.sender), "Only the project owner can withdraw");
        uint256 creatorsShare = revenueLedgers[_projectName].creatorShare;
        payable(msg.sender).transfer(creatorsShare);
        revenueLedgers[_projectName].creatorShare = 0;
        emit CreatorWithdrawal(_projectName, msg.sender, creatorsShare);
    }

    function OFWithdraw() public onlyOwner {
    require(openFilmsWallet != address(0), "OpenFilms Wallet not set");
    payable(openFilmsWallet).transfer(totalOFShare);
    totalOFShare = 0;
}


    function updateMovieDetails(string memory _projectName, string memory _newIpfsHash, uint256 _newViewCost) public {
        require(projectRegistry.isProjOwner(_projectName, msg.sender), "Only the project owner can update the movie details");
        require(bytes(movies[_projectName].ipfsHash).length != 0, "Movie not found");

        movies[_projectName].ipfsHash = _newIpfsHash;
        movies[_projectName].viewCost = _newViewCost;

        emit MovieDetailsUpdated(_projectName, _newIpfsHash, _newViewCost);
    }

    function isViewer(string memory _projectName, address _viewer) public view returns (bool) {
        require(bytes(movies[_projectName].ipfsHash).length != 0, "Movie not found");
        
        for (uint i = 0; i < movies[_projectName].viewers.length; i++) {
            if (movies[_projectName].viewers[i] == _viewer) {
                return true;
            }
        }
        return false;
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

    function getAllMovies() public view returns (string[] memory, string[] memory) {
        uint256 movieCount = allMovieNames.length;
        string[] memory projectNames = new string[](movieCount);
        string[] memory ipfsHashes = new string[](movieCount);

        for (uint256 i = 0; i < movieCount; i++) {
            string memory projectName = allMovieNames[i];
            Movie storage movie = movies[projectName];
            projectNames[i] = projectName;
            ipfsHashes[i] = movie.ipfsHash;
        }

        return (projectNames, ipfsHashes);
    }
}