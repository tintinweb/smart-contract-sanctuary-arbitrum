pragma solidity ^0.8.0;

import "./IERC20.sol";

contract FaucetTech
{
    address public ownerAddress;
    uint public claimPerWallet;
    uint public timePerClaim;
    bool public gSet;
    uint public gDecimals;
    mapping(address=>uint) public totalClaimedAmount;
    mapping(address=>bool) public claimActive;
    mapping(address=>uint) public claimTimePre;
    mapping(address=>uint) public nextClaimTime;    
    mapping(address=>uint) public claimCount;
    IERC20 gToken;

    constructor() public
    {
        ownerAddress=msg.sender;
        claimPerWallet=8500;
        timePerClaim=60;
        gSet=false;
    }
    modifier onlyOwner
    {
        require(msg.sender==ownerAddress,"Caller is not authorized to make the call");
        _;
    }
    modifier gAddressSet
    {
        require(gSet,"The g Address has not been set yet");
        _;
    }
    function setCAddress(address gAddress,uint decimal) public onlyOwner
    {
        gToken=IERC20(gAddress);
        //g Address set
        gSet=true;
        gDecimals=decimal; //Decimal set;
    }
    function viewFaucetBalance() public view returns(uint)
    {
        return gToken.balanceOf(address(this))/10**gDecimals; //Returns value alongwith Decimals
    }
    function setClaimTime(uint tSec) public onlyOwner
    {
        timePerClaim=tSec; //Setting the claim timer
    }
    function setClaimAmount(uint cAmount) public onlyOwner
    {
        claimPerWallet=cAmount; //Setting the claim amount
    }
    function claimFaucetTokens() public gAddressSet
    {
        if(claimCount[msg.sender]==0)
        {
            //First time claim. Transact through.
            claimTimePre[msg.sender]=block.timestamp;
            nextClaimTime[msg.sender]=claimTimePre[msg.sender]+timePerClaim;
            claimCount[msg.sender]++;
            totalClaimedAmount[msg.sender]+=claimPerWallet;
            //Verify and change values then transfer.
            gToken.transfer(msg.sender,claimPerWallet*10**gDecimals);
        }
        else
        {
            require(block.timestamp>=nextClaimTime[msg.sender],"Claim time not yet matured");
            claimTimePre[msg.sender]=block.timestamp;
            nextClaimTime[msg.sender]=claimTimePre[msg.sender]+timePerClaim;
            claimCount[msg.sender]++;
            totalClaimedAmount[msg.sender]+=claimPerWallet;
            gToken.transfer(msg.sender,claimPerWallet*10**gDecimals); //Claim tokens.
        }
    }
    function withdrawGTokens() public onlyOwner
    {
        gToken.transfer(msg.sender,gToken.balanceOf(address(this))); //Transfers the balance of this contract.
    }
    function getTimeRemaining() public view returns(uint)
    {
        require(claimCount[msg.sender]>0,"No past claims made yet.");
        return nextClaimTime[msg.sender]-block.timestamp;
    }
    function getTotalClaimed() public view returns(uint)
    {
        require(claimCount[msg.sender]>0,"No past claims made yet.");
        return totalClaimedAmount[msg.sender];
    }
    function getClaimCount() public view returns(uint)
    {
        return claimCount[msg.sender];
    }
    function getNextClaimTime() public view returns(uint)
    {
        return nextClaimTime[msg.sender];
    }
}