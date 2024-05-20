// Hack the planet(s)
// Planetary Council
// Galactic Federation
// Network State Genesis

pragma solidity 0.8.3;
import "Ownable.sol";
import "IERC721.sol";
import "ERC721.sol";

contract NetworkStateGenesis is ERC721, Ownable {
    string public GENESIS; // Preserving consciousness of the moment
    string public _tokenURI;
  	event Purchase(address addr, uint256 currentSerialNumber, uint256 price);

    address payable public multisig; // Ensure you are comfortable with m-of-n signatories on Gnosis Safe (don't trust, verify)
    address public minter;

    constructor(string memory name, string memory symbol, address _minter) ERC721(name, symbol) {
        minter = _minter;
    }

    // 1. Deploy 2. Include the smart contract address in the PDF. 3. Upload PDF to IPFS 4. Save IPFS hash in this method.
    function setGenesis(string memory IPFSURI) public onlyOwner {
        require(bytes(GENESIS).length == 0, "GENESIS can be set only once"); // https://ethereum.stackexchange.com/a/46254/2524
        GENESIS = IPFSURI;
    }

    function setTokenURI(string memory URI) public onlyOwner {
        require(bytes(_tokenURI).length == 0, "_tokenURI can be set only once");
        _tokenURI = URI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURI;
    }

    function mint(address addr, uint serialNumber) payable public {
        require(msg.sender == minter, "Only minter can mint");
        _mint(addr, serialNumber);
    }  
}