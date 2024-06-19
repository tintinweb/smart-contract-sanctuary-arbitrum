/**
 *Submitted for verification at Arbiscan.io on 2024-06-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TrustGame {

    address public owner;

    struct GameData {
        uint256 gameId;
        string data;
        uint256 hexValue;
    }

    mapping(address => bool) private trustedAddresses;
    mapping(uint256 => GameData) public games;
    mapping(uint256 => bool) public gameExists;



    event GamePlayed(uint256 indexed gameId, string data);

    constructor() {
        owner = msg.sender;
        trustedAddresses[owner] = true;

    }

  

    function isTrustedAddress(address _address) external view returns (bool) {
        return trustedAddresses[_address];
    }

    function addTrustedAddress(address _address) external {
        require(
            msg.sender == owner,
            "Only the contract owner can add a trusted address"
        );
        require(!trustedAddresses[_address], "Address is already trusted");
        trustedAddresses[_address] = true;
    }

    function getGameData(uint256 _gameId)
        external
        view
        returns (
            uint256,
            string memory,
            uint256
        )
    {
        require(gameExists[_gameId], "Game ID does not exist");
        GameData memory gameData = games[_gameId];
        return (gameData.gameId, gameData.data, gameData.hexValue);
    }

    function keccakEncrypt(string memory secret) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(secret));
    }

    function getConcatenateStrings(
        string memory serverSecret,
        string[] memory stringList
    ) public pure returns (string memory) {
        string memory concatenated = string(
            abi.encodePacked(serverSecret, "|")
        );
        for (uint256 i = 0; i < stringList.length; i++) {
            concatenated = string(
                abi.encodePacked(concatenated, stringList[i])
            );
            if (i < stringList.length - 1) {
                concatenated = string(abi.encodePacked(concatenated, "-"));
            }
        }
        return concatenated;
    }

    function uint2str(uint256 _i) internal pure returns (string memory) {
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

    function processString(bytes32 input)
        public
        pure
        returns (
            uint256,
            string memory,
            uint256
        )
    {
        string memory inputString = bytes32ToString(input);
        (
            uint256 hexValue,
            string memory lastFiveString,
            uint256 result
        ) = getLastNCharsAndCompute(inputString, 5);

        if (result >= 100) {
            (hexValue, lastFiveString, result) = getLastNCharsAndCompute(
                inputString,
                10
            );
        }

        return (hexValue, lastFiveString, result);
    }

    function getRandomNumberBytes(bytes32 resultHash)
        public
        pure
        returns (
            uint256,
            string memory,
            uint256
        )
    {
        string memory inputString = bytes32ToString(resultHash);
        (
            uint256 hexValue,
            string memory lastFiveString,
            uint256 result
        ) = getLastNCharsAndCompute(inputString, 5);

        if (result >= 100) {
            (hexValue, lastFiveString, result) = getLastNCharsAndCompute(
                inputString,
                10
            );
        }

        return (hexValue, lastFiveString, result);
    }

    function bytes32ToString(bytes32 _bytes32)
        public
        pure
        returns (string memory)
    {
        bytes memory bytesArray = new bytes(64);
        for (uint256 i = 0; i < 32; i++) {
            uint8 _f = uint8(uint8(_bytes32[i]) / uint8(16));
            uint8 _l = uint8(uint8(_bytes32[i]) - 16 * _f);
            bytesArray[i * 2] = toHexDigit(_f);
            bytesArray[i * 2 + 1] = toHexDigit(_l);
        }
        return string(bytesArray);
    }

    function toHexDigit(uint8 d) internal pure returns (bytes1) {
        if (0 <= d && d <= 9) {
            return bytes1(uint8(bytes1("0")) + d);
        } else if (10 <= uint8(d) && uint8(d) <= 15) {
            return bytes1(uint8(bytes1("a")) + d - 10);
        }
        revert("Invalid hex digit");
    }

    function getLastNCharsAndCompute(string memory input, uint256 n)
        internal
        pure
        returns (
            uint256,
            string memory,
            uint256
        )
    {
        bytes memory inputBytes = bytes(input);
        uint256 length = inputBytes.length;
        require(length >= n, "Input string must be at least n characters long");

        bytes memory lastNBytes = new bytes(n);
        for (uint256 i = 0; i < n; i++) {
            lastNBytes[i] = inputBytes[length - n + i];
        }

        string memory lastNString = string(lastNBytes);
        uint256 hexValue = parseHex(lastNString);
        uint256 result = hexValue / 10000;

        return (hexValue, lastNString, result);
    }

    function parseHex(string memory hexString) internal pure returns (uint256) {
        bytes memory hexBytes = bytes(hexString);
        uint256 result = 0;
        for (uint256 i = 0; i < hexBytes.length; i++) {
            uint256 value = uint8(hexBytes[i]);
            if (value >= 48 && value <= 57) {
                result = result * 16 + (value - 48);
            } else if (value >= 65 && value <= 70) {
                result = result * 16 + (value - 55);
            } else if (value >= 97 && value <= 102) {
                result = result * 16 + (value - 87);
            } else {
                revert("Invalid character in hex string");
            }
        }
        return result;
    }

    function stringToBytes32(string memory source)
        public
        pure
        returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function getRandomNumber(string memory resultHash)
        public
        pure
        returns (
            uint256,
            string memory,
            uint256
        )
    {
        (
            uint256 hexValue,
            string memory lastFiveString,
            uint256 result
        ) = getLastNCharsAndCompute(resultHash, 5);

        if (result >= 100) {
            (hexValue, lastFiveString, result) = getLastNCharsAndCompute(
                resultHash,
                10
            );
        }
        return (hexValue, lastFiveString, result);
    }

    function getTicket(uint256 randomNumber, uint256 totalTicket)
        public
        pure
        returns (uint256)
    {
        return (randomNumber * totalTicket) / 10000 / 100;
    }

    function fromRawLaunch(
        uint256 _gameId,
        string memory serverSecret,
        string[] memory _seedList
    ) external {
        require(
            trustedAddresses[msg.sender],
            "Caller is not a trusted address"
        );
        require(!gameExists[_gameId], "Game ID already exists");
        require(_seedList.length > 0, "List cannot be empty");
        string memory secretString = getConcatenateStrings(
            serverSecret,
            _seedList
        );
        bytes32 secretHash = keccakEncrypt(secretString);
        string memory dataString = bytes32ToString(secretHash);

        (uint256 hexValue, , ) = getRandomNumberBytes(secretHash);

        games[_gameId] = GameData({
            gameId: _gameId,
            data: dataString,
            hexValue: hexValue
        });
        gameExists[_gameId] = true;

        emit GamePlayed(_gameId, dataString);
    }

    function LaunchGame(uint256 _gameId, string memory _secretString) external {
        require(
            trustedAddresses[msg.sender],
            "Caller is not a trusted address"
        );
        require(!gameExists[_gameId], "Game ID already exists");
        bytes32 secretHash = keccakEncrypt(_secretString);
        string memory dataString = bytes32ToString(secretHash);

        (uint256 hexValue, , ) = getRandomNumberBytes(secretHash);

        games[_gameId] = GameData({
            gameId: _gameId,
            data: dataString,
            hexValue: hexValue
        });
        gameExists[_gameId] = true;

        emit GamePlayed(_gameId, dataString);
    }
}