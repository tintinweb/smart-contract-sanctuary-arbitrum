/**
 *Submitted for verification at Arbiscan.io on 2024-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ProjectRegistry {
    struct Project {
        string name;
        string ipfsHash;
        address projectOwner;
        bool allTokensSold;
        uint256 tokenPrice;
        uint256 totalTokens;
        uint256 totalFunding;
        address[] funders;  // List of funders for each project
        uint8 milestone;
        uint8 funder_ownership; // New field
            }

    Project[] public projects;

    // Mapping for quick lookup
    mapping(string => uint256) public projectNameToIndex;
    mapping(string => mapping(address => uint256)) public funderContributions;

    
    event AllTokensSold(string projectName);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    mapping(string => bool) public projectNameExists;
    address public nftContractAddress;
    address public claimContractAddress;  // New variable for claim contract's address
    address public owner;
    address public newOwner;

    event ProjectRegistered(string name, string ipfsHash);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function claimOwnership() public {
        require(msg.sender == newOwner, "Ownable: caller is not the new owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }

    /**
     * @dev Allows the owner to set the address of the claim contract.
     * @param _address The address of the claim contract.
     */
    function setClaimContractAddress(address _address) public onlyOwner {
        claimContractAddress = _address;
    }

   
    function registerProject(string memory _name, string memory _ipfsHash, uint8 _funderOwnership) public {
        require(!projectNameExists[_name], "Project name already exists");
        projects.push(Project({
            name: _name,
            ipfsHash: _ipfsHash,
            projectOwner: msg.sender,
            allTokensSold: false,
            tokenPrice: 0,
            totalTokens: 0,
            totalFunding: 0,
            funders: new address[](0),
            milestone: 0,
            funder_ownership: _funderOwnership// Initializing the funder_ownership here
        }));
        
        // Update lookup mapping
        projectNameToIndex[_name] = projects.length - 1;
        
        projectNameExists[_name] = true;
        emit ProjectRegistered(_name, _ipfsHash);
    }

    function setNFTContractAddress(address _address) public onlyOwner {
        nftContractAddress = _address;
    }

    function setAllTokensSold(string memory _name) public {
        require(msg.sender == nftContractAddress || msg.sender == owner, "Unauthorized");

        uint256 index = projectNameToIndex[_name];
        projects[index].allTokensSold = true;
        emit AllTokensSold(_name);
    }

    function setProjectDetails(string memory _name, uint256 _tokenPrice, uint256 _totalTokens, uint256 _totalFunding) public {
        require(msg.sender == nftContractAddress, "Unauthorized");

        uint256 index = projectNameToIndex[_name];
        projects[index].tokenPrice = _tokenPrice;
        projects[index].totalTokens = _totalTokens;
        projects[index].totalFunding = _totalFunding;
    }

    function getTotalProjects() public view returns (uint) {
        return projects.length;
    }

    function projectExists(string memory _name) public view returns (bool) {
        return projectNameExists[_name];
    }

    function isProjOwner(string memory _name, address _address) public view returns (bool) {
        uint256 index = projectNameToIndex[_name];
        require(projectNameExists[_name], "Project does not exist");
        return projects[index].projectOwner == _address;
    }

    function getProjectDetails(string memory _name) public view returns (
        string memory name,
        string memory ipfsHash,
        address projectOwner,
        bool allTokensSold,
        uint256 tokenPrice,
        uint256 totalTokens,
        uint256 totalFunding
    ) {
        require(projectNameExists[_name], "Project does not exist");
        
        uint256 index = projectNameToIndex[_name];
        Project memory proj = projects[index];

        return (
            proj.name,
            proj.ipfsHash,
            proj.projectOwner,
            proj.allTokensSold,
            proj.tokenPrice,
            proj.totalTokens,
            proj.totalFunding
        );
    }

    /**
     * @dev Adds a funder's address for a specific project. 
     * This can only be called by the NFT contract or the contract owner.
     */
   function addFunder(string memory _name, address _funder, uint256 _contribution) public {
    require(msg.sender == nftContractAddress || msg.sender == owner, "Unauthorized");
    require(projectNameExists[_name], "Project does not exist");
    
    uint256 index = projectNameToIndex[_name];

    // Check if this is the first time the user is funding the project
    if (!isFunderOfProject(_name, _funder)) {
        projects[index].funders.push(_funder);
    }

    // Update the funder's contribution
    funderContributions[_name][_funder] += _contribution;
}


    /**
     * @dev Returns the list of funders for a specific project.
     */
    function getProjectFunders(string memory _name) public view returns (address[] memory) {
        require(projectNameExists[_name], "Project does not exist");
        
        uint256 index = projectNameToIndex[_name];
        return projects[index].funders;
    }

    function areAllTokensSold(string memory _name) public view returns (bool) {
        require(projectNameExists[_name], "Project does not exist");
        
        uint256 index = projectNameToIndex[_name];
        return projects[index].allTokensSold;
    }

     function setMilestone(string memory _name, uint8 _milestone) public {
        require(msg.sender == claimContractAddress, "Unauthorized");  // Modified this line
        require(projectNameExists[_name], "Project does not exist");
        require(_milestone >= 1 && _milestone <= 4, "Milestone value should be between 1 and 4");

        uint256 index = projectNameToIndex[_name];
        projects[index].milestone = _milestone;
    }

    function getTotalFundingOfProject(string memory _name) public view returns (uint256) {
        require(projectNameExists[_name], "Project does not exist");
        
        uint256 index = projectNameToIndex[_name];
        return projects[index].totalFunding;
    }

    /**
     * @dev Returns the milestone of a specific project.
     */
    function getProjectMilestone(string memory _name) public view returns (uint8) {
        require(projectNameExists[_name], "Project does not exist");
        
        uint256 index = projectNameToIndex[_name];
        return projects[index].milestone;
    }

    /**
     * @dev Returns the total number of funders for a specific project.
     */
    function getTotalFundersOfProject(string memory _name) public view returns (uint256) {
        require(projectNameExists[_name], "Project does not exist");
        
        uint256 index = projectNameToIndex[_name];
        return projects[index].funders.length;
    }

    /**
     * @dev Checks if an address is a funder of a specific project.
     */
    function isFunderOfProject(string memory _name, address _funder) public view returns (bool) {
        require(projectNameExists[_name], "Project does not exist");
        
        uint256 index = projectNameToIndex[_name];
        for (uint i = 0; i < projects[index].funders.length; i++) {
            if (projects[index].funders[i] == _funder) {
                return true;
            }
        }
        return false;
    }

    /**
 * @dev Returns the funder ownership percentage of a specific project.
 */
function getFunderOwnership(string memory _name) public view returns (uint8) {
    require(projectNameExists[_name], "Project does not exist");
    
    uint256 index = projectNameToIndex[_name];
    return projects[index].funder_ownership;
}



function getFundersContribution(string memory _projectName, address _funder) public view returns (uint256) {
    require(projectNameExists[_projectName], "Project does not exist");
    return funderContributions[_projectName][_funder];
}

}