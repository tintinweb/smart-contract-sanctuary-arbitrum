// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract FuzziesTest2 is ERC721Enumerable, Ownable {
    using Address for address payable;
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 150000;

    bool public mintingActive = false;

    string private _currentBaseURI;

    struct MintConfig {
        uint256 quantity;
        uint256 price;
    }

    struct SplitConfig {
        address payable _address;
        uint256 weight;
        uint256 balance;
    }

    mapping (uint => MintConfig) public mintConfigs;
    mapping (uint => SplitConfig) public splitConfigs;
    mapping (address => uint256) public freeMint;
    mapping (address => bool) public whitelist;

    constructor() ERC721("Fuzzies", "FUZZ") {
        _currentBaseURI = "ipfs://bafybeihwn5mn5unxiya2eofyrxjyw3qxoqynodo3yirnig4txrucf2i5nm/";

        mintConfigs[1] = MintConfig({quantity: 1, price: 0.0022 ether});
        mintConfigs[10] = MintConfig({quantity: 10, price: 0.021 ether});
        mintConfigs[100] = MintConfig({quantity: 100, price: 0.21 ether});
        mintConfigs[1000] = MintConfig({quantity: 1000, price: 2.1 ether});
        mintConfigs[10000] = MintConfig({quantity: 10000, price: 21 ether});

        splitConfigs[0] = SplitConfig({_address: payable(0x32Eb42fEEBa8F8D2504FaF25879435dfC65f6327),weight: 584, balance: 0});
        splitConfigs[1] = SplitConfig({_address: payable(0xBa67C8550B2A9941E313C1acC1431c89877Cca2D),weight: 1000, balance: 0});
        splitConfigs[2] = SplitConfig({_address: payable(0x0cD07c72f8Ffd310de0151A7565114B6d5C94482),weight: 459, balance: 0});
        splitConfigs[3] = SplitConfig({_address: payable(0x653384D6B72Bf4BDeD16776363B426B51fF89aEf),weight: 2000, balance: 0});
        splitConfigs[4] = SplitConfig({_address: payable(0x65fdb9E09c9d1ab04888215ac94e132302dBe8B4),weight: 500, balance: 0});
        splitConfigs[5] = SplitConfig({_address: payable(0xD99b34CF3377C841d4bA6d5D627d447Cd862eB8e),weight: 2957, balance: 0});
        splitConfigs[6] = SplitConfig({_address: payable(0x3d67b76CF3dcc881255eb2262E788BE03b2f5B9F),weight: 2500, balance: 0});

    }

    function mint(uint configIndex) public payable {
        require(mintingActive, "Minting is not active");
        require(totalSupply() + mintConfigs[configIndex].quantity <= MAX_SUPPLY, "Exceeds max supply");

        uint256 price = mintConfigs[configIndex].price;
        if (whitelist[msg.sender]) {
            price = price * 85 / 100; // apply a 15% discount if on whitelist
            whitelist[msg.sender] = false; // remove from whitelist
        }
        
        require(msg.value >= price, "Incorrect Ether value sent");

        uint256 supply = totalSupply();

        for (uint256 i = 0; i < mintConfigs[configIndex].quantity; i++) {
            _mint(msg.sender, supply + i + 1);
        }

        splitFunds();
    }

    function mintFree() public {
        uint256 mintsAvailable = freeMint[msg.sender];
        require(mintsAvailable > 0, "No free mints available");
        
        uint256 supply = totalSupply();
        uint256 mintsPossible = MAX_SUPPLY > supply ? MAX_SUPPLY - supply : 0;
        
        uint256 mintsToMake = mintsAvailable < mintsPossible ? mintsAvailable : mintsPossible;
        require(mintsToMake > 0, "No mints possible at the moment");
        
        for (uint256 i = 0; i < mintsToMake; i++) {
            _mint(msg.sender, supply + i + 1);
        }
    
        freeMint[msg.sender] -= mintsToMake;
    }


    // Override the baseURI function to return the modifiable _baseURI
    function _baseURI() internal view override returns (string memory) {
        return _currentBaseURI;
    }

    // Add a function to allow the owner to change the baseURI
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _currentBaseURI = newBaseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
            : '';
    }

    function splitFunds() private {
        uint256 totalWeight = 0;
        for (uint256 i = 0; i < 7; i++) {
            totalWeight = totalWeight.add(splitConfigs[i].weight);
        }

        for (uint256 i = 0; i < 7; i++) {
            uint256 share = msg.value.mul(splitConfigs[i].weight).div(totalWeight);
            splitConfigs[i].balance = splitConfigs[i].balance.add(share);
        }
    }

    function withdraw(uint configIndex) public {
        require(msg.sender == splitConfigs[configIndex]._address, "Only the intended recipient can withdraw");

        uint256 amount = splitConfigs[configIndex].balance;
        require(amount > 0, "Nothing to withdraw");

        splitConfigs[configIndex].balance = 0;
        splitConfigs[configIndex]._address.sendValue(amount);
    }

    function setMintingActive(bool _mintingActive) public onlyOwner {
        mintingActive = _mintingActive;
    }

    function setFreeMints(address _address, uint256 _quantity) public onlyOwner {
        freeMint[_address] = _quantity;
    }

    function setWhitelists(address _address, bool _value) public onlyOwner {
        whitelist[_address] = _value;
    }
}