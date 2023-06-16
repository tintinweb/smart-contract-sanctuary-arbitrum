// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

struct AuctionInfo {
    address id;
    address auctionToken;
    address payToken;
    bool finalized;
    uint64 vestingStart;
    uint64 vestingDuration;
    uint64 startTime;
    uint64 endTime;
    uint128 ceilingPrice;
    uint128 minPrice;
    uint128 totalTokens;
    uint128 commitmentsTotal;
    bool auctionEnded;
    bool auctionSuccessful;
}

struct CommitmentInfo {
    uint256 amount;
    AuctionInfo auction;
}

interface IAuctionFactory {
    function totalAuctions() external view returns (uint256);
    function auctions(uint256 index) external view returns (address);
}

interface IBatchAuction {
    function auctionToken() external view returns (address);
    function payToken() external view returns (address);
    function finalized() external view returns (bool);
    function totalTokens() external view returns (uint128);
    function startTime() external view returns (uint64);
    function endTime() external view returns (uint64);
    function minPrice() external view returns (uint128);
    function ceilingPrice() external view returns (uint128);
    function commitmentsTotal() external view returns (uint128);
    function auctionEnded() external view returns (bool);
    function auctionSuccessful() external view returns (bool);
    function commitments(address _user) external view returns (uint256);
    function vestingStart() external view returns (uint64);
    function vestingDuration() external view returns (uint64);
}

contract LvlBatchAuctionLens {
    // IAuctionFactory
    function getAuctions(IAuctionFactory _auctionFactory)
        public
        view
        returns (address[] memory _auctions, uint256 _totalAuctions)
    {
        _totalAuctions = _auctionFactory.totalAuctions();
        if (_totalAuctions > 0) {
            _auctions = new address[](_totalAuctions);
            uint256 _index = 0;
            for (uint256 i = _totalAuctions; i > 0; i--) {
                _auctions[_index++] = _auctionFactory.auctions(i - 1);
            }
        }
    }

    // FOR LVL
    function getLvlAuctionInfo(IBatchAuction _batchAuction) public view returns (AuctionInfo memory) {
        AuctionInfo memory _info;
        _info.id = address(_batchAuction);
        _info.auctionToken = _batchAuction.auctionToken();
        _info.payToken = _batchAuction.payToken();
        _info.finalized = _batchAuction.finalized();
        _info.vestingStart = _batchAuction.vestingStart();
        _info.vestingDuration = _batchAuction.vestingDuration();
        _info.startTime = _batchAuction.startTime();
        _info.endTime = _batchAuction.endTime();
        _info.ceilingPrice = _batchAuction.ceilingPrice();
        _info.minPrice = _batchAuction.minPrice();
        _info.totalTokens = _batchAuction.totalTokens();
        _info.commitmentsTotal = _batchAuction.commitmentsTotal();
        _info.auctionEnded = _batchAuction.auctionEnded();
        _info.auctionSuccessful = _batchAuction.auctionSuccessful();
        return _info;
    }

    function getLvlAuctionInfos(IAuctionFactory _auctionFactory, uint256 _skip, uint256 _take)
        external
        view
        returns (AuctionInfo[] memory _auctionInfos)
    {
        (address[] memory _auctions, uint256 _totalAuctions) = getAuctions(_auctionFactory);
        _skip = _skip < _totalAuctions ? _skip : _totalAuctions;
        _take = _skip + _take > _totalAuctions ? _totalAuctions - _skip : _take;
        _auctionInfos = new AuctionInfo[](_take);
        for (uint256 i = 0; i < _take; i++) {
            _auctionInfos[i] = getLvlAuctionInfo(IBatchAuction(_auctions[_skip + i]));
        }
    }

    function getOnGoingLvlAuctionInfos(IAuctionFactory _auctionFactory)
        external
        view
        returns (AuctionInfo[] memory _auctionInfos)
    {
        (address[] memory _auctions, uint256 _totalAuctions) = getAuctions(_auctionFactory);
        if (_totalAuctions > 0) {
            _auctionInfos = new AuctionInfo[](_totalAuctions);
            uint256 _index = 0;
            for (uint256 i = 0; i < _totalAuctions; i++) {
                AuctionInfo memory _batchAuction = getLvlAuctionInfo(IBatchAuction(_auctions[i]));
                if (
                    block.timestamp >= _batchAuction.startTime && block.timestamp <= _batchAuction.endTime
                        && !_batchAuction.finalized && !_batchAuction.auctionEnded
                ) {
                    _auctionInfos[_index++] = _batchAuction;
                }
            }
        }
    }

    function getUpCommingLvlAuctionInfos(IAuctionFactory _auctionFactory)
        external
        view
        returns (AuctionInfo[] memory _auctionInfos)
    {
        (address[] memory _auctions, uint256 _totalAuctions) = getAuctions(_auctionFactory);
        _auctionInfos = new AuctionInfo[](_totalAuctions);
        uint256 _index = 0;
        for (uint256 i = 0; i < _totalAuctions; i++) {
            AuctionInfo memory _batchAuction = getLvlAuctionInfo(IBatchAuction(_auctions[i]));
            if (block.timestamp < _batchAuction.startTime) {
                _auctionInfos[_index++] = _batchAuction;
            }
        }
    }

    function getLvlAuctionsCommittedByUser(IAuctionFactory _auctionFactory, address _user)
        external
        view
        returns (CommitmentInfo[] memory _commitments)
    {
        (address[] memory _auctions, uint256 _totalAuctions) = getAuctions(_auctionFactory);
        uint256 _index = 0;
        _commitments = new CommitmentInfo[](_totalAuctions);
        for (uint256 i = 0; i < _totalAuctions; i++) {
            uint256 _commited = IBatchAuction(_auctions[i]).commitments(_user);
            if (_commited > 0) {
                AuctionInfo memory _batchAuction = getLvlAuctionInfo(IBatchAuction(_auctions[i]));
                _commitments[_index] = CommitmentInfo({amount: _commited, auction: _batchAuction});
                _index++;
            }
        }
    }
}