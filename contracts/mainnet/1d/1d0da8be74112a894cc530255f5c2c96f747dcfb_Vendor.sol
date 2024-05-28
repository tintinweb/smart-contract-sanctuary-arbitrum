// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./Strings.sol";
import "./VIPToken.sol";
import "./AffiliateProgram.sol";
import "./TransactionHistory.sol";
import "./TransactionId.sol";
import "./ERC2771ElevatedPriviliges.sol";

interface IERC20WithPermit is IERC20 {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

contract Vendor is ERC2771ElevatedPriviliges {
    VIPToken vipToken;
    address payable private receiverWalletAddress;
    uint256 internal _usdPricePerToken;
    uint256 internal _salesCap;
    uint256 internal _purchasedVolume;
    bool internal _isBuyTokenAllowed;
    IERC20WithPermit internal _usdc;
    AffiliateProgram internal _affiliateProgram;
    TransactionHistory internal _transactionHistory;
    event BuyTokensFromUsdcSuccess(bytes32 transactionHash, string transactionSequenceNumber);

    struct TransactionDetails {
        bytes32 walletHash;
        string transactionSequenceNumber;
        string affiliateCode;
        uint256 amountToBuy;
        uint256 bonusAmount;
        uint256 usdcAmount;
        uint256 timestamp;
    }

    constructor(VIPToken token, address ownerOverride, address payable receiverWalletAddress_, address usdcAddress, address affiliateProgramAddress, address transactionHistoryAddress, address trustedForwarder) ERC2771ElevatedPriviliges(trustedForwarder) {
        transferOwnership(ownerOverride);
        vipToken = VIPToken(token);
        _affiliateProgram = AffiliateProgram(affiliateProgramAddress);
        _transactionHistory = TransactionHistory(transactionHistoryAddress);
        receiverWalletAddress = receiverWalletAddress_;
        _usdPricePerToken = 5 * 10 ** 16;
        _salesCap = 25 * 10 ** 6 * 10 ** 18;
        _purchasedVolume = 149260 * 10 ** 18;
        _isBuyTokenAllowed = true;
        _usdc = IERC20WithPermit(usdcAddress);
    }

    function buyTokensFromUsdc(uint256 usdcAmount, string memory _affiliateCode, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public onlyOpenSales {
        _usdc.permit(_msgSender(), address(this), usdcAmount, deadline, v, r, s);
        
        require(_usdc.balanceOf(_msgSender()) >= usdcAmount, "Not enough Usdc.");
        require(_usdc.transferFrom(_msgSender(), receiverWalletAddress, usdcAmount), "Failed to transfer USDC.");

        (uint256 amountToBuy, uint256 bonusAmount, uint256 overallAmount) = _calculateTokensForUsdc(usdcAmount, _affiliateCode);
        
        require(_purchasedVolume + amountToBuy <= _salesCap, "Denied: Token purchase would exceed sales cap.");
        vipToken.airdropToken(_msgSender(), overallAmount);
        _purchasedVolume = _purchasedVolume + amountToBuy;

        TransactionDetails memory txDetails = TransactionDetails({
            walletHash: TransactionId.hashWalletAddress(_msgSender()),
            transactionSequenceNumber: TransactionId.createSequenceNumber(block.timestamp),
            affiliateCode: _affiliateCode,
            amountToBuy: amountToBuy,
            bonusAmount: bonusAmount,
            usdcAmount: usdcAmount,
            timestamp: block.timestamp
        });

        _transactionHistory.addTransaction(
            txDetails.walletHash,
            txDetails.transactionSequenceNumber,
            txDetails.affiliateCode,
            txDetails.amountToBuy,
            txDetails.bonusAmount,
            txDetails.usdcAmount,
            txDetails.timestamp
        );

        emit BuyTokensFromUsdcSuccess(txDetails.walletHash, txDetails.transactionSequenceNumber);
    }

    function _calculateTokensForUsdc(uint256 usdcAmount, string memory affiliateCode) internal view returns(uint256, uint256, uint256) {
        uint256 amountToBuy = 0;
        if (usdPricePerToken() > usdcAmount * 10 ** 12) {
            amountToBuy = usdcAmount * 10 ** 12 / (usdPricePerToken() / 10 ** 18);
        } else {
            amountToBuy = ((usdcAmount * 10 ** 12 ) / usdPricePerToken()) * 10 ** 18;
        }
        uint256 bonusAmount = 0;
        (bool exists, uint256 idx) = _affiliateProgram.findBonusIdx(affiliateCode);
        if (exists == true) {
            AffiliateProgram.Bonus memory affiliateBonus = _affiliateProgram.bonuses()[idx];
            bonusAmount = (amountToBuy * affiliateBonus.bonusInPerc) / 100;
        }
        uint256 overallAmount = amountToBuy + bonusAmount;

        return (amountToBuy, bonusAmount, overallAmount);
    }

    function usdPricePerToken() public view returns (uint256) {
        return _usdPricePerToken;
    }

    function setUsdPricePerToken(uint256 price) public onlyOwner {
        _usdPricePerToken = price;
    }

    function salesCap() public onlyElevatedOrOwner view returns (uint256) {
        return _salesCap;
    }

    function setSalesCap(uint256 newSalesCap) public onlyOwner {
        _salesCap = newSalesCap;
    }

    function purchasedVolume() external onlyElevatedOrOwner view returns (uint256) {
        return _purchasedVolume;
    }

    function disableBuyToken() external onlyOwner {
        _isBuyTokenAllowed = false;
    }

    function allowBuyToken() external onlyOwner {
        _isBuyTokenAllowed = true;
    }

    function isBuyTokenAllowed() public view returns (bool) {
        return _isBuyTokenAllowed;
    }

    function setUsdcAddress(address usdcAddress) external onlyOwner {
        _usdc = IERC20WithPermit(usdcAddress);
    }

    function setTransactionHistoryAddress(address transactionHistoryAddress) external onlyOwner {
        _transactionHistory = TransactionHistory(transactionHistoryAddress);
    }

    function withdraw(address targetAddress, uint256 amount) external onlyOwner {
        require(vipToken.balanceOf(address(this)) >= amount, 'Not enough funds.');

        vipToken.transfer(targetAddress, amount);
    }

    modifier onlyOpenSales() {
        require(isBuyTokenAllowed(), "Buying tokens is currently disabled.");
        _;
    }
}