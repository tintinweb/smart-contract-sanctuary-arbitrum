// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC1155.sol";
import "./Strings.sol";
import "./Ownable.sol";

///     _________ _______ _________ _        _______    _______  _______  _______  _______ 
///     \__   __/(  ___  )\__   __/( (    /|(  ___  )  (  ____ )(  ___  )(  ____ \(  ____ \
///        ) (   | (   ) |   ) (   |  \  ( || (   ) |  | (    )|| (   ) || (    \/| (    \/
///        | |   | (___) |   | |   |   \ | || |   | |  | (____)|| (___) || (_____ | (_____ 
///        | |   |  ___  |   | |   | (\ \) || |   | |  |  _____)|  ___  |(_____  )(_____  )
///        | |   | (   ) |   | |   | | \   || |   | |  | (      | (   ) |      ) |      ) |
///        | |   | )   ( |___) (___| )  \  || (___) |  | )      | )   ( |/\____) |/\____) |
///        )_(   |/     \|\_______/|/    )_)(_______)  |/       |/     \|\_______)\_______)

contract TainoPass is ERC1155, Ownable {
    using Strings for uint256;
    
    address private xContract;
    string private baseURI;

    mapping(uint256 => bool) public validxTypes;
    mapping(uint256 => uint256) public validxTypes_prices;


    event SetBaseURI(string indexed _baseURI);

    constructor(string memory _baseURI) ERC1155(_baseURI) {
        baseURI = _baseURI;
        validxTypes[0] = true;
        validxTypes[1] = true;
        validxTypes[2] = true;
        emit SetBaseURI(baseURI);
    }

    function mintBatch(uint256[] memory ids, uint256[] memory amounts)
        external
        onlyOwner
    {
        _mintBatch(owner(), ids, amounts, "");
    }

    function enableTypes(uint256 ntype) public onlyOwner
    {
        validxTypes[ntype] = true;
    }

    function disableTypes(uint256 ntype) public onlyOwner
    {
        validxTypes[ntype] = false;
    }

    function updateMintValue(uint256 ntype,uint256 price) public onlyOwner
    {
        require(price>=0,'price cannot less than zero');
        validxTypes_prices[ntype] = price;
    }

    function publicMint(uint256[] memory ids, uint256[] memory amounts)  public payable
    {      
        require(ids.length==amounts.length,'size must be the same');
        
        bool invalidFound = false;
        uint256 totalPriceRequired = 0;
        for(uint256 i=0;i<ids.length;i++)
        {
            if( validxTypes[2]!=true)
            {
                invalidFound = true;
                break;
            }
            uint256 xtype = ids[i];
            uint256 typePrice = validxTypes_prices[xtype];
            totalPriceRequired += amounts[i]*typePrice;
        }

        require(invalidFound==false,'some type not enabled');
        require(msg.value>=totalPriceRequired,'not enough money');
         _mintBatch(msg.sender, ids, amounts, ""); 
    }


    function setContractAddress(address xContractAddress)
        external
        onlyOwner
    {
        xContract = xContractAddress;
    }

    function burnForAddress(uint256 typeId, address burnTokenAddress)
        external
    {
        require(msg.sender == xContract, "Invalid burner address");
        _burn(burnTokenAddress, typeId, 1);
    }

    // DM NoSass in discord, tell him you're ready for your foot massage
    function updateBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
        emit SetBaseURI(baseURI);
    }

    function uri(uint256 typeId)
        public
        view                
        override
        returns (string memory)
    {
        require(
            validxTypes[typeId],
            "URI requested for invalid serum type"
        );
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, typeId.toString()))
                : baseURI;
    }
}