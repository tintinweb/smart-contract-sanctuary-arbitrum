// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns(bool);
    function balanceOf(address account) external view returns(uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
    function allowance(address owner, address spender) external view returns(uint256);
}

contract Vesting {

	struct VestingSchedule {
  	uint256 unlockAt;
  	uint256 amount;
  	bool isClaimed;
  	}

	address public owner;
	IERC20 public pingu = IERC20(0x906fdAeBD56945362e38D8FBA1277793f7cEC95a);

	mapping(address => VestingSchedule[]) public vestingSchedules;

	modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

	constructor() {
		owner = msg.sender;
	}

	function setVestingSchedules(address[] memory addresses, uint256[] memory unlockAts, uint256[] memory amounts) external onlyOwner {
		require(addresses.length == unlockAts.length && unlockAts.length == amounts.length, "Invalid input");
		for (uint i = 0; i < addresses.length; i++) {
			vestingSchedules[addresses[i]].push(VestingSchedule(unlockAts[i], amounts[i], false));
		}
	}

	function getVestingSchedules(address account) external view returns (VestingSchedule[] memory) {
        return vestingSchedules[account];
    }

	function removeVestingSchedule(address account) external onlyOwner {
        delete vestingSchedules[account];
    }

	function removeAllVestingSchedules(address[] memory addresses) external onlyOwner {
		for (uint i = 0; i < addresses.length; i++) {
			delete vestingSchedules[addresses[i]];
		}
	}

	function claim() external {
		VestingSchedule[] storage schedules = vestingSchedules[msg.sender];
		for (uint j = 0; j < schedules.length; j++) {
			if (block.timestamp >= schedules[j].unlockAt && !schedules[j].isClaimed) {
				require(pingu.transfer(msg.sender, schedules[j].amount), "Transfer failed");
				schedules[j].isClaimed = true;
			}
		}
	}

	function withdrawToken(address _tokenAddress) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        uint256 contractTokenBalance = token.balanceOf(address(this));
        require(contractTokenBalance > 0, "Insufficient balance");
        require(token.transfer(msg.sender, contractTokenBalance), "Withdrawal failed");
    }

}