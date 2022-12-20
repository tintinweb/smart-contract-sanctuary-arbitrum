/**
 *Submitted for verification at Arbiscan on 2022-12-20
*/

// File: base64-sol/base64.sol



pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// File: contracts/PetRenderer.sol


pragma solidity ^0.8.9;


contract PetRenderer {
  string[][] public palettes = [
    ['#b5eaea', '#edf6e5', '#f38ba0'],
    ['#b5c7ea', '#e5f6e8', '#f3bb8b'],
    ['#eab6b5', '#eee5f6', '#8bf3df'],
    ['#c3eab5', '#f6e9e5', '#c18bf3'],
    ['#eab5d9', '#e5e8f6', '#8bf396']
  ];
  
  string[] public paletteDescriptions = ['Blueberry', 'Grape', 'Cherry', 'Lime', 'Strawberry'];
  string[] public species = ['Kitty', 'Mouse', 'Puppy', 'Rabbit'];
  string[] public eyeDescriptions = ['Mischief', 'Open', 'Sleepy', 'Winky'];
  string[] public mouthDescriptions = ['Frown', 'Happy', 'Straight'];

  bytes[] public bodies = [
    bytes(hex'1b000101100001010500010101030101070001010600010101030101040001010203010105000101010001010400010102030101040001010303010104000101050001010303010104000101010301040203010103000101040001010203010401030101040001010103020401030a0101030204010301010400010101030304010108030101030401030101040001010103020401010a03010102040103010104000201010401010c0301010104020105000201030301040a03020106000101030303040a030101060001010203050409030101040004010103050408030401040001010303030401030301040302040101040004010303010403030101040302040401040001010c0304040101070001010b0303040101090001010903030401010b0001010803020401010d000a010f000101060401010f000201060302010d00020108030201'),
    bytes(hex'340003010a00030107000101030301010800010103030101050001010503010106000101050301010400010101030304010301010600010101030304010301010300010102030304020301010400010102030304020301010200010101030504010301010400010101030504010301010200010101030504010301010400010101030504010301010200010101030504080105040103010102000101010304040101010306040103010104040103010102000101020302040101030304040303010102040203010103000101010301040101050302040503010101040103010104000101010301010e03010101030101050002010e030201070001010e030101050004010603030105030401050001010703010106030101050004010e030401060001010c0301010b0001010a0301010d000a010f000101060401010f00010108030101'),
    bytes(hex'3c0001010d00050104000101010001010300050103000101040402010300010104000201040401010200010105040101030001010400010105040101020001010304010101040a0101040101030401010200010102040101020401010803010102040101020401010200010101040201010401010a030101010402010104010103000101010002010c0302010100010106000101030301040a03010107000101030303040a030101060001010203050409030101060001010203050409030101060001010303030401030301040302040101060001010403010403030101040303040101060001010c0304040101070001010b0303040101090001010903030401010b0001010803020401010d000a010f000101060401010f000201060302010d00020108030201'),
    bytes(hex'1c0002010c00020107000101020301010a000101020301010500010104030101080001010403010104000101010302040103010108000101010302040103010103000101020302040203010106000101020302040203010102000101010304040103010106000101010304040103010102000101010304040103010106000101010304040103010102000101010304040103010106000101010304040103010102000101010304040103010106000101010304040103010103000101010303040103080101030304010301010400010101030304010108030101030401030101050001010103010401010a03010101040103010106000101010301010c0301010103010107000101030301040a03010107000101030303040a030101060001010203050409030101040004010103050408030401040001010303030401030301040302040101040004010303010403030101040302040401040001010c0304040101070001010a0304040101090001010903030401010b000101070303040101')
  ];

  bytes[][] public eyes = [
    [
      bytes(hex'ff0028000301050003010e00010107000101'),
      bytes(hex'ff0029000101070001010f00010107000101'),
      bytes(hex'ff004000030105000301'),
      bytes(hex'ff00290001011700010106000301')
    ],
    [
      bytes(hex'ff0070000301050003010e00010107000101'),
      bytes(hex'ff0071000101070001010f00010107000101'),
      bytes(hex'ff008800030105000301'),
      bytes(hex'ff00710001011700010106000301')
    ],
    [
      bytes(hex'ff0028000301050003010e00010107000101'),
      bytes(hex'ff0029000101070001010f00010107000101'),
      bytes(hex'ff004000030105000301'),
      bytes(hex'ff00290001011700010106000301')
    ], 
    [
      bytes(hex'ff0088000301050003010e00010107000101'),
      bytes(hex'ff0089000101070001010f00010107000101'),
      bytes(hex'ff00a000030105000301'),
      bytes(hex'ff00890001011700010106000301')
    ]
  ];

  bytes[][] public mouths = [
    [
      bytes(hex'ff008c000101010001011400010103000101'),
      bytes(hex'ff008b00010101000101010001011400010101000101'),
      bytes(hex'ff008b000501')
    ],
    [
      bytes(hex'ff00bc000101010001011400010103000101'),
      bytes(hex'ff00bb00010101000101010001011400010101000101'),
      bytes(hex'ff00bb000501')
    ],
    [
      bytes(hex'ff008c000101010001011400010103000101'),
      bytes(hex'ff008b00010101000101010001011400010101000101'),
      bytes(hex'ff008b000501')
    ],
    [
      bytes(hex'ff00ec000101010001011400010103000101'),
      bytes(hex'ff00eb00010101000101010001011400010101000101'),
      bytes(hex'ff00eb000501')
    ]
  ];

  struct Traits {
    uint8 palette;
    uint8 species;
    uint8 eyes;
    uint8 mouth;
  }

  function tokenURI(uint256 tokenId, uint256 seed) public view returns (string memory) {
    return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(_tokenJson(tokenId, seed)))));
  }

  function _tokenJson(uint256 tokenId, uint256 seed) internal view returns (string memory) {
    Traits memory traits = _traitsFor(seed);

    return string(abi.encodePacked(
      '{"name": "BotPet #', _uintToStr(tokenId), '", "description": "Pets for Arbibots!!", "image": "data:image/svg+xml;base64,',
      Base64.encode(bytes(_renderSvg(seed))),
      '", "attributes": [',
        '{"trait_type": "Palette", "value": "', paletteDescriptions[traits.palette], '"},',
        '{"trait_type": "Species", "value": "', species[traits.species], '"},',
        '{"trait_type": "Eyes", "value": "', eyeDescriptions[traits.eyes], '"},',
        '{"trait_type": "Mouth", "value": "', mouthDescriptions[traits.mouth], '"}',
      ']}'
    ));
  }

  function _renderSvg(uint256 seed) internal view returns (string memory) {
    Traits memory traits = _traitsFor(seed);
    string[] memory palette = palettes[traits.palette];

    string memory svg = string(abi.encodePacked(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" shape-rendering="crispEdges" width="256" height="256">'
      '<rect width="100%" height="100%" fill="', palette[0], '" />',
      _renderRects(bodies[traits.species], palette),
      _renderRects(eyes[traits.species][traits.eyes], palette),
      _renderRects(mouths[traits.species][traits.mouth], palette),
      '</svg>'
    ));
    return svg;
  }

  function _renderRects(bytes memory data, string[] memory palette) private pure returns (string memory) {
    string memory rects;
    uint256 drawIndex = 0;
    for (uint256 i = 0; i < data.length; i = i+2) {
      uint8 runLength = uint8(data[i]); // we assume runLength of any non-transparent segment cannot exceed image width (24px)
      uint8 colorIndex = uint8(data[i+1]);
      if (colorIndex != 0) { // transparent
        uint8 x = uint8(drawIndex % 24);
        uint8 y = uint8(drawIndex / 24);
        string memory color = "#000000";
        if (colorIndex > 1) {
          color = palette[colorIndex-2];
        }
        rects = string(abi.encodePacked(rects, '<rect width="', _uintToStr(runLength), '" height="1" x="', _uintToStr(x), '" y="', _uintToStr(y), '" fill="', color, '" />'));
      }
      drawIndex += runLength;
    }

    return rects;
  }

  function _traitsFor(uint256 seed) private view returns (Traits memory) {
    return Traits({
      palette: uint8(uint256(keccak256(abi.encode(seed, 1))) % palettes.length),
      species: uint8(uint256(keccak256(abi.encode(seed, 2))) % species.length),
      eyes: uint8(uint256(keccak256(abi.encode(seed, 3))) % eyes[0].length),
      mouth: uint8(uint256(keccak256(abi.encode(seed, 4))) % mouths[0].length)
    });
  }

  function _uintToStr(uint256 _i) private pure returns (string memory _uintAsString) {
    if (_i == 0) {
      return "0";
    }
    uint256 j = _i;
    uint256 len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint256 k = len;
    while (_i != 0) {
      k = k - 1;
      uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      _i /= 10;
    }
    return string(bstr);
  }
}