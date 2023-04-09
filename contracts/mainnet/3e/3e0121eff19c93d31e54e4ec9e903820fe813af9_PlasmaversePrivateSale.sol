/**
 *Submitted for verification at Arbiscan on 2023-04-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PlasmaversePrivateSale {
    address owner;
    mapping(address => WhitelistEntry) whitelist;

    uint256 minPurchase = 0.03 ether;
    uint256 startTime;
    uint256 endTime;
    uint256 totalPurchased;

    struct WhitelistEntry {
        uint256 maxCap;
        uint256 totalPurchased;
    }

    constructor(uint256 _startTime, uint256 _endTime) {
        owner = msg.sender;
        startTime = _startTime;
        endTime = _endTime;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only contract owner can call this function."
        );
        _;
    }

    function addToWhitelist(
        address[] memory _addresses,
        uint256[] memory _maxCaps
    ) public onlyOwner {
        require(_addresses.length == _maxCaps.length, "Invalid input length.");

        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = WhitelistEntry(_maxCaps[i], 0);
        }
    }

    function removeFromWhitelist(address _address) public onlyOwner {
        delete whitelist[_address];
    }

    function setMinPurchase(uint256 _minPurchase) public onlyOwner {
        minPurchase = _minPurchase;
    }

    function getMinPurchase() public view returns (uint256) {
        return minPurchase;
    }

    function getSalePeriod() public view returns (uint256 _startTime, uint256 _endTime) {
        _startTime = startTime;
        _endTime = endTime;
    }

    function setSalePeriod(uint256 _startTime, uint256 _endTime)
        public
        onlyOwner
    {
        require(_endTime > _startTime, "Invalid sale period.");
        startTime = _startTime;
        endTime = _endTime;
    }

    function getPurchasesByWallet(address[] memory wallets)
        public
        view
        returns (
            uint256[] memory purchasedAmounts,
            uint256[] memory remainingAllocations
        )
    {
        purchasedAmounts = new uint256[](wallets.length);
        remainingAllocations = new uint256[](wallets.length);

        for (uint256 i = 0; i < wallets.length; i++) {
            require(
                whitelist[wallets[i]].maxCap > 0,
                "Wallet is not in the whitelist"
            );
            purchasedAmounts[i] = whitelist[wallets[i]].totalPurchased;
            remainingAllocations[i] =
                whitelist[wallets[i]].maxCap -
                purchasedAmounts[i];
        }
    }

    function getTotalPurchases() public view returns (uint256) {
        return totalPurchased;
    }

    function purchase() public payable {
        require(
            block.timestamp >= startTime && block.timestamp <= endTime,
            "Sale is not active."
        );
        require(
            msg.value >= minPurchase,
            "Amount is less than minimum purchase."
        );
        require(whitelist[msg.sender].maxCap > 0, "You are not whitelisted.");

        WhitelistEntry storage entry = whitelist[msg.sender];
        uint256 remainingCap = entry.maxCap - entry.totalPurchased;
        uint256 purchaseAmount = msg.value < remainingCap
            ? msg.value
            : remainingCap;
        uint256 refundAmount = msg.value - purchaseAmount;

        // max hardcap limit
        uint256 progressPurchased = totalPurchased + purchaseAmount;
        require(progressPurchased <= 111 ether, "Purchase exceeds max 111 ether.");
        
        entry.totalPurchased += purchaseAmount;
        totalPurchased += purchaseAmount;

        if (refundAmount > 0) {
            payable(msg.sender).transfer(refundAmount);
        }
    }

    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}