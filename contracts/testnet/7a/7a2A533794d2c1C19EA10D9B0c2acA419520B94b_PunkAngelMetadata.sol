// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "base64-sol/base64.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../../lib/strings.sol";

/// @title Punk Angel domain metadata contract
/// @author Tempe Techie
/// @notice Contract that generates metadata for the Punk Angel domain.
contract PunkAngelMetadata is Ownable {
  address public minter;

  mapping(string => uint256) public uniqueFeaturesId; // uniqueFeaturesId => tokenId
  mapping(uint256 => string) public idToUniqueFeatures; // tokenId => uniqueFeaturesId
  mapping(uint256 => uint256) public pricePaid; // tokenId => price (price that user paid for the domain)

  // face:
  // - 0: no item on the face
  // - 1: big VR glasses
  // - 2: thin VR glasses
  // - 3: gas mask
  string[] face = [
    "",
    '<g id="layer_7" data-name="layer 7"><rect class="cls-29" x="175.52" y="158.97" width="134.28" height="64.92" rx="32.38"/><path class="cls-25" d="M277.41,166a25.42,25.42,0,0,1,25.39,25.39v.15a25.42,25.42,0,0,1-25.39,25.39H207.9a25.42,25.42,0,0,1-25.38-25.39v-.15A25.42,25.42,0,0,1,207.9,166h69.51m0-7H207.9a32.48,32.48,0,0,0-32.38,32.39v.15A32.48,32.48,0,0,0,207.9,223.9h69.51a32.48,32.48,0,0,0,32.39-32.39v-.15A32.48,32.48,0,0,0,277.41,159Z"/></g>', 
    '<g id="layer_8" data-name="layer 8"><path class="cls-33" d="M242.39,199a142.43,142.43,0,0,1-48.83-8.5v-8.7c1.46-.52,21.89-7.54,49.79-7.54a154.94,154.94,0,0,1,48.41,7.54v8.71C290.36,191.06,270.31,199,242.39,199Z" /><path class="cls-33" d="M243.35,174.37a154.79,154.79,0,0,1,48.29,7.5v8.53c-1.93.78-21.78,8.45-49.25,8.45a142.43,142.43,0,0,1-48.71-8.45v-8.53c2-.71,22.23-7.5,49.67-7.5h0m0-.25c-29.17,0-49.92,7.57-49.92,7.57v8.88a142.71,142.71,0,0,0,49,8.53c29.17,0,49.5-8.53,49.5-8.53v-8.88a155.22,155.22,0,0,0-48.54-7.57Z" /><line class="cls-26" x1="201.69" y1="186.61" x2="259.5" y2="186.61" /><line class="cls-27" x1="267.84" y1="186.61" x2="282.57" y2="186.61" /></g>',
    '<g id="layer_9" data-name="layer 9"><path class="cls-19" d="M195.67,192.08s8.14-.71,20,5.48c0,0,7.61,4.07,12-1.59,0,0,8.67-10.44,15-11.68,0,0,6.9.89,13.09,11a12.77,12.77,0,0,0,13.8,2.66s14-7.26,20.35-6.28l7.78,3.45s-5.3,44.94-19.81,59.62l-23.36,7.78-1.59,15h-20.7l-1.94-15.39-21.23-5.66s-14-5.66-21.94-60.86Z"/><path class="cls-34" d="M224.87,223.31l3.53.08,6.72,7.52h14.33l7.26-7.52h4.07V234l-8,22.29h-20l-7.78-23Z"/><path class="cls-19" d="M226.87,220s2.3-13.21,15.6-13c0,0,10.82-.36,14.83,13Z"/><rect class="cls-19" x="233.97" y="265.86" width="17.25" height="10.08" rx="5.04"/><ellipse class="cls-34" cx="265.22" cy="251.65" rx="4.45" ry="4.99"/><ellipse class="cls-34" cx="220.42" cy="251.65" rx="4.45" ry="4.99"/><rect class="cls-26" x="237.84" y="235.13" width="8.96" height="15.81" rx="4.14"/><ellipse class="cls-34" cx="292.59" cy="227.66" rx="24.5" ry="12.92" transform="translate(1.35 457.03) rotate(-76.11)"/><ellipse class="cls-19" cx="295.63" cy="228.41" rx="15.82" ry="8.34" transform="translate(2.93 460.55) rotate(-76.11)"/><ellipse class="cls-34" cx="296.98" cy="228.74" rx="11.45" ry="6.03" transform="translate(3.63 462.12) rotate(-76.11)"/><ellipse class="cls-34" cx="192.15" cy="227.66" rx="12.92" ry="24.5" transform="translate(-49.04 52.79) rotate(-13.89)"/><ellipse class="cls-19" cx="190.16" cy="228.15" rx="8.34" ry="15.82" transform="translate(-49.21 52.33) rotate(-13.89)"/><ellipse class="cls-34" cx="188.82" cy="228.48" rx="6.03" ry="11.45" transform="translate(-49.33 52.02) rotate(-13.89)"/><path class="cls-34" d="M233.47,198.68s8.85-9,17.93,0v3.66s-8.37-7.9-17.93,0Z"/><rect class="cls-34" x="235.42" y="267.74" width="14.21" height="1.24"/><rect class="cls-34" x="235.36" y="273.05" width="14.21" height="1.24"/><rect class="cls-34" x="235.36" y="270.4" width="14.21" height="1.24"/></g>'
  ];

  // arms:
  // - 0: no wires
  // - 1: wires on left arm
  // - 2: wires on right arm
  // - 3: wires on both arms
  string[] arms = [
    "",
    '<ellipse class="cls-23" cx="158.34" cy="359.35" rx="0.55" ry="0.54" /><polyline class="cls-22" points="145.39 373.85 145.39 395.87 153.06 403.35 153.06 415.29 145.39 422.97 145.39 461.67 148.39 464.91 148.01 478.23 143.21 482.07 143.21 491.67" /><circle class="cls-23" cx="145.39" cy="373.85" r="0.8" /><path class="cls-22" d="M142.25,473.09V458l-7.6-7.87v-30.7l7.6-7.34v-8l-7.6-8V366.29l5.51-.07,6.84-16-.09-10.76" /><circle class="cls-23" cx="147" cy="339.43" r="0.8" /><polyline class="cls-22" points="153.06 487.45 153.06 456.01 158.34 449.74 158.34 431.65 153.06 426.65 153.06 421.37 158.34 416.49 158.34 400.98 153.06 395.79 153.06 385.42 158.34 380.41 158.34 370.6 158.34 359.35" /><ellipse class="cls-23" cx="153.06" cy="487.45" rx="0.55" ry="0.54" /><ellipse class="cls-23" cx="143.21" cy="491.67" rx="0.55" ry="0.54" /><ellipse class="cls-23" cx="142.25" cy="473.09" rx="0.55" ry="0.54" />',
    '<ellipse class="cls-23" cx="351.25" cy="359.72" rx="0.55" ry="0.54" /><polyline class="cls-22" points="364.2 374.22 364.2 396.24 356.52 403.72 356.52 415.65 364.2 423.34 364.2 462.04 361.2 465.28 361.58 478.6 366.38 482.44 366.38 492.04" /><circle class="cls-23" cx="364.2" cy="374.22" r="0.8" /><path class="cls-22" d="M367.33,473.46V458.35l7.61-7.87v-30.7l-7.61-7.34v-8l7.61-8V366.66l-5.52-.07-6.84-16,.09-10.75" /><circle class="cls-23" cx="362.58" cy="339.81" r="0.8" /><polyline class="cls-22" points="356.52 487.82 356.52 456.38 351.25 450.11 351.25 432.02 356.52 427.02 356.52 421.74 351.25 416.86 351.25 401.35 356.52 396.16 356.52 385.79 351.25 380.78 351.25 370.98 351.25 359.72" /><ellipse class="cls-23" cx="356.53" cy="487.82" rx="0.55" ry="0.54" /><ellipse class="cls-23" cx="366.38" cy="492.04" rx="0.55" ry="0.54" /><ellipse class="cls-23" cx="367.28" cy="473.46" rx="0.55" ry="0.54" />',
    '<ellipse class="cls-23" cx="158.34" cy="359.35" rx="0.55" ry="0.54" /><polyline class="cls-22" points="145.39 373.85 145.39 395.87 153.06 403.35 153.06 415.29 145.39 422.97 145.39 461.67 148.39 464.91 148.01 478.23 143.21 482.07 143.21 491.67" /><circle class="cls-23" cx="145.39" cy="373.85" r="0.8" /><path class="cls-22" d="M142.25,473.09V458l-7.6-7.87v-30.7l7.6-7.34v-8l-7.6-8V366.29l5.51-.07,6.84-16-.09-10.76" /><circle class="cls-23" cx="147" cy="339.43" r="0.8" /><polyline class="cls-22" points="153.06 487.45 153.06 456.01 158.34 449.74 158.34 431.65 153.06 426.65 153.06 421.37 158.34 416.49 158.34 400.98 153.06 395.79 153.06 385.42 158.34 380.41 158.34 370.6 158.34 359.35" /><ellipse class="cls-23" cx="153.06" cy="487.45" rx="0.55" ry="0.54" /><ellipse class="cls-23" cx="143.21" cy="491.67" rx="0.55" ry="0.54" /><ellipse class="cls-23" cx="142.25" cy="473.09" rx="0.55" ry="0.54" /><ellipse class="cls-23" cx="351.25" cy="359.72" rx="0.55" ry="0.54" /><polyline class="cls-22" points="364.2 374.22 364.2 396.24 356.52 403.72 356.52 415.65 364.2 423.34 364.2 462.04 361.2 465.28 361.58 478.6 366.38 482.44 366.38 492.04" /><circle class="cls-23" cx="364.2" cy="374.22" r="0.8" /><path class="cls-22" d="M367.33,473.46V458.35l7.61-7.87v-30.7l-7.61-7.34v-8l7.61-8V366.66l-5.52-.07-6.84-16,.09-10.75" /><circle class="cls-23" cx="362.58" cy="339.81" r="0.8" /><polyline class="cls-22" points="356.52 487.82 356.52 456.38 351.25 450.11 351.25 432.02 356.52 427.02 356.52 421.74 351.25 416.86 351.25 401.35 356.52 396.16 356.52 385.79 351.25 380.78 351.25 370.98 351.25 359.72" /><ellipse class="cls-23" cx="356.53" cy="487.82" rx="0.55" ry="0.54" /><ellipse class="cls-23" cx="366.38" cy="492.04" rx="0.55" ry="0.54" /><ellipse class="cls-23" cx="367.28" cy="473.46" rx="0.55" ry="0.54" />'
  ];

  // lips:
  // - 0: normal
  // - 1: smile
  // - 2: surprise
  string[] lips = [
    '<path d="M225.19 235.74s4 9.93 14.72 9.45c0 0 11.35.91 16.2-9.18 0-.01-20.93-3.91-30.92-.27z" fill="url(#grad_42)" opacity=".63"/><path d="M240.4 231.39a7.34 7.34 0 00-9.67 0s-4.56 3.24-7.38 3.3a8.39 8.39 0 008 1.14 15.05 15.05 0 012.58-.48 15.4 15.4 0 012.74 0c2.34.16 2.75.47 4.27.59 2.26.19 2.63-.39 5.13-.47a17.51 17.51 0 015 .59s1.22.31 7.47-.23a28.09 28.09 0 01-7.83-3.6 7.87 7.87 0 00-10.31-.84z" class="cls-27"/><path class="cls-17" d="M242.34 238.8c0 .33.06.66.08 1a1.87 1.87 0 01-.08 1 2 2 0 01-.09-1l.09-1zM233.25 237.45c-.09.39-.18.77-.28 1.16a2.59 2.59 0 01-.44 1.09 2.72 2.72 0 01.28-1.16c.14-.36.29-.73.44-1.09zM236.62 238.17q.06.45.09.9a1.56 1.56 0 01-.09.9 1.56 1.56 0 01-.09-.9q0-.45.09-.9zM247.15 238.17c.14.28.27.57.4.87a1.72 1.72 0 01.23.93 1.7 1.7 0 01-.4-.87c-.08-.3-.16-.61-.23-.93zM250.3 237.45c.13.21.26.42.37.64a1 1 0 01.22.71 1.11 1.11 0 01-.37-.64c-.08-.24-.15-.47-.21-.71z"/><path class="cls-18" d="M241.11 233.99l-.12-1.98h.25l-.13 1.98zM232.02 235.34l-.84-2.22.24-.07.6 2.29zM235.4 234.62l-.13-1.8h.25l-.12 1.8zM245.93 234.62l.51-1.85.23.09-.74 1.76zM249.07 235.34l.47-1.4.23.09-.7 1.31z"/>',
    '<path class="cls-24" d="M224.16,233.24a20.79,20.79,0,0,0,4.14,6.95,15.71,15.71,0,0,0,3.06,2.72,16.06,16.06,0,0,0,8.21,2.64,18.25,18.25,0,0,0,5.67-.54,13.05,13.05,0,0,0,4.19-1.64,12.89,12.89,0,0,0,2.75-2.47,17.13,17.13,0,0,0,3.57-7.87Z"/><path class="cls-35" d="M228.64,234.8s7.42,5,14.79,3.8c0,0,4.43-.11,9.38-4.95C252.81,233.65,230.59,233.28,228.64,234.8Z"/><path class="cls-17" d="M241.34,240.21c0,.31.06.62.08.94a1.69,1.69,0,0,1-.08.94h0a1.79,1.79,0,0,1-.09-.94l.09-.94Z"/><path class="cls-17" d="M232.69,238.93c-.08.36-.16.73-.26,1.09a2.33,2.33,0,0,1-.42,1h0a2.28,2.28,0,0,1,.25-1.1c.14-.35.28-.7.43-1Z"/><path class="cls-17" d="M235.9,239.61c0,.28.07.57.09.85a1.43,1.43,0,0,1-.09.86h0a1.43,1.43,0,0,1-.09-.86c0-.28.05-.57.09-.85Z"/><path class="cls-17" d="M245.91,239.6c.14.28.26.55.39.83a1.57,1.57,0,0,1,.21.88h0a1.48,1.48,0,0,1-.38-.82c-.08-.3-.15-.59-.22-.89Z"/><path class="cls-17" d="M248.91,238.92l.36.61a1,1,0,0,1,.19.67h0a1,1,0,0,1-.36-.61c-.07-.22-.14-.44-.2-.67Z"/><path class="cls-27" d="M240,230.93c-.7-.24-.83-.34-1.31-.47a5.86,5.86,0,0,0-1.56-.17,15.1,15.1,0,0,0-4.46,1c-.38.16-1.15.51-2.31.9-.05,0-1.09.37-1.88.56a14,14,0,0,1-4.87.25,8.19,8.19,0,0,0,2,1.46,13.13,13.13,0,0,0,5.74.82,22.45,22.45,0,0,1,2.38-.25,15.35,15.35,0,0,1,2,.08c1.66.16,2.36.57,3.86.74a8.85,8.85,0,0,0,4.28-.29,14.79,14.79,0,0,1,2.75-.92,9.39,9.39,0,0,1,1.2-.18c1.57-.13,1.89.33,3.66.33a9.26,9.26,0,0,0,1.93-.19,7.35,7.35,0,0,0,1.1-.3,7.12,7.12,0,0,0,2.34-1.39,11.26,11.26,0,0,1-2.62-.26c-1.26-.29-1.61-.7-4.63-1.78a11.46,11.46,0,0,0-2.49-.73,5.32,5.32,0,0,0-2.33.17c-.63.19-.76.38-1.76.7a4.21,4.21,0,0,1-1.37.31A6,6,0,0,1,240,230.93Z"/><polygon class="cls-36" points="241.64 233.42 241.46 231.83 241.71 231.82 241.64 233.42"/><polygon class="cls-36" points="234.38 234.73 233.63 232.98 233.86 232.9 234.38 234.73"/><polygon class="cls-36" points="237.07 234.06 236.9 232.62 237.15 232.62 237.07 234.06"/><polygon class="cls-36" points="245.52 233.8 245.86 232.3 246.1 232.38 245.52 233.8"/><polygon class="cls-36" points="248.07 234.3 248.38 233.16 248.62 233.25 248.07 234.3"/>',
    '<path class="cls-28" d="M226.57,239.38c.89,1.67,3.93,6.89,9,8.39a18.74,18.74,0,0,0,3.09.57,16.06,16.06,0,0,0,7.39-.8,14.39,14.39,0,0,0,3.73-2,14.18,14.18,0,0,0,4.5-6.12S240.74,231.18,226.57,239.38Z"/><path class="cls-31" d="M235.19,238.38a7.26,7.26,0,0,0,1.53,1.34,7.46,7.46,0,0,0,4.24,1.16,5.49,5.49,0,0,0,2.3-.46,5.58,5.58,0,0,0,2.52-2.16S241.62,234.62,235.19,238.38Z"/><path class="cls-27" d="M240.65,230.52a10,10,0,0,0-7.07-.11,12.35,12.35,0,0,0-5.4,5c-.09.15-.39.68-.84,1.41-.65,1-1.23,1.86-1.63,2.4,0,0,1.22.13,2.92.13a16.32,16.32,0,0,0,5-.42c.2-.07.82-.27,1.58-.58s1.31-.59,1.48-.67a10.07,10.07,0,0,1,4-.82,8.84,8.84,0,0,1,1.58.08,9.12,9.12,0,0,1,3.52,1.29,13.22,13.22,0,0,0,1.93.59,35.62,35.62,0,0,0,7.39.53s-.35-.63-.75-1.42-.44-1-.78-1.76c0,0-.36-.79-.77-1.58a9.84,9.84,0,0,0-5.88-4.77A9.33,9.33,0,0,0,240.65,230.52Z"/><path class="cls-17" d="M240.87,242.23l.09,1a2,2,0,0,1-.09,1h0a1.87,1.87,0,0,1-.08-1c0-.33.05-.66.08-1Z"/><path class="cls-17" d="M231.78,240.89c-.09.38-.18.77-.28,1.15a2.68,2.68,0,0,1-.44,1.1h0a2.67,2.67,0,0,1,.28-1.15c.14-.37.29-.74.44-1.1Z"/><path class="cls-17" d="M235.15,241.6q.06.45.09.9a1.56,1.56,0,0,1-.09.9h0a1.56,1.56,0,0,1-.09-.9q0-.45.09-.9Z"/><path class="cls-17" d="M245.68,241.6c.14.29.27.58.4.87a1.76,1.76,0,0,1,.23.93h0a1.78,1.78,0,0,1-.4-.87c-.08-.31-.16-.62-.23-.93Z"/><path class="cls-17" d="M248.83,240.88c.13.21.26.42.37.64a1,1,0,0,1,.22.71h0a1.14,1.14,0,0,1-.37-.64c-.08-.23-.15-.47-.21-.71Z"/><polygon class="cls-30" points="241.49 235.33 241.36 233.35 241.61 233.35 241.49 235.33"/><polygon class="cls-30" points="232.4 236.68 231.56 234.47 231.79 234.4 232.4 236.68"/><polygon class="cls-30" points="235.77 235.96 235.65 234.16 235.9 234.16 235.77 235.96"/><polygon class="cls-30" points="246.3 235.96 246.81 234.12 247.05 234.2 246.3 235.96"/><polygon class="cls-30" points="249.45 236.68 249.92 235.28 250.15 235.38 249.45 236.68"/>'
  ];

  function stringToUint8(string memory _numString) internal pure returns(uint8) {
    return uint8(bytes(_numString)[0]) - 48;
  }

  function getSlice(uint256 _begin, uint256 _end, string memory _text) internal pure returns (string memory) {
    bytes memory a = new bytes(_end - _begin + 1);

    for (uint i = 0 ; i <= (_end - _begin); i++) {
        a[i] = bytes(_text)[i + _begin - 1];
    }
    
    return string(a);
  }

  function getMetadata(
    string calldata _fullDomainName, 
    uint256 _tokenId
  ) external view returns(string memory) {
    string memory features = idToUniqueFeatures[_tokenId];
    uint256 domainLength = strings.len(strings.toSlice(_fullDomainName)) - 10; // 10 is length of .punkangel

    return string(
      abi.encodePacked("data:application/json;base64,",Base64.encode(bytes(abi.encodePacked(
        '{"name": "', _fullDomainName ,'", ',
        '"paid": "', Strings.toString(pricePaid[_tokenId]) ,'", ',
        '"attributes": [{"trait_type": "length", "value": "', Strings.toString(domainLength) ,'"}, ', _getTraits(features) ,'], ',
        '"description": "A collection of Punk Angel NFTs created by Punk Domains: https://punk.domains/#/nft/angel", ',
        '"image": "', _getImage(features, _fullDomainName), '"}'))))
    );
  }

  function _getImagePart1(string memory _features) internal pure returns (string memory) {
    string memory bg1 = getSlice(1, 6, _features);
    string memory bg2 = getSlice(7, 12, _features);
    string memory hair = getSlice(13, 18, _features);
    string memory skin = getSlice(19, 24, _features);

    return string(abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" width="500" height="500"><defs><linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="0%"><stop offset="0%" stop-color="#',bg1,'"/><stop offset="100%" stop-color="#',bg2,'"/></linearGradient><linearGradient id="grad_42" x1="240.65" y1="245.21" x2="240.65" y2="234.19" gradientUnits="userSpaceOnUse"><stop offset=".41" stop-color="#460c68"/><stop offset=".6" stop-color="#531a6f"/><stop offset=".89" stop-color="#d55d68"/></linearGradient><linearGradient id="grad_49" x1="175.52" y1="191.43" x2="309.8" y2="191.43" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#dcd836"/><stop offset="1" stop-color="#702a86"/></linearGradient><linearGradient id="grad9" x1="239.95" y1="245.59" x2="239.95" y2="233.03" gradientUnits="userSpaceOnUse"><stop offset="0.16" stop-color="#460c68"/><stop offset="0.38" stop-color="#531a6f"/><stop offset="0.66" stop-color="#d55d68"/></linearGradient><linearGradient id="grad2" x1="240.43" y1="248.46" x2="240.43" y2="235.74" gradientUnits="userSpaceOnUse"><stop offset="0.28" stop-color="#460c68"/><stop offset="0.53" stop-color="#531a6f"/><stop offset="0.77" stop-color="#d55d68"/></linearGradient><linearGradient id="grad5" x1="193.56" y1="186.61" x2="291.76" y2="186.61" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#570d7b"/><stop offset="0.46" stop-color="#fac9c5"/><stop offset="0.75" stop-color="#52befb"/></linearGradient><style>.cls-4{fill:#030713;opacity:.58}.cls-13,.cls-14,.cls-21,.cls-22,.cls-6{fill:none}.cls-13,.cls-22,.cls-23,.cls-6{stroke:#ffe7da}.cls-13,.cls-14,.cls-21,.cls-22,.cls-23,.cls-6{stroke-miterlimit:10}.cls-8{fill:#',hair,'}.cls-9{fill:#',skin,'}.cls-12{fill:#5b107f}.cls-11{fill:#',skin,'}.cls-13,.cls-22,.cls-23{opacity:.21}.cls-13,.cls-21,.cls-22,.cls-23{stroke-linecap:round}.cls-14{stroke:#1d1d1b}.cls-17{fill:#ff797c}.cls-18,.cls-23{fill:#ac546b}.cls-19{fill:#0c182c}.cls-20{fill:#1d1d1b}.cls-21{stroke:#f37ead}.cls-22,.cls-23{stroke-width:.9px}.cls-24{fill:url(#grad9);}.cls-25{fill:url(#grad_49);}.cls-27{fill:#460c68;}.cls-28{fill:url(#grad2);opacity:0.63;}.cls-29{fill:#151737;}.cls-30{fill:#ac546b}.cls-31{stroke-linecap:round;stroke-width:0.5px;stroke-miterlimit:10;}.cls-33{fill:url(#grad5);}.cls-34{fill:#ADACA8;}.cls-35{fill:#d2c8db;}.cls-36{fill:#ac546b;}'));
  }

  function _getImagePart2(
    string memory _features,
    string memory _fullDomainName
  ) internal view returns (string memory) {
    string memory dress = getSlice(25, 30, _features);
    string memory faceIndexStr = getSlice(31, 31, _features);
    string memory armsIndexStr = getSlice(32, 32, _features);
    string memory lipsIndexStr = getSlice(33, 33, _features);

    return string(abi.encodePacked(
      '.cls-32{fill:#',dress,'}</style></defs><path fill="url(#grad)" d="M0 0h500v500H0z"/><g id="layer_4" data-name="layer 4"><path class="cls-4" d="M285.74 301.62a59 59 0 0121.46-20c22.32-12 44.85-4.75 49.22-3.25 0 0 49.65 5.75 89.49-37.46 0 0 39.53 11.64 11.95 55.77 0 0 21.45 18.39-22.68 41.07 3.35 2.8 4.59 5.44 4.89 7.71 2.37 18.26-53.17 37.84-57.21 39.24q-48.55-41.53-97.12-83.08zM214.06 301.45a59 59 0 00-21.45-20c-22.32-12-44.85-4.75-49.23-3.25 0 0-49.64 5.75-89.48-37.46 0 0-39.53 11.65-11.95 55.78 0 0-21.46 18.38 22.67 41.06-3.4 2.81-4.64 5.44-4.88 7.71-1.9 17.59 53.25 35.79 60.41 38.1z"/><g opacity=".21"><path class="cls-6" d="M181.87 345.81l-24.61-14.95-18.29-.04-12.06-7.32-8.03-15.95-67.54-41.03M158.29 384.64l-18.89-11.47-13 2.87-19.3-11.73-3.09-12.64-17.69-10.75"/><path class="cls-6" d="M162.85 377.13l-26.75-16.25-12.25 2.84-7.86-4.78-3.49-12.39-22.87-13.89-12.25 2.84-15.55-9.45-3.12-12.17-14.48-8.8"/><path class="cls-6" d="M165.34 373.02l-30.5-18.53-13 2.87-19.12-11.61L99.45 333l-33.78-20.52M167.73 369.09l-7.62-4.64-3.2-12.46-19.3-11.72-12.53 2.91-45.04-27.36"/><path class="cls-6" d="M172.4 361.4l-6.45 1.34-31.81-19.32-4.48-13.85-22.39-13.6-13.93 2.67-39.97-24.28"/><path class="cls-6" d="M179.46 349.78l-7.63-4.63-12.68 3.55-19.3-11.72-2.87-13-19.48-11.83-12.68 3.55-26.27-15.95"/><circle class="cls-6" cx="85.85" cy="340.64" r=".94"/><circle class="cls-6" cx="65.67" cy="312.48" r=".94"/><circle class="cls-6" cx="44.23" cy="305.08" r=".94"/><circle class="cls-6" cx="79.61" cy="315.62" r=".94"/><ellipse class="cls-6" cx="53.37" cy="294.36" rx=".94" ry="1.1" transform="rotate(-58.73 53.35 294.347)"/><circle class="cls-6" cx="78.54" cy="299.75" r=".94"/><path class="cls-6" d="M184.15 342.05l-26.91-16.34-2.73-12.3-7.85-4.77-11.98 3.36-23.08-14.01-3-12.47-15.43-9.37-12.18 3.24-14.59-8.86M188.87 334.28l-10.78-6.55-.98-11.06-21.91-13.3-9.88 4.45-5.72-3.47-1.07-11.11-21.25-12.9"/><path class="cls-6" d="M189.36 333.47l-1.26-4.89-36.99-22.47-12.02 3.25-11.41-6.93-2.46-12.05-21.05-12.78M195.79 322.88l-13.54-8.23-.74-11.45-13.81-8.39-10.41 4.69-12.64-7.68"/><ellipse class="cls-6" cx="104.17" cy="277.6" rx=".94" ry=".9" transform="rotate(-58.73 104.152 277.584)"/><ellipse class="cls-6" cx="144.65" cy="291.82" rx=".94" ry=".67" transform="rotate(-58.73 144.632 291.808)"/><ellipse class="cls-6" cx="117.41" cy="280.41" rx=".94" ry=".67" transform="rotate(-58.73 117.39 280.4)"/><ellipse class="cls-6" cx="66.4" cy="270.53" rx=".94" ry=".93" transform="rotate(-58.73 66.386 270.514)"/><circle class="cls-6" cx="51.34" cy="266.52" r=".94"/><path class="cls-6" d="M321.1 349.25l24.61-14.95 18.29-.04 12.06-7.32 8.02-15.95 67.55-41.02M344.68 388.08l18.89-11.47 12.99 2.87 19.31-11.73 3.08-12.64 17.7-10.74"/><path class="cls-6" d="M340.12 380.57l26.75-16.25 12.25 2.84 7.86-4.77 3.48-12.39 22.88-13.9 12.24 2.84 15.55-9.45 3.13-12.17 14.48-8.79"/><path class="cls-6" d="M337.62 376.46l30.51-18.52 13 2.87 19.12-11.62 3.27-12.75 33.78-20.52M335.24 372.53l7.62-4.63 3.2-12.46 19.3-11.73 12.53 2.91 45.04-27.36"/><path class="cls-6" d="M330.57 364.84l6.45 1.35 31.81-19.32 4.47-13.86 22.39-13.59 13.94 2.66 39.97-24.27"/><path class="cls-6" d="M323.51 353.23l7.63-4.63 12.68 3.55 19.3-11.73 2.87-12.99 19.48-11.84 12.68 3.56 26.27-15.96"/><circle class="cls-6" cx="417.12" cy="344.08" r=".94"/><circle class="cls-6" cx="437.3" cy="315.92" r=".94"/><circle class="cls-6" cx="458.74" cy="308.53" r=".94"/><circle class="cls-6" cx="423.36" cy="319.06" r=".94"/><ellipse class="cls-6" cx="449.6" cy="297.8" rx="1.1" ry=".94" transform="rotate(-31.27 449.66 297.823)"/><circle class="cls-6" cx="424.42" cy="303.19" r=".94"/><path class="cls-6" d="M318.82 345.5l26.91-16.35 2.73-12.3 7.85-4.77 11.98 3.37 23.08-14.02 3-12.46 15.43-9.38 12.18 3.25 14.59-8.87"/><path class="cls-6" d="M314.09 337.72l10.79-6.55.98-11.05 21.91-13.31 9.88 4.46 5.72-3.47 1.07-11.12 21.24-12.9"/><path class="cls-6" d="M313.61 336.92l1.25-4.9 37-22.46 12.02 3.25 11.41-6.93 2.46-12.05 21.05-12.78M307.17 326.33l13.55-8.23.74-11.46 13.81-8.39 10.41 4.69 12.64-7.68"/><ellipse class="cls-6" cx="398.8" cy="281.04" rx=".9" ry=".94" transform="rotate(-31.27 398.866 281.065)"/><ellipse class="cls-6" cx="358.32" cy="295.26" rx=".67" ry=".94" transform="rotate(-31.27 358.38 295.28)"/><ellipse class="cls-6" cx="385.56" cy="283.86" rx=".67" ry=".94" transform="rotate(-31.27 385.612 283.887)"/><ellipse class="cls-6" cx="436.57" cy="273.97" rx=".93" ry=".94" transform="rotate(-31.27 436.64 273.99)"/><circle class="cls-6" cx="451.63" cy="269.97" r=".94"/></g><ellipse cx="271.16" cy="75.45" rx="14.16" ry="30.31" transform="rotate(-75 270.282 75.025)" stroke-miterlimit="10" opacity=".21" stroke-width="1.5" stroke="#ffe7da" fill="none"/></g><path class="cls-8" d="M249.12 99.48s-4-9.09-15.66-7.2c0 0 7.38 1.26 11 6.21 0 0-11.79-6.84-17.91-3.6 0 0 4.32-.36 6.3 2.16 0 0-12-1.08-14.13 1 0 0 2.52.72 2.61 1.44 0 0-8.19-.18-10.35 3.69h3s-6.36 3.12-8.7 7.62a11 11 0 00-8.88 3.6s-11.1 2.88-28.08-.9a20.67 20.67 0 0011.22 5 10 10 0 01-5.28.54s8.94 5 15.9 4.8a26.83 26.83 0 01-6.9 2.76 13.44 13.44 0 006.12.6s-18.54 14.76-19.5 24.33c0 0 2.58-3.15 4.92-3.63 0 0-10.32 12.36-9.36 21.36 0 0 6.54-13.08 11.46-14.16 0 0-9.54 23.34-1.26 46a12.22 12.22 0 011.53-5.94s1.17 18.09 5.85 22.59a31.38 31.38 0 001.53-9.36s3.21 16.41-10.11 37.41c0 0 11.16-11.28 12.48-16.08 0 0-4.8 18.6-8.52 23 0 0 13.44-13.92 15.12-19.8 0 0 0 7.44-1.68 11.64 0 0 6.12-4.08 6-5.76 0 0 .72 5.52-5.28 11.76 0 0-11 8-8.52 24.72 0 0 3.6-10.92 7.08-13 0 0-5.4 14.52 1.32 25.8 0 0-1-16.32 4.56-23.88 0 0 .24 15.72 7.32 21.36 0 0 3.6-12.6 5.4-13.56 0 0 .48 13.32 2.4 16.92 0 0 7.92-15.24 15.36-16.8l46.08-16.38s9.18 2.16 15.66 38.7c0 0 7.2-6.48 7-26.82 0 0 2.35 14.22 0 19.08 0 0 5.4-4 3.24-20.52 0 0 4.14 8.28 7.56 10.08 0 0-4.14-9.54-2.52-15.66 0 0 5.4 10.08 10.26 11.16 0 0-16.74-25.2-13.38-47.76 0 0 20.16 26.88 25.68 27.12 0 0-13.92-14.16-15.12-24.72 0 0 11.76 16.08 19.68 16.8 0 0-20.64-13.68-18-25 0 0 .24-16.25-1-25l2.19 2.33s-.27-14.31-3.87-19.71a26.9 26.9 0 016.73 10.3 42.11 42.11 0 00-1.36-7.84 43.2 43.2 0 00-8.6-16.28s7 1.08 13.5 12.78c0 0-2.34-14.94-18.54-29.88 0 0 4-.18 7.74 4.32 0 0-.36-7-8.1-13.86 0 0 8.64 3.78 11.16 8.64 0 0-2.52-13.5-27.54-29.34 0 0 12.24 2.7 19.8 12.06 0 0-6.12-16.74-35.82-20.88 0 0 12.78-7.74 26.82-5.76 0 0-11-6.84-33.3 4.5 0 0-4.32-3.51-7.92-3.6 0 0 5.64-1.71 8.37.18 0 .03-4.68-6.54-14.76-1.68z" id="layer_2" data-name="layer 2"/><g id="layer_3" data-name="layer 3"><path class="cls-9" d="M219.51 251.85s7.74 22.68 2.7 42.66c0 0 25.56 10.62 55.8-1.26 0 0-7.2-27.18-3.24-49.68z"/><path d="M219.73 253.45s25.58 9.32 54.7-7.73q-.37 3.32-.57 6.89a121.92 121.92 0 00.27 17.28 60.85 60.85 0 01-20.21 1.33c-5.79-.6-17.18-1.93-27.24-10.34a41.72 41.72 0 01-6.95-7.43z" opacity=".63" fill="#5b107f"/><path class="cls-11" d="M194.22 188.58a4.21 4.21 0 00-4.5 4s-.63 10.53 5.85 30.42c0 0 1.17 3.51 6.12 2.75zM291.25 187.54a4.2 4.2 0 014.69 3.82s1.14 10.49-4.36 30.67c0 0-1 3.56-6 3z"/><path class="cls-9" d="M195.13 153.13L194 162q-.28 5.33-.42 10.9c-.13 5.48-.13 10.79 0 15.92 0 0 2.79 36.18 13.77 51.3 0 0 16.47 22.86 32.49 22.14a53.06 53.06 0 008.11-1 44.21 44.21 0 0013.06-4.63 46 46 0 007.77-5.69 96.59 96.59 0 0010.93-10.79 43.9 43.9 0 002.82-4.33 47.18 47.18 0 004.62-11.27s5.16-25.8 4.8-46.32c0 0-.72-16.2-2-20.16l-6.3-32.4-87.12 6.84a37.27 37.27 0 00-1.34 20.62z"/><path class="cls-12" d="M252.44 170.43v6.36s23-2.88 29.4-9.36c0 0-23.84 3.36-29.4 3z"/><path class="cls-13" d="M252.8 158.28l1.09 17.43h3.6v5.32h8.71v.75"/><path class="cls-8" d="M193.14 138.36a19 19 0 002.22 18.57l7 .24 2.79-11.74-1.66 12h2.38l1.94-11.43-.63 11.74h1.35l3.37-11.11-1.75 11.37h1.75l2.93-12.78-1.26 12.55 2.16-.09s4-22.32 7.14-26c0 0-6.12 25.23-4 26.36l3.48.22s.72-15.12 4-17.82l-2.07 17.82h2.43s.09-13.68 5.22-22.95l-2.88 23.58h4.68s1.53-15 3.24-18.9c0 0 3.24 12.6.81 18.9h6.12s.9-18.09 3.87-23.13l.69 22.59 7-.09s1.73-16.39 3.54-20.26l1.56 20.85h3.12s.48-8.49 1.8-10.89l2.52 10.92v-15.21l4.32 14.4 8.64-.84-1.56-8.52 4 10.17 3-.69-1.44-8 3.24 7.32h2.4l-.6-34.2-95.28 4.92z"/><path class="cls-12" d="M228.52 170.43v6.36s-23-2.88-29.4-9.36c0 0 23.88 3.36 29.4 3z"/><path class="cls-14" d="M229.68 211.49a16.08 16.08 0 01-1.26 2.61c-.5.63-1.08 5 1.71 6.07a1.91 1.91 0 00.78-.14 3.35 3.35 0 001-.79 3.35 3.35 0 011.39-.89 2.1 2.1 0 011.73.63l2.25 2.77a5.88 5.88 0 00.93.67 3.76 3.76 0 001.17.47 3.43 3.43 0 001.68 0 3.47 3.47 0 001.7-1.05s3.36-3.36 4.68-3.21a1 1 0 01.9.53s1.14 1.45 2.11 1.35a3.3 3.3 0 002.13-2.31 12.58 12.58 0 00.14-3.38 12.79 12.79 0 00-.69-3.12"/><path class="cls-19" d="M215.32 182.1s-4.06 6.24 2.38 9.15l3.56.18a7.17 7.17 0 003.58-5.83s-4.03-4.09-9.52-3.5z"/><path class="cls-14" d="M206 186s5 7.46 22 4.88c0 0 .43-.29.09-1 0 0-6.42-14.58-24.06-4"/><path class="cls-20" d="M227.94 187.43a17.42 17.42 0 00-10.57-6 19.42 19.42 0 00-6.22.33c-1 .2-2 .56-3 .83l-2.93 1.18v-.06l2.89-1.33c1-.32 2-.73 3-1a19.7 19.7 0 016.36-.57 14.3 14.3 0 016.12 2 12.65 12.65 0 014.45 4.57z"/><path class="cls-13" d="M268.82 191.55l.82 3.87 9.21-1.09 2.55 6.07 9.73-4.58"/><path class="cls-19" d="M272.14 183.83s2 7.18-5 8l-3.11-.08a9.19 9.19 0 01-1.6-2.73 9.06 9.06 0 01-.4-4.72s5.05-2.67 10.11-.47z"/><path class="cls-14" d="M278.35 187.28s-5.45 7.13-22.26 3.48c0 0-.41-.32 0-1 0 0 7.33-14.14 24.26-2.42"/><path class="cls-20" d="M256.31 187.27a12.61 12.61 0 014.74-4.28 14.25 14.25 0 016.23-1.59 19.8 19.8 0 016.31 1c1 .32 2 .79 3 1.18l2.8 1.5v.07l-2.85-1.37c-1-.33-2-.75-3-1a19.25 19.25 0 00-6.17-.72 16.81 16.81 0 00-5.92 1.65 16.58 16.58 0 00-5 3.66z"/><circle class="cls-8" cx="267.14" cy="186.85" r="1.59"/><path class="cls-9" d="M225.19 293.19a58.23 58.23 0 00-17.68 10.32c-1.95 1-5 2.52-8.88 4.23-25.8 11.47-35.06 8.49-53.16 18.33-7.88 4.28-16.35 9-21.9 18.89-3.63 6.46-4.64 12.66-5.25 22a238.31 238.31 0 002.07 49.62s8.4 50.64 6.24 62.16c0 0-.72 11.44 2.4 21.08h250.32s-.09-17.12-.14-37c0-14.19-1.37-31.18.07-47.25.48-5.4 1.15-11.55 1.15-11.55 1.14-10.36 2.23-17.78 2.43-19.27 1-7.62 1-20.33-3.51-42.71 0 0-4.14-16.2-23.94-20 0 0-34.74-6.3-52.56-14.58 0 0-26.82-14-26.82-16.38z"/><path d="M153.81 322.13s17.7 30.12 14.34 73.31-10.32 60.15 5.76 104.35h165.6s20.64-42-5.76-110.12c0 0-7.93-35.57 7.31-70.59 0 0-30.95-4.17-63.05-25.83 0 0-25.93 11.93-55.8 1.26l-5.82 2.79c-11.1 5.3-21.17 10-23.88 11.25-6.51 2.98-18.36 7.81-38.7 13.58z" class="cls-32"/><path class="cls-21" d="M229.59 325.35s19.92-12 43-1.44M222.87 335.43s27.12-13.2 58.32 0M222.87 348.39s30.72-13 57.12-1M215.67 362.07s38.21-14.18 77.28 0"/><path class="cls-9" d="M178.11 397.29l3.6 6.66S208 393.51 237 404l2.16-6.66s-28.29-14.09-61.05-.05zM264.37 397.29L268 404s26.28-10.44 55.26 0l2.16-6.66s-28.29-14.09-61.05-.05z"/></g><g id="layer_5" data-name="layer 5"><path class="cls-22" d="M271.93 247.65l1.21-1.31v-15.67l-3.1-3.11v-4.83l3.1-3.02v-8.92"/><circle class="cls-23" cx="273.15" cy="210.79" r=".32"/><path class="cls-22" d="M260.61 297.82l1.22-1.3v-15.67l-3.11-3.11v-4.83l3.11-3.03v-8.91"/><circle class="cls-23" cx="261.83" cy="260.97" r=".32"/><path class="cls-22" d="M280.95 237.73v-7.68l3.24-3.19v-7.83l-3.24-3.14v-7.17"/><circle class="cls-23" cx="280.95" cy="208.72" r=".32"/><path class="cls-22" d="M269.38 296.07v-7.68l3.25-3.19v-7.83l-3.25-3.14v-7.17"/><circle class="cls-23" cx="269.39" cy="267.06" r=".32"/><path class="cls-22" d="M274.93 244.73v-6.12l3.08-3.19V223l-3.08-2.97v-3.25l3.08-3.24V201.5"/><circle class="cls-23" cx="278.01" cy="201.57" r=".32"/><path class="cls-22" d="M265.99 252.87v-7.32l2.13-2.03v-2.13l-2.13-1.98v-6.28l2.13-2.1v-4.19l-2.13-2.03v-3.97"/><circle class="cls-23" cx="265.99" cy="220.84" r=".22"/><path class="cls-22" d="M251.38 298.81v-4.73l1.36-1.31v-1.39l-1.36-1.27v-4.06l1.36-1.36v-2.72l-1.36-1.31v-2.57"/><circle class="cls-23" cx="251.38" cy="278.09" r=".14"/>',
      arms[stringToUint8(armsIndexStr)],
      '</g>',
      lips[stringToUint8(lipsIndexStr)],
      face[stringToUint8(faceIndexStr)],
      '<text x="50%" y="6%" font-family="monospace" dominant-baseline="middle" fill="#ffffff" text-anchor="middle" font-size="1.8em">',
      _fullDomainName,
      '</text>',
      '</svg>')
    );
  }

  function _getImage(
    string memory _features,
    string memory _fullDomainName
  ) internal view returns (string memory) {
    string memory svgBase64Encoded = Base64.encode(bytes(string(abi.encodePacked(
      _getImagePart1(_features),
      _getImagePart2(_features, _fullDomainName)
    ))));

    return string(abi.encodePacked("data:image/svg+xml;base64,", svgBase64Encoded));
  }

  function _getTraits(string memory _features) internal pure returns (string memory) {
    string memory faceIndexStr = getSlice(31, 31, _features);
    string memory lipsIndexStr = getSlice(33, 33, _features);

    string memory faceItem = "None";
    if (stringToUint8(faceIndexStr) == 1) {
      faceItem = "Big VR glasses";
    } else if (stringToUint8(faceIndexStr) == 2) {
      faceItem = "Thin VR glasses";
    } else if (stringToUint8(faceIndexStr) == 3) {
      faceItem = "Gas mask";
    }

    string memory expression = "Serious";
    if (stringToUint8(lipsIndexStr) == 1) {
      expression = "Smile";
    } else if (stringToUint8(lipsIndexStr) == 2) {
      expression = "Surprise";
    }

    return string(abi.encodePacked(
      '{"trait_type": "hair color", "value": "#', getSlice(13, 18, _features) ,'"}, ',
      '{"trait_type": "dress color", "value": "#', getSlice(25, 30, _features) ,'"}, ',
      '{"trait_type": "skin color", "value": "#', getSlice(19, 24, _features) ,'"}, ',
      '{"trait_type": "face item", "value": "', faceItem ,'"}, ',
      '{"trait_type": "expression", "value": "', expression ,'"}'
    ));
  }

  // WRITE (MINTER)
  
  // Each domain has a unique features ID. Example: 3A1174741911F257FFCA965A000000231.
  // First 5 entries in the ID are colors, the last 3 digits are indices for face items, arm wires, and lips expressions
  function setUniqueFeaturesId(
    uint256 _tokenId, 
    string[] calldata _unqs, 
    uint256 _price
  ) external returns(string memory selectedFeatureId) {
    require(msg.sender == minter, "Only minter can set unique features ID.");

    pricePaid[_tokenId] = _price;

    uint256 length = _unqs.length;
    
    for (uint256 i = 0; i < length;) {
      string calldata _unq = _unqs[i];
      
      if (uniqueFeaturesId[_unq] == 0) {
        if (bytes(_unq).length == 33) {
          // check the last three digits in _unq (if in correct range)
          string memory faceIndexStr = getSlice(31, 31, _unq);
          string memory armsIndexStr = getSlice(32, 32, _unq);
          string memory lipsIndexStr = getSlice(33, 33, _unq);

          if (
            stringToUint8(faceIndexStr) <= 3 && 
            stringToUint8(armsIndexStr) <= 3 && 
            stringToUint8(lipsIndexStr) <= 2
          ) {
            uniqueFeaturesId[_unq] = _tokenId;
            idToUniqueFeatures[_tokenId] = _unq;
            return _unq;
          }
        }
      }

      unchecked { ++i; }
    }

    revert("Feature IDs already used");

  }

  function changeMinter(address _newMinter) external onlyOwner {
    minter = _newMinter;
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