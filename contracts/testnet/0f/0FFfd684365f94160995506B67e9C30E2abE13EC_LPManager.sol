pragma solidity ^0.8.0;

import "./Lib_Type.sol";

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";

contract LPManager is Initializable, ContextUpgradeable, OwnableUpgradeable {
    event AddPoolEvent(address indexed maker, bytes32 indexed lpId);
    event RemovePoolEvent(address indexed maker, bytes32 indexed lpId);

    mapping(bytes32 => Lib_Type.LP) public lps;
    Lib_Type.LpKey[] public lpKeys;

    function initialize() public initializer {
        __Ownable_init();
    }

    // exclude deleted lp
    function lpValidCount() public view returns (uint256) {
        uint256 len = 0;
	for (uint256 i = 0; i < lpKeys.length; i++) {
          if (!lpKeys[i].isDeleted) {
            len = len + 1;
	  }
	}
        return len;
    }

    // include deleted lp, used to iterate lpKeys
    function lpCount() public view returns (uint256) {
      return lpKeys.length;
    }


    // add a lp or update one
    function addLP(Lib_Type.Token memory baseToken,
		   Lib_Type.Token memory token_1,
		   Lib_Type.Token memory token_2,
		   address maker,
		   uint256 gasCompensation,
		   uint256 txFeeRatio,
		   uint256 startTimestamp,
		   uint256 stopTimestamp) external onlyOwner {
        bytes32 lpId = Lib_Type.getLpId(token_1, token_2, maker);
	lps[lpId] = Lib_Type.LP(
            lpId,
	    baseToken,
	    token_1,
	    token_2,
	    maker,
	    gasCompensation,
	    txFeeRatio,
	    startTimestamp,
	    stopTimestamp
	);

	Lib_Type.LpKey memory lpKey = Lib_Type.LpKey(lpId, false);
	uint256 index = 0;
	for (; index < lpKeys.length; index++) {
            if (lpKeys[index].isDeleted) {
	        lpKeys[index] = lpKey;
		break;
	    }
	    if (lpKeys[index].lpId == lpId) {
	        lpKeys[index] = lpKey;
		break;
	    }
	}
	if (index == lpKeys.length) {
	    lpKeys.push(lpKey);
	}

	emit AddPoolEvent(maker, lpId);
    }

    function removeLP(bytes32 lpId) external {
        address sender = _msgSender();

	uint256 index = 0;
	for (; index < lpKeys.length; index++) {
            if (lpKeys[index].lpId == lpId && !lpKeys[index].isDeleted) {
		break;
	    }
	}
	if (index < lpKeys.length) {
	    if (lps[lpId].maker == sender) {
		lpKeys[index].isDeleted = true;
      	        delete lps[lpId];
		emit RemovePoolEvent(sender, lpId);
	    }
	}
    }
}