// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Lib_Type.sol";

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";

contract LPManager is Initializable, ContextUpgradeable, OwnableUpgradeable {
  event AddPoolEvent(address indexed maker, bytes32 indexed lpId);
  event UpdatePoolEvent(address indexed maker, bytes32 indexed lpId);
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

  function findLpIndex(bytes32 lpId) internal view returns (uint256, bool) {
    uint256 index = 0;
    for (; index < lpKeys.length; index++) {
      if (lpKeys[index].isDeleted) {
        continue;
      }
      if (lpKeys[index].lpId == lpId) {
        break;
      }
    }
    return (index, index < lpKeys.length);
  }

  function findFirstAvailableIndex() internal view returns (uint256) {
    uint256 index = 0;
    for (; index < lpKeys.length; index++) {
      if (lpKeys[index].isDeleted) {
        break;
      }
    }
    return index;
  }

  function addLP(
      Lib_Type.Token memory baseToken,
      Lib_Type.Token memory token_1,
      Lib_Type.Token memory token_2,
      address maker,
      uint256 gasCompensation,
      uint256 txFeeRatio,
      uint256 startTimestamp,
      uint256 stopTimestamp) external onlyOwner {

    bytes32 lpId = Lib_Type.getLpId(token_1, token_2, maker);
    (, bool ok) = findLpIndex(lpId);
    require(!ok, "lp already exists");

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

	  // add LpKey
    Lib_Type.LpKey memory lpKey = Lib_Type.LpKey(lpId, false);
	  uint256 index = findFirstAvailableIndex();
	  if (index == lpKeys.length) {
      lpKeys.push(lpKey);
	  } else {
      lpKeys[index] = lpKey;
	  }

	  emit AddPoolEvent(maker, lpId);
  }

  function updateLP(Lib_Type.Token memory baseToken,
                    Lib_Type.Token memory token_1,
                    Lib_Type.Token memory token_2,
                    address maker,
                    uint256 gasCompensation,
                    uint256 txFeeRatio,
                    uint256 startTimestamp,
                    uint256 stopTimestamp) external onlyOwner {
    bytes32 lpId = Lib_Type.getLpId(token_1, token_2, maker);
	  (, bool ok) = findLpIndex(lpId);
	  require(ok, "lp not found");

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

	  emit UpdatePoolEvent(maker, lpId);
  }

  function addOrUpdateLP(Lib_Type.Token memory baseToken,
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

	  (, bool ok) = findLpIndex(lpId);
	  if (ok) {
	    emit UpdatePoolEvent(maker, lpId);
	  } else {
      Lib_Type.LpKey memory lpKey = Lib_Type.LpKey(lpId, false);
	    uint256 index = findFirstAvailableIndex();
	    if (index == lpKeys.length) {
        lpKeys.push(lpKey);
	    } else {
        lpKeys[index] = lpKey;
	    }
	    emit AddPoolEvent(maker, lpId);
	  }
  }
   
  function removeLP(bytes32 lpId) external {
    address sender = _msgSender();

	  (uint256 index, bool ok) = findLpIndex(lpId);
	  require(ok, "lp not found");
	  require(lps[lpId].maker == sender, "only maker can remove its lp");
    lpKeys[index].isDeleted = true;
    delete lps[lpId];
    emit RemovePoolEvent(sender, lpId);
  }
}