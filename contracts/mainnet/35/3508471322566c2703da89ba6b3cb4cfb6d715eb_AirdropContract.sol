// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function burn(uint256 amount) external;
    function decimals() external view returns (uint8);
}

contract AirdropContract {
    address public owner;
    IERC20 public token;
    mapping(address => uint256) public allocations;
    mapping(address => uint256) public claimedAmounts;

    uint256 public totalClaimed;
    uint256 public totalClaimable;
    uint256 public totalBurned = 0;

    address private constant TOKEN_ADDRESS = 0x906fdAeBD56945362e38D8FBA1277793f7cEC95a;

    event AirdropClaimed(address indexed _address, uint256 _amount);
    event TokensBurned(uint256 _amount);

    constructor(address[] memory _addresses, uint256[] memory _amounts) {
        require(_addresses.length == _amounts.length, "Addresses and amounts length mismatch");
        owner = msg.sender;
        token = IERC20(TOKEN_ADDRESS);
        
        uint256 sum = 0;
        
        for (uint i = 0; i < _addresses.length; i++) {
            sum += _amounts[i];
            allocations[_addresses[i]] = _amounts[i];
            totalClaimable += _amounts[i];
        }

        require(sum == 15000000, "Total amounts must equal 15% of the supply");
    }

    modifier ownerOnly() {
        require(msg.sender == owner, "ownerOnly");
        _;
    }

    function claimAirdrop() public {
        uint256 amountToClaim = allocations[msg.sender];
        
        require(amountToClaim > 0, "No allocation for this address");
        require(totalClaimable >= amountToClaim, "Airdrop closed, sorry");

        uint256 adjustedAmountToClaim = amountToClaim * (10 ** token.decimals());
        allocations[msg.sender] = 0;
        claimedAmounts[msg.sender] += amountToClaim;
        totalClaimed += amountToClaim;
        totalClaimable -= amountToClaim;

        require(token.transfer(msg.sender, adjustedAmountToClaim), "Token transfer failed");
        emit AirdropClaimed(msg.sender, adjustedAmountToClaim);
    }

    function burnUnclaimedTokens() public ownerOnly {
        uint256 amountToBurn = totalClaimable;
        require(amountToBurn > 0, "No tokens to burn");

        uint256 adjustedAmountToBurn = amountToBurn * (10 ** token.decimals());

        totalClaimable = 0;
        totalBurned = amountToBurn;

        token.burn(adjustedAmountToBurn);
        emit TokensBurned(adjustedAmountToBurn);
    }

    function getAllocation(address _address) public view returns (uint256) {
        return allocations[_address];
    }

    function getTotalClaimed() public view returns (uint256) {
        return totalClaimed;
    }

    function getTotalClaimable() public view returns (uint256) {
        return totalClaimable;
    }

    function getClaimedAmount(address _address) public view returns (uint256) {
        return claimedAmounts[_address];
    }

    function getTotalBurned() public view returns (uint256) {
        return totalBurned;
    }
}