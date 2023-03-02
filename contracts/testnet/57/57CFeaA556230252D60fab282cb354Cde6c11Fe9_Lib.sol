//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
interface IPits {
    function validation() external view returns (bool);

    function getTimeOut() external view returns (uint256);

    function getTimeBelowMinimum() external view returns (uint256);

    function getDaysOff(uint256 _timestamp) external view returns (uint256);

    function getTotalDaysOff() external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error CsToHigh();
error NotAContract();
error NotYourToken();
error NotAuthorized();
error WrongMultiple();
error CannotClaimNow();
error TransferFailed();
error InvalidTokenId();
error InvalidLockTime();
error NoMoreAnimalsAllowed();
error LengthsNotEqual();
error ZeroBalanceError();
error CsIsBellowHundred();
error NeandersmolsIsLocked();
error BalanceIsInsufficient();
error InvalidTokenForThisJob();
error DevelopmentGroundIsLocked();
error NeandersmolIsNotInDevelopmentGround();

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IPits } from "../interfaces/IPits.sol";
import { DevelopmentGroundIsLocked } from "./Error.sol";

library Lib {
    function getDevelopmentGroundBonesReward(
        uint256 _currentLockPeriod,
        uint256 _lockPeriod,
        uint256 _lastRewardTime,
        IPits _pits
    ) external view returns (uint256) {
        if (_lockPeriod == 0) return 0;
        uint256 rewardRate = getRewardRate(_lockPeriod);

        uint256 time = (block.timestamp - _lastRewardTime) / 1 days;

        return
            (rewardRate *
                time -
                calculateFinalReward(_currentLockPeriod, _pits)) * 10 ** 18;
    }

    function calculatePrimarySkill(
        uint256 _bonesStaked,
        uint256 _amountPosition,
        uint256 _currentLockPeriod,
        uint256 _tokenId,
        IPits _pits,
        mapping(uint256 => mapping(uint256 => uint256)) storage trackTime,
        mapping(uint256 => mapping(uint256 => uint256)) storage trackToken
    ) external view returns (uint256) {
        if (_bonesStaked == 0) return 0;
        uint256 amount;
        for (uint256 i = 1; i <= _amountPosition; ) {
            uint256 time = (block.timestamp - trackTime[_tokenId][i]) / 1 days;
            uint256 stakedAmount = trackToken[_tokenId][trackTime[_tokenId][i]];
            amount += (time * stakedAmount);

            unchecked {
                ++i;
            }
        }

        return
            (amount -
                calculateFinalReward(_currentLockPeriod, _pits) *
                10 ** 20) / 10 ** 4;
    }

    function calculateFinalReward(
        uint256 _currentLockPeriod,
        IPits _pits
    ) internal view returns (uint256) {
        uint256 amount;

        if (_currentLockPeriod != _pits.getTimeOut()) {
            uint256 howLong = (block.timestamp - _pits.getTimeOut()) / 1 days;
            amount = (_pits.getTotalDaysOff() -
                _pits.getDaysOff(_currentLockPeriod) +
                howLong);
        }
        if (_currentLockPeriod == 0) {
            uint256 off;
            _pits.getTimeOut() != 0
                ? off = (block.timestamp - _pits.getTimeOut()) / 1 days
                : 0;
            if (_pits.validation()) off = _pits.getTotalDaysOff();
            amount = off;
        }
        return amount * 10;
    }

    function getRewardRate(
        uint _lockTime
    ) internal pure returns (uint256 rewardRate) {
        if (_lockTime == 50 days) rewardRate = 10;
        if (_lockTime == 100 days) rewardRate = 50;
        if (_lockTime == 150 days) rewardRate = 100;
    }

    function pitsValidation(IPits _pits) external view {
        if (!_pits.validation()) revert DevelopmentGroundIsLocked();
    }

    function removeItem(
        uint256[] storage _element,
        uint256 _removeElement
    ) internal {
        uint256 i;
        for (; i < _element.length; ) {
            if (_element[i] == _removeElement) {
                _element[i] = _element[_element.length - 1];
                _element.pop();
                break;
            }

            unchecked {
                ++i;
            }
        }
    }
}