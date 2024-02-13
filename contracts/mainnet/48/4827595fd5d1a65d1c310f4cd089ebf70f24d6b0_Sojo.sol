/**
 *Submitted for verification at Arbiscan.io on 2024-02-12
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Sojo {
	address public owner;
	string public sealId;
	bool isSealed = true;

	struct Location {
		string latitude;
		string longitude;
	}

	Location[] public locations;

	event SealStatus(bool isSealed);
	event LocationAdded(string longitude, string latitude);

	modifier onlyOwner() {
		require(msg.sender == owner, "You aren't the owner");
		_;
	}

	constructor(string memory _sealId, string memory _longitude, string memory _latitude) {
		sealId = _sealId;
		owner = msg.sender;
		setLocation(_longitude, _latitude);
	}

	function getSealId() external view returns (string memory) {
		return sealId;
	}

	function getStatus() external view returns (bool) {
		return isSealed;
	}

	function openSeal(string memory _longitude, string memory _latitude) external onlyOwner {
		setLocation(_longitude, _latitude);
		isSealed = false;
		emit SealStatus(isSealed);
	}

	function setLocation(string memory _longitude, string memory _latitude) public onlyOwner {
		require(isSealed == true, 'Seal already opened');
		locations.push(Location({longitude: _longitude, latitude: _latitude}));
		emit LocationAdded(_longitude, _latitude);
	}

	function getAllLocationParameters() external view returns (Location[] memory) {
		return locations;
	}
}