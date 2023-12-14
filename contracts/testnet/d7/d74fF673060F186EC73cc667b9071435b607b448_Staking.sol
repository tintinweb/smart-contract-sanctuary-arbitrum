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
import { Errors } from 'contracts/types/Errors.sol';
import { Type } from 'contracts/types/Type.sol';
import { Events } from '../shared/Events.sol';

contract Staking is Modifier {
    // 스테이킹
    function staking(uint _amount) public payable {
        if ($.period == 0) revert Errors.NOT_POSSIBLE();
        if (IERC20($.rToken).balanceOf(msg.sender) < _amount) revert Errors.INSUFFICIENT_AMOUNT();

        $.staker[msg.sender] = Type.Staker(_amount, true, 0, 0);

        IERC20($.rToken).transferFrom(msg.sender, address(this), _amount);

        emit Events.staking(msg.sender, _amount, block.timestamp);
    }

    // 언스테이킹 신청
    function unStaking(uint _amount) public guard {
        Type.Staker memory staker = $.staker[msg.sender];
        if (staker.amount <= _amount) revert Errors.INSUFFICIENT_AMOUNT();
        if (!staker.staking) revert Errors.ALREADY_UNSTKAIN();
        if (staker.claimTime != 0) revert Errors.ALREADY_UNSTKAIN();

        staker.staking = false;
        staker.claimTime = block.timestamp + $.period;
        staker.claimAmount = _amount;
        $.staker[msg.sender] = staker;
        emit Events.unstaking(msg.sender, staker.claimAmount, staker.claimTime);
    }

    // 언스 물량 회수
    function claim() public guard {
        Type.Staker memory staker = $.staker[msg.sender];
        if (staker.claimAmount == 0) revert Errors.INSUFFICIENT_AMOUNT();
        if (staker.staking) revert Errors.ALREADY_UNSTKAIN();

        uint amount = staker.claimAmount;
        if ((staker.amount - staker.claimAmount) == 0) staker.staking = false;
        staker.claimTime = 0;
        staker.claimAmount = 0;
        $.staker[msg.sender] = staker;

        IERC20($.rToken).transfer(msg.sender, amount);

        emit Events.claimToken(msg.sender, staker.claimAmount, block.timestamp);
    }

    // 스테이킹 여부
    function isStaking(address _target) public view returns (bool) {
        return $.staker[_target].staking;
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

interface Events {
    event staking(address indexed _owner, uint indexed amount, uint indexed _now);
    event unstaking(address indexed _owner, uint indexed _claimAmount, uint indexed _claimTime);
    event claimToken(address indexed _owner, uint indexed _claimAmount, uint indexed _now);
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