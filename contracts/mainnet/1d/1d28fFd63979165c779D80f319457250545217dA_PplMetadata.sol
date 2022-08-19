// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "base64-sol/base64.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../../lib/strings.sol";

/// @title .ppl NFT Metadata contract
/// @author Tempe Techie
/// @notice Contract that generates metadata for the .ppl domain NFT.
contract PplMetadata {
  enum Cat{ BG, CLS1, CLS2, CLS3 }

  string[] bg = ["2f0d49", "FF00FF", "FF1493", "FF2000", "227f20", "FF7F50", "FFD700", "00FF00", "7FFF00", "0000CD", "8B4513", "D2691E", "800008", "00CED1", "DC143C"];
  string[] cls = ["2E8B57", "c111c3", "2e3192", "B0C4DE", "BDB76B", "008080", "a82928", "98847d", "af9e94", "DB7093", "C71585", "DDA0DD", "BA55D3", "7B68EE", "CD5C5C", "FF7F50", "FFE4B5", "ADD8E6", "B0E0E6", "CD853F"];

  function getBgIndex(uint256 _tokenId) internal view returns(uint) {
    return uint(keccak256(abi.encodePacked(_tokenId))) % bg.length;
  }

  function getClassColors(uint256 _tokenId) internal view returns(string[3] memory) {
    uint cls1 = uint(keccak256(abi.encodePacked(_tokenId,address(this)))) % cls.length;
    uint cls2 = uint(keccak256(abi.encodePacked(address(this),_tokenId))) % cls.length;
    uint cls3 = uint(keccak256(abi.encodePacked(address(0),_tokenId))) % cls.length;

    // decrease likelyhood of classes with same color code
    if (cls1 == cls2) {
      cls2 = uint(keccak256(abi.encodePacked(address(this),_tokenId,cls2))) % cls.length;
    } else if (cls3 == cls1 || cls3 == cls2) {
      cls3 = uint(keccak256(abi.encodePacked(address(0),_tokenId,cls3))) % cls.length;
    }

    return [cls[cls1], cls[cls2], cls[cls3]];
  }

  function getMetadata(
    string calldata _domainName, 
    string calldata _tld, 
    uint256 _tokenId
  ) external view returns(string memory) {
    string memory fullDomainName = string(abi.encodePacked(_domainName, _tld));
    uint256 domainLength = strings.len(strings.toSlice(_domainName));

    return string(
      abi.encodePacked("data:application/json;base64,",Base64.encode(bytes(abi.encodePacked(
        '{"name": "', fullDomainName ,'", ',
        '"attributes": [',
        '{"trait_type": "length", "value": "', Strings.toString(domainLength) ,'"}, ',
        _getOtherMetadata(fullDomainName, _tokenId)))))
    );
  }

  function _getOtherMetadata(
    string memory _fullDomainName, 
    uint256 _tokenId
  ) internal view returns (string memory) {
    string memory bgColor = bg[getBgIndex(_tokenId)];
    string[3] memory colors = getClassColors(_tokenId);

    return string(
      abi.encodePacked(
        _getColorTraits([bgColor, colors[0], colors[1], colors[2]]),
        '"description": "A collection of PEOPLE web3 domain (.ppl) NFTs created by Joie Degarlic: https://ppl.domains", ',
        '"image": "', _getImage(_fullDomainName, bgColor, [colors[0], colors[1], colors[2]]), '"}')
    );
  }
  
  function _getColorTraits(
    string[4] memory _colors
  ) internal pure returns (string memory) {
    return string(
      abi.encodePacked(
        '{"trait_type": "background", "value": "#', _colors[0] ,'"}, ',
        '{"trait_type": "color 1", "value": "#', _colors[1] ,'"}, ',
        '{"trait_type": "color 2", "value": "#', _colors[2] ,'"}, ',
        '{"trait_type": "color 3", "value": "#', _colors[3] ,'"}',
        '], '
      )
    );
  }

  function _getImage(
    string memory _fullDomainName, 
    string memory _bg,
    string[3] memory _clsArray
  ) internal pure returns (string memory) {
    string memory svgBase64Encoded = Base64.encode(bytes(string(abi.encodePacked(
      _getImagePart1(_bg, _clsArray),
      _getImagePart2(_fullDomainName)
    ))));

    return string(abi.encodePacked("data:image/svg+xml;base64,", svgBase64Encoded));
  }

  function _getImagePart1( 
    string memory _bg,
    string[3] memory _clsArray
  ) internal pure returns (string memory) {
    return string(abi.encodePacked('<svg version="1.0" xmlns="http://www.w3.org/2000/svg" width="1080.000000pt" height="1080.000000pt" viewBox="0 0 1080.000000 1080.000000" preserveAspectRatio="xMidYMid meet" style="background-color:#',
    _bg,'">',
    '<defs><style>.cls-1{fill:#',_clsArray[0],'}.cls-2{fill:#',_clsArray[1],'}.cls-3{fill:#',_clsArray[2],'}.s-1'));
  }

  function _getImagePart2(
    string memory _fullDomainName
  ) internal pure returns (string memory) {
    return string(abi.encodePacked(
      '{fill:#243144}.s-2{fill:#435e69}.s-3{fill:#869d9d}.s-4{fill:#597c79}</style></defs>',
      '<g transform="translate(0.000000,1080.000000) scale(0.100000,-0.100000)" fill="#000000" stroke="none"><path class="cls-1" d="M5190 10303 c-676 -37 -1295 -196 -1885 -484 -512 -250 -938 -559 -1355 -985 -776 -793 -1250 -1812 -1366 -2939 -25 -235 -25 -715 0 -950 100 -973 454 -1838 1065 -2604 134 -168 488 -531 646 -663 786 -656 1682 -1030 2710 -1130 191 -19 693 -15 885 6 1010 110 1883 479 2655 1124 138 116 508 492 621 632 629 780 989 1650 1090 2635 25 235 25 715 0 950 -115 1121 -586 2137 -1355 2928 -366 376 -698 631 -1146 882 -763 427 -1700 646 -2565 598z m205 -910 c4 -10 13 -61 21 -113 18 -125 64 -218 159 -320 38 -41 75 -84 81 -95 6 -11 55 -58 110 -104 54 -46 226 -194 381 -329 272 -237 285 -250 376 -376 75 -104 105 -156 147 -256 47 -114 51 -130 47 -183 -5 -57 21 -262 43 -342 6 -22 23 -69 37 -104 24 -61 24 -68 18 -230 -6 -158 -2 -247 26 -568 l12 -142 -27 -71 c-16 -39 -25 -74 -22 -77 4 -4 28 14 54 40 l48 47 131 0 132 0 22 -70 23 -69 140 -62 c78 -34 192 -84 254 -111 l113 -50 23 21 c12 11 27 21 32 21 5 0 31 -42 56 -94 l47 -94 53 -16 c29 -8 54 -13 56 -11 2 2 -1 49 -7 105 -6 55 -11 146 -11 201 0 93 -1 100 -18 95 -22 -8 -111 30 -118 49 -3 8 0 36 6 62 7 26 12 59 12 73 1 26 -24 100 -43 134 -10 17 0 29 72 98 73 68 88 78 114 75 36 -5 94 21 97 42 0 9 0 25 0 36 -1 12 11 36 26 54 27 33 29 33 58 20 26 -13 29 -19 26 -54 -2 -29 -11 -48 -33 -67 -16 -15 -29 -34 -29 -41 0 -7 16 -28 35 -47 19 -18 39 -50 45 -69 6 -20 21 -57 32 -83 20 -45 20 -48 3 -85 -10 -21 -25 -47 -35 -58 -14 -16 -19 -47 -24 -140 -9 -157 -33 -343 -51 -396 -14 -39 -14 -44 3 -63 10 -12 29 -38 42 -59 12 -21 27 -36 34 -34 6 2 64 17 129 33 64 15 117 33 117 39 0 5 -11 45 -25 88 -14 43 -25 95 -25 116 0 33 -4 40 -25 45 -42 11 -46 33 -34 166 l12 121 -32 50 c-35 56 -38 86 -16 129 9 16 18 50 22 75 3 25 12 50 19 56 8 6 14 24 14 38 0 44 30 119 60 151 40 43 73 40 105 -10 28 -45 26 -90 -7 -126 l-19 -22 38 -7 c48 -8 83 -31 83 -53 0 -9 7 -35 15 -57 26 -73 18 -130 -25 -180 -14 -17 -16 -32 -10 -100 4 -44 11 -103 15 -132 7 -49 6 -53 -21 -78 -26 -24 -29 -34 -31 -93 0 -37 -4 -84 -8 -104 l-7 -38 123 68 c68 38 150 84 182 102 66 37 211 76 442 120 130 24 442 106 517 135 11 4 18 0 22 -12 35 -120 43 -823 13 -1073 -117 -948 -471 -1760 -1072 -2458 -93 -108 -115 -124 -115 -81 0 10 -4 19 -9 19 -4 0 -14 27 -21 60 -7 33 -16 60 -20 60 -7 0 -34 58 -45 98 -4 12 -10 22 -14 22 -5 0 -14 14 -21 30 -7 18 -20 30 -31 30 -10 0 -21 9 -24 20 -4 14 -15 20 -36 20 -16 0 -29 5 -29 10 0 6 -96 10 -267 10 -263 0 -268 0 -295 -23 -59 -49 -73 -57 -137 -76 -98 -30 -183 -51 -203 -51 -19 0 -22 -8 -12 -34 9 -22 50 -20 178 9 60 14 111 24 112 22 1 -1 10 -56 20 -122 l17 -120 -55 -120 c-30 -66 -58 -128 -61 -137 -3 -9 -27 -26 -52 -37 -25 -11 -58 -30 -73 -41 -107 -84 -155 -116 -212 -141 -102 -47 -219 -117 -295 -179 -38 -31 -110 -80 -160 -110 -105 -63 -286 -189 -435 -304 -144 -112 -179 -130 -385 -205 -216 -79 -225 -81 -331 -81 -55 0 -148 -5 -209 -11 -112 -10 -398 3 -420 21 -5 4 -48 28 -95 53 -141 75 -145 78 -188 148 -40 63 -48 70 -140 119 -148 80 -222 131 -282 198 -173 192 -237 268 -255 302 -11 21 -33 58 -49 82 -16 23 -41 66 -56 93 -42 79 -63 116 -87 145 -13 15 -23 33 -23 39 0 22 -72 90 -107 102 -35 11 -66 9 -168 -10 -27 -6 -78 -10 -112 -10 -35 -1 -63 -5 -63 -10 0 -22 -77 -33 -216 -32 -91 1 -144 -2 -144 -9 0 -5 -7 -10 -15 -10 -8 0 -15 5 -15 10 0 6 -25 10 -55 10 -30 0 -55 -4 -55 -10 0 -6 -37 -10 -90 -10 -53 0 -90 -4 -90 -10 0 -5 -22 -10 -50 -10 -27 0 -50 -4 -50 -10 0 -5 -22 -10 -50 -10 -27 0 -50 -4 -50 -10 0 -5 -22 -10 -50 -10 -43 0 -50 -3 -50 -20 0 -11 -7 -20 -15 -20 -8 0 -15 -4 -15 -10 0 -5 -7 -10 -16 -10 -9 0 -26 -11 -38 -25 l-22 -26 -150 148 c-748 743 -1193 1658 -1319 2713 -22 183 -31 625 -16 820 13 170 58 501 69 512 4 4 23 3 42 -2 46 -13 238 3 430 36 l145 25 89 -40 c86 -40 91 -41 196 -41 225 0 557 -67 827 -166 84 -31 160 -54 168 -50 25 9 37 55 46 176 14 202 76 363 172 446 55 46 152 94 193 94 25 0 46 11 83 43 64 54 68 67 34 104 -44 47 -147 202 -140 210 4 3 38 -6 76 -21 l69 -27 58 19 c61 20 77 38 103 114 13 36 35 44 65 24 30 -19 31 -28 47 -308 l12 -207 30 -28 30 -28 -6 25 c-4 14 -12 68 -19 122 -11 89 -10 104 11 205 20 92 32 122 80 203 31 52 72 129 91 170 18 41 44 90 57 109 13 18 23 44 23 57 0 12 5 26 10 29 6 3 10 14 10 23 0 40 119 229 187 297 22 22 84 87 138 145 102 107 168 166 223 194 18 9 32 21 32 26 0 18 206 200 226 200 8 0 148 115 248 204 71 64 84 81 128 172 57 119 76 185 89 309 5 50 13 128 18 175 5 46 7 88 5 92 -7 12 5 28 21 28 7 0 16 -8 20 -17z"/><path class="cls-1" d="M5270 5874 c-134 -14 -170 -23 -361 -95 -68 -26 -82 -37 -142 -105 -61 -68 -67 -79 -67 -119 0 -40 6 -49 92 -143 l92 -101 130 -45 c129 -45 133 -45 296 -51 l165 -6 105 58 c95 53 113 68 202 168 57 63 119 122 148 140 28 16 50 33 50 36 0 4 -40 42 -89 86 -86 76 -93 80 -242 136 -171 63 -163 63 -379 41z"/><path class="cls-2" d="M5360 9408 c0 -28 -30 -365 -36 -400 -4 -29 -2 -38 9 -38 11 0 13 -10 10 -44 -5 -38 0 -53 39 -119 36 -63 58 -87 131 -143 65 -50 121 -108 229 -238 179 -215 270 -319 371 -422 l79 -82 -16 -70 c-9 -39 -16 -79 -16 -89 0 -14 34 -35 131 -83 134 -67 153 -84 151 -137 -1 -18 8 -25 51 -38 65 -22 76 -31 57 -49 -13 -12 -38 -9 -175 20 -173 37 -148 37 -420 8 -27 -3 -120 -22 -205 -44 -85 -21 -156 -37 -159 -34 -2 2 22 28 55 58 32 30 56 57 52 61 -4 4 -31 1 -60 -7 -52 -14 -54 -16 -134 -133 l-81 -119 -12 -104 c-23 -201 -25 -329 -6 -422 10 -47 20 -148 24 -224 l6 -140 80 -18 c44 -9 86 -15 93 -13 15 5 18 -170 3 -180 -10 -6 -204 -35 -208 -31 -2 2 13 21 32 43 19 23 35 46 35 51 0 13 -101 72 -123 72 -8 0 -29 -24 -46 -54 -45 -80 -61 -89 -126 -66 -29 10 -102 23 -161 29 -59 6 -109 13 -111 14 -4 5 135 128 197 176 l45 34 -1 471 c0 259 -4 479 -8 489 -11 23 -23 22 -37 -5 -6 -13 -13 -25 -15 -27 -2 -2 -40 20 -86 47 -46 28 -126 67 -178 87 l-95 37 -155 -7 c-132 -6 -178 -13 -310 -45 -85 -22 -156 -37 -158 -35 -2 2 6 33 19 69 l24 65 55 6 c30 4 108 13 172 21 64 8 121 14 127 14 7 0 11 28 11 74 0 40 5 88 12 107 6 19 44 71 85 115 40 45 73 90 73 101 0 11 -13 53 -30 93 -16 40 -30 79 -30 86 0 8 -5 14 -11 14 -21 0 -248 -215 -365 -347 -120 -134 -122 -138 -170 -257 -53 -135 -199 -444 -237 -503 -15 -23 -34 -80 -47 -141 -22 -103 -22 -104 -5 -225 10 -67 22 -127 27 -134 5 -6 8 -94 6 -195 -3 -204 -6 -191 83 -362 37 -70 214 -306 230 -306 5 0 9 -5 9 -11 0 -7 8 -19 18 -28 9 -9 25 -31 36 -50 10 -19 27 -42 37 -52 11 -11 19 -26 19 -34 0 -8 3 -15 8 -15 4 0 14 -15 21 -32 25 -57 65 -118 77 -118 14 0 74 102 74 126 0 9 -32 52 -71 95 -46 51 -68 83 -63 91 4 7 32 43 62 80 47 59 68 75 166 128 88 47 119 70 150 110 29 37 50 53 86 65 60 20 83 14 140 -36 l45 -40 -37 7 c-46 8 -48 -2 -13 -54 14 -20 25 -49 25 -63 0 -16 7 -30 18 -34 14 -5 10 -12 -27 -44 -24 -21 -42 -42 -40 -48 2 -6 60 10 135 38 119 43 147 49 292 63 88 9 165 16 171 16 6 0 11 5 11 10 0 6 -8 10 -17 10 -35 0 4 18 77 35 41 10 116 33 166 51 l92 32 108 -90 c73 -61 140 -106 206 -139 l98 -49 -35 -53 c-29 -42 -35 -61 -35 -103 0 -40 -11 -76 -50 -164 -46 -103 -50 -118 -50 -189 0 -75 -1 -80 -52 -166 -49 -81 -63 -97 -183 -192 -93 -75 -163 -121 -247 -164 l-118 -59 -159 0 -159 0 -29 46 c-23 37 -42 53 -108 86 -44 22 -139 85 -212 140 -124 94 -138 108 -248 254 -65 85 -124 154 -131 154 -8 0 -14 -2 -14 -5 0 -13 126 -234 146 -255 21 -23 23 -35 27 -165 5 -151 21 -305 61 -565 19 -129 26 -228 33 -455 11 -397 5 -824 -12 -963 -8 -62 -15 -119 -15 -126 0 -8 -15 -36 -34 -63 -18 -27 -43 -67 -54 -88 -36 -72 -291 -310 -358 -335 -14 -6 -79 -10 -145 -10 -82 0 -119 -4 -119 -11 0 -6 16 -29 35 -50 19 -22 35 -44 35 -50 0 -6 10 -24 23 -39 24 -29 45 -66 87 -145 15 -27 40 -70 56 -94 16 -24 40 -63 54 -87 23 -39 85 -114 250 -296 60 -67 134 -118 282 -198 92 -49 100 -56 140 -119 43 -70 47 -73 188 -148 47 -25 90 -49 95 -53 22 -18 308 -31 420 -21 61 6 154 11 209 11 64 0 116 6 150 17 131 42 375 137 407 159 19 13 38 24 42 24 4 0 55 38 114 84 148 114 330 242 438 306 50 30 122 79 160 110 76 62 193 132 295 179 57 25 105 57 212 141 15 11 48 30 73 41 25 11 49 28 52 37 3 9 31 71 61 137 l55 120 -17 120 c-10 66 -19 121 -20 122 -1 2 -52 -8 -112 -22 -133 -30 -171 -32 -178 -7 -7 20 -8 20 -411 52 -266 21 -343 37 -478 98 -169 77 -311 214 -343 331 -7 25 -19 71 -28 101 -8 30 -26 89 -41 130 -14 41 -37 107 -50 145 -13 39 -35 142 -49 230 -23 147 -26 203 -36 705 -12 574 -11 571 -57 605 -15 11 -11 17 117 162 106 120 205 267 294 438 77 147 94 171 254 350 69 78 87 105 111 171 16 44 34 91 40 107 12 30 -2 269 -19 322 -5 17 -8 147 -6 295 3 265 0 289 -35 366 -11 22 -19 49 -19 60 0 11 -6 40 -14 65 -21 66 -39 233 -32 287 6 43 1 62 -45 173 -42 101 -70 149 -149 259 -94 130 -108 144 -359 363 -144 126 -318 276 -386 333 -69 58 -125 109 -125 115 0 6 -38 53 -84 104 -46 51 -93 105 -103 121 -10 15 -31 94 -48 182 -18 89 -36 157 -43 160 -7 2 -12 -2 -12 -10z m1250 -2100 c58 -33 107 -62 109 -64 8 -7 -22 -72 -60 -130 l-40 -62 -70 -7 c-38 -4 -69 -11 -69 -16 0 -5 -68 -43 -150 -84 l-150 -75 -143 10 c-78 6 -145 14 -148 18 -4 4 -14 29 -24 55 -10 26 -22 50 -27 54 -6 3 -23 -4 -38 -16 -21 -15 -37 -19 -60 -15 -17 4 -33 11 -36 15 -3 5 14 61 38 124 l43 115 70 27 c38 14 106 44 150 66 44 22 94 44 110 48 17 5 111 6 210 3 l180 -5 105 -61z m-1838 13 c45 -6 49 -9 132 -114 47 -60 86 -113 86 -119 0 -6 -29 -7 -82 -3 -66 5 -87 3 -103 -8 -23 -18 -25 -15 40 -46 l50 -23 -147 -74 -147 -73 -151 19 c-83 11 -155 22 -159 24 -5 3 -11 36 -15 73 -15 152 -8 146 -128 109 -43 -14 -78 -21 -78 -18 0 4 56 57 125 117 118 104 129 111 202 132 69 19 93 21 203 16 69 -3 146 -9 172 -12z"/><path class="cls-3" d="M5275 8863 c-66 -127 -99 -175 -171 -243 -72 -69 -218 -190 -229 -190 -3 0 -46 -32 -95 -70 -90 -72 -160 -144 -160 -165 0 -7 14 -45 30 -85 17 -40 30 -82 30 -93 0 -11 -33 -56 -73 -101 -41 -44 -79 -96 -85 -115 -13 -37 -16 -171 -4 -171 4 0 95 -7 202 -15 l195 -15 95 -64 c142 -94 134 -59 135 -637 l0 -466 -45 -34 c-62 -48 -201 -171 -197 -176 2 -1 52 -8 111 -14 59 -6 132 -19 161 -29 65 -23 81 -14 126 66 17 30 38 54 46 54 22 0 123 -59 123 -72 0 -5 -16 -28 -35 -51 -19 -22 -34 -41 -32 -43 4 -4 198 25 208 31 5 4 9 41 9 85 0 89 6 83 -110 109 l-75 17 -6 140 c-4 76 -14 177 -24 224 -19 93 -17 221 6 422 l12 104 81 119 81 119 55 14 c30 7 96 24 145 37 50 13 155 31 235 39 l145 15 134 -34 c74 -18 138 -32 142 -29 4 2 2 18 -4 35 -10 27 -31 41 -144 98 -98 48 -133 70 -133 84 0 10 7 50 16 89 l16 70 -79 82 c-101 103 -192 207 -371 422 -108 129 -164 188 -229 238 -71 54 -95 81 -130 139 -25 43 -42 85 -43 105 0 52 -22 37 -65 -45z"/><path class="cls-3" d="M4754 6094 c-28 -10 -54 -31 -80 -64 -31 -40 -62 -63 -150 -110 -98 -53 -119 -69 -166 -128 -30 -37 -58 -73 -62 -80 -5 -8 17 -40 63 -91 39 -43 71 -86 71 -96 0 -9 -16 -44 -36 -77 -36 -63 -38 -86 -4 -95 10 -3 71 -74 135 -158 110 -145 125 -159 248 -253 73 -55 168 -118 212 -140 66 -33 85 -49 108 -86 l29 -46 159 0 159 0 118 59 c84 43 154 89 247 164 120 95 134 111 183 192 51 86 52 91 52 166 0 68 5 87 41 170 23 52 45 98 50 103 5 6 9 37 9 71 0 52 5 67 35 112 l35 53 -98 49 c-66 33 -133 78 -206 139 l-108 90 -101 -33 c-134 -44 -206 -65 -223 -65 -35 0 -5 -20 104 -69 64 -29 130 -56 147 -59 41 -7 213 -127 239 -167 24 -36 21 -42 -33 -75 -27 -17 -83 -70 -125 -118 -92 -107 -151 -158 -253 -219 l-78 -46 -157 6 c-150 6 -161 8 -292 51 -74 25 -147 53 -161 63 -14 10 -36 38 -50 63 -13 25 -44 65 -69 90 -45 43 -46 46 -46 104 l0 60 63 61 c34 34 72 67 85 74 12 6 22 18 22 26 0 7 19 28 41 46 36 29 39 34 25 44 -9 7 -16 23 -16 36 0 14 -11 41 -25 61 -35 52 -33 62 13 54 l37 -7 -40 36 c-40 36 -76 56 -98 54 -7 0 -31 -7 -53 -15z"/><path d="M4435 7618 c-22 -5 -93 -15 -158 -22 -73 -8 -124 -19 -132 -27 -10 -12 -45 -106 -45 -123 0 -9 62 5 277 59 29 7 123 16 210 20 156 6 159 6 223 -20 70 -29 156 -71 174 -85 6 -5 27 -23 48 -40 l36 -31 21 30 c43 61 26 99 -74 160 -95 58 -109 63 -174 67 -36 3 -84 7 -106 10 -79 10 -261 12 -300 2z"/><path d="M6090 7603 c-30 -2 -60 -9 -66 -14 -6 -5 -37 -8 -67 -5 -31 2 -57 0 -59 -5 -3 -8 -58 -17 -113 -18 -22 -1 -22 -1 -132 -87 -98 -77 -97 -86 6 -60 180 46 290 68 368 72 48 3 92 9 98 13 33 24 189 4 323 -43 74 -25 96 -25 106 -1 10 26 -54 58 -214 108 -126 40 -167 46 -250 40z"/><path class="s-1" d="M4394 7311 c-34 -10 -80 -32 -101 -49 -22 -17 -43 -29 -45 -26 -17 17 -194 -138 -181 -159 2 -4 10 -3 17 2 7 6 16 8 19 5 7 -7 140 37 145 48 2 5 15 8 28 8 14 0 42 9 64 20 l39 20 52 -45 53 -45 107 0 c82 0 109 -3 19 -15 16 -19 47 -19 80 0 16 9 54 14 102 15 42 0 79 4 82 8 3 4 -14 29 -36 55 -54 63 -145 108 -296 147 -138 34 -163 35 -248 11z"/><path class="s-1" d="M5896 7232 c-129 -51 -140 -62 -134 -132 4 -45 12 -45 175 4 81 24 82 24 130 6 l48 -18 -35 -9 c-49 -13 -48 -33 5 -67 l46 -28 121 73 c114 68 169 87 193 69 6 -4 28 -11 50 -14 22 -4 50 -10 63 -13 53 -13 15 26 -91 94 l-112 71 -170 6 -170 6 -119 -48z"/><path class="s-2" d="M6105 7367 c-22 -8 -65 -26 -95 -42 -30 -16 -91 -43 -135 -60 -55 -23 -85 -41 -95 -58 -8 -14 -11 -29 -7 -33 4 -4 64 14 133 41 l126 47 162 -7 161 -7 88 -55 c48 -31 86 -57 85 -59 -2 -1 -37 1 -78 7 l-74 9 -117 -70 c-65 -39 -123 -70 -129 -70 -17 0 -83 47 -73 53 4 2 23 8 41 12 45 9 37 24 -26 47 l-52 20 -103 -31 c-149 -43 -141 -44 -148 9 -4 35 -7 41 -13 25 -5 -11 -14 -33 -21 -50 -43 -106 -43 -109 5 -119 43 -8 94 28 85 61 -6 24 8 32 21 12 4 -6 19 -9 36 -5 25 5 42 -4 120 -64 134 -104 157 -100 327 58 l101 94 21 -47 21 -48 64 7 c35 4 69 9 76 11 16 6 59 75 86 138 l21 47 -37 24 c-20 12 -71 41 -113 64 l-76 41 -174 5 c-132 5 -184 3 -214 -7z"/><path class="s-2" d="M4470 7331 c-8 -5 -12 -13 -8 -16 4 -4 68 -22 143 -41 86 -22 167 -50 217 -75 44 -22 86 -39 94 -37 9 2 -7 29 -47 80 l-61 76 -76 6 c-198 15 -248 16 -262 7z"/><path class="s-2" d="M4303 7182 c-54 -27 -68 -47 -34 -49 10 -1 56 -30 102 -65 46 -36 101 -74 122 -86 l37 -21 65 20 c36 11 82 31 101 44 20 13 44 27 55 30 26 9 24 18 -11 43 -26 19 -42 22 -133 22 l-103 0 -53 45 c-29 25 -62 45 -74 44 -12 0 -46 -12 -74 -27z"/><path class="s-3" d="M4255 7130 c-3 -6 -4 -18 -1 -28 3 -9 8 -48 11 -87 10 -121 30 -133 261 -150 64 -5 75 -3 126 23 31 16 82 40 114 52 78 29 135 61 127 72 -3 6 -25 18 -49 29 l-44 18 -68 -25 c-37 -14 -96 -36 -132 -48 l-65 -23 -35 23 c-19 13 -38 24 -43 24 -5 0 -47 29 -93 65 -86 66 -98 73 -109 55z"/><path class="s-3" d="M6320 7040 c-52 -49 -104 -92 -115 -95 -11 -4 -30 -11 -42 -17 -16 -8 -48 -7 -115 1 l-93 11 -60 65 c-53 58 -85 80 -85 58 0 -5 23 -57 71 -158 9 -19 21 -21 117 -23 59 -2 123 -7 143 -12 34 -9 46 -5 189 70 85 44 155 82 157 84 2 1 -6 26 -18 54 -14 33 -28 52 -38 52 -9 -1 -59 -41 -111 -90z"/><path class="s-4" d="M5876 7065 c-10 -8 -23 -12 -27 -9 -23 14 -3 -17 44 -68 l52 -57 84 -11 c45 -6 85 -9 87 -7 5 4 -190 156 -209 162 -7 3 -21 -2 -31 -10z"/><polygon class="cls-1" points="1750,4250 2500,3750 2750,4250"/><polygon class="cls-2" points="2750,4250 3000,3750 3750,4250"/><polygon class="cls-3" points="2450,4750 2750,4250 3050,4750"/></g><g transform="translate(0.000000,1080.000000) scale(0.100000,0.100000)"><text x="5300" y="-9500" text-anchor="middle" font-family="monospace" font-size="400" fill="white">',
      _fullDomainName,
      '</text></g></svg>'
    ));
  }

}

// SPDX-License-Identifier: MIT

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

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
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <[email protected]>
 */

pragma solidity ^0.8.0;

library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint _len) private pure {
        // Copy word-length chunks while possible
        for(; _len >= 32; _len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = type(uint).max;
        if (_len > 0) {
            mask = 256 ** (32 - _len) - 1;
        }
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    /*
     * @dev Returns the length of a null-terminated bytes32 string.
     * @param self The value to find the length of.
     * @return The length of the string, from 0 to 32.
     */
    function len(bytes32 self) internal pure returns (uint) {
        uint ret;
        if (self == 0)
            return 0;
        if (uint(self) & type(uint128).max == 0) {
            ret += 16;
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);
        }
        if (uint(self) & type(uint64).max == 0) {
            ret += 8;
            self = bytes32(uint(self) / 0x10000000000000000);
        }
        if (uint(self) & type(uint32).max == 0) {
            ret += 4;
            self = bytes32(uint(self) / 0x100000000);
        }
        if (uint(self) & type(uint16).max == 0) {
            ret += 2;
            self = bytes32(uint(self) / 0x10000);
        }
        if (uint(self) & type(uint8).max == 0) {
            ret += 1;
        }
        return 32 - ret;
    }

    /*
     * @dev Returns a slice containing the entire bytes32, interpreted as a
     *      null-terminated utf-8 string.
     * @param self The bytes32 value to convert to a slice.
     * @return A new slice containing the value of the input argument up to the
     *         first null.
     */
    function toSliceB32(bytes32 self) internal pure returns (slice memory ret) {
        // Allocate space for `self` in memory, copy it there, and point ret at it
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }

    /*
     * @dev Returns a new slice containing the same data as the current slice.
     * @param self The slice to copy.
     * @return A new slice containing the same data as `self`.
     */
    function copy(slice memory self) internal pure returns (slice memory) {
        return slice(self._len, self._ptr);
    }

    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice's text.
     */
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

    /*
     * @dev Returns the length in runes of the slice. Note that this operation
     *      takes time proportional to the length of the slice; avoid using it
     *      in loops, and call `slice.empty()` if you only need to know whether
     *      the slice is empty or not.
     * @param self The slice to operate on.
     * @return The length of the slice in runes.
     */
    function len(slice memory self) internal pure returns (uint l) {
        // Starting at ptr-31 means the LSB will be the byte we care about
        uint ptr = self._ptr - 31;
        uint end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly { b := and(mload(ptr), 0xFF) }
            if (b < 0x80) {
                ptr += 1;
            } else if(b < 0xE0) {
                ptr += 2;
            } else if(b < 0xF0) {
                ptr += 3;
            } else if(b < 0xF8) {
                ptr += 4;
            } else if(b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }

    /*
     * @dev Returns true if the slice is empty (has a length of 0).
     * @param self The slice to operate on.
     * @return True if the slice is empty, False otherwise.
     */
    function empty(slice memory self) internal pure returns (bool) {
        return self._len == 0;
    }

    /*
     * @dev Returns a positive number if `other` comes lexicographically after
     *      `self`, a negative number if it comes before, or zero if the
     *      contents of the two slices are equal. Comparison is done per-rune,
     *      on unicode codepoints.
     * @param self The first slice to compare.
     * @param other The second slice to compare.
     * @return The result of the comparison.
     */
    function compare(slice memory self, slice memory other) internal pure returns (int) {
        uint shortest = self._len;
        if (other._len < self._len)
            shortest = other._len;

        uint selfptr = self._ptr;
        uint otherptr = other._ptr;
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                // Mask out irrelevant bytes and check again
                uint mask = type(uint).max; // 0xffff...
                if(shortest < 32) {
                  mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                }
                unchecked {
                    uint diff = (a & mask) - (b & mask);
                    if (diff != 0)
                        return int(diff);
                }
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int(self._len) - int(other._len);
    }

    /*
     * @dev Returns true if the two slices contain the same text.
     * @param self The first slice to compare.
     * @param self The second slice to compare.
     * @return True if the slices are equal, false otherwise.
     */
    function equals(slice memory self, slice memory other) internal pure returns (bool) {
        return compare(self, other) == 0;
    }

    /*
     * @dev Extracts the first rune in the slice into `rune`, advancing the
     *      slice to point to the next rune and returning `self`.
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `rune`.
     */
    function nextRune(slice memory self, slice memory rune) internal pure returns (slice memory) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint l;
        uint b;
        // Load the first byte of the rune into the LSBs of b
        assembly { b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF) }
        if (b < 0x80) {
            l = 1;
        } else if(b < 0xE0) {
            l = 2;
        } else if(b < 0xF0) {
            l = 3;
        } else {
            l = 4;
        }

        // Check for truncated codepoints
        if (l > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += l;
        self._len -= l;
        rune._len = l;
        return rune;
    }

    /*
     * @dev Returns the first rune in the slice, advancing the slice to point
     *      to the next rune.
     * @param self The slice to operate on.
     * @return A slice containing only the first rune from `self`.
     */
    function nextRune(slice memory self) internal pure returns (slice memory ret) {
        nextRune(self, ret);
    }

    /*
     * @dev Returns the number of the first codepoint in the slice.
     * @param self The slice to operate on.
     * @return The number of the first codepoint in the slice.
     */
    function ord(slice memory self) internal pure returns (uint ret) {
        if (self._len == 0) {
            return 0;
        }

        uint word;
        uint length;
        uint divisor = 2 ** 248;

        // Load the rune into the MSBs of b
        assembly { word:= mload(mload(add(self, 32))) }
        uint b = word / divisor;
        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if(b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if(b < 0xF0) {
            ret = b & 0x0F;
            length = 3;
        } else {
            ret = b & 0x07;
            length = 4;
        }

        // Check for truncated codepoints
        if (length > self._len) {
            return 0;
        }

        for (uint i = 1; i < length; i++) {
            divisor = divisor / 256;
            b = (word / divisor) & 0xFF;
            if (b & 0xC0 != 0x80) {
                // Invalid UTF-8 sequence
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

    /*
     * @dev Returns the keccak-256 hash of the slice.
     * @param self The slice to hash.
     * @return The hash of the slice.
     */
    function keccak(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

    /*
     * @dev Returns true if `self` starts with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function startsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        if (self._ptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }
        return equal;
    }

    /*
     * @dev If `self` starts with `needle`, `needle` is removed from the
     *      beginning of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function beyond(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

    /*
     * @dev Returns true if the slice ends with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function endsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        uint selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }

        return equal;
    }

    /*
     * @dev If `self` ends with `needle`, `needle` is removed from the
     *      end of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function until(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        uint selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr = selfptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr >= end)
                        return selfptr + selflen;
                    ptr++;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    // Returns the memory address of the first byte after the last occurrence of
    // `needle` in `self`, or the address of `self` if not found.
    function rfindPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                ptr = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr <= selfptr)
                        return selfptr;
                    ptr--;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr + needlelen;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }

    /*
     * @dev Modifies `self` to contain everything from the first occurrence of
     *      `needle` to the end of the slice. `self` is set to the empty slice
     *      if `needle` is not found.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function find(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

    /*
     * @dev Modifies `self` to contain the part of the string from the start of
     *      `self` to the end of the first occurrence of `needle`. If `needle`
     *      is not found, `self` is set to the empty slice.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function rfind(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function split(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        split(self, needle, token);
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and `token` to everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function rsplit(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and returning everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` after the last occurrence of `delim`.
     */
    function rsplit(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        rsplit(self, needle, token);
    }

    /*
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return The number of occurrences of `needle` found in `self`.
     */
    function count(slice memory self, slice memory needle) internal pure returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }

    /*
     * @dev Returns True if `self` contains `needle`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return True if `needle` is found in `self`, false otherwise.
     */
    function contains(slice memory self, slice memory needle) internal pure returns (bool) {
        return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(slice memory self, slice memory other) internal pure returns (string memory) {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

    /*
     * @dev Joins an array of slices, using `self` as a delimiter, returning a
     *      newly allocated string.
     * @param self The delimiter to use.
     * @param parts A list of slices to join.
     * @return A newly allocated string containing all the slices in `parts`,
     *         joined with `self`.
     */
    function join(slice memory self, slice[] memory parts) internal pure returns (string memory) {
        if (parts.length == 0)
            return "";

        uint length = self._len * (parts.length - 1);
        for(uint i = 0; i < parts.length; i++)
            length += parts[i]._len;

        string memory ret = new string(length);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        for(uint i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }

    /**
     * Lower
     * 
     * Converts all the values of a string to their corresponding lower case
     * value.
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string base to convert to lower case
     * @return string 
     */
    function lower(string memory _base)
        internal
        pure
        returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _lower(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    /**
     * Lower
     * 
     * Convert an alphabetic character to lower case and return the original
     * value when not alphabetic
     * 
     * @param _b1 The byte to be converted to lower case
     * @return bytes1 The converted value if the passed value was alphabetic
     *                and in a upper case otherwise returns the original value
     */
    function _lower(bytes1 _b1)
        private
        pure
        returns (bytes1) {

        if (_b1 >= 0x41 && _b1 <= 0x5A) {
            return bytes1(uint8(_b1) + 32);
        }

        return _b1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}