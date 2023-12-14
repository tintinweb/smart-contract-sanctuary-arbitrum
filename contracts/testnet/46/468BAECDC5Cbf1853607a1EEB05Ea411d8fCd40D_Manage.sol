// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.22;
import { Modifier } from '../shared/Modifier.sol';

contract Manage is Modifier {
    function getTitle() public view returns (string memory) {
        return $.title;
    }

    function getTarget() public view returns (bytes32) {
        return $.target;
    }

    function getCount() public view returns (uint) {
        return $.count;
    }

    function getNonce() public view returns (string memory) {
        return $.nonce;
    }

    function getHint() public view returns (bytes32[] memory, bytes32[] memory) {
        return ($.minHint, $.maxHint);
    }

    function getOwner() public view returns (address) {
        return $.owner;
    }

    function getAll() public view returns (bool, uint, address) {
        return ($.setup, $.playingEvent, $.owner);
    }

    // 실행 권한 등록
    function setPermission(address _account, bool _state) public permission {
        $.permission[_account] = _state;
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