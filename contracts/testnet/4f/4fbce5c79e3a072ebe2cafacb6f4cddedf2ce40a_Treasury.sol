// SPDX-License-Identifier: GPL
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct CashBonusConfig {
    uint32 timestamp;
    uint32 duration;
    uint16 rate;
}

interface CashReserve {
    function totalDeposits() external view returns (uint256);
}

interface CashInterface is IERC20 {
    event Mint(
        address indexed sender,
        address indexed to,
        uint256 amount,
        uint256 value,
        uint256 timestamp
    );

    event Swap(
        address indexed sender,
        address indexed to,
        uint256 amount,
        uint256 value,
        uint256 supply,
        uint256 deposits,
        uint256 reserves,
        uint256 timestamp
    );

    event Burn(
        address indexed sender,
        uint256 amount,
        uint256 timestamp
    );

    event Issue(
        address indexed sender,
        uint256 amount,
        uint256 value,
        uint256 timestamp
    );

    event Inflate(
        address indexed sender,
        address indexed to,
        uint256 amount,
        uint256 timestamp
    );

    event Deflate(
        address indexed sender,
        address indexed from,
        uint256 amount,
        uint256 timestamp
    );

    event Collect(
        address indexed sender,
        address indexed to,
        uint256 amount,
        uint256 found,
        uint256 timestamp
    );

    event SetBonus(
        address indexed from,
        uint32 bonus,
        uint32 duration,
        uint16 rate,
        uint256 timestamp
    );

    event SetReserve(
        address indexed from,
        CashReserve reserve,
        uint256 timestamp
    );

    event Lock(address indexed from, uint256 timestamp);

    function reserve() external view returns (CashReserve);

    function totalDeposits() external view returns (uint256);

    function bonusRate(uint256 value, uint256 timestamp) external view returns (uint256);

    function mint(address to) external payable returns (uint256);

    function swap(address to, uint256 cash) external returns (uint256);

    function burn(uint256 amount) external;

    function issue() external payable returns (uint256);

    function inflate(address to, uint256 amount) external;

    function deflate(address from, uint256 amount) external;
}

// SPDX-License-Identifier: GPL
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

struct Art {
    IERC721Metadata collection;
    uint256 collectable;
}

// SPDX-License-Identifier: GPL
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./Art.sol";
import "./Token.sol";
import "./Encoder.sol";

abstract contract ArtToken is Token, ERC721 {
    Encoder private _encoder;

    event Encode(
        address indexed sender,
        Encoder indexed encoder,
        uint256 timestamp
    );

    function tokenURI(uint256 id) public view override returns (string memory) {
        return _encoder.tokenURI(id);
    }

    function encoder() external view returns (Encoder) {
        return _encoder;
    }

    function setEncoder(Encoder encoder_) external onlyDelegate {
        _encoder = encoder_;

        emit Encode(msg.sender, encoder_, block.timestamp);
    }

    constructor(
        string memory name_,
        string memory symbol_
    ) ERC721(name_, symbol_) Token(name_, symbol_) {
        _encoder = Encoder(address(this));
    }
}

// SPDX-License-Identifier: GPL
pragma solidity ^0.8.9;

interface Encoder {
    function tokenURI(uint256) external view returns (string memory);
}

// SPDX-License-Identifier: GPL
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is Pausable, Ownable {
    string private _name;
    string private _symbol;
    address private _delegate;

    event Delegate(
        address indexed sender,
        address indexed to,
        uint256 timestamp
    );

    event Rename(
        address indexed sender,
        string name,
        string indexed symbol,
        uint256 timestamp
    );

    modifier onlyDelegate() {
        require(
            msg.sender == owner() || msg.sender == _delegate,
            "Token: caller is not the owner or delegate"
        );
        _;
    }

    function __name() internal view returns (string memory) {
        return _name;
    }

    function __symbol() internal view returns (string memory) {
        return _symbol;
    }

    function delegate() external view returns (address) {
        return _delegate;
    }

    function pause() external onlyDelegate {
        _pause();
    }

    function unpause() external onlyDelegate {
        _unpause();
    }

    function rename(
        string memory name_,
        string memory symbol_
    ) external onlyDelegate {
        _name = name_;
        _symbol = symbol_;
        emit Rename(msg.sender, name_, symbol_, block.timestamp);
    }

    function setDelegate(address delegate_) external onlyDelegate {
        _delegate = delegate_;
        emit Delegate(msg.sender, delegate_, block.timestamp);
    }

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
}

// SPDX-License-Identifier: GPL
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../helpers/Art.sol";

struct Security {
    address delegate;
    address releaseTo;
    address closeTo;
    address rewardTo;
    uint32 releaseBonus;
    uint32 rewardBonus;
}

struct Deposit {
    uint256 amount;
    uint64 timestamp;
    uint64 collected;
    uint64 duration;
    uint32 rate;
}

interface NoteInterface {
    event Print(
        address sender,
        uint256 indexed id,
        IERC721 indexed collection,
        uint256 indexed collectable,
        uint256 timestamp
    );

    event Secure(
        address indexed sender,
        uint256 indexed id,
        address indexed delegate,
        address releaseTo,
        address closeTo,
        address rewardTo,
        uint32 releaseBonus,
        uint32 rewardBonus,
        uint256 timestamp
    );

    event Certificate(
        address indexed sender,
        uint256 indexed id,
        uint256 indexed print,
        uint256 principal,
        uint64 duration,
        uint64 rate,
        uint256 amount,
        uint256 value,
        uint256 timestamp
    );

    function count() external view returns (uint256);

    function delegateOf(uint256 id) external view returns (address);

    function getArt(uint256 id) external view returns (Art memory);

    function getPrint(uint256 id) external view returns (uint256);

    function getPrintArt(uint256 id) external view returns (Art memory);

    function getSecurity(uint256 id) external view returns (Security memory);

    function getDeposit(uint256 id) external view returns (Deposit memory);

    function getReward(uint256 id) external view returns (uint256);

    function getClaim(uint256 id) external view returns (uint256);

    function getPenalty(uint256 id) external view returns (uint256);

    function getInterest(uint256 id) external view returns (uint256);
}

// SPDX-License-Identifier: GPL
pragma solidity ^0.8.9;

import "../cash/CashInterface.sol";

struct Economics {
    uint32 settleRate;
    uint32 maxDuration;
    uint32 maxCollection;
    uint32 minCollection;
    uint16 timeDilation;
    uint16 captureBonus;
    uint16 commission;
    uint16 timeBonus;
}

abstract contract NoteReserve is CashReserve {
    address private _safe = address(this);
    CashInterface private _cash;

    uint256 private _deposits;
    uint256 private _settledAt;
    uint16 private _rate = 33333;

    Economics private _economics =
        Economics({
            settleRate: 15 minutes,
            maxDuration: 5550 days,
            maxCollection: 730 days,
            minCollection: 1 days,
            timeDilation: 1,
            captureBonus: 1000,
            commission: 2000,
            timeBonus: 1000
        });

    event Clear(
        address indexed sender,
        uint256 balance,
        uint256 indexed timestamp
    );

    event Settle(
        address indexed sender,
        uint256 supply,
        uint256 deposits,
        uint32 interestRate,
        uint256 indexed timestamp
    );

    event SetSafe(
        address indexed sender,
        address indexed safe,
        uint256 timestamp
    );

    event SetEconomics(
        address indexed sender,
        uint32 settleRate,
        uint32 maxDuration,
        uint32 maxCollection,
        uint32 minCollection,
        uint16 timeDilation,
        uint16 captureBonus,
        uint16 commission,
        uint16 timeBonus,
        uint256 timestamp
    );

    receive() external payable {}

    fallback() external payable {}

    function cash() external view returns (CashInterface) {
        return _cash;
    }

    function safe() public view returns (address) {
        return _safe;
    }

    function economics() public view returns (Economics memory) {
        return _economics;
    }

    function interestRate() public view returns (uint16) {
        return _rate;
    }

    function settledAt() external view returns (uint256) {
        return _settledAt;
    }

    function cooldown() public view returns (uint256) {
        return _settledAt + _economics.settleRate;
    }

    function totalDeposits() external view returns (uint256) {
        return _deposits;
    }

    function clear() external {
        address to = address(_cash);
        uint256 balance = address(this).balance;

        (bool success, ) = to.call{value: balance}("");
        require(success, "Failed to clear balance");

        emit Clear(msg.sender, balance, block.timestamp);
    }

    function settle() public {
        require(block.timestamp > cooldown(), "Treasury: cool down");

        uint256 supply = _cash.totalSupply() + _deposits;
        _rate = calculateInterestRate(supply, _deposits);
        _settledAt = block.timestamp;

        emit Settle(msg.sender, supply, _deposits, _rate, block.timestamp);
    }

    function calculateTimeBonus(uint256 interest) public view returns (uint256) {
        return interest + (interest * _economics.timeBonus) / 10000;
    }

    function calculateReward(uint256 interest) public view returns (uint256) {
        return (interest * _economics.commission) / 10000;
    }

    // 3.33% to 333.33%
    function calculateInterestRate(
        uint256 supply_,
        uint256 deposits_
    ) public pure returns (uint16) {
        if (supply_ == 0) return 33333;

        uint256 value = 33000 * deposits_;
        value /= supply_;
        value *= deposits_;
        value /= supply_;

        return uint16(value + 333);
    }

    function calculateMaximumInterest(
        uint256 rate,
        uint256 amount,
        uint64 duration,
        uint256 time
    ) public view returns (uint256) {
        uint256 principal = amount;

        principal = (principal * time) / _economics.maxDuration;
        principal = (((principal * 25) / 2) * rate) / 10000;

        uint256 bonus = (principal * duration) / _economics.maxDuration;
        bonus = (bonus * 33333) / 10000;

        return principal + bonus;
    }

    function calculateEarlyInterest(
        uint256 rate,
        uint256 amount,
        uint64 duration,
        uint256 time
    ) public view returns (uint256) {
        uint256 maximum = calculateMaximumInterest(
            rate,
            amount,
            duration,
            time
        );

        return (maximum * time) / duration;
    }

    function calculateLateInterest(
        uint256 rate,
        uint256 amount,
        uint64 duration,
        uint64 remaining
    ) public view returns (uint256) {
        uint64 total = duration / _economics.timeDilation;
        if (total < remaining) return 0;

        uint64 left = total - remaining;
        uint256 principal = calculateMaximumInterest(rate, amount, total, left);

        principal = (principal * left) / total;
        principal = (principal * left) / total;

        return _economics.timeDilation * principal;
    }

    function calculateEarlyPenalty(
        uint256 amount,
        uint64 duration,
        uint256 time
    ) public pure returns (uint256) {
        uint256 penalty = amount - (amount * time) / duration;
        return penalty > amount ? amount : penalty;
    }

    function calculateLatePenalty(
        uint256 amount,
        uint64 duration,
        uint256 late
    ) public view returns (uint256) {
        if (_economics.timeDilation * late > duration) return amount;
        uint256 penalty = (_economics.timeDilation * amount * late) / duration;
        return penalty > amount ? amount : penalty;
    }

    function calculateCollectionWindow(
        uint64 duration
    ) public view returns (uint64) {
        uint64 window = duration / _economics.timeDilation;
        if (window < _economics.minCollection) return _economics.minCollection;
        if (window > _economics.maxCollection) return _economics.maxCollection;
        return window;
    }

    function calculateInterest(
        uint256 amount,
        uint32 rate,
        uint64 duration,
        uint64 age
    ) public view returns (uint256) {
        if (age == 0 || duration == 0 || amount == 0) {
            return 0;
        }

        uint64 expiry = duration + calculateCollectionWindow(duration);

        return _calculateInterest(amount, rate, duration, age, expiry);
    }

    function calculatePenalty(
        uint256 amount,
        uint64 duration,
        uint256 time
    ) public view returns (uint256) {
        if (amount == 0) return 0;
        if (duration == 0) return 0;
        if (time == 0) return amount;

        if (time < duration) {
            return calculateEarlyPenalty(amount, duration, time);
        }

        uint256 expiry = duration + calculateCollectionWindow(duration);

        if (time > expiry) {
            return calculateLatePenalty(amount, duration, time - expiry);
        }

        return 0;
    }

    function _calculateInterest(
        uint256 amount,
        uint32 rate,
        uint64 duration,
        uint64 age,
        uint64 expiry
    ) internal view returns (uint256) {
        if (age < duration) {
            return calculateEarlyInterest(rate, amount, duration, age);
        } else if (age > expiry) {
            return calculateLateInterest(rate, amount, duration, age - expiry);
        }

        return
            calculateTimeBonus(
                calculateMaximumInterest(rate, amount, duration, duration)
            );
    }

    function _setEconomics(Economics calldata economics_) internal {
        require(
            economics_.minCollection <= economics_.maxCollection,
            "Treasury: invalid collection period"
        );

        require(
            economics_.commission <= 10000,
            "Treasury: commission out of bounds"
        );

        require(
            economics_.captureBonus <= 10000,
            "Treasury: commission out of bounds"
        );

        require(
            economics_.timeBonus <= 10000,
            "Treasury: timeBonus out of bounds"
        );

        _economics = economics_;

        emit SetEconomics(
            msg.sender,
            economics_.settleRate,
            economics_.maxDuration,
            economics_.maxCollection,
            economics_.minCollection,
            economics_.timeDilation,
            economics_.captureBonus,
            economics_.commission,
            economics_.timeBonus,
            block.timestamp
        );
    }

    function _setSafe(address safe_) internal {
        _safe = safe_;

        emit SetSafe(msg.sender, safe_, block.timestamp);
    }

    function _requireValidDuration(uint64 duration) internal view {
        require(
            duration > 0 && duration <= _economics.maxDuration,
            "Treasury: duration is out of bounds"
        );
    }

    function _depositCash(
        uint256 amount,
        uint256 extra
    ) internal returns (uint256) {
        // Transfering cash
        if (amount > 0) {
            _cash.deflate(msg.sender, amount);
        }

        // Transfering value; mint cash
        if (msg.value > 0) {
            amount += _cash.issue{value: msg.value}();
        }

        // Track deposits
        amount += extra;
        _deposits += amount;

        return amount;
    }

    function _inflate(address to, uint256 released, uint32 bonus) internal {
        uint256 remainder = _fund(to, released, bonus);
        _cash.inflate(to, remainder);
    }

    function _withdraw(
        address closeTo,
        address releaseTo,
        uint256 principal,
        uint256 released,
        uint256 captured,
        uint32 bonus
    ) internal {
        // Pay penalties
        if (captured > 0) {
            _deposits -= captured;
            _cash.inflate(_safe, captured);
        }

        // Withdraw the remaining principal
        _deposits -= principal;

        // Fund the withdraw
        released = _fund(releaseTo, released, bonus);

        // Release principal and interest
        if (releaseTo == address(0)) {
            _cash.inflate(closeTo, principal + released);
        } else {
            _cash.inflate(releaseTo, released);
            _cash.inflate(closeTo, principal);
        }
    }

    function _captureCash(address to, uint256 captured) internal {
        // Pay penalties
        if (captured > 0) {
            _deposits -= captured;
        }

        // Pay the bonus
        uint256 claim = (captured * _economics.captureBonus) / 10000;
        _cash.inflate(_safe, captured - claim);
        _cash.inflate(to, claim);
    }

    function _fund(
        address to,
        uint256 released,
        uint32 bonus
    ) internal returns (uint256) {
        if (bonus == 0) return released;
        if (msg.sender == to) return released;

        uint256 amount = (released * bonus) / 10000;
        _cash.inflate(msg.sender, amount);

        return released - amount;
    }

    constructor(CashInterface cash_) {
        _cash = cash_;
    }
}

// SPDX-License-Identifier: GPL
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../helpers/ArtToken.sol";
import "./NoteInterface.sol";
import "./NoteReserve.sol";

abstract contract NoteToken is NoteInterface, NoteReserve, ArtToken {
    uint256 private _count;

    mapping(uint256 => Art) private _art;
    mapping(uint256 => uint256) private _prints;
    mapping(uint256 => uint256) private _claims;
    mapping(uint256 => uint256) private _rewards;
    mapping(uint256 => uint256) private _penalty;
    mapping(uint256 => uint256) private _interest;
    mapping(uint256 => Deposit) private _deposits;
    mapping(uint256 => Security) private _security;

    function name() public view override returns (string memory) {
        return __name();
    }

    function symbol() public view override returns (string memory) {
        return __symbol();
    }

    function count() external view returns (uint256) {
        return _count;
    }

    function delegateOf(uint256 id) external view returns (address) {
        return _security[id].delegate;
    }

    function getArt(uint256 id) external view returns (Art memory) {
        return _art[id];
    }

    function getPrint(uint256 id) external view returns (uint256) {
        return _prints[id];
    }

    function getPrintArt(uint256 id) public view returns (Art memory) {
        return _art[_prints[id]];
    }

    function getSecurity(uint256 id) external view returns (Security memory) {
        return _security[id];
    }

    function getDeposit(uint256 id) external view returns (Deposit memory) {
        return _deposits[id];
    }

    function getReward(uint256 id) external view returns (uint256) {
        return _rewards[id];
    }

    function getClaim(uint256 id) external view returns (uint256) {
        return _claims[id];
    }

    function getPenalty(uint256 id) external view returns (uint256) {
        return _penalty[id];
    }

    function getInterest(uint256 id) external view returns (uint256) {
        return _interest[id];
    }

    function setSafe(address safe_) external onlyDelegate {
        _setSafe(safe_);
    }

    function setEconomics(Economics calldata economics_) external onlyOwner {
        _setEconomics(economics_);
    }

    function _print(uint256 id, Art calldata art) internal {
        art.collection.transferFrom(msg.sender, safe(), art.collectable);

        _prints[id] = id;
        _art[id] = art;

        emit Print(
            msg.sender,
            id,
            art.collection,
            art.collectable,
            block.timestamp
        );
    }

    function _deposit(
        uint256 id,
        uint256 print,
        uint256 amount,
        uint64 duration
    ) internal returns (uint256) {
        _requireValidDuration(duration);

        uint256 principal = _depositCash(amount, 0);
        require(principal > 0, "Treasury: invalid amount");

        Deposit storage note = _deposits[id];
        note.timestamp = uint64(block.timestamp);
        note.amount = uint128(principal);
        note.rate = interestRate();
        note.duration = duration;
        _prints[id] = print;

        emit Certificate(
            msg.sender,
            id,
            print,
            principal,
            duration,
            note.rate,
            amount,
            msg.value,
            block.timestamp
        );

        return _count;
    }

    function _secure(uint256 id, Security memory params) internal {
        require(
            params.closeTo == address(0) || params.releaseTo != address(0),
            "Treasury: release address required with close address"
        );

        if (params.rewardTo == address(0)) {
            require(params.rewardBonus == 0, "Treasury: invalid bonus");
        } else {
            require(params.rewardBonus <= 10000, "Treasury: invalid bonus");
        }

        if (params.releaseTo == address(0)) {
            require(params.releaseBonus == 0, "Treasury: invalid bonus");
        } else {
            require(params.releaseBonus <= 10000, "Treasury: invalid bonus");
        }

        _security[id] = params;

        emit Secure(
            msg.sender,
            id,
            params.delegate,
            params.releaseTo,
            params.closeTo,
            params.rewardTo,
            params.releaseBonus,
            params.rewardBonus,
            block.timestamp
        );
    }

    function _reward(uint256 id, uint256 limit) internal returns (uint256) {
        uint256 reward = _rewards[id] - _claims[id];

        if (limit > 0 && reward > limit) {
            reward = limit;
        }

        _claims[id] += reward;
        return reward;
    }

    function _boost(
        uint256 id,
        Deposit storage note,
        uint256 amount
    ) internal returns (uint256 interest, uint256 released) {
        (uint64 age, uint64 expiry) = _chronos(note);

        require(
            age > note.duration && age < expiry,
            "Treasury: deposit is not ready to boost"
        );

        (interest, released) = _collect(id, note, 0, age, expiry);
        note.amount += _depositCash(amount, released);
        note.timestamp = uint64(block.timestamp);
        _interest[id] = 0;

        return (interest, released);
    }

    function _release(
        uint256 id,
        Deposit memory note,
        uint256 limit
    ) internal returns (uint256 interest, uint256 released) {
        (uint64 age, uint64 expiry) = _chronos(note);

        return _collect(id, note, limit, age, expiry);
    }

    function _close(
        uint256 id,
        Deposit storage note
    ) internal returns (uint256, uint256, uint256, uint256) {
        (uint64 age, uint64 expiry) = _chronos(note);

        (uint256 interest, uint256 released) = _collect(
            id,
            note,
            0,
            age,
            expiry
        );

        note.collected = uint64(block.timestamp);
        (uint256 penalty, uint256 captured) = _balance(id, note, age, expiry);

        return (interest, penalty, released, captured);
    }

    function _capture(
        uint256 id,
        Deposit memory note
    ) internal returns (uint256 penalty, uint256 captured) {
        (uint64 age, uint64 expiry) = _chronos(note);

        require(age > expiry, "Treasury: note is not expired");

        return _balance(id, note, age, expiry);
    }

    function _collect(
        uint256 id,
        Deposit memory note,
        uint256 limit,
        uint64 age,
        uint64 expiry
    ) internal returns (uint256 interest, uint256 released) {
        // Accounting for interest
        uint256 current = _interest[id];
        interest = _calculateInterest(
            note.amount,
            note.rate,
            note.duration,
            age,
            expiry
        );

        // Only release avaliable interest
        if (current > interest) {
            return (interest, 0);
        }

        // Release the remaining interest
        released = interest - current;

        // Do not surpass the requested release limit
        if (limit != 0 && released > limit) {
            released = limit;
        }

        // Keep track of the released interest and update rewards
        _rewards[_prints[id]] += calculateReward(released);
        _interest[id] += released;

        return (interest, released);
    }

    function _balance(
        uint256 id,
        Deposit memory note,
        uint64 age,
        uint64 expiry
    ) internal returns (uint256 penalty, uint256 captured) {
        // Accounting for penalties
        if (age < note.duration) {
            // Early
            penalty = calculateEarlyPenalty(note.amount, note.duration, age);
        } else if (age > expiry) {
            // Late
            penalty = calculateLatePenalty(
                note.amount,
                note.duration,
                age - expiry
            );
        }

        if (penalty > _penalty[id]) {
            // Keep track of the captured penalties
            captured = penalty - _penalty[id];
            _penalty[id] = penalty;
        }

        return (penalty, captured);
    }

    function _requireSecureNote(uint id) internal view returns (
        Deposit storage note,
        Security memory security,
        bool operator
    ) {
        _requireNote(id);
        note = _deposits[id];
        security = _security[id];

        if (msg.sender == ownerOf(id) || msg.sender == security.delegate) {
            return (note, security, true);
        }

        require(
            block.timestamp > note.timestamp + note.duration,
            "Treasury: caller does not have permission"
        );

        return (note, security, false);
    }

    function _checkSecurity(
        address to,
        address secureTo,
        bool op
    ) internal pure {
        require(
            to != address(0) && (op || to == secureTo),
            "Treasury: caller does not have permission"
        );
    }

    function _secureReward(
        uint256 id,
        address to
    ) internal view returns (uint32) {
        (, Security memory security, bool op) = _requireSecureNote(id);

        _checkSecurity(to, security.rewardTo, op);

        return security.rewardBonus;
    }

    function _secureRelease(
        uint256 id,
        address to
    ) internal view returns (Deposit memory, uint32 releaseBonus) {
        (
            Deposit memory note,
            Security memory security,
            bool op
        ) = _requireSecureNote(id);

        _requireOpenDeposit(note);
        _checkSecurity(to, security.releaseTo, op);

        return (note, security.releaseBonus);
    }

    function _secureClose(
        uint256 id,
        address closeTo,
        address releaseTo
    ) internal view returns (Deposit storage, uint32 releaseBonus) {
        (
            Deposit storage note,
            Security memory security,
            bool op
        ) = _requireSecureNote(id);

        _requireOpenDeposit(note);
        _checkSecurity(closeTo, security.closeTo, op);
        _checkSecurity(releaseTo, security.releaseTo, op);

        return (note, security.releaseBonus);
    }

    function _secureBoost(uint256 id) internal view returns (Deposit storage) {
        (Deposit storage note, , bool op) = _requireSecureNote(id);

        require(op, "Treasury: caller does not have permission");
        _requireOpenDeposit(note);

        return note;
    }

    function _secureCapture(
        uint256 id
    ) internal view returns (Deposit memory note) {
        _requireNote(id);

        note = _deposits[id];
        _requireOpenDeposit(note);

        return note;
    }

    function _createNote() internal returns (uint256) {
        return ++_count;
    }

    function _requireNote(uint256 id) internal view {
        require(id > 0 && id <= _count, "Treasury: invalid token ID");
    }

    function _requirePrint(uint256 id) internal view {
        require(
            address(_art[id].collection) != address(0),
            "Treasury: art is not a print"
        );
    }

    function _requireOpenDeposit(Deposit memory note) internal pure {
        require(
            note.amount > 0 && note.duration > 0 && note.collected == 0,
            "Treasury: note is not an open deposit"
        );
    }

    function _requireMyNote(uint256 id) internal view {
        require(
            msg.sender == ownerOf(id),
            "Treasury: caller does not have permission"
        );
    }

    function _chronos(
        Deposit memory note
    ) internal view returns (uint64 age, uint64 expiry) {
        age = uint64(block.timestamp) - note.timestamp;
        expiry = note.duration + calculateCollectionWindow(note.duration);
        return (age, expiry);
    }

    function _afterTokenTransfer(
        address from,
        address,
        uint256 id,
        uint256
    ) internal virtual override {
        if (from != address(0)) {
            // Prevent mistaken releases after a sale and/or transfer
            delete _security[id];

            emit Secure(
                msg.sender,
                id,
                address(0),
                address(0),
                address(0),
                address(0),
                0,
                0,
                block.timestamp
            );
        }
    }
}

// SPDX-License-Identifier: GPL
pragma solidity ^0.8.9;

import "./TreasuryInterface.sol";
import "./NoteToken.sol";

contract Treasury is TreasuryInterface, NoteToken {
    function forge(
        address to,
        Art calldata art
    ) external whenNotPaused returns (uint256 id) {
        id = _createNote();

        _print(id, art);
        _mint(to, id);

        return id;
    }

    function deposit(
        uint256 print,
        DepositParams calldata params
    ) external payable whenNotPaused returns (uint256 id) {
        _requirePrint(print);
        id = _createNote();

        _deposit(id, print, params.amount, params.duration);
        _mint(params.to, id);

        return id;
    }

    function forgeDeposit(
        Art calldata art,
        DepositParams calldata params
    ) external payable whenNotPaused returns (uint256 id) {
        id = _createNote();

        _print(id, art);
        _deposit(id, id, params.amount, params.duration);
        _mint(params.to, id);

        return id;
    }

    function secure(uint256 id, Security calldata params) external {
        _requireMyNote(id);
        _secure(id, params);
    }

    function reward(ReleaseParams calldata params) external returns (uint256) {
        uint32 rewardBonus = _secureReward(params.id, params.to);
        uint256 released = _reward(params.id, params.limit);

        _inflate(params.to, released, rewardBonus);

        emit Reward(
            msg.sender,
            params.id,
            params.to,
            released,
            params.limit,
            rewardBonus,
            block.timestamp
        );

        return released;
    }

    function release(ReleaseParams calldata params) external returns (uint256) {
        (Deposit memory note, uint32 releaseBonus) = _secureRelease(
            params.id,
            params.to
        );

        (uint256 interest, uint256 released) = _release(
            params.id,
            note,
            params.limit
        );

        _inflate(params.to, released, releaseBonus);

        emit Release(
            msg.sender,
            params.id,
            params.to,
            interest,
            released,
            releaseBonus,
            block.timestamp
        );

        return released;
    }

    function boost(
        uint256 id,
        uint256 extra
    ) external payable whenNotPaused returns (uint256) {
        Deposit storage note = _secureBoost(id);

        (uint256 interest, uint256 released) = _boost(id, note, extra);

        emit Boost(
            msg.sender,
            id,
            interest,
            released,
            extra,
            msg.value,
            note.amount,
            block.timestamp
        );

        return released;
    }

    function close(CloseParams calldata params) external {
        (Deposit storage note, uint32 releaseBonus) = _secureClose(
            params.id,
            params.to,
            params.releaseTo
        );

        (
            uint256 interest,
            uint256 penalty,
            uint256 released,
            uint256 captured
        ) = _close(params.id, note);

        _withdraw(
            params.to,
            params.releaseTo,
            note.amount - penalty,
            released,
            captured,
            releaseBonus
        );

        emit Close(
            msg.sender,
            params.id,
            params.to,
            params.releaseTo,
            note.amount,
            interest,
            penalty,
            released,
            captured,
            releaseBonus,
            block.timestamp
        );
    }

    function capture(uint256 id, address to) public whenNotPaused returns (uint256) {
        Deposit memory note = _secureCapture(id);

        (uint256 penalty, uint256 captured) = _capture(id, note);
        _captureCash(to, captured);

        emit Capture(msg.sender, id, to, penalty, captured, block.timestamp);
        return captured;
    }

    function captureMany(uint256[] memory ids, address to) external whenNotPaused {
        for (uint i = 0; i < ids.length; i++) {
            capture(ids[i], to);
        }
    }

    constructor(
        CashInterface cash
    ) NoteReserve(cash) ArtToken("ARTFUL CASH", "CASH") {}
}

// SPDX-License-Identifier: GPL
pragma solidity ^0.8.9;

import "../cash/CashInterface.sol";
import "./NoteInterface.sol";
import "../helpers/Art.sol";

struct DepositParams {
    address to;
    uint256 amount;
    uint64 duration;
}

struct ReleaseParams {
    address to;
    uint256 id;
    uint256 limit;
}

struct CloseParams {
    uint256 id;
    address to;
    address releaseTo;
}

interface TreasuryInterface is NoteInterface, IERC721 {
    event Reward(
        address indexed sender,
        uint256 indexed id,
        address indexed to,
        uint256 reward,
        uint256 limit,
        uint32 rewardBonus,
        uint256 timestamp
    );

    event Release(
        address indexed sender,
        uint256 indexed id,
        address indexed to,
        uint256 interest,
        uint256 release,
        uint32 releaseBonus,
        uint256 timestamp
    );

    event Boost(
        address indexed sender,
        uint256 indexed id,
        uint256 interest,
        uint256 released,
        uint256 extra,
        uint256 value,
        uint256 principal,
        uint256 timestamp
    );

    event Close(
        address indexed sender,
        uint256 indexed id,
        address indexed closeTo,
        address releaseTo,
        uint256 amount,
        uint256 interest,
        uint256 penalty,
        uint256 released,
        uint256 captured,
        uint32 releaseBonus,
        uint256 timestamp
    );

    event Capture(
        address indexed sender,
        uint256 indexed id,
        address indexed to,
        uint256 penalty,
        uint256 captured,
        uint256 timestamp
    );

    function forge(
        address to,
        Art calldata art
    ) external returns (uint256 id);

    function deposit(
        uint256 print,
        DepositParams calldata params
    ) external payable returns (uint256 id);

    function forgeDeposit(
        Art calldata art,
        DepositParams calldata params
    ) external payable returns (uint256 id);

    function reward(ReleaseParams calldata params) external returns (uint256);

    function release(ReleaseParams calldata params) external returns (uint256);

    function boost(uint256 id, uint256 extra) external payable returns (uint256);

    function close(CloseParams calldata params) external;

    function secure(uint256 id, Security calldata params) external;

    function capture(uint256 id, address to) external returns (uint256);

    function captureMany(uint256[] memory ids, address to) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.2) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
     *
     * WARNING: Anyone calling this MUST ensure that the balances remain consistent with the ownership. The invariant
     * being that for any address `a` the value returned by `balanceOf(a)` must be equal to the number of tokens such
     * that `ownerOf(tokenId)` is `a`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __unsafe_increaseBalance(address account, uint256 amount) internal {
        _balances[account] += amount;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}