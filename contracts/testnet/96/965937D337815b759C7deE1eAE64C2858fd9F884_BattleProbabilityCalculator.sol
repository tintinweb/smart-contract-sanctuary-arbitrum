// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IBattleProbabilityCalculator.sol";
import "../lib/FloatingPointConstants.sol";

contract BattleProbabilityCalculator is IBattleProbabilityCalculator {
  function calculateProbability(
    int256 _attackerBp,
    int256 _defenderBp
  ) external pure returns (uint256 result) {
    result += uint((SIGNED_ONE_HUNDRED * (_attackerBp)) / (_attackerBp + _defenderBp));
    _attackerBp = (_attackerBp * _attackerBp) / SIGNED_DECIMAL_POINT;
    _defenderBp = (_defenderBp * _defenderBp) / SIGNED_DECIMAL_POINT;
    result += 5000 + uint((int(90000) * (_attackerBp)) / (_attackerBp + _defenderBp));
    result /= 2;
    return result;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IBattleProbabilityCalculator {

  function calculateProbability(int256 attackerBp, int256 defenderBp) external pure returns (uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

uint256 constant DECIMAL_POINT = 10 ** 3;
int256 constant SIGNED_DECIMAL_POINT = int256(DECIMAL_POINT);

uint256 constant ONE_HUNDRED = 100 * DECIMAL_POINT;
int256 constant SIGNED_ONE_HUNDRED = 100 * SIGNED_DECIMAL_POINT;

int256 constant SIGNED_ZERO = 0;