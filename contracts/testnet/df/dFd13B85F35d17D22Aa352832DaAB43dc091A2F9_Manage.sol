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
import { Type } from 'contracts/types/Type.sol';
import { Errors } from 'contracts/types/Errors.sol';
import { IGame } from 'contracts/services/game/IGame.sol';
import { IERC20 } from 'contracts/interfaces/IERC20.sol';

contract Manage is Modifier {
    // operate 조회
    function getOperate() public view returns (bool) {
        return $.operate;
    }

    // operate 설정
    function setOperate(bool _state) public permission {
        $.operate = _state;
    }

    // 왕국 위치 조회
    function getCastle(uint _index) public view returns (address) {
        return $.kingdoms[_index];
    }

    // 왕국 이벤트 등록 조회
    function joinedCastleState(uint _event, address _target) public view returns (bool) {
        return $.playingKingdom[_event][_target];
    }

    // 왕구 정보 조회2
    function joinedCastleState(uint _event) public view returns (uint) {
        return $.playingKingdomCount[_event];
    }

    // 이벤트 조회
    function getWorldEvent(uint _event) public view returns (Type.WorldEvent memory) {
        return $.wevents[_event];
    }

    // 이벤트 조회
    function getWorldEventAll() public view returns (Type.WorldEvent[] memory) {
        return $.wevents;
    }

    // 왕국 게임정보 셋팅
    function setKingdomUpdate(uint _event, uint _count) external {
        (bool state, uint __event, address owner) = IGame(msg.sender).getAll();
        if (!$.playingKingdom[__event][owner]) revert Errors.NO_PERMISSION(msg.sender); // 왕국만 최초 한번 실행 가능
        if (state && (__event == _event)) {
            $.playingKingdomList[_event].push(Type.KingdomList(msg.sender, _count, true));
        } else {
            revert Errors.NOT_AVAILABLE(owner);
        }
    }

    // 게임정보 조회
    function getKingdomGame(uint _event) public view returns (Type.KingdomList[] memory) {
        return $.playingKingdomList[_event];
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