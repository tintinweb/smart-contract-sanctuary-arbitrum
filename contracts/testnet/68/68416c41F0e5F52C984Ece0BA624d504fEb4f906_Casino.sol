/**
 *Submitted for verification at Arbiscan on 2023-07-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;




interface ChipInterface {
    function mint(address _to, uint256 _amount) external;
    function burn(address _to, uint256 _amount) external;
}

contract Casino {
    ChipInterface public chipContract;

    address payable owner;
    uint256 public chipPrice = .001 ether;
    uint256 public membershipFee = .015 ether;
    uint48 public initialChipCount = 500;

    event ChipsGiven(address indexed user, uint48 amount, uint48 timestamp);
    event ChipsPurchased(address indexed user, uint48 amount, uint48 timestamp);
    event ChipsTaken(address indexed user, uint48 amount, uint48 timestamp);
    event NewMember(address indexed player, uint48 timestamp, uint48 initialChipCount);
    address[] memberAddresses;
    mapping(address => bool) public members;
    mapping(address => bool) games;

    constructor(address chips) {
        chipContract = ChipInterface(chips);
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can use this function.");
        _;
    }

    modifier onlyGames() {
        require(games[msg.sender], "Only games can use this function.");
        _;
    }

    function transferOwnership(address payable newOwner) public onlyOwner {
        owner = newOwner;
    }

    function setChipContract(address newContract, bool supplyMembers)
        public
        onlyOwner
    {
        chipContract = ChipInterface(newContract);
        if (supplyMembers) {
            for (uint256 i = memberAddresses.length - 1; i >= 0; i--) {
                chipContract.mint(memberAddresses[i], initialChipCount);
            }
        }
    }

    function setInitialChipCount(uint48 newChipCount) public onlyOwner {
        initialChipCount = newChipCount;
    }

    function setMembershipFee(uint256 fee) public onlyOwner {
        membershipFee = fee;
    }

    function setChipPrice(uint256 price) public onlyOwner {
        chipPrice = price;
    }

    function joinCasino() public payable {
        require(!members[msg.sender], "You are already a member of the casino.");
        require(msg.value == membershipFee, "Must send membershipFee");
        owner.transfer(msg.value);
        memberAddresses.push(msg.sender);
        members[msg.sender] = true;
        chipContract.mint(msg.sender, initialChipCount);
        emit NewMember(msg.sender, uint48(block.timestamp), initialChipCount);
    }
    
    function buyChips(uint48 amount) public payable {
        require(members[msg.sender], "You must be a member to buy chips.");
        require(msg.value == amount * chipPrice, "Must send correct amount.");
        owner.transfer(msg.value);
        emit ChipsPurchased(msg.sender, amount, uint48(block.timestamp));
        chipContract.mint(msg.sender, amount);
        emit ChipsGiven(msg.sender, amount, uint48(block.timestamp));
    }

    function giveChips(address to, uint48 amount) public onlyGames {
        chipContract.mint(to, amount);
        emit ChipsGiven(to, amount, uint48(block.timestamp));
    }

    function takeChips(address from, uint48 amount) public onlyGames {
        chipContract.burn(from, amount);
        emit ChipsTaken(from, amount, uint48(block.timestamp));
    }

    function addGame(address game) public onlyOwner {
        games[game] = true;
    }

    function removeGame(address game) public onlyOwner {
        games[game] = false;
    }

    function isGame(address _address) public view returns (bool) {
        return games[_address];
    }

    function isMember(address _address) public view returns (bool) {
        return members[_address];
    }
}