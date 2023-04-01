// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;
/**
                       &GJ7P         P7JG&        
                &    &57JG&           &GJ75&    & 
               J7B  B77B                 B77B  B7J
               ?7P &77&                   &77& 57J
               &Y75J75    &#         #&    Y7JY7Y&
                 &PY7?&  P7J&       &J7P  &?7YP&  
                    B?7G&?7G         G7?&G7?B     
                      BY777?J???????J?777YB       
                 &#BBB#G7777777777777777?G#BBB#   
                P777777777???7777777???777777777G 
                Y77777777?!.~???????~.!?77777777Y 
                 #BP77777?~ ^?7!~!7?^ ~?77777PB&  
                   B777777777:     :777777777G    
                   Y7777777?~  :~:  ~?7777777J    
                   J777777777.  .  :777777777?    
                   J77777777??7~^~7?777777777?    
                   Y7777777777?????7777777777J    
                   P7???????????????????????75        

    website : https://arbswap.io
    twitter : https://twitter.com/arbswapofficial
 */

import "./ERC721.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./IERC20.sol";

error NonExistentTokenURI();
error WithdrawTransfer();
error NoContract();
error Minted();

contract ArbEgg is ERC721, Ownable {
    using Strings for uint256;
    string public baseURI;
    uint256 public currentTokenId;
    mapping(address => bool) public minted;

    event revokeToken(address, address, uint256);

    constructor(string memory _baseURI) ERC721("Arb Egg", "AREG") {
        baseURI = _baseURI;
    }

    function claim() external returns (uint256) {
        if (minted[msg.sender]) {
            revert Minted();
        }
        if (tx.origin != msg.sender) {
            revert NoContract();
        }
        uint256 newTokenId = ++currentTokenId;
        minted[msg.sender] = true;
        _safeMint(msg.sender, newTokenId);
        return newTokenId;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        if (ownerOf(tokenId) == address(0)) {
            revert NonExistentTokenURI();
        }
        return bytes(baseURI).length > 0 ? baseURI : "";
    }

    function totalSupply() public view returns (uint256) {
        return currentTokenId;
    }

    function withdrawPayments(address payable payee) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool transferTx, ) = payee.call{value: balance}("");
        if (!transferTx) {
            revert WithdrawTransfer();
        }
    }

    function revokeWrongToken(address token_) external onlyOwner {
        if (token_ == address(0x0)) {
            (bool sent, ) = msg.sender.call{value: address(this).balance}(
                new bytes(0)
            );
            require(sent, "Failed to send VS");
            return;
        }
        IERC20 token = IERC20(token_);
        uint256 amount = token.balanceOf(address(this));
        token.transfer(msg.sender, amount);

        emit revokeToken(msg.sender, token_, amount);
    }
}