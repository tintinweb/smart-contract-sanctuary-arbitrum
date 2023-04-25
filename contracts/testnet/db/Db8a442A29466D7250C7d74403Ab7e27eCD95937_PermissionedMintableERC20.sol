// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

interface IAuthority {
	/* ========== EVENTS ========== */

	event GovernorPushed(address indexed from, address indexed to);
	event GuardianPushed(address indexed to);
	event ManagerPushed(address indexed from, address indexed to);

	event GovernorPulled(address indexed from, address indexed to);
	event GuardianRevoked(address indexed to);
	event ManagerPulled(address indexed from, address indexed to);

	/* ========== VIEW ========== */

	function governor() external view returns (address);

	function guardian(address _target) external view returns (bool);

	function manager() external view returns (address);

	function pullManager() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../interfaces/IAuthority.sol";

error UNAUTHORIZED();

/**
 *  @title Contract used for access control functionality, based off of OlympusDao Access Control
 */
abstract contract AccessControl {
	/* ========== EVENTS ========== */

	event AuthorityUpdated(IAuthority authority);

	/* ========== STATE VARIABLES ========== */

	IAuthority public authority;

	/* ========== Constructor ========== */

	constructor(IAuthority _authority) {
		authority = _authority;
		emit AuthorityUpdated(_authority);
	}

	/* ========== GOV ONLY ========== */

	function setAuthority(IAuthority _newAuthority) external {
		_onlyGovernor();
		authority = _newAuthority;
		emit AuthorityUpdated(_newAuthority);
	}

	/* ========== INTERNAL CHECKS ========== */

	function _onlyGovernor() internal view {
		if (msg.sender != authority.governor()) revert UNAUTHORIZED();
	}

	function _onlyGuardian() internal view {
		if (!authority.guardian(msg.sender) && msg.sender != authority.governor()) revert UNAUTHORIZED();
	}

	function _onlyManager() internal view {
		if (msg.sender != authority.manager() && msg.sender != authority.governor())
			revert UNAUTHORIZED();
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "../libraries/AccessControl.sol";

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
contract PermissionedMintableERC20 is AccessControl {
	/*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

	event Transfer(address indexed from, address indexed to, uint256 amount);

	event Approval(address indexed owner, address indexed spender, uint256 amount);

	/*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

	string public name;

	string public symbol;

	uint8 public immutable decimals;

	/*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

	uint256 public totalSupply;

	mapping(address => uint256) public balanceOf;

	mapping(address => mapping(address => uint256)) public allowance;

	/*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

	uint256 internal immutable INITIAL_CHAIN_ID;

	bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

	mapping(address => uint256) public nonces;

	/*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

	constructor(
		string memory _name,
		string memory _symbol,
		uint8 _decimals,
		address _authority
	) AccessControl(IAuthority(_authority)) {
		name = _name;
		symbol = _symbol;
		decimals = _decimals;

		INITIAL_CHAIN_ID = block.chainid;
		INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
	}

	/*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

	function approve(address spender, uint256 amount) public virtual returns (bool) {
		allowance[msg.sender][spender] = amount;

		emit Approval(msg.sender, spender, amount);

		return true;
	}

	function transfer(address to, uint256 amount) public virtual returns (bool) {
		balanceOf[msg.sender] -= amount;

		// Cannot overflow because the sum of all user
		// balances can't exceed the max uint256 value.
		unchecked {
			balanceOf[to] += amount;
		}

		emit Transfer(msg.sender, to, amount);

		return true;
	}

	function transferFrom(address from, address to, uint256 amount) public virtual returns (bool) {
		uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

		if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

		balanceOf[from] -= amount;

		// Cannot overflow because the sum of all user
		// balances can't exceed the max uint256 value.
		unchecked {
			balanceOf[to] += amount;
		}

		emit Transfer(from, to, amount);

		return true;
	}

	/*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

	function permit(
		address owner,
		address spender,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) public virtual {
		require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

		// Unchecked because the only math done is incrementing
		// the owner's nonce which cannot realistically overflow.
		unchecked {
			bytes32 digest = keccak256(
				abi.encodePacked(
					"\x19\x01",
					DOMAIN_SEPARATOR(),
					keccak256(
						abi.encode(
							keccak256(
								"Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
							),
							owner,
							spender,
							value,
							nonces[owner]++,
							deadline
						)
					)
				)
			);

			address recoveredAddress = ecrecover(digest, v, r, s);

			require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

			allowance[recoveredAddress][spender] = value;
		}

		emit Approval(owner, spender, value);
	}

	function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
		return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
	}

	function computeDomainSeparator() internal view virtual returns (bytes32) {
		return
			keccak256(
				abi.encode(
					keccak256(
						"EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
					),
					keccak256(bytes(name)),
					keccak256("1"),
					block.chainid,
					address(this)
				)
			);
	}

	function mint(address to, uint256 amount) external returns (bool) {
		_onlyGovernor();
		_mint(to, amount);
	}

	/*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

	function _mint(address to, uint256 amount) internal virtual {
		totalSupply += amount;

		// Cannot overflow because the sum of all user
		// balances can't exceed the max uint256 value.
		unchecked {
			balanceOf[to] += amount;
		}

		emit Transfer(address(0), to, amount);
	}

	function _burn(address from, uint256 amount) internal virtual {
		balanceOf[from] -= amount;

		// Cannot underflow because a user's balance
		// will never be larger than the total supply.
		unchecked {
			totalSupply -= amount;
		}

		emit Transfer(from, address(0), amount);
	}
}