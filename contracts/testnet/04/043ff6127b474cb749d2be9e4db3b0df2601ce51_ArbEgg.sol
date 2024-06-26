// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10;
/**
                            &BPY??JY#                          #Y???YPB&                            
                         #GYJ???????J                          J???????JYG&                         
                      &BY??????????JG                          GJ??????????YB                       
                    &PJ????????J5G#&                            &#G5J????????JG&                    
                   GJ???????J5B&                                    &B5J???????JG                   
 B5YY5#          #Y???????JG&                                          &GJ???????Y#          B5YY5B 
P??????B        G???????JG                                                GJ???????G        G??????P
J??????B       P???????5&                                                  &5???????P       G??????J
???????#      G???????G                                                      G???????G      #??????J
J??????B     B???????G                                                        G???????B     G??????J
P??????Y    &J??????P                                                          P??????J&   &J??????G
&J??????5&  G??????J                                                            J??????G  #Y??????Y 
 #J??????JP#Y??????G                                                            G??????Y#P???????J& 
  &Y???????????????B            #GPPG#                        BGPPG#            B???????????????5&  
    BY?????????????G          BJ??????J#                    #J??????JB          G?????????????YB    
      #PJ??????????J&        B???????YB&                    &BY???????B        &J??????????YP#      
         #BP5J??????Y&      &???????P                          5??????J&      &Y??????J5PB&         
             #J??????JB     G??????Y                            J??????G     BJ??????J&             
              &Y???????YG&  P??????5                            Y??????G  &GY???????Y&              
                GJ???????J5BP??????J&      &&&&######&&&&      &J??????GG5J???????JG                
                 &PJ????????????????5BP5YYJJJ??????????JJJYY5PBY????????????????JP&                 
                   &GY????????????????????????????????????????????????????????5B&                   
                      &B5J????????????????????????????????????????????????J5B&                      
                         G????????????????????????????????????????????????G                         
         &#BGGPPPPGGGB#BY??????????????????????????????????????????????????YB#BGGGPPPPGGB#&         
      B5J??????????????????????????????????????????????????????????????????????????????????YPB      
    BJ????????????????????????????????????????????????????????????????????????????????????????YB    
   G????????????????????????????????????????????????????????????????????????????????????????????B   
  &?????????????????????????????????????????????????????????????????????????????????????????????J   
  B??????????????????????????????????????????????????????????????????????????????????????????????#  
  &J?????????????????????????????!...:???????????????????????7:..:7?????????????????????????????J   
   #J????????????????????????????^    !??????????????????????~    ~????????????????????????????Y#   
     B5J?????????????????????????^    !??????????????????????~    ~????????????????????????JY5B     
        &#BBG5???????????????????^    7??????????????????????!    ~???????????????????5GBB#&        
             5???????????????????7~^^!??????!~::....::~!??????~^^~????????????????????Y             
            &????????????????????????????7^.            .~?????????????????????????????#            
            G???????????????????????????!.                .!???????????????????????????5            
            Y??????????????????????????!                    7??????????????????????????J&           
           &???????????????????????????:      .:~!7~^:.     ^???????????????????????????#           
           #???????????????????????????:     !????????!     :???????????????????????????G           
           G???????????????????????????~     .!?????7~.     !???????????????????????????P           
           P????????????????????????????~      .:::..      ~????????????????????????????5           
           P?????????????????????????????!:              :7?????????????????????????????Y           
           5???????????????????????????????7~:..    ..^~7???????????????????????????????Y           
           P???????????????????????????????????77777????????????????????????????????????Y           
           P????????????????????????????????????????????????????????????????????????????Y           
           G????????????????????????????????????????????????????????????????????????????5           
           B????????????????????????????????????????????????????????????????????????????P           
           #????????????????????????????????????????????????????????????????????????????G           
            J???????????????????????????????????????????????????????????????????????????#           
            5??????????????????????????????????????????????????????????????????????????J            
            B??????????????????????????????????????????????????????????????????????????5            
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

    function withdrawPayments(address payable payee) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool transferTx, ) = payee.call{value: balance}("");
        if (!transferTx) {
            revert WithdrawTransfer();
        }
    }

    function revokeWrongToken(address token_) external onlyOwner {
        if (token_ == address(0x0)) {
            (bool sent, bytes memory data) = msg.sender.call{
                value: address(this).balance
            }(new bytes(0));
            require(sent, "Failed to send VS");
            return;
        }
        IERC20 token = IERC20(token_);
        uint256 amount = token.balanceOf(address(this));
        token.transfer(msg.sender, amount);

        emit revokeToken(msg.sender, token_, amount);
    }
}