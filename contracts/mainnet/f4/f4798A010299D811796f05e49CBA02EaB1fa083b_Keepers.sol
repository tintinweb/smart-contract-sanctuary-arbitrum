// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { IMinter } from "../periphery/interfaces/IMinter.sol";
import { IVoter2 } from "./interfaces/IVoter2.sol";
import { IEpochFlipper } from "./interfaces/IEpochFlipper.sol";

contract Keepers {
   uint constant WEEK = 7 days;
   uint private period;
   IMinter private immutable _minter;
   IVoter2 private immutable _voter;
   IEpochFlipper private immutable _epochFlipper;
   address private immutable _xcal;
   address private admin;
   bool public boostedVeDistSuccess;
   bool public boostedGaugeDistSuccess;
   bool public distributeSuccess;
   bool public distributeFeesSuccess;

   event Log(uint);

   constructor(address minter, address voter, address xcal, address epochFlipper) {
      _minter = IMinter(minter);
      _voter = IVoter2(voter);
      _epochFlipper = IEpochFlipper(epochFlipper);
      _xcal = xcal;
      // last thursday 12PM UTC
      period = (block.timestamp / WEEK) * WEEK;
   }

   function checkUpkeep() external view returns (bool upkeepNeeded, bytes memory performData) {
      upkeepNeeded = block.timestamp > (period + WEEK);
      performData = abi.encode(getPerformData());
   }

   function performUpkeep(bytes memory performData) external {
      if (block.timestamp > (period + WEEK)) {
         // decode calldata
         address[] memory _gauges = abi.decode(performData, (address[]));

         try _epochFlipper.veDistBoost() {
            boostedVeDistSuccess = true;
         } catch {
            boostedVeDistSuccess = false;
         }

         _minter.update_period();

         try _voter.distribute() {
            distributeSuccess = true;
         } catch {
            distributeSuccess = false;
         }

         try _voter.distributeFees(_gauges) {
            distributeFeesSuccess = true;
         } catch {
            distributeFeesSuccess = false;
         }

         try _epochFlipper.boostSelectedGauges() {
            boostedGaugeDistSuccess = true;
         } catch {
            boostedGaugeDistSuccess = false;
         }

         period += WEEK;
      }
   }

   function getPerformData() public view returns (address[] memory) {
      // number of gauges registered on voter
      uint _length = _voter.length();
      // all gauges registered on voter
      address[] memory _gauges = gauges(_length);
      // gauges with non-zero rewards
      (address[] memory _validGauges, uint _count) = validGauges(_gauges, _length);

      return trim(_validGauges, _count);
   }

   function gauges(uint length) public view returns (address[] memory) {
      address[] memory _gauges = new address[](length);
      for (uint i; i < length; i++) {
         _gauges[i] = _voter.allGauges(i);
      }
      return _gauges;
   }

   function validGauges(address[] memory allGauges, uint length) public view returns (address[] memory, uint) {
      address[] memory _validGauges = new address[](length);
      uint _c;
      for (uint i; i < length; i++) {
         if (_voter.weights(allGauges[i]) != 0) {
            _validGauges[_c] = allGauges[i];
            _c++;
         }
      }
      return (_validGauges, _c);
   }

   function trim(address[] memory arr, uint count) internal pure returns (address[] memory) {
      address[] memory _trimmed = new address[](count);
      for (uint i; i < count; i++) {
         _trimmed[i] = arr[i];
      }
      return _trimmed;
   }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IMinter {
  function update_period() external returns (uint);

  // function initialize(address[] memory claimants, uint[] memory amounts, uint max) external;
  function initialize() external;

  function active_period() external view returns (uint);

  function weekly_emission() external view returns (uint);

  function calculate_growth(uint _minted) external view returns (uint);

  function _token() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IVoter2 {
   function attachTokenToGauge(uint _tokenId, address account) external;

   function detachTokenFromGauge(uint _tokenId, address account) external;

   function emitDeposit(uint _tokenId, address account, uint amount) external;

   function emitWithdraw(uint _tokenId, address account, uint amount) external;

   function distribute(address _gauge) external;

   function notifyRewardAmount(uint amount) external;

   function _ve() external view returns (address);

   function createSwapGauge(address pair) external returns (address);

   function factory() external view returns (address);

   function listing_fee() external view returns (uint);

   function whitelist(address token) external;

   function isWhitelisted(address token) external view returns (bool);

   function bribeFactory() external view returns (address);

   function bribes(address gauge) external view returns (address);

   function gauges(address pair) external view returns (address);

   function isGauge(address gauge) external view returns (bool);

   function allGauges(uint index) external view returns (address);

   function vote(uint tokenId, address[] calldata gaugeVote, uint[] calldata weights) external;

   function lastVote(uint tokenId) external view returns (uint);

   function gaugeVote(uint tokenId) external view returns (address[] memory);

   function votes(uint tokenId, address gauge) external view returns (uint);

   function weights(address gauge) external view returns (uint);

   function usedWeights(uint tokenId) external view returns (uint);

   function claimable(address gauge) external view returns (uint);

   function totalWeight() external view returns (uint);

   function reset(uint tokenId) external;

   function claimFees(address[] memory bribes, address[][] memory tokens, uint tokenId) external;

   function distributeFees(address[] memory gauges) external;

   function updateGauge(address gauge) external;

   function poke(uint tokenId) external;

   function initialize(address minter) external;

   function minter() external view returns (address);

   function claimRewards(address[] memory gauges, address[][] memory rewards) external;

   function admin() external view returns (address);

   function isReward(address gauge, address token) external view returns (bool);

   function isBribe(address bribe, address token) external view returns (bool);

   function isLive(address gauge) external view returns (bool);

   function setBribe(address bribe, address token, bool status) external;

   function setReward(address gauge, address token, bool status) external;

   function killGauge(address _gauge) external;

   function reviveGauge(address _gauge) external;

   function distroFees() external;

   // additional signatures for Voter
   function distribute() external;

   function length() external view returns (uint);

   function updateAll() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IEpochFlipper {
   function veDistBoost() external;

   function boostSelectedGauges() external;
}