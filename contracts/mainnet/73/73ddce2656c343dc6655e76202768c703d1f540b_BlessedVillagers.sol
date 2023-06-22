// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./IERC20.sol";
import "./AggregatorV3Interface.sol";

contract BlessedVillagers is ERC721A, Ownable, ReentrancyGuard {

    event RefUsed(address by, address ref, uint256 amount);
    
    string public baseUri = "ipfs://QmNxh959di3qS3FXVDNFGcH15sfG15gtJLVJFPAAPhYVWu/";

    bool public mintEnabled = false;
    bool public permDisabled = false;
    bool public tradingBlock = true;

    uint256 costInUSD = 33 * 10 ** 8; //$33 in 8 decimal format

    address magicFeed = 0x47E55cCec6582838E173f252D08Afd8116c2202d;
    address ethFeed = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;

    address magicContract = 0x539bdE0d7Dbd336b79148AA742883198BBF60342;

    address payTo = 0xF6F4fF252b28162De985f6B81199Cd33212A43a1;

    mapping(address => bool) public allowlist;

    constructor() ERC721A("Blessed Villager", "BLESSV") {

    }

    function getMagicPrice() public view returns (uint256) {
        (,int price,,,) = AggregatorV3Interface(magicFeed).latestRoundData();

        return (costInUSD / uint256(price) * 1 ether);
    }

    function getEthPrice() public view returns (uint256) {
        (,int price,,,) = AggregatorV3Interface(ethFeed).latestRoundData();

        uint256 costInWei = (costInUSD * 1 ether) / uint256(price);

        return costInWei;
    }

    function mintBlessedWithMagic(uint256 amount, address ref) external nonReentrant {

        if(!allowlist[msg.sender])
            require(mintEnabled, "Mint disabled");

        require(!permDisabled, "Mint has been disabled forever");
        require(msg.sender == tx.origin, "EOA only");

        require(amount > 0, "Non zero value");
        require(amount <= 20, "Max 20 per tx");

        uint256 cost = getMagicPrice() * amount;

        IERC20(magicContract).transferFrom(
            msg.sender,
            payTo,
            cost
        );

        _mint(msg.sender, amount);

        if(ref != address(0) && ref != msg.sender)
            emit RefUsed(msg.sender, ref, amount);
        

    }

    function mintBlessedWithEth(uint256 amount, address ref) external payable nonReentrant {

        if(!allowlist[msg.sender])
            require(mintEnabled, "Mint disabled");

        require(!permDisabled, "Mint has been disabled forever");
        require(msg.sender == tx.origin, "EOA only");
        require(amount > 0, "Non zero value");
        require(msg.value >= getEthPrice() * amount, "Ether value sent is not correct");
        require(amount <= 20, "Max 20");

        _mint(msg.sender, amount);

        if(ref != address(0) && ref != msg.sender) 
            emit RefUsed(msg.sender, ref, amount);
    }

    function setMintState(bool state) public onlyOwner {
        require(!permDisabled, "Mint has been disabled forever");
        mintEnabled = state;
    }

    function setMagicContract(address magicAddress) public onlyOwner {
        magicContract = magicAddress;
    }

    function foreverDisableMint() public onlyOwner {
        permDisabled = true;
        mintEnabled = false;
    }

    function foreverOpenTrading() public onlyOwner {
        tradingBlock = false;
    }

    function mintAdmin(uint256[] calldata amount, address[] calldata wallet) external payable onlyOwner {
        require(!permDisabled, "Mint has been disabled forever");

        for(uint256 i = 0; i < wallet.length; i++)
            _mint(wallet[i], amount[i]);
    }

    function allowlistWallet(address[] calldata wallet, bool state) external onlyOwner {
        for(uint256 i = 0; i < wallet.length; i++)
            allowlist[wallet[i]] = state;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {

        if(from == address(0)) {
            super._beforeTokenTransfers(from, to, startTokenId, quantity);
            return;
        }

        require(tradingBlock, "Trading is currently blocked");

        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {

		return string(abi.encodePacked(baseUri, Strings.toString(tokenId), ".json"));
	}

    function setBaseUri(string memory uri) public onlyOwner {
        baseUri = uri;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(payTo).call {value: address(this).balance}("");
        require(success);
    }

}