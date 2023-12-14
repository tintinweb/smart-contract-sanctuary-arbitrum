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
import { Modifier } from '../shared/Modifier.sol';
import { IERC20 } from 'contracts/interfaces/IERC20.sol';
import { IWorld } from 'contracts/services/world/IWorld.sol';
import { IGame } from 'contracts/services/game/IGame.sol';
import { Type } from 'contracts/types/Type.sol';
import { Errors } from 'contracts/types/Errors.sol';
import { Utils } from '../shared/Internals.sol';
import { IKingdom } from 'contracts/services/kingdom/IKingdom.sol';
import { Data } from '../shared/Data.sol';
import { Events } from '../shared/Events.sol';

contract Claim is Modifier {
    using Utils for Data.Storage;

    // 이 게임 왕국이 종료를 선언
    // 약탈자및 왕국은 해당 기능을 통해 토큰을 수령해갈수있다.
    function harvest() external guard {
        Type.WorldEvent memory worldEvent = IWorld($.world).getWorldEvent($.playingEvent);
        if ($.harvested) revert Errors.ALREADY_HARVESTED();
        if (block.timestamp < (worldEvent.start + worldEvent.duration)) revert Errors.NOT_YET(); // 게임이 끝난 여부 확인
        if ($.checkNumber() && IKingdom($.owner).owner() == msg.sender) revert Errors.WAS_LOOTED(); // 약탈자 에게 강탈 당했는지 확인
        if (IKingdom($.owner).owner() != msg.sender && $.checked[$.target].owner != msg.sender)
            revert Errors.NO_PERMISSION(msg.sender); // 왕국 소유자 또는 번호를 찾은 권한있는 약탈자가 수행했는지 확인

        uint amount = yield();
        $.harvested = true;
        IERC20($.rToken).transferFrom($.reserve, msg.sender, amount);

        emit Events.harvest(msg.sender, amount, block.timestamp);
    }

    // 이게임의 왕국 수확량 조회
    function yield() public view returns (uint) {
        unchecked {
            Type.WorldEvent memory worldEvent = IWorld($.world).getWorldEvent($.playingEvent);
            uint joined = IWorld($.world).joinedCastleState($.playingEvent); // 함께하는 왕국들

            uint worldWeight; // 왕국 전체 파밍속도
            uint kingdomAmount; // 실제 왕국이 할당받은 토큰
            uint time = worldEvent.start + worldEvent.duration > block.timestamp
                ? block.timestamp
                : worldEvent.start + worldEvent.duration;

            Type.KingdomList[] memory kingdoms = IWorld($.world).getKingdomGame($.playingEvent);

            // 왕국 전체 파밍속도
            for (uint i = 0; i < joined; i++) {
                worldWeight += kingdoms[i].count;
            }
            kingdomAmount = worldEvent.amount / ((worldWeight * 100) / $.count);

            // 제시간에 참여 못한 왕국 계산
            if ($.startTime - worldEvent.start > 600) {
                uint loss = ($.startTime - worldEvent.start) * (kingdomAmount / worldEvent.duration);
                return kingdomAmount = ((kingdomAmount / worldEvent.duration) * (time - $.startTime)) - loss;
            } else {
                return kingdomAmount = (kingdomAmount / worldEvent.duration) * (time - $.startTime);
            }
        }
    }
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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.22;

interface Events {
    event claim(address indexed _owner, bytes32 indexed _hasedNumber, uint indexed _now);
    event harvest(address indexed _owner, uint indexed _amount, uint indexed _now);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.22;

import { Data } from '../shared/Data.sol';

library Utils {
    // check target number
    function checkNumber(Data.Storage storage $) internal view returns (bool) {
        return $.checked[$.target].state;
    }

    function getHased(uint64 _number) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(_number));
    }

    function getHased(uint64 _number, string memory _nonce) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(_number, _nonce));
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

interface IKingdom {
    function state() external view returns (bool);

    function setState(bool _state) external;

    function getGame(string memory _title) external view returns (uint);

    function reserve() external view returns (address);

    function owner() external view returns (address);
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