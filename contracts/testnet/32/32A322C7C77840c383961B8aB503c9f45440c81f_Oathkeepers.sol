// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract Oathkeepers is ERC1155, Ownable {

    uint256 public constant MAX_SUPPLY = 1500;
    uint256 public constant MAX_PER_WALLET = 5;

    uint256 public tokensMinted = 0;

    address public magicAddress = 0x539bdE0d7Dbd336b79148AA742883198BBF60342;
    address public paymentTo = 0xF6F4fF252b28162De985f6B81199Cd33212A43a1;
    uint256 public mintCost = 175;

    bool private tradingEnabled = false;
    bool private mintingEnabled = false;

    mapping(address => uint256) public mintedPerWallet;

    constructor() ERC1155("ipfs://QmYt6Mc19XsX6QhKRgdVEVsog2pZRFKdFPmKK5urcMDRDW") {
        _mintTeam();
    }

    function mint(uint256 amount) public {
        require(mintingEnabled, "Minting not enabled");
        require(mintedPerWallet[msg.sender] + amount <= MAX_PER_WALLET, "Over max per wallet");
        require(tokensMinted + amount <= MAX_SUPPLY, "Sold out");
        require(amount > 0, "Amount must be greater than 0");

        uint256 cost = amount * (mintCost * 1 ether);

        IERC20(magicAddress).transferFrom(msg.sender, paymentTo, cost);

        tokensMinted += amount;
        _mint(msg.sender, 1, amount, "");
    }

    function _mintTeam() internal {
        tokensMinted += 80;
        _mint(msg.sender, 1, 80, "");
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function setCost(uint256 newCost) public onlyOwner {
        mintCost = newCost;
    }

    function setMinting(bool state) public onlyOwner {
        mintingEnabled = state;
    }

    function openTradingForever() public onlyOwner {
        tradingEnabled = true;
    }

    function setApprovalForAll(address operator, bool approved) public override {
        require(tradingEnabled, "Trading not enabled");
        
        super.setApprovalForAll(operator, approved);
    }

    function _beforeTokenTransfer(
        address,
        address from,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) internal override {
        if(from == address(0))
            return;

        require(tradingEnabled, "Trading not enabled");
    }

}