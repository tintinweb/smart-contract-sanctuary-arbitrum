// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";

contract Oathkeepers is ERC1155, Ownable, ReentrancyGuard {

    uint256 public constant MAX_SUPPLY = 1500;
    uint256 public MAX_PER_WALLET = 50;

    uint256 public constant TEAM_ALLOCATION = 80;

    uint16 public publicMintsLeft = 1000;
    uint16 public privateMintsLeft = 500;

    uint256 public tokensMinted = 0;

    address public magicAddress = 0x88f9eFB3A7F728fdb2B8872fE994c84b1d148f65;
    address public paymentTo = 0xF6F4fF252b28162De985f6B81199Cd33212A43a1;
    
    address private signer = 0x747dE5ebf415272A603Cd1af325B5a7695a515c8;

    uint256 public mintCost = 150;

    bool private tradingEnabled = false;
    bool private mintingEnabled = false;

    mapping(address => uint256) public mintedPerWallet;
    mapping(address => bool) public mintedPrivate;

    constructor() ERC1155("ipfs://QmYt6Mc19XsX6QhKRgdVEVsog2pZRFKdFPmKK5urcMDRDW") {
        require(tokensMinted + TEAM_ALLOCATION <= MAX_SUPPLY, "Team allocation too high");
        
        _mintTeam();
    }

    function mint(uint256 amount) public nonReentrant {
        require(mintingEnabled, "Minting not enabled");
        require(publicMintsLeft >= amount, "Not enough public mints left");
        require(mintedPerWallet[msg.sender] + amount <= MAX_PER_WALLET, "Over max per wallet");
        require(tokensMinted + amount <= MAX_SUPPLY, "Sold out");
        require(amount > 0, "Amount must be greater than 0");
        require(msg.sender == tx.origin, "EOA only");

        uint256 cost = amount * (mintCost * 1 ether);

        IERC20(magicAddress).transferFrom(msg.sender, paymentTo, cost);

        tokensMinted += amount;
        publicMintsLeft -= uint16(amount);

        _mint(msg.sender, 1, amount, "");

    }

    function mintAllowlist(bytes calldata signature) public nonReentrant {
        require(mintingEnabled, "Minting not enabled");
        require(privateMintsLeft > 0, "Not enough private mints left");
        require(tokensMinted + 1 <= MAX_SUPPLY, "Sold out");
        require(msg.sender == tx.origin, "EOA only");
        require(!mintedPrivate[msg.sender], "Already minted");

        mintedPrivate[msg.sender] = true;

        bytes32 hash = ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(msg.sender)));
        require(verify(hash, signature), "Invalid signature");

        uint256 cost = mintCost * 1 ether;
        
        IERC20(magicAddress).transferFrom(msg.sender, paymentTo, cost);

        privateMintsLeft -= 1;
        tokensMinted += 1;

        _mint(msg.sender, 1, 1, "");
    }

    function _mintTeam() internal {
        tokensMinted += TEAM_ALLOCATION;
        publicMintsLeft -= uint16(TEAM_ALLOCATION);

        _mint(msg.sender, 1, TEAM_ALLOCATION, "");
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

    function setMagicAddress(address newAddress) public onlyOwner {
        magicAddress = newAddress;
    }

    function givePrivateToPublic() public onlyOwner {
        publicMintsLeft += privateMintsLeft;
        privateMintsLeft = 0;
    }

    function verify(bytes32 hash, bytes memory signature) internal view returns (bool) {
        return ECDSA.recover(hash, signature) == signer;
    }

    function setApprovalForAll(address operator, bool approved) public override {
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

        require(tradingEnabled, "Trading not enabled");
    }

}