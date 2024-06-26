// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract SlotDataContract {
	uint256 latest = 49;                                // Slot 0
	string name;                                        // Slot 1
	mapping(uint256=>uint256) highscores;               // Slot 2
	mapping(uint256=>string) highscorers;               // Slot 3
	mapping(string=>string) realnames;                  // Slot 4
	uint256 zero;                                       // Slot 5
	bytes pointlessBytes;                               // Slot 6
	bytes paddedAddress;                                // Slot 7
	mapping(address=>string) addressIdentifiers;        // Slot 8
	string iam = "tomiscool";                           // Slot 9
	mapping(string=>string) stringStrings;              // Slot 10
	address anotherAddress;                             // Slot 11

	struct Node {
		uint256 num;
		string str;
		mapping(bytes => Node) map;
	}
	Node root; // Slot 12-14

	constructor(address _anotherAddress) {

		name = "Satoshi";
		highscores[0] = 1;
		highscores[latest] = 12345;
		highscorers[latest] = name;
		highscorers[1] = "Hubert Blaine Wolfeschlegelsteinhausenbergerdorff Sr.";
		realnames["Money Skeleton"] = "Vitalik Buterin";
		realnames[highscorers[latest]] = "Hal Finney";
		pointlessBytes = abi.encodePacked(uint8(0),uint8(0),uint8(49));
		paddedAddress = abi.encodePacked(uint64(0), _anotherAddress);
		addressIdentifiers[_anotherAddress] = "tom";
		stringStrings["tom"] = "clowes";
		anotherAddress = _anotherAddress;

		//tom => 0x746f6d
		//tomiscool => 0x746f6d6973636f6f6c

		root.num = 1;
		root.str = "raffy";
		root.map["a"].num = 2;
		root.map["a"].str = "chonk";
		root.map["a"].map["b"].num = 3;
		root.map["a"].map["b"].str = "eth";

		// realnames[highscorers[latest]].slice(0, 3) + highscores[latest].slice(16, 16)
		highscorers[uint256(keccak256(abi.encodePacked("Hal", uint128(12345))))] = "chonk";

	}
}