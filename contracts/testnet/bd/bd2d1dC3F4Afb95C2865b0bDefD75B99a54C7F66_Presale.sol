// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IERC20.sol";

contract Presale {

    // Verification
    bytes32 public originalistMerkleRoot;
    bytes32 public waitlistMerkleRoot;

    // Address Configs
    address public owner;
    address public token;
    address public stable;

    // Sale Details
    uint public saleAmount; // 50,000,000
    uint public privateSaleRatio; // 700 / 1000
    uint public price; //0.007 usdc per token
    uint public maxDeposit; //1000 usdc

    // Sale Progress
    uint public originalistSold;
    uint public waitlistSold;
    uint public publicSold;

    // Sale Stages
    bool public isOriginalistStart;
    bool public isWaitlistStart;
    bool public isPublicStart;
    bool public isClaimStart;

    mapping(address => uint) public alloc;
    mapping(address => uint) public deposit;

    constructor(
        address _token,
        address _stable,
        uint _price,
        uint _saleAmount,
        uint _maxDeposit,
        uint _privateSaleRatio
    ) {
        owner = msg.sender;
        token = _token;
        stable = _stable;
        price = _price;
        saleAmount = _saleAmount;
        maxDeposit = _maxDeposit;
        privateSaleRatio = _privateSaleRatio;
    }
    function depositPublic(uint _stableAmount) public {
        require(_stableAmount > 0, "Amount cannot be zero");
        require(isPublicStart == true, "Public Sale is not available");
        require(
            deposit[msg.sender] + _stableAmount <= maxDeposit,
            "Max alloc reached"
        );

        uint tokenAmt = (_stableAmount * 1e18) / price;
        uint tokenSold = originalistSold + waitlistSold + publicSold;
        require(saleAmount >= tokenAmt + tokenSold, "Insufficient token balance");

        IERC20(stable).transferFrom(msg.sender, owner, _stableAmount);
        deposit[msg.sender] += _stableAmount;

        // Update Alloc
        alloc[msg.sender] += tokenAmt;

        publicSold += tokenAmt;
    }

    function claim() public {
        require(isClaimStart == true, "Claim not allowed");
        require(alloc[msg.sender] > 0, "Nothing to claim");
        IERC20(token).transfer(msg.sender, alloc[msg.sender]);
        alloc[msg.sender] = 0;
    }

    function startOriginalistSale() public onlyOwner {
        isOriginalistStart = true;
    }

    function startWaitlistSale() public onlyOwner {
        isOriginalistStart = false;
        isWaitlistStart = true;
    }

    function startPublicSale() public onlyOwner {
        isWaitlistStart = false;
        isPublicStart = true;
    }

    function endPublicSale() public onlyOwner {
        isPublicStart = false;
    }

    function startClaim() public onlyOwner {
        require(isPublicStart == false, "Presale is open");
        isClaimStart = true;
    }

    function recover() public onlyOwner {
        require(isClaimStart == true, "Claim not allowed");
        uint unsoldAmt = saleAmount - originalistSold - waitlistSold - publicSold;
        IERC20(token).transfer(owner, unsoldAmt);
    }

    function setOwner(address _address) public onlyOwner {
        owner = _address;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
}