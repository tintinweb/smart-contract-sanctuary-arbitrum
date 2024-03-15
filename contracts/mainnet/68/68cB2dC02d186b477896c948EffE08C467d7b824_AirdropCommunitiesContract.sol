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

  mapping(address => string[]) public userGroups;
  mapping(string => uint256) public groupClaimed;
  mapping(address => bool) public globalClaimed;

  string[] public groupNames = ["Pyth", "GMX", "HyperLiquid", "Mux", "Vertex"];
  uint256 private constant TOKENS_PER_ADDRESS = 1000;
  uint256 private constant MAX_TOKENS_PER_GROUP = 500000;

  address private constant TOKEN_ADDRESS = 0x964CBf436Ddb782d09465930ce8b431311Cb54f4;

  event AirdropClaimed(address indexed _address, uint256 _amount);

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
      userGroups[_addresses[i]].push(_groupName);
    }
  }

  function claimAirdrop() public {
    require(!globalClaimed[msg.sender], "Airdrop already claimed");
    require(userGroups[msg.sender].length > 0, "Address not whitelisted");

    bool allocated = false;
    for (uint i = 0; i < userGroups[msg.sender].length && !allocated; i++) {
      string memory groupName = userGroups[msg.sender][i];
      if (groupClaimed[groupName] + TOKENS_PER_ADDRESS <= MAX_TOKENS_PER_GROUP) {
        groupClaimed[groupName] += TOKENS_PER_ADDRESS;
        allocated = true;
      }
    }

    require(allocated, "Community allocation depleted");
    globalClaimed[msg.sender] = true;

    uint256 amountToClaim = TOKENS_PER_ADDRESS * (10 ** token.decimals());
    require(token.transfer(msg.sender, amountToClaim), "Token transfer failed");
    emit AirdropClaimed(msg.sender, amountToClaim);
  }

  function withdrawUnclaimedTokens() public ownerOnly {
    uint256 contractTokenBalance = token.balanceOf(address(this));
    require(contractTokenBalance > 0, "No tokens to withdraw");
    require(token.transfer(owner, contractTokenBalance), "Withdrawal failed");
  }

  function isEligible(address _address) public view returns (bool) {
    return userGroups[_address].length > 0 && !globalClaimed[_address];
  }

  function isAllocationAvailable(address _address) public view returns(bool) {
    if (!isEligible(_address)) {
      return false;
    }
    for (uint i = 0; i < userGroups[_address].length; i++) {
      string memory groupName = userGroups[_address][i];
      if (groupClaimed[groupName] + TOKENS_PER_ADDRESS <= MAX_TOKENS_PER_GROUP) {
        return true;
      }
    }
    return false;
  }

  function hasClaimed(address _address) public view returns (bool) {
    return globalClaimed[_address];
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