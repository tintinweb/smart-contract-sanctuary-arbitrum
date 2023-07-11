/**
 *Submitted for verification at Arbiscan on 2023-07-11
*/

/*

FFFFF  TTTTTTT  M   M         GGGGG  U    U  RRRRR     U    U
FF       TTT   M M M M       G       U    U  RR   R    U    U
FFFFF    TTT   M  M  M      G  GGG   U    U  RRRRR     U    U
FF       TTT   M  M  M   O  G    G   U    U  RR R      U    U
FF       TTT   M     M       GGGGG    UUUU   RR  RRR    UUUU



						Contact us at:
			https://discord.com/invite/QpyfMarNrV
					https://t.me/FTM1337

	Community Mediums:
		https://medium.com/@ftm1337
		https://twitter.com/ftm1337

	SPDX-License-Identifier: UNLICENSED


	ElRamses_Depositor.sol

	El Ramses is a Liquid Staking Derivate for veRAM (Vote-Escrowed Ramses NFT).
	It can be minted by burning (veRAM) veNFTs.
	El Ramses adheres to the EIP20 Standard.
	It can be staked with Guru Network to earn pure ETH instead of multiple small tokens.
	El Ramses can be further deposited into Kompound Protocol to mint ibRAM.
	ibRAM is a doubly-compounding interest-bearing veRAM at its core.
	ibRAM uses ElRamses's ETH yield to buyback more El Ramses from the open-market via JIT Aggregation.
	The price (in RAM) to mint El Ramses goes up every epoch due to positive rebasing.
	This property gives ibRAM a "hyper-compounding" double-exponential trajectory against raw RAM tokens.
	ELR is the market ticker for El Ramses.
	Price of 1 ELR is NOT dependent upon the price of RAM.

*/

pragma solidity ^0.8.17;

interface IERC20 {
	function totalSupply() external view returns (uint256);
	function transfer(address recipient, uint amount) external returns (bool);
	function balanceOf(address) external view returns (uint);
	function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}
interface IELR is IERC20 {
	function mint(address w, uint a) external returns (bool);
}
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
interface IVotingEscrow {
	struct LockedBalance {
		int128 amount;
		uint end;
	}
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function locked(uint id) external view returns(LockedBalance memory);
	function token() external view returns (address);
	function merge(uint _from, uint _to) external;
}

contract ElRamses_Depositor {
	struct LockedBalance {
		int128 amount;
		uint end;
	}
	bool internal _locked;
	address public dao;
	address public vault_veram;
	address public vault_xram;
	address public vault_ram;
	address public vault_elr;
	IELR public ELR;
	IVotingEscrow public veRAM;
	IERC20 public XRAM;
	IERC20 public RAM;
	uint public ID = 2985;
	uint public supplied;
	uint public converted_veram;
	uint public converted_xram;
	uint public converted_ram;
	uint public minted;
	uint public fees_generated;
	/*
	 *	1 xram -> 0.8 veram ; 1.25 xram -> 1 veram
	 *	1 xram -> 0.65 ram ; 1.538 xram -> 1 veram
	 */
	uint public fees_veram = 18_7500;
	uint public fees_xram = 35_0000;
	uint public fees_ram = 0;
	uint public price_veram = 1.28e18;
	uint public price_xram = 1.28e18;
	uint public price_ram = 1.28e18;
	uint public max_nft_size = 100_000 * 1e18;
	/// @notice ftm.guru simple re-entrancy check
	modifier lock() {
		require(!_locked,  "Re-entry!");
		_locked = true;
		_;
		_locked = false;
	}
	modifier DAO() {
		require(msg.sender==dao, "Unauthorized!");
		_;
	}
	event Deposit(address indexed, uint indexed, uint, uint, uint);
    function onERC721Received(address, address,  uint256, bytes calldata) external view returns (bytes4) {
        require(msg.sender == address(veRAM), "!veToken");
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
	function deposit_ram(uint _inc) public lock returns (uint) {
		RAM.transferFrom(msg.sender, vault_ram, _inc);
		supplied += _inc;
		converted_ram += _inc;
		// Calculate and mint the amount of ELR the veNFT is worth. The ratio will change overtime,
		// as ELR is minted when veRAM are deposited + gained from rebases
		//uint256 _amt = (_inc * _ts) / _main.amount;
		uint _amt = _inc * 1e18 / price_ram;
		uint _mint = _amt * (1e6 - fees_ram) / 1e6;
		ELR.mint(msg.sender, _mint);
		if(fees_ram > 0) {
			ELR.mint(vault_elr, _amt - _mint);
			fees_generated += (_amt - _mint);
		}
		emit Deposit(msg.sender, 0, _inc, _amt, _mint);
		minted+=_amt;
		return _mint;
	}
	function deposit_xram(uint _inc) public lock returns (uint) {
		XRAM.transferFrom(msg.sender, vault_xram, _inc);
		supplied += _inc;
		converted_xram += _inc;
		// Calculate and mint the amount of ELR the veNFT is worth. The ratio will change overtime,
		// as ELR is minted when veRAM are deposited + gained from rebases
		//uint256 _amt = (_inc * _ts) / _main.amount;
		uint _amt = _inc * 1e18 / price_xram;
		uint _mint = _amt * (1e6 - fees_xram) / 1e6;
		ELR.mint(msg.sender, _mint);
		if(fees_xram > 0) {
			ELR.mint(vault_elr, _amt - _mint);
			fees_generated += (_amt - _mint);
		}
		emit Deposit(msg.sender, 2, _inc, _amt, _mint);
		minted+=_amt;
		return _mint;
	}
	function deposit(uint _id) public returns (uint) { return deposit_veram(_id); }
	function deposit_veram(uint _id) public lock returns (uint) {
		//self.checks
		//uint _ts = ELR.totalSupply();
		//require(_ts > 0, "Uninitialized!");
		IVotingEscrow.LockedBalance memory _main = veRAM.locked(ID);
		require(_main.amount > 0 && _main.end > block.timestamp, "Stale veNFT!");

		uint256 _inc;
		IVotingEscrow.LockedBalance memory _user = veRAM.locked(_id);
		if( _fungify(_main, _user, _id) ) {
			veRAM.safeTransferFrom(msg.sender, address(this), _id);
			veRAM.merge(_id,ID);
			IVotingEscrow.LockedBalance memory _merged = veRAM.locked(ID);
			int _in = _merged.amount - _main.amount;
			require(_in > 0, "Dirty Deposit!");
			_inc = uint256(_in);//cast to uint
		}
		else { _inc = _int128_uint256(_user.amount); }
		supplied += _inc;
		converted_veram++;
		// Calculate and mint the amount of ELR the veNFT is worth. The ratio will change overtime,
		// as ELR is minted when veRAM are deposited + gained from rebases
		//uint256 _amt = (_inc * _ts) / _main.amount;
		uint _amt = _inc * 1e18 / price_veram;
		uint _mint = _amt * (1e6 - fees_veram) / 1e6;
		ELR.mint(msg.sender, _mint);
		if(fees_veram > 0) {
			ELR.mint(vault_elr, _amt - _mint);
			fees_generated += (_amt - _mint);
		}
		emit Deposit(msg.sender, _id, _inc, _amt, _mint);
		minted+=_amt;
		return _mint;
	}

	function _fungify(
		IVotingEscrow.LockedBalance memory _main,
		IVotingEscrow.LockedBalance memory _user,
		uint256 _id
	) internal returns(bool) {
		if( _int128_uint256(_user.amount) > max_nft_size) {
			veRAM.safeTransferFrom( msg.sender, vault_veram, _id);
			return false;
		}
		if( _int128_uint256(_main.amount) > max_nft_size) {
			//veRAM.safeTransferFrom( address(this), dao, ID);
			veRAM.safeTransferFrom( msg.sender, vault_veram, _id);
			ID = _id;
			return false;
		}
		else { return true; }
	}

	function quote(uint _id) public view returns (uint) { return quote_veram(_id); }
	function quote_veram(uint _id) public view returns (uint) {
		IVotingEscrow.LockedBalance memory _user = veRAM.locked(_id);
		return ( ( _int128_uint256(_user.amount) * 1e18 / price_veram) * (1e6 - fees_veram) ) / 1e6;
	}
	function quote_xram(uint _amt) public view returns (uint) {
		return ( ( _amt * 1e18 / price_xram) * (1e6 - fees_xram) ) / 1e6;
	}
	function quote_ram(uint _amt) public view returns (uint) {
		return ( ( _amt * 1e18 / price_ram) * (1e6 - fees_ram) ) / 1e6;
	}
	function rawQuote_veram(uint _inc) public view returns (uint) {
		return ( (_inc * 1e18 / price_veram) * (1e6 - fees_veram) ) / 1e6;
	}
	function rawQuote_xram(uint _inc) public view returns (uint) {
		return ( (_inc * 1e18 / price_xram) * (1e6 - fees_xram) ) / 1e6;
	}
	function rawQuote_ram(uint _inc) public view returns (uint) {
		return ( (_inc * 1e18 / price_ram) * (1e6 - fees_ram) ) / 1e6;
	}
	function price() public view returns (uint) {
		return price_ram;
	}
	function setDAO(address d) public DAO {
		dao = d;
	}
	function setID(uint _id) public DAO {
		ID = _id;
	}
	function rescue20(address _t, uint _a) public DAO lock {
		IERC20 _tk = IERC20(_t);
		_tk.transfer(dao, _a);
	}
	function rescue721(address _t, uint _a) public DAO lock {
		IVotingEscrow _tk = IVotingEscrow(_t);
		_tk.safeTransferFrom(address(this), dao, _a);
	}
	function setFees(uint _v, uint _x, uint _r) public DAO {
		require(_v<=1e6,"EF1");
		require(_x<=1e6,"EF2");
		require(_r<=1e6,"EF3");
		fees_veram = _v;
		fees_xram = _x;
		fees_ram = _r;
	}
	function setPrice(uint _v, uint _x, uint _r) public DAO {
		require(_v*_x*_r>0,"EP1");
		price_veram = _v;
		price_xram = _x;
		price_ram = _r;
	}
	function setVaults(address _v, address _x, address _r, address _e) public DAO {
		require(_v!=address(0),"EV1");
		require(_x!=address(0),"EV2");
		require(_r!=address(0),"EV3");
		require(_e!=address(0),"EV4");
		vault_veram = _v;
		vault_xram = _x;
		vault_ram = _r;
		vault_elr = _e;
	}
	constructor(address ve, address x, address e, address f) {
		dao=msg.sender;
		veRAM = IVotingEscrow(ve);
		XRAM = IERC20(x);
		RAM = IERC20(IVotingEscrow(ve).token());
		ELR = IELR(e);
		vault_veram = msg.sender;
		vault_xram = msg.sender;
		vault_ram = msg.sender;
		vault_elr = f;//fees
	}

	///////// Utils
	function _int128_uint256(int128 _n) internal pure returns(uint256) {
		int _i = _n;
		return uint256(_i);
	}
}

/*
	Community, Services & Enquiries:
		https://discord.gg/QpyfMarNrV

	Powered by Guru Network DAO ( 🦾 , 🚀 )
		Simplicity is the ultimate sophistication.
*/