// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.22;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.22;

interface IGame {
    function setPermission(address _account, bool _state) external;

    function getTitle() external view returns (string memory);

    function getCount() external view returns (bytes32);

    function getOwner() external view returns (address);

    function getAll() external view returns (bool, uint, address);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.22;

import { Modifier } from '../shared/Modifier.sol';
import { IERC20 } from 'contracts/interfaces/IERC20.sol';
import { Errors } from 'contracts/types/Errors.sol';
import { IGame } from 'contracts/services/game/IGame.sol';
import { IWorld } from 'contracts/services/world/IWorld.sol';

contract Manage is Modifier {
    // 저축량
    function saving() public view returns (uint) {
        return IERC20($.rToken).balanceOf(address(this));
    }

    // 권한 확인
    function getPermission(address _target) public view returns (bool) {
        return $.permission[_target];
    }

    function setWorld(address _target) public permission {
        $.world = _target;
    }

    function setPeriod(uint256 _timePeriodInSeconds) public permission {
        if ($.timestampSet == true) revert Errors.ALREADY_REGISTERED();
        $.timestampSet = true;
        $.period = _timePeriodInSeconds;
    }

    // 왕 게임 권한 요청
    function kingGameApprove(uint _event) external {
        if (IGame(msg.sender).getOwner() == address(0)) revert Errors.NOT_AVAILABLE(msg.sender);
        IERC20($.rToken).approve(msg.sender, IWorld($.world).getWorldEvent(_event).amount);
        //IWorld($.world).approveGame(msg.sender, _event); // IERC20($.rToken).approve(_target, 1000);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.22;

import { Type } from 'contracts/types/Type.sol';

library Data {
    struct Storage {
        mapping(address => bool) permission;
        mapping(address => Type.Staker) staker;
        address rToken;
        address world;
        bool process;
        bool timestampSet; // 셋업1
        uint period; // 락 기간
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.22;

import { Data } from './Data.sol';
import { Errors } from 'contracts/types/Errors.sol';

abstract contract Modifier {
    using Data for Data.Storage;
    Data.Storage internal $;

    modifier permission() {
        if (!$.permission[msg.sender]) revert Errors.NO_PERMISSION(msg.sender);
        _;
    }
    modifier guard() {
        if ($.process) revert Errors.REENTRANCY($.process);
        $.process = true;
        _;
        $.process = false;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.22;
import { Type } from 'contracts/types/Type.sol';

interface IWorld {
    function joinTheKingdom(uint _event) external;

    function joinedCastleState(uint _event, address _target) external view returns (bool);

    function getWorldEvent(uint _index) external view returns (Type.WorldEvent memory);

    function joinedCastleState(uint _event) external view returns (uint);

    function setKingdomUpdate(uint _event, uint _count) external;

    function getKingdomGame(uint _event) external view returns (Type.KingdomList[] memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.22;

interface Errors {
    error NO_PERMISSION(address);
    error NOT_POSSIBLE();
    error INSUFFICIENT_AMOUNT();
    error LOW_VALUE(uint);
    error WRONG_VALUE(uint);
    error ALREADY_REGISTERED();
    error ALREADY_UNSTKAIN();
    error ALREADY_HARVESTED();
    error NOT_AVAILABLE(address);
    error EVENT_STATE(bool);
    error MISMATCH_OWNER();
    error REENTRANCY(bool);
    error NOT_FOUNDED();
    error NOT_YET();
    error WAS_LOOTED();
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.22;

// import {Type} from "modules/history/types/Type.sol";

interface Type {
    enum State {
        START,
        END
    }

    struct WorldEvent {
        uint index; // 식별 번호
        uint amount; // 뿌릴양
        uint start; // 시작 시간
        uint duration; // 이벤트 기간
        State state; // 이벤트 상태
        //uint totalCounts; // 왕국 해시 통합 카운트
    }

    // 참여중인 게임 정보
    struct KingdomList {
        address kingdom;
        uint count;
        bool state;
    }

    // 번호
    struct Checker {
        address owner;
        bool state;
    }

    struct Staker {
        uint amount;
        bool staking; // true : staking, false : unstaking
        uint claimTime; // 언스 예정일
        uint claimAmount; // 언스 양
    }
}