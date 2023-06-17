// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./IERC20.sol";
import "./console.sol";


contract BlessedVillagers is ERC721A, Ownable, ReentrancyGuard {

    event RefUsed(address by, address ref, uint256 amount);

    string public baseUri = "ipfs://QmaEDZM1pFFfzi1NhZmtXYsfWVuL6zmFUw1u97JNvyYtq9/";

    bool public mintEnabled = true;
    bool public permDisabled = false;
    bool public tradingBlock = true;

    uint256 ethCost = 0.0001 ether;
    uint256 magicCost = 0.0001 ether;

    address magicContract = 0x44C8C27879bd2b13aA551Dfc085382cBc25c2185;

    mapping(address => uint256) refPoints;

    constructor() ERC721A("Blessed Villager", "BLESSV") {

    }

    function mintBlessedWithMagic(uint256 amount, address ref) external nonReentrant {

        require(mintEnabled, "Mint disabled");
        require(msg.sender == tx.origin, "EOA only");

        require(amount > 0, "Non zero value");

        uint256 cost = magicCost * amount;

        IERC20(magicContract).transferFrom(
            msg.sender,
            owner(),
            cost
        );

        _mint(msg.sender, amount);

        if(ref != address(0) && ref != msg.sender) {
            refPoints[ref] += amount;
            emit RefUsed(msg.sender, ref, amount);
        }

    }

    function mintBlessedWithEth(uint256 amount, address ref) external payable nonReentrant {

        require(mintEnabled, "Mint disabled");
        require(msg.sender == tx.origin, "EOA only");

        require(amount > 0, "Non zero value");

        require(msg.value >= ethCost * amount, "Ether value sent is not correct");

        _mint(msg.sender, amount);

        if(ref != address(0) && ref != msg.sender) {
            refPoints[ref] += amount;
            emit RefUsed(msg.sender, ref, amount);
        }
    }


    function getRefPointsFor(address _address) public view returns (uint256) {
        return refPoints[_address];
    }

    function setMintState(bool state) public onlyOwner {
        require(!permDisabled, "Mint has been disabled forever");
        mintEnabled = state;
    }

    function setEthCost(uint256 cost) public onlyOwner {
        ethCost = cost;
    }

    function setMagicCost(uint256 cost) public onlyOwner {
        magicCost = cost;
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
        require(mintEnabled, "Mint disabled");

        for(uint256 i = 0; i < wallet.length; i++)
            _mint(wallet[i], amount[i]);
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
        (bool success, ) = payable(msg.sender).call {value: address(this).balance}("");
        require(success);
    }

}