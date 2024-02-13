// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Metadata.sol";

/*
	X: https://twitter.com/ArbMates
	TG: https://t.me/ArbMatesPortal
*/

interface Receiver {
	function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns (bytes4);
}

interface Router {
	function WETH() external pure returns (address);
	function factory() external pure returns (address);
	function addLiquidityETH(address, uint256, uint256, uint256, address, uint256) external payable returns (uint256, uint256, uint256);
}

interface Factory {
	function createPair(address, address) external returns (address);
}


contract ArbMates {

	uint256 constant private UINT_MAX = type(uint256).max;
	uint256 constant private TOTAL_SUPPLY = 256;
	uint256 constant private LIQUIDITY_TOKENS = 105;
	Router constant private ROUTER = Router(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

	uint256 constant private M1 = 0x5555555555555555555555555555555555555555555555555555555555555555;
	uint256 constant private M2 = 0x3333333333333333333333333333333333333333333333333333333333333333;
	uint256 constant private M4 = 0x0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f;
	uint256 constant private H01 = 0x0101010101010101010101010101010101010101010101010101010101010101;
	bytes32 constant private TRANSFER_TOPIC = keccak256(bytes("Transfer(address,address,uint256)"));
	bytes32 constant private APPROVAL_TOPIC = keccak256(bytes("Approval(address,address,uint256)"));

	uint256 constant public MINT_COST = 0.05 ether;

	uint8 constant public decimals = 0;

	struct User {
		bytes32 mask;
		mapping(address => uint256) allowance;
		mapping(address => bool) approved;
	}

	struct Info {
		bytes32 salt;
		address pair;
		address owner;
		Metadata metadata;
		mapping(address => User) users;
		mapping(uint256 => address) approved;
		address[] holders;
	}
	Info private info;

	mapping(bytes4 => bool) public supportsInterface;

	event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
	event ERC20Transfer(bytes32 indexed topic0, address indexed from, address indexed to, uint256 tokens) anonymous;
	event Approval(address indexed owner, address indexed spender, uint256 indexed tokenId);
	event ERC20Approval(bytes32 indexed topic0, address indexed owner, address indexed spender, uint256 tokens) anonymous;
	event ApprovalForAll(address indexed owner, address indexed operator, bool approved);


	modifier _onlyOwner() {
		require(msg.sender == owner());
		_;
	}


	constructor(address owner) payable {
		require(msg.value > 0);
		info.owner = owner;
		info.metadata = new Metadata();
		supportsInterface[0x01ffc9a7] = true; // ERC-165
		supportsInterface[0x80ac58cd] = true; // ERC-721
		supportsInterface[0x5b5e139f] = true; // Metadata
		info.salt = keccak256(abi.encodePacked("Salt:", blockhash(block.number - 1)));
	}

	function setOwner(address _owner) external _onlyOwner {
		info.owner = _owner;
	}

	function setMetadata(Metadata _metadata) external _onlyOwner {
		info.metadata = _metadata;
	}

	function initialize() external {
		require(pair() == address(0x0));
		address _this = address(this);
		address _weth = ROUTER.WETH();
		info.users[_this].mask = bytes32(UINT_MAX);
		info.holders.push(_this);
		emit ERC20Transfer(TRANSFER_TOPIC, address(0x0), _this, TOTAL_SUPPLY);
		for (uint256 i = 0; i < TOTAL_SUPPLY; i++) {
			emit Transfer(address(0x0), _this, TOTAL_SUPPLY + i + 1);
		}
		_approveERC20(_this, address(ROUTER), LIQUIDITY_TOKENS);
		info.pair = Factory(ROUTER.factory()).createPair(_weth, _this);
		ROUTER.addLiquidityETH{value:_this.balance}(_this, LIQUIDITY_TOKENS, 0, 0, owner(), block.timestamp);
		_transferERC20(_this, 0xf723566Ab2c5706895195764b389C8cD969D6E72, 36); //10 to team, 26 to airdrop to cellmate holders
		_transferERC20(_this, owner(), 10); // 10 tokens to provide lp to wArbMates
	}

	function mint() external payable {
		uint256 _tokens = 1;

		require(tx.origin == msg.sender, "EOA only");

		address _this = address(this);
		uint256 _available = balanceOf(_this);
		require(_tokens <= _available);
		uint256 _cost = _tokens * MINT_COST;
		require(msg.value >= _cost);
		_transferERC20(_this, msg.sender, _tokens);
		payable(owner()).transfer(_cost);
		if (msg.value > _cost) {
			payable(msg.sender).transfer(msg.value - _cost);
		}
	}

	function approve(address _spender, uint256 _tokens) external returns (bool) {
		if (_tokens > TOTAL_SUPPLY && _tokens <= 2 * TOTAL_SUPPLY) {
			_approveNFT(_spender, _tokens);
		} else {
			_approveERC20(msg.sender, _spender, _tokens);
		}
		return true;
	}

	function setApprovalForAll(address _operator, bool _approved) external {
		info.users[msg.sender].approved[_operator] = _approved;
		emit ApprovalForAll(msg.sender, _operator, _approved);
	}

	function transfer(address _to, uint256 _tokens) external returns (bool) {
		_transferERC20(msg.sender, _to, _tokens);
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _tokens) external returns (bool) {
		if (_tokens > TOTAL_SUPPLY && _tokens <= 2 * TOTAL_SUPPLY) {
			_transferNFT(_from, _to, _tokens);
		} else {
			uint256 _allowance = allowance(_from, msg.sender);
			require(_allowance >= _tokens);
			if (_allowance != UINT_MAX) {
				info.users[_from].allowance[msg.sender] -= _tokens;
			}
			_transferERC20(_from, _to, _tokens);
		}
		return true;
	}

	function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
		safeTransferFrom(_from, _to, _tokenId, "");
	}

	function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public {
		_transferNFT(_from, _to, _tokenId);
		uint32 _size;
		assembly {
			_size := extcodesize(_to)
		}
		if (_size > 0) {
			require(Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) == 0x150b7a02);
		}
	}

	function bulkTransfer(address _to, uint256[] memory _tokenIds) external {
		_transferNFTs(_to, _tokenIds);
	}
	

	function owner() public view returns (address) {
		return info.owner;
	}

	function pair() public view returns (address) {
		return info.pair;
	}

	function holders() public view returns (address[] memory) {
		return info.holders;
	}

	function salt() external view returns (bytes32) {
		return info.salt;
	}

	function metadata() external view returns (address) {
		return address(info.metadata);
	}

	function name() external view returns (string memory) {
		return info.metadata.name();
	}

	function symbol() external view returns (string memory) {
		return info.metadata.symbol();
	}

	function tokenURI(uint256 _tokenId) public view returns (string memory) {
		return info.metadata.tokenURI(_tokenId);
	}

	function totalSupply() public pure returns (uint256) {
		return TOTAL_SUPPLY;
	}

	function maskOf(address _user) public view returns (bytes32) {
		return info.users[_user].mask;
	}

	function balanceOf(address _user) public view returns (uint256) {
		return _popcount(maskOf(_user));
	}

	function allowance(address _user, address _spender) public view returns (uint256) {
		return info.users[_user].allowance[_spender];
	}

	function ownerOf(uint256 _tokenId) public view returns (address) {
		unchecked {
			require(_tokenId > TOTAL_SUPPLY && _tokenId <= 2 * TOTAL_SUPPLY);
			bytes32 _mask = bytes32(1 << (_tokenId - TOTAL_SUPPLY - 1));
			address[] memory _holders = holders();
			for (uint256 i = 0; i < _holders.length; i++) {
				if (maskOf(_holders[i]) & _mask == _mask) {
					return _holders[i];
				}
			}
			return address(0x0);
		}
	}

	function getApproved(uint256 _tokenId) public view returns (address) {
		require(_tokenId > TOTAL_SUPPLY && _tokenId <= 2 * TOTAL_SUPPLY);
		return info.approved[_tokenId];
	}

	function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
		return info.users[_owner].approved[_operator];
	}

	function getToken(uint256 _tokenId) public view returns (address tokenOwner, address approved, string memory uri) {
		return (ownerOf(_tokenId), getApproved(_tokenId), tokenURI(_tokenId));
	}

	function getTokens(uint256[] memory _tokenIds) external view returns (address[] memory owners, address[] memory approveds, string[] memory uris) {
		uint256 _length = _tokenIds.length;
		owners = new address[](_length);
		approveds = new address[](_length);
		uris = new string[](_length);
		for (uint256 i = 0; i < _length; i++) {
			(owners[i], approveds[i], uris[i]) = getToken(_tokenIds[i]);
		}
	}


	function _approveERC20(address _owner, address _spender, uint256 _tokens) internal {
		info.users[_owner].allowance[_spender] = _tokens;
		emit ERC20Approval(APPROVAL_TOPIC, _owner, _spender, _tokens);
	}

	function _approveNFT(address _spender, uint256 _tokenId) internal {
		bytes32 _mask = bytes32(1 << (_tokenId - TOTAL_SUPPLY - 1));
		require(maskOf(msg.sender) & _mask == _mask);
		info.approved[_tokenId] = _spender;
		emit Approval(msg.sender, _spender, _tokenId);
	}
	
	function _transferERC20(address _from, address _to, uint256 _tokens) internal {
		unchecked {
			bytes32 _mask;
			uint256 _pos = 0;
			uint256 _count = 0;
			uint256 _n = uint256(maskOf(_from));
			uint256[] memory _tokenIds = new uint256[](_tokens);
			while (_n > 0 && _count < _tokens) {
				if (_n & 1 == 1) {
					_mask |= bytes32(1 << _pos);
					_tokenIds[_count++] = TOTAL_SUPPLY + _pos + 1;
				}
				_pos++;
				_n >>= 1;
			}
			require(_count == _tokens);
			require(maskOf(_from) & _mask == _mask);
			_transfer(_from, _to, _mask, _tokenIds);
		}
	}
	
	function _transferNFT(address _from, address _to, uint256 _tokenId) internal {
		unchecked {
			require(_tokenId > TOTAL_SUPPLY && _tokenId <= 2 * TOTAL_SUPPLY);
			bytes32 _mask = bytes32(1 << (_tokenId - TOTAL_SUPPLY - 1));
			require(maskOf(_from) & _mask == _mask);
			require(msg.sender == _from || msg.sender == getApproved(_tokenId) || isApprovedForAll(_from, msg.sender));
			uint256[] memory _tokenIds = new uint256[](1);
			_tokenIds[0] = _tokenId;
			_transfer(_from, _to, _mask, _tokenIds);
		}
	}
	
	function _transferNFTs(address _to, uint256[] memory _tokenIds) internal {
		unchecked {
			bytes32 _mask;
			for (uint256 i = 0; i < _tokenIds.length; i++) {
				_mask |= bytes32(1 << (_tokenIds[i] - TOTAL_SUPPLY - 1));
			}
			require(_popcount(_mask) == _tokenIds.length);
			require(maskOf(msg.sender) & _mask == _mask);
			_transfer(msg.sender, _to, _mask, _tokenIds);
		}
	}

	function _transfer(address _from, address _to, bytes32 _mask, uint256[] memory _tokenIds) internal {
		unchecked {
			require(_tokenIds.length > 0);
			for (uint256 i = 0; i < _tokenIds.length; i++) {
				if (getApproved(_tokenIds[i]) != address(0x0)) {
					info.approved[_tokenIds[i]] = address(0x0);
					emit Approval(address(0x0), address(0x0), _tokenIds[i]);
				}
				emit Transfer(_from, _to, _tokenIds[i]);
			}
			info.users[_from].mask ^= _mask;
			bool _from0 = maskOf(_from) == 0x0;
			bool _to0 = maskOf(_to) == 0x0;
			info.users[_to].mask |= _mask;
			if (_from0) {
				uint256 _index;
				address[] memory _holders = holders();
				for (uint256 i = 0; i < _holders.length; i++) {
					if (_holders[i] == _from) {
						_index = i;
						break;
					}
				}
				if (_to0) {
					info.holders[_index] = _to;
				} else {
					info.holders[_index] = _holders[_holders.length - 1];
					info.holders.pop();
				}
			} else if (_to0) {
				info.holders.push(_to);
			}
			require(maskOf(_from) & maskOf(_to) == 0x0);
			emit ERC20Transfer(TRANSFER_TOPIC, _from, _to, _tokenIds.length);
		}
	}


	function _popcount(bytes32 _b) internal pure returns (uint256) {
		uint256 _n = uint256(_b);
		if (_n == UINT_MAX) {
			return 256;
		}
		unchecked {
			_n -= (_n >> 1) & M1;
			_n = (_n & M2) + ((_n >> 2) & M2);
			_n = (_n + (_n >> 4)) & M4;
			_n = (_n * H01) >> 248;
		}
		return _n;
	}
}


contract Deploy {
	ArbMates immutable public arbmates;
	constructor() payable {
		arbmates = new ArbMates{value:msg.value}(msg.sender);
		arbmates.initialize();
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface CM {
	function salt() external view returns (bytes32);
}

contract Metadata {
	
	string public name = "ArbMates";
	string public symbol = "MATE";

	string constant private TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
	bytes3 constant private BG_COLOR = 0xd1d3dc;
	uint256 constant private PADDING = 2;

	struct Size {
		uint248 size;
		uint8 chance;
	}
	Size[] private sizes;

	struct Color {
		bytes3 primaryColor;
		bytes3 outlineColor;
		uint8 chance;
		string name;
	}
	Color[] private colors;

	CM immutable public arbmates;


	constructor() {
		arbmates = CM(msg.sender);

		// sizes
		sizes.push(Size(14, 120));
		sizes.push(Size(16, 80));
		sizes.push(Size(18, 50));
		sizes.push(Size(20, 20));
		sizes.push(Size(22, 10));
		sizes.push(Size(24, 5));
		
		// colors
		colors.push(Color(0x62B4F9, 0x3172A3, 100, "Azure Radiance"));
        colors.push(Color(0xBFA2DB, 0x7A5B8E, 75, "Lush Lavender"));
        colors.push(Color(0xFF9E58, 0xC76B34, 55, "Sunset Orange"));
        colors.push(Color(0xA0E8AF, 0x4A8D5A, 35, "Mint Dream"));
        colors.push(Color(0xF7A8B8, 0xB3727E, 25, "Rose Water"));
        colors.push(Color(0xFFD580, 0xCBA052, 15, "Golden Sunrise"));
        colors.push(Color(0x7EC8E3, 0x3B7CA5, 10, "Celestial Blue"));
        colors.push(Color(0xCA5FA1, 0x7A3657, 5, "Twilight Magenta"));
	}

	function tokenURI(uint256 _tokenId) external view returns (string memory) {
		unchecked {
			( , uint256 _size, uint256 _colorIndex) = _getTokenInfo(_tokenId);
			string memory _json = string(abi.encodePacked('{"name":"Arb Cell #', _uint2str(_tokenId), '","description":"The first ERC20721 on Arbitrum. Onchain and randomly generated.  Inspired by CellMates.",'));
			_json = string(abi.encodePacked(_json, '"image":"', svgURI(_tokenId), '","attributes":['));
			_json = string(abi.encodePacked(_json, '{"trait_type":"Size","value":', _uint2str(_size - 2 * PADDING), '},'));
			_json = string(abi.encodePacked(_json, '{"trait_type":"Color","value":"', colors[_colorIndex].name, '"}'));
			_json = string(abi.encodePacked(_json, ']}'));
			return string(abi.encodePacked('data:application/json;base64,', _encode(bytes(_json))));
		}
	}

	function svgURI(uint256 _tokenId) public view returns (string memory) {
		return string(abi.encodePacked('data:image/svg+xml;base64,', _encode(bytes(getSVG(_tokenId)))));
	}
	
	function bmpURI(uint256 _tokenId) public view returns (string memory) {
		return string(abi.encodePacked('data:image/bmp;base64,', _encode(getBMP(_tokenId))));
	}

	function getSVG(uint256 _tokenId) public view returns (string memory) {
		return string(abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" version="1.1" preserveAspectRatio="xMidYMid meet" viewBox="0 0 512 512" width="100%" height="100%"><defs><style type="text/css">svg{image-rendering:optimizeSpeed;image-rendering:-moz-crisp-edges;image-rendering:-o-crisp-edges;image-rendering:-webkit-optimize-contrast;image-rendering:pixelated;image-rendering:optimize-contrast;-ms-interpolation-mode:nearest-neighbor;background-color:', _col2str(BG_COLOR), ';background-image:url(', bmpURI(_tokenId), ');background-repeat:no-repeat;background-size:contain;background-position:50% 50%;}</style></defs></svg>'));
	}
	
	function getBMP(uint256 _tokenId) public view returns (bytes memory) {
		(bytes32 _seed, uint256 _size, uint256 _colorIndex) = _getTokenInfo(_tokenId);
		return _getBMP(_makePalette(colors[_colorIndex].primaryColor, colors[_colorIndex].outlineColor), _convertToColors(_addOutline(_expandAndReflect(_step(_step(_getInitialState(_seed, _size)))))), _size);
	}
	
	
	function _getTokenInfo(uint256 _tokenId) internal view returns (bytes32 seed, uint256 size, uint256 colorIndex) {
		unchecked {
			seed = keccak256(abi.encodePacked("Seed:", _tokenId, arbmates.salt()));
			size = _sampleSize(seed);
			colorIndex = _sampleColor(seed);
		}
	}

	function _sampleSize(bytes32 _seed) internal view returns (uint256 size) {
		unchecked {
			uint256 _total = 0;
			for (uint256 i = 0; i < sizes.length; i++) {
				_total += sizes[i].chance;
			}
			uint256 _target = uint256(keccak256(abi.encodePacked("Size:", _seed))) % _total;
			_total = 0;
			for (uint256 i = 0; i < sizes.length; i++) {
				_total += sizes[i].chance;
				if (_target < _total) {
					return sizes[i].size;
				}
			}
		}
	}

	function _sampleColor(bytes32 _seed) internal view returns (uint256 colorIndex) {
		unchecked {
			uint256 _total = 0;
			for (uint256 i = 0; i < colors.length; i++) {
				_total += colors[i].chance;
			}
			uint256 _target = uint256(keccak256(abi.encodePacked("Color:", _seed))) % _total;
			_total = 0;
			for (uint256 i = 0; i < colors.length; i++) {
				_total += colors[i].chance;
				if (_target < _total) {
					return i;
				}
			}
		}
	}

	function _getInitialState(bytes32 _seed, uint256 _size) internal pure returns (uint8[][] memory state) {
		unchecked {
			uint256 _rollingSeed = uint256(keccak256(abi.encodePacked("State:", _seed)));
			state = new uint8[][](_size - 2 * PADDING - 2);
			for (uint256 y = 0; y < state.length; y++) {
				state[y] = new uint8[](_size / 2 - PADDING - 1);
				for (uint256 x = 0; x < state[y].length; x++) {
					state[y][x] = uint8(_rollingSeed % 2);
					if (_rollingSeed < type(uint16).max) {
						_rollingSeed = uint256(keccak256(abi.encodePacked("Roll:", _seed, _rollingSeed)));
					} else {
						_rollingSeed /= 2;
					}
				}
			}
		}
	}

	function _getNeighborhood(uint8[][] memory _state) internal pure returns (uint8[][] memory neighborhood) {
		unchecked {
			neighborhood = new uint8[][](_state.length);
			for (uint256 y = 0; y < _state.length; y++) {
				neighborhood[y] = new uint8[](_state[y].length);
				for (uint256 x = 0; x < _state[y].length; x++) {
					uint8 _count = 0;
					if (y > 0) {
						_count += _state[y - 1][x];
					}
					if (y < _state.length - 1) {
						_count += _state[y + 1][x];
					}
					if (x > 0) {
						_count += _state[y][x - 1];
					}
					if (x < _state[y].length - 1) {
						_count += _state[y][x + 1];
					}
					neighborhood[y][x] = _count;
				}
			}
		}
	}

	function _step(uint8[][] memory _state) internal pure returns (uint8[][] memory newState) {
		unchecked {
			uint8[][] memory _neighborhood = _getNeighborhood(_state);
			newState = new uint8[][](_state.length);
			for (uint256 y = 0; y < _state.length; y++) {
				newState[y] = new uint8[](_state[y].length);
				for (uint256 x = 0; x < _state[y].length; x++) {
					newState[y][x] = ((_state[y][x] == 0 && _neighborhood[y][x] <= 1) || (_state[y][x] == 1 && (_neighborhood[y][x] == 2 || _neighborhood[y][x] == 3))) ? 1 : 0;
				}
			}
		}
	}

	function _expandAndReflect(uint8[][] memory _state) internal pure returns (uint8[][] memory newState) {
		unchecked {
			newState = new uint8[][](_state.length + 2 * PADDING + 2);
			for (uint256 y = 0; y < newState.length; y++) {
				newState[y] = new uint8[](_state.length + 2 * PADDING + 2);
				for (uint256 x = 0; x < newState[y].length; x++) {
					if (y > PADDING && y <= _state.length + PADDING && x > PADDING && x <= _state.length + PADDING) {
						newState[y][x] = _state[y - PADDING - 1][x > _state[y - PADDING - 1].length + PADDING ? _state.length + PADDING - x : x - PADDING - 1];
					} else {
						newState[y][x] = 0;
					}
				}
			}
		}
	}

	function _addOutline(uint8[][] memory _state) internal pure returns (uint8[][] memory newState) {
		unchecked {
			uint8[][] memory _neighborhood = _getNeighborhood(_state);
			newState = new uint8[][](_state.length);
			for (uint256 y = 0; y < _state.length; y++) {
				newState[y] = new uint8[](_state[y].length);
				for (uint256 x = 0; x < _state[y].length; x++) {
					newState[y][x] = _state[y][x] == 0 && _neighborhood[y][x] > 0 ? 2 : _state[y][x];
				}
			}
		}
	}

	function _convertToColors(uint8[][] memory _state) internal pure returns (bytes memory cols) {
		unchecked {
			uint256 _scanline = _state[0].length;
			if (_scanline % 4 != 0) {
				_scanline += 4 - (_scanline % 4);
			}
			cols = new bytes(_state.length * _scanline);
			for (uint256 y = 0; y < _state.length; y++) {
				for (uint256 x = 0; x < _state[y].length; x++) {
					cols[(_state.length - y - 1) * _scanline + x] = bytes1(_state[y][x]);
				}
			}
		}
	}
	
	function _makePalette(bytes3 _primaryColor, bytes3 _outlineColor) internal pure returns (bytes memory) {
		unchecked {
			return abi.encodePacked(BG_COLOR, bytes1(0), _primaryColor, bytes1(0), _outlineColor, bytes1(0));
		}
	}

	function _getBMP(bytes memory _palette, bytes memory _colors, uint256 _size) internal pure returns (bytes memory) {
		unchecked {
			uint32 _bufSize = 14 + 40 + uint32(_palette.length);
			bytes memory _buf = new bytes(_bufSize - _palette.length);
			_buf[0] = 0x42;
			_buf[1] = 0x4d;
			uint32 _tmp = _bufSize + uint32(_colors.length);
			uint32 b;
			for (uint i = 2; i < 6; i++) {
				assembly {
					b := and(_tmp, 0xff)
					_tmp := shr(8, _tmp)
				}
				_buf[i] = bytes1(uint8(b));
			}
			_tmp = _bufSize;
			for (uint i = 10; i < 14; i++) {
				assembly {
					b := and(_tmp, 0xff)
					_tmp := shr(8, _tmp)
				}
				_buf[i] = bytes1(uint8(b));
			}
			_buf[14] = 0x28;
			_tmp = uint32(_size);
			for (uint i = 18; i < 22; i++) {
				assembly {
					b := and(_tmp, 0xff)
					_tmp := shr(8, _tmp)
				}
				_buf[i] = bytes1(uint8(b));
				_buf[i + 4] = bytes1(uint8(b));
			}
			_buf[26] = 0x01;
			_buf[28] = 0x08;
			_tmp = uint32(_colors.length);
			for (uint i = 34; i < 38; i++) {
				assembly {
					b := and(_tmp, 0xff)
					_tmp := shr(8, _tmp)
				}
				_buf[i] = bytes1(uint8(b));
			}
			_tmp = uint32(_palette.length / 4);
			for (uint i = 46; i < 50; i++) {
				assembly {
					b := and(_tmp, 0xff)
					_tmp := shr(8, _tmp)
				}
				_buf[i] = bytes1(uint8(b));
				_buf[i + 4] = bytes1(uint8(b));
			}
			return abi.encodePacked(_buf, _palette, _colors);
		}
	}

	function _uint2str(uint256 _value) internal pure returns (string memory) {
		unchecked {
			uint256 _digits = 1;
			uint256 _n = _value;
			while (_n > 9) {
				_n /= 10;
				_digits++;
			}
			bytes memory _out = new bytes(_digits);
			for (uint256 i = 0; i < _out.length; i++) {
				uint256 _dec = (_value / (10**(_out.length - i - 1))) % 10;
				_out[i] = bytes1(uint8(_dec) + 48);
			}
			return string(_out);
		}
	}

	function _col2str(bytes3 _col) internal pure returns (string memory str) {
		unchecked {
			str = "#";
			for (uint256 i = 0; i < 6; i++) {
				uint256 _hex = (uint24(_col) >> (4 * (i + 1 - 2 * (i % 2)))) % 16;
				bytes memory _char = new bytes(1);
				_char[0] = bytes1(uint8(_hex) + (_hex > 9 ? 87 : 48));
				str = string(abi.encodePacked(str, string(_char)));
			}
		}
	}

	function _encode(bytes memory _data) internal pure returns (string memory result) {
		unchecked {
			if (_data.length == 0) return '';
			string memory _table = TABLE;
			uint256 _encodedLen = 4 * ((_data.length + 2) / 3);
			result = new string(_encodedLen + 32);

			assembly {
				mstore(result, _encodedLen)
				let tablePtr := add(_table, 1)
				let dataPtr := _data
				let endPtr := add(dataPtr, mload(_data))
				let resultPtr := add(result, 32)

				for {} lt(dataPtr, endPtr) {}
				{
					dataPtr := add(dataPtr, 3)
					let input := mload(dataPtr)
					mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
					resultPtr := add(resultPtr, 1)
					mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
					resultPtr := add(resultPtr, 1)
					mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
					resultPtr := add(resultPtr, 1)
					mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
					resultPtr := add(resultPtr, 1)
				}
				switch mod(mload(_data), 3)
				case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
				case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
			}
			return result;
		}
	}
}