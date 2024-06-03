// SPDX-License-Identifier: AGPL-v3.0
// Copyright (C) 2021-2024 halys

pragma solidity ^0.8.19;

import { Read } from './mixin/Read.sol';

contract Feedbase {

    struct Feed {
        bytes32 val;
        uint256 ttl;
    }

    event Push(
        address indexed src,
        bytes32 indexed tag,
        bytes32         val,
        uint256         ttl
    );

    error ErrTTL();
    uint256 internal constant READ = 0;

    // src -> tag -> Feed
    mapping(address=>mapping(bytes32=>Feed)) _feeds;

    function pull(address src, bytes32 tag)
      external view returns (bytes32 val, uint256 ttl) {
        Feed storage feed = _feeds[src][tag];
        ttl = feed.ttl;
        if (ttl == READ) (val, ttl) = Read(src).read(tag);
        else val = feed.val;
    }

    function push(bytes32 tag, bytes32 val, uint256 ttl) external payable {
        if (ttl == READ) revert ErrTTL();
        _feeds[msg.sender][tag] = Feed({val: val, ttl: ttl});
        emit Push(msg.sender, tag, val, ttl);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021-2024 halys

pragma solidity ^0.8.19;

import { Feedbase } from '../Feedbase.sol';
import { Ward } from '../mixin/ward.sol';

interface Read {
    function read(bytes32 tag) external view returns (bytes32 val, uint256 ttl);
}

abstract contract Block is Read, Ward {
    struct Config {
        address[] sources;
        bytes32[] tags;
    }
    mapping(bytes32=>Config) configs;

    error ErrMatch();
    error ErrShort();

    Feedbase public immutable feedbase;
    uint256 internal constant RAY = 10 ** 27;

    constructor(address fb) Ward() {
        feedbase = Feedbase(fb);
    }
    
    function setConfig(bytes32 tag, Config calldata _config)
      external payable _ward_ {
        uint n = _config.sources.length;
        if (n < 2) revert ErrShort();
        if (_config.tags.length != n) revert ErrMatch();
        configs[tag] = _config;
    }

    // can't have public getter for struct of dynamic arrays
    function getConfig(bytes32 tag) external view returns (Config memory) {
        return configs[tag];
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021-2024 halys

pragma solidity ^0.8.19;

// tools for ward (root user) management
contract Ward {
    event SetWard(address indexed caller, address indexed trusts, bool bit);
    error ErrWard(address caller, address object, bytes4 sig);

    mapping (address usr => bool) public wards;

    constructor() {
        wards[msg.sender] = true;
        emit SetWard(address(this), msg.sender, true);
    }

    function ward(address usr, bool bit)
      _ward_ external
    {
        emit SetWard(msg.sender, usr, bit);
        wards[usr] = bit;
    }

    function give(address usr)
      _ward_ external
    {
        wards[usr] = true;
        emit SetWard(msg.sender, usr, true);
        wards[msg.sender] = false;
        emit SetWard(msg.sender, msg.sender, false);
    }

    modifier _ward_ {
        if (!wards[msg.sender]) {
            revert ErrWard(msg.sender, address(this), msg.sig);
        }
        _;
    }
}

/// SPDX-License-Identifier: AGPL-3.0-only

// Copyright (C) 2021 kevin and his friends
// Copyright (C) 2017, 2018, 2019 dbrock, rain, mrchico

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, version 3.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.19;

contract Gem {
    bytes32 public name;
    bytes32 public symbol;
    uint256 public totalSupply;
    uint8   public constant decimals = 18;

    mapping (address => uint)                      public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
    mapping (address => uint)                      public nonces;
    mapping (address => bool)                      public wards;

    bytes32 constant DOMAIN_SUBHASH = keccak256(
        'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
    );
    bytes32 constant PERMIT_TYPEHASH = keccak256(
        'Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)'
    );
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return keccak256(abi.encode( DOMAIN_SUBHASH,
            keccak256("GemPermit"), keccak256("0"),
            block.chainid, address(this))
        );
    }

    event Approval(address indexed src, address indexed usr, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);
    event Ward(address indexed setter, address indexed user, bool authed);

    error ErrPermitDeadline();
    error ErrPermitSignature();
    error ErrOverflow();
    error ErrUnderflow();
    error ErrZeroDst();
    error ErrWard();

    constructor(bytes32 name_, bytes32 symbol_)
      payable
    {
        name = name_;
        symbol = symbol_;

        wards[msg.sender] = true;
        emit Ward(msg.sender, msg.sender, true);
    }

    function ward(address usr, bool authed)
      payable external
    {
        if (!wards[msg.sender]) revert ErrWard();
        wards[usr] = authed;
        emit Ward(msg.sender, usr, authed);
    }

    function mint(address usr, uint wad)
      payable external
    {
        if (!wards[msg.sender]) revert ErrWard();
        unchecked {
            // only need to check totalSupply for overflow
            uint256 prev = totalSupply;
            if (prev + wad < prev) revert ErrOverflow();

            balanceOf[usr] += wad;
            totalSupply     = prev + wad;
            emit Transfer(address(0), usr, wad);

            if (usr == address(0)) revert ErrZeroDst();
        }
    }

    function burn(address usr, uint wad)
      payable external
    {
        if (!wards[msg.sender]) revert ErrWard();
        unchecked {
            // only need to check balanceOf[usr] for underflow
            uint256 prev = balanceOf[usr];
            balanceOf[usr] = prev - wad;
            totalSupply    -= wad;
            emit Transfer(usr, address(0), wad);

            if (prev < wad) revert ErrUnderflow();
        }
    }

    function transfer(address dst, uint wad)
      payable external returns (bool ok)
    {
        unchecked {
            ok = true;
            uint256 prev = balanceOf[msg.sender];
            balanceOf[msg.sender] = prev - wad;
            balanceOf[dst]       += wad;
            emit Transfer(msg.sender, dst, wad);

            if (prev < wad) revert ErrUnderflow();
            if (dst == address(0)) revert ErrZeroDst();
        }
    }

    function transferFrom(address src, address dst, uint wad)
      payable external returns (bool ok)
    {
        unchecked {
            ok              = true;
            uint256 prevB   = balanceOf[src];
            balanceOf[src]  = prevB - wad;
            balanceOf[dst] += wad;
            uint256 prevA   = allowance[src][msg.sender];

            if (prevA != type(uint256).max) {
                allowance[src][msg.sender] = prevA - wad;
                emit Approval(src, msg.sender, prevA - wad);

                if (prevA < wad) revert ErrUnderflow();
            }
            emit Transfer(src, dst, wad);

            if (prevB < wad) revert ErrUnderflow();
            if (dst == address(0)) revert ErrZeroDst();
        }
    }

    function approve(address usr, uint wad)
      payable external returns (bool ok)
    {
        ok = true;
        allowance[msg.sender][usr] = wad;
        emit Approval(msg.sender, usr, wad);
    }

    // EIP-2612
    function permit(address owner, address spender, uint256 value, uint256 deadline,
                    uint8 v, bytes32 r, bytes32 s)
      payable external
    {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);

        address signer;
        unchecked {
            signer = ecrecover(
                keccak256(abi.encodePacked( "\x19\x01",
                    keccak256(abi.encode( DOMAIN_SUBHASH,
                        keccak256("GemPermit"), keccak256("0"),
                        block.chainid, address(this))),
                    keccak256(abi.encode( PERMIT_TYPEHASH, owner, spender,
                        value, nonces[owner]++, deadline )))),
                v, r, s
            );
        }

        if (signer == address(0)) revert ErrPermitSignature();
        if (owner != signer) revert ErrPermitSignature();
        if (block.timestamp > deadline) revert ErrPermitDeadline();
    }
}

contract GemFab {
    mapping(address=>bool) public built;

    event Build(address indexed caller, address indexed gem);

    function build(bytes32 name, bytes32 symbol)
      payable external returns (Gem gem)
    {
        gem = new Gem(name, symbol);
        built[address(gem)] = true;
        emit Build(msg.sender, address(gem));
        gem.ward(msg.sender, true);
        gem.ward(address(this), false);
        return gem;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {OwnableStorage} from './OwnableStorage.sol';

abstract contract OwnableInternal {
  using OwnableStorage for OwnableStorage.Layout;

  modifier onlyOwner {
    require(
      msg.sender == OwnableStorage.layout().owner,
      'Ownable: sender must be owner'
    );
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library OwnableStorage {
  struct Layout {
    address owner;
  }

  bytes32 internal constant STORAGE_SLOT = keccak256(
    'solidstate.contracts.storage.Ownable'
  );

  function layout () internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly { l.slot := slot }
  }

  function setOwner (
    Layout storage l,
    address owner
  ) internal {
    l.owner = owner;
  }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

// Copyright (C) 2021-2024 halys

pragma solidity ^0.8.19;

import { OwnableInternal, OwnableStorage } from "../lib/solidstate-solidity/contracts/access/OwnableInternal.sol";
import { Math } from "./mixin/math.sol";
import { Flog } from "./mixin/flog.sol";
import { Palm } from "./mixin/palm.sol";
import { Gem }  from "../lib/gemfab/src/gem.sol";
import { Feedbase } from "../lib/feedbase/src/Feedbase.sol";

abstract contract Bank is Math, Flog, Palm, OwnableInternal {

    // per-collateral type accounting
    struct Ilk {
        uint256 tart;  // [wad] Total Normalised Debt
        uint256 rack;  // [ray] Accumulated Rate

        uint256 line;  // [rad] Debt Ceiling
        uint256 dust;  // [rad] Urn Debt Floor

        uint256  fee;  // [ray] Collateral-specific, per-second compounding rate
        uint256  rho;  // [sec] Time of last drip

        uint256 chop;  // [ray] Liquidation Penalty

        address hook;  // [obj] Frob/grab/safe hook
    }

    struct BankStorage {
        Gem      rico;
        Feedbase fb;
    }

    struct VatStorage {
        mapping (bytes32 => Ilk) ilks;                          // collaterals
        mapping (bytes32 => mapping (address => uint256)) urns; // CDPs
        uint256 joy;   // [wad]
        uint256 sin;   // [rad]
        uint256 rest;  // [rad] Debt remainder
        uint256 debt;  // [wad] Total Rico Issued
        uint256 ceil;  // [wad] Total Debt Ceiling
        uint256 par;   // [ray] System Price (rico/ref)
        uint256 lock;  // lock
    }

    uint256 internal constant UNLOCKED = 2;
    uint256 internal constant LOCKED = 1;

    // RISK mint rate. Used in struct, never extend in upgrade
    struct Ramp {
        uint256 bel; // [sec] last flxp timestamp
        uint256 cel; // [sec] max seconds flop can ramp up
        uint256 rel; // [ray] fraction of RISK supply/s
        uint256 wel; // [ray] fraction of joy/flap
    }

    struct Plx {
        uint256 pep; // [int] discount growth exponent
        uint256 pop; // [ray] relative discount factor
        int256  pup; // [ray] relative discount y-axis shift
    }

    struct Rudd {
        address src;
        bytes32 tag;
    }

    struct VowStorage {
        Gem     risk;
        Ramp    ramp;
        uint256 loot; // [ray] portion of flap taken by user (vs protocol)
        uint256 dam;  // [ray] per-second flap discount
        uint256 dom;  // [ray] per-second flop discount
    }

    struct VoxStorage {
        Rudd    tip; // feedbase src,tag
        uint256 way; // [ray] System Rate (SP growth rate)
        uint256 how; // [ray] sensitivity paramater
        uint256 tau; // [sec] last poke
        uint256 cap; // [ray] `way` bound
    }

    bytes32 internal constant VAT_INFO = "vat.0";
    bytes32 internal constant VAT_POS  = keccak256(abi.encodePacked(VAT_INFO));
    bytes32 internal constant VOW_INFO = "vow.0";
    bytes32 internal constant VOW_POS  = keccak256(abi.encodePacked(VOW_INFO));
    bytes32 internal constant VOX_INFO = "vox.0";
    bytes32 internal constant VOX_POS  = keccak256(abi.encodePacked(VOX_INFO));
    bytes32 internal constant BANK_INFO = "ricobank.0";
    bytes32 internal constant BANK_POS  = keccak256(abi.encodePacked(BANK_INFO));
    function getVowStorage() internal pure returns (VowStorage storage vs) {
        bytes32 pos = VOW_POS;  assembly { vs.slot := pos }
    }
    function getVoxStorage() internal pure returns (VoxStorage storage vs) {
        bytes32 pos = VOX_POS;  assembly { vs.slot := pos }
    }
    function getVatStorage() internal pure returns (VatStorage storage vs) {
        bytes32 pos = VAT_POS;  assembly { vs.slot := pos }
    }
    function getBankStorage() internal pure returns (BankStorage storage bs) {
        bytes32 pos = BANK_POS; assembly { bs.slot := pos }
    }

    error ErrWrongKey();
    error ErrWrongUrn();
    error ErrBound();
    error ErrLock();

    // bubble up error code from a reverted call
    function bubble(bytes memory data) internal pure {
        assembly {
            let size := mload(data)
            revert(add(32, data), size)
        }
    }

    function owner() internal view returns (address) {
        return OwnableStorage.layout().owner;
    }

    function must(uint actual, uint lo, uint hi) internal pure {
        if (actual < lo || actual > hi) revert ErrBound();
    }

    // lock for CDP manipulation functions
    // not necessary for drip, because frob and bail drip
    // uses VatStorage from previous iteration.  move to BS in future
    modifier _lock_ {
        VatStorage storage vs = getVatStorage();
        if (vs.lock == LOCKED) revert ErrLock();
        vs.lock = LOCKED;
        _;
        vs.lock = UNLOCKED;
    }

}

// SPDX-License-Identifier: AGPL-3.0-or-later

// Copyright (C) 2021-2024 halys

pragma solidity ^0.8.19;
import { Gem }  from "../lib/gemfab/src/gem.sol";
import { Feedbase } from "../lib/feedbase/src/Feedbase.sol";
import { Bank } from "./bank.sol";

contract File is Bank {
    uint constant _CAP_MAX = 1000000072964521287979890107; // ~10x/yr
    uint constant _REL_MAX = 100 * RAY / BANKYEAR; // ~100x/yr
    function CAP_MAX() external pure returns (uint) {return _CAP_MAX;}
    function REL_MAX() external pure returns (uint) {return _REL_MAX;}

    function file(bytes32 key, bytes32 val) external payable onlyOwner _flog_ {
        VatStorage storage vatS = getVatStorage();
        VowStorage storage vowS = getVowStorage();
        VoxStorage storage voxS = getVoxStorage();
        BankStorage storage bankS = getBankStorage();
        uint _val = uint(val);

               if (key == "rico") { bankS.rico = Gem(address(bytes20(val)));
        } else if (key == "fb") { bankS.fb = Feedbase(address(bytes20(val)));
        } else if (key == "ceil") { vatS.ceil = _val;
        } else if (key == "par") { vatS.par = _val;
        } else if (key == "rel") {
            must(_val, 0, _REL_MAX);
            vowS.ramp.rel = _val;
        } else if (key == "bel") {
            must(_val, 0, block.timestamp);
            vowS.ramp.bel = _val;
        } else if (key == "cel") { vowS.ramp.cel = _val;
        } else if (key == "wel") {
            must(_val, 0, RAY);
            vowS.ramp.wel = _val;
        } else if (key == "loot") {
            must(_val, 0, RAY);
            vowS.loot = _val;
        } else if (key == "dam") {
            must(_val, 0, RAY);
            vowS.dam = _val;
        } else if (key == "dom") {
            must(_val, 0, RAY);
            vowS.dom = _val;
        } else if (key == "risk") { vowS.risk = Gem(address(bytes20(val)));
        } else if (key == "tip.src") { voxS.tip.src = address(bytes20(val));
        } else if (key == "tip.tag") { voxS.tip.tag = val;
        } else if (key == "how") {
            must(_val, RAY, type(uint).max);
            voxS.how = _val;
        } else if (key == "cap") {
            must(_val, RAY, _CAP_MAX);
            voxS.cap = _val;
        } else if (key == "tau") {
            must(_val, block.timestamp, type(uint).max);
            voxS.tau = _val;
        } else if (key == "way") {
            must(_val, rinv(voxS.cap), voxS.cap);
            voxS.way = _val;
        } else revert ErrWrongKey();

        emit NewPalm0(key, val);
    }

    function enlist(address gem, address usr, bool authed) external onlyOwner {
        Gem(gem).ward(usr, authed);
    }

    function rico() external view returns (Gem) {return getBankStorage().rico;}
    function fb() external view returns (Feedbase) {return getBankStorage().fb;}
}

/// SPDX-License-Identifier: AGPL-3.0

// Copyright (C) 2021-2024 halys

pragma solidity ^0.8.19;

abstract contract Flog {
    event NewFlog(
        address indexed caller
      , bytes4 indexed sig
      , bytes data
    );

    // similar to ds-note - emits function call data
    // use at beginning of external state modifying functions
    modifier _flog_ {
        emit NewFlog(msg.sender, msg.sig, msg.data);
        _;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

// Copyright (C) 2021-2024 halys
// Copyright (C) 2021 .
// Copyright (C) 2020 Maker Ecosystem Growth Holdings, INC.
// Copyright (C) 2018 Rain <[email protected]>
// Copyright (C) 2018 Lev Livnev <[email protected]>
// Copyright (C) 2017, 2018, 2019 dbrock, rain, mrchico
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.19;

contract Math {
    // when a (uint, int) arithmetic operation over/underflows
    // Err{returnty}{Over|Under}
    // need these because solidity has no native (uint, int) 
    // overflow checks
    error ErrUintOver();
    error ErrUintUnder();
    error ErrIntUnder();
    error ErrIntOver();

    uint256 internal constant BLN = 10 **  9;
    uint256 internal constant WAD = 10 ** 18;
    uint256 internal constant RAY = 10 ** 27;
    uint256 internal constant RAD = 10 ** 45;

    uint256 internal constant BANKYEAR = ((365 * 24) + 6) * 3600;

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x <= y ? x : y;
    }
    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x >= y ? x : y;
    }

    function add(uint x, int y) internal pure returns (uint z) {
        unchecked {
            z = x + uint(y);
            if (y > 0 && z <= x) revert ErrUintOver();
            if (y < 0 && z >= x) revert ErrUintUnder();
        }
    }

    function mul(uint x, int y) internal pure returns (int z) {
        unchecked {
            z = int(x) * y;
            if (int(x) < 0) revert ErrIntOver();
            if (y != 0 && z / y != int(x)) {
                if (y > 0) revert ErrIntOver();
                else revert ErrIntUnder();
            }
        }
    }

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x * y / WAD;
    }
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x * WAD / y;
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x * y / RAY;
    }
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x * RAY / y;
    }
    function rinv(uint256 x) internal pure returns (uint256) {
        return rdiv(RAY, x);
    }

    function grow(uint256 amt, uint256 ray, uint256 dt) internal pure returns (uint256 z) {
        z = amt * rpow(ray, dt) / RAY;
    }

    // from dss src/abaci.sol:136
    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        assembly {
            switch n case 0 { z := RAY }
            default {
                switch x case 0 { z := 0 }
                default {
                    switch mod(n, 2) case 0 { z := RAY } default { z := x }
                    let half := div(RAY, 2)  // for rounding.
                    for { n := div(n, 2) } n { n := div(n,2) } {
                        let xx := mul(x, x)
                        if shr(128, x) { revert(0,0) }
                        let xxRound := add(xx, half)
                        if lt(xxRound, xx) { revert(0,0) }
                        x := div(xxRound, RAY)
                        if mod(n,2) {
                            let zx := mul(z, x)
                            if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                            let zxRound := add(zx, half)
                            if lt(zxRound, zx) { revert(0,0) }
                            z := div(zxRound, RAY)
                        }
                    }
                }
            }
        }
    }

    function concat(bytes32 a, bytes32 b) internal pure returns (bytes32 res) {
        uint i;
        while (i < 32 && a[i] != 0) {
            unchecked{ i++; }
        }
        res = a | (b >> (i << 3));
    }

    function rmash(uint deal, uint pep, uint pop, int pup)
      internal pure returns (uint res) {
        res = rmul(pop, rpow(deal, pep));
        if (pup < 0 && uint(-pup) > res) return 0;
        res = add(res, pup);
    }
}

/// SPDX-License-Identifier: AGPL-3.0

// Copyright (C) 2021-2024 halys

pragma solidity ^0.8.19;

abstract contract Palm {
    event NewPalm0(
        bytes32 indexed key
      , bytes32 val
    );
    event NewPalm1(
        bytes32 indexed key
      , bytes32 indexed idx0
      , bytes32 val
    );
    event NewPalm2(
        bytes32 indexed key
      , bytes32 indexed idx0
      , bytes32 indexed idx1
      , bytes32 val
    );
    event NewPalmBytes2(
        bytes32 indexed key
      , bytes32 indexed idx0
      , bytes32 indexed idx1
      , bytes val
    );
}