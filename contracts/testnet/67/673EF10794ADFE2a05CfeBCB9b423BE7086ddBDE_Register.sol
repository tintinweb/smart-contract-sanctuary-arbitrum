// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.22;

interface IKingdom {
    function state() external view returns (bool);

    function setState(bool _state) external;

    function getGame(string memory _title) external view returns (uint);

    function reserve() external view returns (address);

    function owner() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.22;

import { Errors } from 'contracts/types/Errors.sol';
import { Modifier } from '../shared/Modifier.sol';
import { IKingdom } from 'contracts/services/kingdom/IKingdom.sol';
import { Type } from 'contracts/types/Type.sol';

contract Register is Modifier {
    // 왕국 이벤트 참여, 왕국 컨트랙트를 통해서 참여해야함
    function joinTheKingdom(uint _event) public {
        if ($.wevents[_event].state == Type.State.END) revert Errors.EVENT_STATE(false); // 이벤트 종료 여부
        if (!IKingdom(msg.sender).state()) revert Errors.NOT_AVAILABLE(msg.sender); // 왕국 health check
        if ($.playingKingdom[_event][msg.sender]) revert Errors.ALREADY_REGISTERED(); // 중복 왕국 체크
        $.playingKingdom[_event][msg.sender] = true;
        $.playingKingdomCount[_event]++;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.22;

import { Type } from 'contracts/types/Type.sol';

library Data {
    struct Storage {
        mapping(address => bool) permission;
        mapping(uint => mapping(address => bool)) playingKingdom; // 게임에 참여한 왕국 상태
        mapping(uint => uint) playingKingdomCount; // 게임에 참여한 왕국 index,
        mapping(uint => Type.KingdomList[]) playingKingdomList; // 게임에 참여한 왕국 정보
        mapping(uint => address) kingdoms; // 건국된 왕국 정보
        bool operate;
        Type.WorldEvent[] wevents; // 이벤트들
        uint kcounts; // 왕국 갯수
        uint gcounts; // 게임갯수
        uint minAmount; // 건국 토큰 갯수
        address mainToken;
        address reserve;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.22;

import {Data} from "./Data.sol";
import {Errors} from "contracts/types/Errors.sol";

abstract contract Modifier {
    using Data for Data.Storage;
    Data.Storage internal $;

    modifier permission() {
        if (!$.permission[msg.sender]) revert Errors.NO_PERMISSION(msg.sender);
        _;
    }

    modifier isOperate() {
        if (!$.operate) revert Errors.NOT_POSSIBLE();
        _;
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