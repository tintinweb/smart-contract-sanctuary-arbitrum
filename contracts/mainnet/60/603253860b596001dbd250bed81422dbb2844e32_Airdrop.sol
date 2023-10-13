/**
 *Submitted for verification at Arbiscan.io on 2023-10-12
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract Context {
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Claimable is Ownable {
    function claimToken(address tokenAddress, uint256 amount) external onlyOwner {
        IERC20(tokenAddress).transfer(owner(), amount);
    }

    function claimETH(uint256 amount) external onlyOwner {
        (bool sent, ) = owner().call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
}

contract Airdrop is Claimable {
    event Claim(address to, uint256 amount, address referrer, uint256 referrerFee);

    IERC20 public token;

    uint256 public airDropAmount = 100000 * 10**18;
    uint256 public feeAmount = 0.0015 ether;
    uint256 public referrerFeePercentage = 20; // 20% referrer fee
    uint256 public tokenReferrerFeePercentage = 30; // 30% token referrer fee

    mapping(address => address) public referrers;
    bool public isAirdropActive = true;

    modifier onlyAirdropActive() {
        require(isAirdropActive, "Airdrop is not active");
        _;
    }

    function startAirdrop() external onlyOwner {
        isAirdropActive = true;
    }

    function stopAirdrop() external onlyOwner {
        isAirdropActive = false;
    }

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
    }

    function deposit(uint256 _amount) public {
        require(token.transferFrom(msg.sender, address(this), _amount), "Deposit failed");
    }

    function withdraw(uint256 _amount) public onlyOwner {
        require(token.balanceOf(address(this)) >= _amount, "Insufficient balance for withdrawal");
        require(token.transfer(owner(), _amount), "Withdraw failed");
    }

    function setClaimFees(uint256 _feeAmount) external onlyOwner {
        feeAmount = _feeAmount;
    }

    function setReferrerFees(uint256 _referrerFeePercentage, uint256 _tokenReferrerFeePercentage) external onlyOwner {
        referrerFeePercentage = _referrerFeePercentage;
        tokenReferrerFeePercentage = _tokenReferrerFeePercentage;
    }

    function setAirdropClaimAmount(uint256 _airDropAmount) external onlyOwner {
        airDropAmount = _airDropAmount;
    }

    function setReferrer(address _user, address _referrer) external onlyOwner {
        referrers[_user] = _referrer;
    }

    function airdrop() public payable onlyAirdropActive {
        require(msg.value >= feeAmount, "Fee is too small.");

        address referrer = referrers[_msgSender()];
        uint256 referrerEthFee = (msg.value * referrerFeePercentage) / 100;

        if (referrer != address(0) && referrerEthFee > 0) {
            require(referrer.balance >= referrerEthFee, "Insufficient balance for referrer fee");
            (bool successReferrer, ) = referrer.call{value: referrerEthFee}("");
            require(successReferrer, "Failed to send Ether to referrer");
        }

        require(token.balanceOf(address(this)) >= airDropAmount, "Insufficient balance for airdrop");
        require(token.transfer(_msgSender(), airDropAmount), "Airdrop failed");
        emit Claim(_msgSender(), airDropAmount, referrer, referrerEthFee);

        uint256 ownerEthFee = msg.value - referrerEthFee;
        require(owner().balance >= ownerEthFee, "Insufficient balance for owner fee");
        (bool successOwner, ) = owner().call{value: ownerEthFee}("");
        require(successOwner, "Failed to send Ether to contract owner");
    }

    receive() external payable {}

    fallback() external payable {}
}