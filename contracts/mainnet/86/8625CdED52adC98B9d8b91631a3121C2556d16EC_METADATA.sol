pragma solidity >0.8.0;

//import "@rari-capital/solmate/src/tokens/ERC721.sol";
//import "hardhat/console.sol";


interface IMRPP {
    struct PPMAN {
        uint id;
        uint wins;                          // battle wins
        uint losses;                        // battle losses
        uint honor;                         // changed the rng god number $$$  changegodnumber()
        uint donations;                     // amount person has donated  $$$  helpthenurses() 
        uint girth;                         // times user called swordfight
        uint nepotism;                      // patriarchy 
    }
    function getPPInfo(uint _tokenid) external view returns(PPMAN memory);
}

contract METADATA {

    //uint delme;

    IMRPP public mrpp;
    struct Info {
        address owner;
    }
    Info private info;

    string constant private TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    constructor() {
        info.owner = msg.sender;
        //delme = _delme;
    }

    modifier _onlyOwner() {
		require(msg.sender == owner());
		_;
	}

    function setOwner(address _owner) external _onlyOwner {
		info.owner = _owner;
	}

    function owner() public view returns (address) {
		return info.owner;
	}

    function setMRPP(IMRPP _mrpp) public _onlyOwner {
        mrpp = _mrpp;
    }

    function getPPInfo(uint _tokenid) public view returns (IMRPP.PPMAN memory) {
        return mrpp.getPPInfo(_tokenid);
    }

    function tokenuri(uint id) external view returns(string memory) {
        IMRPP.PPMAN memory pp = getPPInfo(id);
        string memory name = "Mr PP";
        string memory desc = "some description";
        string memory _json = string(abi.encodePacked('{"name":"', name, ' #', _uint2str(id), '","description":"', desc, '", "attributes": ['));
        _json = string(abi.encodePacked(_json, '{"trait_type": "pp size","value": ', _uint2str(pp.wins), '},' ));
        _json = string(abi.encodePacked(_json, '{"trait_type": "deaths","value": ', _uint2str(pp.losses), '},' ));
        _json = string(abi.encodePacked(_json, '{"trait_type": "honor","value": ', _uint2str(pp.honor), '}],' ));
        _json = string(abi.encodePacked(_json, '"image":"data:image/svg+xml;base64,', _encode(bytes(makeRawSVG(pp))), '"}'));
        return string(abi.encodePacked("data:application/json;base64,", _encode(bytes(_json))));
        //return _json;
    }

    function makeRawSVG(IMRPP.PPMAN memory pp) internal view returns (string memory) {
        string memory svg;
        string[10] memory bg = ["#20B2AA","#9ACD32","#B22222","#E9967A","#FF1493","#FF4500","#6B8E23","#B8860B","#A0522D","#CD853F"];
        string memory bgcolor = bg[pp.id % 10];
        svg = string(abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" width="250" height="250"> <g> <rect x="0" y="0" width="250" height="250" fill="', bgcolor, '"></rect>'));
        // dickstuff
        uint dicksize = pp.wins / 10;
        string memory dick;
        for (uint i; i < dicksize; i++) {
            dick = string(abi.encodePacked(dick, "="));
        }
        uint girth = pp.girth / 10;
        // hats
        if (pp.donations >= 100 ether)  {
            svg = string(abi.encodePacked(svg, '<text x="20" y="35" font-family="Arial,Helvetica,sans-serif" font-size="25" fill="blue">A</text>'));
            svg = string(abi.encodePacked(svg, '<text x="8" y="85" font-family="Arial,Helvetica,sans-serif" font-size="15" fill="blue"> ( . Y . ) </text>'));
        } else if (pp.donations >= 50 ether)  {
            svg = string(abi.encodePacked(svg, '<text x="10" y="35" font-family="Arial,Helvetica,sans-serif" font-size="25" fill="blue">&#128081;</text>'));
            svg = string(abi.encodePacked(svg, '<text x="8" y="85" font-family="Arial,Helvetica,sans-serif" font-size="15" fill="blue"> ( . Y . ) </text>'));
        } else if (pp.donations >= 1 ether)  {
            svg = string(abi.encodePacked(svg, '<text x="10" y="35" font-family="Arial,Helvetica,sans-serif" font-size="25" fill="blue">&#127913;</text>'));
        } else if (pp.donations >= 0.5 ether)  {
            svg = string(abi.encodePacked(svg, '<text x="10" y="35" font-family="Arial,Helvetica,sans-serif" font-size="25" fill="blue">&#128082;</text>'));
        } else if (pp.donations >= 0.25 ether)  {
            svg = string(abi.encodePacked(svg, '<text x="17" y="35" font-family="Arial,Helvetica,sans-serif" font-size="25" fill="blue">W</text>'));
        } else if (pp.donations > 0) {
            svg = string(abi.encodePacked(svg, '<text x="20" y="35" font-family="Arial,Helvetica,sans-serif" font-size="25" fill="blue">w</text>'));
        } else {
            svg = string(abi.encodePacked(svg, '<text x="20" y="35" font-family="Arial,Helvetica,sans-serif" font-size="25" fill="blue"></text>'));
        }


        svg = string(abi.encodePacked(svg, '<text x="5" y="60" font-family="Arial,Helvetica,sans-serif" font-size="35" fill="blue">\\O/</text><text x="25" y="85" font-family="Arial,Helvetica,sans-serif" font-size="35" fill="blue">|</text><text x="25" y="115" font-family="Arial,Helvetica,sans-serif" font-size="35" fill="blue">|</text>'));
        svg = string(abi.encodePacked(svg, '<text x="29" y="120" font-family="Arial,Helvetica,sans-serif" font-size="', _uint2str(20 + girth) ,'" fill="blue">', dick, "D</text>"));
        

        svg = string(abi.encodePacked(svg, '<text x="18" y="149" font-family="Arial,Helvetica,sans-serif" font-size="35" fill="blue">/\\</text>'));
        svg = string(abi.encodePacked(svg, '<text x="5" y="170" font-family="Arial,Helvetica,sans-serif" font-size="20" fill="blue">KILLS: ', _uint2str(pp.wins), '</text>'));
        svg = string(abi.encodePacked(svg, '<text x="5" y="190" font-family="Arial,Helvetica,sans-serif" font-size="20" fill="blue">REKTS: ', _uint2str(pp.losses), '</text>'));
        svg = string(abi.encodePacked(svg, '</g></svg>'));
        //console.log(svg);
        return svg;
    }

    function getRaw(uint _id) external view returns (string memory) {
        IMRPP.PPMAN memory ppman = getPPInfo(_id);
        return makeRawSVG(ppman);
    }
    

    function _uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function _encode(bytes memory _data) internal pure returns (string memory result) {
		if (_data.length == 0) return '';
		string memory _table = TABLE;
		uint256 _encodedLen = 4 * ((_data.length + 2) / 3);
		result = new string(_encodedLen + 32);

		assembly {
			mstore(result, _encodedLen)
			let tablePtr := add(_table, 1)
			let dataPtr := _data
			let endPtr := add(dataPtr, mload(_data))
			let resultPtr := add(result, 32)

			for {} lt(dataPtr, endPtr) {}
			{
				dataPtr := add(dataPtr, 3)
				let input := mload(dataPtr)
				mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
				resultPtr := add(resultPtr, 1)
				mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
				resultPtr := add(resultPtr, 1)
				mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
				resultPtr := add(resultPtr, 1)
				mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
				resultPtr := add(resultPtr, 1)
			}
			switch mod(mload(_data), 3)
			case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
			case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
		}
		return result;
	}

}