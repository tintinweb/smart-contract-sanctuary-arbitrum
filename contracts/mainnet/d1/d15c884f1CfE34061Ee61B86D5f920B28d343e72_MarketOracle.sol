// SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

import "./SignatureLib.sol";

// Oracle
interface IOracle {
    struct Scratched {
        bytes16 propositionId;
        // Timestamp of when the result was scratched
        uint256 timestamp;
        // Odds of the scratched proposition at time of scratching
        uint256 odds;
    }

    struct Result {
        bytes16 winningPropositionId;
        Scratched[] scratched;
	}

    function hasResult(bytes16 marketId) external view returns (bool);

    function checkResult(
        bytes16 marketId,
        bytes16 propositionId
    ) external view returns (uint8);

    function getResult(bytes16 marketId) external view returns (Result memory);

    function setResult(
        bytes16 marketId,
        bytes16 propositionId,
        SignatureLib.Signature calldata signature
    ) external;

	function setScratchedResult(
		bytes16 marketId,
		bytes16 propositionId,
        uint256 odds,
		SignatureLib.Signature calldata signature
	) external;

    event ResultSet(bytes16 indexed marketId, bytes16 indexed propositionId);
    event ScratchedSet(bytes16 indexed marketId, bytes16 indexed propositionId);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

import "./IOracle.sol";
import "./SignatureLib.sol";

contract MarketOracle is IOracle {

	// Mapping of marketId => winning propositionId
	mapping(bytes16 => Result) private _results;
	address private immutable _owner;

	// Race result constants
	uint8 public constant NULL = 0x00;
    uint8 public constant WINNER = 0x01;
    uint8 public constant LOSER = 0x02;
    uint8 public constant SCRATCHED = 0x03;

	constructor() {
		_owner = msg.sender;
	}

	function getOwner() external view returns (address) {
		return _owner;
	}

	function hasResult(bytes16 marketId) external view returns (bool) {
		return _results[marketId].winningPropositionId != bytes16(0);
	}

	function checkResult(
		bytes16 marketId,
		bytes16 propositionId
	) external view returns (uint8) {
		require(
			propositionId != bytes16(0),
			"checkResult: Invalid propositionId"
		);

		if (_results[marketId].winningPropositionId == propositionId) {
			return WINNER;
		}
		
		uint256 totalScratched = _results[marketId].scratched.length;
		for (uint256 i = 0; i < totalScratched; i++) {
			if (_results[marketId].scratched[i].propositionId == propositionId) {
				return SCRATCHED;
			}
		}

		if (_results[marketId].winningPropositionId != propositionId && _results[marketId].winningPropositionId != bytes16(0)) {
			return LOSER;
		}

		return NULL;
	}

	function getResult(bytes16 marketId) external view returns (Result memory) {
		require(
			marketId != bytes16(0),
			"getResult: Invalid propositionId"
		);
		return _getResult(marketId);
	}

	function _getResult(bytes16 marketId) private view returns (Result memory) {
		return _results[marketId];
	}

	function setResult(
		bytes16 marketId,
		bytes16 winningPropositionId,
		SignatureLib.Signature calldata signature
	) external {
		bytes32 messageHash = keccak256(abi.encodePacked(marketId, winningPropositionId));
		require(
			isValidSignature(messageHash, signature),
			"setResult: Invalid signature"
		);
		require(
			winningPropositionId != bytes16(0),
			"setResult: Invalid propositionId"
		);
		require(
			_results[marketId].winningPropositionId == bytes16(0),
			"setResult: Result already set"
		);
		_results[marketId].winningPropositionId = winningPropositionId;

		emit ResultSet(marketId, winningPropositionId);
	}

	function setScratchedResult(
		bytes16 marketId,
		bytes16 scratchedPropositionId,
		uint256 odds,
		SignatureLib.Signature calldata signature
	) external {
		bytes32 messageHash = keccak256(abi.encodePacked(marketId, scratchedPropositionId, odds));
		require(
			isValidSignature(messageHash, signature),
			"setScratchedResult: Invalid signature"
		);
		require(
			scratchedPropositionId != bytes16(0),
			"setScratchedResult: Invalid propositionId"
		);

		uint256 totalScratched = _results[marketId].scratched.length;
		for (uint256 i = 0; i < totalScratched; i++) {
			if (_results[marketId].scratched[i].propositionId == scratchedPropositionId) {
				revert("setScratchedResult: Result already set");
			}
		}

		_results[marketId].scratched.push(
			Scratched(
				scratchedPropositionId,
				block.timestamp,
				odds
		));

		emit ScratchedSet(marketId, scratchedPropositionId);
	}

	function isValidSignature(
		bytes32 messageHash,
		SignatureLib.Signature calldata signature
	) private view returns (bool) {
		address signer = SignatureLib.recoverSigner(messageHash, signature);
		assert(signer != address(0));
		return address(signer) == address(_owner);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

library SignatureLib {
    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function recoverSigner(
        bytes32 message,
        Signature memory signature
    ) public pure returns (address) {
        bytes32 prefixedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", message)
        );
        return ecrecover(prefixedHash, signature.v, signature.r, signature.s);
    }
}