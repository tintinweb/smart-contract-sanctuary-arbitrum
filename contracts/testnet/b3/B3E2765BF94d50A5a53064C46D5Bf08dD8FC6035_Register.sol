// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.22;

import { Errors } from 'contracts/types/Errors.sol';
import { Modifier } from '../shared/Modifier.sol';
import { IWorld } from 'contracts/services/world/IWorld.sol';
import { IReserve } from 'contracts/services/reserve/IReserve.sol';

contract Register is Modifier {
    // 게임 시작
    function startGame(
        bytes32 _target,
        uint8 _count,
        bytes32[] memory _minHint,
        bytes32[] memory _maxHint,
        string memory _nonce
    ) public permission {
        if ($.setup) revert Errors.ALREADY_REGISTERED();

        $.target = _target;
        $.count = _count;
        $.minHint = _minHint;
        $.maxHint = _maxHint;
        $.setup = true;
        $.nonce = _nonce;
        $.startTime = block.timestamp;
        IWorld($.world).setKingdomUpdate($.playingEvent, _count);
        IReserve($.reserve).kingGameApprove($.playingEvent);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.22;

import { Type } from 'contracts/types/Type.sol';

library Data {
    struct Storage {
        string title; // 왕국이 설정한 게임 이름
        bytes32 target; // 왕국이 설정한 타겟 번호
        uint count; // 왕국이 설정한 힌트 갯수
        bytes32[] minHint; // 타겟 이하의 힌트
        bytes32[] maxHint; // 타겟 이상의 힌트
        bool setup; // 게임 셋팅 상태, 파밍 참여 상태
        string nonce; // 힌트 해시할때 사용하는 논스
        uint playingEvent; // 참여 이벤트 번호
        address owner; // 왕국 주소
        address world; // world 주소
        address reserve;
        mapping(address => bool) permission; // 실행 권한
        uint startTime; // 파밍 시작시간
        mapping(bytes32 => Type.Checker) checked; // 찾은 번호들
        bool process;
        bool harvested;
        address rToken;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.22;

import { Errors } from 'contracts/types/Errors.sol';
import { Data } from './Data.sol';

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

interface IReserve {
    function isStaking(address _target) external view returns (bool);

    function kingGameApprove(uint _event) external;
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