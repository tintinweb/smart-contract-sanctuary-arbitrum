// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.8;

library EnumerableSet {
    struct Set {
        bytes32[] _values;
        mapping(bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                set._values[toDeleteIndex] = lastValue;
                set._indexes[lastValue] = valueIndex;
            }

            delete set._values[lastIndex];
            set._values.pop();

            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        return set._values[index];
    }

    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    //======== Bytes32Set ========

    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value)
        public
        returns (bool)
    {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value)
        public
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value)
        public
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) public view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint256 index)
        public
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    function values(Bytes32Set storage set)
        public
        view
        returns (bytes32[] memory)
    {
        return _values(set._inner);
    }

    //======== AddressSet ========

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value)
        public
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value)
        public
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value)
        public
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) public view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index)
        public
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function values(AddressSet storage set)
        public
        view
        returns (address[] memory)
    {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    //======== UintSet ========

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) public returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value)
        public
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value)
        public
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) public view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index)
        public
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }

    function values(UintSet storage set)
        public
        view
        returns (uint256[] memory)
    {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright (c) 2021-2024 LI LI @ JINGTIAN & GONGCHENG.
 *
 * This WORK is licensed under ComBoox SoftWare License 1.0, a copy of which 
 * can be obtained at:
 *         [https://github.com/paul-lee-attorney/comboox]
 *
 * THIS WORK IS PROVIDED ON AN "AS IS" BASIS, WITHOUT 
 * WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
 * TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE. IN NO 
 * EVENT SHALL ANY CONTRIBUTOR BE LIABLE TO YOU FOR ANY DAMAGES.
 *
 * YOU ARE PROHIBITED FROM DEPLOYING THE SMART CONTRACTS OF THIS WORK, IN WHOLE 
 * OR IN PART, FOR WHATEVER PURPOSE, ON ANY BLOCKCHAIN NETWORK THAT HAS ONE OR 
 * MORE NODES THAT ARE OUT OF YOUR CONTROL.
 * */

pragma solidity ^0.8.8;

import "./EnumerableSet.sol";

library TeamsRepo {
    using EnumerableSet for EnumerableSet.UintSet;

    struct Member {
        uint16 seqOfTeam;
        uint40 userNo;
        uint8 state;
        uint32 rate; 
				uint32 workHours; // appliedAmt for Team / Project
        uint32 budgetAmt;
        uint32 approvedAmt;
        uint32 receivableAmt;
        uint32 paidAmt;
    }

    struct Team {
        EnumerableSet.UintSet membersList;
        mapping(uint256 => Member) members;
    }

    struct Repo {
        EnumerableSet.UintSet teamsList;
        mapping(uint256 => Team) teams;
        EnumerableSet.UintSet payroll;
        mapping(uint256 => uint256) cashBox;
    }

    modifier onlyManager(Repo storage repo, uint caller) {
        require(isManager(repo, caller),
            "TR.onlyManager: not");
        _;
    }

    modifier onlyListedTeam(
        Repo storage repo,
        uint seqOfTeam
    ) {
        require(teamIsListed(repo, seqOfTeam),
          "TR.onlyListedTeam: not");
        _;
    }
  
    modifier onlyTeamLeader(
        Repo storage repo, 
        uint caller,
        uint seqOfTeam
    ) {
        require(isTeamLeader(repo, caller, seqOfTeam),
            "TR.onlyLeader: not");
        _;
    }

    ///////////////////
    //   Write I/O   //
    ///////////////////

    function setManager(Repo storage repo, uint acct) public {
        repo.teams[0].members[0].userNo = uint40(acct);    
    }

    function transferProject(
        Repo storage repo,
        uint caller,
        uint newManager
    ) public onlyManager(repo, caller) {
        repo.teams[0].members[0].userNo = uint40(newManager);    
    }

    // ---- Project ----

    function setBudget(
        Repo storage repo,
        uint caller,
        uint budget
    ) public onlyManager(repo, caller) {
        Member storage info = repo.teams[0].members[0];
        require (info.state == 0, "TR.setBudget: already fixed");
        info.budgetAmt = uint32(budget);
    }

    function fixBudget(Repo storage repo, uint caller) 
			public onlyManager(repo, caller) 
		{
        Member storage info = repo.teams[0].members[0];
        require (info.state == 0, "TR.fixBudget: already fixed");
        info.state = 1;
    }

    function increaseBudget(
        Repo storage repo,
        uint caller,
				uint deltaAmt
    ) public onlyManager(repo, caller) {
        Member storage info = repo.teams[0].members[0];
        require (info.state > 0,
            "TR.increaseBudget: still pending");
				info.budgetAmt += uint32(deltaAmt);
    }

    // ---- Team ----

    function createTeam(
        Repo storage repo,
        uint caller,
        uint budget
    ) public {
				uint40 acct = uint40(caller);

        require(acct > 0, "TR.addTeam: zero leader");

        Member storage projInfo = 
            repo.teams[0].members[0];

        projInfo.seqOfTeam++;
				        
        Member storage teamInfo = 
						repo.teams[projInfo.seqOfTeam].members[0];

				teamInfo.seqOfTeam = projInfo.seqOfTeam;			
				teamInfo.userNo = acct;
				teamInfo.budgetAmt = uint32(budget);

				repo.teamsList.add(projInfo.seqOfTeam);
    }

    function updateTeam(
        Repo storage repo,
        uint caller,
        uint seqOfTeam,
        uint budget
    ) public onlyTeamLeader(repo, caller, seqOfTeam){

        Member storage teamInfo = 
            repo.teams[seqOfTeam].members[0];

        require(teamInfo.state == 0,
            "updateTeam: already approved");

				teamInfo.budgetAmt = uint32(budget);
    }

    function enrollTeam(
        Repo storage repo,
        uint caller,
        uint seqOfTeam
    ) public onlyManager(repo, caller) 
			onlyListedTeam(repo, seqOfTeam)	
		{
        Member storage projInfo = 
            repo.teams[0].members[0];
        
        Member storage teamInfo = 
            repo.teams[seqOfTeam].members[0];

				_enrollMember(projInfo, teamInfo);
    }

		function _enrollMember(
			Member storage teamInfo,
			Member storage member
		) private {
        require(member.state == 0,
            "enrollTeam: already enrolled");

        require(teamInfo.budgetAmt >= 
            (teamInfo.approvedAmt + member.budgetAmt),
            "enrollTeam: budget overflow");

        member.state = 1;
        teamInfo.approvedAmt += member.budgetAmt;
		}

    function replaceLeader(
        Repo storage repo,
        uint caller,
        uint seqOfTeam,
        uint leader
    ) public onlyManager(repo, caller) 
			onlyListedTeam(repo, seqOfTeam)
    {
				uint40 acct = uint40(leader);
				require(acct > 0,"TR.addTeam: zero leader");
				repo.teams[seqOfTeam].members[0].userNo = acct;
    }

    function increaseTeamBudget(
        Repo storage repo,
        uint caller,
        uint seqOfTeam,
				uint delta
    ) public onlyManager(repo, caller) 
        onlyListedTeam(repo, seqOfTeam)
    {
        Member storage projInfo = repo.teams[0].members[0];
        Member storage teamInfo = repo.teams[seqOfTeam].members[0];

				_increaseBudget(projInfo, teamInfo, delta);
    }

		function _increaseBudget(
			Member storage teamInfo,
			Member storage member,
			uint delta
		)	private {

			uint32 amt = uint32(delta);

			require (amt > 0, "TR.increaseBudget: Zero amt");
			
			require (teamInfo.budgetAmt >= teamInfo.approvedAmt + amt,
					"TR.increaseTeamBudget: budget overflow");
			
			member.budgetAmt += amt;
			teamInfo.approvedAmt += amt;
		}

    // ---- Member ----

    function enrollMember(
        Repo storage repo,
        uint caller,
        uint seqOfTeam,
        uint userNo,
        uint rate,
        uint budgetAmt
    ) public onlyTeamLeader(repo, caller, seqOfTeam) {    
        Team storage t = repo.teams[seqOfTeam];
        Member storage teamInfo = t.members[0];

				uint40 acct = uint40(userNo);
        require(acct > 0,
            "enrollMember: zero userNo");

        require(!t.membersList.contains(acct),
            "enrollMember: already enrolled");

        Member storage member = t.members[acct];

				member.seqOfTeam = teamInfo.seqOfTeam;
        member.userNo = acct;
				member.rate = uint32(rate);
				member.budgetAmt = uint32(budgetAmt);

				_enrollMember(teamInfo, member);				

        t.membersList.add(acct);
        repo.payroll.add(acct);
    }

		function removeMember(
				Repo storage repo,
				uint caller,
				uint seqOfTeam,
				uint userNo
		) public {

				(Member storage teamInfo, Member storage member) = 
						_getTeamInfoAndMember(repo, caller, seqOfTeam, userNo);
				
				require(member.state > 0,
						"removeMember: not enrolled");

				member.state = 0;

				teamInfo.approvedAmt -= (member.budgetAmt - member.receivableAmt);
				teamInfo.workHours -= (member.approvedAmt);
		}

		function _getTeamInfoAndMember(
				Repo storage repo,
				uint caller,
				uint seqOfTeam,
				uint userNo
		) private view returns(
				Member storage teamInfo,
				Member storage member 
		) {
				(teamInfo, member) = _getInfoAndMember(repo, seqOfTeam, userNo);
				require(teamInfo.userNo == caller, "not team leader");
		}

		function _getInfoAndMember(
				Repo storage repo,
				uint seqOfTeam,
				uint userNo
		) private view onlyListedTeam(repo, seqOfTeam) returns(
				Member storage teamInfo,
				Member storage member 
		) {				
				Team storage t = repo.teams[seqOfTeam];
				teamInfo = t.members[0];
				
				require(t.membersList.contains(userNo),
						"removeMember: not listed");

				member = t.members[userNo];
		}


		function restoreMember(
				Repo storage repo,
				uint caller,
				uint seqOfTeam,
				uint userNo
		) public {
			
				(Member storage teamInfo, Member storage member) = 
					_getTeamInfoAndMember(repo, caller, seqOfTeam, userNo);
				
				require(member.state == 0,
						"restoreMember: already enrolled");

				uint32 balance = (member.budgetAmt - member.receivableAmt);
				require(teamInfo.budgetAmt >= teamInfo.approvedAmt + balance,
						"enrollMember: budget overflow");
				teamInfo.budgetAmt += balance;

				if (member.approvedAmt > 0) {
					member.state = 2;
					teamInfo.workHours += member.approvedAmt;				
				} else {
					member.state = 1;
				}
		}

		function increaseMemberBudget(
				Repo storage repo,
				uint caller,
				uint seqOfTeam,
				uint userNo,
				uint delta
		) public {
			
				(Member storage teamInfo, Member storage member) =
						_getTeamInfoAndMember(repo, caller, seqOfTeam, userNo);

				require(member.state > 0,
						"increaseMemberBudget: not enrolled");

				_increaseBudget(teamInfo, member, delta);
		}

		function adjustSalary(
				Repo storage repo,
				uint caller,
				uint seqOfTeam,
				uint userNo,
				bool increase,
				uint delta
		) public {

				( , Member storage member) = 
						_getTeamInfoAndMember(repo, caller, seqOfTeam, userNo);

				require(member.state > 0,
						"adjustSalary: not enrolled");
				
				uint32 amt = uint32(delta);

				if (increase) {
					member.rate += amt;
				} else {
					require (member.rate >= amt, 
						"adjustSalary: insufficient amt");
					member.rate -= amt;
				}
		}

	  // ---- Work ----

		function applyWorkingHour(
				Repo storage repo,
				uint caller,
				uint seqOfTeam,
				uint hrs
		) public {

				(, Member storage member) = _getInfoAndMember(repo, seqOfTeam, caller);

				require(member.state == 1,
						"TR.applyHr: wrong state");

				uint32 delta = uint32(member.rate * hrs);

				require(member.budgetAmt >= member.receivableAmt + delta,
						"TR.applyHr: exceed budget");

				member.workHours += uint32(hrs);
				member.approvedAmt = delta;

				member.state = 2;
		}

		function verifyMemberWork(
				Repo storage repo,
				uint caller,
				uint seqOfTeam,
				uint userNo,
				uint ratio
		) public {
				require(ratio <= 10000, "TR.verifyHr: ratio overflow");

				(Member storage teamInfo, Member storage member) = 
					_getTeamInfoAndMember(repo, caller, seqOfTeam, userNo);

				require(member.state == 2, "TR.verifyHr: wrong state");

				member.approvedAmt = uint32(member.approvedAmt * ratio / 10000);
				member.state = 3;

				teamInfo.workHours += member.approvedAmt;
		}

		function verifyTeamWork(
				Repo storage repo,
				uint caller,
				uint seqOfTeam,
				uint ratio
		) public onlyManager(repo, caller) 
				onlyListedTeam(repo, seqOfTeam)
		{
				require(ratio <= 10000,
						"TR.verifyHr: ratio overflow");

				Team storage t = repo.teams[seqOfTeam];
				Member storage teamInfo = t.members[0];

				require(teamInfo.workHours > 0,
						"TR.approveTeamWork: zero applied");

				uint32 deltaAmt = uint32(teamInfo.workHours * ratio / 10000);
				teamInfo.receivableAmt += deltaAmt;

				Member storage proInfo = repo.teams[0].members[0];
				proInfo.receivableAmt += deltaAmt;

				_confirmTeamWork(t, ratio);

				teamInfo.workHours = 0;
		}

		function _confirmTeamWork(
				Team storage t,
				uint ratio
		) private {
				uint[] memory ls = t.membersList.values();
				uint len = ls.length;

				while (len > 0) {
						Member storage m = t.members[ls[len-1]];
						if (m.state == 3) {
								m.receivableAmt += uint32(m.approvedAmt * ratio / 10000);
								m.approvedAmt = 0;
								m.state = 1;
						}
						len--;
				}
		}

		function distributePayment(
				Repo storage repo,
				uint amtInWei,
				uint centPriceInWei
		) public {

				uint[] memory ls = repo.teamsList.values();
				uint len = ls.length;
		
				Member storage projInfo = repo.teams[0].members[0];
		
				uint rate = amtInWei * 10000 / (projInfo.receivableAmt - projInfo.paidAmt);
				uint32 sum = 0;

				while (len > 0) {
						Team storage t = repo.teams[ls[len-1]];
						Member storage info = t.members[0];
						
						if (info.receivableAmt > info.paidAmt) {
								uint32 amt = _distributePackage(repo, t, rate, centPriceInWei);
								info.paidAmt += amt;	
								sum += amt;
						}
						
						len--;
				}

				projInfo.paidAmt += sum;
				repo.cashBox[0] += amtInWei;
		}

		function _distributePackage(
				Repo storage repo,
				Team storage t,
				uint rate,
				uint centPriceInWei
		) private returns (uint32 sum) {
				uint[] memory ls = t.membersList.values();
				uint len = ls.length;
				sum = 0;

				while (len > 0) {
						Member storage m = t.members[ls[len-1]];

						uint outstandingAmt = m.receivableAmt - m.paidAmt;

						if (outstandingAmt > 0) {
								uint amt = rate * outstandingAmt / 10000;

								repo.cashBox[m.userNo] += amt;

								uint32 amtFiat = uint32((amt * 10 / centPriceInWei + 5)/10);

								m.paidAmt += amtFiat;
								sum += amtFiat;
						}

						len--;
				}
		}

		function pickupDeposit(
				Repo storage repo,
				uint caller,
				uint amt
		) public {
				require (repo.payroll.contains(caller),
						"TR.pickupDeposit: not in payroll");

				uint balance = repo.cashBox[caller];

				require (balance >= amt,
						"TR.pickupDeposit: insufficient balance");
				
				repo.cashBox[caller] -= amt;
				repo.cashBox[0] -= amt;
		}

		///////////////////
		//   Read I/O    //
		///////////////////

		function isManager(
				Repo storage repo,
				uint acct
		) public view returns(bool) {
				return acct > 0 &&
						repo.teams[0].members[0].userNo == acct;
		}

		function getProjectInfo(
				Repo storage repo
		) public view returns(Member memory info) {
				info = repo.teams[0].members[0];
		}

		// ---- Teams ----

		function qtyOfTeams (
				Repo storage repo
		) public view returns(uint) {
				return repo.teams[0].members[0].seqOfTeam;
		}

		function getListOfTeams(
				Repo storage repo
		) public view returns(uint[] memory) {
				return repo.teamsList.values();
		}

		function teamIsListed(
				Repo storage repo,
				uint seqOfTeam
		) public view returns(bool) {
				return repo.teamsList.contains(seqOfTeam);
		}

		function teamIsEnrolled(
				Repo storage repo,
				uint seqOfTeam
		) public view returns(bool) {
				return repo.teamsList.contains(seqOfTeam) &&
						repo.teams[seqOfTeam].members[0].state == 1;
		}

		// ---- TeamInfo ----

		function isTeamLeader(
				Repo storage repo,
				uint acct,
				uint seqOfTeam
		) public view returns(bool) {
				return repo.teamsList.contains(seqOfTeam) &&
						repo.teams[seqOfTeam].members[0].userNo == acct;
		}

		function getTeamInfo(
				Repo storage repo,
				uint seqOfTeam
		) public view returns(Member memory info) {
				if (repo.teamsList.contains(seqOfTeam)) {
					info = repo.teams[seqOfTeam].members[0];
				}
		}

		// ---- Member ----

		function isMember(
				Repo storage repo,
				uint acct,
				uint seqOfTeam
		) public view  returns (bool) {
				return repo.teamsList.contains(seqOfTeam) &&
						repo.teams[seqOfTeam].membersList.contains(acct);
		}

		function isEnrolledMember(
				Repo storage repo,
				uint acct,
				uint seqOfTeam
		) public view returns (bool) {
				return repo.teamsList.contains(seqOfTeam) &&
					repo.teams[seqOfTeam].membersList.contains(acct) &&
					repo.teams[seqOfTeam].members[acct].state > 0;
		}

		function getTeamMembersList(
				Repo storage repo,
				uint seqOfTeam
		) public view returns (uint[] memory ls) {
				if (repo.teamsList.contains(seqOfTeam)) {
					ls = repo.teams[seqOfTeam].membersList.values();
				}
		}

		function getMemberInfo(
				Repo storage repo,
				uint acct,
				uint seqOfTeam
		) public view returns (Member memory m) {

				if (repo.teamsList.contains(seqOfTeam) &&
						repo.teams[seqOfTeam].membersList.contains(acct)
				) {
					m = repo.teams[seqOfTeam].members[acct];
				}
		}

		function getMembersOfTeam(Repo storage repo,uint seqOfTeam) 
				public view returns (Member[] memory) 
		{
				uint[] memory ls = getTeamMembersList(repo, seqOfTeam);
				uint len = ls.length;
				Member[] memory output = new Member[](len);
				
				Team storage t = repo.teams[seqOfTeam];

				while (len > 0) {
						output[len-1] = t.members[ls[len-1]];
						len--;
				}

				return output;
		}

		// ---- Payroll ----

		function getPayroll(
				Repo storage repo
		) public view returns (uint[] memory list) {
				return repo.payroll.values();
		}

		function inPayroll(
				Repo storage repo,
				uint acct
		) public view returns(bool) {
				return repo.payroll.contains(acct);
		}

		function getBalanceOf(
				Repo storage repo,
				uint acct
		) public view returns(uint) {
				return repo.cashBox[acct];
		}
}