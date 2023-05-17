/**
 *Submitted for verification at Arbiscan on 2023-05-15
*/

//SPDX-License-Identifier: MIT Licensed
pragma solidity ^0.8.10;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function tokensForSale() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external;

    function transfer(address to, uint256 value) external;

    function transferFrom(address from, address to, uint256 value) external;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
} 

contract tokenAirdrop {
    IERC20 public token;

    address payable public owner;
    bytes32 public merkleRoot;

    uint256 public TokenPerUser;
    uint256 public TokenPerDollar;
    uint256 public totalUsersClaimed;
    uint256 public claimedToken;
    uint256 public totalFreeClaimable = 25_000_000 ether;
    uint256 public boughtTokens;
    uint256 public totalPaidClaimable = 25_000_000 ether;
    uint256 public ethPerDollar = 0.00053 ether;
    uint256 public maxClaimPerUser = 0.0053 ether;
    uint256 public hardcap = 2.615 ether;
    uint256 public totalCollected;

    struct user {
        uint256 Eth_balance;
        uint256 token_balance;
    }

    mapping(address => user) public users;
    mapping(address => bool) public _isClaimed;

    bool public enableClaim = true;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not an owner");
        _;
    }

    event ClaimToken(address indexed _user, uint256 indexed _amount);

    constructor() {
        owner = payable(0x5f01B0bd1f6C55996081C624653E3cb9a655E155);
        token = IERC20(0xd5B3539AE886135Fdf65870ddeD2F469759d922E);
        TokenPerUser = 5_000 ether;
        TokenPerDollar = 5_000 ether;
    }

    function ClaimWL() public {
        require(enableClaim == true, "Claim not active yet"); 
        require(!_isClaimed[msg.sender], "already claimed");
        require(totalUsersClaimed < 5000, "First 5000 Users claimed");

        token.transfer(msg.sender, TokenPerUser);
        _isClaimed[msg.sender] = true;
        totalUsersClaimed++;
        claimedToken += TokenPerUser;

        emit ClaimToken(msg.sender, TokenPerUser);
    }

    function ClaimOneDollar() public payable {
        require(enableClaim == true, "Claim not active yet");
        require(
            msg.value >= ethPerDollar,
            "you must have eth having worth equal to $1"
        );
        require(
            users[msg.sender].Eth_balance + msg.value <= maxClaimPerUser,
            "max claim per user met"
        );
        require(totalCollected + msg.value <= hardcap, "hardcap reached");
        uint256 numberOfTokens;
        numberOfTokens = EthToToken(msg.value);
        token.transfer(msg.sender, numberOfTokens);
        users[msg.sender].Eth_balance += msg.value;
        users[msg.sender].token_balance += numberOfTokens;
        totalCollected += msg.value;

        boughtTokens += numberOfTokens;

        emit ClaimToken(msg.sender, numberOfTokens);
    }

    // to check number of token for given eth
    function EthToToken(uint256 _amount) public view returns (uint256) {
        uint256 numberOfTokens = (_amount * (TokenPerDollar)) / ethPerDollar;
        return numberOfTokens;
    }

    function changeLimits(
        uint256 _ethPerDollar,
        uint256 _maxClaimPerUser,
        uint256 _hardcap
    ) external onlyOwner {
        ethPerDollar = _ethPerDollar;
        maxClaimPerUser = _maxClaimPerUser;
        hardcap = _hardcap;
    }

    function setMerkleRoot(bytes32 merkleRootHash) external onlyOwner {
        merkleRoot = merkleRootHash;
    }

    function toBytes32(address addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    function EnableClaim(bool _claim) public onlyOwner {
        enableClaim = _claim;
    }

    // transfer ownership
    function changeOwner(address payable _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    // change tokens
    function changeToken(address _token) external onlyOwner {
        token = IERC20(_token);
    }

    // to draw funds for liquidity
    function transferFundsEth(uint256 _value) external onlyOwner {
        owner.transfer(_value);
    }

    // to draw out tokens
    function transferTokens(IERC20 TOKEN, uint256 _value) external onlyOwner {
        TOKEN.transfer(msg.sender, _value);
    }
}