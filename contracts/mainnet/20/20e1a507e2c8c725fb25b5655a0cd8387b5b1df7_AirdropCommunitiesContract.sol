// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
}

contract AirdropCommunitiesContract {
    address public owner;
    IERC20 public token;

    mapping(address => string) public userGroup;
    mapping(string => uint256) public groupClaimed;
    mapping(address => bool) public globalClaimed;

    string[] public groupNames = ["Pyth", "GMX", "Mux", "HyperLiquid", "Vertex"];
    uint256 private constant TOKENS_PER_ADDRESS = 1000;
    uint256 private constant MAX_TOKENS_PER_GROUP = 500000;

    address private constant TOKEN_ADDRESS = 0x6d7E759aFfCcE48BF0Ad33FEBcd99C2bC78d9a1d;

    event AirdropClaimed(address indexed _address, uint256 _amount, string group);

    constructor() {
        owner = msg.sender;
        token = IERC20(TOKEN_ADDRESS);
    }

    modifier ownerOnly() {
        require(msg.sender == owner, "Owner only action");
        _;
    }

    function whitelistAddresses(address[] memory _addresses, string memory _groupName) public ownerOnly {
        require(isValidGroup(_groupName), "Invalid group name");
        for (uint i = 0; i < _addresses.length; i++) {
            userGroup[_addresses[i]] = _groupName;
        }
    }

    function claimAirdrop() public {
        require(!globalClaimed[msg.sender], "Airdrop already claimed");
        string memory groupName = userGroup[msg.sender];
        require(bytes(groupName).length > 0, "Address not whitelisted");
        require(groupClaimed[groupName] + TOKENS_PER_ADDRESS <= MAX_TOKENS_PER_GROUP, "Community allocation depleted");

        uint256 amountToClaim = TOKENS_PER_ADDRESS * (10 ** token.decimals());
        groupClaimed[groupName] += TOKENS_PER_ADDRESS;
        globalClaimed[msg.sender] = true;

        require(token.transfer(msg.sender, amountToClaim), "Token transfer failed");
        emit AirdropClaimed(msg.sender, amountToClaim, groupName);
    }

    function withdrawUnclaimedTokens() public ownerOnly {
        uint256 contractTokenBalance = token.balanceOf(address(this));
        require(contractTokenBalance > 0, "No tokens to withdraw");
        require(token.transfer(owner, contractTokenBalance), "Withdrawal failed");
    }  

    function getClaimedTokensByGroup(string memory _groupName) public view returns (uint256) {
        require(isValidGroup(_groupName), "Invalid group name");
        return groupClaimed[_groupName];
    }

    function isValidGroup(string memory _groupName) internal view returns (bool) {
        for (uint i = 0; i < groupNames.length; i++) {
            if (keccak256(bytes(groupNames[i])) == keccak256(bytes(_groupName))) {
                return true;
            }
        }
        return false;
    }
}