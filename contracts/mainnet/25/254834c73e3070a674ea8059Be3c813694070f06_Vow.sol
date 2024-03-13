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
        uint256 flock; // flash lock
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
}

// SPDX-License-Identifier: AGPL-3.0-or-later

// Copyright (C) 2021-2024 halys

pragma solidity ^0.8.19;

import { Bank } from "../bank.sol";

interface Hook {
    struct FHParams {
        address sender;
        bytes32 i;
        address u;
        bytes   dink;
        int256  dart;
    }
    struct BHParams {
        bytes32 i;
        address u;
        uint256 bill;
        uint256 owed;
        address keeper;
        uint256 deal;
        uint256 tot;
    }

    function frobhook(FHParams calldata) external payable returns (bool safer);
    function bailhook(BHParams calldata) external payable returns (bytes memory);
    function safehook(bytes32 i, address u) external view
      returns (uint tot, uint cut, uint minttl);
    function ink(bytes32 i, address u) external view returns (bytes memory);
}

abstract contract HookMix is Hook, Bank {

    // Sync with vat. Update joy and possibly line. Workaround for stack too deep
    function vsync(bytes32 i, uint earn, uint owed, uint over) internal {
        VatStorage storage vs = getVatStorage();

        if (earn < owed) {
            // drop line value for this ilk as precaution
            uint prev = vs.ilks[i].line;
            uint loss = RAY * (owed - earn);
            uint next = loss > prev ? 0 : prev - loss;
            vs.ilks[i].line = next;
            emit NewPalm1("line", i, bytes32(next));
        }

        // update joy to help cancel out sin
        uint mood = vs.joy + earn - over;
        vs.joy = mood;
        emit NewPalm0("joy", bytes32(mood));
    }
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

// SPDX-License-Identifier: AGPL-3.0-or-later

/// vat.sol -- Rico CDP database

// Copyright (C) 2021-2024 halys
// Copyright (C) 2018 Rain <[email protected]>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
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

import { Bank } from "./bank.sol";
import { Hook } from "./hook/hook.sol";

contract Vat is Bank {
    function ilks(bytes32 i) external view returns (Ilk memory) {
        return getVatStorage().ilks[i];
    }
    function urns(bytes32 i, address u) external view returns (uint) {
        return getVatStorage().urns[i][u];
    }
    function joy()  external view returns (uint) {return getVatStorage().joy;}
    function sin()  external view returns (uint) {return getVatStorage().sin;}
    function rest() external view returns (uint) {return getVatStorage().rest;}
    function debt() external view returns (uint) {return getVatStorage().debt;}
    function ceil() external view returns (uint) {return getVatStorage().ceil;}
    function par()  external view returns (uint) {return getVatStorage().par;}
    function ink(bytes32 i, address u) external view returns (bytes memory) {
        return abi.decode(_hookview(i, abi.encodeWithSelector(
            Hook.ink.selector, i, u
        )), (bytes));
    }
    function MINT() external pure returns (uint) {return _MINT;}
    function FEE_MAX() external pure returns (uint) {return _FEE_MAX;}

    enum Spot {Sunk, Iffy, Safe}

    uint256 constant _MINT    = 2 ** 128;
    uint256 constant _FEE_MAX = 1000000072964521287979890107; // ~10x/yr

    error ErrIlkInit();
    error ErrNotSafe();
    error ErrUrnDust();
    error ErrDebtCeil();
    error ErrMultiIlk();
    error ErrHookData();
    error ErrLock();
    error ErrSafeBail();
    error ErrHookCallerNotBank();
    error ErrNoHook();

    // lock for CDP manipulation functions
    // not necessary for drip, because frob and bail drip
    modifier _lock_ {
        VatStorage storage vs = getVatStorage();
        if (vs.lock == LOCKED) revert ErrLock();
        vs.lock = LOCKED;
        _;
        vs.lock = UNLOCKED;
    }

    function init(bytes32 ilk, address hook)
      external payable onlyOwner _flog_
    {
        VatStorage storage vs = getVatStorage();
        if (vs.ilks[ilk].rack != 0) revert ErrMultiIlk();
        vs.ilks[ilk] = Ilk({
            rack: RAY,
            fee : RAY,
            hook: hook,
            rho : block.timestamp,
            tart: 0,
            chop: 0, line: 0, dust: 0
        });
        emit NewPalm1("rack", ilk, bytes32(RAY));
        emit NewPalm1("fee",  ilk, bytes32(RAY));
        emit NewPalm1("hook", ilk, bytes32(bytes20(hook)));
        emit NewPalm1("rho",  ilk, bytes32(block.timestamp));
        emit NewPalm1("tart", ilk, bytes32(uint(0)));
        emit NewPalm1("chop", ilk, bytes32(uint(0)));
        emit NewPalm1("line", ilk, bytes32(uint(0)));
        emit NewPalm1("dust", ilk, bytes32(uint(0)));
    }

    function safe(bytes32 i, address u)
      public view returns (Spot, uint, uint)
    {
        VatStorage storage vs = getVatStorage();
        Ilk storage ilk = vs.ilks[i];
        bytes memory data = _hookview(i, abi.encodeWithSelector(
            Hook.safehook.selector, i, u
        ));
        if (data.length != 96) revert ErrHookData();
 
        (uint tot, uint cut, uint ttl) = abi.decode(data, (uint, uint, uint));
        uint art = vs.urns[i][u];
        if (art == 0) return (Spot.Safe, RAY, tot);
        if (block.timestamp > ttl) return (Spot.Iffy, 0, tot);

        // par acts as a multiplier for collateral requirements
        // par increase has same effect on cut as fee accumulation through rack
        // par decrease acts like a negative fee
        uint256 tab = art * rmul(vs.par, ilk.rack);
        if (tab <= cut) {
            return (Spot.Safe, RAY, tot);
        } else {
            uint256 deal = cut / (tab / RAY);
            return (Spot.Sunk, deal, tot);
        }
    }

    // modify CDP
    // locked with bail to make individual urn manipulations atomic
    // e.g. avoid making the urn safe in the middle of an unsafe borrow
    function frob(bytes32 i, address u, bytes calldata dink, int dart)
      external payable _flog_ _lock_
    {
        VatStorage storage vs = getVatStorage();
        Ilk storage ilk = vs.ilks[i];

        uint rack = _drip(i);

        // modify normalized debt
        uint256 art   = add(vs.urns[i][u], dart);
        vs.urns[i][u] = art;
        emit NewPalm2("art", i, bytes32(bytes20(u)), bytes32(art));

        // keep track of total so it denorm doesn't exceed line
        ilk.tart      = add(ilk.tart, dart);
        emit NewPalm1("tart", i, bytes32(ilk.tart));

        uint _debt;
        uint _rest;
        {
            // rico mint/burn amount increases with rack
            int dtab = mul(rack, dart);
            if (dtab > 0) {
                // borrow
                // dtab is a rad, debt is a wad
                uint wad = uint(dtab) / RAY;
                _debt    = vs.debt += wad;
                emit NewPalm0("debt", bytes32(_debt));

                // remainder is a ray
                _rest = vs.rest += uint(dtab) % RAY;
                emit NewPalm0("rest", bytes32(_rest));

                getBankStorage().rico.mint(msg.sender, wad);
            } else if (dtab < 0) {
                // paydown
                // dtab is a rad, so burn one extra to round in system's favor
                uint wad = (uint(-dtab) / RAY) + 1;
                _debt = vs.debt -= wad;
                emit NewPalm0("debt", bytes32(_debt));

                // accrue excess from rounding to rest
                _rest = vs.rest += add(wad * RAY, dtab);
                emit NewPalm0("rest", bytes32(_rest));

                getBankStorage().rico.burn(msg.sender, wad);
            }
        }

        // safer if less/same art and more/same ink
        Hook.FHParams memory p = Hook.FHParams(msg.sender, i, u, dink, dart);
        bytes memory data      = _hookcall(
            i, abi.encodeWithSelector(Hook.frobhook.selector, p)
        );
        if (data.length != 32) revert ErrHookData();

        // urn is safer, or it is safe
        if (!abi.decode(data, (bool))) {
            (Spot spot,,) = safe(i, u);
            if (spot != Spot.Safe) revert ErrNotSafe();
        }

        // urn has no debt, or a non-dusty amount
        if (art != 0 && rack * art < ilk.dust) revert ErrUrnDust();

        // either debt has decreased, or debt ceilings are not exceeded
        if (dart > 0) {
            if (ilk.tart * rack > ilk.line) revert ErrDebtCeil();
            else if (_debt + (_rest / RAY) > vs.ceil) revert ErrDebtCeil();
        }
    }

    // liquidate CDP
    // locked with frob to make individual urn manipulations atomic
    // e.g. avoid making the urn safe in the middle of a liquidation
    function bail(bytes32 i, address u)
      external payable _flog_ _lock_ returns (bytes memory)
    {
        uint rack = _drip(i);
        uint deal; uint tot;
        {
            Spot spot;
            (spot, deal, tot) = safe(i, u);
            if (spot != Spot.Sunk) revert ErrSafeBail();
        }
        VatStorage storage vs = getVatStorage();
        Ilk storage ilk = vs.ilks[i];

        uint art = vs.urns[i][u];
        delete vs.urns[i][u];
        emit NewPalm2("art", i, bytes32(bytes20(u)), bytes32(uint(0)));

        // bill is the debt hook will attempt to cover when auctioning ink
        uint dtab = art * rack;
        uint owed = dtab / RAY;
        uint bill = rmul(ilk.chop, owed);

        ilk.tart -= art;
        emit NewPalm1("tart", i, bytes32(ilk.tart));

        // when switching from surplus to potential deficit, reset vow auction
        if (vs.sin / RAY <= vs.joy && (vs.sin + dtab) / RAY > vs.joy ) {
            getVowStorage().ramp.bel = block.timestamp;
            emit NewPalm0("bel", bytes32(block.timestamp));
        }

        // record the bad debt for vow to heal
        vs.sin += dtab;
        emit NewPalm0("sin", bytes32(vs.sin));

        // ink auction
        Hook.BHParams memory p = Hook.BHParams(
            i, u, bill, owed, msg.sender, deal, tot
        );
        return abi.decode(_hookcall(
            i, abi.encodeWithSelector(Hook.bailhook.selector, p)
        ), (bytes));
    }

    function drip(bytes32 i) external payable _flog_ { _drip(i); }

    // drip without flog
    function _drip(bytes32 i) internal returns (uint rack) {
        VatStorage storage vs = getVatStorage();
        Ilk storage ilk       = vs.ilks[i];
        // multiply rack by fee every second
        uint prev = ilk.rack;
        if (prev == 0) revert ErrIlkInit();
 
        if (block.timestamp == ilk.rho) {
            return ilk.rack;
        }

        // multiply rack by fee every second
        rack = grow(prev, ilk.fee, block.timestamp - ilk.rho);

        // difference between current and previous rack determines interest
        uint256 delt = rack - prev;
        uint256 rad  = ilk.tart * delt;
        uint256 all  = vs.rest + rad;

        ilk.rho      = block.timestamp;
        emit NewPalm1("rho", i, bytes32(block.timestamp));

        ilk.rack     = rack;
        emit NewPalm1("rack", i, bytes32(rack));

        vs.debt      = vs.debt + (all / RAY);
        emit NewPalm0("debt", bytes32(vs.debt));

        // tart * rack is a rad, interest is a wad, rest is the change
        vs.rest      = all % RAY;
        emit NewPalm0("rest", bytes32(vs.rest));

        vs.joy       = vs.joy + (all / RAY);
        emit NewPalm0("joy", bytes32(vs.joy));
    }

    // flash borrow
    // locked with itself to avoid flashing more than MINT
    function flash(address code, bytes calldata data)
      external payable returns (bytes memory result) {
        // lock->mint->call->burn->unlock
        VatStorage storage vs = getVatStorage();
        if (vs.flock == LOCKED) revert ErrLock();
        vs.flock = LOCKED;

        getBankStorage().rico.mint(code, _MINT);
        bool ok;
        (ok, result) = code.call(data);
        if (!ok) bubble(result);
        getBankStorage().rico.burn(code, _MINT);

        vs.flock = UNLOCKED;
    }

    function filk(bytes32 ilk, bytes32 key, bytes32 val)
      external payable onlyOwner _flog_
    {
        uint _val = uint(val);
        VatStorage storage vs = getVatStorage();
        Ilk storage i = vs.ilks[ilk];
               if (key == "line") { i.line = _val;
        } else if (key == "dust") { i.dust = _val;
        } else if (key == "hook") { i.hook = address(bytes20(val));
        } else if (key == "chop") {
            must(_val, RAY, 10 * RAY);
            i.chop = _val;
        } else if (key == "fee") {
            must(_val, RAY, _FEE_MAX);
            _drip(ilk);
            i.fee = _val;
        } else { revert ErrWrongKey(); }
        emit NewPalm1(key, ilk, bytes32(val));
    }

    // delegatecall the ilk's hook
    function _hookcall(bytes32 i, bytes memory indata)
      internal returns (bytes memory outdata) {
        // call will succeed if nonzero hook has no code (i.e. EOA)
        address hook = getVatStorage().ilks[i].hook;
        if (hook == address(0)) revert ErrNoHook();

        bool ok;
        (ok, outdata) = hook.delegatecall(indata);
        if (!ok) bubble(outdata);
    }

    // similar to _hookcall, but uses staticcall to avoid modifying state
    // can't delegatecall within a view function
    // so, _hookview calls hookcallext instead, which delegatecalls _hookcall
    function _hookview(bytes32 i, bytes memory indata)
      internal view returns (bytes memory outdata) {
        bool ok;
        (ok, outdata) = address(this).staticcall(
            abi.encodeWithSelector(Vat.hookcallext.selector, i, indata)
        );
        if (!ok) bubble(outdata);
        outdata = abi.decode(outdata, (bytes));
    }

    // helps caller call hook functions without delegatecall
    function hookcallext(bytes32 i, bytes memory indata)
      external payable returns (bytes memory) {
        if (msg.sender != address(this)) revert ErrHookCallerNotBank();
        return _hookcall(i, indata);
    }

    function filh(bytes32 ilk, bytes32 key, bytes32[] calldata xs, bytes32 val)
      external payable onlyOwner _flog_ {
        _hookcall(ilk, abi.encodeWithSignature(
            "file(bytes32,bytes32,bytes32[],bytes32)", key, ilk, xs, val
        ));
    }

    function geth(bytes32 ilk, bytes32 key, bytes32[] calldata xs)
      external view returns (bytes32) {
        return abi.decode(
            _hookview(ilk, abi.encodeWithSignature(
                "get(bytes32,bytes32,bytes32[])", key, ilk, xs
            )), (bytes32)
        );
    }

}

// SPDX-License-Identifier: AGPL-3.0-or-later

// Copyright (C) 2021-2024 halys

pragma solidity ^0.8.19;

import { Vat }  from "./vat.sol";
import { Bank, Gem } from "./bank.sol";

// total system profit/loss balancing mechanism
// triggers surplus (flap), and deficit (flop) auctions
contract Vow is Bank {
    function RISK() external view returns (Gem) {return getVowStorage().risk;}
    function ramp() external view returns (Ramp memory) {
        return getVowStorage().ramp;
    }
    function loot() external view returns (uint) { return getVowStorage().loot; }
    function dam() external view returns (uint) { return getVowStorage().dam; }
    function dom() external view returns (uint) { return getVowStorage().dom; }
    function pex() external pure returns (uint) { return _pex; }
    uint constant public _pex = RAY * WAD;

    error ErrReflop();

    function keep(bytes32[] calldata ilks) external payable _flog_ {
        VowStorage storage  vowS  = getVowStorage();
        VatStorage storage  vatS  = getVatStorage();
        BankStorage storage bankS = getBankStorage();

        for (uint256 i = 0; i < ilks.length;) {
            Vat(address(this)).drip(ilks[i]);
            unchecked {++i;}
        }

        Gem rico = bankS.rico;
        Gem risk = vowS.risk;

        // use equal scales for sin and joy
        uint joy = vatS.joy;
        uint sin = vatS.sin / RAY;

        if (joy > sin) {

            // pay down sin, then auction off surplus RICO for RISK
            if (sin > 1) {
                // gas - don't zero sin
                joy = _heal(sin - 1);
            }

            // price decreases with time
            uint price = grow(
                _pex, vowS.dam, block.timestamp - vowS.ramp.bel
            );

            // buy-and-burn risk with remaining (`flap`) rico
            uint flap  = rmul(joy - 1, vowS.ramp.wel);
            joy       -= flap;
            vatS.joy   = joy;
            emit NewPalm0("joy", bytes32(joy));

            uint sell  = rmul(flap, vowS.loot);
            uint earn  = rmul(sell, price);

            // swap rico for RISK, pay protocol fee
            Gem(risk).burn(msg.sender, earn);
            Gem(rico).mint(msg.sender, sell);
            if (sell < flap) Gem(rico).mint(owner(), flap - sell);

            vowS.ramp.bel = block.timestamp;
            emit NewPalm0("bel", bytes32(block.timestamp));

        } else if (sin > joy) {

            // mint-and-sell risk to cover `under`
            uint under = sin - joy;

            // pay down as much sin as possible
            if (joy > 1) {
                // gas - don't zero joy
                joy = _heal(joy - 1);
            }

            // price decreases with time
            uint elapsed = block.timestamp - vowS.ramp.bel;
            uint price   = grow(_pex, vowS.dom, elapsed);

            // rate-limit flop
            uint charge = min(elapsed, vowS.ramp.cel);
            uint flop   = charge * rmul(vowS.ramp.rel, risk.totalSupply());
            if (0 == flop) revert ErrReflop();

            // swap RISK for rico to cover sin
            uint earn = rmul(flop, price);
            uint bel  = block.timestamp;
            if (earn > under) {
                // always advances >= 1s from max(vowS.bel, timestamp - cel)
                bel  -= wmul(charge, WAD - wdiv(under, earn));
                flop  = (flop * under) / earn;
                earn  = under;
            }

            // update last flop stamp
            vowS.ramp.bel = bel;
            emit NewPalm0("bel", bytes32(bel));

            Gem(rico).burn(msg.sender, earn);
            Gem(risk).mint(msg.sender, flop);

            // new joy will heal some sin in next flop
            joy     += earn;
            vatS.joy = joy;
            emit NewPalm0("joy", bytes32(joy));

        }

    }

    function _heal(uint wad) internal returns (uint joy) {
        VatStorage storage vs = getVatStorage();

        vs.sin  = vs.sin  - (wad * RAY);
        emit NewPalm0("sin", bytes32(vs.sin));

        vs.joy  = (joy = vs.joy - wad);
        emit NewPalm0("joy", bytes32(joy));

        vs.debt = vs.debt - wad;
        emit NewPalm0("debt", bytes32(vs.debt));
    }

}