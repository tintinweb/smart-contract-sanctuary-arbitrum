/**
 *Submitted for verification at Arbiscan.io on 2024-05-06
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


	eTHENA.sol

	eTHENA is a Liquid Staking Derivate for veTHE (Vote-Escrowed Thena NFT).
	It can be minted by burning (veTHE) veNFTs.
	eTHENA is an ERC20 based token.
	It can be staked with Guru Network to earn pure BNB instead of multiple small tokens.
	eTHENA can be further deposited into Kompound Protocol to mint iTHENA.

	iTHENA is a doubly-compounding interest-bearing veTHE at its core.
	iTHENA is an ERC4626 based token, which also adheres to the EIP20 Standard.
	iTHENA uses eTHENA's BNB yield to buyback more eTHENA from the open-market via JIT Aggregation.

	The price (in THE) to mint eTHENA goes up every epoch due to positive rebasing.
	This property gives iTHENA a "hyper-compounding" double-exponential trajectory against raw THE tokens.

*/

pragma solidity 0.8.9;

interface IERC20 {
	function totalSupply() external view returns (uint256);
	function balanceOf(address) external view returns (uint);
	function allowance(address, address) external view returns (uint);
	function transfer(address recipient, uint amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint amount) external returns (bool);
	function burn(uint amount) external;
	function mint(address w, uint a) external returns (bool); // ETHENA
	///function mint(uint amount, address to) external returns (bool); // ELRETRO
}
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
interface IVotingEscrow {
	struct LockedBalance {
		int128 amount;
		uint end;
	}
	function balanceOf(address) external view returns (uint);
    function locked(uint id) external view returns(LockedBalance memory);
	function token() external view returns (address);
	function tokenOfOwnerByIndex(address _owner, uint _tokenIndex) external view returns (uint);
	// function getVotes(address) external view returns (uint);
	function totalSupply() external view returns (uint256);
	function isApprovedOrOwner(address, uint) external view returns (bool);

	function create_lock_for(uint _value, uint _lock_duration, address _to) external returns (uint);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
	function merge(uint _from, uint _to) external;
	function setApprovalForAll(address _who, bool _give) external;
	//function split(uint[] memory amounts, uint _tokenId) external;
	function split(uint nft, uint removalAmount) external returns(uint newNft);
}
interface IVoter {
	function _ve() external view returns (address);
	function poolVoteLength(uint256) external view returns (uint256);
	function poolVote(uint256, uint256) external view returns (address);
	function votes(uint256, address) external view returns (uint256);
	function lastVoted(uint256) external view returns (uint256);

	function reset(uint256) external;
	function vote(uint256, address[] memory, uint256[] memory) external;
	//function claimBribes(address[] memory _bribes, address[][] memory _tokens, uint _tokenId) external;
}
interface IGuruFarmland {
	function totalSupply() external view returns (uint256);
	function balanceOf(address) external view returns (uint);
	function tvl() external view returns (uint256);
	function tvlDeposits() external view returns (uint256);
	function apr() external view returns (uint256);
	function getAssetPrice(address) external view returns (uint256);
	function stake() external view returns (address);
	function stakingToken() external view returns (address);
	function want() external view returns (address);
	function asset() external view returns (address);
}
interface IRebase {
	function claim(uint256) external;
}
interface IRedemptions {
	function reclaim(address _sendTo, uint _nftId) external;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract elTokenManager {
	///////////// DONT EDIT /////////////
	struct LockedBalance {
		int128 amount;
		uint end;
	}
	///////////// DONT EDIT /////////////
	bool internal _locked; /// @notice ftm.guru simple re-entrancy check
	bool public paused;
	///////////// DONT EDIT /////////////
	uint public ID;
	address public dao;
	///////////// DONT EDIT /////////////
	IERC20 public ELTOKEN;
	IVotingEscrow public VENFT;
	IVoter public VOTER;
	///////////// DONT EDIT /////////////
	mapping(address => bool) public voteManager;
	mapping(uint256 => address[]) public votedPools;
	mapping(uint256 => uint[]) public votedWeights;
	///////////// DONT EDIT /////////////
	uint public votedTime;
	uint public redeemFeesToDao;
	uint public redeemFeesToBurn;
	uint public mintFeesToDao;
	uint public mintFeesToBurn;
	uint public floor;
	///////////// DONT EDIT /////////////
	IRebase public REBASE;
	IRedemptions public REDEMPTIONS;
	mapping(address => uint[]) public pendingRedemptions;
	///////////// DONT EDIT /////////////
	///////////// DONT EDIT /////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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
	modifier OnlyVoteManagers() {
		require(voteManager[msg.sender], "Unauthorized Voter!");
		_;
	}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	event Deposit(address indexed user, uint nft, uint veAmount, uint shares, uint wen);
	event Withdraw(address indexed user, uint nft, uint veAmount, uint shares, uint wen);
	event Reclaim(address indexed user, uint nft);

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function onERC721Received(address, address,  uint256, bytes calldata) external view returns (bytes4) {
        require(msg.sender == address(VENFT), "!veToken");
        require(_locked, "unwanted");
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

	function initialize(address _vo, address _el, uint _id, IRedemptions _r) external lock {
		require(dao == address(0));
		dao = msg.sender;
		voteManager[msg.sender] = true;
		VOTER = IVoter(_vo);
		VENFT = IVotingEscrow(VOTER._ve());
		ELTOKEN = IERC20(_el);
		ID = _id;
		REDEMPTIONS = _r;
		mintFeesToDao = 0.1 ether;
		mintFeesToBurn = 0.1 ether; // recompounded
		redeemFeesToDao = 0.1 ether;
		redeemFeesToBurn = 0.1 ether; // recompounded
		floor = 2.7e6 ether;
		if(ELTOKEN.totalSupply() == 0) {
			IVotingEscrow.LockedBalance memory _main = VENFT.locked(_id);
			require(_main.amount > 0, "Dirty veNFT!");
			int _iamt = _main.amount;
			uint _amt = uint(_iamt);
			///ELTOKEN.mint(msg.sender, _amt); // ETHENA
			///ELTOKEN.mint(_amt, msg.sender); // ELRETRO
			uint _uamt = _mintDeposit(msg.sender, _amt); // ELRAMSES
			emit Deposit(msg.sender, _id, _amt, _uamt, block.timestamp);
		}
	}

	function deposit(uint _id) external lock returns (uint) {
		require(!paused,"paused");
		{
			REBASE.claim( ID); // self
			REBASE.claim(_id); // user
		}
		uint _ts = ELTOKEN.totalSupply();
		IVotingEscrow.LockedBalance memory _main = VENFT.locked(ID);
		require(_main.amount > 0, "Dirty veNFT!");
		int _ibase = _main.amount;	//pre-cast to int
		uint256 _base = uint256(_ibase);
		VENFT.safeTransferFrom(msg.sender, address(this), _id);
		//VENFT.safeTransferFrom(dao, address(this), ID);
		VENFT.merge(_id,ID);
		//VENFT.safeTransferFrom(address(this), dao, ID);
		IVotingEscrow.LockedBalance memory _merged = VENFT.locked(ID);
		int _in = _merged.amount - _main.amount;
		require(_in > 0, "Dirty Deposit!");
		uint256 _inc = uint256(_in);//cast to uint
		// If no eTHENA exists, mint it 1:1 to the amount of THE present inside the veNFT deposited
		if (_ts == 0 || _base == 0) {
			///ELTOKEN.mint(msg.sender, _inc); // ETHENA
			///ELTOKEN.mint(_inc, msg.sender); // ELRETRO
			uint _uamt = _mintDeposit(msg.sender, _inc); // ELRAMSES
			emit Deposit(msg.sender, _id, _inc, _uamt, block.timestamp);
			// Carry forward old votes into new nft
			{
				//if(VOTER.poolVoteLength(ID) == 0) {
				if(_poolVoteLength(ID) == 0) {
					_revote();
				}
			}
			return _inc;
		}
		// Calculate and mint the amount of eTHENA the veNFT is worth. The ratio will change overtime,
		// as eTHENA is minted when veTHE are deposited + gained from rebases
		else {
			uint256 _amt = (_inc * _ts) / _base;
			///ELTOKEN.mint(msg.sender, _amt); // ETHENA
			///ELTOKEN.mint(_amt, msg.sender); // ELRETRO
			uint _uamt = _mintDeposit(msg.sender, _amt); // ELRAMSES
			emit Deposit(msg.sender, _id, _inc, _uamt, block.timestamp);
			// Carry forward old votes into new nft
			{
				//if(VOTER.poolVoteLength(ID) == 0) {
				if(_poolVoteLength(ID) == 0) {
					_revote();
				}
			}
			return _amt;
		}
	}

	function _mintDeposit(address _to, uint _elamt) internal returns(uint) {

		ELTOKEN.mint(address(this), _elamt);

		uint _toDao =  _elamt * mintFeesToDao / 1e18;		// _tamt = 1.00
		uint _toBurn = _elamt * mintFeesToBurn / 1e18;		// _burn = 0.05
		uint _toUser = _elamt - _toDao - _toBurn;			// _utamt = 1.00 - 0.10 - 0.05 = 0.85

		ELTOKEN.transfer(dao, _toDao);
		ELTOKEN.burn(_toBurn);
		ELTOKEN.transfer(_to, _toUser);

		return _toUser;
	}



	function withdraw(uint _tamt) external lock returns(uint) {
		require(!paused,"paused");
		REBASE.claim( ID); // self
		require(ELTOKEN.transferFrom(msg.sender, address(this), _tamt), "in folded");
		// first stamp tokens per share
		uint _ts = ELTOKEN.totalSupply();
		uint256 _base;
		{
			IVotingEscrow.LockedBalance memory _main = VENFT.locked(ID);
			require(_main.amount > 0, "Dirty veNFT!");
			int _ibase = _main.amount;	//pre-cast to int
			_base = uint256(_ibase);
		}
		require(_ts-_tamt > floor, "Too much drawn!");
		require(block.timestamp % 7 days    <=    6 days, "No Split on Wednesdays!");
		uint _utamt; // user input el token amount after fees
		// take fees
		{
			uint _dao = _tamt * redeemFeesToDao / 1e18;		// _tamt = 1.00
			uint _burn = _tamt * redeemFeesToBurn / 1e18;		// _burn = 0.05
			_utamt = _tamt - _dao - _burn;				// _utamt = 1.00 - 0.10 - 0.05 = 0.85
			ELTOKEN.transfer(dao, _dao);				// _dao = 0.10
			ELTOKEN.burn(_tamt - _dao);					// .burn(1.00 - 0.10) = .burn(0.90)
		}
		// split into two : [_ts-_utamt , _utamt]
		{
			VOTER.reset(ID);
			VENFT.safeTransferFrom(dao, address(this), ID);
			require(VENFT.balanceOf(address(this)) == 1, "unexpected balance!");
			/*
			uint[] memory _splitRatios = new uint[](2);
			_splitRatios[0] = _ts-_utamt;
			_splitRatios[1] = _utamt;
			VENFT.split( _splitRatios, ID);
			*/
			uint _userVe = _base * _utamt / _ts ;
			uint _userNft = VENFT.split( ID, _userVe);
			// fees accrued into first, user gets second

			require(ID == VENFT.tokenOfOwnerByIndex(address(this), 0) , "2split");
			VENFT.safeTransferFrom(address(this), dao, ID);
			/// We cant vote in the same block, so defer actual claim to a new tx in new future block
			/// VENFT.safeTransferFrom(address(this), msg.sender, _newID + 1);
			/// // Carry forward old votes into new dao nft
			/// _revote();
			pendingRedemptions[msg.sender].push(_userNft);
			VENFT.safeTransferFrom(address(this), address(REDEMPTIONS), _userNft);
			/*
			int _uvi = VENFT.locked(_newID + 1).amount;
			uint _uv = uint256(_uvi);
			*/
			emit Withdraw(msg.sender, _userNft, _userVe, _tamt, block.timestamp);
			return _userVe;
		}
	}

	function reclaim() external {
		uint _lv = pendingRedemptions[msg.sender].length;
		require(_lv > 0, "no pending redemptions!");
		for(uint i; i<_lv; i++) {
			uint _pn = pendingRedemptions[msg.sender][i];
			REDEMPTIONS.reclaim( msg.sender, _pn );
			emit Reclaim(msg.sender, _pn);
		}
		delete pendingRedemptions[msg.sender];
		_revote();
	}

	function _revote() internal {
		uint _mi = ID;
		uint _ept = getCurrentEpoch();
		//uint _len = VOTER.poolVoteLength(_mi);
		uint _len = _poolVoteLength(_mi);
		uint _rlv = VOTER.lastVoted(_mi);
		uint _mlv = votedTime;

		if(_rlv==0) { // new nft : wont have root data
			if(votedPools[_ept].length > 0) { // use this epoch's cache if available
				VOTER.vote(_mi, votedPools[_ept], votedWeights[_ept]);
				votedTime = block.timestamp;
			}
			else {
				uint _len2 = votedPools[_ept - 1 weeks].length;
				if(_len2 > 0) { // else use last epoch's cache if available
					for(uint i; i<_len2; i++){
						votedPools[_ept].push(votedPools[_ept - 1 weeks][i]);
						votedWeights[_ept].push(votedWeights[_ept - 1 weeks][i]);
					}
					VOTER.vote(_mi, votedPools[_ept], votedWeights[_ept]);
					votedTime = block.timestamp;
				}
			}
		}
		else if(_rlv>0) { // old nft
			if(_rlv==_mlv) { // rootLastVote used manager
				if(_mlv>_ept && votedPools[_ept].length > 0) { // manager voted AND earlier this epoch
					return;
				}
				else if(_mlv > _ept - 1 weeks && votedPools[_ept - 1 weeks].length > 0) { // manager voted BUT last epoch
					for(uint i; i<_len; i++){
						votedPools[_ept].push(votedPools[_ept - 1 weeks][i]);
						votedWeights[_ept].push(votedWeights[_ept - 1 weeks][i]);
					}
					VOTER.vote(_mi, votedPools[_ept], votedWeights[_ept]);
					votedTime = block.timestamp;
				}
			}
			else if(_len>0) {
				// nuke stale cache
				delete votedPools[_ept];
				delete votedWeights[_ept];
				// generate new cache
				address[] memory _miPools = new address[](_len);
				uint[] memory _miWeights = new uint[](_len);
				for(uint i; i<_len; i++){
					_miPools[i] = VOTER.poolVote(_mi, i);
					_miWeights[i] = VOTER.votes(_mi, _miPools[i]);
					votedPools[_ept].push(_miPools[i]);
					votedWeights[_ept].push(_miWeights[i]);
				}
				VOTER.vote(_mi, _miPools, _miWeights);
				votedTime = block.timestamp;
			}
		}
		require(VOTER.lastVoted(_mi) >= _ept, "No votes!");
	}

	function _poolVoteLength(uint _id) internal view returns (uint _pvl) {
		for(uint i; ; i++) {
			try VOTER.poolVote(_id, i) returns (address) {
				_pvl++;
			}
			catch{
				return _pvl;
			}
		}
	}

	function voteReset() OnlyVoteManagers external lock {
		VOTER.reset(ID);
	}

	function vote(address[] memory _p, uint[] memory _w) OnlyVoteManagers external lock {
		require(_p.length==_w.length,"len mismatch");
		VOTER.vote(ID, _p, _w);
		uint _ept = getCurrentEpoch();
		delete votedPools[_ept];
		delete votedWeights[_ept];
		for(uint i; i< _p.length; i++) {
			votedPools[_ept].push(_p[i]);
			votedWeights[_ept].push(_w[i]);
		}
		votedTime = block.timestamp;
	}

	function voteFrom(uint _mi) OnlyVoteManagers external lock {
		//uint _len = VOTER.poolVoteLength(_mi);
		uint _len = _poolVoteLength(_mi);
		require( _len > 0, "Target hasnt voted!");
		address[] memory _miPools = new address[](_len);
		uint[] memory _miWeights = new uint[](_len);
		for(uint i; i<_len; i++){
			_miPools[i] = VOTER.poolVote(_mi, i);
			_miWeights[i] = VOTER.votes(_mi, _miPools[i]);
		}
		VOTER.vote(ID, _miPools, _miWeights);
		uint _ept = getCurrentEpoch();
		delete votedPools[_ept];
		delete votedWeights[_ept];
		for(uint i; i< _len; i++) {
			votedPools[_ept].push(_miPools[i]);
			votedWeights[_ept].push(_miWeights[i]);
		}
		votedTime = block.timestamp;
	}


	/*
	function claimBribes(address[] memory _bribes, address[][] memory _tokens, uint _tokenId) OnlyVoteManagers external lock {
		;
	}
	*/

	// if protocol becomes inactive, people can split off full ELTOKEN supply
	function publicPanic() external lock {
		if(votedTime + 6 weeks < block.timestamp) {
			floor = 1 ether;
		}
	}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	function rescue(address _t, uint _a) external DAO lock {
		IERC20 _tk = IERC20(_t);
		_tk.transfer(dao, _a);
	}
	function setDAO(address d) external DAO lock {
		require(d!=address(0), "d==0!");
		dao = d;
		VENFT.setApprovalForAll(dao, true);
	}
	function setVoteManager(address _m, bool _b) external DAO lock {
		voteManager[_m] = _b;
	}
	function setID(uint _id) external DAO lock {
		ID = _id;
	}
	function setFees(uint _md, uint _mb, uint _rd, uint _rb) external DAO lock {
		require(_md+_mb <= 0.5e18, "fee too high!");
		require(_rd+_rb <= 0.5e18, "fee too high!");
		mintFeesToDao = _md;
		mintFeesToBurn = _mb;
		redeemFeesToDao = _rd;
		redeemFeesToBurn = _rb;
	}
	function setFloor(uint _f) external DAO lock {
		floor = _f;
	}
	function setPaused(bool _p) external DAO lock {
		paused = _p;
	}
	function setRebase(IRebase _r) external DAO lock {
		REBASE = _r;
	}
	function setRedemptions(IRedemptions _r) external DAO lock {
		REDEMPTIONS = _r;
	}


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	function getCurrentEpoch() public view returns(uint) {
		return block.timestamp - (block.timestamp % 7 days);
	}

	function quote(uint _id) public view returns (uint) {
		uint _ts = ELTOKEN.totalSupply();
		IVotingEscrow.LockedBalance memory _main = VENFT.locked(ID);
		IVotingEscrow.LockedBalance memory _user = VENFT.locked(_id);
		if( ! (_main.amount > 0) ) {return 0;}
		int _ibase = _main.amount;	//pre-cast to int
		uint256 _base = uint256(_ibase);
		int _in = _user.amount;
		if( ! (_in > 0) ) {return 0;}
		uint256 _inc = uint256(_in);//cast to uint
		// If no eTHENA exists, mint it 1:1 to the amount of THE present inside the veNFT deposited
		if (_ts == 0 || _base == 0) {
			return _inc;
		}
		// Calculate and mint the amount of eTHENA the veNFT is worth. The ratio will change overtime,
		// as eTHENA is minted when veTHE are deposited + gained from rebases
		else {
			uint256 _amt = (_inc * _ts) / _base;
			return _amt;
		}
	}
	function rawQuote(uint _inc) public view returns (uint) {
		uint _ts = ELTOKEN.totalSupply();
		IVotingEscrow.LockedBalance memory _main = VENFT.locked(ID);
		if( ! (_main.amount > 0) ) {return 0;}
		int _ibase = _main.amount;	//pre-cast to int
		uint256 _base = uint256(_ibase);
		// If no eTHENA exists, mint it 1:1 to the amount of THE present inside the veNFT deposited
		if (_ts == 0 || _base == 0) {
			return _inc;
		}
		// Calculate and mint the amount of eTHENA the veNFT is worth. The ratio will change overtime,
		// as eTHENA is minted when veTHE are deposited + gained from rebases
		else {
			uint256 _amt = (_inc * _ts) / _base;
			return _amt;
		}
	}

	function price() public view returns (uint) {
		return 1e36 / rawQuote(1e18);
	}

	function getCurrentVote() public view returns (uint _id, uint _wen, address[] memory _pools, uint[] memory _wt) {
		return(ID, votedTime, votedPools[getCurrentEpoch()], votedWeights[getCurrentEpoch()]);
	}

	function getPreviousVote(uint _etime) public view returns (address[] memory _pools, uint[] memory _wt) {
		return(votedPools[_etime], votedWeights[_etime]);
	}

	function getApr(address _contract) public view returns(uint) {
		try IGuruFarmland(_contract).apr() returns(uint _apr) {
			return _apr;
		}
		catch {
			return 404;
		}
	}

	function getTvl(address _contract) public view returns(uint) {
		try IGuruFarmland(_contract).tvlDeposits() returns(uint _tvl) {
			return _tvl;
		}
		catch {
			try IGuruFarmland(_contract).tvl() returns(uint _tvl) {
				return _tvl;
			}
			catch {
				return 404;
			}
		}
	}

	function getAllowance(address _user, address _farm) public view returns(uint) {
		try IGuruFarmland(_farm).stakingToken() returns(address _st) {	// GuruMultiRewardFarmlands
			return IERC20(_st).allowance(_user, _farm);
		}
		catch {
			try IGuruFarmland(_farm).stake() returns(address _st) {	// GuruFarmland
				return IERC20(_st).allowance(_user, _farm);
			}
			catch {
				try IGuruFarmland(_farm).want() returns(address _st) {	// Kompound Protocol
					return IERC20(_st).allowance(_user, _farm);
				}
				catch {
					try IGuruFarmland(_farm).asset() returns(address _st) {	// EIP-4626
						return IERC20(_st).allowance(_user, _farm);
					}
					catch {
						return 404;	// idkbro
					}
				}
			}
		}
	}


	function info(
		address _user,
		address[] memory _farms,
		address[] memory _pricing
	)
	public
	view
	returns(
		uint[] memory, //uint[10] memory,
		address[] memory,
		uint[] memory,
		uint[] memory,
		uint[] memory
	) {

		uint[] memory _basics = new uint[]( 13 + (_pricing.length/2) + pendingRedemptions[_user].length);

		_basics[0] = ELTOKEN.balanceOf(_user);
		_basics[1] = ELTOKEN.totalSupply();
		_basics[2] = price();
		_basics[3] = block.timestamp % 7 days > 6 days ? ELTOKEN.totalSupply() : floor;
		_basics[4] = redeemFeesToDao;
		_basics[5] = redeemFeesToBurn;
		_basics[6] = ID;
		_basics[7] = uint(int256(VENFT.locked(ID).amount));
		_basics[8] = VENFT.totalSupply();
		_basics[9] = VENFT.locked(ID).end;
		_basics[10] = votedTime;
		_basics[11] = ELTOKEN.allowance(_user, address(this));
		_basics[12] = VENFT.balanceOf(_user);

		for(uint i; i < _pricing.length; i += 2) {
			_basics[13 + i/2] = IGuruFarmland(_pricing[i]).getAssetPrice(_pricing[i+1]);
		}

		for(uint i; i < pendingRedemptions[_user].length; i++) {
			_basics[13 + (_pricing.length/2) + i] = pendingRedemptions[_user][i];
		}


		uint[] memory _farm_info = new uint[](_farms.length * 5);

		for(uint i; i < _farms.length * 5; i += 5) {
			IGuruFarmland _farm = IGuruFarmland(_farms[i/5]);
			_farm_info[i  ] = _farm.balanceOf(_user);
			_farm_info[i+1] = _farm.totalSupply();
			_farm_info[i+2] = getTvl(_farms[i/5]);//_farm.tvlDeposits();
			_farm_info[i+3] = getApr(_farms[i/5]);//_farm.apr();
			_farm_info[i+4] = getAllowance(_user, _farms[i/5]);
		}


		uint _venfts = VENFT.balanceOf(_user);
		uint[] memory _venftUserData = new uint[](_venfts * 4);

		for(uint i; i < _venfts * 4; i += 4) {
			_venftUserData[i  ] = VENFT.tokenOfOwnerByIndex(_user,i/4);
			IVotingEscrow.LockedBalance memory _lb = VENFT.locked(_venftUserData[i]);
			_venftUserData[i+1] = uint(int256(_lb.amount));
			_venftUserData[i+2] = _lb.end;
			_venftUserData[i+3] = VENFT.isApprovedOrOwner(address(this), _venftUserData[i]) == true ? 1 : 0;
		}

		return (
			_basics,
			votedPools[getCurrentEpoch()],
			votedWeights[getCurrentEpoch()],
			_farm_info,
			_venftUserData
		);
		/*
		return (
			ELTOKEN.balanceOf(_user),
			ELTOKEN.totalSupply(),
			price(),
			floor,
			redeemFeesToDao,
			redeemFeesToBurn,
			ID,
			uint(int256(VENFT.locked(ID).amount)),
			VENFT.totalSupply(),
			votedTime,
			votedPools[getCurrentEpoch()],
			votedWeights[getCurrentEpoch()],
			_farm_bals,
			_farm_tots,
			_farm_tvls,
			_farm_aprs,
			_venft_nft_ids,
			_venft_amounts,
			_venft_unlocks
		);
		*/
	}
}

/*
	Community, Services & Enquiries:
		https://discord.gg/QpyfMarNrV

	Powered by Guru Network DAO ( 🦾 , 🚀 )
		Simplicity is the ultimate sophistication.
*/