// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";

contract Oathkeepers is ERC1155, Ownable, ReentrancyGuard {

    event MintedPublic(address wallet, uint256 amount);
    event MintedPrivate(address wallet);

    uint256 public maxSupply = 1717;
    uint256 public MAX_PER_WALLET = 20;

    uint16 public publicMintsLeft = 0;

    uint256 public tokensMinted = 0;

    address public magicAddress = 0x539bdE0d7Dbd336b79148AA742883198BBF60342;
    address public paymentTo = 0xF6F4fF252b28162De985f6B81199Cd33212A43a1;
    
    address private signer = 0x747dE5ebf415272A603Cd1af325B5a7695a515c8;

    uint256 public mintCost = 100;

    bool private tradingEnabled = false;
    bool private mintingEnabled = false;

    mapping(address => uint256) public mintedPerWallet;
    mapping(address => bool) public mintedPrivate;
    mapping(address => bool) public whitelistedTrade;

    constructor() ERC1155("ipfs://QmYt6Mc19XsX6QhKRgdVEVsog2pZRFKdFPmKK5urcMDRDW") {

    }

    //Public and allowlist functions removed.

    function adminMint(address[] calldata wallets, uint256[] calldata amounts) public onlyOwner {
        require(wallets.length == amounts.length, "Arrays must be same length");

        for(uint256 i = 0; i < wallets.length; i++) {

            tokensMinted += amounts[i];

            _mint(wallets[i], 1, amounts[i], "");
        }
    }

    function mintLeftover() public onlyOwner {
        uint256 amount = maxSupply - tokensMinted;
        require(amount > 0, "No tokens left to mint");

        tokensMinted += amount;

        _mint(msg.sender, 1, amount, "");
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
    
    function resetWallet(address wallet) public onlyOwner {
        mintedPerWallet[wallet] = 0;
    }

    function whitelistTrader(address wallet) public onlyOwner {
        whitelistedTrade[wallet] = true;
    }

    function setPublicLeft(uint16 amount) public onlyOwner {
        require(publicMintsLeft + amount <= maxSupply, "Cannot set public mints left to more than max supply");
        publicMintsLeft = amount;
    }

    function setMagicAddress(address newAddress) public onlyOwner {
        magicAddress = newAddress;
    }

    function setMaxSupply(uint256 amount) public onlyOwner {
        require(!tradingEnabled, "Cannot increase supply after trading is enabled");
        maxSupply = amount;
    }

    function verify(bytes32 hash, bytes memory signature) internal view returns (bool) {
        return ECDSA.recover(hash, signature) == signer;
    }

    function setApprovalForAll(address operator, bool approved) public override {

        if(!whitelistedTrade[msg.sender])
            require(tradingEnabled, "Trading not enabled");
        
        super.setApprovalForAll(operator, approved);
    }

    function setMaxPerWallet(uint256 max) public onlyOwner {
        MAX_PER_WALLET = max;
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

        if(!whitelistedTrade[msg.sender])
            require(tradingEnabled, "Trading not enabled");
    }

}