/**
 *Submitted for verification at Arbiscan on 2023-06-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.4;

interface nftContract {
    function ownerOf(uint256 tokenId) external view returns(address);
    function tokenURI(uint256 tokenId) external view returns(string memory);
    function name() external view returns(string memory);
}

contract Arbitrum_Wildcard_Registry {


function compare(string memory _a, string memory _b) internal pure returns(int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;

        for (uint i = 0; i < minLength; i++)
        if (a[i] < b[i]) return -1;
        else if (a[i] > b[i]) return 1;
        if (a.length < b.length) return -1;
        else if (a.length > b.length) return 1;
        else
            return 0;
    }

function equals(string memory _a, string memory _b) internal pure returns(bool) {
        return compare(_a, _b) == 0;
    }

function addressToBytes(address a) internal pure returns(bytes memory b) {
        b = new bytes(20);
        assembly {
            mstore(add(b, 32), mul(a, exp(256, 12)))
        }
    }

function toUint(string memory input) internal pure returns(uint256) {
        bytes memory inputBytes = bytes(input);
        uint256 result = 0;
        for (uint8 i = 0; i < inputBytes.length; i++) {
            uint8 digit = uint8(inputBytes[i]) - 48; 
            require(digit >= 0 && digit <= 9, "Subdomain must be a valid NFT token ID");
            result = result * 10 + digit;
        }
        return result;
    }

function toString(address _addr) public pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_addr)));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint8(uint8(value[i + 12] >> 4))];
            str[3+i*2] = alphabet[uint8(uint8(value[i + 12]) & 0xf)];
        }
        return string(str);
    }

function decodeName(bytes memory input) internal pure returns(string memory) {
    uint pos = 0;
    uint8 labelCount = 0;
    string memory leftLabel = "";
    while (pos < input.length) {
        uint8 length = uint8(input[pos]);
        if (length == 0) {
            break;
        }
        require(length > 0 && length <= 63, "Invalid length");
        bytes memory labelBytes = new bytes(length);
        for (uint i = 0; i < length; i++) {
            labelBytes[i] = input[pos + i + 1];
        }
        string memory label = string(labelBytes);
        if (labelCount == 0) {
            leftLabel = label;
            break; // Exit the loop after getting the leftLabel
        }
        labelCount++;
        pos += length + 1;
    }
    return leftLabel;
}


function decodeData(bytes memory callData) internal pure returns(uint256 functionName, string memory key, uint256 coinType) {
        bytes32 node;
        bytes4 functionSelector;
        assembly {
            functionSelector:= mload(add(callData, 0x20))
        }
        bytes memory callDataWithoutSelector = new bytes(callData.length - 4);
        for (uint256 i = 0; i < callData.length - 4; i++) {
            callDataWithoutSelector[i] = callData[i + 4];
        }
        if (functionSelector == bytes4(keccak256("addr(bytes32)"))) {
            functionName = 1;
            (node) = abi.decode(callDataWithoutSelector, (bytes32));
        } if (functionSelector == bytes4(keccak256("addr(bytes32,uint256)"))) {
            functionName = 2;
            (node, coinType) = abi.decode(callDataWithoutSelector, (bytes32, uint256));
        } if (functionSelector == bytes4(keccak256("contenthash(bytes32)"))) {
            functionName = 3;
            (node) = abi.decode(callDataWithoutSelector, (bytes32));
        } if (functionSelector == bytes4(keccak256("text(bytes32,string)"))) {
            functionName = 4;
            (node, key) = abi.decode(callDataWithoutSelector, (bytes32, string));
        }
    }

function resolve(bytes memory callData) public view returns(bytes memory) {
        (bytes memory name, bytes memory data, address nft) = abi.decode(callData, (bytes, bytes, address));
        (string memory domain) = decodeName(name);
        (uint256 functionName, string memory key, uint256 coinType) = decodeData(data);
        nftContract wildcard = nftContract(nft);

            if (functionName == 1) {
                return abi.encode(wildcard.ownerOf(toUint(domain)));
            }
            if (functionName == 2 && (coinType == 60 || coinType > 2147483648)) {
                return abi.encode(addressToBytes(wildcard.ownerOf(toUint(domain))));
            }
            if (functionName == 4 && equals(key, "avatar") && toUint(domain) >= 0) {
                string memory nftaddr = toString(nft);
                return abi.encode(abi.encodePacked("https://avatar-arbitrum-cv4s4om35q-uc.a.run.app?nft=",nftaddr,"&id=",domain));
            }
            if (functionName == 4 && equals(key, "description") && toUint(domain) >= 0) {
                return abi.encode(wildcard.name());
            }
            if (functionName == 4 && equals(key, "url") && toUint(domain) >= 0) {
                return abi.encode(wildcard.tokenURI(toUint(domain)));
            }

            return abi.encode(0x00); 

}
}