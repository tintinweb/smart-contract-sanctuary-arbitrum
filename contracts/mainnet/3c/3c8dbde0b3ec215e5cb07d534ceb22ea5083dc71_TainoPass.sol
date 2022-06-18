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
    
     string private baseURI;

    mapping(uint256 => bool) public validtaino_passTypes;
    mapping(uint256 => string) public url_taino_passTypes;

    event SetBaseURI(string indexed _baseURI);

    constructor(string memory _baseURI) ERC1155(_baseURI) {
       
        validtaino_passTypes[0] = true;
        validtaino_passTypes[1] = true;
        validtaino_passTypes[2] = true;
        url_taino_passTypes[1] = "https://bafkreif4t54scghlqeh2elzzlvw3osfcmm7nsrwyagcoisnmxt6aj5z3o4.ipfs.nftstorage.link/";
        url_taino_passTypes[2] = "https://bafkreiaw7vjcojnfd6rbdt5lmjos35htnwb2w2xzvc77s4o4pkot7fempm.ipfs.nftstorage.link/";
        url_taino_passTypes[3] = "https://bafkreid5xwwektftzjrsmkterej7fdos6zyfhycx4lr3o2nqohtwbqlhsi.ipfs.nftstorage.link/";
    }

    function mintBatch(uint256[] memory ids, uint256[] memory amounts)
        external
        onlyOwner
    {
        _mintBatch(owner(), ids, amounts, "");
    }

    function updateUri(uint256 typeId, string memory _url) external onlyOwner
    {
          require(
            validtaino_passTypes[typeId],
            "URI requested for invalid taino pass type"
        );
        url_taino_passTypes[typeId] = _url;
    }

    // DM NoSass in discord, tell him you're ready for your foot massage


    function uri(uint256 typeId)
        public
        view                
        override
        returns (string memory)
    {
        require(
            validtaino_passTypes[typeId],
            "URI requested for invalid taino pass type"
        );
        return  url_taino_passTypes[typeId];
    }
}